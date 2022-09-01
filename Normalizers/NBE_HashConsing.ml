
open Common.Syntax

module CacheIndex = struct

    let indicies = Array.init 10000 (fun idx -> Idx idx)

    let rec of_term = function
        | Idx idx   -> indicies.(idx)
        | Lam tm'   -> Lam(of_term tm')
        | App(f, a) -> App(of_term f, of_term a)

    let to_term tm = tm



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
        | VLvl lvl        -> indicies.(level - lvl - 1)
        | VLam(env, body) -> Lam(quote (level + 1) @@ eval (VLvl level :: env) body)
        | VApp(vf, va)    -> App(quote level vf, quote level va)
end



module CacheLevelIndex = struct

    let indicies = Array.init 10000 (fun idx -> Idx idx)

    let rec of_term = function
        | Idx idx   -> indicies.(idx)
        | Lam tm'   -> Lam(of_term tm')
        | App(f, a) -> App(of_term f, of_term a)

    let to_term tm = tm


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


    let levels = Array.init 10000 (fun lvl -> VLvl lvl)

    let rec quote level value =
        match value with
        | VLvl lvl        -> indicies.(level - lvl - 1)
        | VLam(env, body) -> Lam(quote (level + 1) @@ eval (levels.(level) :: env) body)
        | VApp(vf, va)    -> App(quote level vf, quote level va)
end


type hc_term =
    { shape : term_shape
    ; hash  : int }

and term_shape =
    | HC_Idx of int
    | HC_Lam of hc_term
    | HC_App of hc_term * hc_term


let shape_equal s1 s2 =
    match s1, s2 with
    | HC_Idx idx1   , HC_Idx idx2    -> idx1 = idx2
    | HC_Lam tm1    , HC_Lam tm2     -> tm1 == tm2
    | HC_App(f1, a1), HC_App(f2, a2) -> f1 == f2 && a1 == a2
    | _                        -> false

let hash_shape shape =
    match shape with
    | HC_Idx idx   -> idx
    | HC_Lam tm'   -> 19 * tm'.hash + 1
    | HC_App(f, a) -> 19 * (19 * f.hash + a.hash) + 2


module HT = Hashtbl.Make(struct
        type t = hc_term
        let equal htm1 htm2 = shape_equal htm1.shape htm2.shape
        let hash htm = htm.hash
    end)

let tbl = HT.create 10000


let hashcons shape =
    let tm = { shape; hash = hash_shape shape } in
    match HT.find tbl tm with
    | tm                  -> tm
    | exception Not_found -> HT.add tbl tm tm; tm


let idx idx = hashcons (HC_Idx idx)
let lam tm' = hashcons (HC_Lam tm')
let app f a = hashcons (HC_App(f, a)) 



let rec of_term = function
    | Idx i     -> idx i
    | Lam tm'   -> lam (of_term tm')
    | App(f, a) -> app (of_term f) (of_term a)

let rec to_term tm =
    match tm.shape with
    | HC_Idx idx   -> Idx idx
    | HC_Lam tm'   -> Lam(to_term tm')
    | HC_App(f, a) -> App(to_term f, to_term a)



module HashCons = struct
    type value =
        | VLvl of int
        | VLam of value list * hc_term
        | VApp of value * value

    let rec eval env tm =
        match tm.shape with
        | HC_Idx idx   -> List.nth env idx
        | HC_Lam tm'   -> VLam(env, tm')
        | HC_App(f, a) -> apply_val (eval env f) (eval env a)

    and apply_val vf va =
        match vf with
        | VLam(env, body) -> eval (va :: env) body
        | _               -> VApp(vf, va)
    [@@inline]


    let rec quote level value =
        match value with
        | VLvl lvl        -> idx (level - lvl - 1)
        | VLam(env, body) -> lam (quote (level + 1) @@ eval (VLvl level :: env) body)
        | VApp(vf, va)    -> app (quote level vf) (quote level va)
end


let normalizer_cache_level_index = Normalizer.normalizer_with_alt_term_rep
        ~of_term:CacheLevelIndex.of_term ~to_term:CacheLevelIndex.to_term
        ~normalize:(fun tm -> CacheLevelIndex.(quote 0 @@ eval [] tm))

let normalizer_cache_level_index_o = Normalizer.simple_normalizer
        (fun tm -> CacheLevelIndex.(quote 0 @@ eval [] tm))


let normalizer_cache_index = Normalizer.normalizer_with_alt_term_rep
        ~of_term:CacheIndex.of_term ~to_term:CacheIndex.to_term
        ~normalize:(fun tm -> CacheIndex.(quote 0 @@ eval [] tm))

let normalizer_cache_index_o = Normalizer.simple_normalizer
        (fun tm -> CacheIndex.(quote 0 @@ eval [] tm))


let normalizer_hashcons = Normalizer.normalizer_with_alt_term_rep
        ~of_term:of_term ~to_term:to_term
        ~normalize:(fun htm -> HashCons.(quote 0 @@ eval [] htm))
