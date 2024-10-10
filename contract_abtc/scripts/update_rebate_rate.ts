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
 

const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress = MODULE_ADDRESS

const PRIVATE_KEY = '0x5adbf0299c7ddd87a75455c03d1b56880eb89e0f1d99cc3f2e0d748aca9c18d4'

const singer = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey(PRIVATE_KEY),
})

async function updateRebateRate() {

    const transaction = await aptos.transaction.build.simple({
        sender: singer.accountAddress,
        data: {
            function: `${moduleAddress}::market::update_rebate_rate`,
            typeArguments: [],
            functionArguments: ['20'], // rebate_rate percent
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
        `🚀 ~ Transaction submitted :`, response
    )

    // const response = await aptos.transaction.simulate.simple({
    //     signerPublicKey: singer.publicKey,
    //     transaction
    // })
    // console.log(
    //     // get mint amount as price
    //     response[0]['events'][4]
    // )
}

async function main() {
    await updateRebateRate()
}

(async () => {
    await main()
})()