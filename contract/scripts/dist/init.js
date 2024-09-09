"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.formatAptosDecimal = exports.DOGE_FEEDER_ADDRESS = exports.PEPE_FEEDER_ADDRESS = exports.AVAX_FEEDER_ADDRESS = exports.SOL_FEEDER_ADDRESS = exports.BNB_FEEDER_ADDRESS = exports.ETH_FEEDER_ADDRESS = exports.BTC_FEEDER_ADDRESS = exports.USDC_FEEDER_ADDRESS = exports.USDT_FEEDER_ADDRESS = exports.APT_FEEDER_ADDRESS = exports.COIN_ADDRESS = exports.FEERDER_ADDRESS = exports.MODULE_ADDRESS = void 0;
var ts_sdk_1 = require("@aptos-labs/ts-sdk");
exports.MODULE_ADDRESS = "0x74bd2f63f61199da6b79f3bf478cea1ae7543dbf1c6bff1176ab9ff86aa271e1";
exports.FEERDER_ADDRESS = "0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387";
exports.COIN_ADDRESS = "0xfa78899981b78f231628501583779f99565b49cbec9bbf84f9a04465ba17ca55";
exports.APT_FEEDER_ADDRESS = "44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e";
exports.USDT_FEEDER_ADDRESS = "41f3625971ca2ed2263e78573fe5ce23e13d2558ed3f2e47ab0f84fb9e7ae722";
exports.USDC_FEEDER_ADDRESS = "1fc18861232290221461220bd4e2acd1dcdfbc89c84092c93c18bdc7756c1588";
exports.BTC_FEEDER_ADDRESS = "f9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b";
exports.ETH_FEEDER_ADDRESS = "ca80ba6dc32e08d06f1aa886011eed1d77c77be9eb761cc10d72b7d0a2fd57a6";
exports.BNB_FEEDER_ADDRESS = "ecf553770d9b10965f8fb64771e93f5690a182edc32be4a3236e0caaa6e0581a";
exports.SOL_FEEDER_ADDRESS = "fe650f0367d4a7ef9815a593ea15d36593f0643aaaf0149bb04be67ab851decd";
exports.AVAX_FEEDER_ADDRESS = "d7566a3ba7f7286ed54f4ae7e983f4420ae0b1e0f3892e11f9c4ab107bbad7b9";
exports.PEPE_FEEDER_ADDRESS = "ed82efbfade01083ffa8f64664c86af39282c9f084877066ae72b635e77718f0";
exports.DOGE_FEEDER_ADDRESS = "31775e1d6897129e8a84eeba975778fb50015b88039e9bc140bbd839694ac0ae";
var formatAptosDecimal = function (value, decimals) {
    if (decimals === void 0) { decimals = 8; }
    return Number((value * Math.pow(10, decimals)).toFixed(0));
};
exports.formatAptosDecimal = formatAptosDecimal;
var aptosConfig = new ts_sdk_1.AptosConfig({ fullnode: "https://aptos.testnet.suzuka.movementlabs.xyz/v1" });
var aptos = new ts_sdk_1.Aptos(aptosConfig);
var moduleAddress = exports.MODULE_ADDRESS;
var coinAddress = exports.COIN_ADDRESS;
var PRIVATE_KEY = '0x133487887937d76a6be888daa30247d04aa040b56fcb6b79b36bb04144d89c22';
var singer = ts_sdk_1.Account.fromPrivateKey({
    privateKey: new ts_sdk_1.Ed25519PrivateKey(PRIVATE_KEY),
});
var MOCK_USDC_COIN_STORE = "0x1::coin::CoinStore<".concat(coinAddress, "::usdc::USDC>");
var MOCK_USDT_COIN_STORE = "0x1::coin::CoinStore<".concat(coinAddress, "::usdt::USDT>");
var MOCK_LP_COIN_STORE = "0x1::coin::CoinStore<".concat(moduleAddress, "::lp::LP>");
//vault
var APTOS_VAULT_ADDRESS = ts_sdk_1.APTOS_COIN;
var USDC_VAULT_ADDRESS = "".concat(coinAddress, "::usdc::USDC");
var USDT_VAULT_ADDRESS = "".concat(coinAddress, "::usdt::USDT");
var BTC_VAULT_ADDRESS = "".concat(coinAddress, "::btc::BTC");
var ETH_VAULT_ADDRESS = "".concat(coinAddress, "::ETH::ETH");
//symbol
var BTC_SYMBOL_ADDRESS = "".concat(coinAddress, "::btc::BTC");
var ETH_SYMBOL_ADDRESS = "".concat(coinAddress, "::ETH::ETH");
var BNB_SYMBOL_ADDRESS = "".concat(coinAddress, "::BNB::BNB");
var SOL_SYMBOL_ADDRESS = "".concat(coinAddress, "::SOL::SOL");
var AVAX_SYMBOL_ADDRESS = "".concat(coinAddress, "::AVAX::AVAX");
var APTOS_SYMBOL_ADDRESS = ts_sdk_1.APTOS_COIN;
var DOGE_SYMBOL_ADDRESS = "".concat(coinAddress, "::DOGE::DOGE");
var PEPE_SYMBOL_ADDRESS = "".concat(coinAddress, "::PEPE::PEPE");
//direction
var SIDE_LONG = "".concat(moduleAddress, "::pool::LONG");
var SIDE_SHORT = "".concat(moduleAddress, "::pool::SHORT");
//fee
var FEE_ADDRESS = ts_sdk_1.APTOS_COIN;
//list
var VAULT_LIST = [
    // {
    //     name: 'APT',
    //     vaultType: APTOS_VAULT_ADDRESS,
    //     weight: formatAptosDecimal(0.05, 18),
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         APT_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    // },
    // {
    //     name: 'USDC',
    //     vaultType: USDC_VAULT_ADDRESS,
    //     weight: formatAptosDecimal(0.3, 18),
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         USDC_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    // },
    // {
    //     name: 'USDT',
    //     vaultType: USDT_VAULT_ADDRESS,
    //     weight: formatAptosDecimal(0.3, 18),
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         USDT_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    // },
    // {
    //     name: 'BTC',
    //     vaultType: BTC_VAULT_ADDRESS,
    //     weight: formatAptosDecimal(0.2, 18),
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         BTC_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    // },
    {
        name: 'ETH',
        vaultType: ETH_VAULT_ADDRESS,
        weight: (0, exports.formatAptosDecimal)(0.15, 18),
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder: exports.ETH_FEEDER_ADDRESS,
        param_multiplier: '800000000000000',
    },
];
var SYMBOL_LIST = [
    {
        name: 'BTC',
        symbolType: BTC_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder: exports.BTC_FEEDER_ADDRESS,
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: (0, exports.formatAptosDecimal)(5, 18),
        open_fee_bps: (0, exports.formatAptosDecimal)(0.001, 18),
        decrease_fee_bps: (0, exports.formatAptosDecimal)(0.001, 18),
        liquidation_threshold: (0, exports.formatAptosDecimal)(0.98, 18),
        liquidation_bonus: '10000000000000000',
    },
    {
        name: 'ETH',
        symbolType: ETH_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder: exports.ETH_FEEDER_ADDRESS,
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: (0, exports.formatAptosDecimal)(5, 18),
        open_fee_bps: (0, exports.formatAptosDecimal)(0.001, 18),
        decrease_fee_bps: (0, exports.formatAptosDecimal)(0.001, 18),
        liquidation_threshold: (0, exports.formatAptosDecimal)(0.98, 18),
        liquidation_bonus: '10000000000000000',
    },
    {
        name: 'BNB',
        symbolType: BNB_SYMBOL_ADDRESS,
        max_interval: 2000,
        max_price_confidence: '18446744073709551615',
        feeder: exports.BNB_FEEDER_ADDRESS,
        param_multiplier: '800000000000000',
        param_max: '7500000000000000',
        max_leverage: 100,
        min_holding_duration: 20,
        max_reserved_multiplier: 20,
        min_collateral_value: (0, exports.formatAptosDecimal)(5, 18),
        open_fee_bps: (0, exports.formatAptosDecimal)(0.001, 18),
        decrease_fee_bps: (0, exports.formatAptosDecimal)(0.001, 18),
        liquidation_threshold: (0, exports.formatAptosDecimal)(0.98, 18),
        liquidation_bonus: '10000000000000000',
    },
    // {
    //     name: 'SOL',
    //     symbolType: SOL_SYMBOL_ADDRESS,
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         SOL_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    //     param_max: '7500000000000000',
    //     max_leverage: 100,
    //     min_holding_duration: 20,
    //     max_reserved_multiplier: 20,
    //     min_collateral_value: formatAptosDecimal(5, 18),
    //     open_fee_bps: formatAptosDecimal(0.001, 18),
    //     decrease_fee_bps: formatAptosDecimal(0.001, 18),
    //     liquidation_threshold: formatAptosDecimal(0.98, 18),
    //     liquidation_bonus: '10000000000000000',
    // },
    // {
    //     name: 'AVAX',
    //     symbolType: AVAX_SYMBOL_ADDRESS,
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         AVAX_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    //     param_max: '7500000000000000',
    //     max_leverage: 100,
    //     min_holding_duration: 20,
    //     max_reserved_multiplier: 20,
    //     min_collateral_value: formatAptosDecimal(5, 18),
    //     open_fee_bps: formatAptosDecimal(0.001, 18),
    //     decrease_fee_bps: formatAptosDecimal(0.001, 18),
    //     liquidation_threshold: formatAptosDecimal(0.98, 18),
    //     liquidation_bonus: '10000000000000000',
    // },
    // {
    //     name: 'APT',
    //     symbolType: APTOS_SYMBOL_ADDRESS,
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         APT_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    //     param_max: '7500000000000000',
    //     max_leverage: 100,
    //     min_holding_duration: 20,
    //     max_reserved_multiplier: 20,
    //     min_collateral_value: formatAptosDecimal(5, 18),
    //     open_fee_bps: formatAptosDecimal(0.001, 18),
    //     decrease_fee_bps: formatAptosDecimal(0.001, 18),
    //     liquidation_threshold: formatAptosDecimal(0.98, 18),
    //     liquidation_bonus: '10000000000000000',
    // },
    // {
    //     name: 'DOGE',
    //     symbolType: DOGE_SYMBOL_ADDRESS,
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         DOGE_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    //     param_max: '7500000000000000',
    //     max_leverage: 100,
    //     min_holding_duration: 20,
    //     max_reserved_multiplier: 20,
    //     min_collateral_value: formatAptosDecimal(5, 18),
    //     open_fee_bps: formatAptosDecimal(0.001, 18),
    //     decrease_fee_bps: formatAptosDecimal(0.001, 18),
    //     liquidation_threshold: formatAptosDecimal(0.98, 18),
    //     liquidation_bonus: '10000000000000000',
    // },
    // {
    //     name: 'PEPE',
    //     symbolType: PEPE_SYMBOL_ADDRESS,
    //     max_interval: 2000,
    //     max_price_confidence: '18446744073709551615',
    //     feeder:
    //         PEPE_FEEDER_ADDRESS,
    //     param_multiplier: '800000000000000',
    //     param_max: '7500000000000000',
    //     max_leverage: 100,
    //     min_holding_duration: 20,
    //     max_reserved_multiplier: 20,
    //     min_collateral_value: formatAptosDecimal(5, 18),
    //     open_fee_bps: formatAptosDecimal(0.001, 18),
    //     decrease_fee_bps: formatAptosDecimal(0.001, 18),
    //     liquidation_threshold: formatAptosDecimal(0.98, 18),
    //     liquidation_bonus: '10000000000000000',
    // },
];
var DIRECTION_LIST = [SIDE_LONG, SIDE_SHORT];
function hexStringToUint8Array(hexString) {
    if (hexString.length % 2 !== 0) {
        hexString = '0' + hexString;
    }
    var byteArray = new Uint8Array(hexString.length / 2);
    for (var i = 0; i < byteArray.length; i++) {
        byteArray[i] = parseInt(hexString.slice(i * 2, i * 2 + 2), 16);
    }
    return byteArray;
}
function executeAddNewVault() {
    return __awaiter(this, void 0, void 0, function () {
        var _i, VAULT_LIST_1, vault, transaction, committedTransaction, response;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _i = 0, VAULT_LIST_1 = VAULT_LIST;
                    _a.label = 1;
                case 1:
                    if (!(_i < VAULT_LIST_1.length)) return [3 /*break*/, 6];
                    vault = VAULT_LIST_1[_i];
                    return [4 /*yield*/, aptos.transaction.build.simple({
                            sender: singer.accountAddress,
                            data: {
                                function: "".concat(moduleAddress, "::market::add_new_vault"),
                                typeArguments: [vault.vaultType],
                                functionArguments: [
                                    vault.weight,
                                    vault.max_interval,
                                    vault.max_price_confidence,
                                    hexStringToUint8Array(vault.feeder),
                                    vault.param_multiplier,
                                ],
                            },
                        })];
                case 2:
                    transaction = _a.sent();
                    return [4 /*yield*/, aptos.signAndSubmitTransaction({
                            signer: singer,
                            transaction: transaction,
                        })];
                case 3:
                    committedTransaction = _a.sent();
                    return [4 /*yield*/, aptos.waitForTransaction({
                            transactionHash: committedTransaction.hash
                        })];
                case 4:
                    response = _a.sent();
                    console.log("\uD83D\uDE80 ~ Transaction submitted Add new Vault : ".concat(vault.name), response);
                    _a.label = 5;
                case 5:
                    _i++;
                    return [3 /*break*/, 1];
                case 6: return [2 /*return*/];
            }
        });
    });
}
function executeAddNewSymbol() {
    return __awaiter(this, void 0, void 0, function () {
        var _i, SYMBOL_LIST_1, symbol, _a, DIRECTION_LIST_1, direction, transaction, committedTransaction, response;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _i = 0, SYMBOL_LIST_1 = SYMBOL_LIST;
                    _b.label = 1;
                case 1:
                    if (!(_i < SYMBOL_LIST_1.length)) return [3 /*break*/, 8];
                    symbol = SYMBOL_LIST_1[_i];
                    _a = 0, DIRECTION_LIST_1 = DIRECTION_LIST;
                    _b.label = 2;
                case 2:
                    if (!(_a < DIRECTION_LIST_1.length)) return [3 /*break*/, 7];
                    direction = DIRECTION_LIST_1[_a];
                    console.log("\uD83D\uDE80 ~ Add new Symbol Execute ~ symbol:".concat(symbol.name, ", direction:").concat(direction, " "));
                    return [4 /*yield*/, aptos.transaction.build.simple({
                            sender: singer.accountAddress,
                            data: {
                                function: "".concat(moduleAddress, "::market::add_new_symbol"),
                                typeArguments: [symbol.symbolType, direction],
                                functionArguments: [
                                    symbol.max_interval,
                                    symbol.max_price_confidence,
                                    hexStringToUint8Array(symbol.feeder),
                                    symbol.param_multiplier,
                                    symbol.param_max,
                                    symbol.max_leverage,
                                    symbol.min_holding_duration,
                                    symbol.max_reserved_multiplier,
                                    symbol.min_collateral_value,
                                    symbol.open_fee_bps,
                                    symbol.decrease_fee_bps,
                                    symbol.liquidation_threshold,
                                    symbol.liquidation_bonus,
                                ],
                            },
                        })];
                case 3:
                    transaction = _b.sent();
                    return [4 /*yield*/, aptos.signAndSubmitTransaction({
                            signer: singer,
                            transaction: transaction,
                        })];
                case 4:
                    committedTransaction = _b.sent();
                    return [4 /*yield*/, aptos.waitForTransaction({
                            transactionHash: committedTransaction.hash
                        })];
                case 5:
                    response = _b.sent();
                    console.log("\uD83D\uDE80 ~ Transaction submitted Add new Symbol : ".concat(symbol.name), response);
                    _b.label = 6;
                case 6:
                    _a++;
                    return [3 /*break*/, 2];
                case 7:
                    _i++;
                    return [3 /*break*/, 1];
                case 8: return [2 /*return*/];
            }
        });
    });
}
function executeAddCollateralToSymbol() {
    return __awaiter(this, void 0, void 0, function () {
        var _i, VAULT_LIST_2, vault, _a, SYMBOL_LIST_2, symbol, _b, DIRECTION_LIST_2, direction, transaction, committedTransaction, response, error_1;
        return __generator(this, function (_c) {
            switch (_c.label) {
                case 0:
                    _i = 0, VAULT_LIST_2 = VAULT_LIST;
                    _c.label = 1;
                case 1:
                    if (!(_i < VAULT_LIST_2.length)) return [3 /*break*/, 12];
                    vault = VAULT_LIST_2[_i];
                    _a = 0, SYMBOL_LIST_2 = SYMBOL_LIST;
                    _c.label = 2;
                case 2:
                    if (!(_a < SYMBOL_LIST_2.length)) return [3 /*break*/, 11];
                    symbol = SYMBOL_LIST_2[_a];
                    _b = 0, DIRECTION_LIST_2 = DIRECTION_LIST;
                    _c.label = 3;
                case 3:
                    if (!(_b < DIRECTION_LIST_2.length)) return [3 /*break*/, 10];
                    direction = DIRECTION_LIST_2[_b];
                    console.log("\uD83D\uDE80 ~ Add new Vault Execute ~ vault:".concat(vault.name, ", symbol:").concat(symbol.name, ", direction:").concat(direction, " "));
                    return [4 /*yield*/, aptos.transaction.build.simple({
                            sender: singer.accountAddress,
                            data: {
                                function: "".concat(moduleAddress, "::market::add_collateral_to_symbol"),
                                typeArguments: [
                                    vault.vaultType, symbol.symbolType, direction
                                ],
                                functionArguments: [],
                            },
                        })];
                case 4:
                    transaction = _c.sent();
                    _c.label = 5;
                case 5:
                    _c.trys.push([5, 8, , 9]);
                    return [4 /*yield*/, aptos.signAndSubmitTransaction({
                            signer: singer,
                            transaction: transaction,
                        })];
                case 6:
                    committedTransaction = _c.sent();
                    return [4 /*yield*/, aptos.waitForTransaction({
                            transactionHash: committedTransaction.hash
                        })];
                case 7:
                    response = _c.sent();
                    console.log("\uD83D\uDE80 ~ Transaction submitted Collateral => Symbol", response);
                    return [3 /*break*/, 9];
                case 8:
                    error_1 = _c.sent();
                    console.log("🚀 ~ executeAddCollateralToSymbol ~ error:", error_1);
                    return [3 /*break*/, 9];
                case 9:
                    _b++;
                    return [3 /*break*/, 3];
                case 10:
                    _a++;
                    return [3 /*break*/, 2];
                case 11:
                    _i++;
                    return [3 /*break*/, 1];
                case 12: return [2 /*return*/];
            }
        });
    });
}
function main() {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: 
                // await executeAddNewVault()
                // await executeAddNewSymbol()
                return [4 /*yield*/, executeAddCollateralToSymbol()
                    // await replaceVaultPriceFeeder()
                    // await replaceSymbolPriceFeeder()
                ];
                case 1:
                    // await executeAddNewVault()
                    // await executeAddNewSymbol()
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
function replaceVaultPriceFeeder() {
    return __awaiter(this, void 0, void 0, function () {
        var _i, VAULT_LIST_3, vault, transaction, committedTransaction, response;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    _i = 0, VAULT_LIST_3 = VAULT_LIST;
                    _a.label = 1;
                case 1:
                    if (!(_i < VAULT_LIST_3.length)) return [3 /*break*/, 6];
                    vault = VAULT_LIST_3[_i];
                    return [4 /*yield*/, aptos.transaction.build.simple({
                            sender: singer.accountAddress,
                            data: {
                                function: "".concat(moduleAddress, "::market::replace_vault_feeder"),
                                typeArguments: [vault.vaultType],
                                functionArguments: [
                                    hexStringToUint8Array(vault.feeder),
                                    vault.max_interval,
                                    vault.max_price_confidence,
                                ],
                            },
                        })];
                case 2:
                    transaction = _a.sent();
                    return [4 /*yield*/, aptos.signAndSubmitTransaction({
                            signer: singer,
                            transaction: transaction,
                        })];
                case 3:
                    committedTransaction = _a.sent();
                    return [4 /*yield*/, aptos.waitForTransaction({
                            transactionHash: committedTransaction.hash
                        })];
                case 4:
                    response = _a.sent();
                    console.log("\uD83D\uDE80 ~ Transaction submitted Replace Vault Feeder : ".concat(vault.name), response.success ? 'Success' : 'Failed');
                    _a.label = 5;
                case 5:
                    _i++;
                    return [3 /*break*/, 1];
                case 6: return [2 /*return*/];
            }
        });
    });
}
function replaceSymbolPriceFeeder() {
    return __awaiter(this, void 0, void 0, function () {
        var _i, SYMBOL_LIST_3, symbol, _a, DIRECTION_LIST_3, direction, transaction, committedTransaction, response;
        return __generator(this, function (_b) {
            switch (_b.label) {
                case 0:
                    _i = 0, SYMBOL_LIST_3 = SYMBOL_LIST;
                    _b.label = 1;
                case 1:
                    if (!(_i < SYMBOL_LIST_3.length)) return [3 /*break*/, 8];
                    symbol = SYMBOL_LIST_3[_i];
                    _a = 0, DIRECTION_LIST_3 = DIRECTION_LIST;
                    _b.label = 2;
                case 2:
                    if (!(_a < DIRECTION_LIST_3.length)) return [3 /*break*/, 7];
                    direction = DIRECTION_LIST_3[_a];
                    console.log("\uD83D\uDE80 ~ Replace Symbol Feeder Execute ~ symbol:".concat(symbol.name, ", direction:").concat(direction, " "));
                    return [4 /*yield*/, aptos.transaction.build.simple({
                            sender: singer.accountAddress,
                            data: {
                                function: "".concat(moduleAddress, "::market::replace_symbol_feeder"),
                                typeArguments: [symbol.symbolType, direction],
                                functionArguments: [
                                    hexStringToUint8Array(symbol.feeder),
                                    symbol.max_interval,
                                    symbol.max_price_confidence,
                                ],
                            },
                        })];
                case 3:
                    transaction = _b.sent();
                    return [4 /*yield*/, aptos.signAndSubmitTransaction({
                            signer: singer,
                            transaction: transaction,
                        })];
                case 4:
                    committedTransaction = _b.sent();
                    return [4 /*yield*/, aptos.waitForTransaction({
                            transactionHash: committedTransaction.hash
                        })];
                case 5:
                    response = _b.sent();
                    console.log("\uD83D\uDE80 ~ Transaction submitted Replace Symbol Feeder: ".concat(symbol.name), response.success ? 'Success' : 'Failed');
                    _b.label = 6;
                case 6:
                    _a++;
                    return [3 /*break*/, 2];
                case 7:
                    _i++;
                    return [3 /*break*/, 1];
                case 8: return [2 /*return*/];
            }
        });
    });
}
(function () { return __awaiter(void 0, void 0, void 0, function () {
    return __generator(this, function (_a) {
        switch (_a.label) {
            case 0: return [4 /*yield*/, main()];
            case 1:
                _a.sent();
                return [2 /*return*/];
        }
    });
}); })();
