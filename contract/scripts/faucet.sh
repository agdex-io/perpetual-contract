#!/bin/zsh

# faucet usdc
usdc=`aptos move run --function-id 0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5::usdc::mint --assume-yes`
echo "$usdc"

# faucet usdt
usdt=`aptos move run --function-id 0xfa78899981b78f231628501583779f99565b49cbec9bbf84f9a04465ba17ca55::usdt::mint --args "u64:10000000000" --assume-yes`
echo "$usdt"

# faucet ETH
eth=`aptos move run --function-id 0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5::ETH::ETH --assume-yes`
echo "$eth"

# faucet BTC
btc=`aptos move run --function-id 0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5::btc::BTC --assume-yes`
echo "$btc"
