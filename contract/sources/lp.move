module perpetual::lp {

    use std::option;
    use std::string;
    use aptos_framework::fungible_asset;
    use aptos_framework::object::{Self, Object, ConstructorRef, DeleteRef, ExtendRef};
    use aptos_framework::fungible_asset::{MintRef, BurnRef, generate_burn_ref, generate_mint_ref};

    friend perpetual::market;

    struct LP has key {}

    struct RefAbility has key {
        mint_ref: MintRef,
        burn_ref: BurnRef
    }

    fun init_module(account: &signer) {
        let creator_ref = object::create_named_object(account, b"TEST");
        fungible_asset::add_fungibility(
            &creator_ref,
            option::some(100) /* max supply */,
            string::utf8(b"TEST"),
            string::utf8(b"@@"),
            6,
            string::utf8(b"http://www.example.com/favicon.ico"),
            string::utf8(b"http://www.example.com"),
        );
        let mint_ref = fungible_asset::generate_mint_ref(&creator_ref);
        let burn_ref = generate_burn_ref(&creator_ref);
        move_to(account, RefAbility{
            mint_ref,
            burn_ref
        })
    }

    public(friend) fun mint() {}

    public(friend) fun burn() {}

    public(friend) fun get_supply(): u128 acquires RefAbility {
        let ref_ability = borrow_global<RefAbility>(@perpetual);
        let supply_opt =
            fungible_asset::supply(fungible_asset::mint_ref_metadata(&ref_ability.mint_ref));
        option::destroy_some(supply_opt)
    }

}