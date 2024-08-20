module perpetual::lp {


    use std::option;
    use std::signer;
    use std::string;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    friend perpetual::market;

    struct AGLP {}

    struct MoneyCapabilities has key {
        burn_cap: BurnCapability<AGLP>,
        freeze_cap: FreezeCapability<AGLP>,
        mint_cap: MintCapability<AGLP>,
    }

    fun init_module(sender: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = aptos_framework::coin::initialize<AGLP>(
            sender,
            string::utf8(b"AGLP"),
            string::utf8(b"AGLP"),
            6,
            true,
        );

        move_to(sender, MoneyCapabilities{
            burn_cap,
            freeze_cap,
            mint_cap
        })
    }

    public(friend) fun mint_to(sender: &signer, amount: u64) acquires MoneyCapabilities {
        if (!coin::is_account_registered<AGLP>(signer::address_of((sender)))) {
            coin::register<AGLP>(sender);
        };

        let cap = borrow_global_mut<MoneyCapabilities>(@perpetual);
        let lp_coin = coin::mint<AGLP>(amount, &cap.mint_cap);
        coin::deposit(signer::address_of(sender), lp_coin);
    }

    public(friend) fun burn(sender: &signer, amount: u64) acquires MoneyCapabilities {
        if (!coin::is_account_registered<AGLP>(signer::address_of((sender)))) {
            coin::register<AGLP>(sender);
        };

        let cap = borrow_global_mut<MoneyCapabilities>(@perpetual);
        coin::burn_from<AGLP>(signer::address_of(sender), amount, &cap.burn_cap);
    }

    public fun get_supply(): u128 {
        let op_supply = coin::supply<AGLP>();
        option::destroy_some(op_supply)
    }

}