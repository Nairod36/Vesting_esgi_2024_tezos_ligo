module C = struct

    type register = (address,nat)big_map

    type storage = {
        ledger : register;
        total_supply : nat;
        admin : address;
    }

    type result = operation list * storage

  module Errors = struct
    let not_admin = "Not admin"
    let not_found = "Balance not found"
    let no_money = "Not enough money in bank"
    let no_more_supply = "Not enough money in supply"
  end

    let updateValue(m,key,value:register*address*nat):register = Big_map.update key (Some value) m

    [@entry] let mint (amount,addr: nat*address) (store : storage) : result =
        let _ = assert_with_error (Tezos.get_sender() = store.admin) Errors.not_admin in
        let store = { store with ledger = updateValue(store.ledger,addr,amount); total_supply = store.total_supply + amount } in
        [],store

    [@entry] let transfer (addr,amount:address*nat) (store : storage) : result =
        // let () = assert_with_error ((Tezos.get_sender()
        let balance1 = match Big_map.find_opt (Tezos.get_sender()) store.ledger with
            |Some l -> l
            |None -> failwith Errors.not_found
        in
        let _ = assert_with_error (balance1 >= amount) Errors.no_money in
        let new_amount1 = abs(balance1 - amount) in
        let balance2 = match Big_map.find_opt addr store.ledger with
            |Some l -> l
            |None -> 0n
        in
        let new_amount2 = balance2 + amount in
        [],{store with ledger = updateValue(updateValue(store.ledger,(Tezos.get_sender()),new_amount1),addr,new_amount2)}

    [@entry] let burn (amount:nat) (store: storage) : result =
        let _ = assert_with_error (Tezos.get_sender() = store.admin) Errors.not_admin in
        let _ = assert_with_error (store.total_supply >= amount) Errors.no_more_supply in
        [],{store with total_supply = abs(store.total_supply - amount)}
end