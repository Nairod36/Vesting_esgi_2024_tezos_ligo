#import "@ligo/fa/lib/main.mligo" "FA2"


#import "@ligo/fa/lib/fa2/asset/single_asset.impl.mligo" "SingleAsset"
#import "@ligo/fa/test/fa2/balance_of_callback_contract.mligo" "Callback"

let test_deploy = 
    let { storage; operations } = Test.originate (contract_of SingleAsset) in
    let get_initial_storage (a, b, c : nat * nat * nat) =
    let () = Test.reset_state 6n ([] : tez list) in

    let owner1 = Test.nth_bootstrap_account 0 in
    let owner2 = Test.nth_bootstrap_account 1 in
    let owner3 = Test.nth_bootstrap_account 2 in

    let owners = [owner1; owner2; owner3] in

    let op1 = Test.nth_bootstrap_account 3 in
    let op2 = Test.nth_bootstrap_account 4 in
    let op3 = Test.nth_bootstrap_account 5 in

    let ops = [op1; op2; op3] in

    let ledger = Big_map.literal ([
        (owner1, a);
        (owner2, b);
        (owner3, c);
      ])
    in

    let operators  = Big_map.literal ([
        (owner1, Set.literal [op1]);
        (owner2, Set.literal [op1;op2]);
        (owner3, Set.literal [op1;op3]);
        (op3   , Set.literal [op1;op2]);
      ])
    in

    let token_info = (Map.empty: (string, bytes) map) in
    let token_data = {
      token_id   = 0n;
      token_info = token_info;
    } in
    let token_metadata = Big_map.literal ([
      (0n, token_data);
    ])
    in


 let metadata =Big_map.literal [
	("", [%bytes {|tezos-storage:data|}]);
	("data", [%bytes
{|{
	"name":"FA2",
	"description":"Example FA2 implementation",
	"version":"0.1.0",
	"license":{"name":"MIT"},
	"authors":["Benjamin Fuentes<benjamin.fuentes@marigold.dev>"],
	"homepage":"",
	"source":{"tools":["Ligo"], "location":"https://github.com/ligolang/contract-catalogue/tree/main/lib/fa2"},
	"interfaces":["TZIP-012"],
	"errors":[],
	"views":[]

}|}]);
]  in

  let initial_storage: FA2_single_asset.storage = {
      ledger         = ledger;
      metadata       = metadata;
      token_metadata = token_metadata;
      operators      = operators;
  } in

  initial_storage, owners, ops

  
        






