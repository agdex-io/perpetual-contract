#!/bin/zsh

# faucet account
faucet=`aptos account fund-with-faucet`
echo "$faucet"

deploy=`aptos move publish --package-dir  ../ --assume-yes --included-artifacts none --override-size-check --skip-fetch-latest-git-deps --move-2`
echo "$deploy"
# publish