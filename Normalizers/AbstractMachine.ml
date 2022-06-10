
open Common.Syntax


module ListStack = struct
    type value =
        | VLvl of int
        | VClo of (value list * term)
        | VNF  of term

    type stack_frame =
        | UseArg of value
        | QuoteLam
        | QuoteFun of term

    let rec run (level, value, stack) =
        match value, stack with
        | VClo(env, Idx idx), _ ->
            run (level, List.nth env idx, stack)
        | VClo(env, App(f, a)), _ ->
            run (level, VClo(env, f), UseArg(VClo(env, a)) :: stack)
        | VClo(env, Lam tm'), UseArg v :: stack' ->
            run (level, VClo(v :: env, tm'), stack')
        | VClo(env, Lam tm'), _ ->
            run (level + 1, VClo(VLvl level :: env, tm'), QuoteLam :: stack)

        | VLvl lvl, _ ->
            run (level, VNF(Idx(level - 1 - lvl)), stack)
        | VNF f, UseArg a :: stack' ->
            run (level, a, QuoteFun f :: stack')
        | VNF t, QuoteLam :: stack' ->
            run (level - 1, VNF(Lam t), stack')
        | VNF a, QuoteFun f :: stack' ->
            run (level, VNF(App(f, a)), stack')
        | VNF t, [] ->
            t

    let normalize tm = run (0, VClo([], tm), [])
end


module ADTStack = struct
    type value =
        | VLvl of int
        | VClo of (value list * term)
        | VNF  of term

    type stack =
        | Empty
        | UseArg of (value list * term) * stack
        | QuoteFun of term * stack
        | QuoteLam of stack

    let rec run (level, value, stack) =
        match value, stack with
        | VClo(env, Idx idx  ), _ ->
            run (level, List.nth env idx, stack)
        | VClo(env, App(f, a)), _ ->
            run (level, VClo(env, f), UseArg((env, a), stack))
        | VClo(env, Lam body), UseArg(clo, stack') ->
            run (level, VClo(VClo clo :: env, body), stack')
        | VClo(env, Lam body), _ ->
            run (level + 1, VClo(VLvl level :: env, body), QuoteLam stack)
        | VLvl lvl, _ ->
            run (level, VNF(Idx(level - lvl - 1)), stack)
        | VNF f, UseArg(clo, stack') -> run (level, VClo clo, QuoteFun(f, stack'))
        | VNF a, QuoteFun(f, stack') -> run (level, VNF(App(f, a)), stack')
        | VNF t, QuoteLam stack'     -> run (level - 1, VNF(Lam t), stack')
        | VNF t, Empty               -> t

    let normalize tm = run (0, VClo([], tm), Empty)
end


module ArrayStack = struct
    type value =
        | VLvl of int
        | VClo of (value list * term)
        | VNF  of term

    type stack_frame =
        | UseArg of (value list * term)
        | QuoteLam
        | QuoteFun of term
        | Halt

    module Stack = Common.Data.ArrayStack

    let garbage = Halt

    let rec run (level, value, stack) =
        match value, Stack.last stack with
        | VClo(env, Idx idx  ), _ ->
            run (level, List.nth env idx, stack)
        | VClo(env, App(f, a)), _ ->
            Stack.push (UseArg(env, a)) stack;
            run (level, VClo(env, f), stack)
        | VClo(env, Lam body), UseArg clo ->
            Stack.pop stack;
            run (level, VClo(VClo clo :: env, body), stack)
        | VClo(env, Lam body), _ ->
            Stack.push QuoteLam stack;
            run (level + 1, VClo(VLvl level :: env, body), stack)
        | VLvl lvl, _ ->
            run (level, VNF(Idx(level - lvl - 1)), stack)
        | VNF f, UseArg clo ->
            Stack.pop stack;
            Stack.push (QuoteFun f) stack;
            run (level, VClo clo, stack)
        | VNF a, QuoteFun f -> Stack.pop stack; run (level, VNF(App(f, a)), stack)
        | VNF t, QuoteLam  -> Stack.pop stack; run (level - 1, VNF(Lam t), stack)
        | VNF t, Halt -> t

    let preprocess init_size tm =
        let stack = Stack.create ~init_size ~garbage:Halt () in
        Stack.push Halt stack;
        (tm,  stack)

    let normalize (tm, stack) =
        run (0, VClo([], tm), stack)
end


module CBV = struct
    type value =
        | VLvl of int
        | VClo of (value list * term)
        | VNF  of term

    type stack =
        | Empty
        | CallFn of value * stack
        | UseArg of value * stack
        | QuoteLam of stack
        | QuoteFun of term * stack

    let rec run (level, value, stack) =
        match value, stack with
        | VClo(env, Idx idx), _ ->
            run (level, List.nth env idx, stack)
        | VClo(env, App(f, a)), _ ->
            run (level, VClo(env, a), CallFn(VClo(env, f), stack))
        | VClo(env, Lam tm'), UseArg(v, stack') ->
            run (level, VClo(v :: env, tm'), stack')
        | value, CallFn(func, stack') ->
            run (level, func, UseArg(value, stack'))
        | VClo(env, Lam tm'), _ ->
            run (level + 1, VClo(VLvl level :: env, tm'), QuoteLam stack)

        | VLvl lvl, _ ->
            run (level, VNF(Idx(level - 1 - lvl)), stack)
        | VNF f, UseArg(a, stack') ->
            run (level, a, QuoteFun(f, stack'))
        | VNF t, QuoteLam stack' ->
            run (level - 1, VNF(Lam t), stack')
        | VNF a, QuoteFun(f, stack') ->
            run (level, VNF(App(f, a)), stack')
        | VNF t, Empty ->
            t

    let normalize tm = run (0, VClo([], tm), Empty)
end


let normalizer_list = Normalizer.Norm(Fun.id, ListStack.normalize)
let normalizer_adt  = Normalizer.Norm(Fun.id, ADTStack.normalize)
let normalizer_arr  = Normalizer.Norm(
        ArrayStack.preprocess 1000000,
        ArrayStack.normalize
    )
let normalizer_cbv = Normalizer.Norm(Fun.id, CBV.normalize)
