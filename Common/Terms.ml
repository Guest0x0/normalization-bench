
open Syntax

let apply f args = List.fold_left (fun f a -> App(f, a)) f args

let id = Lam(Idx 0)

let rec church_aux = function
    | 0 -> Idx 0
    | n -> App(Idx 1, church_aux (n - 1))

let church n = Lam(Lam(church_aux n))

let church_zero = Lam(Lam(Idx 0))
let church_succ =
    Lam( (* 2 = n *)
        Lam( (* 1 = succ *)
            Lam( (* 0 = zero *)
                apply (Idx 1)
                    [apply (Idx 2) [Idx 1; Idx 0]]
            )
        )
    )

let church_add =
    Lam( (* m = 3 *)
        Lam( (* n = 2 *)
            Lam( (* succ = 1 *)
                Lam( (* zero = 0 *)
                    apply (Idx 3)
                        [Idx 1; apply (Idx 2) [Idx 1; Idx 0]]
                )
            )
        )
    )

let church_mul =
    Lam( (* m = 3 *)
        Lam( (* n = 2 *)
            Lam( (* succ = 1 *)
                Lam( (* zero = 0 *)
                    apply (Idx 3)
                        [apply (Idx 2) [Idx 1]; Idx 0]
                )
            )
        )
    )



let idx n =
    Lam( (* case_idx = 2 *)
        Lam( (* case_lam = 1 *)
            Lam( (* case_app = 0 *)
                apply (Idx 2) [n]
            )
        )
    )

let lam t =
    Lam( (* case_idx = 2 *)
        Lam( (* case_lam = 1 *)
            Lam( (* case_app = 0 *)
                apply (Idx 1) [apply t [Idx 2; Idx 1; Idx 0]]
            )
        )
    )

let app f a =
    Lam( (* case_idx = 2 *)
        Lam( (* case_lam = 1 *)
            Lam( (* case_app = 0 *)
                apply (Idx 0)
                    [ apply f [Idx 2; Idx 1; Idx 0]
                    ; apply a [Idx 2; Idx 1; Idx 0] ]
            )
        )
    )

let church_lam_size =
    Lam( (* tm = 0 *)
        apply (Idx 0)
            [ Lam(church 1)
            ; church_succ
            ; Lam(Lam(apply church_succ
                                [apply church_add [Idx 0; Idx 1]])) ]
    )

let rec encode_term tm =
    match tm with
    | Idx n     -> idx (church n)
    | Lam tm'   -> lam (encode_term tm')
    | App(f, a) -> app (encode_term f) (encode_term a)
