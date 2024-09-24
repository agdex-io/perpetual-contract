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

export async function check(hash: HexInput) {
    
    const response = await aptos.getTransactionByHash({transactionHash: hash});
    const PoolDepositEvent = response['events'].filter((e) => e['type'].indexOf("pool::PoolDeposit")>=0);
    let errorList = [] as any[];
    if(PoolDepositEvent.length != 1) errorList.push("Not Successful TXN");

    const depositAmount = PoolDepositEvent[0]['data']['deposit_amount'];
    const collateralPrice = PoolDepositEvent[0]['data']['collateral_price'];
    const depositValue = Number(depositAmount) * Number(collateralPrice['price']['value']) / Number(collateralPrice['precision']);
    const feeRate = Number(PoolDepositEvent[0]['data']['fee_rate']['value'])
    const feeValue = BigNumber(depositValue).multipliedBy(BigNumber(feeRate)).dividedBy(BigNumber(Math.pow(10, 18)));
    const feeValueCheck = BigNumber(PoolDepositEvent[0]['data']['fee_value']['value'])
    if (feeValue.integerValue().toString() != feeValueCheck.integerValue().toString()) {
        errorList.push("Fee Error: "+feeValue.minus(feeValueCheck).toString());
    }
    // treasury reserve amount
    const treasuryReserveAmount = feeValue.multipliedBy(BigNumber(FeeInfo['treasuryReserveFee']))
                                    .multipliedBy(Number(collateralPrice['precision'])).dividedBy(Number(collateralPrice['price']['value'])).dividedBy(BigNumber(Math.pow(10, 18)));
    const  treasuryReserveAmountCheck= BigNumber(PoolDepositEvent[0]['data']['treasury_reserve_amount'])
    if (treasuryReserveAmount.integerValue().toString() != treasuryReserveAmountCheck.integerValue().toString()) {
        errorList.push("Treasury reserve fee Error: "+BigNumber(treasuryReserveAmount).minus(BigNumber(treasuryReserveAmountCheck)).toString());
    }

    if(errorList.length > 0) {
        return Error(errorFromatter(errorList));
    }

    // mint amount

}

async function main(hash: HexInput) {
    const res = await check(hash)
    console.log(res);
}

(async () => {
    await main("0xadaa52af80c00177722a02129310ece42a4d067e8166bda90b9787d6e50e634a")
})()