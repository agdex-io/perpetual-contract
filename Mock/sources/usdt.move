module mock::usdt {

    use std::signer;
    use std::string;
    use aptos_std::table::{Self, Table};
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    struct USDT {}

    struct FakeMoneyCapabilities has key {
        burn_cap: BurnCapability<USDT>,
        freeze_cap: FreezeCapability<USDT>,
        mint_cap: MintCapability<USDT>,
    }

    struct MintRecord has key {
        record: Table<address, u64>
    }

    const MINT_AMOUNT: u64 = 1000000;
    const MINT_INTERVAL: u64 = 24*60*60;
    const EALREADY_MINTED: u64 = 1;

    fun init_module(sender: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = aptos_framework::coin::initialize<USDT>(
            sender,
            string::utf8(b"Mock USDT"),
            string::utf8(b"USDT"),
            6,
            false,
        );

        move_to(sender, FakeMoneyCapabilities{
            burn_cap,
            freeze_cap,
            mint_cap
        });
        move_to(sender, MintRecord{
            record: table::new<address, u64>()
        })
    }

    public entry fun mint(sender: &signer) acquires FakeMoneyCapabilities, MintRecord {
        let sender_addr = signer::address_of(sender);
        let now = timestamp::now_seconds();
        if (!coin::is_account_registered<USDT>(sender_addr)) {
            coin::register<USDT>(sender);
        };
        let cap = borrow_global_mut<FakeMoneyCapabilities>(@mock);
        if (sender_addr == @mock) {
            let fake_coin = coin::mint<USDT>(10000000000000, &cap.mint_cap);
            coin::deposit(signer::address_of(sender), fake_coin);
            return
        };
        let rec = borrow_global_mut<MintRecord>(@mock);
        if (!table::contains(&rec.record, sender_addr)) {
            table::add(&mut rec.record, sender_addr, now);
        } else {
            assert!((now - *table::borrow(&rec.record, sender_addr)) > MINT_INTERVAL, EALREADY_MINTED);
        };
        let fake_coin = coin::mint<USDT>(MINT_AMOUNT, &cap.mint_cap);
        coin::deposit(signer::address_of(sender), fake_coin);
        *table::borrow_mut(&mut rec.record, sender_addr) = now;
    }
}