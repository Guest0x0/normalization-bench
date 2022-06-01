
type term =
    | Idx of int
    | Lam of term
    | App of term * term



let rec church_aux = function
    | 0 -> Idx 1
    | n -> App(Idx 0, church_aux (n - 1))

let church n = Lam(Lam(church_aux n))

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


type normalizer =
    Norm :
      { name      : string
      ; of_term   : term -> 'rep
      ; normalize : 'rep -> 'rep
      ; readback  : 'rep -> term }
      -> normalizer
