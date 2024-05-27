module perpetual::positions {

    use aptos_framework::coin::Coin;
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::model::{FundingFeeModel};
    use perpetual::sdecimal::{Self, SDecimal};
    use aptos_std::smart_vector::{Self, SmartVector};
    use aptos_std::type_info::{Self, TypeInfo};

    friend perpetual::market;

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
        reserved: u64,
        collateral: Coin<CoinType>,
        order_id: u256 // ?
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

    public(friend) fun open_position<Collateral>() {}

    public(friend) fun decrease_position<Collateral>() {}

    public(friend) fun unwrap_decrease_position_result<Collateral>() {}

    public(friend) fun decrease_reserved_from_position<Collateral>() {}

    public(friend) fun pledge_in_position<Collateral>() {}

    public(friend) fun redeem_from_postion<Collateral>() {}

    public(friend) fun liquidate_position<Collateral>() {}

    public(friend) fun destroy_position<Collateral>() {}
}
