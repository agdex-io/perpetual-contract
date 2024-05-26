module perpetual::market {

    use std::string::String;
    use aptos_std::table::Table;
    use perpetual::rate::{Self, Rate};
    use perpetual::pool::{Self, Symbol};
    use perpetual::model::{Self, ReservingFeeModel, RebaseFeeModel};
    use perpetual::positions::{Position};
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
        account: &signer,
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
        move_to(account, market);
        // emit event
    }

    public entry fun add_new_vault<Collateral>(
        account: &signer,
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
            account,
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

    public entry fun replace_vault_feeder<LP, Collateral>() {

    }

    public entry fun add_new_symbol<LP, Index, Direction>() {
        // create funding fee model
        // create public position config
        // add symbol to market
        // emit event
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
