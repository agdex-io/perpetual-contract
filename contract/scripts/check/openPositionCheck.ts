import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {errorFromatter, FeeInfo} from '../batch/helper'
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
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    const poolOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolOpenPosition")>=0);
    const positionOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("positions::PositionOpenPosition")>=0);
    let errorList = [] as any[];

    if(rateChangedEvent.length != 1) errorList.push("Not Successful TXN");
    if(poolOpenPositionEvent.length != 1) errorList.push("Not Successful TXN");
    if(positionOpenPositionEvent.length != 1) errorList.push("Not Successful TXN");

    const openAmount = response['payload']['arguments'][1];
    const collateralPrice = poolOpenPositionEvent[0]['data']['collateral_price'];
    const indexPrice = poolOpenPositionEvent[0]['data']['index_price'];
    const openPositionFeeAmountOnchain = poolOpenPositionEvent[0]['data']['open_fee_amount'];
    const treasuryReserveAmountOnchain = poolOpenPositionEvent[0]['data']['treasury_reserve_amount'];
    const rebateFeeAmountOnchain = poolOpenPositionEvent[0]['data']['rebate_amount'];

    // openPositionSize = openAmount * indexPrice
    // const openPositionFeeValue = openPositionSize * decreaseFeeRate
    let openPositionSize = BigNumber(Number(openAmount))
            .multipliedBy(BigNumber(indexPrice['price']['value'])).dividedBy(BigNumber(Number(indexPrice['precision'])));
    let openPositionFeeValue = openPositionSize.multipliedBy(BigNumber(FeeInfo['openPositionFeeInfo'])).dividedBy(Math.pow(10, 18));
    let openPositionFeeAmount = openPositionFeeValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(Number(collateralPrice['precision']));
    if (openPositionFeeAmount.integerValue().toString() != BigNumber(openPositionFeeAmountOnchain).integerValue().toString()) {
        const delta = openPositionFeeAmount.integerValue().minus(BigNumber(openPositionFeeAmountOnchain).integerValue());
        errorList.push("open fee amount error: " + delta.toString());
    }

    // treasury reserve amount
    // openPositionFeeValue * treasuryReserveRate / collateralPrice
    const treasuryReserveValue = openPositionFeeValue.multipliedBy(FeeInfo['treasuryReserveFee']).div(BigNumber(Math.pow(10, 18)));
    const treasuryReserveAmount = treasuryReserveValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    
    if (treasuryReserveAmount.integerValue().toString() != BigNumber(treasuryReserveAmountOnchain).toString()) {
        const delta = treasuryReserveAmount.integerValue().minus(BigNumber(treasuryReserveAmountOnchain));
        errorList.push("treasury reserve amount error: " + delta.toString());
    }

    // rebate fee amount
    // openPositionFeeValue * rebateRate / collateralPrice
    const rebateFeeValue = openPositionFeeValue.multipliedBy(BigNumber(FeeInfo['rebateFee'])).dividedBy(Math.pow(10, 18));
    const rebateFeeAmount = rebateFeeValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    if(rebateFeeAmountOnchain != 0 && rebateFeeAmount.integerValue().toString() != BigNumber(rebateFeeAmountOnchain).toString()) {
        const delta = rebateFeeAmount.integerValue().minus(BigNumber(rebateFeeAmountOnchain));
        console.log(openPositionFeeAmount.integerValue());
        console.log(rebateFeeAmount);
        console.log(rebateFeeAmountOnchain);
        errorList.push("rebate amount error: " + delta.toString());
    }

    if (errorList.length > 0) {
        return Error(errorFromatter(errorList));
    }
}

async function main(hash: HexInput) {
    const res = await check(hash)
    console.log(res)
}

(async () => {
    await main("0xa734a88d3e54ad1c04805ad854b1bd814b3afd24ba1a1eb77e97c1226ee60eb0")
})()