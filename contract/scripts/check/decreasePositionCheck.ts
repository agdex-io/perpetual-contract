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
const moduleAddress =
    MODULE_ADDRESS

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

function sdecimalPlus(a, b) {
    if (a['is_positive']) {
        if (b['is_positive']) {
            return BigNumber(a['value']['value']).plus(BigNumber(b['value']['value']))
        } else {
            return BigNumber(a['value']['value']).minus(BigNumber(b['value']['value']))
        }
    } else {
        if (b['is_positive']) {
            return BigNumber(b['value']['value']).minus(BigNumber(a['value']['value']))
        } else {
            return BigNumber(b['value']['value']).plus(BigNumber(b['value']['value'])).multipliedBy(BigNumber(-1))
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


// 合约缺少事件
export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    const poolDecreasePositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolDecreasePosition")>=0);
    const positionDecreasePositionEvent = response['events'].filter((e) => e['type'].indexOf("positions::PositionDecreasePosition")>=0);
    const positionSnapshot = response['events'].filter((e) => e['type'].indexOf("positions::PositionSnapshot")>=0);
    let errorList = [] as any[];
    if(rateChangedEvent.length != 1) errorList.push("Not Successful TXN");
    if(poolDecreasePositionEvent.length != 1) errorList.push("Not Successful TXN");
    if(positionDecreasePositionEvent.length != 1) errorList.push("Not Successful TXN");
    if(positionSnapshot.length != 1) errorList.push("Not Successful TXN");
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
    const decreaseFeeValueOnchain = positionDecreasePositionEvent[0]['data']['decrease_fee_value']['value'];
    const treasuryReserveAmountOnchain = poolDecreasePositionEvent[0]['data']['treasury_reserve_amount'];
    const rebateFeeAmountOnchain = poolDecreasePositionEvent[0]['data']['rebate_amount'];

    // decrease fee value
    // decreaseSize = decreaseAmount / positionAmount * positionSize
    const decreaseSize = BigNumber(Number(decreaseAmount)).multipliedBy(BigNumber(Number(positionSizePre))).div(BigNumber(Number(positionAmountPre)));
    // decreaseFeeValue = decreaseSize * decreaseFeeRate
    const decreaseFeeValue = decreaseSize.multipliedBy(FeeInfo['decreaseFeeInfo']).div(BigNumber(Math.pow(10, 18)));
    if (decreaseFeeValue.toString() != BigNumber(decreaseFeeValueOnchain).toString()) {
        const delta = decreaseFeeValue.minus(BigNumber(decreaseFeeValueOnchain));
        errorList.push("decrease fee value error: " + delta.toString());
    }
    // treasury reserve amount
    // decreaseFeeValue * treasuryReserveRate / collateralPrice
    const treasuryReserveValue = decreaseFeeValue.multipliedBy(FeeInfo['treasuryReserveFee']).div(BigNumber(Math.pow(10, 18)));
    const treasuryReserveAmount = treasuryReserveValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    if (treasuryReserveAmount.integerValue().toString() != BigNumber(treasuryReserveAmountOnchain).toString()) {
        const delta = treasuryReserveAmount.integerValue().minus(BigNumber(treasuryReserveAmountOnchain));
        errorList.push("treasury reserve amount error: " + delta.toString());
    }
    // rebate fee amount
    // decreaseFeeValue * rebateRate / collateralPrice
    const rebateFeeValue = decreaseFeeValue.multipliedBy(BigNumber(FeeInfo['rebateFee'])).dividedBy(Math.pow(10, 18));
    const rebateFeeAmount = rebateFeeValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    if(rebateFeeAmount.integerValue().toString() != BigNumber(rebateFeeAmountOnchain).toString()) {
        const delta = rebateFeeAmount.integerValue().minus(BigNumber(rebateFeeAmountOnchain));
        errorList.push("rebate amount error: " + delta.toString());
    }
    // settled amount
    // settledSize = deltaSize * decreaseAmount / positionSize - (fundingFeeValue + decreaseFeeValue + reservingFeeValue)
    // fundingFeeValue = last_funding_fee + delta_funding_rate * position_size
    // reservingFeeValue = last_reserving_fee + delta_reserving_rate * position_reserved_amount * collateral_price
    // settleAmount = settledSize / collateralPrice
    const currentSize = BigNumber(positionAmountPre).multipliedBy(BigNumber(indexPrice['price']['value'])).dividedBy(BigNumber(indexPrice['precision']));
    const deltaSize = BigNumber(positionSizePre).minus(currentSize);
    const settledDeltaSize = deltaSize.multipliedBy(decreaseAmount).dividedBy(BigNumber(positionAmountPre));
    const fundingFeeValue = 
        sdecimalToBigNumber(fundingFeePre).plus
        (sdecimalMinus(fundingFeeRateCur, fundingFeeRatePre).multipliedBy(BigNumber(positionSizePre)).dividedBy(BigNumber(Math.pow(10, 18))));
    const reservingFeeAmount = BigNumber(reservingFeePre).plus((BigNumber(reservingFeeRateCur['value'])
                                .minus(reservingFeeRatePre['value'])).multipliedBy(BigNumber(positionReservedAmount)));
    const reservingFeeValue = reservingFeeAmount.multipliedBy(BigNumber(collateralPrice['price']['value'])).dividedBy(BigNumber(collateralPrice['precision'])).dividedBy(BigNumber(Math.pow(10, 18)));
                                
    const settledSize = settledDeltaSize.minus(fundingFeeValue.plus(decreaseFeeValue).plus(reservingFeeValue));
    const settledAmount = settledSize.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    const settledAmountCheck = settledAmount.integerValue().abs();
    if(settledAmountCheck.toString() != BigNumber(settledAmountOnchain).toString()) {
        const delta = settledAmountCheck.minus(BigNumber(settledAmountOnchain)).toString();
        errorList.push('Settled Amount Error: ' + delta);
    }

    if(errorList.length > 0) {
        return Error(errorFromatter(errorList));
    }
}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0x43891e60c584476a977b297cb218d4420d7ebd990026c7f37e68a1ef3a065b5c")
})()