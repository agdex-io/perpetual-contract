import {
    Account,
    Aptos,
    APTOS_COIN,
    AptosConfig,
    Ed25519PrivateKey,
    Network,
    MoveVector,
    U8,
    U64
} from '@aptos-labs/ts-sdk'


export const MODULE_ADDRESS = "0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d"
export const FEERDER_ADDRESS = "0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387"
export const COIN_ADDRESS = "0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5"

export const APT_FEEDER_ADDRESS =
    "44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e"
export const USDT_FEEDER_ADDRESS =
    "41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722"
export const USDC_FEEDER_ADDRESS =
    "1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588"
export const BTC_FEEDER_ADDRESS =
    "f9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b"
export const ETH_FEEDER_ADDRESS =
    "ca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6"
export const BNB_FEEDER_ADDRESS =
    "ecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a"
export const SOL_FEEDER_ADDRESS =
    "fe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd"
export const AVAX_FEEDER_ADDRESS =
    "d7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9"
export const PEPE_FEEDER_ADDRESS =
    "ed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0"
export const DOGE_FEEDER_ADDRESS =
    "31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae"

export const formatAptosDecimal = (value: number, decimals: number = 8) => {
    return Number((value * Math.pow(10, decimals)).toFixed(0));
}

const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress =
    MODULE_ADDRESS
const coinAddress =
    COIN_ADDRESS

const PRIVATE_KEY = '0x5adbf0299c7ddd87a75455c03d1b56880eb89e0f1d99cc3f2e0d748aca9c18d4'

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

async function simulateTransaction() {

    const transaction = await aptos.transaction.build.simple({
        sender: singer.accountAddress,
        data: {
            function: `${moduleAddress}::market::deposit`,
            typeArguments: [APTOS_VAULT_ADDRESS],
            functionArguments: [
                100000000, // deposit amount
                0,
                new MoveVector<MoveVector<U8>>([]),
            ],
        },
    })

    const response = await aptos.transaction.simulate.simple({
        signerPublicKey: singer.publicKey,
        transaction
    })
    console.log(
        // get mint amount as price
        response[0]['events'][4]
    )
}

async function main() {
    await simulateTransaction()
}

(async () => {
    await main()
})()