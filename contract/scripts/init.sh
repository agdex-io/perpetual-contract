#!/bin/zsh

# add admin to acl
add_admin=`aptos move run --function-id 0x87e95448bc9088569ed1f9b724a1ec679a187a1c80ff49b52c305318956c4bb7::admin::add_acl --args 'address:["0x87e95448bc9088569ed1f9b724a1ec679a187a1c80ff49b52c305318956c4bb7"]'`
echo "$add_admin"

# add new vault
#add_new_vault=`aptos move run --function-id 0x6e89a3aaeded4fdfe52a1c8d92a7ab2af500a50bb6eecb16ce3c0a70fee12669::market::add_new_vault --type-args 0x1::aptos_framework::aptos_coin::AptosCoin --args u256:100000000000000000 u64:20 u64:18446744073709551615 u8:44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e u256:800000000000000`

# add new symbol

# add collateral to symbol