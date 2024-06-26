import {
    Account,
    Aptos,
    AptosConfig,
    InputGenerateTransactionPayloadData,
    Network,
    NetworkToNetworkName,
    UserTransactionResponse,
    TransactionWorkerEventsEnum,
    Ed25519PrivateKey,
    Serializer,
    U256,
    U64,
    MoveString,
    U8,
    MoveVector,
  } from "@aptos-labs/ts-sdk";

  const APTOS_NETWORK: Network = /*NetworkToNetworkName[process.env.APTOS_NETWORK] ||*/ Network.TESTNET;
  const config = new AptosConfig({ network: APTOS_NETWORK });
  const aptos = new Aptos(config);

  //const aptosConfig = new AptosConfig({ network: NetworkToNetworkName[Network.TESTNET]});
  //const aptos = new Aptos(aptosConfig);

  const contract_address = "0x9e54d3231b270990fde73545f034dfa771696759e4f40ef8d5fc214cf88b4c6f";
  const alice = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey("0x26b0855831c4ab50215da60e87521dbaa465ab90e5299d61e155f5854958a43a")
  });

  
  async function add_new_vault(
    collateral: any,
    weight: any,
    max_interval: any,
    max_price_confidence: any,
    feeder: any,
    param_multiplier: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::add_new_vault`,
        typeArguments: ["0x1::aptos_coin::AptosCoin"],
        functionArguments: [
          weight, 
          max_interval, 
          max_price_confidence, 
          feeder, 
          param_multiplier
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function add_new_referral(
    L: any,
    referrer: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::add_new_referral`,
        typeArguments: [L],
        functionArguments: [
          referrer,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function replace_vault_feeder(
    collateral: any,
    feeder: any,
    max_interval: any,
    max_price_confidence: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::replace_vault_feeder`,
        typeArguments: [collateral],
        functionArguments: [
          feeder, 
          max_interval, 
          max_price_confidence
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }



  async function add_new_symbol(
    index: any,
    direction: any,
    max_interval: any, 
    max_price_confidence: any, 
    feeder: any, 
    param_multiplier: any, 
    param_max: any, 
    max_leverage: any, 
    min_holding_duration: any, 
    max_reserved_multiplier: any, 
    min_collateral_value: any, 
    open_fee_bps: any, 
    decrease_fee_bps: any, 
    liquidation_threshold: any, 
    liquidation_bonus: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::add_new_symbol`,
        typeArguments: [index, contract_address+"::pool::"+direction],
        functionArguments: [
          max_interval, 
          max_price_confidence, 
          feeder, 
          param_multiplier, 
          param_max, 
          max_leverage, 
          min_holding_duration, 
          max_reserved_multiplier, 
          min_collateral_value, 
          open_fee_bps, 
          decrease_fee_bps, 
          liquidation_threshold, 
          liquidation_bonus,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function replace_symbol_feeder(
    index: any,
    direction: any,
    feeder: any,
    max_interval: any,
    max_price_confidence: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::replace_symbol_feeder`,
        typeArguments: [index, contract_address+"::pool::"+direction],
        functionArguments: [
          feeder, 
          max_interval, 
          max_price_confidence
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function add_collateral_to_symbol(
    collateral: any,
    index: any,
    direction: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::add_collateral_to_symbol`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function remove_collateral_from_symbol(
    collateral: any,
    index: any,
    direction: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::remove_collateral_from_symbol`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function set_symbol_status(
    index: any,
    direction: any,
    open_enabled: any,
    decrease_enabled: any,
    liquidate_enabled: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::set_symbol_status`,
        typeArguments: [index, contract_address+"::pool::"+direction],
        functionArguments: [
          open_enabled,
          decrease_enabled,
          liquidate_enabled
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function replace_position_config(
    index: any,
    direction: any,
    max_leverage: any,
    min_holding_duration: any,
    max_reserved_multiplier: any,
    min_collateral_value: any,
    open_fee_bps: any,
    decrease_fee_bps: any,
    liquidation_threshold: any,
    liquidation_bonus: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::replace_position_config`,
        typeArguments: [index, contract_address+"::pool::"+direction],
        functionArguments: [
          max_leverage,
          min_holding_duration,
          max_reserved_multiplier,
          min_collateral_value,
          open_fee_bps,
          decrease_fee_bps,
          liquidation_threshold,
          liquidation_bonus,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function open_position(
    collateral: any,
    index: any,
    direction: any,
    fee: any,
    trade_level: any,
    open_amount: any,
    reserve_amount: any,
    collateral_amount: any,
    fee_amount: any,
    collateral_price_threshold: any,
    limited_index_price: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::open_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction, fee],
        functionArguments: [
          trade_level,
          open_amount,
          reserve_amount,
          collateral_amount,
          fee_amount,
          collateral_price_threshold,
          limited_index_price,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function decrease_position(
    collateral: any,
    index: any,
    direction: any,
    fee: any,
    trade_level: any,
    fee_amount: any,
    take_profit: any,
    decrease_amount: any,
    collateral_price_threshold: any,
    limited_index_price: any,
    position_num: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::decrease_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction, fee],
        functionArguments: [
          trade_level,
          fee_amount,
          take_profit,
          decrease_amount,
          collateral_price_threshold,
          limited_index_price,
          position_num,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function decrease_reserved_from_position(
    collateral: any,
    index: any,
    direction: any,
    decrease_amount: any,
    position_num: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::decrease_reserved_from_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [
          decrease_amount,
          position_num,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function pledge_in_position(
    collateral: any,
    index: any,
    direction: any,
    pledge_num: any,
    position_num: any,
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::pledge_in_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [
          pledge_num,
          position_num,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function redeem_from_position(
    collateral: any,
    index: any,
    direction: any,
    redeem_amount: any,
    position_num: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::redeem_from_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [
          redeem_amount,
          position_num,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function liquidate_position(
    collateral: any,
    index: any,
    direction: any,
    owner: any,
    position_num: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::liquidate_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [
          owner,
          position_num,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;

  }

  async function clear_closed_position(
    collateral: any,
    index: any,
    direction: any,
    position_num: any,
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::clear_closed_position`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [
          position_num,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function execute_open_position_order(
    collateral: any,
    index: any,
    direction: any,
    fee: any,
    owner: any,
    order_num: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::execute_open_position_order`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction, fee],
        functionArguments: [
          owner,
          order_num,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function execute_decrease_position_order(
    collateral: any,
    index: any,
    direction: any,
    fee: any,
    owner: any,
    order_num: any,
    position_num: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::execute_decrease_position_order`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction, fee],
        functionArguments: [
          owner,
          order_num,
          position_num,
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function clear_open_position_order(
    collateral: any,
    index: any,
    direction: any,
    fee: any,
    order_num: any,
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::clear_closed_position_order`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction, fee],
        functionArguments: [
          order_num,          
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }


  async function clear_decrease_position_order(
    collateral: any,
    index: any,
    direction: any,
    fee: any,
    order_num: any,
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::clear_decrease_position_order`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction, fee],
        functionArguments: [
          order_num,          
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,    
    });

    return committedTransaction;
  }

  async function deposit(
    collateral: any,
    deposit_amount: any,
    min_amount_out: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::deposit`,
        typeArguments: [collateral],
        functionArguments: [
          deposit_amount,
          min_amount_out, 
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function withdraw(
    collateral: any,
    lp_burn_amount: any,
    min_amount_out: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::withdraw`,
        typeArguments: [collateral],
        functionArguments: [
          lp_burn_amount,
          min_amount_out, 
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  async function swap(
    source: any,
    destination: any,
    amount_in: any,
    min_amount_out: any,
    feeder: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: alice.accountAddress,
      data: {
        function: `${contract_address}::market::swap`,
        typeArguments: [source, destination],
        functionArguments: [
          amount_in,
          min_amount_out, 
          feeder,
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: alice,
      transaction,
    });

    return committedTransaction;
  }

  function toByteArray(hexString: string) {
    let result: number[] = [];
    for (var i = 0; i < hexString.length; i += 2) {
      result.push(parseInt(hexString.substring(i, i+2), 16));
    }
    return result;
  }

  let vas = "";
  

  fetch("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e", {
	  method: 'GET',
	  headers: {
        'Content-type': 'application/json',
      },
	})
      .then((response) => response.json())
      .then((data) => {
        if (data.error) {
          alert(data.error);
        } else {
          vas = data["binary"]["data"][0];

          let vaas = toByteArray(vas);
          

          fetch("https://hermes-beta.pyth.network/v2/updates/price/latest?ids%5B%5D=41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722", {
            method: 'GET',
            headers: {
                'Content-type': 'application/json',
              },
          })
              .then((response) => response.json())
              .then((data2) => {

              vas = data2["binary"]["data"][0];
              let vaas2 = toByteArray(vas);
          
          open_position(
            "0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0::usdt::USDT",
            "0x1::aptos_coin::AptosCoin",
            "SHORT",
            "0x1::aptos_coin::AptosCoin",
            "1",
            "1000000",
            "100000",
            "100000",
            "10",
            "1",
            "1",
            [vaas2, vaas]
          )
          
          
         /*
          execute_open_position_order(
            "0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0::usdt::USDT",
            "0x1::aptos_coin::AptosCoin",
            "SHORT",
            "0x1::aptos_coin::AptosCoin",
            alice.accountAddress,
            "2",
            [vaas2, vaas]
          )
            */
           
            liquidate_position(
              "0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0::usdt::USDT",
              "0x1::aptos_coin::AptosCoin",
              "SHORT",
              alice.accountAddress,
              2,
              [vaas2, vaas]
              )
          })
              
        }
      });

      /*
      pledge_in_position(
        "0x6f60af74988c64cd3b7c1e214697e6949db39c061d8d4cf59a7e2bd1b66c8bf0::usdt::USDT",
        "0x1::aptos_coin::AptosCoin",
        "SHORT",
        "10",
        "1",
      )*/

    