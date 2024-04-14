"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const signer_1 = require("@taquito/signer");
const taquito_1 = require("@taquito/taquito");
const dotenv = __importStar(require("dotenv"));
const exo_2_mligo_json_1 = __importDefault(require("../compiled/exo_2.mligo.json"));
const RPC_ENDPOINT = "http://ghostnet.tezos.marigold.dev";
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        const Tezos = new taquito_1.TezosToolkit(RPC_ENDPOINT);
        dotenv.config();
        const SECRET_KEY = process.env.SECRET_KEY || "";
        const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS || "";
        Tezos.setProvider({
            signer: yield signer_1.InMemorySigner.fromSecretKey(SECRET_KEY),
        });
        const initialStorage = {
            admin: ADMIN_ADDRESS,
            value: "42",
            ledger: new Map([]),
            metadata: new Map([]),
            operators: new Map([]),
            token_metadata: new Map([]),
            total_supply: 10000,
        };
        try {
            const originated = yield Tezos.contract.originate({
                code: exo_2_mligo_json_1.default,
                storage: initialStorage,
            });
            console.log(`Waiting for myContract ${originated.contractAddress} to be confirmed...`);
            yield originated.confirmation(2);
            console.log("confirmed contract: ", originated.contractAddress);
        }
        catch (error) {
            console.log(error);
        }
    });
}
main();
