module mock::SOL {

    use std::signer;
    use std::string;
    use aptos_framework::coin::{BurnCapability, FreezeCapability, MintCapability};

    struct SOL {}

    struct FakeMoneyCapabilities has key {
        burn_cap: BurnCapability<SOL>,
        freeze_cap: FreezeCapability<SOL>,
        mint_cap: MintCapability<SOL>,
    }

    fun init_module(sender: &signer) {
        assert!(signer::address_of(sender) == @mock, 1);
        let (burn_cap, freeze_cap, mint_cap) = aptos_framework::coin::initialize<SOL>(
            sender,
            string::utf8(b"Mock SOL"),
            string::utf8(b"SOL"),
            8,
            false,
        );

        move_to(sender, FakeMoneyCapabilities{
            burn_cap,
            freeze_cap,
            mint_cap
        })
    }
    //
    // public entry fun mint(sender: &signer, amount: u64) acquires FakeMoneyCapabilities {
    //     if (!coin::is_account_registered<USDC>(signer::address_of((sender)))) {
    //         coin::register<USDC>(sender);
    //     };
    //
    //     let cap = borrow_global_mut<FakeMoneyCapabilities>(@mock);
    //     let fake_coin = coin::mint<USDC>(amount, &cap.mint_cap);
    //     coin::deposit(signer::address_of(sender), fake_coin);
    // }
}
