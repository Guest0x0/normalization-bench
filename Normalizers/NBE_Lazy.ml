
open Common.Syntax

type value =
    | VLvl of int
    | VLam of (value Lazy.t -> value Lazy.t)
    | VApp of value Lazy.t * value Lazy.t

let rec quote level value =
    match Lazy.force value with
    | VLvl lvl   -> Idx(level - lvl - 1)
    | VLam f     -> Lam(quote (level + 1) @@ f @@ lazy(VLvl level))
    | VApp(f, a) -> App(quote level f, quote level a)

let apply_val vf va =
    match Lazy.force vf with
    | VLam f -> Lazy.force (f va)
    | _      -> VApp(vf, va)

let rec eval env tm =
    match tm with
    | Idx idx   -> List.nth env idx
    | Lam tm'   -> Lazy.from_val @@ VLam(fun vx -> eval (vx :: env) tm')
    | App(f, a) -> lazy(apply_val (eval env f) (eval env a))


let normalizer = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval [] tm))
