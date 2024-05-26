module perpetual::lp {

    use aptos_framework::fungible_asset;
    use aptos_framework::object::{Self, Object, ConstructorRef, DeleteRef, ExtendRef};

    struct LP has key {}

    fun init_module(account: &signer) {
        let creator_ref = object::create_named_object(account, b"TEST");
    }

    public(friend) fun mint() {}

    public(friend) fun burn() {}

}