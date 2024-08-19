import {
    Account,
    Aptos,
    APTOS_COIN,
    AptosConfig,
    Ed25519PrivateKey,
    Network,
} from '@aptos-labs/ts-sdk'

const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress =
    '0xd6f52e4b31ca8fc8708da946344b1577b1466450f9d6b53d0a3066a1df90861b'
const coinAddress =
    '0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0'
const PRIVATE_KEY =
    '0xd1b1905f11e418345712c49e3e014e8f322ebae38f248398941477b12b638822'

const singer = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(PRIVATE_KEY),
})

const MOCK_USDC_COIN_STORE = `0x1::coin::CoinStore<${coinAddress}::usdc::USDC>`
const MOCK_USDT_COIN_STORE = `0x1::coin::CoinStore<${coinAddress}::usdt::USDT>`
const MOCK_LP_COIN_STORE = `0x1::coin::CoinStore<${moduleAddress}::lp::LP>`

//vault
const APTOS_VAULT_ADDRESS = APTOS_COIN
const USDC_VAULT_ADDRESS = `${coinAddress}::usdc::USDC`
const USDT_VAULT_ADDRESS = `${coinAddress}::usdt::USDT`
const BTC_VAULT_ADDRESS = `${coinAddress}::btc::BTC`
const ETH_VAULT_ADDRESS = `${coinAddress}::ETH::ETH`
//symbol
const BTC_SYMBOL_ADDRESS = `${coinAddress}::btc::BTC`
const ETH_SYMBOL_ADDRESS = `${coinAddress}::ETH::ETH`
const BNB_SYMBOL_ADDRESS = `${coinAddress}::BNB::BNB`
const SOL_SYMBOL_ADDRESS = `${coinAddress}::SOL::SOL`
const AVAX_SYMBOL_ADDRESS = `${coinAddress}::AVAX::AVAX`
const APTOS_SYMBOL_ADDRESS = APTOS_COIN
const DOGE_SYMBOL_ADDRESS = `${coinAddress}::DOGE::DOGE`
const PEPE_SYMBOL_ADDRESS = `${coinAddress}::PEPE::PEPE`

//direction
const SIDE_LONG = `${moduleAddress}::pool::LONG`
const SIDE_SHORT = `${moduleAddress}::pool::SHORT`
//fee
const FEE_ADDRESS = APTOS_COIN
//list
const VAULT_LIST = [
    {
        name: 'APT',
        vaultType: APTOS_VAULT_ADDRESS,
        weight: '50000000000000000',
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e',
        param_multiplier: '800000000000000',
    },
    {
        name: 'USDC',
        vaultType: USDC_VAULT_ADDRESS,
        weight: '300000000000000000',
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588',
        param_multiplier: '800000000000000',
    },
    {
        name: 'USDT',
        vaultType: USDT_VAULT_ADDRESS,
        weight: '300000000000000000',
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722',
        param_multiplier: '800000000000000',
    },
    {
        name: 'BTC',
        vaultType: BTC_VAULT_ADDRESS,
        weight: '200000000000000000',
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722',
        param_multiplier: '800000000000000',
    },
    {
        name: 'ETH',
        vaultType: ETH_VAULT_ADDRESS,
        weight: '150000000000000000',
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722',
        param_multiplier: '800000000000000',
    },
]
const SYMBOL_LIST = [
    {
        name: 'BTC',
        symbolType: BTC_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            'f9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },
    {
        name: 'ETH',
        symbolType: ETH_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            'ca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },
    {
        name: 'BNB',
        symbolType: BNB_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            'ecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },
    {
        name: 'SOL',
        symbolType: SOL_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            'fe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },

    {
        name: 'AVAX',
        symbolType: AVAX_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            'd7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },

    {
        name: 'APT',
        symbolType: APTOS_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },

    {
        name: 'DOGE',
        symbolType: DOGE_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            '31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },

    {
        name: 'PEPE',
        symbolType: PEPE_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder:
            'ed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0',
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: '5000000000000000000',
        open_fee_bps: '1000000000000000',
        decrease_fee_bps: '1000000000000000',
        liquidation_threshold: '980000000000000000',
        liquidation_bonus: '10000000000000000',
    },
]
const DIRECTION_LIST = [SIDE_LONG, SIDE_SHORT]

function hexStringToUint8Array(hexString: string): Uint8Array {
    if (hexString.length % 2 !== 0) {
        hexString = '0' + hexString;
    }
    const byteArray = new Uint8Array(hexString.length / 2);
    for (let i = 0; i < byteArray.length; i++) {
        byteArray[i] = parseInt(hexString.slice(i * 2, i * 2 + 2), 16);
    }
    return byteArray;
}

async function executeAddNewVault() {
    for (const vault of VAULT_LIST) {
        const transaction = await aptos.transaction.build.simple({
            sender: singer.accountAddress,
            data: {
                function: `${moduleAddress}::market::add_new_vault`,
                typeArguments: [vault.vaultType],
                functionArguments: [
                    vault.weight,
                    vault.max_interval,
                    vault.max_price_confidence,
                    hexStringToUint8Array(vault.feeder),
                    vault.param_multiplier,
                ],
            },
        })

        const committedTransaction = await aptos.signAndSubmitTransaction({
            signer: singer,
            transaction,
        })

        const response = await aptos.waitForTransaction({
            transactionHash: committedTransaction.hash
        })
        console.log(
            `🚀 ~ Transaction submitted Add new Vault : ${vault.name}`,
            response
        )
    }
}

async function executeAddNewSymbol() {
    for (const symbol of SYMBOL_LIST) {
        for (const direction of DIRECTION_LIST) {
            console.log(`🚀 ~ Add new Symbol Execute ~ symbol:${symbol.name}, direction:${direction} `)
            const transaction = await aptos.transaction.build.simple({
                sender: singer.accountAddress,
                data: {
                    function: `${moduleAddress}::market::add_new_symbol`,
                    typeArguments: [symbol.symbolType, direction],
                    functionArguments: [
                        symbol.max_interval,
                        symbol.max_price_confidence,
                        hexStringToUint8Array(symbol.feeder),
                        symbol.param_multiplier,
                        symbol.param_max,
                        symbol.max_leverage,
                        symbol.min_holding_duration,
                        symbol.max_reserved_multiplier,
                        symbol.min_collateral_value,
                        symbol.open_fee_bps,
                        symbol.decrease_fee_bps,
                        symbol.liquidation_threshold,
                        symbol.liquidation_bonus,
                    ],
                },
            })

            const committedTransaction = await aptos.signAndSubmitTransaction({
                signer: singer,
                transaction,
            })

            const response = await aptos.waitForTransaction({
                transactionHash: committedTransaction.hash
            })

            console.log(
                `🚀 ~ Transaction submitted Add new Symbol : ${symbol.name}`,
                response
            )
        }
    }
}

async function executeAddCollateralToSymbol() {
    for (const vault of VAULT_LIST) {
        for (const symbol of SYMBOL_LIST) {
            for (const direction of DIRECTION_LIST) {
                console.log(`🚀 ~ Add new Vault Execute ~ vault:${vault.name}, symbol:${symbol.name}, direction:${direction} `)

                const transaction = await aptos.transaction.build.simple({
                    sender: singer.accountAddress,
                    data: {
                        function: `${moduleAddress}::market::add_collateral_to_symbol`,
                        typeArguments: [
                            vault.vaultType, symbol.symbolType, direction
                        ],
                        functionArguments: [],
                    },
                });

                try {
                    const committedTransaction = await aptos.signAndSubmitTransaction({
                        signer: singer,
                        transaction,
                    });
                    const response = await aptos.waitForTransaction({
                        transactionHash: committedTransaction.hash
                    })
                    console.log(`🚀 ~ Transaction submitted Collateral => Symbol`, response);
                } catch (error) {
                    console.log("🚀 ~ executeAddCollateralToSymbol ~ error:", error)

                }

            }
        }
    }
}

async function main() {
    // await executeAddNewVault()
    // await executeAddNewSymbol()
    await executeAddCollateralToSymbol()
}

(async () => {
    await main()
})()