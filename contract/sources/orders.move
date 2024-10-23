module perpetual::orders {

    use std::bcs;
    use std::vector;
    use std::signer;
    use std::option::{Self, Option};
    use aptos_framework::randomness;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::fungible_asset::FungibleAsset;
    use perpetual::type_registry::{Self, get_metadata};
    use perpetual::rate::{Rate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::positions::{Position, PositionConfig};
    use perpetual::agg_price::{AggPrice};
    use perpetual::pool::{Self, OpenPositionResult, DecreasePositionResult,
        OpenPositionFailedEvent, DecreasePositionFailedEvent} ;
    use perpetual::agg_price;

    friend perpetual::market;

    const ERR_ORDER_ALREADY_EXECUTED: u64 = 40001;
    const ERR_INDEX_PRICE_NOT_TRIGGERED: u64 = 40002;

    struct OpenPositionOrder<phantom CoinType, phantom Fee> has store {
        executed: bool,
        created_at: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        position_config: PositionConfig,
        collateral_legacy: Option<Coin<CoinType>>,
        fee_legacy: Option<Coin<Fee>>,
        collateral_store_cap: Option<SignerCapability>,
        fee_store_cap: Option<SignerCapability>
    }

    struct DecreasePositionOrder<phantom CoinType> has store {
        executed: bool,
        created_at: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        fee_legacy: Option<Coin<CoinType>>,
        fee_store_cap: Option<SignerCapability>,
        position_num: u64
    }

    // === Events ===

    struct CreateOpenPositionOrderEvent has copy, drop {
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: Decimal,
        collateral_price_threshold: Decimal,
        position_config: PositionConfig,
        collateral_amount: u64,
        fee_amount: u64,
    }

    struct CreateDecreasePositionOrderEvent has copy, drop {
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: Decimal,
        collateral_price_threshold: Decimal,
        fee_amount: u64,
    }

    public(friend) fun new_open_position_order<Collateral, Fee>(
        user: &signer,
        timestamp: u64,
        open_amount: u64,
        reserve_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        position_config: PositionConfig,
        collateral_legacy: Option<Coin<Collateral>>,
        fee_legacy: Option<Coin<Fee>>,
        collateral_fa: Option<FungibleAsset>,
        fee_fa: Option<FungibleAsset>
    ): OpenPositionOrder<Collateral, Fee> {
        let collateral_store_cap = if (type_registry::registered<Collateral>()) {
            let (collateral_signer, collateral_cap) = generate_resource_account<Collateral>(user, timestamp);
            primary_fungible_store::deposit(signer::address_of(&collateral_signer), option::destroy_some(collateral_fa));
            option::some(collateral_cap)
        } else {
            option::destroy_none(collateral_fa);
            option::none<SignerCapability>()
        };
        let fee_store_cap = if (type_registry::registered<Fee>()) {
            let (fee_signer, fee_cap) = generate_resource_account<Fee>(user, timestamp);
            primary_fungible_store::deposit(signer::address_of(&fee_signer), option::destroy_some(fee_fa));
            option::some(fee_cap)
        } else {
            option::destroy_none(fee_fa);
            option::none<SignerCapability>()
        };

        let order = OpenPositionOrder<Collateral, Fee> {
            executed: false,
            created_at: timestamp,
            open_amount,
            reserve_amount,
            limited_index_price,
            collateral_price_threshold,
            position_config,
            collateral_legacy,
            fee_legacy,
            collateral_store_cap,
            fee_store_cap
        };
        order
    }

    public fun open_amount_of<Collateral, Fee>(order: &OpenPositionOrder<Collateral, Fee>): u64 {
        order.open_amount
    }
    public fun decrease_open_amount_of<Fee>(order: &DecreasePositionOrder<Fee>): u64 {
        order.decrease_amount
    }

    public(friend) fun new_decrease_position_order<Fee>(
        user: &signer,
        timestamp: u64,
        take_profit: bool,
        decrease_amount: u64,
        limited_index_price: AggPrice,
        collateral_price_threshold: Decimal,
        fee_legacy: Option<Coin<Fee>>,
        fee_fa: Option<FungibleAsset>,
        position_num: u64
    ): DecreasePositionOrder<Fee> {
        // let event = CreateDecreasePositionOrderEvent {
        //     take_profit,
        //     decrease_amount,
        //     limited_index_price: agg_price::price_of(&limited_index_price),
        //     collateral_price_threshold,
        //     fee_amount: balance::value(&fee),
        // };
        let fee_store_cap = if (type_registry::registered<Fee>()) {
            let (fee_signer, fee_cap) = generate_resource_account<Fee>(user, timestamp);
            primary_fungible_store::deposit(signer::address_of(&fee_signer), option::destroy_some(fee_fa));
            option::some(fee_cap)
        } else {
            option::destroy_none(fee_fa);
            option::none<SignerCapability>()
        };
        let order = DecreasePositionOrder {
            executed: false,
            created_at: timestamp,
            take_profit,
            decrease_amount,
            limited_index_price,
            collateral_price_threshold,
            fee_legacy,
            fee_store_cap,
            position_num
        };

        // (order, event)
        order
    }

    fun generate_resource_account<Collateral>(user: &signer, timestamp: u64): (signer, SignerCapability) {
        let seed = randomness::bytes(1);
        vector::append(&mut seed, bcs::to_bytes<u64>(&timestamp));
        primary_fungible_store::ensure_primary_store_exists(signer::address_of(user), get_metadata<Collateral>());
        account::create_resource_account(user, seed)
    }

    public(friend) fun execute_open_position_order<Collateral, Index, Direction, Fee>(
        order: &mut OpenPositionOrder<Collateral, Fee>,
        rebate_rate: Rate,
        long: bool,
        lp_supply_amount: Decimal,
        timestamp: u64,
        treasury_address: address,
        treasury_ratio: Rate
    ): (
        u64,
        Option<Coin<Collateral>>,
        Option<FungibleAsset>,
        Option<OpenPositionResult<Collateral>>,
        Option<OpenPositionFailedEvent>,
        Option<Coin<Fee>>,
        Option<FungibleAsset>
    ) {
        assert!(!order.executed, ERR_ORDER_ALREADY_EXECUTED);
        let index_price = agg_price::parse_config(
            &pool::symbol_price_config<Index, Direction>(),
            timestamp
        );
        if (long) {
            assert!(
                decimal::le(&agg_price::price_of(&index_price), &agg_price::price_of(&order.limited_index_price)),
                ERR_INDEX_PRICE_NOT_TRIGGERED,
            );
        } else {
            assert!(
                decimal::ge(&agg_price::price_of(&index_price), &agg_price::price_of(&order.limited_index_price)),
                ERR_INDEX_PRICE_NOT_TRIGGERED,
            );
        };

        // update order status
        order.executed = true;
        // withdraw fee
        let(fee_legacy, fee_fa) = if (type_registry::registered<Fee>()) {
            // fa
            let s = account::create_signer_with_capability(option::borrow(&order.fee_store_cap));
            let amount = primary_fungible_store::balance(signer::address_of(&s), get_metadata<Fee>());
            let fee = primary_fungible_store::withdraw(&s, get_metadata<Fee>(), amount);
            (option::none<Coin<Fee>>(), option::some(fee))
        } else {
            // legacy
            let fee = coin::extract_all<Fee>(option::borrow_mut(&mut order.fee_legacy));
            (option::some(fee), option::none<FungibleAsset>())
        };

        // open position in pool

        let (code, collateral_legacy, collateral_fa, result, failure) = if (type_registry::registered<Collateral>()) {
            // fa
            let s = account::create_signer_with_capability(option::borrow(&order.collateral_store_cap));
            let amount = primary_fungible_store::balance(signer::address_of(&s), get_metadata<Collateral>());
            let collateral = primary_fungible_store::withdraw(&s, get_metadata<Collateral>(), amount);
            let (code, collateral, result, failure) = pool::open_position_fa<Collateral, Index, Direction>(
                &order.position_config,
                collateral,
                order.collateral_price_threshold,
                rebate_rate,
                long,
                order.open_amount,
                order.reserve_amount,
                lp_supply_amount,
                timestamp,
                treasury_address,
                treasury_ratio
            );
            (code, option::none<Coin<Collateral>>(), option::some(collateral), result, failure)
        } else {
            // legacy
            let (code, collateral, result, failure) = pool::open_position_legacy<Collateral, Index, Direction>(
                &order.position_config,
                option::extract(&mut order.collateral_legacy),
                order.collateral_price_threshold,
                rebate_rate,
                long,
                order.open_amount,
                order.reserve_amount,
                lp_supply_amount,
                timestamp,
                treasury_address,
                treasury_ratio
            );
            (code, option::some(collateral), option::none<FungibleAsset>(), result, failure)

        };

        (code, collateral_legacy, collateral_fa, result, failure, fee_legacy, fee_fa)
    }

    public(friend) fun execute_decrease_position_order<Collateral, Index, Direction, Fee>(
        order: &mut DecreasePositionOrder<Fee>,
        position: &mut Position<Collateral>,
        rebate_rate: Rate,
        long: bool,
        lp_supply_amount: Decimal,
        timestamp: u64,
        treasury_address: address,
        treasury_ratio: Rate
    ): (u64, Option<DecreasePositionResult<Collateral>>, Option<DecreasePositionFailedEvent>, Option<Coin<Fee>>, Option<FungibleAsset>) {
        assert!(!order.executed, ERR_ORDER_ALREADY_EXECUTED);
        let index_price = agg_price::parse_config(
            &pool::symbol_price_config<Index, Direction>(),
            timestamp
        );
        if ((long && order.take_profit) || (!long && !order.take_profit)) {
            assert!(
                decimal::ge(
                    &agg_price::price_of(&index_price),
                    &agg_price::price_of(&order.limited_index_price),
                ),
                ERR_INDEX_PRICE_NOT_TRIGGERED,
            );
        } else {
            assert!(
                decimal::le(
                    &agg_price::price_of(&index_price),
                    &agg_price::price_of(&order.limited_index_price),
                ),
                ERR_INDEX_PRICE_NOT_TRIGGERED,
            );
        };

        // update order status
        order.executed = true;
        // withdraw fee
        let (fee_legacy, fee_fa) = if(type_registry::registered<Fee>()) {
            // fa
            let s = account::create_signer_with_capability(option::borrow(&order.fee_store_cap));
            let amount = primary_fungible_store::balance(signer::address_of(&s), get_metadata<Fee>());
            let fee = primary_fungible_store::withdraw(&s, get_metadata<Fee>(), amount);
            (option::none<Coin<Fee>>(), option::some(fee))
        } else {
            // legacy
            let fee = option::extract(&mut order.fee_legacy);
            (option::some(fee), option::none<FungibleAsset>())
        };
        // decrease position in pool
        let (code, result, failure) =
            pool::decrease_position<Collateral, Index, Direction>(
                position,
                order.collateral_price_threshold,
                rebate_rate,
                long,
                order.decrease_amount,
                lp_supply_amount,
                timestamp,
                treasury_address,
                treasury_ratio
        );

        (code, result, failure, fee_legacy, fee_fa)
    }

    public(friend) fun destroy_open_position_order<Collateral, Fee>(
        order: OpenPositionOrder<Collateral, Fee>
    ): (Option<Coin<Collateral>>, Option<FungibleAsset>, Option<Coin<Fee>>, Option<FungibleAsset>) {
        let OpenPositionOrder {
            executed: _,
            created_at: _,
            open_amount: _,
            reserve_amount: _,
            limited_index_price: _,
            collateral_price_threshold: _,
            position_config: _,
            collateral_legacy,
            fee_legacy,
            collateral_store_cap,
            fee_store_cap,
        } = order;
        let (collateral_legacy, collateral_fa) = if (type_registry::registered<Collateral>()) {
            let s = account::create_signer_with_capability(&option::destroy_some(collateral_store_cap));
            let amount = primary_fungible_store::balance(signer::address_of(&s), get_metadata<Collateral>());
            let collateral = primary_fungible_store::withdraw(&s, get_metadata<Collateral>(), amount);
            option::destroy_none(collateral_legacy);
            (option::none<Coin<Collateral>>(), option::some(collateral))
        } else {
            let collateral = option::destroy_some(collateral_legacy);
            option::destroy_none(collateral_store_cap);
            (option::some(collateral), option::none<FungibleAsset>())

        };
        let (fee_legacy, fee_fa) = if (type_registry::registered<Fee>()) {
            let s = account::create_signer_with_capability(&option::destroy_some(fee_store_cap));
            let amount = primary_fungible_store::balance(signer::address_of(&s), get_metadata<Fee>());
            let fee = primary_fungible_store::withdraw(&s, get_metadata<Fee>(), amount);
            option::destroy_none(fee_legacy);
            (option::none<Coin<Fee>>(), option::some(fee))
        } else {
            let fee = option::destroy_some(fee_legacy);
            option::destroy_none(fee_store_cap);
            (option::some(fee), option::none<FungibleAsset>())
        };

        (collateral_legacy, collateral_fa, fee_legacy, fee_fa)
    }

    public(friend) fun destory_decrease_position_order<Fee>(
        order: DecreasePositionOrder<Fee>
    ): (Option<Coin<Fee>>, Option<FungibleAsset>) {
        let DecreasePositionOrder {
            executed: _,
            created_at: _,
            take_profit: _,
            decrease_amount: _,
            limited_index_price: _,
            collateral_price_threshold: _,
            fee_legacy,
            fee_store_cap,
            position_num: _
        } = order;
        let fee_fa = if (type_registry::registered<Fee>()) {
            let s = account::create_signer_with_capability(&option::destroy_some(fee_store_cap));
            let amount = primary_fungible_store::balance(signer::address_of(&s), get_metadata<Fee>());
            let fee = primary_fungible_store::withdraw(&s, get_metadata<Fee>(), amount);
            option::some(fee)
        } else {
            option::none<FungibleAsset>()
        };

        (fee_legacy, fee_fa)
    }


}
