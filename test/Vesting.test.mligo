#import "ligo-utils/utils.mligo" "Utils"
#import "../src/Vesting.mligo" "VestingFA2"
#import "ligo-mocks/FA2_mocks.mligo" "FA2_Mocks"

let admin_address = ("tz1AdminAddress1234" : address)
let beneficiary_address = ("tz1BeneficiaryAddress5678" : address)
let fa2_token_address = ("KT1FA2TokenAddressABCD" : address)
let token_id = 0n
let frozen_duration = 86400 // 1 jour en secondes
let total_amount_to_vest = 1000n
let duration = 31536000 // 1 an en secondes
let start_time = Utils.current_timestamp() // Ou une date fixe pour vos tests

let initial_storage = VestingFA2.initial_storage admin_address frozen_duration start_time fa2_token_address token_id

// Configure le contrat avec les détails de vesting pour le bénéficiaire
let setup_vesting_contract () : VestingFA2.storage =
  let vesting_detail = {
    VestingFA2.beneficiary = beneficiary_address;
    total_amount = total_amount_to_vest;
    claimed_amount = 0n;
    start_vesting_time = Utils.add_seconds start_time frozen_duration;
    duration = duration;
  } in
  let (_, storage_after_addition) = VestingFA2.add_vesting vesting_detail initial_storage in
  storage_after_addition

// Teste l'ajout des détails de vesting
let test_add_vesting () : unit =
  let new_storage = setup_vesting_contract () in
  assert (Big_map.mem beneficiary_address new_storage.extension.vestings, "Vesting detail should be added")

// Teste la revendication réussie des fonds après la période de gel
let test_claim_success () : unit =
  let storage_with_vesting = setup_vesting_contract () in
  let current_time = Utils.add_seconds storage_with_vesting.extension.start_time (frozen_duration + duration + 1) in
  Utils.set_current_timestamp current_time
  let (_, storage_after_claim) = VestingFA2.claim ((), beneficiary_address) storage_with_vesting in
  let detail = Big_map.find beneficiary_address storage_after_claim.extension.vestings in
  assert (match detail with Some(d) -> d.claimed_amount = total_amount_to_vest | None -> false, "All vested tokens should be claimed")

// Teste la fonctionnalité de terminaison du contrat
let test_kill_contract () : unit =
  let storage_with_vesting = setup_vesting_contract () in
  let (_, storage_after_kill) = VestingFA2.kill ((), admin_address) storage_with_vesting in

let () =
  test_add_vesting ();
  test_claim_success ();
  test_kill_contract ();
