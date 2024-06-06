#!/bin/zsh

# faucet account
faucet=`aptos account fund-with-faucet`
echo "$faucet"

deploy=`aptos move publish --package-dir ../ --assume-yes --included-artifacts none`
echo "$deploy"
# publish
