import asyncio
import os
import sys
import requests

from aptos_sdk.account import Account
from aptos_sdk.account_address import AccountAddress
from aptos_sdk.aptos_cli_wrapper import AptosCLIWrapper

from aptos_sdk.async_client import FaucetClient, RestClient
from aptos_sdk.bcs import Serializer
from aptos_sdk.package_publisher import PackagePublisher
from aptos_sdk.transactions import (
    EntryFunction,
    TransactionArgument,
    TransactionPayload,
)

contract_address = "0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387"


class MarketClient(RestClient):


    async def update_feed(self, sender: Account, vaas) -> str:
        price_ids = [
            "44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e",
            "41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722",
            "1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588",
            "f9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b",
            "ca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6",
            "ecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a",
            "fe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd",
            "d7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9",
            "ed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0",
            "31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae",
        ]

        vaas = []

        for id in price_ids:

            res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0x"+id)
            vas_hex = res.json()["binary"]["data"][0]
            vas_bytes_1 = list(bytes.fromhex(vas_hex))
            vaas.append(vas_bytes_1)


        payload = EntryFunction.natural(
            contract_address+"::pyth",
            "update_price_feeds_with_funder",
            [],
            [
                TransactionArgument(vaas, Serializer.sequence_serializer(Serializer.sequence_serializer(Serializer.u8)))
            ]
        )
        signed_transaction = await self.create_bcs_signed_transaction(
            sender, TransactionPayload(payload)
        )
        return await self.submit_bcs_transaction(signed_transaction)

#
async def main():
    sender = Account.load_key("0x5adbf0299c7ddd87a75455c03d1b56880eb89e0f1d99cc3f2e0d748aca9c18d4")
    NODE_URL = "https://fullnode.testnet.aptoslabs.com/v1"

    rest_client = MarketClient(NODE_URL)
    txn_hash = await rest_client.update_feed(sender, [])
    print(txn_hash)
#
#
if __name__ == "__main__":

    while(True):
        asyncio.run(main())
