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

// 合约缺少事件
export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    const poolDecreasePositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolDecreasePosition")>=0);
    const positionDecreasePositionEvent = response['events'].filter((e) => e['type'].indexOf("position::PositioDecreasePosition")>=0);
    console.log(poolDecreasePositionEvent)

    // decrease fee value
    decreaseSize = decreaseAmount / positionAmount * positionSize
    decreaseFeeValue = decreaseSize * decreaseFeeRate
    // treasury reserve amount
    decreaseFeeValue * treasuryReserveRate
    // rebate fee value
    decreaseFeeValue * rebateRate
    // settled amount
    settledSize = deltaSize * decreaseAmount / positionSize - (fundingFeeValue + decreaseFeeValue + reservingFeeValue)
    settleAmount = settledSize / collateralPrice



}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0xfde94fa5f25518d5952188c4af66f7765c45b2c1c20df0cca0b83c86ba1f77dd")
})()