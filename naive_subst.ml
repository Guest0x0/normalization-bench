
open Syntax

let rec shift (base, dist) tm =
    match tm with
    | Idx idx ->
        if idx < base
        then Idx idx
        else Idx(idx + dist)
    | Lam tm' ->
        Lam(shift (base + 1, dist + 1) tm')
    | App(tf, ta) ->
        App(shift (base, dist) tf, shift (base, dist) ta)

let rec subst (level, target) tm =
    match tm with
    | Idx idx ->
        if idx = level
        then shift (0, level) target
        else Idx idx
    | Lam tm' ->
        Lam(subst (level + 1, target) tm')
    | App(tf, ta) ->
        App(subst (level, target) tf, subst (level, target) ta)


let rec normalize tm =
    match tm with
    | Idx idx -> Idx idx
    | Lam tm' -> Lam(normalize tm')
    | App(tf, ta) ->
        match normalize tf with
        | Lam tm' -> normalize (subst (0, normalize ta) tm')
        | tf'     -> App(tf', normalize ta)


let normalizer =
    Norm { name      = "naive_subst"
         ; of_term   = Fun.id
         ; normalize = normalize
         ; readback  = Fun.id }
