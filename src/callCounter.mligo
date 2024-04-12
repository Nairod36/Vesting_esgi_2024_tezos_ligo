module C = struct
    type storage = {
        value: int;
        admin: address
    }

type result = operation list * storage

let get_entrypoint(addr:address) = 
    match Tezos.get_entrypoint_opt "%increment" addr with
        | Some contract -> contract
        | None -> failwith "Error"

[@entry] let call_increment (delta,addr : int*address) (store : storage) : result = 
    let add : int contract = get_entrypoint(addr) in
    let op = Tezos.transaction delta 0mutez add in
    [op], store

end


