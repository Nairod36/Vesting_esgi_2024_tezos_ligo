#import "../.ligo/source/i/ligo__s__fa__1.2.0__ffffffff/lib/main.mligo" "FA2"
#import "../src/Vesting.mligo" "VestingFA2"
#import "./helper/bootstrap.mligo" "Bootstrap"
#import "./helper/assert.mligo" "Assert"

// Import du module Errors
module Errors = VestingFA2.Errors

let test_startVesting_success =
  let initial_storage = {
    beneficiaries = Big_map.literal [];
    admin = ("admin_address" : address);
    fa2_token_address = ("fa2_token_address" : address);
    token_id = 0n;
    vesting_config = {
      start_time = 0;
      vesting_duration = 10000;
      freeze_duration = 5000;
    };
    is_started = false;
  } in
  let { addr ; code = _ ; size = _ } = Test.originate (contract_of VestingFA2) initial_storage 0mutez in
  let _ = Test.startVesting () addr in
  assert (Test.get_storage addr).extension.is_started

let test_updateBeneficiary_success =
  let initial_storage = {
    beneficiaries = Big_map.literal [];
    admin = ("admin_address" : address);
    fa2_token_address = ("fa2_token_address" : address);
    token_id = 0n;
    vesting_config = {
      start_time = 0;
      vesting_duration = 10000;
      freeze_duration = 5000;
    };
    is_started = false;
  } in
  let beneficiary = ("beneficiary_address" : address), {
    promised_amount = 100n;
    claimed_amount = 0n;
  } in
  let { addr ; code = _ ; size = _ } = Test.originate (contract_of VestingFA2) initial_storage 0mutez in
  let _ = Test.updateBeneficiary beneficiary addr in
  let storage = Test.get_storage addr in
  match Big_map.find_opt "beneficiary_address" storage.extension.beneficiaries with
  | None -> assert false
  | Some detail ->
    assert (detail.promised_amount = 100n)

let test_claim_success =
  let initial_storage = {
    beneficiaries = Big_map.literal [("beneficiary_address", {
      promised_amount = 100n;
      claimed_amount = 0n;
    })];
    admin = ("admin_address" : address);
    fa2_token_address = ("fa2_token_address" : address);
    token_id = 0n;
    vesting_config = {
      start_time = 0;
      vesting_duration = 10000;
      freeze_duration = 5000;
    };
    is_started = true;
  } in
  let { addr ; code = _ ; size = _ } = Test.originate (contract_of VestingFA2) initial_storage 0mutez in
  let _ = Test.claim () addr in
  let storage = Test.get_storage addr in
  match Big_map.find_opt "beneficiary_address" storage.extension.beneficiaries with
  | None -> assert false
  | Some detail ->
    assert (detail.claimed_amount > 0n)

let test_kill_success =
  let initial_storage = {
    beneficiaries = Big_map.literal [("beneficiary_address", {
      promised_amount = 100n;
      claimed_amount = 0n;
    })];
    admin = ("admin_address" : address);
    fa2_token_address = ("fa2_token_address" : address);
    token_id = 0n;
    vesting_config = {
      start_time = 0;
      vesting_duration = 10000;
      freeze_duration = 5000;
    };
    is_started = false;
  } in
  let { addr ; code = _ ; size = _ } = Test.originate (contract_of VestingFA2) initial_storage 0mutez in
  let _ = Test.kill "beneficiary_address" addr in
  let storage = Test.get_storage addr in
  match Big_map.find_opt "beneficiary_address" storage.extension.beneficiaries with
  | Some _ -> assert false // Le bénéficiaire devrait être supprimé
  | None -> ()
