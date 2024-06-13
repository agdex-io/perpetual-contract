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
        
        res = requests.get("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e")
        vas_hex = res.json()["binary"]["data"][0]
        vas_bytes = list(bytes.fromhex(vas_hex))

        payload = EntryFunction.natural(
            contract_address+"::pyth",
            "update_price_feeds_with_funder",
            [],
            [
                TransactionArgument([vas_bytes], Serializer.sequence_serializer(Serializer.sequence_serializer(Serializer.u8)))
            ]
        )
        signed_transaction = await self.create_bcs_signed_transaction(
            sender, TransactionPayload(payload)
        )
        return await self.submit_bcs_transaction(signed_transaction)

#
async def main():
    sender = Account.load_key("0xbd7f26f79f52b7248b89a8eac0abefc4b34bd615dc0a04ee7829b5dbad588a71")
    NODE_URL = "https://fullnode.testnet.aptoslabs.com/v1"

    rest_client = MarketClient(NODE_URL)
    txn_hash = await rest_client.update_feed(sender, [])
    print(txn_hash)
#
#
if __name__ == "__main__":

    asyncio.run(main())
