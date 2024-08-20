#!/bin/zsh

# add admin to acl
add_admin=`aptos move run --function-id 0xbfc86b9b41633d8ee54f8b94c79f3b9e248c2eee57f01636116cc58b3fe57c37::admin::add_acl --args 'address:["0xbfc86b9b41633d8ee54f8b94c79f3b9e248c2eee57f01636116cc58b3fe57c37"]' --assume-yes`
echo "$add_admin"

# add new vault
#add_new_vault=`aptos move run --function-id 0x6e89a3aaeded4fdfe52a1c8d92a7ab2af500a50bb6eecb16ce3c0a70fee12669::market::add_new_vault --type-args 0x1::aptos_framework::aptos_coin::AptosCoin --args u256:100000000000000000 u64:20 u64:18446744073709551615 u8:44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e u256:800000000000000`

# add new symbol

# add collateral to symbol

#add_admin=`aptos move run --function-id 0xbfc86b9b41633d8ee54f8b94c79f3b9e248c2eee57f01636116cc58b3fe57c37::admin::add_acl --args 'address:["0xe5c9f72f32b4125c08c4a5c25d6123c215be2a4ab22ee202debf973baf06ce7b","0x8d07663376c920257ab9f2bd8ef0cc5ed5f2264109a3d29fc2b6f8aafc5e875d","0xd7b83a04de1c2dd514f7a5b452b2b20649ede6c0f4e0181c82ec1c154c7f185c","0x9e54d3231b270990fde73545f034dfa771696759e4f40ef8d5fc214cf88b4c6f","0x87e95448bc9088569ed1f9b724a1ec679a187a1c80ff49b52c305318956c4bb7","0x98d62a9becb80590cbc72b293f7443993247bca2dd521dc8b9f6cb403770fcc3"]' --assume-yes`
#echo "$add_admin"
