module perpetual::market {

    use std::string::String;
    use aptos_std::table::Table;
    use perpetual::rate::{Self, Rate};
    use perpetual::pool::{Self, Symbol};
    use perpetual::model::{Self, ReservingFeeModel, RebaseFeeModel};
    use perpetual::positions::{Self, Position, PositionConfig};
    use perpetual::decimal;
    use perpetual::agg_price;
    use aptos_std::type_info::TypeInfo;
    use perpetual::orders::{Self, OpenPositionOrder, DecreasePositionOrder};
    use aptos_framework::coin::Coin;
    use pyth::price_identifier;


    struct Market has key {
        vaults_locked: bool,
        symbols_locked: bool,

        rebate_rate: RebaseFeeModel,

        lp_supply: u64,
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
        open_orders: Table<OrderId<CoinType, Index, Direction, Fee>, OpenPositionOrder<CoinType>>,
        decrease_orders: Table<OrderId<CoinType, Index, Direction, Fee>, DecreasePositionOrder<CoinType>>
    }

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

            lp_supply: 0,
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

    public entry fun replace_vault_feeder<Collateral>() {

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
        pool::new_symbol(admin, model, agg_price::new_agg_price_config<Index>(
            max_interval,
            max_price_confidence,
            identifier
        ));
        // TODO: emit event
    }

    public entry fun replace_symbol_feeder<LP, Index, Direction>() {

    }

    public entry fun add_collateral_to_symbol<LP, Collateral, Index, Direction>() {
        // get symbol
        // pool::add_collateral_to_symbol

    }

    public entry fun remove_collateral_from_symbol<LP, Collateral, Index, Direaction>() {
        // get symbol
        // pool::remove_collateral_to_symbol

    }

    public entry fun set_symbol_status<LP, Index, Direaction>() {

    }

    public entry fun replace_position_config<Index, Direction>() {

    }

    public entry fun add_new_referral<Index, Direction>() {

    }

    public entry fun open_position<LP, Collateral, Index, Direaction, Fee>() {

    }

    public entry fun decrease_position<LP, Collateral, Index, Direction, Fee>() {

    }

    public entry fun decrease_reserved_from_position<LP, Collateral, Index, Direction>() {

    }

    public entry fun pledge_in_position<LP, Collatreal, Index, Direction>() {

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


}
