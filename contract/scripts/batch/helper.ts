import { APTOS_COIN } from "@aptos-labs/ts-sdk"

const moduleAddress = "0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d"
const coinAddress = "0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5"

export const MOCK_USDC_COIN_STORE = `0x1::coin::CoinStore<${coinAddress}::usdc::USDC>`
export const MOCK_USDT_COIN_STORE = `0x1::coin::CoinStore<${coinAddress}::usdt::USDT>`
export const MOCK_BTC_COIN_STORE = `0x1::coin::CoinStore<${coinAddress}::btc::BTC>`
export const MOCK_ETH_COIN_STORE = `0x1::coin::CoinStore<${coinAddress}::ETH::ETH>`

export const MOCK_LP_COIN_STORE = `0x1::coin::CoinStore<${moduleAddress}::lp::LP>`

export const SIDE_LONG = `${moduleAddress}::pool::LONG`
export const SIDE_SHORT = `${moduleAddress}::pool::SHORT`

export const LONG = 'LONG'
export const SHORT = 'SHORT'

export type PoolInfo = {
    name: string
    tokenName: string
    tokenSymbol: string
    tokenAddress: string
    pythFeederAddress: string
    decimal: number
    icon: string
}

export type VaultInfo = {
    name: string,
    symbol: string,
    tokenAddress: string,
    tokenStore: string,
    decimal: number
}

export const LeverageButtonGroup = [
    { value: 2, label: '2x' },
    { value: 10, label: '10x' },
    { value: 20, label: '20x' },
    { value: 50, label: '50x' },
    { value: 100, label: '100x' }
]

export const divideAndCeilTo8Decimals = (a: number, b: number, p: number = 1e6) => {
    const result = a / b;
    const roundedResult = Math.ceil(result * p) / p
    return roundedResult;
}


export const APTOS_COIN_STORE = "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
export const PoolList: PoolInfo[] = [
    {
        name: "BTC/USD",
        tokenName: 'BTC',
        tokenSymbol: 'BTC',
        tokenAddress: `${coinAddress}::btc::BTC`,
        pythFeederAddress: "0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b",
        decimal: 8,
        icon: '/token/btc.svg'
    },
    {
        name: "ETH/USD",
        tokenName: 'ETH',
        tokenSymbol: 'ETH',
        tokenAddress: `${coinAddress}::ETH::ETH`,
        pythFeederAddress: "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6",
        decimal: 8,
        icon: '/token/eth.svg'
    },
    {
        name: "BNB/USD",
        tokenName: 'BNB',
        tokenSymbol: 'BNB',
        tokenAddress: `${coinAddress}::BNB::BNB`,
        pythFeederAddress: "ecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a",
        decimal: 8,
        icon: '/token/bnb.svg'
    },
    {
        name: "SOL/USD",
        tokenName: 'SOL',
        tokenSymbol: 'SOL',
        tokenAddress: `${coinAddress}::SOL::SOL`,
        pythFeederAddress: "fe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd",
        decimal: 8,
        icon: '/token/sol.svg'
    },
    {
        name: "AVAX/USD",
        tokenName: 'AVAX',
        tokenSymbol: 'AVAX',
        tokenAddress: `${coinAddress}::AVAX::AVAX`,
        pythFeederAddress: "d7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9",
        decimal: 8,
        icon: '/token/avax.svg'
    },
    {
        name: "APT/USD",
        tokenName: 'APTOS',
        tokenSymbol: 'APT',
        tokenAddress: APTOS_COIN,
        pythFeederAddress: "0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e",
        decimal: 8,
        icon: '/token/aptos.svg'
    },
    {
        name: "DOGE/USD",
        tokenName: 'DOGE',
        tokenSymbol: 'DOGE',
        tokenAddress: `${coinAddress}::DOGE::DOGE`,
        pythFeederAddress: "31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae",
        decimal: 8,
        icon: '/token/doge.svg'
    },
    {
        name: "PEPE/USD",
        tokenName: 'PEPE',
        tokenSymbol: 'PEPE',
        tokenAddress: `${coinAddress}::PEPE::PEPE`,
        pythFeederAddress: "ed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0",
        decimal: 8,
        icon: '/token/pepe.svg'
    },
]

export type LpTokenInfo = {
    name: String
    tokenName: String
    tokenSymbol: String
    tokenAddress: String
    tokenStore: String
    decimal: 6
}
export const LpToken: LpTokenInfo = {
    name: 'LP',
    tokenName: 'LP',
    tokenSymbol: 'LP',
    tokenAddress: `${moduleAddress}::lp::LP`,
    tokenStore: MOCK_LP_COIN_STORE,
    decimal: 6
}


export const getSideAddress = (side: string) => {
    return `${moduleAddress}::pool::${side}`
}
export const VaultList: VaultInfo[] = [
    {
        name: 'USDT',
        symbol: 'USDT',
        tokenAddress: `${coinAddress}::usdt::USDT`,
        tokenStore: MOCK_USDT_COIN_STORE,
        decimal: 6
    },

    {
        name: 'USDC',
        symbol: 'USDC',
        tokenAddress: `${coinAddress}::usdc::USDC`,
        tokenStore: MOCK_USDC_COIN_STORE,
        decimal: 6
    },
    {
        name: 'BTC',
        symbol: 'BTC',
        tokenAddress: `${coinAddress}::btc::BTC`,
        tokenStore: MOCK_BTC_COIN_STORE,
        decimal: 8
    },
    {
        name: 'ETH',
        symbol: 'ETH',
        tokenAddress: `${coinAddress}::ETH::ETH`,
        tokenStore: MOCK_ETH_COIN_STORE,
        decimal: 8
    },
    {
        name: 'APTOS',
        symbol: 'APT',
        tokenAddress: APTOS_COIN,
        tokenStore: APTOS_COIN_STORE,
        decimal: 8
    }
]
export type PriceFeederInfo = {
    tokenName: string
    tokenSymbol: string
    feederAddress: string
    decimal: number
}

export const PriceFeederList: PriceFeederInfo[] = [
    { tokenName: 'APTOS', tokenSymbol: 'APT', feederAddress: "0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e", decimal: 8 },
    { tokenName: 'USDT', tokenSymbol: 'USDT', feederAddress: "0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722", decimal: 6 },
    { tokenName: 'USDC', tokenSymbol: 'USDC', feederAddress: "0x1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588", decimal: 6 },
    { tokenName: 'BTC', tokenSymbol: "BTC", feederAddress: "0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b", decimal: 8 },
    { tokenName: 'ETH', tokenSymbol: 'ETH', feederAddress: "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6", decimal: 8 },
    { tokenName: 'BNB', tokenSymbol: 'BNB', feederAddress: "ecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a", decimal: 8 },
    { tokenName: 'SOL', tokenSymbol: 'SOL', feederAddress: "fe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd", decimal: 8 },
    { tokenName: 'AVAX', tokenSymbol: 'AVAX', feederAddress: "d7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9", decimal: 8 },
    { tokenName: 'PEPE', tokenSymbol: 'PEPE', feederAddress: "ed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0", decimal: 8 },
    { tokenName: 'DOGE', tokenSymbol: 'DOGE', feederAddress: "31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae", decimal: 8 }
];

export const FeeInfo = {
    rebateFee: "10000000000000000",
    treasuryReserveFee: "250000000000000000",
    decreaseFeeInfo: "1000000000000000"
}

