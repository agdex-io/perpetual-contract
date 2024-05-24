module perpetual::market {

    use std::string::String;
    use aptos_std::table::Table;
    use perpetual::rate::Rate;
    use perpetual::pool::Symbol;


    struct Market<phantom LP> has key {
        vaults_locked: bool,
        symbols_locked: bool,

        rebate_rate: Rate,

        symbols: Table<u64, Symbol>,
        positions: Table<u64, u64>,
        orders: Table<u64, u64>,

        lp_supply: u64,
    }

    struct LONG has drop {}

    struct SHORT has drop {}

    public(friend) fun create_market<LP>(
        account: &signer,
        rebate_rate: Rate
    ) {
        // create rebase fee model
        // move market resource to account
        // emit event
    }

    public entry fun add_new_vault<LP, Collateral>() {
        // create reserving fee model
        // add vault to market
        // emit event
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
