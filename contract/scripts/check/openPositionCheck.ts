import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {FeeInfo} from '../batch/helper'


export const MODULE_ADDRESS = "0x565904b9a3195938d5d94b892cfa384a4fa5489b7ea5315169226cfec158b44d"
const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress =
    MODULE_ADDRESS

export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    const poolOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolOpenPosition")>=0);
    const positionOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("position::PositioOpenPosition")>=0);

    // open fee rate
    // open fee value
    // treasury reserve amount
    // rebate fee value
    // 

}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0xa801c39e7c62361c9ae6a32eb5e5f6c88552dc50f47bb96dd4b08b641e7c7691")
})()