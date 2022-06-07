
open Common.Syntax

type value =
    | VLvl of int
    | VClo of (value list * term)
    | VNF  of term

type stack =
    | SEmpty
    | SClo of (value list * term) * stack
    | SNF  of term * stack
    | SLam of stack

let rec run (level, value, stack) =
    match value, stack with
    | VClo(env, Idx idx  ), _ ->
        run (level, List.nth env idx, stack)
    | VClo(env, App(f, a)), _ ->
        run (level, VClo(env, f), SClo((env, a), stack))
    | VClo(env, Lam body), SClo(clo, stack') ->
        run (level, VClo(VClo clo :: env, body), stack')
    | VClo(env, Lam body), _ ->
        run (level + 1, VClo(VLvl level :: env, body), SLam stack)
    | VLvl lvl, _ ->
        run (level, VNF(Idx(level - lvl - 1)), stack)
    | VNF f, SClo(clo, stack') -> run (level, VClo clo, SNF(f, stack'))
    | VNF a, SNF(f, stack')    -> run (level, VNF(App(f, a)), stack')
    | VNF t, SLam stack'       -> run (level, VNF(Lam t), stack')
    | VNF t, SEmpty            -> t


let normalizer = Normalizer.Norm(Fun.id, fun tm -> run (0, VClo([], tm), SEmpty))
