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
    const withdrawValue = Number(marketValue) * (Number(burnAmount) * Math.pow(10, 18) / (Number(lpSupplyAmount)));
    const feeValue = (Number(withdrawValue) * Number(FeeInfo['rebateFee'])) / Math.pow(10, 18);
    const feeValueCheck = Number(PoolWithdrawEvent[0]['data']['fee_value']['value']);
    if (feeValue != feeValueCheck) {
        throw new Error("Rebate Fee Error: "+BigNumber(feeValue).minus(BigNumber(feeValueCheck)).toString());
    }
    // treasury reserve amount
    const treasuryReserveAmount = Math.floor(feeValue * Number(FeeInfo['treasuryReserveFee']) / Math.pow(10, 18) 
                                    * Number(collateralPrice['precision']) / Number(collateralPrice['price']['value']));
    const treasuryReserveAmountCheck = Number(PoolWithdrawEvent[0]['data']['treasury_reserve_amount']);
    if (treasuryReserveAmount != treasuryReserveAmountCheck) {
        console.log(treasuryReserveAmount);
        console.log(treasuryReserveAmountCheck);
        throw new Error("Treasury Fee Error: "+BigNumber(treasuryReserveAmount).minus(treasuryReserveAmountCheck).toString());
    }
    // withdraw amount

}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0xbc6e5504889a10fbff41cfa4106a1d81bb77b70f8a9fae905cf78d8976b6848d")
})()