
open Syntax
open Common

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





(*
module AMap = ArrMap(struct
        type t = value
        let garbage = VLvl(-1)
    end)

let garbage = VLvl (-1)

let rec eval_arr env tm =
    match tm with
    | Idx idx -> AMap.get idx env
    | Lam tm' ->
        let env' = AMap.copy env in
        VLam(fun vx -> AMap.push vx env'; eval_arr env' tm')
    | App(f, a) ->
        apply_val (eval_arr env f) (eval_arr env a)
*)



let load () =
    register_normalizer "NBE.HOAS.list" @@ Norm {
        of_term   = eval_list [];
        normalize = Fun.id;
        readback  = quote 0
    };
    register_normalizer "NBE.HOAS.tree" @@ Norm {
        of_term   = eval_map TMap.empty;
        normalize = Fun.id;
        readback  = quote 0
    }

(*
let normalizer_arr =
    Norm { name      = "NBE.HOAS.array"
         ; of_term   = (fun tm -> eval_arr (AMap.empty ()) tm)
         ; normalize = Fun.id
         ; readback  = quote 0 }
*)
