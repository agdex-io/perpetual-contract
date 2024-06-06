module perpetual::lp {

    use std::option;
    use std::string;
    use aptos_framework::object;
    use aptos_framework::fungible_asset::{Self, MintRef, BurnRef, generate_burn_ref, Metadata, FungibleAsset};

    friend perpetual::market;

    struct LP has key {}

    struct RefAbility has key {
        mint_ref: MintRef,
        burn_ref: BurnRef
    }

    fun init_module(account: &signer) {
        // TODO: coin metadata
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

    public(friend) fun mint_to(user: &signer, mint_amount: u64) acquires RefAbility {
        let ref_ability = borrow_global<RefAbility>(@perpetual);
        let metadata = fungible_asset::mint_ref_metadata(&ref_ability.mint_ref);
        let user_store =
            fungible_asset::create_store<Metadata>(&object::create_object_from_account(user), metadata);
        let fa = fungible_asset::mint(&ref_ability.mint_ref, mint_amount);
        fungible_asset::deposit(user_store, fa);
    }

    public(friend) fun burn(fa: FungibleAsset) acquires RefAbility {
        let ref_ability = borrow_global<RefAbility>(@perpetual);
        fungible_asset::burn(&ref_ability.burn_ref, fa);
    }

    public fun get_supply(): u128 acquires RefAbility {
        let ref_ability = borrow_global<RefAbility>(@perpetual);
        let supply_opt =
            fungible_asset::supply(fungible_asset::mint_ref_metadata(&ref_ability.mint_ref));
        option::destroy_some(supply_opt)
    }

}