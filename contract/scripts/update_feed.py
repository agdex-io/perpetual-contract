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

contract_address = "0x9357e76fe965c9956a76181ee49f66d51b7f9c3800182a944ed96be86301e49f"


class MarketClient(RestClient):


    async def update_feed(self, sender: Account, vaas) -> str:
        
        res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e")
        vas_hex = res.json()["binary"]["data"][0]
        vas_bytes_1 = list(bytes.fromhex(vas_hex))

        res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0x41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722")
        vas_hex = res.json()["binary"]["data"][0]
        vas_bytes_2 = list(bytes.fromhex(vas_hex))

        res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0x1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588")
        vas_hex = res.json()["binary"]["data"][0]
        vas_bytes_3 = list(bytes.fromhex(vas_hex))

        res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b")
        vas_hex = res.json()["binary"]["data"][0]
        vas_bytes_4 = list(bytes.fromhex(vas_hex))

        res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0xca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6")
        vas_hex = res.json()["binary"]["data"][0]
        vas_bytes_5 = list(bytes.fromhex(vas_hex))


        payload = EntryFunction.natural(
            contract_address+"::pyth",
            "update_price_feeds_with_funder",
            [],
            [
                TransactionArgument([vas_bytes_1, vas_bytes_2, vas_bytes_3, vas_bytes_4, vas_bytes_5], Serializer.sequence_serializer(Serializer.sequence_serializer(Serializer.u8)))
            ]
        )
        signed_transaction = await self.create_bcs_signed_transaction(
            sender, TransactionPayload(payload)
        )
        return await self.submit_bcs_transaction(signed_transaction)

#
async def main():
    sender = Account.load_key("0x1eb195d09146082ad2271dabcc416ec057527a0c4415098be67cf9bf6849143d")
    NODE_URL = "https://aptos.testnet.suzuka.movementlabs.xyz/v1/"

    rest_client = MarketClient(NODE_URL)
    txn_hash = await rest_client.update_feed(sender, [])
    print(txn_hash)
#
#
if __name__ == "__main__":

    asyncio.run(main())
