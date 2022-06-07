
open Common.Syntax
open Common.Data

module ListEnv = struct
    type value =
        | VLvl of int
        | VLam of (value list * term)
        | VApp of value * value


    let rec eval env tm =
        match tm with
        | Idx idx   -> List.nth env idx
        | Lam tm'   -> VLam(env, tm')
        | App(f, a) -> apply_val (eval env f) (eval env a)

    and apply_val vf va =
        match vf with
        | VLam clo -> apply_clo clo va
        | _        -> VApp(vf, va)

    and apply_clo (env, body) va = eval (va :: env) body

    let rec quote level value =
        match value with
        | VLvl lvl     -> Idx(level - lvl - 1)
        | VLam clo     -> Lam(quote (level + 1) (apply_clo clo (VLvl level)))
        | VApp(vf, va) -> App(quote level vf, quote level va)
end

module TMapEnv = struct
    type value =
        | VLvl of int
        | VLam of (value TMap.t * term)
        | VApp of value * value


    let rec eval env tm =
        match tm with
        | Idx idx   -> TMap.get idx env
        | Lam tm'   -> VLam(env, tm')
        | App(f, a) -> apply_val (eval env f) (eval env a)

    and apply_val vf va =
        match vf with
        | VLam clo -> apply_clo clo va
        | _        -> VApp(vf, va)

    and apply_clo (env, body) va = eval (TMap.push va env) body

    let rec quote level value =
        match value with
        | VLvl lvl     -> Idx(level - lvl - 1)
        | VLam clo     -> Lam(quote (level + 1) (apply_clo clo (VLvl level)))
        | VApp(vf, va) -> App(quote level vf, quote level va)
end


let normalizer_list = Normalizer.Norm(Fun.id, fun tm -> ListEnv.(quote 0 @@ eval [] tm))
let normalizer_tree = Normalizer.Norm(Fun.id, fun tm -> TMapEnv.(quote 0 @@ eval TMap.empty tm))
