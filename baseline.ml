
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


exception NonTerminating
let normalize size tm =
    let max_steps = size * 10 in
    let steps = ref 0 in
    let rec loop tm =
        if !steps < max_steps then 
            raise NonTerminating;
        match tm with
        | Idx idx -> Idx idx
        | Lam tm' -> Lam(loop tm')
        | App(tf, ta) ->
            match loop tf with
            | Lam tm' ->
                incr steps;
                subst (0, loop ta) tm'
            | tf'     -> App(tf', loop ta)
    in
    loop tm


let terminating size tm =
    try ignore (normalize size tm); false with
      NonTerminating -> true
