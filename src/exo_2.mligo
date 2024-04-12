// This is mycontract.mligo
module C = struct
  type storage = {
    value : int; 
    admin: address
  }
  type result = operation list * storage

  module Errors = struct
    let not_admin = "Not admin"
  end

  [@entry] let increment (delta : int) (store : storage) : result = [],{ store with value = store.value + delta }
  [@entry] let decrement (delta : int) (store : storage) : result = [],{ store with value = store.value - delta }
  [@entry] let reset () (store : storage) : result = 
    let () = assert_with_error ((Tezos.get_sender()) = store.admin) Errors.not_admin in
    [], { store with value = 0 }


  [@entry] let increment_many (l : int list) (store : storage) : result = 
    let f (acc, elt: int * int) : int = acc + elt in
    [],{ store with value = List.fold f l store.value }

end