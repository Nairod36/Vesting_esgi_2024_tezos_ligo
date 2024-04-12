let rec fact n =
  if n <= 0n then 1n
  else n * fact (n - 1n)


let test_fact =
  let res = fact(5n) in
  let () = Test.log(res) in
  let () = assert(res=120n) in
  ()
