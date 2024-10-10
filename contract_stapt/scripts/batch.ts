import {
    Account,
    Aptos,
    APTOS_COIN,
    AptosConfig,
    Ed25519PrivateKey,
    Network,
} from '@aptos-labs/ts-sdk'
import axios from 'axios';
import { getSideAddress, PoolList, VaultList } from './batch/helper';

export const formatAptosDecimal = (value: number, decimals: number = 8) => {
    return Number((value * Math.pow(10, decimals)).toFixed(0));
}

const moduleAddress = "0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d"
export const coinAddress = "0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5"

const PRIVATE_KEY = '0x5adbf0299c7ddd87a75455c03d1b56880eb89e0f1d99cc3f2e0d748aca9c18d4'
const singer = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(PRIVATE_KEY),
})

const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)



//vault
const APTOS_VAULT_ADDRESS = APTOS_COIN
const USDC_VAULT_ADDRESS = `${coinAddress}::usdc::USDC`
const USDT_VAULT_ADDRESS = `${coinAddress}::usdt::USDT`
const BTC_VAULT_ADDRESS = `${coinAddress}::btc::BTC`
const ETH_VAULT_ADDRESS = `${coinAddress}::ETH::ETH`

//symbol
const APTOS_SYMBOL_ADDRESS = APTOS_COIN
const BTC_SYMBOL_ADDRESS = `${coinAddress}::btc::BTC`
const ETH_SYMBOL_ADDRESS = `${coinAddress}::ETH::ETH`
const BNB_SYMBOL_ADDRESS = `${coinAddress}::BNB::BNB`
const SOL_SYMBOL_ADDRESS = `${coinAddress}::SOL::SOL`
const AVAX_SYMBOL_ADDRESS = `${coinAddress}::AVAX::AVAX`
const DOGE_SYMBOL_ADDRESS = `${coinAddress}::DOGE::DOGE`
const PEPE_SYMBOL_ADDRESS = `${coinAddress}::PEPE::PEPE`

const APT_FEEDER_ADDRESS = "0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e"
const USDT_FEEDER_ADDRESS = "0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722"
const USDC_FEEDER_ADDRESS = '0x1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588'
const BTC_FEEDER_ADDRESS = "0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b"
const ETH_FEEDER_ADDRESS = "0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6"
const BNB_FEEDER_ADDRESS = "0xecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a"
const SOL_FEEDER_ADDRESS = "0xfe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd"
const AVAX_FEEDER_ADDRESS = "0xd7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9"
const PEPE_FEEDER_ADDRESS = "0xed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0"
const DOGE_FEEDER_ADDRESS = "0x31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae"

const PRICE_FEEDER_ADDRESS = "0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387"
const MODULE_ADDRESS = "0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d"
const COIN_ADDRESS = "0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5"

export const AptFeeder = APT_FEEDER_ADDRESS
export const UsdtFeeder = USDT_FEEDER_ADDRESS
export const UsdcFeeder = USDC_FEEDER_ADDRESS
export const BtcFeeder = BTC_FEEDER_ADDRESS
export const EthFeeder = ETH_FEEDER_ADDRESS
export const BnbFeeder = BNB_FEEDER_ADDRESS
export const SolFeeder = SOL_FEEDER_ADDRESS
export const AvaxFeeder = AVAX_FEEDER_ADDRESS
export const PepeFeeder = PEPE_FEEDER_ADDRESS
export const DogeFeeder = DOGE_FEEDER_ADDRESS


const priceIds = [
    { name: "APT", address: AptFeeder, priceDecimal: 8 },
    { name: "USDT", address: UsdtFeeder, priceDecimal: 8 },
    { name: "USDC", address: UsdcFeeder, priceDecimal: 8 },
    { name: "BTC", address: BtcFeeder, priceDecimal: 8 },
    { name: "ETH", address: EthFeeder, priceDecimal: 8 },
    { name: "BNB", address: BnbFeeder, priceDecimal: 8 },
    { name: "SOL", address: SolFeeder, priceDecimal: 8 },
    { name: "AVAX", address: AvaxFeeder, priceDecimal: 8 },
    { name: "PEPE", address: PepeFeeder, priceDecimal: 10 },
    { name: "DOGE", address: DogeFeeder, priceDecimal: 8 },
];

const fetchPythPricesData = async (item: any): Promise<any> => {
    try {
        const response = await axios.get(`https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=${item.address}`);
        return {
            name: item.name,
            symbol: item.name,
            binary: response.data.binary.data[0],
            parsed: response.data.parsed[0].price.price,
            priceDecimal: item.priceDecimal
        }
    } catch (error) {
        return null
    }
}

const fetchVaasBytes = async () => {
    let vasBytes: any[] = []
    for (let i = 0; i < priceIds.length; i++) {
        const vaa = await fetchPythPricesData(priceIds[i])
        const res: any = Array.from(Buffer.from(vaa?.binary, 'hex'))
        vasBytes.push(res)
    }

    return vasBytes
    // console.log('vasBytes:', vasBytes)
}


const LONG = 'LONG'
const SHORT = 'SHORT'
const side = LONG;


const vault = VaultList[0]
const symbol = PoolList[0]

const open_position = async (vasBytes) => {


    const transaction = await aptos.transaction.build.simple({
        sender: singer.accountAddress,
        data: {
            function: `${moduleAddress}::market::open_position`,
            typeArguments: [
                vault.tokenAddress,
                symbol.tokenAddress,
                getSideAddress(side),
                APTOS_COIN,
            ],
            functionArguments: [
                1,
                '632293',                                                                   // open_amount
                '200000000',                                                                // reserve_amount
                '10000000',                                                                  // collateral
                10,                                                                         // fee_amount
                '899944550999999872',                                                       // collateral_price_threshold
                '56700720324579996991488',                                                  // trigger price
                vasBytes                                                                    // limited_index_price
            ],
        },
    })

    const committedTx = await aptos.signAndSubmitTransaction({
        signer: singer,
        transaction: transaction,
    })

    const res = await aptos.waitForTransaction({
        transactionHash: committedTx.hash
    })

    // console.log(
    //     `🚀 ~ Transaction submitted Add: ${vault.name}`, res
    // )
}

export const getTableHandle = async (address: string, resourceType: `${string}::${string}::${string}`) => {
    const result = await aptos.getAccountResource({
        accountAddress: address,
        resourceType: resourceType
    })
    return { result }
}

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


export const SIDE_LONG = `${moduleAddress}::pool::LONG`
export const SIDE_SHORT = `${moduleAddress}::pool::SHORT`

export const getPositionTableHandle = async (vault: VaultInfo, symbol: PoolInfo) => {
    const longPositionResult: any =
        await getTableHandle(moduleAddress, `${moduleAddress}::market::PositionRecord<${vault.tokenAddress},${symbol.tokenAddress},${SIDE_LONG}>`)
    return { longPositionResult }
}

export const getAllUserPositions = async (ownerAddress: string, tableHandle: string) => {
    if (tableHandle && tableHandle.length !== 66) {
        tableHandle = '0x'.concat('0'.repeat(66 - tableHandle.length)).concat(tableHandle.slice(2))
    }
    try {
        const ledgerInfo = await aptos.getLedgerInfo()
        const lastVersion = ledgerInfo.ledger_version
        const response = await aptos.getTableItemsData({
            options: {
                where: {
                    table_handle: { _eq: tableHandle },
                    decoded_key: { _contains: { owner: ownerAddress } },

                },
                orderBy: [{ transaction_version: 'desc' }],
            },
        });

        console.log("Fetched positions:", response);
        return response;
    } catch (error) {
        console.error("Error fetching positions:", error);
        throw error;
    }
}

const fetchPositions = async (handle: string) => {

    const result = await getAllUserPositions(singer?.accountAddress.toString(), handle)
    return result
}

const clear_open_position_order = async (orderId) => {

    // const vault = VaultList[0]
    // const symbol = PoolList[0]

    const transaction = await aptos.transaction.build.simple({
        sender: singer.accountAddress,
        data: {
            function: `${moduleAddress}::market::clear_open_position_order`,
            typeArguments: [
                vault.tokenAddress,
                symbol.tokenAddress,
                getSideAddress(side),
                APTOS_COIN,
            ],
            functionArguments: [orderId],
        }
    })

    const committedTx = await aptos.signAndSubmitTransaction({
        signer: singer,
        transaction: transaction,
    })

    const res = await aptos.waitForTransaction({
        transactionHash: committedTx.hash
    })

    // console.log(
    //     `🚀 ~ Transaction submitted Add: ${vault.name}`, res
    // )
}

const decrease_position = async (vasBytes) => {

    const { longPositionResult } = await getPositionTableHandle(vault, symbol)

    const longPositionHandle = longPositionResult?.result?.positions?.handle
    const longPosition: any = await fetchPositions(longPositionHandle)

    console.log('longPosition:', JSON.stringify(longPosition, null, 4))
    console.log('longPosition:', JSON.stringify(longPosition[0].config, null, 4))

    const sideLongPositionData = longPosition.map((item) => ({
        ...item,
        side: LONG,
    }))

    const combinedData: any[] = [
        ...sideLongPositionData,
    ]
    const orderMap: { [key: string]: any } = {}
    combinedData.forEach((order) => {
        if (!orderMap[order?.decoded_key?.id.toString().concat(order?.side)]) {
            orderMap[order?.decoded_key?.id.toString().concat(order?.side)] = order
        }
    })
    const updatedCombinedData = Object.values(orderMap)

    const filterList = updatedCombinedData.filter(
        (item) => !item?.decoded_value?.closed
    )

    const sortedData: any[] = filterList.sort((a, b) => {
        const verA = a.transaction_version
        const verB = b.transaction_version
        return verB - verA
    })
    console.log('sortedData:', sortedData.length)

    for (let i = 0; i < sortedData.length; i++) {
        const positionId = sortedData[0].decoded_key.id
        const position_amount = sortedData[0].decoded_value.position_amount

        const transaction = await aptos.transaction.build.simple({
            sender: singer.accountAddress,
            data: {
                function: `${moduleAddress}::market::decrease_position`,
                typeArguments: [
                    vault.tokenAddress,
                    symbol.tokenAddress,
                    getSideAddress(side),
                    APTOS_COIN,
                ],
                functionArguments: [
                    1,                                                    // trade_level
                    10,                                                   // fee_amount
                    true,                                                 // take_profit
                    position_amount,                                      // decrease_amount
                    '899944550999999872',                                 // collateral_price_threshold
                    '56700720324579996991488',                            // limited_index_price
                    positionId,
                    vasBytes,                                                            // limited_index_price
                ],
            }
        })

        const committedTx = await aptos.signAndSubmitTransaction({
            signer: singer,
            transaction: transaction,
        })

        const res = await aptos.waitForTransaction({
            transactionHash: committedTx.hash
        })

        console.log(
            `🚀 ~ Transaction submitted Add: ${vault.name}`, res
        )
    }
}

(async () => {

    console.log('priceIds[0].address:', priceIds[0].address)

    const vasBytes = await fetchVaasBytes()

    // for (let i = 0; i < 10; i++) {
    //     await open_position(vasBytes)
    // }

    await decrease_position(vasBytes)

    // for(let orderId = 70; orderId< 100; orderId++) {
    //     try{
    //         await clear_open_position_order(orderId)
    //     } catch(e) {

    //     }
    // }

})()