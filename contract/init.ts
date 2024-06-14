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

  const contract_address = "0x999b2b425eff92c09e11e27f1c93c3783a38c7c54684c354f2132bcdf75855d9";

  async function add_new_vault(
    sender: Account,
    weight: any,
    max_interval: any,
    max_price_confidence: any,
    feeder: any,
    param_multiplier: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: contract_address,
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
      signer: sender,
      transaction,
    });

    return committedTransaction;
  }


  async function add_new_symbol(
    sender: Account,
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
      sender: contract_address,
      data: {
        function: `${contract_address}::market::add_collateral_to_symbol`,
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
      signer: sender,
      transaction,
    });

    return committedTransaction;

  }


  async function add_collateral_to_symbol(
    sender: Account,
    collateral: any,
    index: any,
    direction: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: contract_address,
      data: {
        function: `${contract_address}::coin::transfer`,
        typeArguments: [collateral, index, contract_address+"::pool::"+direction],
        functionArguments: [],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: sender,
      transaction,
    });

    return committedTransaction;
  }


  async function replace_symbol_feeder(
    sender: Account,
    index: any,
    direction: any,
    feeder: any,
    max_interval: any,
    max_price_confidence: any
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: contract_address,
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
      signer: sender,
      transaction,
    });

    return committedTransaction;

  }


  async function deposit(
    sender: Account,
    collateral: any,
    deposit_amount: any,
    min_amount_out: any,
  ) {
    const transaction = await aptos.transaction.build.simple({
      sender: contract_address,
      data: {
        function: `${contract_address}::market::deposit`,
        typeArguments: [collateral],
        functionArguments: [
          deposit_amount,
          min_amount_out, 
        ],
      },
    });

    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: sender,
      transaction,
    });

    return committedTransaction;

  }


  async function open_position(
    sender: Account,
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
      sender: contract_address,
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
      signer: sender,
      transaction,
    });

    return committedTransaction;

  }

  const weight = parseInt("100000000000000000");
  const max_interval = parseInt("20");
  const max_price_confidence = parseInt("18446744073709551615");
  //const feeder = new String("44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e");
  const param_multiplier = parseInt("800000000000000");

  function toByteArray(hexString: string) {
    let result: number[] = [];
    for (var i = 0; i < hexString.length; i += 2) {
      result.push(parseInt(hexString.substring(i, 2), 16));
    }
    return result;
  }

  const feeder = toByteArray("0x44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e");

  /*
  const serializer = new Serializer();
  weight.serialize(serializer);
  max_interval.serialize(serializer);
  max_price_confidence.serialize(serializer);
  param_multiplier.serialize(serializer);
*/
  const alice = Account.fromPrivateKey({
    privateKey: new Ed25519PrivateKey("0x26b0855831c4ab50215da60e87521dbaa465ab90e5299d61e155f5854958a43a")
  });

  add_new_vault(
    alice, 
    weight,
    max_interval,
    max_price_confidence,
    feeder,
    param_multiplier
  );