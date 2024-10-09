module switchboard::aggregator {

    use switchboard::math::{Self, SwitchboardDecimal};

    public fun latest_value(addr: address): SwitchboardDecimal {
        math::new(0, 0, false)
    }

    public fun latest_round_timestamp(addr: address): u64 {
        0
    }

    public fun latest_round_open_timestamp(addr: address): u64 {
        0
    }
}
