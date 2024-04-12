import { InMemorySigner } from "@taquito/signer";
import { MichelsonMap, TezosToolkit } from "@taquito/taquito";
import { char2Bytes } from "@taquito/utils";

import myContract from "../compiled/exo_2.mligo.json";

const RPC_ENDPOINT = "https://ghostnet.tezos.marigold.dev";

async function main() {
  const Tezos = new TezosToolkit(RPC_ENDPOINT);

  //set alice key
  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(
      "edskS6fJx41BJvzZYhjzmYhMTDcT5g4TSC1R8sLtapUdoNnkxECfG79myoT2qBXJJYhTLPW6skzFfXUmKa1ABKH1ETQDP4SiM3"
    ),
  });

  const initialStorage = {
    admin : "tz1eEG8zDbkQr9r7vnsCGS8meXxqt7JXoDRb",
    value : "42" 
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