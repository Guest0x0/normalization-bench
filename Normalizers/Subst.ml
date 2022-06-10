
open Common.Syntax

let rec shift (base, dist) tm =
    match tm with
    | Idx idx ->
        if idx < base
        then Idx idx
        else Idx(idx + dist)
    | Lam tm' ->
        Lam(shift (base + 1, dist) tm')
    | App(tf, ta) ->
        App(shift (base, dist) tf, shift (base, dist) ta)

let rec subst (level, target) tm =
    match tm with
    | Idx idx ->
        begin match Int.compare idx level with
        | -1 -> Idx idx
        | 0  -> shift (0, level) target
        | _  -> Idx(idx - 1)
        end
    | Lam tm' ->
        Lam(subst (level + 1, target) tm')
    | App(tf, ta) ->
        App(subst (level, target) tf, subst (level, target) ta)


let rec normalize_naive tm =
    match tm with
    | Idx idx -> Idx idx
    | Lam tm' -> Lam(normalize_naive tm')
    | App(tf, ta) ->
        match normalize_naive tf with
        | Lam tm' -> normalize_naive (subst (0, normalize_naive ta) tm')
        | tf'     -> App(tf', normalize_naive ta)

let rec normalize_head tm =
    match tm with
    | Idx _ | Lam _ ->
        tm
    | App(f, a) ->
        match normalize_head f with
        | Lam tm' -> normalize_head (subst (0, normalize_head a) tm')
        | f'      -> App(f', normalize a)

and normalize tm =
    match tm with
    | Idx idx   -> Idx idx
    | Lam tm'   -> Lam(normalize tm')
    | App(f, a) ->
        match normalize_head f with
        | Idx idx -> App(Idx idx, normalize a)
        | Lam tm' -> normalize (subst (0, normalize_head a) tm')
        | f'      -> App(f', normalize a)

let normalizer_naive = Normalizer.simple_normalizer normalize_naive
let normalizer_whead = Normalizer.simple_normalizer normalize
