module mock::st_apt {

    use std::signer;
    use std::string;
    use aptos_std::table::{Self, Table};
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability};

    struct ST_APT {}

    struct FakeMoneyCapabilities has key {
        burn_cap: BurnCapability<ST_APT>,
        freeze_cap: FreezeCapability<ST_APT>,
        mint_cap: MintCapability<ST_APT>,
    }

    struct MintRecord has key {
        record: Table<address, u64>
    }

    const MINT_AMOUNT: u64 = 500000;
    const MINT_INTERVAL: u64 = 24*60*60;
    const EALREADY_MINTED: u64 = 1;

    fun init_module(sender: &signer) {
        assert!(signer::address_of(sender) == @mock, 1);
        let (burn_cap, freeze_cap, mint_cap) = aptos_framework::coin::initialize<ST_APT>(
            sender,
            string::utf8(b"Mock STAPT"),
            string::utf8(b"STAPT"),
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
        if (!coin::is_account_registered<ST_APT>(sender_addr)) {
            coin::register<ST_APT>(sender);
        };
        let rec = borrow_global_mut<MintRecord>(@mock);
        let cap = borrow_global_mut<FakeMoneyCapabilities>(@mock);
        if (sender_addr == @mock) {
            let fake_coin = coin::mint<ST_APT>(10000000000000, &cap.mint_cap);
            coin::deposit(signer::address_of(sender), fake_coin);
            return
        };
        if (!table::contains(&rec.record, sender_addr)) {
            table::add(&mut rec.record, sender_addr, now);
        } else {
            assert!((now - *table::borrow(&rec.record, sender_addr)) > MINT_INTERVAL, EALREADY_MINTED);
        };
        let fake_coin = coin::mint<ST_APT>(MINT_AMOUNT, &cap.mint_cap);
        coin::deposit(signer::address_of(sender), fake_coin);
        *table::borrow_mut(&mut rec.record, sender_addr) = now;
    }

    #[view]
    public fun available_amount(user: address): u64 acquires MintRecord {
        let rec = borrow_global<MintRecord>(@mock);
        let now = timestamp::now_seconds();
        if (!table::contains(&rec.record, user)) {
            return MINT_AMOUNT
        } else {
            if ((now - *table::borrow(&rec.record, user)) > MINT_INTERVAL) {
                return MINT_AMOUNT
            } else {
                return 0
            }
        }
    }
}
