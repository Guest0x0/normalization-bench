
open Syntax

let rec church_aux = function
    | 0 -> Idx 0
    | n -> App(Idx 1, church_aux (n - 1))

let church n = Lam(Lam(church_aux n))


let church_zero = Lam(Lam(Idx 0))
let church_succ =
    Lam( (* 2 = n *)
        Lam( (* 1 = succ *)
            Lam( (* 0 = zero *)
                App(
                    Idx 1, App(App(Idx 2, Idx 1), Idx 0)
                )
            )
        )
    )

let church_add =
    Lam( (* m = 3 *)
        Lam( (* n = 2 *)
            Lam( (* succ = 1 *)
                Lam( (* zero = 0 *)
                    App(App(Idx 3, Idx 1),
                        App(App(Idx 2, Idx 1), Idx 0))
                )
            )
        )
    )

let church_mul =
    Lam( (* m = 3 *)
        Lam( (* n = 2 *)
            Lam( (* succ = 1 *)
                Lam( (* zero = 0 *)
                    App(App(Idx 3, App(Idx 2, Idx 1)), Idx 0)
                )
            )
        )
    )

let id = Lam(Idx 0)
