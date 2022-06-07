
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


let rec quote level value =
    match value with
    | VLvl lvl     -> Idx(level - lvl - 1)
    | VLam f       -> Lam(quote (level + 1) (f (VLvl level)))
    | VApp(tf, ta) -> App(quote level tf, quote level ta)



let rec eval_list env tm =
    match tm with
    | Idx idx -> List.nth env idx
    | Lam tm' ->
        VLam(fun vx -> eval_list (vx :: env) tm')
    | App(tf, ta) ->
        apply_val (eval_list env tf) (eval_list env ta)


let rec eval_map env tm =
    match tm with
    | Idx idx -> TMap.get idx env
    | Lam tm' ->
        VLam(fun vx -> eval_map (TMap.push vx env) tm')
    | App(tf, ta) ->
        apply_val (eval_map env tf) (eval_map env ta)



let normalizer_list = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval_list [] tm))
let normalizer_tree = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval_map TMap.empty tm))
