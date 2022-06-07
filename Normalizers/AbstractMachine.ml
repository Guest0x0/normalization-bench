
open Common.Syntax

module ListStack = struct
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

    let normalize tm = run (0, VClo([], tm), SEmpty)
end


module VecStack = struct
    type value =
        | VLvl of int
        | VClo of (value list * term)
        | VNF  of term

    type stack_frame =
        | SClo of (value list * term)
        | SLam
        | SNF  of term
        | SHalt

    module Vec = Common.Data.Vector

    let garbage = SHalt

    let rec run (level, value, stack) =
        match value, Vec.last stack with
        | VClo(env, Idx idx  ), _ ->
            run (level, List.nth env idx, stack)
        | VClo(env, App(f, a)), _ ->
            Vec.push (SClo(env, a)) stack;
            run (level, VClo(env, f), stack)
        | VClo(env, Lam body), SClo clo ->
            Vec.pop stack;
            run (level, VClo(VClo clo :: env, body), stack)
        | VClo(env, Lam body), _ ->
            Vec.push SLam stack;
            run (level + 1, VClo(VLvl level :: env, body), stack)
        | VLvl lvl, _ ->
            run (level, VNF(Idx(level - lvl - 1)), stack)
        | VNF f, SClo clo ->
            Vec.pop stack;
            Vec.push (SNF f) stack;
            run (level, VClo clo, stack)
        | VNF a, SNF f -> Vec.pop stack; run (level, VNF(App(f, a)), stack)
        | VNF t, SLam  -> Vec.pop stack; run (level, VNF(Lam t), stack)
        | VNF t, SHalt -> t

    let normalize init_size tm =
        let stack = Vec.create ~init_size ~garbage:SHalt () in
        Vec.push SHalt stack;
        run (0, VClo([], tm), stack)
end


let normalizer_list = Normalizer.Norm(Fun.id, ListStack.normalize)
let normalizer_vec size = Normalizer.Norm(Fun.id, VecStack.normalize size)
