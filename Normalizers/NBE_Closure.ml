
open Common.Syntax
open Common.Data

module ListEnv = struct
    type value =
        | VLvl of int
        | VLam of value list * term
        | VApp of value * value


    let rec eval env tm =
        match tm with
        | Idx idx   -> List.nth env idx
        | Lam tm'   -> VLam(env, tm')
        | App(f, a) -> apply_val (eval env f) (eval env a)

    and apply_val vf va =
        match vf with
        | VLam(env, body) -> eval (va :: env) body
        | _               -> VApp(vf, va)
    [@@inline]

    let rec quote level value =
        match value with
        | VLvl lvl        -> Idx(level - lvl - 1)
        | VLam(env, body) -> Lam(quote (level + 1) @@ eval (VLvl level :: env) body)
        | VApp(vf, va)    -> App(quote level vf, quote level va)
end

module TMapEnv = struct
    type value =
        | VLvl of int
        | VLam of value TMap.t * term
        | VApp of value * value


    let rec eval env tm =
        match tm with
        | Idx idx   -> TMap.get idx env
        | Lam tm'   -> VLam(env, tm')
        | App(f, a) -> apply_val (eval env f) (eval env a)

    and apply_val vf va =
        match vf with
        | VLam(env, body) -> eval (TMap.push va env) body
        | _               -> VApp(vf, va)
    [@@inline]

    let rec quote level value =
        match value with
        | VLvl lvl        -> Idx(level - lvl - 1)
        | VLam(env, body) -> Lam(quote (level + 1) @@ eval (TMap.push (VLvl level) env) body)
        | VApp(vf, va)    -> App(quote level vf, quote level va)
end


let normalizer_list = Normalizer.simple_normalizer
        (fun tm -> ListEnv.(quote 0 @@ eval [] tm))
let normalizer_tree = Normalizer.simple_normalizer
        (fun tm -> TMapEnv.(quote 0 @@ eval TMap.empty tm))
