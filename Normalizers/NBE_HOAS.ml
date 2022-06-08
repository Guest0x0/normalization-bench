
open Common.Syntax
open Common.Data

type value =
    | VLvl of int
    | VLam of (value -> value)
    | VApp of value * value

let apply_val vf va =
    match vf with
    | VLam f -> f va
    | _      -> VApp(vf, va)
[@@inline]


let rec quote level value =
    match value with
    | VLvl lvl   -> Idx(level - lvl - 1)
    | VLam f     -> Lam(quote (level + 1) (f (VLvl level)))
    | VApp(f, a) -> App(quote level f, quote level a)



let rec eval_list env tm =
    match tm with
    | Idx idx   -> List.nth env idx
    | Lam tm'   -> VLam(fun vx -> eval_list (vx :: env) tm')
    | App(f, a) -> apply_val (eval_list env f) (eval_list env a)


let rec eval_map env tm =
    match tm with
    | Idx idx   -> TMap.get idx env
    | Lam tm'   -> VLam(fun vx -> eval_map (TMap.push vx env) tm')
    | App(f, a) -> apply_val (eval_map env f) (eval_map env a)


let rec eval_skew env tm =
    match tm with
    | Idx idx   -> SkewList.get idx env
    | Lam tm'   -> VLam(fun vx -> eval_skew (SkewList.push vx env) tm')
    | App(f, a) -> apply_val (eval_skew env f) (eval_skew env a)


let normalizer_list = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval_list [] tm))
let normalizer_tree = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval_map TMap.empty tm))
let normalizer_skew = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval_skew SkewList.empty tm))
