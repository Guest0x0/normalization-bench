
type term =
    | Idx of int
    | Lam of term
    | App of term * term



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



let rec pp_term ctx fmt tm =
    let open Format in
    match ctx, tm with
    | _   , Idx idx   -> fprintf fmt "%d" idx
    | `Arg, _         -> fprintf fmt "(%a)" (pp_term `Any) tm
    | `Fun, App(f, a) -> fprintf fmt "%a@ %a"
            (pp_term `Fun) f (pp_term `Arg) a
    | _   , App(f, a) -> fprintf fmt "@[<hov2>%a@ %a@]"
            (pp_term `Fun) f (pp_term `Arg) a
    | `Lam, Lam body  -> fprintf fmt "lam.@ %a" (pp_term `Lam) body
    | `Any, Lam body  -> fprintf fmt "@[<hov2>lam.@ %a@]" (pp_term `Lam) body
    | _   , Lam _     -> fprintf fmt "(%a)" (pp_term `Any) tm

let pp_term = pp_term `Any




type normalizer =
    Norm :
      { of_term   : term -> 'rep
      ; normalize : 'rep -> 'rep
      ; readback  : 'rep -> term }
      -> normalizer

let normalizers : (string * normalizer) list ref = ref []

let register_normalizer name normalizer =
    normalizers := (name, normalizer) :: !normalizers
