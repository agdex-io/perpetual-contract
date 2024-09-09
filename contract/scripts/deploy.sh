#!/bin/zsh

# faucet account
#faucet=`aptos account fund-with-faucet`
#echo "$faucet"

deploy=`movement move publish --package-dir ../ --assume-yes --included-artifacts none --skip-fetch-latest-git-deps`
echo "$deploy"
# publish
