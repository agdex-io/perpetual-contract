import {
    Aptos,
    AptosConfig,
    Network,
    HexInput
} from '@aptos-labs/ts-sdk'
import {FeeInfo} from '../batch/helper'


export const MODULE_ADDRESS = "0x1a911ef2f607357dc1668b5395e775f4b44d2b8708b1b4ce0252f004953ff202"
const aptosConfig = new AptosConfig({ network: Network.TESTNET })
const aptos = new Aptos(aptosConfig)
const moduleAddress =
    MODULE_ADDRESS

export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const PoolWithdrawEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolWithdraw")>=0);
    console.log(PoolWithdrawEvent);

    // if(PoolWithdrawEvent.length != 1) throw new Error("Not Successful TXN");

    // // fee amount
    // if (Number(PoolWithdrawEvent[0]['data']['fee_rate']['value']) != Number(FeeInfo['rebateFee'])) {
    //     throw new Error("Rebate Rate Not Correct");
    // }
    // const burnAmount = PoolWithdrawEvent[0]['data']['burn_amount'];
    // const collateralPrice = PoolWithdrawEvent[0]['data']['collateral_price'];
    // const depositValue = Number(burnAmount) * Number(collateralPrice['price']['value']) / Number(collateralPrice['precision']);
    // console.log(depositValue);
    // const feeValue = (depositValue * Number(FeeInfo['rebateFee']) / Math.pow(10, 18));
    // console.log(feeValue);
    // console.log(Number(PoolWithdrawEvent[0]['data']['fee_value']['value']));
    // // console.log(PoolWithdrawEvent[0]['data']['fee_value'])
    // if (feeValue != Number(PoolWithdrawEvent[0]['data']['fee_value']['value'])) {
    //     throw new Error("Rebate Fee Error");
    // }
    // // treasury reserve amount
    // const treasury_reserve_amount = feeValue * Number(FeeInfo['treasuryReserveFee']) / Math.pow(10, 18) 
    //                                 * Number(collateralPrice['precision']) / Number(collateralPrice['price']['value']);
    // if (treasury_reserve_amount != Number(PoolWithdrawEvent[0]['data']['treasury_reserve_amount'])) {
    //     throw new Error("Treasury reserve fee Error")
    // }
    // withdraw amount

}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0x3aca9dd3c343617bf5e1cf5be224d09e437d237d2f69055dba4204acee428103")
})()