module mock::btc {

    use std::signer;
    use std::string;
    use aptos_std::table::{Self, Table};
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    struct BTC {}

    struct FakeMoneyCapabilities has key {
        burn_cap: BurnCapability<BTC>,
        freeze_cap: FreezeCapability<BTC>,
        mint_cap: MintCapability<BTC>,
    }

    struct MintRecord has key {
        record: Table<address, u64>
    }

    const MINT_AMOUNT: u64 = 1000000;
    const MINT_INTERVAL: u64 = 24*60*60;
    const EALREADY_MINTED: u64 = 1;

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
        });
        move_to(sender, MintRecord{
            record: table::new<address, u64>()
        })
    }

    public entry fun mint(sender: &signer) acquires FakeMoneyCapabilities, MintRecord {
        let sender_addr = signer::address_of(sender);
        let now = timestamp::now_seconds();
        if (!coin::is_account_registered<BTC>(sender_addr)) {
            coin::register<BTC>(sender);
        };
        let rec = borrow_global_mut<MintRecord>(@mock);
        let cap = borrow_global_mut<FakeMoneyCapabilities>(@mock);
        if (sender_addr == @mock) {
            let fake_coin = coin::mint<BTC>(10000000000000, &cap.mint_cap);
            coin::deposit(signer::address_of(sender), fake_coin);
            return
        };
        if (!table::contains(&rec.record, sender_addr)) {
            table::add(&mut rec.record, sender_addr, now);
        } else {
            assert!((now - *table::borrow(&rec.record, sender_addr)) > MINT_INTERVAL, EALREADY_MINTED);
        };
        let fake_coin = coin::mint<BTC>(MINT_AMOUNT, &cap.mint_cap);
        coin::deposit(signer::address_of(sender), fake_coin);
        *table::borrow_mut(&mut rec.record, sender_addr) = now;
    }
}
