/// This module manages price feeds for trading pairs and interacts with the supra_validator module to process coherent cluster information.
/// It provides functions for updating price feeds, checking for stale data, and retrieving price information.
///
/// Auction:
/// Free-node - The free-node can perform the `process_cluster` entry function.
/// User - The user can use the `get_price`, `get_prices`, and `extract_price` public functions
module supra_holder::svalue_feed_holder {
    use std::vector;

    /// Return type of the price that we are given to customer
    struct Price has store, drop {
        pair: u32,
        value: u128,
        decimal: u16,
        timestamp: u128,
        round: u64
    }

    #[view]
    /// External view function
    /// It will return OracleHolder resource address
    public fun get_oracle_holder_address(): address {
        @0x1
    }

    #[view]
    /// External view function
    /// It will return the priceFeedData value for that particular tradingPair
    public fun get_price(oracle_holder: address, pair: u32): (u128, u16, u128, u64)  {
        (0, 0, 0, 0)
    }

    #[view]
    /// External view function
    /// It will return the priceFeedData value for that multiple tradingPair
    /// If any of the pairs do not exist in the OracleHolder, an empty vector will be returned for that pair.
    /// If a client requests 10 pairs but only 8 pairs exist, only the available 8 pairs' price data will be returned.
    public fun get_prices(oracle_holder: address, pairs: vector<u32>): vector<Price> {
        vector::empty<Price>()
    }

    /// External public function
    /// It will return the extracted price value for the Price struct
    public fun extract_price(price: &Price): (u32, u128, u16, u128, u64) {
        (0, 0, 0, 0, 0)
    }

    #[view]
    /// External public function.
    /// This function will help to find the prices of the derived pairs
    /// Derived pairs are the one whose price info is calculated using two compatible pairs using either multiplication or division.
    /// Return values in tuple
    ///     1. derived_price : u32
    ///     2. decimal : u16
    ///     3. round-difference : u64
    ///     4. `"pair_id1" as compared to "pair_id2"` : u8 (Where 0=>EQUAL, 1=>LESS, 2=>GREATER)
    public fun get_derived_price(
        oracle_holder: address,
        pair_id1: u32,
        pair_id2: u32,
        operation: u8
    ): (u128, u16, u64, u8) {
        (0, 0, 0, 0)
    }
}
