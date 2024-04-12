// Je veux prendre les liste L1 et L2 et les transformer en une liste de paires, dans laquelle on applique f

let L1 = ["a", "b", "c"]
let L2 = [1, 2, 3, 4]

//comme ça : Resultat = [f("a";1);f("b";2);f("C";3);] 

let rec zipwith ()
match L1, L2 with

// On peut le faire avec une fonction récursive

