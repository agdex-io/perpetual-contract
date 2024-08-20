module mock::ETH {

    use std::signer;
    use std::string;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    struct ETH {}

    struct FakeMoneyCapabilities has key {
        burn_cap: BurnCapability<ETH>,
        freeze_cap: FreezeCapability<ETH>,
        mint_cap: MintCapability<ETH>,
    }

    public entry fun init(sender: &signer) {
        assert!(signer::address_of(sender) == @mock, 1);
        let (burn_cap, freeze_cap, mint_cap) = aptos_framework::coin::initialize<ETH>(
            sender,
            string::utf8(b"Mock ETH"),
            string::utf8(b"ETH"),
            8,
            false,
        );

        move_to(sender, FakeMoneyCapabilities{
            burn_cap,
            freeze_cap,
            mint_cap
        })
    }

    public entry fun mint(sender: &signer, amount: u64) acquires FakeMoneyCapabilities {
        if (!coin::is_account_registered<ETH>(signer::address_of((sender)))) {
            coin::register<ETH>(sender);
        };

        let cap = borrow_global_mut<FakeMoneyCapabilities>(@mock);
        let fake_coin = coin::mint<ETH>(amount, &cap.mint_cap);
        coin::deposit(signer::address_of(sender), fake_coin);
    }
}
