#!/bin/zsh

# faucet usdc
usdc=`aptos move run --function-id 0x69c513e5bb8fbbe8f82dab674ad477f760b7dd9920c838a7463682bfe2204a70::usdc::mint --assume-yes`
echo "$usdc"

# faucet usdt
usdt=`aptos move run --function-id 0x69c513e5bb8fbbe8f82dab674ad477f760b7dd9920c838a7463682bfe2204a70::usdt::mint  --assume-yes`
echo "$usdt"

# faucet ETH
eth=`aptos move run --function-id 0x69c513e5bb8fbbe8f82dab674ad477f760b7dd9920c838a7463682bfe2204a70::ETH::mint --assume-yes`
echo "$eth"

# faucet BTC
btc=`aptos move run --function-id 0x69c513e5bb8fbbe8f82dab674ad477f760b7dd9920c838a7463682bfe2204a70::btc::mint --assume-yes`
echo "$btc"
