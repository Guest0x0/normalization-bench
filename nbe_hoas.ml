
open Syntax

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



let rec eval_list (env, level) tm =
    match tm with
    | Idx idx ->
        begin match List.nth env idx with
        | value               -> value
        | exception Not_found -> VLvl(level - idx - 1)
        end
    | Lam tm' ->
        VLam(fun vx -> eval_list (vx :: env, level + 1) tm')
    | App(tf, ta) ->
        apply_val (eval_list (env, level) tf) (eval_list (env, level) ta)


module IMap = Map.Make(Int)

let rec eval_map (env, level) tm =
    match tm with
    | Idx idx ->
        begin match IMap.find idx env with
        | value               -> value
        | exception Not_found -> VLvl(level - idx - 1)
        end
    | Lam tm' ->
        VLam(fun vx -> eval_map (IMap.add level vx env, level + 1) tm')
    | App(tf, ta) ->
        apply_val (eval_map (env, level) tf) (eval_map (env, level) ta)



let normalizer_list =
    Norm { name      = "NBE.HOAS.list"
         ; of_term   = eval_list ([], 0)
         ; normalize = Fun.id
         ; readback  = quote 0 }

let normalizer_map =
    Norm { name      = "NBE.HOAS.map"
         ; of_term   = eval_map (IMap.empty, 0)
         ; normalize = Fun.id
         ; readback  = quote 0 }
