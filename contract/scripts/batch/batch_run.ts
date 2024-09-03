import {
    Account,
    Aptos,
    APTOS_COIN,
    AptosConfig,
    Ed25519PrivateKey,
    Network,
} from '@aptos-labs/ts-sdk'
import { getSideAddress, PoolList, VaultList } from './helper';

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
const BTC_SYMBOL_ADDRESS = `${coinAddress}::btc::BTC`
const ETH_SYMBOL_ADDRESS = `${coinAddress}::ETH::ETH`
const BNB_SYMBOL_ADDRESS = `${coinAddress}::BNB::BNB`
const SOL_SYMBOL_ADDRESS = `${coinAddress}::SOL::SOL`
const AVAX_SYMBOL_ADDRESS = `${coinAddress}::AVAX::AVAX`
const APTOS_SYMBOL_ADDRESS = APTOS_COIN
const DOGE_SYMBOL_ADDRESS = `${coinAddress}::DOGE::DOGE`
const PEPE_SYMBOL_ADDRESS = `${coinAddress}::PEPE::PEPE`


const open_position = async() => {

    const LONG= 'LONG'
    const SHORT = 'SHORT'
    const side = LONG;

    const vault = VaultList[0]
    const symbol = PoolList[0]
    
    const openAmount = 10;
    const collateral = 1
    const leverageNumber = 20;
    const vaultPrice = 1;
    const slippage = 1;
    const inputPrice = 1;


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
                formatAptosDecimal(Number(openAmount), symbol.decimal),                     // open_amount
                leverageNumber > 20 ? formatAptosDecimal(Number(collateral) * 20, vault.decimal)
                : formatAptosDecimal(Number(collateral) * leverageNumber, vault.decimal),   // reserve_amount
                formatAptosDecimal(Number(collateral), vault.decimal),                      // collateral
                10,                                                                         // fee_amount
                formatAptosDecimal(Number(vaultPrice * (1 - slippage)), 18),                // collateral_price_threshold
                formatAptosDecimal(Number(inputPrice), 18),                                 // limited_index_price
                'vasBytes',
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

    console.log(
        `🚀 ~ Transaction submitted Add new Vault : ${vault.name}`, res
    )
} 


(async () => {
    
    await open_position()

    // await close_position()
})()