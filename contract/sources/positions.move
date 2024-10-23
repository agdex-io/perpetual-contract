module perpetual::positions {

    use std::bcs;
    use std::vector;
    use aptos_framework::signer;
    use aptos_framework::account::{Self, SignerCapability};
    use std::option::{Self, Option};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::event::emit;
    use aptos_framework::randomness;
    use aptos_framework::fungible_asset;
    use aptos_framework::fungible_asset::FungibleAsset;
    use aptos_framework::primary_fungible_store;
    use perpetual::type_registry::get_metadata;
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::agg_price::{Self, AggPrice};
    use perpetual::sdecimal::{Self, SDecimal};

    friend perpetual::market;
    friend perpetual::pool;

    const OK: u64 = 0;

    const ERR_ALREADY_CLOSED: u64 = 30001;
    const ERR_POSITION_NOT_CLOSED: u64 = 30002;
    const ERR_INVALID_PLEDGE: u64 = 30003;
    const ERR_INVALID_REDEEM_AMOUNT: u64 = 30004;
    const ERR_INVALID_OPEN_AMOUNT: u64 = 30005;
    const ERR_INVALID_DECREASE_AMOUNT: u64 = 30006;
    const ERR_INSUFFICIENT_COLLATERAL: u64 = 30007;
    const ERR_INSUFFICIENT_RESERVED: u64 = 30008;
    const ERR_COLLATERAL_VALUE_TOO_LESS: u64 = 30009;
    const ERR_HOLDING_DURATION_TOO_SHORT: u64 = 30010;
    const ERR_LEVERAGE_TOO_LARGE: u64 = 30011;
    const ERR_LIQUIDATION_TRIGGERED: u64 = 30012;
    const ERR_LIQUIDATION_NOT_TRIGGERED: u64 = 30013;
    const ERR_EXCEED_MAX_RESERVED: u64 = 30014;
    const ERR_COLLATERAL_PRICE_EXCEED_THRESHOLD: u64 = 30015;

    struct PositionConfig has copy, drop, store {
        max_leverage: u64,
        min_holding_duration: u64,
        max_reserved_multiplier: u64,
        min_collateral_value: Decimal,
        open_fee_bps: Rate,
        decrease_fee_bps: Rate,
        // liquidation_threshold + liquidation_bonus < 100%
        liquidation_threshold: Rate,
        liquidation_bonus: Rate,
    }

    struct Position<phantom CoinType> has store {
        legacy: bool,
        closed: bool,
        config: PositionConfig,
        open_timestamp: u64,
        position_amount: u64,
        position_size: Decimal,
        reserving_fee_amount: Decimal,
        funding_fee_value: SDecimal,
        last_reserving_rate: Rate,
        last_funding_rate: SRate,
        reserved_legacy: Option<Coin<CoinType>>,
        collateral_legacy: Option<Coin<CoinType>>,
        reserved_fa: Option<SignerCapability>,
        collateral_fa: Option<SignerCapability>,
    }

    struct OpenPositionResult<phantom Collateral> {
        legacy: bool,
        position: Position<Collateral>,
        open_fee_legacy: Option<Coin<Collateral>>,
        open_fee_fa: Option<FungibleAsset>,
        open_fee_amount: Decimal,
    }

    struct DecreasePositionResult<phantom Collateral> {
        legacy: bool,
        closed: bool,
        has_profit: bool,
        settled_amount: u64,
        decreased_reserved_amount: u64,
        decrease_size: Decimal,
        reserving_fee_amount: Decimal,
        decrease_fee_value: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        to_vault_legacy: Option<Coin<Collateral>>,
        to_trader_legacy: Option<Coin<Collateral>>,
        to_vault_fa: Option<FungibleAsset>,
        to_trader_fa: Option<FungibleAsset>,
    }

    #[event]
    struct VaultDepositEvent<phantom Collateral> has copy, drop, store {
        amount: u64
    }

    #[event]
    struct VaultWithdrawEvent<phantom Collateral> has copy, drop, store {
        amount: u64
    }
    #[event]
    struct PositionOpenPosition<phantom Collateral> has copy, drop, store {
        closed: bool,
        config: PositionConfig,
        open_timestamp: u64,
        position_amount: u64,
        position_size: Decimal,
        reserving_fee_amount: Decimal,
        funding_fee_value: SDecimal,
        last_reserving_rate: Rate,
        last_funding_rate: SRate,
        reserved: u64,
        collateral: u64
    }

    #[event]
    struct PositionSnapshot<phantom Collateral> has copy, drop, store {
        closed: bool,
        config: PositionConfig,
        open_timestamp: u64,
        position_amount: u64,
        position_size: Decimal,
        reserving_fee_amount: Decimal,
        funding_fee_value: SDecimal,
        last_reserving_rate: Rate,
        last_funding_rate: SRate,
        reserved_amount: u64,
        collateral_amount: u64
    }

    #[event]
    struct PositionDecreasePosition<phantom Collateral> has copy, drop, store {
        closed: bool,
        has_profit: bool,
        decrease_timestamp: u64,
        settled_amount: u64,
        decreased_reserved_amount: u64,
        decrease_size: Decimal,
        reserving_fee_amount: Decimal,
        decrease_fee_value: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        to_vault: u64,
        to_trader: u64
    }

    #[event]
    struct PositionLiquidation<phantom Collateral> has copy, drop, store {
        bonus_amount: u64,
        collateral_amount: u64,
        position_amount: u64,
        reserved_amount: u64,
        position_size: Decimal,
        reserving_fee_amount: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        to_vault_amount: u64,
        to_liquidator_amount: u64,
    }

    public(friend) fun new_position_config(
        max_leverage: u64,
        min_holding_duration: u64,
        max_reserved_multiplier: u64,
        min_collateral_value: u256,
        open_fee_bps: u128,
        decrease_fee_bps: u128,
        liquidation_threshold: u128,
        liquidation_bonus: u128,
    ): PositionConfig {
        PositionConfig {
            max_leverage,
            min_holding_duration,
            max_reserved_multiplier,
            min_collateral_value: decimal::from_raw(min_collateral_value),
            open_fee_bps: rate::from_raw(open_fee_bps),
            decrease_fee_bps: rate::from_raw(decrease_fee_bps),
            liquidation_threshold: rate::from_raw(liquidation_threshold),
            liquidation_bonus: rate::from_raw(liquidation_bonus),
        }
    }

    public(friend) fun open_position<Collateral>(
        config: &PositionConfig,
        collateral_price: &AggPrice,
        index_price: &AggPrice,
        fa_signer_cap: &SignerCapability,
        collateral: FungibleAsset,
        collateral_price_threshold: Decimal,
        open_amount: u64,
        reserve_amount: u64,
        reserving_rate: Rate,
        funding_rate: SRate,
        timestamp: u64,
    ): (u64, Option<OpenPositionResult<Collateral>>) {
        if (fungible_asset::amount(&collateral) == 0) {
            return (ERR_INVALID_PLEDGE, option::none())
        };
        if (
            decimal::lt(
                &agg_price::price_of(collateral_price),
                &collateral_price_threshold,
            )
        ) {
            return (ERR_COLLATERAL_PRICE_EXCEED_THRESHOLD, option::none())
        };
        if (open_amount == 0) {
            return (ERR_INVALID_OPEN_AMOUNT, option::none())
        };
        if (fungible_asset::amount(&collateral) * config.max_reserved_multiplier < reserve_amount) {
            return (ERR_EXCEED_MAX_RESERVED, option::none())
        };

        // compute position size
        let open_size = agg_price::coins_to_value(index_price, open_amount);

        // compute fee
        let open_fee_value = decimal::mul_with_rate(open_size, config.open_fee_bps);
        let open_fee_amount_dec = agg_price::value_to_coins(collateral_price, open_fee_value);
        let open_fee_amount = decimal::ceil_u64(open_fee_amount_dec);
        if (open_fee_amount > fungible_asset::amount(&collateral)) {
            return (ERR_INSUFFICIENT_COLLATERAL, option::none())
        };

        // compute collateral value
        let collateral_value = agg_price::coins_to_value(
            collateral_price,
            fungible_asset::amount(&collateral) - open_fee_amount,
        );
        if (decimal::lt(&collateral_value, &config.min_collateral_value)) {
            return (ERR_COLLATERAL_VALUE_TOO_LESS, option::none())
        };

        // validate leverage
        let ok = check_leverage(config, collateral_value, open_amount, index_price);
        if (!ok) {
            return (ERR_LEVERAGE_TOO_LARGE, option::none())
        };

        let (reserved_fa_signer, reserved_signercap) = generate_resource_account<Collateral>(fa_signer_cap, timestamp);
        let (collateral_fa_account, collateral_signercap) = generate_resource_account<Collateral>(fa_signer_cap, timestamp);
        // take away open fee
        let open_fee = fungible_asset::extract(&mut collateral, open_fee_amount);
        emit(VaultWithdrawEvent<Collateral>{amount: reserve_amount});
        let collateral_amount = fungible_asset::amount(&collateral);
        primary_fungible_store::deposit(signer::address_of(&collateral_fa_account), collateral);
        primary_fungible_store::transfer(
            &account::create_signer_with_capability(fa_signer_cap),
            get_metadata<Collateral>(),
            account::get_signer_capability_address(&reserved_signercap),
            reserve_amount
        );

        // construct position
        let position = Position {
            legacy: false,
            closed: false,
            config: *config,
            open_timestamp: timestamp,
            position_amount: open_amount,
            position_size: open_size,
            reserving_fee_amount: decimal::zero(),
            funding_fee_value: sdecimal::zero(),
            last_reserving_rate: reserving_rate,
            last_funding_rate: funding_rate,
            reserved_legacy: option::none<Coin<Collateral>>(),
            collateral_legacy: option::none<Coin<Collateral>>(),
            reserved_fa: option::some<SignerCapability>(reserved_signercap),
            collateral_fa: option::some<SignerCapability>(collateral_signercap)
        };

        emit(PositionOpenPosition<Collateral> {
            closed: false,
            config: *config,
            open_timestamp: timestamp,
            position_amount: open_amount,
            position_size: open_size,
            reserving_fee_amount: decimal::zero(),
            funding_fee_value: sdecimal::zero(),
            last_reserving_rate: reserving_rate,
            last_funding_rate: funding_rate,
            reserved: reserve_amount,
            collateral: collateral_amount,
        });
        let result = OpenPositionResult {
            legacy: false,
            position,
            open_fee_legacy: option::none<Coin<Collateral>>(),
            open_fee_fa: option::some(open_fee),
            open_fee_amount: open_fee_amount_dec,
        };
        (OK, option::some(result))
    }

    fun generate_resource_account<Collateral>(cap: &SignerCapability, timestamp: u64): (signer, SignerCapability) {
        let s = account::create_signer_with_capability(cap);
        let seed = randomness::bytes(1);
        vector::append(&mut seed, bcs::to_bytes<u64>(&timestamp));
        primary_fungible_store::ensure_primary_store_exists(signer::address_of(&s), get_metadata<Collateral>());
        account::create_resource_account(&s, seed)
    }

    public(friend) fun open_position_legacy<Collateral>(
        config: &PositionConfig,
        collateral_price: &AggPrice,
        index_price: &AggPrice,
        liquidity: &mut Coin<Collateral>,
        collateral: &mut Coin<Collateral>,
        collateral_price_threshold: Decimal,
        open_amount: u64,
        reserve_amount: u64,
        reserving_rate: Rate,
        funding_rate: SRate,
        timestamp: u64,
    ): (u64, Option<OpenPositionResult<Collateral>>) {
        if (coin::value(collateral) == 0) {
            return (ERR_INVALID_PLEDGE, option::none())
        };
        if (
            decimal::lt(
                &agg_price::price_of(collateral_price),
                &collateral_price_threshold,
            )
        ) {
            return (ERR_COLLATERAL_PRICE_EXCEED_THRESHOLD, option::none())
        };
        if (open_amount == 0) {
            return (ERR_INVALID_OPEN_AMOUNT, option::none())
        };
        if (coin::value(collateral) * config.max_reserved_multiplier < reserve_amount) {
            return (ERR_EXCEED_MAX_RESERVED, option::none())
        };

        // compute position size
        let open_size = agg_price::coins_to_value(index_price, open_amount);

        // compute fee
        let open_fee_value = decimal::mul_with_rate(open_size, config.open_fee_bps);
        let open_fee_amount_dec = agg_price::value_to_coins(collateral_price, open_fee_value);
        let open_fee_amount = decimal::ceil_u64(open_fee_amount_dec);
        if (open_fee_amount > coin::value(collateral)) {
            return (ERR_INSUFFICIENT_COLLATERAL, option::none())
        };

        // compute collateral value
        let collateral_value = agg_price::coins_to_value(
            collateral_price,
            coin::value(collateral) - open_fee_amount,
        );
        if (decimal::lt(&collateral_value, &config.min_collateral_value)) {
            return (ERR_COLLATERAL_VALUE_TOO_LESS, option::none())
        };

        // validate leverage
        let ok = check_leverage(config, collateral_value, open_amount, index_price);
        if (!ok) {
            return (ERR_LEVERAGE_TOO_LARGE, option::none())
        };

        // take away open fee
        let open_fee = coin::extract(collateral, open_fee_amount);
        emit(VaultWithdrawEvent<Collateral>{amount: reserve_amount});
        let collateral_amount = coin::value(collateral);

        // construct position
        let position = Position {
            legacy: true,
            closed: false,
            config: *config,
            open_timestamp: timestamp,
            position_amount: open_amount,
            position_size: open_size,
            reserving_fee_amount: decimal::zero(),
            funding_fee_value: sdecimal::zero(),
            last_reserving_rate: reserving_rate,
            last_funding_rate: funding_rate,
            reserved_legacy: option::some(coin::extract(liquidity, reserve_amount)),
            collateral_legacy: option::some(coin::extract_all(collateral)),
            reserved_fa: option::none<SignerCapability>(),
            collateral_fa: option::none<SignerCapability>()
        };

        emit(PositionOpenPosition<Collateral> {
            closed: false,
            config: *config,
            open_timestamp: timestamp,
            position_amount: open_amount,
            position_size: open_size,
            reserving_fee_amount: decimal::zero(),
            funding_fee_value: sdecimal::zero(),
            last_reserving_rate: reserving_rate,
            last_funding_rate: funding_rate,
            reserved: reserve_amount,
            collateral: collateral_amount,
        });
        let result = OpenPositionResult {
            legacy: true,
            position,
            open_fee_legacy: option::some(open_fee),
            open_fee_fa: option::none<FungibleAsset>(),
            open_fee_amount: open_fee_amount_dec,
        };
        (OK, option::some(result))
    }

    public(friend) fun decrease_position<Collateral>(
        position: &mut Position<Collateral>,
        collateral_price: &AggPrice,
        index_price: &AggPrice,
        collateral_price_threshold: Decimal,
        long: bool,
        decrease_amount: u64,
        reserving_rate: Rate,
        funding_rate: SRate,
        timestamp: u64,
    ): (u64, Option<DecreasePositionResult<Collateral>>) {
        if (position.closed) {
            return (ERR_ALREADY_CLOSED, option::none())
        };
        let reserved_amount = 0;
        let collateral_amount = 0;
        if(position.legacy) {
            reserved_amount = coin::value(option::borrow(&position.reserved_legacy));
            collateral_amount = coin::value(option::borrow(&position.collateral_legacy));
        } else {
            reserved_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.reserved_fa)),
                get_metadata<Collateral>()
            );
            collateral_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.collateral_fa)),
            get_metadata<Collateral>()
            );
        };
        emit(PositionSnapshot<Collateral>{
            closed: position.closed,
            config: position.config,
            open_timestamp: position.open_timestamp,
            position_amount: position.position_amount,
            position_size: position.position_size,
            reserving_fee_amount: position.reserving_fee_amount,
            funding_fee_value: position.funding_fee_value,
            last_reserving_rate: position.last_reserving_rate,
            last_funding_rate: position.last_funding_rate,
            reserved_amount,
            collateral_amount
        });
        if (
            decimal::lt(
                &agg_price::price_of(collateral_price),
                &collateral_price_threshold,
            )
        ) {
            return (ERR_COLLATERAL_PRICE_EXCEED_THRESHOLD, option::none())
        };
        if (
            decrease_amount == 0 || decrease_amount > position.position_amount
        ) {
            return (ERR_INVALID_DECREASE_AMOUNT, option::none())
        };

        let decrease_size = decimal::div_by_u64(
            decimal::mul_with_u64(position.position_size, decrease_amount),
            position.position_amount,
        );

        // compute delta size
        let delta_size = compute_delta_size(position, index_price, long);
        let settled_delta_size = sdecimal::div_by_u64(
            sdecimal::mul_with_u64(delta_size, decrease_amount),
            position.position_amount,
        );
        delta_size = sdecimal::sub(delta_size, settled_delta_size);

        // check holding duration
        let ok = check_holding_duration(position, &delta_size, timestamp);
        if (!ok) {
            return (ERR_HOLDING_DURATION_TOO_SHORT, option::none())
        };

        // compute fee
        let reserving_fee_amount = compute_reserving_fee_amount(position, reserving_rate);
        let reserving_fee_value = agg_price::coins_to_value(
            collateral_price,
            decimal::ceil_u64(reserving_fee_amount),
        );
        let funding_fee_value = compute_funding_fee_value(position, funding_rate);
        let decrease_fee_value = decimal::mul_with_rate(
            decrease_size,
            position.config.decrease_fee_bps,
        );

        // impact fee on settled delta size
        settled_delta_size = sdecimal::sub(
            settled_delta_size,
            sdecimal::add_with_decimal(
                funding_fee_value,
                decimal::add(decrease_fee_value, reserving_fee_value),
            ),
        );

        let closed = decrease_amount == position.position_amount;

        // handle settlement
        let has_profit = sdecimal::is_positive(&settled_delta_size);
        let settled_amount = agg_price::value_to_coins(
            collateral_price,
            sdecimal::value(&settled_delta_size),
        );
        let settled_amount = if (has_profit) {
            let profit_amount = decimal::floor_u64(settled_amount);
            if (profit_amount >=reserved_amount) {
                // should close position if reserved is not enough to pay profit
                closed = true;
                profit_amount = reserved_amount;
            };

            profit_amount
        } else {
            let loss_amount = decimal::ceil_u64(settled_amount);
            if (loss_amount >= collateral_amount) {
                // should close position if collateral is not enough to pay loss
                closed = true;
                loss_amount = collateral_amount;
            };

            loss_amount
        };
        let decreased_reserved_amount = if (closed) {
            reserved_amount
        } else {
            if (has_profit) { settled_amount } else { 0 }
        };

        let position_amount = position.position_amount - decrease_amount;
        let position_size = decimal::sub(position.position_size, decrease_size);

        // should check the position if not closed
        if (!closed) {
            // compute collateral value
            let collateral_value = agg_price::coins_to_value(
                collateral_price,
                if (has_profit) {
                    collateral_amount
                } else {
                    collateral_amount - settled_amount
                },
            );
            if (decimal::lt(&collateral_value, &position.config.min_collateral_value)) {
                return (ERR_COLLATERAL_VALUE_TOO_LESS, option::none())
            };

            // validate leverage
            ok = check_leverage(&position.config, collateral_value, position_amount, index_price);
            if (!ok) {
                return (ERR_LEVERAGE_TOO_LARGE, option::none())
            };

            // check liquidation
            ok = check_liquidation(&position.config, collateral_value, &delta_size);
            if (ok) {
                return (ERR_LIQUIDATION_TRIGGERED, option::none())
            };
        };

        // update position
        position.closed = closed;
        position.position_amount = position_amount;
        position.position_size = position_size;
        position.reserving_fee_amount = decimal::zero();
        position.funding_fee_value = sdecimal::zero();
        position.last_funding_rate = funding_rate;
        position.last_reserving_rate = reserving_rate;

        let (
            to_vault_legacy,
            to_trader_legacy,
            to_vault_fa,
            to_trader_fa,
            to_vault_amount,
            to_trader_amount
        ) = if(position.legacy) {
            let (to_vault, to_trader) = if (has_profit) {
                (
                    coin::zero(),
                    coin::extract(option::borrow_mut(&mut position.reserved_legacy), settled_amount),
                )
            } else {
                (
                    coin::extract(option::borrow_mut(&mut position.collateral_legacy), settled_amount),
                    coin::zero(),
                )
            };

            if (closed) {
                coin::merge(&mut to_vault, coin::extract_all(option::borrow_mut(&mut position.reserved_legacy)));
                coin::merge(&mut to_trader, coin::extract_all(option::borrow_mut(&mut position.collateral_legacy)));
            };
            let to_vault_amount = coin::value(&to_vault);
            let to_trader_amount = coin::value(&to_trader);
            (option::some(to_vault), option::some(to_trader), option::none<FungibleAsset>(), option::none<FungibleAsset>(), to_vault_amount, to_trader_amount)
        } else {
            let (to_vault, to_trader) = if (has_profit) {
                (
                    fungible_asset::zero(get_metadata<Collateral>()),
                    primary_fungible_store::withdraw(
                        &account::create_signer_with_capability(option::borrow(&position.reserved_fa)),
                            get_metadata<Collateral>(),
                            settled_amount
                    ),
                )
            } else {
                (
                    primary_fungible_store::withdraw(
                        &account::create_signer_with_capability(option::borrow(&position.collateral_fa)),
                        get_metadata<Collateral>(),
                        settled_amount
                    ),
                    fungible_asset::zero(get_metadata<Collateral>()),
                )
            };

            if (closed) {
                let reserved_fa = primary_fungible_store::balance(
                    account::get_signer_capability_address(option::borrow(&position.reserved_fa)),
                    get_metadata<Collateral>()
                );
                let collateral_fa = primary_fungible_store::balance(
                    account::get_signer_capability_address(option::borrow(&position.collateral_fa)),
                    get_metadata<Collateral>()
                );
                fungible_asset::merge(
                    &mut to_vault,
                    primary_fungible_store::withdraw(&account::create_signer_with_capability(option::borrow(&position.reserved_fa)), get_metadata<Collateral>(), reserved_fa));
                fungible_asset::merge(
                    &mut to_trader,
                primary_fungible_store::withdraw(&account::create_signer_with_capability(option::borrow(&position.reserved_fa)), get_metadata<Collateral>(), reserved_fa));
            };
            let to_vault_amount = fungible_asset::amount(&to_vault);
            let to_trader_amount = fungible_asset::amount(&to_trader);
            (option::none<Coin<Collateral>>(), option::none<Coin<Collateral>>(), option::some<FungibleAsset>(to_vault), option::some<FungibleAsset>(to_trader), to_vault_amount, to_trader_amount)
        };
        emit(PositionDecreasePosition<Collateral> {
            closed,
            has_profit,
            decrease_timestamp: timestamp,
            settled_amount,
            decreased_reserved_amount,
            decrease_size,
            reserving_fee_amount,
            decrease_fee_value,
            reserving_fee_value,
            funding_fee_value,
            to_vault: to_vault_amount,
            to_trader: to_trader_amount,
        });

        let result = DecreasePositionResult {
            legacy: position.legacy,
            closed,
            has_profit,
            settled_amount,
            decreased_reserved_amount,
            decrease_size,
            reserving_fee_amount,
            decrease_fee_value,
            reserving_fee_value,
            funding_fee_value,
            to_vault_legacy,
            to_trader_legacy,
            to_vault_fa,
            to_trader_fa,
        };
        (OK, option::some(result))
    }

    public(friend) fun unwrap_open_position_result<C>(
        res: OpenPositionResult<C>,
    ): (bool, Position<C>, Option<Coin<C>>, Option<FungibleAsset>, Decimal) {
        let OpenPositionResult { legacy, position, open_fee_legacy, open_fee_fa, open_fee_amount } = res;

        (legacy, position, open_fee_legacy, open_fee_fa, open_fee_amount)
    }

    public(friend) fun decrease_reserved_from_position<Collateral>(
        position: &mut Position<Collateral>,
        decrease_amount: u64,
        reserving_rate: Rate
    ): (Option<Coin<Collateral>>, Option<FungibleAsset>) {
        assert!(!position.closed, ERR_ALREADY_CLOSED);
        let reserved_amount = 0;
        let collateral_amount = 0;
        if(position.legacy) {
            reserved_amount = coin::value(option::borrow(&position.reserved_legacy));
            collateral_amount = coin::value(option::borrow(&position.collateral_legacy));
        } else {
            reserved_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.reserved_fa)),
                get_metadata<Collateral>()
            );
            collateral_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.collateral_fa)),
                get_metadata<Collateral>()
            );
        };
        assert!(
            decrease_amount < reserved_amount,
            ERR_INSUFFICIENT_RESERVED,
        );

        // compute fee
        let reserving_fee_amount = compute_reserving_fee_amount(position, reserving_rate);

        // update position
        position.reserving_fee_amount = reserving_fee_amount;
        position.last_reserving_rate = reserving_rate;

        if (position.legacy) {
            (
                option::some(coin::extract(option::borrow_mut(&mut position.reserved_legacy), decrease_amount)),
                option::none<FungibleAsset>()
            )
        } else {
            (
                option::none<Coin<Collateral>>(),
                option::some(primary_fungible_store::withdraw(
                    &account::create_signer_with_capability(option::borrow(&position.reserved_fa)),
                    get_metadata<Collateral>(),
                    decrease_amount
                ))
            )
        }
    }

    public(friend) fun pledge_in_position<Collateral>(
        position: &mut Position<Collateral>,
        pledge_legacy: Option<Coin<Collateral>>,
        pledge_fa: Option<FungibleAsset>
    ) {
        assert!(!position.closed, ERR_ALREADY_CLOSED);
        // handle pledge
        if (position.legacy) {
            assert!(coin::value(option::borrow(&pledge_legacy)) > 0, ERR_INVALID_PLEDGE);
            coin::merge(option::borrow_mut(&mut position.collateral_legacy), option::destroy_some(pledge_legacy));
        } else {
            assert!(fungible_asset::amount(option::borrow(&pledge_fa)) > 0, ERR_INVALID_PLEDGE);
            primary_fungible_store::deposit(account::get_signer_capability_address(option::borrow(&position.reserved_fa)), option::destroy_some(pledge_fa));
        }
    }

    public(friend) fun redeem_from_position<Collateral>(
        position: &mut Position<Collateral>,
        collateral_price: &AggPrice,
        index_price: &AggPrice,
        long: bool,
        redeem_amount: u64,
        reserving_rate: Rate,
        funding_rate: SRate,
        timestamp: u64,
    ): (Option<Coin<Collateral>>, Option<FungibleAsset>) {
        assert!(!position.closed, ERR_ALREADY_CLOSED);
        let reserved_amount = 0;
        let collateral_amount = 0;
        if(position.legacy) {
            reserved_amount = coin::value(option::borrow(&position.reserved_legacy));
            collateral_amount = coin::value(option::borrow(&position.collateral_legacy));
        } else {
            reserved_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.reserved_fa)),
                get_metadata<Collateral>()
            );
            collateral_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.collateral_fa)),
                get_metadata<Collateral>()
            );
        };
        assert!(
            redeem_amount > 0
                && redeem_amount < collateral_amount,
            ERR_INVALID_REDEEM_AMOUNT,
        );

        // compute delta size
        let delta_size = compute_delta_size(position, index_price, long);

        // check holding duration
        let ok = check_holding_duration(position, &delta_size, timestamp);
        assert!(ok, ERR_HOLDING_DURATION_TOO_SHORT);

        // compute fee
        let reserving_fee_amount = compute_reserving_fee_amount(position, reserving_rate);
        let reserving_fee_value = agg_price::coins_to_value(
            collateral_price,
            decimal::ceil_u64(reserving_fee_amount),
        );
        let funding_fee_value = compute_funding_fee_value(position, funding_rate);

        // impact fee on delta size
        delta_size = sdecimal::sub(
            delta_size,
            sdecimal::add_with_decimal(funding_fee_value, reserving_fee_value),
        );

        // update position
        position.reserving_fee_amount = reserving_fee_amount;
        position.funding_fee_value = funding_fee_value;
        position.last_reserving_rate = reserving_rate;
        position.last_funding_rate = funding_rate;

        // redeem
        let (redeem_legacy, redeem_fa, collateral_amount) = if (position.legacy) {
            let redeem = coin::extract(option::borrow_mut(&mut position.collateral_legacy), redeem_amount);
            (option::some(redeem), option::none<FungibleAsset>(), coin::value(option::borrow(&position.collateral_legacy)))
        } else {
            let redeem = primary_fungible_store::withdraw(&account::create_signer_with_capability(option::borrow(&position.collateral_fa)), get_metadata<Collateral>(), redeem_amount);
            (option::none<Coin<Collateral>>(), option::some<FungibleAsset>(redeem), primary_fungible_store::balance(account::get_signer_capability_address(option::borrow(&position.collateral_fa)), get_metadata<Collateral>()))
        };

        // compute collateral value
        let collateral_value = agg_price::coins_to_value(
            collateral_price,
            collateral_amount
        );
        assert!(
            decimal::ge(&collateral_value, &position.config.min_collateral_value),
            ERR_COLLATERAL_VALUE_TOO_LESS,
        );

        // validate leverage
        ok = check_leverage(
            &position.config,
            collateral_value,
            position.position_amount,
            index_price,
        );
        assert!(ok, ERR_LEVERAGE_TOO_LARGE);

        // validate liquidation
        ok = check_liquidation(&position.config, collateral_value, &delta_size);
        assert!(!ok, ERR_LIQUIDATION_TRIGGERED);

        (redeem_legacy, redeem_fa)
    }

    public(friend) fun liquidate_position<Collateral>(
        position: &mut Position<Collateral>,
        collateral_price: &AggPrice,
        index_price: &AggPrice,
        long: bool,
        reserving_rate: Rate,
        funding_rate: SRate,
    ): (
        u64,
        u64,
        u64,
        u64,
        Decimal,
        Decimal,
        Decimal,
        SDecimal,
        Option<Coin<Collateral>>,
        Option<Coin<Collateral>>,
        Option<FungibleAsset>,
        Option<FungibleAsset>,
    ) {
        assert!(!position.closed, ERR_ALREADY_CLOSED);
        let reserved_amount = 0;
        let collateral_amount = 0;
        if(position.legacy) {
            reserved_amount = coin::value(option::borrow(&position.reserved_legacy));
            collateral_amount = coin::value(option::borrow(&position.collateral_legacy));
        } else {
            reserved_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.reserved_fa)),
                get_metadata<Collateral>()
            );
            collateral_amount = primary_fungible_store::balance(
                account::get_signer_capability_address(option::borrow(&position.collateral_fa)),
                get_metadata<Collateral>()
            );
        };
        emit(PositionSnapshot<Collateral>{
            closed: position.closed,
            config: position.config,
            open_timestamp: position.open_timestamp,
            position_amount: position.position_amount,
            position_size: position.position_size,
            reserving_fee_amount: position.reserving_fee_amount,
            funding_fee_value: position.funding_fee_value,
            last_reserving_rate: position.last_reserving_rate,
            last_funding_rate: position.last_funding_rate,
            reserved_amount,
            collateral_amount
        });

        // compute delta size
        let delta_size = compute_delta_size(position, index_price, long);

        // compute fee
        let reserving_fee_amount = compute_reserving_fee_amount(position, reserving_rate);
        let reserving_fee_value = agg_price::coins_to_value(
            collateral_price,
            decimal::ceil_u64(reserving_fee_amount),
        );
        let funding_fee_value = compute_funding_fee_value(position, funding_rate);

        // impact fee on delta size
        delta_size = sdecimal::sub(
            delta_size,
            sdecimal::add_with_decimal(funding_fee_value, reserving_fee_value),
        );

        // compute collateral value
        let collateral_value = agg_price::coins_to_value(
            collateral_price,
            collateral_amount,
        );

        // liquidation check
        let ok = check_liquidation(&position.config, collateral_value, &delta_size);
        assert!(ok, ERR_LIQUIDATION_NOT_TRIGGERED);

        let position_amount = position.position_amount;
        let position_size = position.position_size;

        // update position
        position.closed = true;
        position.position_amount = 0;
        position.position_size = decimal::zero();
        position.reserving_fee_amount = decimal::zero();
        position.funding_fee_value = sdecimal::zero();
        position.last_funding_rate = funding_rate;
        position.last_reserving_rate = reserving_rate;

        // compute liquidation bonus
        let bonus_amount = decimal::floor_u64(
            decimal::mul_with_rate(
                decimal::from_u64(collateral_amount),
                position.config.liquidation_bonus,
            )
        );

        let to_vault_amount = 0;
        let to_liquidator_amount = 0;
        let (to_liquidator_legacy, to_vault_legacy, to_liquidator_fa, to_vault_fa) =  if(position.legacy) {
            let to_liquidator = coin::extract(option::borrow_mut(&mut position.collateral_legacy), bonus_amount);
            let to_vault = coin::extract_all(option::borrow_mut(&mut position.reserved_legacy));
            coin::merge(&mut to_vault, coin::extract_all(option::borrow_mut(&mut position.collateral_legacy)));
            to_vault_amount = coin::value(&to_vault);
            to_liquidator_amount = coin::value(&to_liquidator);
            (option::some(to_liquidator), option::some(to_vault), option::none<FungibleAsset>(), option::none<FungibleAsset>())
        } else {
            let to_liquidator = primary_fungible_store::withdraw(
                &account::create_signer_with_capability(option::borrow(&position.collateral_fa)), get_metadata<Collateral>(), bonus_amount);
            let to_vault = primary_fungible_store::withdraw(
                &account::create_signer_with_capability(option::borrow(&mut position.reserved_fa)), get_metadata<Collateral>(), reserved_amount);
            fungible_asset::merge(&mut to_vault, primary_fungible_store::withdraw(
                &account::create_signer_with_capability(option::borrow(&position.collateral_fa)), get_metadata<Collateral>(), (collateral_amount - bonus_amount)));
            to_vault_amount = fungible_asset::amount(&to_vault);
            to_liquidator_amount = fungible_asset::amount(&to_liquidator);
            (option::none<Coin<Collateral>>(), option::none<Coin<Collateral>>(), option::some<FungibleAsset>(to_liquidator), option::some<FungibleAsset>(to_vault))

        };
        emit(PositionLiquidation<Collateral>{
            bonus_amount,
            collateral_amount,
            position_amount,
            reserved_amount,
            position_size,
            reserving_fee_amount,
            reserving_fee_value,
            funding_fee_value,
            to_vault_amount,
            to_liquidator_amount,
        });

        (
            bonus_amount,
            collateral_amount,
            position_amount,
            reserved_amount,
            position_size,
            reserving_fee_amount,
            reserving_fee_value,
            funding_fee_value,
            to_vault_legacy,
            to_liquidator_legacy,
            to_vault_fa,
            to_liquidator_fa,
        )
    }

    public(friend) fun destroy_position<Collateral>(position: Position<Collateral>) {
        // unwrap position
        let Position {
            legacy,
            closed,
            config: _,
            open_timestamp: _,
            position_amount: _,
            position_size: _,
            reserving_fee_amount: _,
            funding_fee_value: _,
            last_reserving_rate: _,
            last_funding_rate: _,
            reserved_legacy,
            collateral_legacy,
            reserved_fa,
            collateral_fa
        } = position;
        assert!(closed, ERR_POSITION_NOT_CLOSED);

        if (legacy) {
            coin::destroy_zero(option::destroy_some(reserved_legacy));
            coin::destroy_zero(option::destroy_some(collateral_legacy));
            option::destroy_none(reserved_fa);
            option::destroy_none(collateral_fa);
        } else {
            option::destroy_none(reserved_legacy);
            option::destroy_none(collateral_legacy);
            coin::destroy_zero(option::destroy_some(reserved_legacy));
            coin::destroy_zero(option::destroy_some(collateral_legacy));
        }
    }

    public fun check_leverage(
        config: &PositionConfig,
        collateral_value: Decimal,
        position_amount: u64,
        index_price: &AggPrice,
    ): bool {
        let max_size = decimal::mul_with_u64(
            collateral_value,
            config.max_leverage,
        );
        let latest_size = agg_price::coins_to_value(
            index_price,
            position_amount,
        );

        decimal::ge(&max_size, &latest_size)
    }

    public fun check_liquidation(
        config: &PositionConfig,
        collateral_value: Decimal,
        delta_size: &SDecimal,
    ): bool {
        if (sdecimal::is_positive(delta_size)) {
            false
        } else {
            decimal::le(
                &decimal::mul_with_rate(
                    collateral_value,
                    config.liquidation_threshold,
                ),
                &sdecimal::value(delta_size),
            )
        }
    }

    public fun position_size<C>(position: &Position<C>): Decimal {
        position.position_size
    }

    public fun collateral_amount<C>(position: &Position<C>): u64 {
        if(position.legacy) {
            coin::value(option::borrow(&position.collateral_legacy))
        } else {
            primary_fungible_store::balance(account::get_signer_capability_address(option::borrow(&position.collateral_fa)), get_metadata<C>())
        }
    }

    public fun reserved_amount<C>(position: &Position<C>): u64 {
        if(position.legacy) {
            coin::value(option::borrow(&position.reserved_legacy))
        } else {
            primary_fungible_store::balance(account::get_signer_capability_address(option::borrow(&position.reserved_fa)), get_metadata<C>())
        }
    }
    // delta_size = |amount * new_price - size|
    public fun compute_delta_size<C>(
        position: &Position<C>,
        index_price: &AggPrice,
        long: bool,
    ): SDecimal {
        let latest_size = agg_price::coins_to_value(
            index_price,
            position.position_amount,
        );
        let cmp = decimal::gt(&latest_size, &position.position_size);
        let (has_profit, delta) = if (cmp) {
            (long, decimal::sub(latest_size, position.position_size))
        } else {
            (!long, decimal::sub(position.position_size, latest_size))
        };

        sdecimal::from_decimal(has_profit, delta)
    }

    public fun check_holding_duration<C>(
        position: &Position<C>,
        delta_size: &SDecimal,
        timestamp: u64,
    ): bool {
        !sdecimal::is_positive(delta_size)
            || position.open_timestamp
            + position.config.min_holding_duration <= timestamp
    }

    public fun compute_reserving_fee_amount<C>(
        position: &Position<C>,
        reserving_rate: Rate,
    ): Decimal {
        let delta_fee = decimal::mul_with_rate(
            decimal::from_u64(reserved_amount(position)),
            rate::sub(reserving_rate, position.last_reserving_rate),
        );
        decimal::add(position.reserving_fee_amount, delta_fee)
    }

    public fun compute_funding_fee_value<C>(
        position: &Position<C>,
        funding_rate: SRate,
    ): SDecimal {
        let delta_rate = srate::sub(
            funding_rate,
            position.last_funding_rate,
        );
        let delta_fee = sdecimal::from_decimal(
            srate::is_positive(&delta_rate),
            decimal::mul_with_rate(
                position.position_size,
                srate::value(&delta_rate),
            ),
        );
        sdecimal::add(position.funding_fee_value, delta_fee)
    }

    public(friend) fun unwrap_decrease_position_result<Collateral>(res: DecreasePositionResult<Collateral>): (
        bool,
        bool,
        bool,
        u64,
        u64,
        Decimal,
        Decimal,
        Decimal,
        Decimal,
        SDecimal,
        Option<Coin<Collateral>>,
        Option<Coin<Collateral>>,
        Option<FungibleAsset>,
        Option<FungibleAsset>
    ) {
        let DecreasePositionResult {
            legacy,
            closed,
            has_profit,
            settled_amount,
            decreased_reserved_amount,
            decrease_size,
            reserving_fee_amount,
            decrease_fee_value,
            reserving_fee_value,
            funding_fee_value,
            to_vault_legacy,
            to_trader_legacy,
            to_vault_fa,
            to_trader_fa
        } = res;

        (
            legacy,
            closed,
            has_profit,
            settled_amount,
            decreased_reserved_amount,
            decrease_size,
            reserving_fee_amount,
            decrease_fee_value,
            reserving_fee_value,
            funding_fee_value,
            to_vault_legacy,
            to_trader_legacy,
            to_vault_fa,
            to_trader_fa,
        )
    }

}
