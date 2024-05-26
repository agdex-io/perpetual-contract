module perpetual::model {

    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::sdecimal::{Self, SDecimal};

    friend perpetual::market;

    struct RebaseFeeModel has store {
        base: Rate,
        multiplier: Decimal,
    }

    struct ReservingFeeModel has store {
        multiplier: Decimal,
    }

    struct FundingFeeModel has store {
        multiplier: Decimal,
        max: Rate,
    }

    const SECONDS_PER_EIGHT_HOUR: u64 = 28800;

    public(friend) fun create_rebase_fee_model(): RebaseFeeModel {
        RebaseFeeModel {
            base: rate::zero(),
            multiplier: decimal::zero()
        }
    }

    public(friend) fun create_funding_fee_model(): FundingFeeModel {
        FundingFeeModel {
            multiplier: decimal::zero(),
            max: rate::zero()
        }
    }

    public(friend) fun create_reserving_fee_model(multiplier: Decimal): ReservingFeeModel {
        ReservingFeeModel {
            multiplier
        }
    }

    public fun compute_rebase_fee_rate() {

    }

    public fun compute_reserving_fee_rate() {

    }

    public fun compute_funding_fee_rate() {

    }

    public fun update_rebase_fee_model(model: &mut RebaseFeeModel) {}
    public fun update_reserving_fee_model(model: &mut ReservingFeeModel) {}
    public fun update_funding_fee_model(model: &mut FundingFeeModel) {}





}
