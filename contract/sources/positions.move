module perpetual::positions {

    use std::option::{Self, Option};
    use aptos_framework::coin::{Self, Coin};
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::model::{FundingFeeModel};
    use perpetual::agg_price::{Self, AggPrice, AggPriceConfig};
    use perpetual::sdecimal::{Self, SDecimal};
    use aptos_std::smart_vector::{Self, SmartVector};
    use aptos_std::type_info::{Self, TypeInfo};

    friend perpetual::market;
    friend perpetual::pool;

    const OK: u64 = 0;

    const ERR_ALREADY_CLOSED: u64 = 1;
    const ERR_POSITION_NOT_CLOSED: u64 = 2;
    const ERR_INVALID_PLEDGE: u64 = 3;
    const ERR_INVALID_REDEEM_AMOUNT: u64 = 4;
    const ERR_INVALID_OPEN_AMOUNT: u64 = 5;
    const ERR_INVALID_DECREASE_AMOUNT: u64 = 6;
    const ERR_INSUFFICIENT_COLLATERAL: u64 = 7;
    const ERR_INSUFFICIENT_RESERVED: u64 = 8;
    const ERR_COLLATERAL_VALUE_TOO_LESS: u64 = 9;
    const ERR_HOLDING_DURATION_TOO_SHORT: u64 = 10;
    const ERR_LEVERAGE_TOO_LARGE: u64 = 11;
    const ERR_LIQUIDATION_TRIGGERED: u64 = 12;
    const ERR_LIQUIDATION_NOT_TRIGGERED: u64 = 13;
    const ERR_EXCEED_MAX_RESERVED: u64 = 14;
    const ERR_COLLATERAL_PRICE_EXCEED_THRESHOLD: u64 = 15;

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
        closed: bool,
        config: PositionConfig,
        open_timestamp: u64,
        position_amount: u64,
        position_size: Decimal,
        reserving_fee_amount: Decimal,
        funding_fee_value: SDecimal,
        last_reserving_rate: Rate,
        last_funding_rate: SRate,
        reserved: Coin<CoinType>,
        collateral: Coin<CoinType>,
    }

    struct OpenPositionResult<phantom Collateral> {
        position: Position<Collateral>,
        open_fee: Coin<Collateral>,
        open_fee_amount: Decimal,
    }

    struct DecreasePositionResult<phantom Collateral> {
        closed: bool,
        has_profit: bool,
        settled_amount: u64,
        decreased_reserved_amount: u64,
        decrease_size: Decimal,
        reserving_fee_amount: Decimal,
        decrease_fee_value: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        to_vault: Coin<Collateral>,
        to_trader: Coin<Collateral>,
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

        // construct position
        let position = Position {
            closed: false,
            config: *config,
            open_timestamp: timestamp,
            position_amount: open_amount,
            position_size: open_size,
            reserving_fee_amount: decimal::zero(),
            funding_fee_value: sdecimal::zero(),
            last_reserving_rate: reserving_rate,
            last_funding_rate: funding_rate,
            reserved: coin::extract(liquidity, reserve_amount),
            collateral: coin::extract_all(collateral),
        };

        let result = OpenPositionResult {
            position,
            open_fee,
            open_fee_amount: open_fee_amount_dec,
        };
        (OK, option::some(result))
    }

    public(friend) fun decrease_position<Collateral>() {}

    public(friend) fun unwrap_open_position_result<C>(
        res: OpenPositionResult<C>,
    ): (Position<C>, Coin<C>, Decimal) {
        let OpenPositionResult { position, open_fee, open_fee_amount } = res;

        (position, open_fee, open_fee_amount)
    }

    public(friend) fun decrease_reserved_from_position<Collateral>() {}

    public(friend) fun pledge_in_position<Collateral>() {}

    public(friend) fun redeem_from_postion<Collateral>() {}

    public(friend) fun liquidate_position<Collateral>() {}

    public(friend) fun destroy_position<Collateral>() {}

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
        coin::value(&position.collateral)
    }
}
