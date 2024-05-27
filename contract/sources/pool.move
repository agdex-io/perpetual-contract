module perpetual::pool {

    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::coin::Coin;
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::model::{FundingFeeModel, ReservingFeeModel};
    use perpetual::sdecimal::{Self, SDecimal};
    use perpetual::positions::{PositionConfig, Position};
    use aptos_std::smart_vector::{Self, SmartVector};
    use aptos_std::type_info::{Self, TypeInfo};
    use perpetual::agg_price::AggPriceConfig;
    use pyth::price;
    use aptos_std::big_vector::borrow;

    friend perpetual::market;

    struct Vault<phantom CoinType> has key, store {
        enabled: bool,
        weight: Decimal,
        last_update: u64,
        liquidity: coin::Coin<CoinType>,
        reserved_amount: u64,
        reserving_fee_model: ReservingFeeModel,
        price_config: AggPriceConfig,
        unrealised_reserving_fee_amount: Decimal,
        acc_reserving_rate: Rate
    }

    struct Symbol<phantom Index, phantom Direction> has key, store {
        open_enabled: bool,
        decrease_enabled: bool,
        liquidate_enabled: bool,
        supported_collaterals: SmartVector<TypeInfo>,
        funding_fee_model: FundingFeeModel,
        price_config: AggPriceConfig,

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

    public(friend) fun new_vault<Collateral>(
        account: &signer,
        weight: u256,
        model: ReservingFeeModel,
        price_config: AggPriceConfig
    ) {
        move_to(account, Vault<Collateral>{
            enabled: true,
            weight: decimal::from_raw(weight),
            last_update: 0,
            liquidity: coin::zero<Collateral>(),
            reserved_amount: 0,
            reserving_fee_model: model,
            price_config,
            unrealised_reserving_fee_amount: decimal::zero(),
            acc_reserving_rate: rate::zero()
        })
    }

    public(friend) fun mut_vault_price_config<Collateral>() {}

    public(friend) fun new_symbol<Index, Direction>(
        admin: &signer,
        model: FundingFeeModel,
        price_config: AggPriceConfig
    ) {
        move_to(admin, Symbol<Index, Direction> {
            open_enabled: true,
            decrease_enabled: true,
            liquidate_enabled: true,
            supported_collaterals: smart_vector::empty(),
            funding_fee_model: model,
            price_config,
            last_update: 0,
            opening_amount: 0,
            opening_size: decimal::zero(),
            realised_pnl: sdecimal::zero(),
            unrealised_funding_fee_value: sdecimal::zero(),
            acc_funding_rate: srate::zero(),
        });
    }

    public(friend) fun replace_symbol_price_config<Index, Direction>(
        admin: &signer,
        price_config: AggPriceConfig
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        symbol.price_config = price_config;
    }

    public(friend) fun add_collateral_to_symbol<Index, Direction, Collateral>(symbol: &mut Symbol<Index, Direction>) {}

    public(friend) fun remove_collateral_to_symbol<Index, Direction, Collateral>(symbol: &mut Symbol<Index, Direction>) {}

    public(friend) fun set_symbol_status<Index, Direction, Collateral>(symbol: &mut Symbol<Index, Direction>) {}

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
