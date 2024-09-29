module perpetual::agg_price {
    use aptos_std::math64::pow;
    use aptos_framework::coin;
    use perpetual::rate::diff;

    use pyth::pyth::get_price_unsafe;
    use pyth::i64::{Self as pyth_i64};
    use pyth::price::{Self as pyth_price};
    use pyth::price_identifier;

    use perpetual::decimal::{Self, Decimal};
    use pyth::price_identifier::PriceIdentifier;
    use stapt_oracle::oracle::{stapt_usd_price, stapt_usd_price_decimal};
    
    friend perpetual::market;

    const ST_APT_PRICE_ID: vector<u8> = x"8a893dd9285c274e9e903d45269dff8f258d471046aba3c7c5037d2609877931";

    const EST_APT_PRICE_BEYOND_TOLERANCE: u64 = 50001;

    struct AggPrice has drop, store, copy {
        price: Decimal,
        precision: u64,
    }

    struct AggPriceConfig has copy, store, drop {
        max_interval: u64,
        max_confidence: u64,
        precision: u64,
        feeder: PriceIdentifier,
    }

    const ERR_INVALID_PRICE_FEEDER: u64 = 50001;
    const ERR_PRICE_STALED: u64 = 50002;
    const ERR_EXCEED_PRICE_CONFIDENCE: u64 = 50003;
    const ERR_INVALID_PRICE_VALUE: u64 = 50004;

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
        }
    }

    public(friend) fun update_agg_price_config_feeder(
        config: &mut AggPriceConfig,
        feeder: PriceIdentifier,
    ) {
        config.feeder = feeder;
    }

    public fun from_price(config: &AggPriceConfig, price: Decimal): AggPrice {
        AggPrice { price, precision: config.precision }
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

        if(price_identifier::get_bytes(&config.feeder) == ST_APT_PRICE_ID) {
            let st_apt_price_decimal =
                decimal::div_by_u64(decimal::from_u64(stapt_usd_price()), stapt_usd_price_decimal());
            // TODO: config into agg_price
            assert!(judge_tolerance(
                price,
                st_apt_price_decimal,
                decimal::div(decimal::from_u64(90), decimal::from_u64((100)))
            ), EST_APT_PRICE_BEYOND_TOLERANCE);
        };

        AggPrice { price, precision: config.precision}
    }

    fun judge_tolerance(price_a: Decimal, price_b: Decimal, tolerance: Decimal): bool {
        let diff_rate = decimal::div(price_a, price_b);
        let one_hundread_percent = decimal::from_u64(1);
        if (decimal::ge(&one_hundread_percent, &diff_rate)) {
            let tolerance_rate = decimal::sub(one_hundread_percent, tolerance);
            return decimal::ge(&tolerance_rate, &diff_rate)
        } else {
            let tolerance_rate = decimal::add(one_hundread_percent, tolerance);
            return decimal::ge(&tolerance_rate, &diff_rate)
        }
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