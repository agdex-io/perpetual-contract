#!/bin/zsh

# add admin to acl

#add_admin=`aptos move run --function-id 0xdc7386d3e8a210b8edf5fabcd4c7baddaa29517269197e45146b02dea4cdbc2f::admin::add_acl --args 'address:["0xdc7386d3e8a210b8edf5fabcd4c7baddaa29517269197e45146b02dea4cdbc2f"]' --assume-yes`
#echo "$add_admin"
#
# add new vault
#add_new_vault=`aptos move run --function-id 0x8916cdadc2d1097eb278ad02193089a604909c65849d6bfaeb7fce87acba1677::market::add_new_vault --type-args 0x1::aptos_framework::aptos_coin::AptosCoin --args u256:100000000000000000 u64:20 u64:18446744073709551615 u8:44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e u256:800000000000000`

# add new symbol

# add collateral to symbol

#add_admin=`aptos move run --function-id 0x9acda19cc96ff9a981800f18954485e9436e9b086c095ba6ba9fa8bb0b6f2971::admin::add_acl --args 'address:["0x938dd1008f738a4e85adbdae7a370665604531d19df2851c89311473404cd378","0xd7b83a04de1c2dd514f7a5b452b2b20649ede6c0f4e0181c82ec1c154c7f185c","0x9e54d3231b270990fde73545f034dfa771696759e4f40ef8d5fc214cf88b4c6f","0x87e95448bc9088569ed1f9b724a1ec679a187a1c80ff49b52c305318956c4bb7","0x98d62a9becb80590cbc72b293f7443993247bca2dd521dc8b9f6cb403770fcc3"]' --assume-yes`
#echo "$add_admin"

# update treasury reserve config

#add_admin=`aptos move run --function-id 0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d::market::update_treasury_reserve_config --args address:0x8a03c8a51f5e98eea3e314e9e56b6dc153059a578810f57713b1e8a6779efdb3 u128:250000000000000000 --assume-yes`
#echo "$add_admin"

# update rebase model

#add_admin=`aptos move run --function-id 0x9acda19cc96ff9a981800f18954485e9436e9b086c095ba6ba9fa8bb0b6f2971::market::update_rebase_model --args u128:1000000000000000 u256:0 --assume-yes`
#echo "$add_admin"

# update rebase model

# add_admin=`aptos move run --function-id 0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d::market::update_vault_weight --type-args 0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5::usdc::USDC --args u256:100000000000000000 --assume-yes`
# echo "$add_admin"

# register

 add_admin=`aptos move run --function-id 0xdc7386d3e8a210b8edf5fabcd4c7baddaa29517269197e45146b02dea4cdbc2f::type_registry::register --type-args 0x69c513e5bb8fbbe8f82dab674ad477f760b7dd9920c838a7463682bfe2204a70::usdt::USDT --args address:0x666d4264b190a8965f78020b406c113821bbb5d7c7a199cb9d780610a4fa9591 --assume-yes`
 echo "$add_admin"
