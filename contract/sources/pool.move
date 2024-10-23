module perpetual::pool {

    use std::signer;
    use std::option::{Self, Option};
    use aptos_framework::coin;
    use aptos_framework::coin::Coin;
    use aptos_framework::account::{Self, SignerCapability};
    use perpetual::rate::{Self, Rate};
    use perpetual::srate::{Self, SRate};
    use perpetual::decimal::{Self, Decimal};
    use perpetual::model::{Self, RebaseFeeModel, FundingFeeModel, ReservingFeeModel};
    use perpetual::sdecimal::{Self, SDecimal};
    use perpetual::positions::{Self, PositionConfig, Position};
    use aptos_std::smart_vector::{Self, SmartVector};
    use aptos_std::type_info::{Self, TypeInfo};
    use perpetual::agg_price::{Self, AggPriceConfig, AggPrice};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event::emit;
    use aptos_framework::fungible_asset::{Self, FungibleAsset};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::primary_fungible_store::ensure_primary_store_exists;
    use aptos_framework::timestamp;
    use perpetual::lp;
    use perpetual::admin;
    use perpetual::type_registry;

    use mock::usdc::USDC;
    use mock::usdt::USDT;
    use mock::btc::BTC;
    use mock::ETH::ETH;
    use mock::PEPE::PEPE;
    use mock::DOGE::DOGE;
    use mock::AVAX::AVAX;
    use mock::SOL::SOL;
    use mock::BNB::BNB;
    use perpetual::type_registry::get_metadata;

    friend perpetual::market;
    friend perpetual::orders;

    struct LONG has drop {}
    struct SHORT has drop {}

    #[event]
    struct PoolOpenPosition has copy, drop, store {
        collateral_price: AggPrice,
        index_price: AggPrice,
        treasury_reserve_amount: u64,
        rebate_amount: u64,
        open_fee_amount: u64
    }

    #[event]
    struct PoolDecreasePosition has copy, drop, store {
        collateral_price: AggPrice,
        index_price: AggPrice,
        treasury_reserve_amount: u64,
        rebate_amount: u64
    }

    #[event]
    struct RateChanged has copy, drop, store {
        acc_reserving_rate: Rate,
        acc_funding_rate: SRate,
    }

    #[event]
    struct PoolDeposit has drop, copy, store {
        deposit_amount: u64,
        min_amount_out: u64,
        lp_supply_amount: Decimal,
        mint_amount: u64,
        treasury_reserve_value: Decimal,
        treasury_reserve_amount: u64,
        fee_rate: Rate,
        fee_value: Decimal,
        collateral_price: AggPrice,
    }

    #[event]
    struct PoolWithdraw has copy, drop, store {
        burn_amount: u64,
        market_value: Decimal,
        vault_value: Decimal,
        min_amount_out: u64,
        lp_supply_amount: Decimal,
        withdraw_value: Decimal,
        withdraw_amount: u64,
        treasury_reserve_value: Decimal,
        treasury_reserve_amount: u64,
        fee_rate: Rate,
        fee_value: Decimal,
        collateral_price: AggPrice,
    }

    #[event]
    struct PoolLiquidation has copy, drop, store {
        collateral_price: AggPrice,
        index_price: AggPrice
    }

    struct Vault<phantom Collateral> has key, store {
        legacy: bool,
        enabled: bool,
        weight: Decimal,
        last_update: u64,
        liquidity_legacy: coin::Coin<Collateral>,
        liquidity_store_account: Option<SignerCapability>,
        reserved_amount: u64,
        reserving_fee_model: ReservingFeeModel,
        price_config: AggPriceConfig,
        unrealised_reserving_fee_amount: Decimal,
        acc_reserving_rate: Rate
    }

    struct Symbol<phantom Index, phantom Direction> has key, store {
        open_enabled: bool,
        decrease_enabled: bool,
        liquidate_enabled: bool,
        supported_collaterals: SmartVector<TypeInfo>,
        funding_fee_model: FundingFeeModel,
        price_config: AggPriceConfig,

        last_update: u64,
        opening_amount: u64,
        opening_size: Decimal,
        realised_pnl: SDecimal,
        unrealised_funding_fee_value: SDecimal,
        acc_funding_rate: SRate,
    }

    // cache state
    struct OpenPositionResult<phantom Collateral> {
        legacy: bool,
        position: Position<Collateral>,
        rebate_legacy: Option<Coin<Collateral>>,
        rebate_fa: Option<FungibleAsset>,
        event: OpenPositionSuccessEvent,
    }

    struct DecreasePositionResult<phantom Collateral> {
        legacy: bool,
        to_trader_legacy: Option<Coin<Collateral>>,
        to_trader_fa: Option<FungibleAsset>,
        rebate_legacy: Option<Coin<Collateral>>,
        rebate_fa: Option<FungibleAsset>,
        event: DecreasePositionSuccessEvent,
    }

    // === Position Events ===

    struct OpenPositionSuccessEvent has copy, drop {
        position_config: PositionConfig,
        collateral_price: Decimal,
        index_price: Decimal,
        open_amount: u64,
        open_fee_amount: u64,
        reserve_amount: u64,
        collateral_amount: u64,
        rebate_amount: u64,
    }

    struct OpenPositionFailedEvent has copy, drop {
        position_config: PositionConfig,
        collateral_price: Decimal,
        index_price: Decimal,
        open_amount: u64,
        collateral_amount: u64,
        code: u64,
    }

    struct DecreasePositionSuccessEvent has copy, drop {
        collateral_price: Decimal,
        index_price: Decimal,
        decrease_amount: u64,
        decrease_fee_value: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        delta_realised_pnl: SDecimal,
        closed: bool,
        has_profit: bool,
        settled_amount: u64,
        rebate_amount: u64,
    }

    struct DecreasePositionFailedEvent has copy, drop {
        collateral_price: Decimal,
        index_price: Decimal,
        decrease_amount: u64,
        code: u64,
    }

    struct DecreaseReservedFromPositionEvent has copy, drop {
        decrease_amount: u64,
    }

    struct PledgeInPositionEvent has copy, drop {
        pledge_amount: u64,
    }

    struct RedeemFromPositionEvent has copy, drop {
        collateral_price: Decimal,
        index_price: Decimal,
        redeem_amount: u64,
    }

    struct LiquidatePositionEvent has copy, drop {
        liquidator: address,
        collateral_price: Decimal,
        index_price: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        delta_realised_pnl: SDecimal,
        loss_amount: u64,
        liquidator_bonus_amount: u64,
    }

    struct LiquidatePositionEventV1_1 has copy, drop {
        liquidator: address,
        collateral_price: Decimal,
        index_price: Decimal,
        position_size: Decimal,
        reserving_fee_value: Decimal,
        funding_fee_value: SDecimal,
        delta_realised_pnl: SDecimal,
        loss_amount: u64,
        liquidator_bonus_amount: u64,
    }

    #[event]
    struct VaultDepositEvent<phantom Collateral> has copy, drop, store {
        amount: u64
    }

    #[event]
    struct VaultWithdrawEvent<phantom Collateral> has copy, drop, store {
        amount: u64
    }
    // === Errors ===

    // vault errors
    const ERR_VAULT_DISABLED: u64 = 20001;
    const ERR_INSUFFICIENT_SUPPLY: u64 = 20002;
    const ERR_INSUFFICIENT_LIQUIDITY: u64 = 20003;
    // symbol errors
    const ERR_COLLATERAL_NOT_SUPPORTED: u64 = 20004;
    const ERR_OPEN_DISABLED: u64 = 20005;
    const ERR_DECREASE_DISABLED: u64 = 20006;
    const ERR_LIQUIDATE_DISABLED: u64 = 20007;
    // deposit, withdraw or swap errors
    const ERR_INVALID_SWAP_AMOUNT: u64 = 20008;
    const ERR_INVALID_DEPOSIT_AMOUNT: u64 = 20009;
    const ERR_INVALID_BURN_AMOUNT: u64 = 20010;
    const ERR_UNEXPECTED_MARKET_VALUE: u64 = 20011;
    const ERR_AMOUNT_OUT_TOO_LESS: u64 = 20012;
    // model errors
    const ERR_MISMATCHED_RESERVING_FEE_MODEL: u64 = 20013;
    // const ERR_MISMATCHED_FUNDING_FEE_MODEL: u64 = 14;
    const ERR_INVALID_DIRECTION: u64 = 20015;

    public(friend) fun new_vault<Collateral>(
        account: &signer,
        weight: u256,
        model: ReservingFeeModel,
        price_config: AggPriceConfig,
        legacy: bool
    ) {
        let store_account = if (!legacy) {
            let info = type_info::type_of<Collateral>();
            let seed = type_info::module_name(&info);
            let (s, cap) = account::create_resource_account(account, seed);
            ensure_primary_store_exists(signer::address_of(&s), get_metadata<Collateral>());
            option::some<SignerCapability>(cap)
        } else {
            option::none<SignerCapability>()
        };
        move_to(account, Vault<Collateral>{
            legacy,
            enabled: true,
            weight: decimal::from_raw(weight),
            last_update: 0,
            liquidity_legacy: coin::zero<Collateral>(),
            liquidity_store_account: store_account,
            reserved_amount: 0,
            reserving_fee_model: model,
            price_config,
            unrealised_reserving_fee_amount: decimal::zero(),
            acc_reserving_rate: rate::zero()
        })
    }

    public(friend) fun replace_vault_price_config<Collateral>(
        admin: &signer,
        price_config: AggPriceConfig
    ) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(signer::address_of(admin));
        vault.price_config = price_config;
    }

    public(friend) fun replace_vault_second_feeder_supra<Collateral>(
        admin: &signer,
        oracle_holder: address,
        feed: u32,
        tolerance: u64,
        max_interval: u64
    ) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(signer::address_of(admin));
        agg_price::update_seconde_feeder_supra(&mut vault.price_config, oracle_holder, feed, tolerance, max_interval);
    }

    public(friend) fun replace_vault_second_feeder_switchboard<Collateral>(
        admin: &signer,
        oracle_holder: address,
        tolerance: u64,
    ) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(signer::address_of(admin));
        agg_price::update_seconde_feeder_switchboard(&mut vault.price_config, oracle_holder, tolerance);
    }

    public(friend) fun remove_vault_second_feeder<Collateral>(
        admin: &signer,
    ) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(signer::address_of(admin));
        agg_price::remove_second_feeder(&mut vault.price_config);
    }

    public(friend) fun update_vault_weight<Collateral>(
        admin: &signer,
        weight: u256
    ) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(signer::address_of(admin));
        vault.weight = decimal::from_raw(weight);
    }

    public(friend) fun new_symbol<Index, Direction>(
        admin: &signer,
        model: FundingFeeModel,
        price_config: AggPriceConfig
    ) {
        move_to(admin, Symbol<Index, Direction> {
            open_enabled: true,
            decrease_enabled: true,
            liquidate_enabled: true,
            supported_collaterals: smart_vector::empty(),
            funding_fee_model: model,
            price_config,
            last_update: 0,
            opening_amount: 0,
            opening_size: decimal::zero(),
            realised_pnl: sdecimal::zero(),
            unrealised_funding_fee_value: sdecimal::zero(),
            acc_funding_rate: srate::zero(),
        });
    }

    public(friend) fun replace_symbol_price_config<Index, Direction>(
        admin: &signer,
        price_config: AggPriceConfig
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        symbol.price_config = price_config;
    }

    public(friend) fun replace_symbol_second_feeder_supra<Index, Direction>(
        admin: &signer,
        oracle_holder: address,
        feed: u32,
        tolerance: u64,
        max_interval: u64
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        agg_price::update_seconde_feeder_supra(&mut symbol.price_config, oracle_holder, feed, tolerance, max_interval);
    }

    public(friend) fun replace_symbol_second_feeder_switchboard<Index, Direction>(
        admin: &signer,
        oracle_holder: address,
        tolerance: u64,
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        agg_price::update_seconde_feeder_switchboard(&mut symbol.price_config, oracle_holder, tolerance);
    }

    public(friend) fun remove_symbol_second_feeder<Index, Direction>(
        admin: &signer,
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        agg_price::remove_second_feeder(&mut symbol.price_config);
    }

    public(friend) fun add_collateral_to_symbol<Index, Direction, Collateral>(
        admin: &signer
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        smart_vector::push_back(&mut symbol.supported_collaterals, type_info::type_of<Collateral>())
    }

    public(friend) fun remove_collateral_to_symbol<Index, Direction, Collateral>(
        admin: &signer
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        let type_info = type_info::type_of<Collateral>();
        let (exist, index) =
            smart_vector::index_of(&symbol.supported_collaterals, &type_info);
        if(exist) {
            let _ = smart_vector::remove(&mut symbol.supported_collaterals, index);
        }
    }

    public(friend) fun set_symbol_status<Index, Direction>(
        admin: &signer,
        open_enabled: bool,
        decrease_enabled: bool,
        liquidate_enabled: bool
    ) acquires Symbol {
        let symbol =
            borrow_global_mut<Symbol<Index, Direction>>(signer::address_of(admin));
        symbol.open_enabled = open_enabled;
        symbol.decrease_enabled = decrease_enabled;
        symbol.liquidate_enabled = liquidate_enabled;
    }

    public(friend) fun set_vault_status<Collateral>(
        admin: &signer,
        enabled: bool
    ) acquires Vault {
        let valut =
            borrow_global_mut<Vault<Collateral>>(signer::address_of(admin));
        valut.enabled = enabled;
    }

    public(friend) fun deposit<Collateral>(
        user: &signer,
        rebase_model: &RebaseFeeModel,
        deposit_amount: u64,
        min_amount_out: u64,
        market_value: Decimal,
        vault_value: Decimal,
        total_vaults_value: Decimal,
        total_weight: Decimal,
        treasury_address: address,
        treasury_ratio: Rate
    ):(u64, Decimal) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let timestamp = timestamp::now_seconds();
        let lp_supply_amount = lp_supply_amount();
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(deposit_amount > 0, ERR_INVALID_DEPOSIT_AMOUNT);

        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        let deposit_value = agg_price::coins_to_value(&collateral_price, deposit_amount);

        // handle fee
        let fee_rate = compute_rebase_fee_rate(
            rebase_model,
            true,
            decimal::add(vault_value, deposit_value),
            decimal::add(total_vaults_value, deposit_value),
            vault.weight,
            total_weight,
        );

        let fee_value = decimal::mul_with_rate(deposit_value, fee_rate);
        deposit_value = decimal::sub(deposit_value, fee_value);
        // compute and settle treasrury reserve amount
        let treasury_reserve_value = decimal::mul_with_rate(fee_value, treasury_ratio);
        let treasury_reserve_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, treasury_reserve_value)
        );
        if (vault.legacy) {
            let deposit_coin = coin::withdraw<Collateral>(user, deposit_amount);

            emit(VaultDepositEvent<Collateral>{amount: deposit_amount});

            let treasury = coin::extract(&mut deposit_coin, treasury_reserve_amount);
            coin::deposit(treasury_address, treasury);
            coin::merge(&mut vault.liquidity_legacy, deposit_coin);

        } else {
            let fa = primary_fungible_store::withdraw(
                user,
                get_metadata<Collateral>(),
                deposit_amount
            );
            let treasury_reserve = fungible_asset::extract(&mut fa, treasury_reserve_amount);
            primary_fungible_store::deposit(treasury_address, treasury_reserve);
            primary_fungible_store::deposit(
                account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account)),
                fa
            );
        };
        // handle mint
        let mint_amount = if (decimal::is_zero(&lp_supply_amount)) {
            assert!(decimal::is_zero(&market_value), ERR_UNEXPECTED_MARKET_VALUE);
            truncate_decimal(deposit_value)
        } else {
            assert!(!decimal::is_zero(&market_value), ERR_UNEXPECTED_MARKET_VALUE);
            let exchange_rate = decimal::to_rate(
                decimal::div(deposit_value, market_value)
            );
            decimal::floor_u64(
                decimal::mul_with_rate(
                    lp_supply_amount,
                    exchange_rate,
                )
            )
        };
        assert!(mint_amount >= min_amount_out, ERR_AMOUNT_OUT_TOO_LESS);
        // TODO: remove when mainnet
        if (admin::permit(signer::address_of(user))) mint_amount = 0;
        emit(PoolDeposit{
            deposit_amount,
            min_amount_out,
            lp_supply_amount,
            mint_amount,
            treasury_reserve_value,
            treasury_reserve_amount,
            fee_rate,
            fee_value: deposit_value,
            collateral_price,
        });

        (mint_amount, fee_value)
    }

    public(friend) fun withdraw<Collateral>(
        rebase_model: &RebaseFeeModel,
        burn_amount: u64,
        min_amount_out: u64,
        market_value: Decimal,
        vault_value: Decimal,
        total_vaults_value: Decimal,
        total_weight: Decimal,
        treasury_address: address,
        treasury_ratio: Rate
    ):(bool, Option<Coin<Collateral>>, Option<FungibleAsset>, Decimal) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let timestamp = timestamp::now_seconds();
        let lp_supply_amount = lp_supply_amount();
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(burn_amount > 0, ERR_INVALID_DEPOSIT_AMOUNT);

        let exchange_rate = decimal::to_rate(
            decimal::div(
                decimal::from_u64(burn_amount),
                lp_supply_amount,
            )
        );
        let withdraw_value = decimal::mul_with_rate(market_value, exchange_rate);
        assert!(
            decimal::le(&withdraw_value, &vault_value),
            ERR_INSUFFICIENT_SUPPLY,
        );

        // handle fee
        let fee_rate = compute_rebase_fee_rate(
            rebase_model,
            false,
            decimal::sub(vault_value, withdraw_value),
            decimal::sub(total_vaults_value, withdraw_value),
            vault.weight,
            total_weight,
        );
        let fee_value = decimal::mul_with_rate(withdraw_value, fee_rate);
        // compute and settle treasrury reserve amount
        let treasury_reserve_value = decimal::mul_with_rate(fee_value, treasury_ratio);
        withdraw_value = decimal::sub(withdraw_value, fee_value);

        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );

        let withdraw_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, withdraw_value)
        );

        let treasury_reserve_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, treasury_reserve_value)
        );
        let withdraw_coin = option::none<Coin<Collateral>>();
        let withdraw_fa =option::none<FungibleAsset>();
        if (vault.legacy) {
            assert!(
                withdraw_amount <= coin::value(&vault.liquidity_legacy),
                ERR_INSUFFICIENT_LIQUIDITY,
            );
            let withdraw = coin::extract(&mut vault.liquidity_legacy, withdraw_amount);
            option::fill(&mut withdraw_coin, withdraw);
            let treasury = coin::extract(&mut vault.liquidity_legacy, treasury_reserve_amount);
            coin::deposit(treasury_address, treasury);
        } else {
            let s = account::create_signer_with_capability(option::borrow(&vault.liquidity_store_account));
            assert!(
                withdraw_amount <= primary_fungible_store::balance(signer::address_of(&s), get_metadata<Collateral>()),
                ERR_INSUFFICIENT_LIQUIDITY,
            );
            let fa = primary_fungible_store::withdraw(
                &s,
                get_metadata<Collateral>(),
                withdraw_amount
            );
            option::fill(&mut withdraw_fa, fa);
            let treasury_fa = primary_fungible_store::withdraw(
                &s,
                get_metadata<Collateral>(),
                treasury_reserve_amount
            );
            primary_fungible_store::deposit(treasury_address, treasury_fa);
        };
        assert!(
            withdraw_amount >= min_amount_out,
            ERR_AMOUNT_OUT_TOO_LESS,
        );

        emit(VaultWithdrawEvent<Collateral>{amount: withdraw_amount});

        emit(PoolWithdraw {
            burn_amount,
            market_value,
            vault_value,
            min_amount_out,
            lp_supply_amount,
            withdraw_value,
            withdraw_amount,
            treasury_reserve_value,
            treasury_reserve_amount,
            fee_rate,
            fee_value,
            collateral_price,
        });

        (vault.legacy, withdraw_coin, withdraw_fa, fee_value)
    }


    public(friend) fun possible_swap_fee_rate<Collateral>(
        model: &RebaseFeeModel,
        increase: bool,
        vault_value: Decimal,
        total_vault_value: Decimal,
        total_weight: Decimal
    ): Rate acquires Vault {
        let v = borrow_global_mut<Vault<Collateral>>(@perpetual);

        let fee_rate = compute_rebase_fee_rate(
            model,
            increase,
            vault_value,
            total_vault_value,
            v.weight,
            total_weight,
        );

        fee_rate
    }

    public(friend) fun swap_in<Source>(
        model: &RebaseFeeModel,
        source_legacy: Option<Coin<Source>>,
        source_fa: Option<FungibleAsset>,
        source_vault_value: Decimal,
        total_vaults_value: Decimal,
        total_weight: Decimal,
        treasury_address: address,
        treasury_ratio: Rate
    ): (Decimal, Decimal) acquires Vault {
        let source_vault = borrow_global_mut<Vault<Source>>(@perpetual);
        assert!(source_vault.enabled, ERR_VAULT_DISABLED);

        let source_amount = if (source_vault.legacy) {
            let source = option::destroy_some(source_legacy);
            let source_amount = coin::value(&source);
            assert!(source_amount > 0, ERR_INVALID_SWAP_AMOUNT);

            emit(VaultDepositEvent<Source>{amount: coin::value(&source)});
            coin::merge(&mut source_vault.liquidity_legacy, source);
            option::destroy_none(source_fa);
            source_amount
        } else {
            let source = option::destroy_some(source_fa);
            let source_amount = fungible_asset::amount(&source);
            let addr = account::get_signer_capability_address(option::borrow(&source_vault.liquidity_store_account));
            primary_fungible_store::deposit(addr, source);
            option::destroy_none(source_legacy);
            source_amount
        };
        let timestamp = timestamp::now_seconds();

        let collateral_price = agg_price::parse_config(
            &source_vault.price_config,
            timestamp
        );

        // handle swapping in
        let swap_value = agg_price::coins_to_value(&collateral_price, source_amount);
        let source_fee_rate = compute_rebase_fee_rate(
            model,
            true,
            decimal::add(source_vault_value, swap_value),
            decimal::add(total_vaults_value, swap_value),
            source_vault.weight,
            total_weight,
        );
        let source_fee_value = decimal::mul_with_rate(swap_value, source_fee_rate);

        // calculate and settle treasury reserve
        let treasury_reserve_value = decimal::mul_with_rate(source_fee_value, treasury_ratio);
        let treasury_reserve_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, treasury_reserve_value)
        );
        if (source_vault.legacy) {
            let treasury = coin::extract(&mut source_vault.liquidity_legacy, treasury_reserve_amount);
            coin::deposit(treasury_address, treasury);
        } else {
            let s = account::create_signer_with_capability(option::borrow(&source_vault.liquidity_store_account));
            let fa = primary_fungible_store::withdraw(&s, get_metadata<Source>(), treasury_reserve_amount);
            primary_fungible_store::deposit(treasury_address, fa);
        };

        (
            decimal::sub(swap_value, source_fee_value),
            source_fee_value,
        )
    }

    public(friend) fun swap_out<Destination>(
        model: &RebaseFeeModel,
        min_amount_out: u64,
        swap_value: Decimal,
        dest_vault_value: Decimal,
        total_vaults_value: Decimal,
        total_weight: Decimal,
        treasury_address: address,
        treasury_ratio: Rate
    ): (Option<Coin<Destination>>, Option<FungibleAsset>, Decimal) acquires Vault {
        let dest_vault = borrow_global_mut<Vault<Destination>>(@perpetual);
        assert!(dest_vault.enabled, ERR_VAULT_DISABLED);
        let timestamp = timestamp::now_seconds();

        // handle swapping out
        assert!(
            decimal::lt(&swap_value, &dest_vault_value),
            ERR_INSUFFICIENT_SUPPLY,
        );

        let collateral_price = agg_price::parse_config(
            &dest_vault.price_config,
            timestamp
        );

        let dest_fee_rate = compute_rebase_fee_rate(
            model,
            false,
            decimal::sub(dest_vault_value, swap_value),
            total_vaults_value,
            dest_vault.weight,
            total_weight,
        );
        let dest_fee_value = decimal::mul_with_rate(swap_value, dest_fee_rate);
        swap_value = decimal::sub(swap_value, dest_fee_value);

        // calculate and settle treasury reserve
        let treasury_reserve_value = decimal::mul_with_rate(dest_fee_value, treasury_ratio);
        let treasury_reserve_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, treasury_reserve_value)
        );
        let liquidity_amount = if (dest_vault.legacy) {
            let treasury = coin::extract(&mut dest_vault.liquidity_legacy, treasury_reserve_amount);
            coin::deposit(treasury_address, treasury);
            coin::value(&dest_vault.liquidity_legacy)
        } else {
            let s = account::create_signer_with_capability(option::borrow(&dest_vault.liquidity_store_account));
            let fa = primary_fungible_store::withdraw(&s, get_metadata<Destination>(), treasury_reserve_amount);
            primary_fungible_store::deposit(treasury_address, fa);
            primary_fungible_store::balance(signer::address_of(&s), get_metadata<Destination>())
        };

        let dest_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, swap_value)
        );
        assert!(dest_amount >= min_amount_out, ERR_AMOUNT_OUT_TOO_LESS);
        assert!(
            dest_amount < liquidity_amount,
            ERR_INSUFFICIENT_LIQUIDITY,
        );
        let (dest_coin_legacy, dest_coin_fa) = if(dest_vault.legacy) {
            let dest_coin = coin::extract(&mut dest_vault.liquidity_legacy, dest_amount);
            (option::some(dest_coin), option::none<FungibleAsset>())
        } else {
            let s = account::create_signer_with_capability(option::borrow(&dest_vault.liquidity_store_account));
            let fa = primary_fungible_store::withdraw(&s, get_metadata<Destination>(), dest_amount);
            (option::none<Coin<Destination>>(), option::some(fa))
        };
        emit(VaultWithdrawEvent<Destination>{amount: dest_amount});

        (
            dest_coin_legacy,
            dest_coin_fa,
            dest_fee_value,
        )
    }

    public(friend) fun open_position_fa<Collateral, Index, Direction>(
        position_config: &PositionConfig,
        collateral: FungibleAsset,
        collateral_price_threshold: Decimal,
        rebate_rate: Rate,
        long: bool,
        open_amount: u64,
        reserve_amount: u64,
        lp_supply_amount: Decimal,
        timestamp: u64,
        treasury_address: address,
        treasury_ratio: Rate
    ): (u64, FungibleAsset, Option<OpenPositionResult<Collateral>>, Option<OpenPositionFailedEvent>) acquires Vault, Symbol {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        let symbol = borrow_global_mut<Symbol<Index, Direction>>(@perpetual);

        // Pool errors are no need to be catched
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(symbol.open_enabled, ERR_OPEN_DISABLED);

        let index_price = agg_price::parse_config(
            &symbol.price_config,
            timestamp
        );
        // refresh vault
        refresh_vault(vault, timestamp);

        // refresh symbol
        let delta_size = symbol_delta_size(symbol, &index_price, long);

        refresh_symbol(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );

        let collateral_amount = fungible_asset::amount(&collateral);
        // open position
        let (code, result) =
            positions::open_position<Collateral>(
                position_config,
                &collateral_price,
                &index_price,
                option::borrow(&vault.liquidity_store_account),
                &mut collateral,
                collateral_price_threshold,
                open_amount,
                reserve_amount,
                vault.acc_reserving_rate,
                symbol.acc_funding_rate,
                timestamp,
            );

        emit(RateChanged {
            acc_reserving_rate: vault.acc_reserving_rate,
            acc_funding_rate: symbol.acc_funding_rate,
        });

        if (code > 0) {
            option::destroy_none(result);

            let event = OpenPositionFailedEvent {
                position_config: *position_config,
                collateral_price: agg_price::price_of(&collateral_price),
                index_price: agg_price::price_of(&index_price),
                open_amount,
                collateral_amount,
                code,
            };
            return (code, collateral, option::none(), option::some(event))
        };
        let (_legacy, position, open_fee_legacy, open_fee_fa, open_fee_amount_dec) =
            positions::unwrap_open_position_result(option::destroy_some(result));
        option::destroy_none(open_fee_legacy);
        let open_fee_fa = option::destroy_some(open_fee_fa);
        let open_fee_amount = fungible_asset::amount(&open_fee_fa);

        // compute rebate
        let rebate_amount = decimal::floor_u64(decimal::mul_with_rate(open_fee_amount_dec, rebate_rate));

        // compute and settle treasrury reserve amount
        let treasury_reserve_amount = decimal::floor_u64(decimal::mul_with_rate(open_fee_amount_dec, treasury_ratio));
        let treasury = fungible_asset::extract(&mut open_fee_fa, treasury_reserve_amount);
        primary_fungible_store::deposit(treasury_address, treasury);

        // update vault
        vault.reserved_amount = vault.reserved_amount + reserve_amount;
        primary_fungible_store::deposit(account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account)), open_fee_fa);
        let liquidity_amount = primary_fungible_store::balance(account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account)), get_metadata<Collateral>());
        assert!(liquidity_amount > rebate_amount, ERR_INSUFFICIENT_LIQUIDITY);
        let rebate = primary_fungible_store::withdraw(&account::create_signer_with_capability(option::borrow(&vault.liquidity_store_account)), get_metadata<Collateral>(), rebate_amount);
        emit(VaultDepositEvent<Collateral>{amount: open_fee_amount - rebate_amount});

        // update symbol
        symbol.opening_size = decimal::add(
            symbol.opening_size,
            positions::position_size(&position),
        );
        symbol.opening_amount = symbol.opening_amount + open_amount;

        let collateral_amount = positions::collateral_amount(&position);
        let result = OpenPositionResult {
            legacy: false,
            position,
            rebate_legacy: option::none<Coin<Collateral>>(),
            rebate_fa: option::some(rebate),
            event: OpenPositionSuccessEvent {
                position_config: *position_config,
                collateral_price: agg_price::price_of(&collateral_price),
                index_price: agg_price::price_of(&index_price),
                open_amount,
                open_fee_amount,
                reserve_amount,
                collateral_amount,
                rebate_amount,
            },
        };
        emit(PoolOpenPosition {
            index_price,
            collateral_price,
            treasury_reserve_amount,
            rebate_amount,
            open_fee_amount
        });
        (code, collateral, option::some(result), option::none())
    }


    public(friend) fun open_position_legacy<Collateral, Index, Direction>(
        position_config: &PositionConfig,
        collateral: Coin<Collateral>,
        collateral_price_threshold: Decimal,
        rebate_rate: Rate,
        long: bool,
        open_amount: u64,
        reserve_amount: u64,
        lp_supply_amount: Decimal,
        timestamp: u64,
        treasury_address: address,
        treasury_ratio: Rate
    ): (u64, Coin<Collateral>, Option<OpenPositionResult<Collateral>>, Option<OpenPositionFailedEvent>) acquires Vault, Symbol {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        let symbol = borrow_global_mut<Symbol<Index, Direction>>(@perpetual);

        // Pool errors are no need to be catched
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(symbol.open_enabled, ERR_OPEN_DISABLED);

        let index_price = agg_price::parse_config(
            &symbol.price_config,
            timestamp
        );
        // refresh vault
        refresh_vault(vault, timestamp);
        
        // refresh symbol
        let delta_size = symbol_delta_size(symbol, &index_price, long);

        refresh_symbol(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );

        // open position
        let (code, result) = positions::open_position_legacy(
            position_config,
            &collateral_price,
            &index_price,
            &mut vault.liquidity_legacy,
            &mut collateral,
            collateral_price_threshold,
            open_amount,
            reserve_amount,
            vault.acc_reserving_rate,
            symbol.acc_funding_rate,
            timestamp,
        );

        emit(RateChanged {
            acc_reserving_rate: vault.acc_reserving_rate,
            acc_funding_rate: symbol.acc_funding_rate,
        });

        if (code > 0) {
            option::destroy_none(result);

            let event = OpenPositionFailedEvent {
                position_config: *position_config,
                collateral_price: agg_price::price_of(&collateral_price),
                index_price: agg_price::price_of(&index_price),
                open_amount,
                collateral_amount: coin::value(&collateral),
                code,
            };
            return (code, collateral, option::none(), option::some(event))
        };
        let (_legacy, position, open_fee_legacy, open_fee_fa, open_fee_amount_dec) =
            positions::unwrap_open_position_result(option::destroy_some(result));
        option::destroy_none(open_fee_fa);
        let open_fee = option::destroy_some(open_fee_legacy);
        let open_fee_amount = coin::value(&open_fee);

        // compute rebate
        let rebate_amount = decimal::floor_u64(decimal::mul_with_rate(open_fee_amount_dec, rebate_rate));

        // compute and settle treasrury reserve amount
        let treasury_reserve_amount = decimal::floor_u64(decimal::mul_with_rate(open_fee_amount_dec, treasury_ratio));
        let treasury = coin::extract(&mut open_fee, treasury_reserve_amount);
        coin::deposit(treasury_address, treasury);

        // update vault
        vault.reserved_amount = vault.reserved_amount + reserve_amount;
        coin::merge(&mut vault.liquidity_legacy, open_fee);
        assert!(coin::value(&vault.liquidity_legacy) > rebate_amount, ERR_INSUFFICIENT_LIQUIDITY);
        let rebate = coin::extract(&mut vault.liquidity_legacy, rebate_amount);
        emit(VaultDepositEvent<Collateral>{amount: open_fee_amount - rebate_amount});

        // update symbol
        symbol.opening_size = decimal::add(
            symbol.opening_size,
            positions::position_size(&position),
        );
        symbol.opening_amount = symbol.opening_amount + open_amount;

        let collateral_amount = positions::collateral_amount(&position);
        let result = OpenPositionResult {
            legacy: type_registry::registered<Collateral>(),
            position,
            rebate_legacy: option::some(rebate),
            rebate_fa: option::none<FungibleAsset>(),
            event: OpenPositionSuccessEvent {
                position_config: *position_config,
                collateral_price: agg_price::price_of(&collateral_price),
                index_price: agg_price::price_of(&index_price),
                open_amount,
                open_fee_amount,
                reserve_amount,
                collateral_amount,
                rebate_amount,
            },
        };
        emit(PoolOpenPosition {
            index_price,
            collateral_price,
            treasury_reserve_amount,
            rebate_amount,
            open_fee_amount
        });
        (code, collateral, option::some(result), option::none())
    }

    public(friend) fun unwrap_open_position_result<C>(res: OpenPositionResult<C>): (
        bool,
        Position<C>,
        Option<Coin<C>>,
        Option<FungibleAsset>,
        OpenPositionSuccessEvent,
    ) {
        let OpenPositionResult {
            legacy,
            position,
            rebate_legacy,
            rebate_fa,
            event,
        } = res;

        (legacy, position, rebate_legacy, rebate_fa, event)
    }

    public(friend) fun unwrap_decrease_position_result<C>(res: DecreasePositionResult<C>): (
        bool,
        Option<Coin<C>>,
        Option<Coin<C>>,
        Option<FungibleAsset>,
        Option<FungibleAsset>,
        DecreasePositionSuccessEvent,
    ) {
        let DecreasePositionResult {
            legacy,
            to_trader_legacy,
            rebate_legacy,
            to_trader_fa,
            rebate_fa,
            event,
        } = res;

        (legacy, to_trader_legacy, rebate_legacy, to_trader_fa, rebate_fa, event)
    }

    public(friend) fun decrease_position<Collateral, Index, Direction>(
        position: &mut Position<Collateral>,
        collateral_price_threshold: Decimal,
        rebate_rate: Rate,
        long: bool,
        decrease_amount: u64,
        lp_supply_amount: Decimal,
        timestamp: u64,
        treasury_address: address,
        treasury_ratio: Rate
    ): (u64, Option<DecreasePositionResult<Collateral>>, Option<DecreasePositionFailedEvent>) acquires Vault, Symbol {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        let symbol = borrow_global_mut<Symbol<Index, Direction>>(@perpetual);
        let index_price = agg_price::parse_config(
            &symbol.price_config,
            timestamp
        );

        // Pool errors are no need to be catched
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(symbol.decrease_enabled, ERR_DECREASE_DISABLED);

        // refresh vault
        refresh_vault(vault, timestamp);
        // refresh symbol
        let delta_size = symbol_delta_size(symbol, &index_price, long);
        refresh_symbol(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );

        // decrease position
        let (code, result) = positions::decrease_position<Collateral>(
            position,
            &collateral_price,
            &index_price,
            collateral_price_threshold,
            long,
            decrease_amount,
            vault.acc_reserving_rate,
            symbol.acc_funding_rate,
            timestamp,
        );
        emit(RateChanged {
            acc_reserving_rate: vault.acc_reserving_rate,
            acc_funding_rate: symbol.acc_funding_rate,
        });
        if (code > 0) {
            option::destroy_none(result);

            let event = DecreasePositionFailedEvent {
                collateral_price: agg_price::price_of(&collateral_price),
                index_price: agg_price::price_of(&index_price),
                decrease_amount,
                code,
            };
            return (code, option::none(), option::some(event))
        };

        let (
            legacy,
            closed,
            has_profit,
            settled_amount,
            decreased_reserved_amount,
            decrease_size,
            reserving_fee_amount,
            decrease_fee_value,
            reserving_fee_value,
            funding_fee_value,
            to_vault_legacy,
            to_trader_legacy,
            to_vault_fa,
            to_trader_fa,
        ) = positions::unwrap_decrease_position_result(option::destroy_some(result));

        // compute rebate
        let rebate_value = decimal::mul_with_rate(decrease_fee_value, rebate_rate);
        let rebate_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, rebate_value)
        );
        // compute and settle treasrury reserve amount
        let treasury_reserve_value = decimal::mul_with_rate(decrease_fee_value, treasury_ratio);
        let treasury_reserve_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, treasury_reserve_value)
        );
        if (legacy) {
            let treasury = coin::extract(&mut vault.liquidity_legacy, treasury_reserve_amount);
            coin::deposit(treasury_address, treasury);

        } else {
            let treasury = primary_fungible_store::withdraw(
                &account::create_signer_with_capability(option::borrow(&vault.liquidity_store_account)),
                get_metadata<Collateral>(),
                treasury_reserve_amount
            );
            primary_fungible_store::deposit(treasury_address, treasury);
        };

        // update vault
        vault.reserved_amount = vault.reserved_amount - decreased_reserved_amount;
        vault.unrealised_reserving_fee_amount = decimal::sub(
            vault.unrealised_reserving_fee_amount,
            reserving_fee_amount,
        );
        let (to_vault_amount, vault_total) = if (legacy) {
            let amount = coin::value(option::borrow(&to_vault_legacy));
            coin::merge(&mut vault.liquidity_legacy, option::destroy_some(to_vault_legacy));
            option::destroy_none(to_vault_fa);
            (amount, coin::value(&vault.liquidity_legacy))
        } else {
            let amount = fungible_asset::amount(option::borrow(&to_vault_fa));
            let liquidity_addr =
                account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account));
            primary_fungible_store::deposit(
                liquidity_addr,
                option::destroy_some(to_vault_fa)
            );
            option::destroy_none(to_vault_legacy);
            (amount, primary_fungible_store::balance(liquidity_addr, get_metadata<Collateral>()))
        };
        emit(VaultDepositEvent<Collateral>{amount: to_vault_amount});
        assert!(vault_total > rebate_amount, ERR_INSUFFICIENT_LIQUIDITY);
        let (rebate_legacy, rebate_fa) = if (legacy) {
            let rebate = coin::extract(&mut vault.liquidity_legacy, rebate_amount);
            (option::some(rebate), option::none<FungibleAsset>())
        } else {
            let rebate = primary_fungible_store::withdraw(
                 &account::create_signer_with_capability(option::borrow(&vault.liquidity_store_account)),
                get_metadata<Collateral>(),
                rebate_amount
            );
            (option::none<Coin<Collateral>>(), option::some(rebate))
        };

        // update symbol
        symbol.opening_size = decimal::sub(symbol.opening_size, decrease_size);
        symbol.opening_amount = symbol.opening_amount - decrease_amount;
        symbol.unrealised_funding_fee_value = sdecimal::sub(
            symbol.unrealised_funding_fee_value,
            funding_fee_value,
        );
        let delta_realised_pnl = sdecimal::sub_with_decimal(
            sdecimal::from_decimal(
                !has_profit,
                agg_price::coins_to_value(&collateral_price, settled_amount),
            ),
            // exclude: decrease fee - rebate - treasury_reserve + reserving fee
            decimal::add(
                decimal::sub(
                    decimal::sub(decrease_fee_value, rebate_value),
                    treasury_reserve_value
                ),
                reserving_fee_value,
            ),
        );
        symbol.realised_pnl = sdecimal::add(symbol.realised_pnl, delta_realised_pnl);

        let result = DecreasePositionResult {
            legacy,
            to_trader_legacy,
            to_trader_fa,
            rebate_legacy,
            rebate_fa,
            event: DecreasePositionSuccessEvent {
                collateral_price: agg_price::price_of(&collateral_price),
                index_price: agg_price::price_of(&index_price),
                decrease_amount,
                decrease_fee_value,
                reserving_fee_value,
                funding_fee_value,
                delta_realised_pnl,
                closed,
                has_profit,
                settled_amount,
                rebate_amount,
            },
        };
        emit(PoolDecreasePosition{
            collateral_price,
            index_price,
            rebate_amount,
            treasury_reserve_amount
        });
        (code, option::some(result), option::none())

    }

    public(friend) fun decrease_reserved_from_position<Collateral>(
        position: &mut Position<Collateral>,
        decrease_amount: u64,
        timestamp: u64,
    ): DecreaseReservedFromPositionEvent acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        // refresh vault
        refresh_vault(vault, timestamp);

        let (decreased_reserved_legacy, decreased_reserved_fa) = positions::decrease_reserved_from_position(
            position,
            decrease_amount,
            vault.acc_reserving_rate,
        );
        
        // update vault
        vault.reserved_amount = vault.reserved_amount - decrease_amount;
        if(vault.legacy) {
            coin::merge(&mut vault.liquidity_legacy, option::destroy_some(decreased_reserved_legacy));
            option::destroy_none(decreased_reserved_fa);
        } else {
            primary_fungible_store::deposit(
                account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account)),
                option::destroy_some(decreased_reserved_fa)
            );
            option::destroy_none(decreased_reserved_legacy)
        };

        DecreaseReservedFromPositionEvent { decrease_amount }

    }

    public(friend) fun pledge_in_position_legacy<Collateral>(
        position: &mut Position<Collateral>,
        pledge: Coin<Collateral>,
    ): PledgeInPositionEvent{
        let pledge_amount = coin::value(&pledge);

        positions::pledge_in_position<Collateral>(position, option::some(pledge), option::none<FungibleAsset>());
        PledgeInPositionEvent {
            pledge_amount
        }
    }

    public(friend) fun pledge_in_position_fa<Collateral>(
        position: &mut Position<Collateral>,
        pledge: FungibleAsset,
    ): PledgeInPositionEvent{
        let pledge_amount = fungible_asset::amount(&pledge);

        positions::pledge_in_position<Collateral>(position, option::none<Coin<Collateral>>(), option::some(pledge));
        PledgeInPositionEvent {
            pledge_amount
        }
    }

    public(friend) fun redeem_from_position<Collateral, Index, Direction>(
        position: &mut Position<Collateral>,
        long: bool,
        redeem_amount: u64,
        lp_supply_amount: Decimal,
        timestamp: u64
    ): (bool, Option<Coin<Collateral>>, Option<FungibleAsset>, RedeemFromPositionEvent) acquires Vault, Symbol {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        let symbol = borrow_global_mut<Symbol<Index, Direction>>(@perpetual);
        let index_price = agg_price::parse_config(
            &symbol.price_config,
            timestamp
        );

        // Pool errors are no need to be catched
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(symbol.decrease_enabled, ERR_DECREASE_DISABLED);

        // refresh vault
        refresh_vault(vault, timestamp);
        // refresh symbol
        let delta_size = symbol_delta_size(symbol, &index_price, long);
        refresh_symbol(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );

        // redeem
        let (redeem_legacy, redeem_fa) = positions::redeem_from_position(
            position,
            &collateral_price,
            &index_price,
            long,
            redeem_amount,
            vault.acc_reserving_rate,
            symbol.acc_funding_rate,
            timestamp,
        );


        emit(RateChanged {
            acc_reserving_rate: vault.acc_reserving_rate,
            acc_funding_rate: symbol.acc_funding_rate,
        });

        let event = RedeemFromPositionEvent {
            collateral_price: agg_price::price_of(&collateral_price),
            index_price: agg_price::price_of(&index_price),
            redeem_amount,
        };

        (vault.legacy, redeem_legacy, redeem_fa, event)
    }

    public(friend) fun liquidate_position<Collateral, Index, Direction>(
        position: &mut Position<Collateral>,
        long: bool,
        lp_supply_amount: Decimal,
        timestamp: u64,
        liquidator: address,
    ): (Option<Coin<Collateral>>, Option<FungibleAsset>, LiquidatePositionEvent) acquires Vault, Symbol {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        let symbol = borrow_global_mut<Symbol<Index, Direction>>(@perpetual);
        let index_price = agg_price::parse_config(
            &symbol.price_config,
            timestamp
        );
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        assert!(symbol.liquidate_enabled, ERR_LIQUIDATE_DISABLED);

        // refresh vault
        refresh_vault(vault, timestamp);
        // refresh symbol
        let delta_size = symbol_delta_size(symbol, &index_price, long);
        refresh_symbol(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );

        let (
            liquidator_bonus_amount,
            trader_loss_amount,
            position_amount,
            reserved_amount,
            position_size,
            reserving_fee_amount,
            reserving_fee_value,
            funding_fee_value,
            to_vault_legacy,
            to_liquidator_legacy,
            to_vault_fa,
            to_liquidator_fa,
        ) = positions::liquidate_position(
            position,
            &collateral_price,
            &index_price,
            long,
            vault.acc_reserving_rate,
            symbol.acc_funding_rate,
        );

        emit(RateChanged {
            acc_reserving_rate: vault.acc_reserving_rate,
            acc_funding_rate: symbol.acc_funding_rate,
        });

        // update vault
        vault.reserved_amount = vault.reserved_amount - reserved_amount;
        vault.unrealised_reserving_fee_amount = decimal::sub(
            vault.unrealised_reserving_fee_amount,
            reserving_fee_amount,
        );
        let _to_vault_amount = if(vault.legacy) {
            let to_vault = option::destroy_some(to_vault_legacy);
            option::destroy_none(to_vault_fa);
            let amount = coin::value(&to_vault);
            emit(VaultDepositEvent<Collateral>{amount});
            coin::merge(&mut vault.liquidity_legacy, to_vault);
            amount
        } else {
            let to_vault = option::destroy_some(to_vault_fa);
            let amount = fungible_asset::amount(&to_vault);
            option::destroy_none(to_vault_legacy);
            let addr = account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account));
            primary_fungible_store::deposit(addr, to_vault);
            emit(VaultDepositEvent<Collateral>{amount});
            amount
        };

        // update symbol
        symbol.opening_size = decimal::sub(symbol.opening_size, position_size);
        symbol.opening_amount = symbol.opening_amount - position_amount;
        symbol.unrealised_funding_fee_value = sdecimal::sub(
            symbol.unrealised_funding_fee_value,
            funding_fee_value,
        );
        let delta_realised_pnl = sdecimal::sub_with_decimal(
            sdecimal::from_decimal(
                true,
                agg_price::coins_to_value(
                    &collateral_price,
                    trader_loss_amount,
                ),
            ),
            // exclude reserving fee
            reserving_fee_value,
        );
        symbol.realised_pnl = sdecimal::add(symbol.realised_pnl, delta_realised_pnl);

        let event = LiquidatePositionEvent {
            liquidator,
            collateral_price: agg_price::price_of(&collateral_price),
            index_price: agg_price::price_of(&index_price),
            reserving_fee_value,
            funding_fee_value,
            delta_realised_pnl,
            loss_amount: trader_loss_amount,
            liquidator_bonus_amount,
        };
        emit(PoolLiquidation{
            collateral_price,
            index_price
        });

        (to_liquidator_legacy, to_liquidator_fa, event)
    }

    public(friend) fun symbol_price_config<Index, Direction>(): AggPriceConfig acquires Symbol {
        borrow_global<Symbol<Index, Direction>>(@perpetual).price_config
    }

    fun refresh_vault<C>(
        vault: &mut Vault<C>,
        timestamp: u64,
    ) {
        let delta_rate = vault_delta_reserving_rate(
            vault,
            timestamp,
        );
        vault.acc_reserving_rate = vault_acc_reserving_rate(vault, delta_rate);
        vault.unrealised_reserving_fee_amount =
            vault_unrealised_reserving_fee_amount(vault, delta_rate);
        vault.last_update = timestamp;
    }

    fun refresh_symbol<Index, Direction>(
        symbol: &mut Symbol<Index, Direction>,
        delta_size: SDecimal,
        lp_supply_amount: Decimal,
        timestamp: u64,
    ) {
        let delta_rate = symbol_delta_funding_rate(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );
        symbol.acc_funding_rate = symbol_acc_funding_rate(symbol, delta_rate);
        symbol.unrealised_funding_fee_value =
            symbol_unrealised_funding_fee_value(symbol, delta_rate);
        symbol.last_update = timestamp;
    }

    public fun vault_delta_reserving_rate<C>(
        vault: &Vault<C>,
        timestamp: u64,
    ): Rate {
        if (vault.last_update > 0) {
            let elapsed = timestamp - vault.last_update;
            if (elapsed > 0) {
                return model::compute_reserving_fee_rate(
                    &vault.reserving_fee_model,
                    vault_utilization(vault),
                    elapsed,
                )
            }
        };
        rate::zero()
    }

    public fun vault_acc_reserving_rate<C>(
        vault: &Vault<C>,
        delta_rate: Rate,
    ): Rate {
        rate::add(vault.acc_reserving_rate, delta_rate)
    }

    public fun vault_unrealised_reserving_fee_amount<C>(
        vault: &Vault<C>,
        delta_rate: Rate,
    ): Decimal {
        decimal::add(
            vault.unrealised_reserving_fee_amount,
            decimal::mul_with_rate(
                decimal::from_u64(vault.reserved_amount),
                delta_rate,
            ),
        )
    }

    public fun vault_utilization<C>(vault: &Vault<C>): Rate {
        let supply_amount = vault_supply_amount(vault);
        if (decimal::is_zero(&supply_amount)) {
            rate::zero()
        } else {
            decimal::to_rate(
                decimal::div(
                    decimal::from_u64(vault.reserved_amount),
                    supply_amount,
                )
            )
        }
    }

    public fun vault_supply_amount<C>(vault: &Vault<C>): Decimal {
        // liquidity_amount + reserved_amount + unrealised_reserving_fee_amount
        let liquidity_amount = if (vault.legacy) {
            coin::value(&vault.liquidity_legacy)
        } else {
            let addr = account::get_signer_capability_address(option::borrow(&vault.liquidity_store_account));
            primary_fungible_store::balance(addr, get_metadata<C>())
        };
        decimal::add(
            decimal::from_u64(
                liquidity_amount + vault.reserved_amount
            ),
            vault.unrealised_reserving_fee_amount,
        )
    }

    public fun symbol_delta_size<Index, Direction>(
        symbol: &Symbol<Index, Direction>,
        price: &AggPrice,
        long: bool,
    ): SDecimal {
        let latest_size = agg_price::coins_to_value(
            price,
            symbol.opening_amount,
        );
        let cmp = decimal::gt(&latest_size, &symbol.opening_size);
        let (is_positive, value) = if (cmp) {
            (!long, decimal::sub(latest_size, symbol.opening_size))
        } else {
            (long, decimal::sub(symbol.opening_size, latest_size))
        };

        sdecimal::from_decimal(is_positive, value)
    }

    public fun symbol_delta_funding_rate<Index, Direction>(
        symbol: &Symbol<Index, Direction>,
        delta_size: SDecimal,
        lp_supply_amount: Decimal,
        timestamp: u64,
    ): SRate {
        if (symbol.last_update > 0) {
            let elapsed = timestamp - symbol.last_update;
            if (elapsed > 0) {
                return model::compute_funding_fee_rate(
                    &symbol.funding_fee_model,
                    symbol_pnl_per_lp(symbol, delta_size, lp_supply_amount),
                    elapsed,
                )
            }
        };
        srate::zero()
    }

    public fun symbol_pnl_per_lp<Index, Direction>(
        symbol: &Symbol<Index, Direction>,
        delta_size: SDecimal,
        lp_supply_amount: Decimal,
    ): SDecimal {
        let pnl = sdecimal::add(
            sdecimal::add(
                symbol.realised_pnl,
                symbol.unrealised_funding_fee_value,
            ),
            delta_size,
        );
        sdecimal::div_by_decimal(pnl, lp_supply_amount)
    }

    public fun symbol_acc_funding_rate<Index, Direction>(
        symbol: &Symbol<Index, Direction>,
        delta_rate: SRate,
    ): SRate {
        srate::add(symbol.acc_funding_rate, delta_rate)
    }

    public fun symbol_unrealised_funding_fee_value<Index, Direction>(
        symbol: &Symbol<Index, Direction>,
        delta_rate: SRate,
    ): SDecimal {
        sdecimal::add(
            symbol.unrealised_funding_fee_value,
            sdecimal::from_decimal(
                srate::is_positive(&delta_rate),
                decimal::mul_with_rate(
                    symbol.opening_size,
                    srate::value(&delta_rate),
                ),
            ),
        )
    }

    public(friend) fun vault_valuation(): (Decimal, Decimal) acquires Vault {
        let timestamp = timestamp::now_seconds();
        let total_value = decimal::zero();
        let total_weight = decimal::zero();
        // loop through all of vault
        let (total_value, total_weight) = valuate_vault<AptosCoin>(timestamp, total_value, total_weight);
        let (total_value, total_weight) = valuate_vault<USDC>(timestamp, total_value, total_weight);
        let (total_value, total_weight) = valuate_vault<USDT>(timestamp, total_value, total_weight);
        let (total_value, total_weight) = valuate_vault<ETH>(timestamp, total_value, total_weight);

        (total_value, total_weight)

    }

    public(friend) fun symbol_valuation(): SDecimal acquires Symbol {
        let timestamp = timestamp::now_seconds();
        let lp_supply_amount = lp_supply_amount();
        let total_value = sdecimal::zero();

        // loop through all of Symbol
        total_value = valuate_symbol<AptosCoin, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<AptosCoin, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<BTC, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<BTC, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<ETH, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<ETH, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<DOGE, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<DOGE, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<SOL, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<SOL, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<PEPE, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<PEPE, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<AVAX, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<AVAX, SHORT>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<BNB, LONG>(timestamp, lp_supply_amount, total_value);
        total_value = valuate_symbol<BNB, SHORT>(timestamp, lp_supply_amount, total_value);

        total_value

    }

    fun valuate_vault<Collateral> (
        timestamp: u64,
        total_value: Decimal,
        total_weight: Decimal
    ):(Decimal, Decimal) acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        refresh_vault(vault, timestamp);
        let value = agg_price::coins_to_value(
            &collateral_price,
            decimal::floor_u64(vault_supply_amount(vault)),
        );
        total_value = decimal::add(total_value, value);
        let weight = vault_weight<Collateral>(vault);
        total_weight = decimal::add(total_weight, weight);
        (total_value, total_weight)
    }

    public(friend) fun vault_value<Collateral>(timestamp: u64): Decimal acquires Vault {
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        assert!(vault.enabled, ERR_VAULT_DISABLED);
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        refresh_vault(vault, timestamp);
        let value = agg_price::coins_to_value(
            &collateral_price,
            decimal::floor_u64(vault_supply_amount(vault)),
        );
        value

    }

    fun valuate_symbol<Index, Direction>(timestamp: u64, lp_supply_amount: Decimal, total_value: SDecimal): SDecimal acquires Symbol {
        let symbol = borrow_global_mut<Symbol<Index, Direction>>(@perpetual);
        let index_price = agg_price::parse_config(
            &symbol.price_config,
            timestamp
        );
        let long = parse_direction<Direction>();
        let delta_size = symbol_delta_size(symbol, &index_price, long);
        refresh_symbol(
            symbol,
            delta_size,
            lp_supply_amount,
            timestamp,
        );
        let delta_size = sdecimal::add(delta_size, symbol.unrealised_funding_fee_value);
        sdecimal::add(total_value, delta_size)
    }

    public fun vault_weight<C>(vault: &Vault<C>): Decimal {
        vault.weight
    }

    public fun lp_supply_amount(): Decimal {
        // LP decimal is 6
        let supply = lp::get_supply();
        decimal::from_u128(supply)
    }

    public fun parse_direction<Direction>(): bool {
        let direction = type_info::type_of<Direction>();
        if (direction == type_info::type_of<LONG>()) {
            true
        } else {
            assert!(
                direction == type_info::type_of<SHORT>(),
                ERR_INVALID_DIRECTION,
            );
            false
        }
    }

    public fun compute_rebase_fee_rate(
        model: &RebaseFeeModel,
        increase: bool,
        vault_value: Decimal,
        total_vaults_value: Decimal,
        vault_weight: Decimal,
        total_vaults_weight: Decimal,
    ): Rate {
        if (decimal::eq(&vault_value, &total_vaults_value)) {
            // first deposit or withdraw all should be zero fee
            rate::zero()
        } else {
            let ratio = decimal::to_rate(
                decimal::div(vault_value, total_vaults_value)
            );
            let target_ratio = decimal::to_rate(
                decimal::div(vault_weight, total_vaults_weight)
            );

            model::compute_rebase_fee_rate(model, increase, ratio, target_ratio)
        }
    }

    fun truncate_decimal(value: Decimal): u64 {
        // decimal's precision is 18, we need to truncate it to 6
        let value = decimal::to_raw(value);
        value = value / 1_000_000_000_000;

        (value as u64)
    }

    public(friend) fun collateral_value<Collateral>(amount: u64): Decimal acquires Vault{
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let timestamp = timestamp::now_seconds();

        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );
        agg_price::coins_to_value(&collateral_price, amount)
    }

    public(friend) fun collateral_amount<Collateral>(value: Decimal): u64 acquires Vault{
        let vault = borrow_global_mut<Vault<Collateral>>(@perpetual);
        let timestamp = timestamp::now_seconds();
        let collateral_price = agg_price::parse_config(
            &vault.price_config,
            timestamp
        );

        let withdraw_amount = decimal::floor_u64(
            agg_price::value_to_coins(&collateral_price, value)
        );
        withdraw_amount

    }

}
