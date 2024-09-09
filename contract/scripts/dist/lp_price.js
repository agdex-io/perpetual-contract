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
exports.MODULE_ADDRESS = "0x8a212ced6c20fb3a24c0580c7a5d7fc4dff7acf67abe697d7b0b56891d8d7c5d";
exports.FEERDER_ADDRESS = "0x7e783b349d3e89cf5931af376ebeadbfab855b3fa239b7ada8f5a92fbea6b387";
exports.COIN_ADDRESS = "0x36e30e32c62d6c3ff4e3f000885626e18d6deb162a8091ac3af6aad4f3bdfae5";
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
var aptosConfig = new ts_sdk_1.AptosConfig({ network: ts_sdk_1.Network.TESTNET });
var aptos = new ts_sdk_1.Aptos(aptosConfig);
var moduleAddress = exports.MODULE_ADDRESS;
var coinAddress = exports.COIN_ADDRESS;
var PRIVATE_KEY = '0x5adbf0299c7ddd87a75455c03d1b56880eb89e0f1d99cc3f2e0d748aca9c18d4';
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
function simulateTransaction() {
    return __awaiter(this, void 0, void 0, function () {
        var transaction, response;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, aptos.transaction.build.simple({
                        sender: singer.accountAddress,
                        data: {
                            function: "".concat(moduleAddress, "::market::deposit"),
                            typeArguments: [APTOS_VAULT_ADDRESS],
                            functionArguments: [
                                100000000,
                                0,
                                new ts_sdk_1.MoveVector([]),
                            ],
                        },
                    })];
                case 1:
                    transaction = _a.sent();
                    return [4 /*yield*/, aptos.transaction.simulate.simple({
                            signerPublicKey: singer.publicKey,
                            transaction: transaction
                        })];
                case 2:
                    response = _a.sent();
                    console.log(response[0]['events'][4]);
                    return [2 /*return*/];
            }
        });
    });
}
function main() {
    return __awaiter(this, void 0, void 0, function () {
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0: return [4 /*yield*/, simulateTransaction()];
                case 1:
                    _a.sent();
                    return [2 /*return*/];
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
