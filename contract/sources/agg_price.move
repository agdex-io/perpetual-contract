module perpetual::agg_price {
    use std::option;
    use aptos_std::math64::pow;
    use aptos_framework::coin;

    use pyth::pyth::get_price_unsafe;
    use pyth::i64::{Self as pyth_i64};
    use pyth::price::{Self as pyth_price};

    use switchboard::aggregator; // For reading aggregators
    use switchboard::math;

    use supra_holder::svalue_feed_holder; // For reading aggregators

    use perpetual::decimal::{Self, Decimal};
    use pyth::price_identifier::PriceIdentifier;
    
    friend perpetual::market;

    enum SecondaryFeed has copy, drop, store {
        SwitchBorad{oracle_holder: address},
        Supra{oracle_holder: address, feed: u32}
    }

    struct AggPrice has drop, store, copy {
        price: Decimal,
        precision: u64,
    }

    // second feeder option for double oracle
    struct AggPriceConfig has copy, store, drop {
        max_interval: u64,
        max_confidence: u64,
        precision: u64,
        feeder: PriceIdentifier,
        second_feeder: option::Option<SecondaryFeed>,
        tolerance: Decimal
    }

    const ERR_INVALID_PRICE_FEEDER: u64 = 50001;
    const ERR_PRICE_STALED: u64 = 50002;
    const ERR_EXCEED_PRICE_CONFIDENCE: u64 = 50003;
    const ERR_INVALID_PRICE_VALUE: u64 = 50004;
    const ESECOND_FEEDER_NOT_EXIST: u64 = 50005;
    const ENOT_SUPRA_FEEDER: u64 = 50006;
    const ENOT_SWITCHBOARD_FEEDER: u64 = 50006;
    const EDOUBLE_ORACLE_TOLERANCE_FAIL: u64 = 50007;

    public(friend) fun new_agg_price_config<CoinType>(
        max_interval: u64,
        max_confidence: u64,
        identifier: PriceIdentifier,
    ): AggPriceConfig {
        AggPriceConfig {
            max_interval,
            max_confidence,
            precision: pow(10, (coin::decimals<CoinType>() as u64)),
            feeder: identifier,
            second_feeder: option::none<SecondaryFeed>(),
            tolerance: decimal::one()
        }
    }

    public(friend) fun update_agg_price_config_feeder(
        config: &mut AggPriceConfig,
        feeder: PriceIdentifier,
    ) {
        config.feeder = feeder;
    }

    public(friend) fun update_seconde_feeder_switchboard(
        config: &mut AggPriceConfig,
        feed: address,
        tolerance: u64
    ) {
        let second_feeder = SecondaryFeed::SwitchBorad{
            oracle_holder: feed,
        };
        option::swap_or_fill(&mut config.second_feeder, second_feeder);
        config.tolerance = decimal::from_u64(tolerance);
    }

    public(friend) fun update_seconde_feeder_supra(
        config: &mut AggPriceConfig,
        oracle_holder: address,
        feed: u32,
        tolerance: u64
    ) {
        let second_feeder = SecondaryFeed::Supra{
            oracle_holder,
            feed,
        };
        option::swap_or_fill(&mut config.second_feeder, second_feeder);
        config.tolerance = decimal::from_u64(tolerance);
    }

    public fun from_price(config: &AggPriceConfig, price: Decimal): AggPrice {
        AggPrice { price, precision: config.precision }
    }

    public fun parse_config(
        config: &AggPriceConfig,
        timestamp: u64,
    ): AggPrice {
        let pyth_price = parse_pyth_feeder(config, timestamp);
        if (!option::is_some(&config.second_feeder)) {
            pyth_price
        } else {
            let second_feed = option::borrow(&config.second_feeder);
            let second_agg_price = if (second_feed is SecondaryFeed::SwitchBorad) {
                parse_switchboard_feeder(config, timestamp)
            } else {
                parse_switchboard_feeder(config, timestamp)
            };
            if (decimal::gt(&pyth_price.price, &second_agg_price.price)) {
                assert!(decimal::gt(
                    &decimal::div(second_agg_price.price, pyth_price.price),
                        &config.tolerance
                ), EDOUBLE_ORACLE_TOLERANCE_FAIL);
            } else {
                assert!(decimal::gt(
                        &decimal::div(pyth_price.price, second_agg_price.price),
                    &config.tolerance
                ), EDOUBLE_ORACLE_TOLERANCE_FAIL);
            };
            pyth_price
        }
    }

    public fun parse_pyth_feeder(
        config: &AggPriceConfig,
        timestamp: u64,
    ): AggPrice {

        let price = get_price_unsafe(config.feeder);
        assert!(
            pyth_price::get_timestamp(&price) + config.max_interval >= timestamp,
            ERR_PRICE_STALED,
        );
        
        assert!(
            pyth_price::get_conf(&price) <= config.max_confidence,
            ERR_EXCEED_PRICE_CONFIDENCE,
        );
        
        let value = pyth_price::get_price(&price);
        // price can not be negative
        let value = pyth_i64::get_magnitude_if_positive(&value);
        // price can not be zero
        assert!(value > 0, ERR_INVALID_PRICE_VALUE);

        let exp = pyth_price::get_expo(&price);
        let price = if (pyth_i64::get_is_negative(&exp)) {
            let exp = pyth_i64::get_magnitude_if_negative(&exp);
            decimal::div_by_u64(decimal::from_u64(value), pow(10, (exp as u64)))
        } else {
            let exp = pyth_i64::get_magnitude_if_positive(&exp);
            decimal::mul_with_u64(decimal::from_u64(value), pow(10, (exp as u64)))
        };

        AggPrice { price, precision: config.precision}
    }

    public fun parse_supra_feeder(
        config: &AggPriceConfig,
        timestamp: u64,
    ): AggPrice {

        assert!(option::is_some(&config.second_feeder), ESECOND_FEEDER_NOT_EXIST);
        let second_feeder = option::borrow(&config.second_feeder);
        assert!(second_feeder is SecondaryFeed::Supra, ENOT_SUPRA_FEEDER);
        let (value, exp, update_timestamp, _round) = svalue_feed_holder::get_price(second_feeder.oracle_holder, second_feeder.feed);
        assert!(
            (update_timestamp as u64) + config.max_interval >= timestamp,
            ERR_PRICE_STALED,
        );

        // assert!(
        //     pyth_price::get_conf(&price) <= config.max_confidence,
        //     ERR_EXCEED_PRICE_CONFIDENCE,
        // );

        // price can not be zero
        assert!(value > 0, ERR_INVALID_PRICE_VALUE);

        let price = decimal::div_by_u64(decimal::from_u128(value), pow(10, (exp as u64)));

        AggPrice { price, precision: config.precision}
    }

    public fun parse_switchboard_feeder(
        config: &AggPriceConfig,
        timestamp: u64,
    ): AggPrice {

        assert!(option::is_some(&config.second_feeder), ESECOND_FEEDER_NOT_EXIST);
        let second_feeder = option::borrow(&config.second_feeder);
        assert!(second_feeder is SecondaryFeed::SwitchBorad, ENOT_SWITCHBOARD_FEEDER);
        let price = aggregator::latest_value(second_feeder.oracle_holder);
        let (value, exp, _neg) = math::unpack(price);
        assert!(
            aggregator::latest_round_timestamp(second_feeder.oracle_holder) + config.max_interval >= timestamp,
            ERR_PRICE_STALED,
        );

        // assert!(
        //     pyth_price::get_conf(&price) <= config.max_confidence,
        //     ERR_EXCEED_PRICE_CONFIDENCE,
        // );

        // price can not be zero
        assert!(value > 0, ERR_INVALID_PRICE_VALUE);

        let price = decimal::div_by_u64(decimal::from_u128(value), pow(10, (exp as u64)));

        AggPrice { price, precision: config.precision}
    }

    public fun price_of(self: &AggPrice): Decimal {
        self.price
    }

    public fun precision_of(self: &AggPrice): u64 {
        self.precision
    }

    public fun coins_to_value(self: &AggPrice, amount: u64): Decimal {
        decimal::div_by_u64(
            decimal::mul_with_u64(self.price, amount),
            self.precision,
        )
    }

    public fun value_to_coins(self: &AggPrice, value: Decimal): Decimal {
        decimal::div(
            decimal::mul_with_u64(value, self.precision),
            self.price,
        )
    }

    #[test_only]
    public fun test_agg_price(price: Decimal, precision: u64): AggPrice {
        AggPrice { price, precision }
    }
}