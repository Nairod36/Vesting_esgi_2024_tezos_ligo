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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const signer_1 = require("@taquito/signer");
const taquito_1 = require("@taquito/taquito");
const exo_2_mligo_json_1 = __importDefault(require("../compiled/exo_2.mligo.json"));
const RPC_ENDPOINT = "https://ghostnet.tezos.marigold.dev";
function main() {
    return __awaiter(this, void 0, void 0, function* () {
        const Tezos = new taquito_1.TezosToolkit(RPC_ENDPOINT);
        //set alice key
        Tezos.setProvider({
            signer: yield signer_1.InMemorySigner.fromSecretKey("edskS6fJx41BJvzZYhjzmYhMTDcT5g4TSC1R8sLtapUdoNnkxECfG79myoT2qBXJJYhTLPW6skzFfXUmKa1ABKH1ETQDP4SiM3"),
        });
        const initialStorage = {
            admin: "tz1eEG8zDbkQr9r7vnsCGS8meXxqt7JXoDRb",
            value: "42"
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
