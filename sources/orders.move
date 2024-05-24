module perpetual::orders {

    use aptos_framework::coin::Coin;
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::sdecimal::{Self, SDecimal};
    use perpetual::positions::{PositionConfig};

    struct OpenPositionOrder<phantom CoinType> has store {
        executed: bool,
        created_at: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: Decimal,
        collateral_price_threshold: Decimal,
        position_config: PositionConfig,
        collateral: Coin<CoinType>,
        fee: Coin<CoinType>,
    }

    struct DecreasePositionOrder<phantom CoinType> has store {
        executed: bool,
        created_at: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: Decimal,
        collateral_price_threshold: Decimal,
        fee: Coin<CoinType>,
    }

    public(friend) fun new_open_position_order<Collateral, Fee>() {}

    public(friend) fun new_decrease_position_order<Fee>() {}

    public(friend) fun execute_open_position_order<Collateral, Fee>() {}

    public(friend) fun destroy_open_position_order<Collateral, Fee>() {}

    public(friend) fun execute_decrease_position_order<Collateral, Fee>() {}

    public(friend) fun destory_decrease_position_order<Fee>() {}


}
