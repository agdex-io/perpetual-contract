module perpetual::market {

    use std::signer;
    use std::option;
    use std::string::String;
    use aptos_std::table::{Self, Table};
    use perpetual::rate::{Self, Rate};
    use perpetual::pool::{Self, Symbol, DecreasePositionFailedEvent, DecreasePositionResult};
    use perpetual::model::{Self, ReservingFeeModel, RebaseFeeModel};
    use perpetual::positions::{Self, Position, PositionConfig};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::lp;
    use perpetual::agg_price;
    use perpetual::referral::{Self, Referral};
    use aptos_std::type_info::{Self, TypeInfo};
    use perpetual::orders::{Self, OpenPositionOrder, DecreasePositionOrder};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;
    use pyth::price_identifier;


    struct Market has key {
        vaults_locked: bool,
        symbols_locked: bool,

        rebate_rate: RebaseFeeModel,
        referrals: Table<address, Referral>
    }

    struct WrappedPositionConfig<phantom Index, phantom Direction> has key {
        enabled: bool,
        inner: PositionConfig
    }

    struct PositionsRecord<phantom CoinType> has key {
        positions: Table<u64, Position<CoinType>>
    }

    struct LONG has drop {}

    struct SHORT has drop {}

    struct OrderId<phantom CoinType, phantom Index, phantom Direction, phantom Fee> has store, copy, drop {
        id: u64,
        owner: address
    }

    struct PositionId<phantom CoinType, phantom Index, phantom Direction> has store, copy, drop {
        id: u64,
        owner: address
    }

    struct PositionRecord<phantom CoinType, phantom Index, phantom Direction> has key {
        creation_num: u64,
        positions: Table<PositionId<CoinType, Index, Direction>, Position<CoinType>>
    }

    struct OrderRecord<phantom CoinType, phantom Index, phantom Direction, phantom Fee> has key {
        creation_num: u64,
        open_orders: Table<OrderId<CoinType, Index, Direction, Fee>, OpenPositionOrder<CoinType, Fee>>,
        decrease_orders: Table<OrderId<CoinType, Index, Direction, Fee>, DecreasePositionOrder<Fee>>
    }

    // === Errors ===
    // common errors
    const ERR_FUNCTION_VERSION_EXPIRED: u64 = 1;
    const ERR_MARKET_ALREADY_LOCKED: u64 = 2;
    // referral errors
    const ERR_ALREADY_HAS_REFERRAL: u64 = 3;
    // perpetual trading errors
    const ERR_INVALID_DIRECTION: u64 = 4;
    const ERR_CAN_NOT_CREATE_ORDER: u64 = 5;
    const ERR_CAN_NOT_TRADE_IMMEDIATELY: u64 = 6;
    // deposit, withdraw and swap errors
    const ERR_VAULT_ALREADY_HANDLED: u64 = 7;
    const ERR_SYMBOL_ALREADY_HANDLED: u64 = 8;
    const ERR_VAULTS_NOT_TOTALLY_HANDLED: u64 = 9;
    const ERR_SYMBOLS_NOT_TOTALLY_HANDLED: u64 = 10;
    const ERR_UNEXPECTED_MARKET_VALUE: u64 = 11;
    const ERR_MISMATCHED_RESERVING_FEE_MODEL: u64 = 12;
    const ERR_SWAPPING_SAME_COINS: u64 = 13;

    public(friend) fun create_market(
        admin: &signer,
        rebate_rate: Rate
    ) {
        // create rebase fee model
        let rate = model::create_rebase_fee_model();
        // move market resource to account
        let market = Market {
            vaults_locked: false,
            symbols_locked: false,

            rebate_rate: rate,
            referrals: table::new<address, Referral>()

        };
        move_to(admin, market);
        //TODO: emit event
    }

    public entry fun add_new_vault<Collateral>(
        admin: &signer,
        weight: u256,
        max_interval: u64,
        max_price_confidence: u64,
        feeder: vector<u8>,
        param_multiplier: u256,
    ) {
        let identifier = pyth::price_identifier::from_byte_vec(feeder);
        // create reserving fee model
        let model = model::create_reserving_fee_model(
            decimal::from_raw(param_multiplier));
        // add vault to market
        pool::new_vault<Collateral>(
            admin,
            weight,
            model,
            agg_price::new_agg_price_config<Collateral>(
                max_interval,
                max_price_confidence,
                identifier
            )
        );
        // TODO: emit event
    }

    public entry fun replace_vault_feeder<Collateral>(
        admin: &signer,
        feeder: vector<u8>,
        max_interval: u64,
        max_price_confidence: u64
    ) {
        let identifier = pyth::price_identifier::from_byte_vec(feeder);
        let price_config =
            agg_price::new_agg_price_config<Collateral>(max_interval, max_price_confidence, identifier);
        pool::replace_vault_price_config<Collateral>(admin, price_config);
    }

    public entry fun add_new_symbol<Index, Direction>(
        admin: &signer,
        max_interval: u64,
        max_price_confidence: u64,
        feeder: vector<u8>,
        param_multiplier: u256,
        param_max: u128,
        max_leverage: u64,
        min_holding_duration: u64,
        max_reserved_multiplier: u64,
        min_collateral_value: u256,
        open_fee_bps: u128,
        decrease_fee_bps: u128,
        liquidation_threshold: u128,
        liquidation_bonus: u128
    ) {
        // create funding fee model
        let model = model::create_funding_fee_model(
            decimal::from_raw(param_multiplier),
            rate::from_raw(param_max)
        );
        // create public position config
        move_to(admin, WrappedPositionConfig<Index, Direction>{
            enabled: true,
            inner: positions::new_position_config(
                max_leverage,
                min_holding_duration,
                max_reserved_multiplier,
                min_collateral_value,
                open_fee_bps,
                decrease_fee_bps,
                liquidation_threshold,
                liquidation_bonus
            )
        });
        let identifier = pyth::price_identifier::from_byte_vec(feeder);
        // add symbol to market
        pool::new_symbol<Index, Direction>(admin, model, agg_price::new_agg_price_config<Index>(
            max_interval,
            max_price_confidence,
            identifier
        ));
        // TODO: emit event
    }

    public entry fun replace_symbol_feeder<Index, Direction>(
        admin: &signer,
        feeder: vector<u8>,
        max_interval: u64,
        max_price_confidence: u64
    ) {
        // TODO: amdin permission check
        let identifier = pyth::price_identifier::from_byte_vec(feeder);
        let price_config =
            agg_price::new_agg_price_config<Index>(max_interval, max_price_confidence, identifier);
        pool::replace_symbol_price_config<Index, Direction>(admin, price_config);
        // TODO: emit event
    }

    public entry fun add_collateral_to_symbol<Collateral, Index, Direction>(
        admin: &signer
    ) {
        // TODO: admin permission check
        // pool::add_collateral_to_symbol
        pool::add_collateral_to_symbol<Collateral, Index, Direction>(admin);
        // create record
        if (!exists<PositionRecord<Collateral, Index, Direction>>(@perpetual)){
            move_to(admin, PositionRecord<Collateral, Index, Direction>{
                creation_num: 0,
                positions: table::new<PositionId<Collateral, Index, Direction>, Position<Collateral>>()
            })
        };

        if (!exists<OrderRecord<Collateral, Index, Direction, AptosCoin>>(@perpetual)) {
            move_to(admin, OrderRecord<Collateral, Index, Direction, AptosCoin>{
                creation_num: 0,
                open_orders: table::new<OrderId<Collateral, Index, Direction, AptosCoin>, OpenPositionOrder<Collateral, AptosCoin>>(),
                decrease_orders: table::new<OrderId<Collateral, Index, Direction, AptosCoin>, DecreasePositionOrder<AptosCoin>>()
            })
        };
    }

    public entry fun remove_collateral_from_symbol<Collateral, Index, Direction>(
        admin: &signer
    ) {
        // TODO: admin permission check
        // pool::remove_collateral_to_symbol
        pool::remove_collateral_to_symbol<Collateral, Index, Direction>(admin);
    }

    public entry fun set_symbol_status<Index, Direaction>(
        admin: &signer,
        open_enabled: bool,
        decrease_enabled: bool,
        liquidate_enabled: bool
    ) {
        // TODO: admin permission check
        pool::set_symbol_status<Index, Direaction>(admin, open_enabled, decrease_enabled, liquidate_enabled);

    }

    public entry fun replace_position_config<Index, Direction>(
        admin: &signer,
        max_leverage: u64,
        min_holding_duration: u64,
        max_reserved_multiplier: u64,
        min_collateral_value: u256,
        open_fee_bps: u128,
        decrease_fee_bps: u128,
        liquidation_threshold: u128,
        liquidation_bonus: u128,
    ) acquires WrappedPositionConfig {
        // TODO: admin permission check
        let wrapped_position_config =
            borrow_global_mut<WrappedPositionConfig<Index, Direction>>(signer::address_of(admin));
        let new_positions_config = positions::new_position_config(
                max_leverage,
                min_holding_duration,
                max_reserved_multiplier,
                min_collateral_value,
                open_fee_bps,
                decrease_fee_bps,
                liquidation_threshold,
                liquidation_bonus
            );
        wrapped_position_config.inner = new_positions_config;
    }

    public entry fun open_position<Collateral, Index, Direction, Fee>(
        user: &signer,
        trade_level: u8,
        open_amount: u64,
        reserve_amount: u64,
        collateral_amount: u64,
        fee_amount: u64,
        collateral_price_threshold: u256,
        limited_index_price: u256
    ) acquires Market, WrappedPositionConfig, OrderRecord, PositionRecord {
        let user_account = signer::address_of(user);
        let market = borrow_global_mut<Market>(@perpetual);
        assert!(!market.vaults_locked && !market.symbols_locked, ERR_MARKET_ALREADY_LOCKED);
        let lp_supply_amount = lp_supply_amount();
        let timestamp = timestamp::now_seconds();
        let long = parse_direction<Direction>();

        let collateral_price_threshold = decimal::from_raw(collateral_price_threshold);
        let index_price = agg_price::parse_pyth_feeder(
            &pool::symbol_price_config<Index, Direction>(),
            timestamp
        );
        let limited_index_price = agg_price::from_price(
            &pool::symbol_price_config<Index, Direction>(),
            decimal::from_raw(limited_index_price),
        );

        // check if limited order can be placed
        let placed = if (long) {
            decimal::gt(
                &agg_price::price_of(&index_price),
                &agg_price::price_of(&limited_index_price),
            )
        } else {
            decimal::lt(
                &agg_price::price_of(&index_price),
                &agg_price::price_of(&limited_index_price),
            )
        };

        let position_config =
            borrow_global<WrappedPositionConfig<Index, Direction>>(@perpetual);

        if (placed) {
            assert!(trade_level < 2, ERR_CAN_NOT_CREATE_ORDER);
            let order = orders::new_open_position_order<Collateral, Fee>(
                timestamp,
                open_amount,
                reserve_amount,
                limited_index_price,
                collateral_price_threshold,
                position_config.inner,
                coin::withdraw<Collateral>(user, collateral_amount),
                coin::withdraw<Fee>(user, fee_amount)
            );
            // add order into record
            let order_record =
                borrow_global_mut<OrderRecord<Collateral, Index, Direction, Fee>>(@perpetual);
            table::add(&mut order_record.open_orders, OrderId<Collateral, Index, Direction, Fee>{
                id: order_record.creation_num,
                owner: user_account
            }, order);
            order_record.creation_num = order_record.creation_num + 1;
            // TODO: emit order created event

        } else {
            let (rebate_rate, referrer) = get_referral_data(&market.referrals, user_account);
            let (code, collateral, result, _) = pool::open_position<Collateral, Index, Direction>(
                &position_config.inner,
                coin::withdraw<Collateral>(user, collateral_amount),
                collateral_price_threshold,
                rebate_rate,
                long,
                open_amount,
                reserve_amount,
                lp_supply_amount,
                timestamp,
            );
            coin::deposit(user_account, collateral);
            // should panic when the owner execute the order
            assert!(code == 0, code);
            //coin::destroy_zero(collateral);

            let (position, rebate, event) =
                pool::unwrap_open_position_result<Collateral>(option::destroy_some(result));

            // add position into record
            let position_record =
                borrow_global_mut<PositionRecord<Collateral, Index, Direction>>(@perpetual);
            table::add(&mut position_record.positions, PositionId<Collateral, Index, Direction>{
                id: position_record.creation_num,
                owner: user_account
            }, position);
            position_record.creation_num = position_record.creation_num + 1;

            coin::deposit(referrer, rebate);


            // TODO: emit position opened
            // event::emit(PositionClaimed {
            //     position_name: option::some(position_name),
            //     event,
            // });
        }
    }

    public entry fun decrease_position<Collateral, Index, Direction, Fee>(
        user: &signer,
        trade_level: u8,
        fee_amount: u64,
        take_profit: bool,
        decrease_amount: u64,
        collateral_price_threshold: u256,
        limited_index_price: u256,
        position_num: u64
    ) acquires Market, PositionRecord, OrderRecord {
        let user_account = signer::address_of(user);
        let market = borrow_global_mut<Market>(@perpetual);
        assert!(!market.vaults_locked && !market.symbols_locked, ERR_MARKET_ALREADY_LOCKED);
        let lp_supply_amount = lp_supply_amount();
        let timestamp = timestamp::now_seconds();
        let long = parse_direction<Direction>();

        let collateral_price_threshold = decimal::from_raw(collateral_price_threshold);
        let index_price = agg_price::parse_pyth_feeder(
            &pool::symbol_price_config<Index, Direction>(),
            timestamp
        );
        let limited_index_price = agg_price::from_price(
            &pool::symbol_price_config<Index, Direction>(),
            decimal::from_raw(limited_index_price),
        );
        let position_id = PositionId<Collateral, Index, Direction> {
            id: position_num,
            owner: user_account
        };

        // check if limit order can be placed
        let placed = if (long) {
            decimal::lt(
                &agg_price::price_of(&index_price),
                &agg_price::price_of(&limited_index_price),
            )
        } else {
            decimal::gt(
                &agg_price::price_of(&index_price),
                &agg_price::price_of(&limited_index_price),
            )
        };

        // Decrease order is allowed to create:
        // 1: limit order can be placed
        // 2: limit order can not placed, but it must be a stop loss order
        if (placed || !take_profit) {
            assert!(trade_level < 2, ERR_CAN_NOT_CREATE_ORDER);

            let order = orders::new_decrease_position_order(
                timestamp,
                take_profit,
                decrease_amount,
                limited_index_price,
                collateral_price_threshold,
                coin::withdraw<Fee>(user, fee_amount),
            );
            // add order into record
            let order_record =
                borrow_global_mut<OrderRecord<Collateral, Index, Direction, Fee>>(@perpetual);
            table::add(&mut order_record.decrease_orders, OrderId<Collateral, Index, Direction, Fee>{
                id: order_record.creation_num,
                owner: user_account
            }, order);
            order_record.creation_num = order_record.creation_num + 1;

            //TODO: emit order created
            // event::emit(OrderCreated { order_name, event });
        } else {
            assert!(trade_level > 0, ERR_CAN_NOT_TRADE_IMMEDIATELY);

            let position_record =
                borrow_global_mut<PositionRecord<Collateral, Index, Direction>>(@perpetual);
            let position  = table::borrow_mut(
                &mut position_record.positions,
                position_id
            );

            let (rebate_rate, referrer) = get_referral_data(&market.referrals, user_account);
            let (code, result, _) = pool::decrease_position<Collateral, Index, Direction>(
                position,
                collateral_price_threshold,
                rebate_rate,
                long,
                decrease_amount,
                lp_supply_amount,
                timestamp,
            );
            // should panic when the owner execute the order
            assert!(code == 0, code);

            let res = option::destroy_some(result);
            let (to_trader, rebate, event) =
                pool::unwrap_decrease_position_result<Collateral>(res);

            coin::deposit<Collateral>(user_account, to_trader);
            coin::deposit<Collateral>(referrer, rebate);

            // no need coin operate here
            // transfer::public_transfer(fee, owner);

            //TODO: emit decrease position
            // event::emit(PositionClaimed {
            //     position_name: option::some(position_name),
            //     event,
            // });
        }
    }

    public entry fun decrease_reserved_from_position<Collateral, Index, Direction>(
        user: &signer,
        decrease_amount: u64,
        position_num: u64
    ) acquires PositionRecord {
        let timestamp = timestamp::now_seconds();
        let user_account = signer::address_of(user);

        let position_id = PositionId<Collateral, Index, Direction> {
            id: position_num,
            owner: user_account,
        };

        let position_record =
            borrow_global_mut<PositionRecord<Collateral, Index, Direction>>(@perpetual);
        let position  = table::borrow_mut(
            &mut position_record.positions,
            position_id
        );

        let event = pool::decrease_reserved_from_position(
            position,
            decrease_amount,
            timestamp
        );

        //TODO: emit decrease reserved from position
        // event::emit(PositionClaimed {
        //     position_name: option::some(position_name),
        //     event,
        // });

    }

    public entry fun pledge_in_position<Collateral, Index, Direction>(
        user: &signer,
        pledge_num: u64,
        position_num: u64,
    ) acquires PositionRecord  {
        let user_account = signer::address_of(user);

        let position_id = PositionId<Collateral, Index, Direction> {
            id: position_num,
            owner: user_account
        };
        let position_record =
            borrow_global_mut<PositionRecord<Collateral, Index, Direction>>(@perpetual);
        let position  = table::borrow_mut(
            &mut position_record.positions,
            position_id
        );

        let event = pool::pledge_in_position(position, coin::withdraw<Collateral>(user, pledge_num));

        // TODO: emit pledge in position
        // event::emit(PositionClaimed {
        //     position_name: option::some(position_name),
        //     event,
        // });
    }

    public entry fun redeem_from_position<LP, Collateral, Index, Direction>() {

    }

    public entry fun liquidate_position<LP, Collateral, Index, Direction>() {

    }

    public entry fun clear_closed_position<Lp, Collateral, Index, Direction>() {

    }

    public entry fun execute_open_position_order<LP, Collateral, Index, Direction, Fee>() {

    }

    public entry fun execute_decrease_position_order<LP, Collateral, Index, Direction, Fee>() {

    }

    public entry fun clear_open_position_order<LP, Collateral, Index, Direction, Fee>() {

    }

    public entry fun clear_decrease_position_order<LP, Collateral, Index, Direction, Fee>() {

    }

    public fun deposit<LP, Collateral>() {

    }

    public fun withdraw<LP, Collateral>() {

    }

    public fun swap<LP, Source, Destination>() {

    }

    public fun create_vaults_valuation<LP>() {

    }

    public fun create_symbols_valuation<LP>() {

    }

    public fun valuate_vault<LP, Collateral>() {

    }

    public fun valuate_symbol<LP, Index, Direction>() {

    }

    public fun force_close_position<LP, Collateral, Index, Direction>() {}

    public fun force_clear_closed_position<LP, Collateral, Index, Direction>() {}

    public fun lp_supply_amount(): Decimal {
        // LP decimal is 6
        let supply = lp::get_supply();
        decimal::div_by_u64(
            decimal::from_u128(supply),
            1_000_000,
        )
    }

    public fun parse_direction<Direction>(): bool {
        let direction = type_info::type_of<Direction>();
        if (direction == type_info::type_of<LONG>()) {
            true
        } else {
            assert!(
                direction == type_info::type_of<SHORT>(),
                ERR_INVALID_DIRECTION,
            );
            false
        }
    }

    fun get_referral_data(
        referrals: &Table<address, Referral>,
        owner: address
    ): (Rate, address) {
        if (table::contains(referrals, owner)) {
            let referral = table::borrow(referrals, owner);
            (referral::get_rebate_rate(referral), referral::get_referrer(referral))
        } else {
            (rate::zero(), @0x0)
        }
    }


}
