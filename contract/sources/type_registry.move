module perpetual::type_registry {

    use std::signer;
    use perpetual::admin;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::Metadata;

    const EALREADY_REGISTERED: u64 = 60001;
    const ENOT_STATE_ACCOUNT: u64 = 60002;
    const ENOT_REGISTERED: u64 = 60003;

    struct Record<phantom T> has key {
        object: address
    }

    public entry fun register<T>(sender: &signer, object: address) {
        let sender_addr = signer::address_of(sender);
        assert!(sender_addr != @perpetual, ENOT_STATE_ACCOUNT);
        assert!(exists<Record<T>>(@perpetual), EALREADY_REGISTERED);
        move_to(sender, Record<T>{
            object
        });
    }

    public entry fun update_record<T>(sender: &signer, object: address) acquires Record {
        let sender_addr = signer::address_of(sender);
        admin::check_permission(sender_addr);
        assert!(exists<Record<T>>(@perpetual), ENOT_REGISTERED);
        let record = borrow_global_mut<Record<T>>(sender_addr);
        record.object = object;
    }

    public fun get_metadata<T>(): Object<Metadata> acquires Record {
        assert!(exists<Record<T>>(@perpetual), ENOT_REGISTERED);
        let record = borrow_global<Record<T>>(@perpetual);
        object::address_to_object(record.object)
    }

    public fun registered<T>(): bool {
        exists<Record<T>>(@perpetual)
    }

}
