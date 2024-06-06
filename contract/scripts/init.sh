#!/bin/zsh

# add admin to acl
add_admin=`aptos move run --function-id 0x6e89a3aaeded4fdfe52a1c8d92a7ab2af500a50bb6eecb16ce3c0a70fee12669::admin::add_acl --args 'address:["0x6e89a3aaeded4fdfe52a1c8d92a7ab2af500a50bb6eecb16ce3c0a70fee12669"]'`
echo "$add_admin"

# add new vault

# add new symbol

# add collateral to symbol
