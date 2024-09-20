import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {FeeInfo, errorFromatter} from '../batch/helper'
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
    const positionLiquidation = response['events'].filter((e) => e['type'].indexOf("positions::PositionLiquidation")>=0);
    const poolLiquidation = response['events'].filter((e) => e['type'].indexOf("pool::PoolLiquidation")>=0);
    const poolRateChanged = response['events'].filter((e) => e['type'].indexOf("pool::RateChanged")>=0);
    const positionSnapshot = response['events'].filter((e) => e['type'].indexOf("positions::PositionSnapshot")>=0);

    let errorList = [] as any[];

    if(poolRateChanged.length != 1) errorList.push("Not Successful TXN");
    if(poolLiquidation.length != 1) errorList.push("Not Successful TXN");
    if(positionLiquidation.length != 1) errorList.push("Not Successful TXN");
    if(positionSnapshot.length != 1) errorList.push("Not Successful TXN");

    const long = response['payload']['type_arguments'][2].indexOf("LONG") >= 0 ? true : false;
    // const decreaseAmount = response['payload']['arguments'][3];
    const positionAmount = positionSnapshot[0]['data']['position_amount']; 
    const positionReservedAmount = positionSnapshot[0]['data']['reserved_amount'];
    const positionCollateralAmount = positionSnapshot[0]['data']['collateral_amount'];
    const liquidateThreshold = positionSnapshot[0]['data']['config']['liquidation_threshold']['value'];
    const liquidateBonusRate = positionSnapshot[0]['data']['config']['liquidation_bonus']['value'];
    const positionSizePre = positionSnapshot[0]['data']['position_size']['value']; 
    const collateralPrice = poolLiquidation[0]['data']['collateral_price'];
    const indexPrice = poolLiquidation[0]['data']['index_price'];
    const fundingFeeRateCur = poolRateChanged[0]['data']['acc_funding_rate'];
    const reservingFeeRateCur = poolRateChanged[0]['data']['acc_reserving_rate'];
    const fundingFeeRatePre = positionSnapshot[0]['data']['last_funding_rate']
    const reservingFeeRatePre = positionSnapshot[0]['data']['last_reserving_rate']
    const fundingFeePre = positionSnapshot[0]['data']['funding_fee_value'];
    const reservingFeePre = positionSnapshot[0]['data']['reserving_fee_amount']['value'];
    const bonusAmountOnchain = positionLiquidation[0]['data']['bonus_amount'];
    const toVaultAmountOnchain = positionLiquidation[0]['data']['to_valut'];

    // // delta size and check liquidation threshold
    // delta_size  = latest_size - position_size_pre(long or short) - (funding_fee_value + reserving_fee_value)
    // assert(collateral_value * liquidate_threshold > delta_size)
    const latest_size = BigNumber(positionAmount).multipliedBy(BigNumber(indexPrice['price']['value'])).dividedBy(BigNumber(indexPrice['precision']));
    const fundingFeeValue = 
        sdecimalToBigNumber(fundingFeePre).plus
        (sdecimalMinus(fundingFeeRateCur, fundingFeeRatePre).multipliedBy(BigNumber(positionSizePre)).dividedBy(BigNumber(Math.pow(10, 18))));
    const reservingFeeAmount = BigNumber(reservingFeePre).plus((BigNumber(reservingFeeRateCur['value'])
                                .minus(reservingFeeRatePre['value'])).multipliedBy(BigNumber(positionReservedAmount)));
    const reservingFeeValue = reservingFeeAmount.multipliedBy(BigNumber(collateralPrice['price']['value'])).dividedBy(BigNumber(collateralPrice['precision'])).dividedBy(BigNumber(Math.pow(10, 18)));
    const collateralValue = BigNumber(positionCollateralAmount).multipliedBy(BigNumber(collateralPrice['price']['value'])).dividedBy(BigNumber(collateralPrice['precision']));
    let deltaSize = latest_size.minus(BigNumber(positionSizePre)).minus(reservingFeeValue.plus(fundingFeeValue));
    if (!long) deltaSize = deltaSize.multipliedBy(-1); 
    if (deltaSize.isPositive()) {
            errorList.push('Liquidation Check Error;');
    } else {
        const deltaSizeThreshold = collateralValue.multipliedBy(BigNumber(liquidateThreshold)).dividedBy(Math.pow(10, 18));
        if (deltaSizeThreshold.abs().gt(deltaSize.abs())) {
            errorList.push('Liquidation Check Error;');
        }
    }
    // to liquidator amount(bonus amount)
    const bounsAmount = BigNumber(positionCollateralAmount).multipliedBy(BigNumber(liquidateBonusRate)).dividedBy(Math.pow(10, 18));
    if(bounsAmount.integerValue().toString() != BigNumber(bonusAmountOnchain).toString()) {
        let delta = bounsAmount.integerValue().minus(BigNumber(bonusAmountOnchain));
        errorList.push("bouns amount error: " + delta.toString());
    }

    // to vault amount
    // collateral_amount - bonus_amount + reserved_amount
    const toVaultAmount = BigNumber(positionCollateralAmount).minus(bounsAmount).plus(BigNumber(positionReservedAmount));
    if(toVaultAmount.integerValue().toString() != BigNumber(toVaultAmountOnchain).toString()) {
        let delta = toVaultAmount.integerValue().minus(BigNumber(toVaultAmountOnchain));
        errorList.push('to vault amount error: ' + delta.toString());
    }
    
    if(errorList.length > 0) {
        return Error(errorFromatter(errorList));
    }

}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0x657443b9e31d73c3861ffcb708f929507d7637242a1906a693b89fab2822afc2")
})()