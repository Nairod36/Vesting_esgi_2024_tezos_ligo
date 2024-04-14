import { InMemorySigner } from "@taquito/signer";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { char2Bytes } from "@taquito/utils";
import * as dotenv from "dotenv";
import myContract from "../compiled/exo_2.mligo.json";

const RPC_ENDPOINT = "http://ghostnet.tezos.marigold.dev";

async function main() {
  const Tezos = new TezosToolkit(RPC_ENDPOINT);

  dotenv.config();
  const SECRET_KEY = process.env.SECRET_KEY || "";
  const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS || "";
  
  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(SECRET_KEY),
  });

  const initialStorage = {
    admin : ADMIN_ADDRESS,
    value : "42",
    ledger: new Map([]),
    metadata: new Map([]),
    operators: new Map([]),
    token_metadata: new Map([]),
    total_supply: 10000,
  };
  

  try {
    const originated = await Tezos.contract.originate({
      code: myContract,
      storage: initialStorage,
    });
    console.log(
      `Waiting for myContract ${originated.contractAddress} to be confirmed...`
    );
    await originated.confirmation(2);
    console.log("confirmed contract: ", originated.contractAddress);
  } catch (error: any) {
    console.log(error);
  }
}

main();