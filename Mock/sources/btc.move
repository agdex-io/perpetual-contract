module mock::btc {

    use std::signer;
    use std::string;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    struct BTC {}

    struct FakeMoneyCapabilities has key {
        burn_cap: BurnCapability<BTC>,
        freeze_cap: FreezeCapability<BTC>,
        mint_cap: MintCapability<BTC>,
    }

    const MAX_AMOUNT: u64 = 100000;
    const EINVALID_AMOUNT: u64 = 1;

    public entry fun init(sender: &signer) {
        assert!(signer::address_of(sender) == @mock, 1);
        let (burn_cap, freeze_cap, mint_cap) = aptos_framework::coin::initialize<BTC>(
            sender,
            string::utf8(b"Mock BTC"),
            string::utf8(b"BTC"),
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
        if (!coin::is_account_registered<BTC>(signer::address_of((sender)))) {
            coin::register<BTC>(sender);
        };

        assert!(amount <= MAX_AMOUNT, EINVALID_AMOUNT);
        let cap = borrow_global_mut<FakeMoneyCapabilities>(@mock);
        let fake_coin = coin::mint<BTC>(amount, &cap.mint_cap);
        coin::deposit(signer::address_of(sender), fake_coin);
    }
}
