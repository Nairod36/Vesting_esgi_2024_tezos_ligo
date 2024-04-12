#import "./helper/bootstrap.mligo" "Bootstrap"
#import "./helper/assert.mligo" "Assert"

#import "../src/exo_2.mligo" "MyContract"
#import "../src/callCounter.mligo" "CallContract"

// type param = MyContract.C parameter_of

let test_exo_2_solution_check_initial_storage =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { value = 42; admin = owner1 } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in
  assert (Test.get_storage addr = initial_storage)


let test_exo_2_solution_increment =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { value = 42; admin = owner1 } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in
  let contr = Test.to_contract addr in
  let _r = Test.transfer_to_contract contr (Increment 1) 0tez in
  let current_storage = Test.get_storage addr in
  assert(current_storage.value = 43)

let test_exo_2_solution_reset_success =
  let (owner1, _owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { value = 42; admin = owner1 } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in
  let contr = Test.to_contract addr in
  let () = Test.set_source owner1 in
  let _r = Test.transfer_to_contract contr (Reset) 0tez in
  let current_storage = Test.get_storage addr in
  assert(current_storage.value = 0)

let test_exo_2_solution_reset_failure =
  let (owner1, owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { value = 42; admin = owner1 } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in
  let contr = Test.to_contract addr in
  let () = Test.set_source owner2 in
  let r = Test.transfer_to_contract contr (Reset) 0tez in
  let () = Assert.string_failure r MyContract.C.Errors.not_admin in
  let current_storage = Test.get_storage addr in
  assert(current_storage.value = initial_storage.value)


let test_exo_2_increment_many =
  let (owner1, owner2, _owner3, _, _, _, _) = Bootstrap.boot_accounts() in
  let initial_storage = { value = 42; admin = owner1 } in
  let {addr ; code = _ ; size = _} = Test.originate (contract_of MyContract.C) initial_storage 0tez in
  let contr = Test.to_contract addr in
  let () = Test.set_source owner2 in
  let r = Test.transfer_to_contract contr (Increment_many [1;2;3;4;5]) 0tez in
  let () = Assert.tx_success r in
  let current_storage = Test.get_storage addr in
  assert(current_storage.value = 57)

let test_call_increment =
  let (owner, _, _, _, _, _, _) = Bootstrap.boot_accounts() in
  
  (* Originate the first contract *)
  let myContract_storage = {value = 0; admin = owner} in
  let origination_result_myContract = Test.originate (contract_of MyContract.C) myContract_storage 0tez in
  let myContract_addr = origination_result_myContract.addr in
  
  (* Originate the second contract *)
  let callContract_storage = {value = 42; admin = owner} in
  let origination_result_callContract = Test.originate (contract_of CallContract.C) callContract_storage 0tez in
  let callContract_addr = origination_result_callContract.addr in

  (* Call the increment function of the first contract via the second contract *)
  let delta = 5 in
  let _ = Test.transfer callContract_addr (Call_increment (delta, Test.to_address(myContract_addr))) 0tez in
  
  (* Check the storage of the first contract *)
  let current_storage = Test.get_storage myContract_addr in
  assert (current_storage.value = 5)




