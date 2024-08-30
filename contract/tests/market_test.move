module perpetual::market_test {
    use aptos_framework::coin;
    use aptos_framework::signer;
    
    use std::vector;
    use std::debug;
    use perpetual::market;

    #[test(user = @0x1)]
    public fun test_pyth_feeds(user: signer) {
        
        let user_signer = signer::address_of(&user);
        let vaas: vector<vector<u8>> = vector::empty();
        let bytes: vector<u8> = x"e62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43";
        let price_id = pyth::price_identifier::from_byte_vec(bytes);
        pyth::pyth::update_price_feeds_with_funder(&user, vaas);
        let vaas: vector<vector<u8>> = vector::empty();
        debug::print(&user);
        
    }
}
