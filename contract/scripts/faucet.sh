#!/bin/zsh

# faucet usdc
usdc=`aptos move run --function-id 0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0::usdc::mint --args "u64:1000000000" --assume-yes`
echo "$usdc"

# faucet usdt
usdt=`aptos move run --function-id 0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0::usdt::mint --args "u64:1000000000" --assume-yes`
echo "$usdt"
