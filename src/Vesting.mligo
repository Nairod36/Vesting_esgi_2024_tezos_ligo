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

  type extension = {
    beneficiaries: (address, beneficiary_detail) big_map; // Beneficiary details
    admin: address;            // Admin of the contract
    fa2_token_address: address; // Address of the FA2 token contract
    token_id: nat;             // Token ID of the FA2 token
    vesting_config: vesting_config; // Vesting configuration details
    is_started: bool;          // Flag to check if vesting has started
  }

  type storage = extension VestingFA2.storage

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

  let get_entrypoint(addr, name:address*string) = 
      if name = "transfer" then
          match Tezos.get_entrypoint_opt "%transfer" addr with
              | Some contract -> contract
              | None -> failwith "transfer not found"
      else
          failwith "Unsupported entrypoint"


  // Initial setup for contract. Called once by the admin to start the vesting period
  [@entry] let startVesting () (s : storage) : ret =
    let sender = Tezos.get_sender() in
    if sender <> s.extension.admin then
      failwith Errors.not_admin
    else if s.extension.is_started then
      failwith Errors.contract_already_started
    else
      let now = Tezos.get_now() in
      let new_start_time = now + s.extension.vesting_config.freeze_duration in
      let updated_vesting_config = {s.extension.vesting_config with start_time = new_start_time} in
      let updated_extension = {s.extension with vesting_config = updated_vesting_config; is_started = true} in
      ([], {s with extension = updated_extension})


  // Allows the admin to update beneficiary details before the vesting has started
  [@entry] let updateBeneficiary (beneficiary: address * beneficiary_detail) (s : storage) : ret =
    let sender = Tezos.get_sender() in
    if s.extension.is_started then
      failwith Errors.contract_already_started
    else if sender <> s.extension.admin then
      failwith Errors.not_admin
    else
      let (beneficiary_address, detail) = beneficiary in
      let updated_beneficiaries = Big_map.update beneficiary_address (Some(detail)) s.extension.beneficiaries in
      let updated_extension = {s.extension with beneficiaries = updated_beneficiaries} in
      let updated_storage = {s with extension = updated_extension} in
      ([], updated_storage)



  [@entry] let transfer (param: VestingFA2.TZIP12.transfer) (s: storage) : ret =
    VestingFA2.transfer param s

  // Allows beneficiaries to claim their available tokens based on the vesting schedule
  [@entry] let claim () (s : storage) : ret =
    let sender = Tezos.get_sender() in
    match Big_map.find_opt sender s.extension.beneficiaries with
    | None -> failwith Errors.not_a_beneficiary
    | Some(detail) ->
      let now = Tezos.get_now() in
      let start_time = s.extension.vesting_config.start_time in
      if now < start_time then
        failwith Errors.probatory_period_not_completed
      else
        let end_time = start_time + s.extension.vesting_config.vesting_duration in
        let available_tokens =
          if now >= end_time then
            detail.promised_amount
          else
            let elapsed_time = now - start_time in
            let total_vesting_time = s.extension.vesting_config.vesting_duration in
            let progress = elapsed_time * detail.promised_amount / total_vesting_time in
            abs(progress)
        in
        let claimable_amount = available_tokens - detail.claimed_amount in
        if claimable_amount = 0 then
          failwith Errors.no_tokens_to_claim
        else
          let updated_beneficiary_details = {promised_amount = detail.promised_amount; claimed_amount = available_tokens} in
          let updated_beneficiaries = Big_map.update sender (Some(updated_beneficiary_details)) s.extension.beneficiaries in
          let updated_extension = {s.extension with beneficiaries = updated_beneficiaries} in
          let claimable_amount = abs(claimable_amount) in
          let transfer_requests = ([{
            from_ = Tezos.get_self_address(); 
            txs = ([{
              to_ = sender; 
              token_id = s.extension.token_id; 
              amount = claimable_amount
            }] : FA2.SingleAssetExtendable.TZIP12.atomic_trans list)
          }] : FA2.SingleAssetExtendable.TZIP12.transfer) in
          let transfer_contract = get_entrypoint(s.extension.fa2_token_address, "transfer") in
          let transfer_op = Tezos.transaction transfer_requests 0mutez transfer_contract in
          ([transfer_op], {s with extension = updated_extension})

[@entry]
let kill () (storage : storage) : ret =
  let now = Tezos.get_now () in
  let end_time = storage.extension.vesting_config.start_time + (86400 * storage.extension.vesting_config.freeze_duration) in
  if now < end_time then
    failwith Errors.vesting_period_not_completed
  else
    match Big_map.find_opt storage.extension.admin storage.extension.beneficiaries with
    | None -> failwith Errors.not_a_beneficiary
    | Some(details) ->
      let total_vesting_time = end_time - storage.extension.vesting_config.start_time in
      let elapsed_time = now - storage.extension.vesting_config.start_time in
      let vested_tokens =
        if now >= end_time then
          details.promised_amount
        else
          let progress = (details.promised_amount * elapsed_time) / total_vesting_time in
          abs progress in  
      let to_claim =  (vested_tokens - details.claimed_amount) in  
      if  to_claim > 0 then
        let transfer_param = {
          from_ = storage.extension.admin;
          txs = [{ to_ = storage.extension.admin; token_id = storage.extension.token_id; amount = to_claim}]
        } in
        let transfer_entrypoint = get_entrypoint(storage.extension.fa2_token_address, "transfer") in
        let transfer_op = Tezos.transaction transfer_param 0mutez transfer_entrypoint in
        let updated_details = { details with claimed_amount = vested_tokens } in
        let updated_beneficiaries = Big_map.update storage.extension.admin (Some updated_details) storage.extension.beneficiaries in
        ([transfer_op], { storage with extension = { storage.extension with beneficiaries = updated_beneficiaries; is_started = false } })
      else
        let cleaned_beneficiaries = Big_map.update storage.extension.admin None storage.extension.beneficiaries in
        ([], { storage with extension = { storage.extension with beneficiaries = cleaned_beneficiaries; is_started = false } })