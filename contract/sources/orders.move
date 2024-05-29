module perpetual::orders {

    use aptos_framework::coin::Coin;
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::sdecimal::{Self, SDecimal};
    use perpetual::positions::{PositionConfig};
    use perpetual::agg_price::{AggPrice};

    friend perpetual::market;

    struct OpenPositionOrder<phantom CoinType, phantom Fee> has store {
        executed: bool,
        created_at: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        position_config: PositionConfig,
        collateral: Coin<CoinType>,
        fee: Coin<Fee>,
    }

    struct DecreasePositionOrder<phantom CoinType> has store {
        executed: bool,
        created_at: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        fee: Coin<CoinType>,
    }

    public(friend) fun new_open_position_order<Collateral, Fee>(
        timestamp: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        position_config: PositionConfig,
        collateral: Coin<Collateral>,
        fee: Coin<Fee>,
    ): OpenPositionOrder<Collateral, Fee> {
        let order = OpenPositionOrder<Collateral, Fee> {
            executed: false,
            created_at: timestamp,
            open_amount,
            reserve_amount,
            limited_index_price,
            collateral_price_threshold,
            position_config,
            collateral,
            fee
        };
        order
    }


    public(friend) fun new_decrease_position_order<Fee>(
        timestamp: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        fee: Coin<Fee>,
    ): DecreasePositionOrder<Fee> {
        // let event = CreateDecreasePositionOrderEvent {
        //     take_profit,
        //     decrease_amount,
        //     limited_index_price: agg_price::price_of(&limited_index_price),
        //     collateral_price_threshold,
        //     fee_amount: balance::value(&fee),
        // };
        let order = DecreasePositionOrder {
            executed: false,
            created_at: timestamp,
            take_profit,
            decrease_amount,
            limited_index_price,
            collateral_price_threshold,
            fee,
        };

        // (order, event)
        order
    }

    public(friend) fun execute_open_position_order<Collateral, Fee>() {}

    public(friend) fun destroy_open_position_order<Collateral, Fee>() {}

    public(friend) fun execute_decrease_position_order<Collateral, Fee>() {}

    public(friend) fun destory_decrease_position_order<Fee>() {}


}
