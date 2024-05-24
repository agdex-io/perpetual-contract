module perpetual::pool {

    use aptos_framework::coin;
    use aptos_framework::coin::Coin;
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::model::{FundingFeeModel};
    use perpetual::sdecimal::{Self, SDecimal};
    use perpetual::positions::{PositionConfig, Position};
    use aptos_std::smart_vector::{Self, SmartVector};
    use aptos_std::type_info::{Self, TypeInfo};

    struct Vault<phantom CoinType> has store {
        enabled: bool,
        last_update: Decimal,
        liquidity:coin::Coin<CoinType>,
        reserved_amount: u64,
        unrealised_reserving_fee_amount: Decimal,
        acc_reserving_rate: Rate
    }

    struct Symbol has store {
        open_enabled: bool,
        decrease_enabled: bool,
        liquidate_enabled: bool,
        supported_collaterals: SmartVector<TypeInfo>,
        funding_fee_model: FundingFeeModel,
        price_config: u64, // oracle

        last_update: u64,
        opening_amount: u64,
        opening_size: Decimal,
        realised_pnl: SDecimal,
        unrealised_funding_fee_value: SDecimal,
        acc_funding_rate: SRate,
    }

    // cache state
    struct OpenPositionResult<phantom Collateral> {
        position: Position<Collateral>,
        rebate: Coin<Collateral>,
        //event: OpenPositionSuccessEvent,
    }

    struct DecreasePositionResult<phantom Collateral> {
        to_trader: Coin<Collateral>,
        rebate: Coin<Collateral>,
        //event: DecreasePositionSuccessEvent,
    }

    public(friend) fun new_vault<Collateral>() {}

    public(friend) fun mut_vault_price_config<Collateral>() {}

    public(friend) fun new_symbol() {}

    public(friend) fun mut_symbol_price_config(symbol: &mut Symbol) {}

    public(friend) fun add_collateral_to_symbol<Collateral>(symbol: &mut Symbol) {}

    public(friend) fun remove_collateral_to_symbol<Collateral>(symbol: &mut Symbol) {}

    public(friend) fun set_symbol_status<Collateral>(symbol: &mut Symbol) {}

    public(friend) fun deposit<Collateral>() {}

    public(friend) fun withdraw<Collateral>() {}

    public(friend) fun swap_in<Source>() {}

    public(friend) fun swap_out<Destination>() {}

    public(friend) fun open_position<Collateral>() {}

    public(friend) fun unwrap_open_position_result<Collateral>() {}

    public(friend) fun decrease_position<Collateral>() {}

    public(friend) fun unwrap_decrease_position_result<C>() {}

    public(friend) fun decrease_reserved_from_position<C>() {}

    public(friend) fun pledge_in_position<Collateral>() {}

    public(friend) fun redeem_from_position<Collateral>() {}

    public(friend) fun liquidate_position<Collateral>() {}

    public(friend) fun valuate_vault<Collateral>() {}

    public(friend) fun valuate_symbol() {}




}
