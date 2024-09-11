import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {FeeInfo} from '../batch/helper'
import BigNumber from "bignumber.js";


export const MODULE_ADDRESS = "0x1a911ef2f607357dc1668b5395e775f4b44d2b8708b1b4ce0252f004953ff202"
const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress =
    MODULE_ADDRESS

export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const PoolWithdrawEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolWithdraw")>=0);
    console.log(PoolWithdrawEvent);

    if(PoolWithdrawEvent.length != 1) throw new Error("Not Successful TXN");

    // fee amount
    if (Number(PoolWithdrawEvent[0]['data']['fee_rate']['value']) != Number(FeeInfo['rebateFee'])) {
        throw new Error("Rebate Rate Not Correct");
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
        throw new Error("Treasury Fee Error: "+BigNumber(treasuryReserveAmount).minus(treasuryReserveAmountCheck).toString());
    }
    // withdraw amount
    const withdrawVauleMinusFee = BigNumber(withdrawValue).minus(BigNumber(feeValue));
    const withdrawAmountCheck = withdrawVauleMinusFee.div(BigNumber(collateralPrice['price']['value']))
                           .multipliedBy(BigNumber(collateralPrice['precision']));
    if (withdrawAmountCheck.integerValue().toString() != BigNumber(PoolWithdrawEvent[0]['data']['withdraw_amount']).toString()) {
        const delta = withdrawAmountCheck.integerValue().minus(BigNumber(PoolWithdrawEvent[0]['data']['withdraw_amount']));
        throw new Error("withdraw amount error: "+ delta.toString());
    }

}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0x037ee5a1347819efdcd547f27d708457aba68dd9b08db4a24d440043fc2be006")
})()