#import "./helper/bootstrap.mligo" "Bootstrap"
#import "./helper/assert.mligo" "Assert"

#import "../src/NairodToken.mligo" "Token"

let test_total_supply =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let new_storage = Test.get_storage addr in 
  assert( new_storage.total_supply = 5n)

let test_mint =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let () = Test.set_source owner1 in
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let new_storage = Test.get_storage addr in 
  let owner1_balance = match Big_map.find_opt owner1 new_storage.ledger with
    |Some l -> l
    |None -> failwith Token.C.Errors.not_found
  in
  assert( owner1_balance = 5n)

let test_mint_fail =
  let (owner1, owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let () = Test.set_source owner2 in
  let r = Test.transfer_to_contract contr_token (Mint 5n owner2) 0tez in
  Assert.string_failure r  Token.C.Errors.not_admin

let test_transfer =
  let (owner1, owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let () = Test.set_source(owner1) in 
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let r = Test.transfer_to_contract contr_token (Transfer owner2 5n) 0tez in
  let () = Assert.tx_success r in
  let new_storage = Test.get_storage addr in 
  let ledger = match Big_map.find_opt owner2 new_storage.ledger with
    |Some l -> l
    |None -> failwith Token.C.Errors.not_found
  in
  assert( ledger = 5n)

let test_transfer_fail =
  let (owner1, owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let () = Test.set_source(owner1) in 
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let r = Test.transfer_to_contract contr_token (Transfer owner2 10n) 0tez in
  Assert.string_failure r  Token.C.Errors.no_money

let test_burn =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let r = Test.transfer_to_contract contr_token (Burn 5n) 0tez in
  let () = Assert.tx_success r in
  let new_storage = Test.get_storage addr in 
  assert( new_storage.total_supply = 0n)

let test_burn_fail_owner =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let r = Test.transfer_to_contract contr_token (Burn 10n) 0tez in
  Assert.string_failure r  Token.C.Errors.no_more_supply

let test_burn_fail_supply =
  let (owner1, owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { ledger = Big_map.literal[]; admin = owner1; total_supply = 0n } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of Token.C) initial_storage 0tez in
  let contr_token = Test.to_contract addr in
  let r = Test.transfer_to_contract contr_token (Mint 5n owner1) 0tez in
  let () = Assert.tx_success r in
  let () = Test.set_source(owner2) in
  let r = Test.transfer_to_contract contr_token (Burn 5n) 0tez in
  Assert.string_failure r  Token.C.Errors.not_admin