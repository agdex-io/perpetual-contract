module perpetual::pool_test {

    use aptos_framework::coin;
    use aptos_framework::signer;
    
    use std::vector;
    use std::debug;
    use perpetual::pool;

    #[test(user = @0x1)]
    public fun test_compute_rebase_fee_rate(user: signer) {

        // let (vault_total_value, vault_total_weight) = pool::vault_valuation();
        // debug::print(vault_total_value, vault_total_weight);
                
    }
}
