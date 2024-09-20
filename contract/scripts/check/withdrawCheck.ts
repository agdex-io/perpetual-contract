import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {errorFromatter, FeeInfo} from '../batch/helper'
import BigNumber from "bignumber.js";


export const MODULE_ADDRESS = "0x1a911ef2f607357dc1668b5395e775f4b44d2b8708b1b4ce0252f004953ff202"
const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress =
    MODULE_ADDRESS

export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const PoolWithdrawEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolWithdraw")>=0);
    let errorList = [] as any[];

    if(PoolWithdrawEvent.length != 1) errorList.push("Not Successful TXN");

    // fee amount
    if (Number(PoolWithdrawEvent[0]['data']['fee_rate']['value']) != Number(FeeInfo['rebateFee'])) {
        console.log(PoolWithdrawEvent[0]['data']['fee_rate']['value']);
        console.log(FeeInfo['rebateFee']);
        errorList.push("Rebate Rate Not Correct");
    }
    const burnAmount = PoolWithdrawEvent[0]['data']['burn_amount'];
    const collateralPrice = PoolWithdrawEvent[0]['data']['collateral_price'];
    const marketValue = PoolWithdrawEvent[0]['data']['market_value']['value'];
    const lpSupplyAmount = PoolWithdrawEvent[0]['data']['lp_supply_amount']['value'];
    const withdrawValue = BigNumber(marketValue).multipliedBy((BigNumber(burnAmount)
                          .multipliedBy(BigNumber(Math.pow(10, 18)).div(BigNumber(lpSupplyAmount)))));
    const feeValue = withdrawValue.multipliedBy(BigNumber(FeeInfo['rebateFee'])).div(BigNumber(Math.pow(10, 18)));
    const feeValueCheck = BigNumber(PoolWithdrawEvent[0]['data']['fee_value']['value']);
    // contract may have truncation error (to_rate)
    // if (feeValue != feeValueCheck) {
    //     console.log(feeValue.valueOf());
    //     console.log(PoolWithdrawEvent[0]['data']['fee_value']['value']);
    //     console.log(feeValueCheck);
    //     throw new Error("Rebate Fee Error: "+BigNumber(feeValue).minus(BigNumber(feeValueCheck)).toString());
    // }
    // treasury reserve amount
    const treasuryReserveAmount = feeValue.multipliedBy(BigNumber(FeeInfo['treasuryReserveFee'])).div(BigNumber(Math.pow(10, 18))) 
                                    .multipliedBy(BigNumber(collateralPrice['precision'])).div(BigNumber(collateralPrice['price']['value']));
    const treasuryReserveAmountCheck = BigNumber(PoolWithdrawEvent[0]['data']['treasury_reserve_amount']);
    if (Math.floor(treasuryReserveAmount.toNumber()) != treasuryReserveAmountCheck.toNumber()) {
        console.log();
        console.log(treasuryReserveAmountCheck.toNumber());
        errorList.push("Treasury Fee Error: "+BigNumber(treasuryReserveAmount).minus(treasuryReserveAmountCheck).toString());
    }
    // withdraw amount
    const withdrawVauleMinusFee = BigNumber(withdrawValue).minus(BigNumber(feeValue));
    const withdrawAmountCheck = withdrawVauleMinusFee.div(BigNumber(collateralPrice['price']['value']))
                           .multipliedBy(BigNumber(collateralPrice['precision']));
    if (withdrawAmountCheck.integerValue().toString() != BigNumber(PoolWithdrawEvent[0]['data']['withdraw_amount']).toString()) {
        const delta = withdrawAmountCheck.integerValue().minus(BigNumber(PoolWithdrawEvent[0]['data']['withdraw_amount']));
        errorList.push("withdraw amount error: "+ delta.toString());
    }

    if(errorList.length > 0) {
        return Error(errorFromatter(errorList));
    }

}

async function main(hash: HexInput) {
    const res = await check(hash)
    console.log(res);
}

(async () => {
    const res = await main("0xcb84686e16af1cbc408e3df8d60200fb0e8e19eb86144da062f442190768e18e")
})()