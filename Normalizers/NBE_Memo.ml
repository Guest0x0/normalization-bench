
open Common.Syntax

type value =
    { rep : value_rep
    ; mutable syn : (int * term) option }

and value_rep =
    | VLvl of int
    | VLam of (value list * term)
    | VApp of value * value


let mkv rep = { rep; syn = None } [@@inline]

let rec eval env tm =
    match tm with
    | Idx idx   -> List.nth env idx
    | Lam tm'   -> mkv @@ VLam(env, tm')
    | App(f, a) ->
        match eval env f with
        | {rep=VLam clo; _} -> apply_closure clo (eval env a)
        | vf                -> mkv @@ VApp(vf, eval env a)

and apply_closure (env, tm') va = eval (va :: env) tm' [@@inline]


let rec quote level v =
    match v.syn with
    | Some(level', tm) when level' = level ->
        tm
    | _ ->
        let tm = quote_rep level v.rep in
        v.syn <- Some(level, tm);
        tm

and quote_rep level rep =
    match rep with
    | VLvl lvl   -> Idx(level - 1 - lvl)
    | VLam clo   -> Lam(quote (level + 1) @@ apply_closure clo @@ mkv (VLvl level))
    | VApp(f, a) -> App(quote level f, quote level a)
[@@inline]


let normalizer = Normalizer.Norm(Fun.id, fun tm -> quote 0 (eval [] tm))
