#!/bin/zsh

# faucet usdc
usdc=`aptos move run --function-id 0x938dd1008f738a4e85adbdae7a370665604531d19df2851c89311473404cd378::usdc::mint --assume-yes`
echo "$usdc"

# faucet usdt
usdt=`aptos move run --function-id 0x938dd1008f738a4e85adbdae7a370665604531d19df2851c89311473404cd378::usdt::mint  --assume-yes`
echo "$usdt"

# faucet ETH
eth=`aptos move run --function-id 0x938dd1008f738a4e85adbdae7a370665604531d19df2851c89311473404cd378::ETH::mint --assume-yes`
echo "$eth"

# faucet BTC
btc=`aptos move run --function-id 0x938dd1008f738a4e85adbdae7a370665604531d19df2851c89311473404cd378::btc::mint --assume-yes`
echo "$btc"
