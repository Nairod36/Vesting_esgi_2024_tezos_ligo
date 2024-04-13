#import "../.ligo/source/i/ligo__s__fa__1.2.0__ffffffff/lib/main.mligo" "FA2"

module VestingFA2 = FA2.SingleAssetExtendable

type vesting_config = {
  start_time: timestamp;
  vesting_duration: int; // Duration of the vesting period in seconds
  freeze_duration: int;  // Duration of the freeze period in seconds
}

type beneficiary_detail = {
  promised_amount: nat;  // Total tokens promised to the beneficiary
  claimed_amount: nat;   // Amount already claimed by the beneficiary
}

type storage = {
  beneficiaries: (address, beneficiary_detail) big_map; // Beneficiary details
  admin: address;            // Admin of the contract
  fa2_token_address: address; // Address of the FA2 token contract
  token_id: nat;             // Token ID of the FA2 token
  vesting_config: vesting_config; // Vesting configuration details
  is_started: bool;          // Flag to check if vesting has started
}

module Errors = struct
  let not_admin = "Not admin"
  let contract_already_started = "Contract already started"
  let sender_not_found = "No sender address provided"
  let not_a_beneficiary = "Not a beneficiary"
  let probatory_period_not_completed = "Probatory period not completed"
  let vesting_period_not_completed = "Vesting period not completed"
  let no_tokens_to_claim = "No tokens to claim"
end

type ret = operation list * storage

let add_seconds (timestamp: timestamp) (duration: int) : timestamp =
  timestamp + duration

// Initial setup for contract. Called once by the admin to start the vesting period
[@entry]
let start (s : storage) : ret =
  let sender_option = Tezos.get_sender() in
match sender_option with
| None -> failwith Errors.sender_not_found
| Some(sender_address) ->
  if sender_address = s.admin then
    if s.is_started then
      failwith Errors.contract_already_started
    else
      let now = Tezos.get_now() in
      let new_start_time = add_seconds(now, s.vesting_config.freeze_duration) in
      let updated_storage = {
        s with
        vesting_config = {s.vesting_config with start_time = new_start_time},
        is_started = true
      } in
      ([], updated_storage)
  else
    failwith Errors.not_admin






// Allows the admin to update beneficiary details before the vesting has started
[@entry]
let updateBeneficiary (beneficiary: address * beneficiary_detail) (s : storage) : ret =
  if s.is_started then
    failwith Errors.contract_already_started
  else
    match Tezos.get_sender() with
    | Some(admin_address) ->
      if admin_address = s.admin then
        let (beneficiary_address, detail) = beneficiary in
        let updated_beneficiaries = Big_map.update beneficiary_address (Some(detail)) s.beneficiaries in
        ([], {s with beneficiaries = updated_beneficiaries})
      else
        failwith Errors.not_admin
    | None ->
      failwith Errors.sender_not_found

[@entry]
let transfer (param: VestingFA2.TZIP12.transfer) (s: storage) : ret =
  VestingFA2.transfer param s

// Allows beneficiaries to claim their available tokens based on the vesting schedule
[@entry]
let claim (s : storage) : ret =
  match Tezos.get_sender() with
  | None -> failwith Errors.sender_not_found
  | Some(addr) -> (
    match Big_map.find_opt addr s.beneficiaries with
    | None -> failwith Errors.not_a_beneficiary
    | Some(detail) -> (
      let now = Tezos.get_now() in
      let freeze_end_time = add_seconds(s.vesting_config.start_time, s.vesting_config.freeze_duration) in
      if now < freeze_end_time then
        failwith Errors.probatory_period_not_completed
      else
        let vesting_end_time = add_seconds(s.vesting_config.start_time, s.vesting_config.vesting_duration) in
        let claimable_amount =
          if now > vesting_end_time then
            detail.promised_amount - detail.claimed_amount  // All remaining tokens are claimable
          else
            let time_since_freeze_end = now - freeze_end_time in
            let vested_amount_during_period = detail.promised_amount * time_since_freeze_end / s.vesting_config.vesting_duration in
            vested_amount_during_period - detail.claimed_amount in
        if claimable_amount <= 0n then
          failwith Errors.no_tokens_to_claim
        else (
          let transfer_ops = [{from_=s.admin; txs=[{to_=addr; token_id=s.token_id; amount=claimable_amount}]}] in
          let transfer = VestingFA2.get_transfer_contract s.fa2_token_address in
          let op = Tezos.transaction transfer_ops 0mutez transfer in
          let updated_detail = {detail with claimed_amount = detail.claimed_amount + claimable_amount} in
          let updated_beneficiaries = Big_map.update addr (Some(updated_detail)) s.beneficiaries in
          ([op], {s with beneficiaries = updated_beneficiaries})
        )
      )
    )

// Allows the admin to retrieve unclaimed funds after vesting period is over and clean up the contract storage
[@entry]
let kill (s : storage) : ret =
  match Tezos.get_sender() with
  | None -> failwith Errors.sender_not_found
  | Some(admin_address) ->
    if admin_address <> s.admin then
      failwith Errors.not_admin
    else
      let vesting_end_time = add_seconds(s.vesting_config.start_time, s.vesting_config.vesting_duration) in
      let now = Tezos.get_now() in
      if now < vesting_end_time then
        failwith Errors.vesting_period_not_completed
      else (
        let operations = Big_map.fold (fun acc beneficiary detail ->
          let unclaimed_amount = detail.promised_amount - detail.claimed_amount in
          if unclaimed_amount > 0n then (
            let transfer_request = VestingFA2.get_transfer_contract s.fa2_token_address in
            let op = Tezos.transaction {from_=s.admin; txs=[{to_=beneficiary; token_id=s.token_id; amount=unclaimed_amount}]} 0mutez transfer_request in
            op :: acc
          ) else
            acc
        ) [] s.beneficiaries in
        (operations, {s with beneficiaries = Big_map.empty; is_started = false})
      )


