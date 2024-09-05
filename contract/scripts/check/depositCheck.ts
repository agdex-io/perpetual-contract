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

export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const PoolDepositEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolDeposit")>=0);
    console.log(PoolDepositEvent);
    if(PoolDepositEvent.length != 1) throw new Error("Not Successful TXN");

    // fee amount
    if (Number(PoolDepositEvent[0]['data']['fee_rate']['value']) != Number(FeeInfo['rebateFee'])) {
        throw new Error("Rebate Rate Not Correct");
    }
    const depositAmount = PoolDepositEvent[0]['data']['deposit_amount'];
    const collateralPrice = PoolDepositEvent[0]['data']['collateral_price'];
    const depositValue = Number(depositAmount) * Number(collateralPrice['price']['value']) / Number(collateralPrice['precision']);
    console.log(depositValue);
    const feeValue = (depositValue * Number(FeeInfo['rebateFee']) / Math.pow(10, 18));
    console.log(feeValue);
    console.log(Number(PoolDepositEvent[0]['data']['fee_value']['value']));
    // console.log(PoolDepositEvent[0]['data']['fee_value'])
    if (feeValue != Number(PoolDepositEvent[0]['data']['fee_value']['value'])) {
        throw new Error("Rebate Fee Error");
    }
    // treasury reserve amount
    const treasury_reserve_amount = feeValue * Number(FeeInfo['treasuryReserveFee']) / Math.pow(10, 18) 
                                    * Number(collateralPrice['precision']) / Number(collateralPrice['price']['value']);
    if (treasury_reserve_amount != Number(PoolDepositEvent[0]['data']['treasury_reserve_amount'])) {
        throw new Error("Treasury reserve fee Error")
    }

    // mint amount

}

async function main(hash: HexInput) {
    await check(hash)
}

(async () => {
    await main("0xadaa52af80c00177722a02129310ece42a4d067e8166bda90b9787d6e50e634a")
})()