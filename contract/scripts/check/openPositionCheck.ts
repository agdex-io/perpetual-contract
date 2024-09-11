import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {FeeInfo} from '../batch/helper'
import BigNumber from "bignumber.js";

export const MODULE_ADDRESS = "0x565904b9a3195938d5d94b892cfa384a4fa5489b7ea5315169226cfec158b44d"
const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)

const moduleAddress = MODULE_ADDRESS

function sdecimalMinus(a, b) {
    if (a['is_positive']) {
        if (b['is_positive']) {
            return BigNumber(a['value']['value']).minus(BigNumber(b['value']['value']))
        } else {
            return BigNumber(a['value']['value']).plus(BigNumber(b['value']['value']))
        }
    } else {
        if (b['is_positive']) {
            return BigNumber(a['value']['value']).plus(BigNumber(b['value']['value'])).multipliedBy(BigNumber(-1))
        } else {
            return BigNumber(b['value']['value']).minus(BigNumber(b['value']['value']))

        }
    }
}

function sdecimalToBigNumber(a) {
    if (a['is_positive']) {
        return BigNumber(a['value']['value'])
    } else {
        return BigNumber(a['value']['value']).multipliedBy(-1)

    }
}

export async function check(hash: HexInput) {
    
    // const response = await aptos.getTransactionByHash({transactionHash: hash});
    // const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    // const poolOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolOpenPosition")>=0);
    // const positionOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("position::PositioOpenPosition")>=0);

    // open fee rate
    // open fee value
    // treasury reserve amount
    // rebate fee value
    // 

    // decrease fee value

    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    const poolDecreasePositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolDecreasePosition")>=0);

    const positionDecreasePositionEvent = response['events'].filter((e) => e['type'].indexOf("positions::PositionDecreasePosition")>=0);
    const positionSnapshot = response['events'].filter((e) => e['type'].indexOf("positions::PositionSnapshot")>=0);
    const decreaseAmount = response['payload']['arguments'][3];
    const positionAmountPre = positionSnapshot[0]['data']['position_amount']; 
    const positionReservedAmount = positionSnapshot[0]['data']['reserved_amount'];
    const positionCollateralAmount = positionSnapshot[0]['data']['reserved_amount'];
    const positionSizePre = positionSnapshot[0]['data']['position_size']['value']; 
    const collateralPrice = poolDecreasePositionEvent[0]['data']['collateral_price'];
    const indexPrice = poolDecreasePositionEvent[0]['data']['index_price'];
    const fundingFeeRateCur = rateChangedEvent[0]['data']['acc_funding_rate'];
    const reservingFeeRateCur = rateChangedEvent[0]['data']['acc_reserving_rate'];
    const fundingFeeRatePre = positionSnapshot[0]['data']['last_funding_rate']
    const reservingFeeRatePre = positionSnapshot[0]['data']['last_reserving_rate']
    const fundingFeePre = positionSnapshot[0]['data']['funding_fee_value'];
    const reservingFeePre = positionSnapshot[0]['data']['reserving_fee_amount']['value'];
    const settledAmountOnchain = positionDecreasePositionEvent[0]['data']['settled_amount'];
    const openPositionFeeValueOnchain = positionDecreasePositionEvent[0]['data']['decrease_fee_value']['value'];
    const treasuryReserveAmountOnchain = poolDecreasePositionEvent[0]['data']['treasury_reserve_amount'];
    const rebateFeeAmountOnchain = poolDecreasePositionEvent[0]['data']['rebate_amount'];

    // openPositionSize = decreaseAmount / positionAmount * positionSize
    const openPositionSize = BigNumber(Number(decreaseAmount)).multipliedBy(BigNumber(Number(positionSizePre))).div(BigNumber(Number(positionAmountPre)));
    // const openPositionFeeValue = openPositionSize * decreaseFeeRate
    let openPositionFeeValue = openPositionSize.multipliedBy(FeeInfo['openPositionFeeInfo']).div(BigNumber(Math.pow(10, 18)));
    if (openPositionFeeValue.toString() != BigNumber(openPositionFeeValueOnchain).toString()) {
        const delta = openPositionFeeValue.minus(BigNumber(openPositionFeeValueOnchain));
        throw new Error("decrease fee value error: " + delta.toString());
    }

    // treasury reserve amount
    // openPositionFeeValue * treasuryReserveRate / collateralPrice
    const treasuryReserveValue = openPositionFeeValue.multipliedBy(FeeInfo['treasuryReserveFee']).div(BigNumber(Math.pow(10, 18)));
    const treasuryReserveAmount = treasuryReserveValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    
    if (treasuryReserveAmount.integerValue().toString() != BigNumber(treasuryReserveAmountOnchain).toString()) {
        const delta = treasuryReserveAmount.integerValue().minus(BigNumber(treasuryReserveAmountOnchain));
        console.log("delta:", delta.toString())
        throw new Error("treasury reserve amount error: " + delta.toString());
    }

    // rebate fee amount
    // openPositionFeeValue * rebateRate / collateralPrice
    const rebateFeeValue = openPositionFeeValue.multipliedBy(BigNumber(FeeInfo['rebateFee'])).dividedBy(Math.pow(10, 18));
    const rebateFeeAmount = rebateFeeValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    if(rebateFeeAmount.integerValue().toString() != BigNumber(rebateFeeAmountOnchain).toString()) {
        const delta = rebateFeeAmount.integerValue().minus(BigNumber(rebateFeeAmountOnchain));
        throw new Error("rebate amount error: " + delta.toString());
    }
    
}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("")
})()