// import {
//     Aptos,
//     AptosConfig,
//     Network,
//     HexInput
// } from '@aptos-labs/ts-sdk'
// import {FeeInfo} from '../batch/helper'
// import BigNumber from "bignumber.js";

// export const MODULE_ADDRESS = "0x565904b9a3195938d5d94b892cfa384a4fa5489b7ea5315169226cfec158b44d"
// const aptosConfig = new AptosConfig({ network: Network.TESTNET })
// const aptos = new Aptos(aptosConfig)
// const moduleAddress =
//     MODULE_ADDRESS

// export async function check(hash: HexInput) {
    
//     const response = await aptos.getTransactionByHash({transactionHash: hash});
//     const rateChangedEvent = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
//     const poolOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolOpenPosition")>=0);
//     const positionOpenPositionEvent = response['events'].filter((e) => e['type'].indexOf("position::PositioOpenPosition")>=0);

//     // open fee rate
//     // open fee value
//     // treasury reserve amount
//     // rebate fee value
//     // 

//     // / decrease fee value
//     // decreaseSize = decreaseAmount / positionAmount * positionSize
//     const decreaseSize = BigNumber(Number(decreaseAmount)).multipliedBy(BigNumber(Number(positionSizePre))).div(BigNumber(Number(positionAmountPre)));
//     // decreaseFeeValue = decreaseSize * decreaseFeeRate
//     const decreaseFeeValue = decreaseSize.multipliedBy(FeeInfo['decreaseFeeInfo']).div(BigNumber(Math.pow(10, 18)));
//     if (decreaseFeeValue.toString() != BigNumber(decreaseFeeValueOnchain).toString()) {
//         const delta = decreaseFeeValue.minus(BigNumber(decreaseFeeValueOnchain));
//         throw new Error("decrease fee value error: " + delta.toString());
//     }

//     // treasury reserve amount
//     // decreaseFeeValue * treasuryReserveRate / collateralPrice
//     const treasuryReserveValue = decreaseFeeValue.multipliedBy(FeeInfo['treasuryReserveFee']).div(BigNumber(Math.pow(10, 18)));
//     const treasuryReserveAmount = treasuryReserveValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
    
//     if (treasuryReserveAmount.integerValue().toString() != BigNumber(treasuryReserveAmountOnchain).toString()) {
//         // const delta = treasuryReserveAmount.integerValue().minus(BigNumber(treasuryReserveAmountOnchain));
//         // console.log("delta:", delta.toString())
//         // throw new Error("treasury reserve amount error: " + delta.toString());
//     }

//     // rebate fee amount
//     // decreaseFeeValue * rebateRate / collateralPrice
//     const rebateFeeValue = decreaseFeeValue.multipliedBy(BigNumber(FeeInfo['rebateFee'])).dividedBy(Math.pow(10, 18));
//     const rebateFeeAmount = rebateFeeValue.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
//     if(rebateFeeAmount.integerValue().toString() != BigNumber(rebateFeeAmountOnchain).toString()) {
//         // const delta = rebateFeeAmount.integerValue().minus(BigNumber(rebateFeeAmountOnchain));
//         // throw new Error("rebate amount error: " + delta.toString());
//     }
    
//     // settled amount
//     // settledSize = deltaSize * decreaseAmount / positionSize - (fundingFeeValue + decreaseFeeValue + reservingFeeValue)
//     // fundingFeeValue = last_funding_fee + delta_funding_rate * position_size
//     // reservingFeeValue = last_reserving_fee + delta_reserving_rate * position_reserved_amount * collateral_price
//     // settleAmount = settledSize / collateralPrice
//     const currentSize = BigNumber(positionAmountPre).multipliedBy(BigNumber(indexPrice['price']['value'])).dividedBy(BigNumber(indexPrice['precision']));
//     const deltaSize = BigNumber(positionSizePre).minus(currentSize);
//     const settledDeltaSize = deltaSize.multipliedBy(decreaseAmount).dividedBy(BigNumber(positionAmountPre));
//     const fundingFeeValue = sdecimalToBigNumber(fundingFeePre).plus
//         (sdecimalMinus(fundingFeeRateCur, fundingFeeRatePre).multipliedBy(BigNumber(positionSizePre)).dividedBy(BigNumber(Math.pow(10, 18))));
//     const reservingFeeAmount = BigNumber(reservingFeePre).plus((BigNumber(reservingFeeRateCur['value'])
//                                 .minus(reservingFeeRatePre['value'])).multipliedBy(BigNumber(positionReservedAmount)));
//     const reservingFeeValue = reservingFeeAmount.multipliedBy(BigNumber(collateralPrice['price']['value'])).dividedBy(BigNumber(collateralPrice['precision'])).dividedBy(BigNumber(Math.pow(10, 18)));
                                
//     const settledSize = settledDeltaSize.minus(fundingFeeValue.plus(decreaseFeeValue).plus(reservingFeeValue));
//     const settledAmount = settledSize.dividedBy(BigNumber(collateralPrice['price']['value'])).multipliedBy(BigNumber(collateralPrice['precision']));
//     const settledAmountCheck = settledAmount.integerValue().abs();
//     if(settledAmountCheck.toString() != BigNumber(settledAmountOnchain).toString()) {
//         const delta = settledAmountCheck.minus(BigNumber(settledAmountOnchain)).toString();
//         // throw new Error('Settled Amount Error: ' + delta);
//     }

// }

// async function main(hash: HexInput) {
//     await check(hash)
// }

// (async () => {
//     await main("0xa801c39e7c62361c9ae6a32eb5e5f6c88552dc50f47bb96dd4b08b641e7c7691")
// })()