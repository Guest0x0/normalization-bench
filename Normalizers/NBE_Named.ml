
open Common.Syntax

type named_term =
    | NVar of int
    | NLam of int * named_term
    | NApp of named_term * named_term

let seed = ref (-1)
let fresh_var () = incr seed; !seed

let rec get_idx var vars =
    match vars with
    | var' :: _ when var' = var -> 0
    | _    :: vars'             -> get_idx var vars' + 1
    | _                         -> failwith "NBE_Named.get_idx"

let rec of_term vars tm =
    match tm with
    | Idx idx -> NVar(List.nth vars idx)
    | Lam tm' ->
        let v = fresh_var () in
        NLam(v, of_term (v :: vars) tm')
    | App(f, a) ->
        NApp(of_term vars f, of_term vars a)

let rec to_term vars ntm =
    match ntm with
    | NVar var        -> Idx(get_idx var vars)
    | NLam(var, body) -> Lam(to_term (var :: vars) body)
    | NApp(func, arg) -> App(to_term vars func, to_term vars arg)


let of_term = of_term []
let to_term = to_term []


module ListEnv = struct
    type value =
        | VVar of int
        | VLam of (int * value) list * int * named_term
        | VApp of value * value

    let rec eval env ntm =
        match ntm with
        | NVar var        -> List.assoc var env
        | NLam(var, body) -> VLam(env, var, body)
        | NApp(func, arg) ->
            match eval env func with
            | VLam(env', var, body) ->
                eval ((var, eval env arg) :: env') body
            | vfunc ->
                VApp(vfunc, eval env arg)

    let rec quote v =
        match v with
        | VVar var -> NVar var
        | VLam(env, var, body) ->
            let var' = fresh_var () in
            NLam(var', quote @@ eval ((var, VVar var') :: env) body)
        | VApp(func, arg) ->
            NApp(quote func, quote arg)

    let normalize tm = quote (eval [] tm)
end

module TreeEnv = struct
    module Env = Map.Make(Int)
    type value =
        | VVar of int
        | VLam of value Env.t * int * named_term
        | VApp of value * value

    let rec eval env ntm =
        match ntm with
        | NVar var        -> Env.find var env
        | NLam(var, body) -> VLam(env, var, body)
        | NApp(func, arg) ->
            match eval env func with
            | VLam(env', var, body) ->
                eval (Env.add var (eval env arg) env') body
            | vfunc ->
                VApp(vfunc, eval env arg)

    let rec quote v =
        match v with
        | VVar var -> NVar var
        | VLam(env, var, body) ->
            let var' = fresh_var () in
            NLam(var', quote @@ eval (Env.add var (VVar var') env) body)
        | VApp(func, arg) ->
            NApp(quote func, quote arg)

    let normalize tm = quote (eval Env.empty tm)
end

module ADTEnv = struct
    type value =
        | VVar of int
        | VLam of env * int * named_term
        | VApp of value * value

    and env =
        | Nil
        | Cons of int * value * env


    let rec lookup k env =
        match env with
        | Cons(k', v, _) when k' = k -> v
        | Cons(_, _, env')           -> lookup k env'
        | Nil                        -> failwith "NBE_Named.ADTEnv.lookup"

    let rec eval env ntm =
        match ntm with
        | NVar var        -> lookup var env
        | NLam(var, body) -> VLam(env, var, body)
        | NApp(func, arg) ->
            match eval env func with
            | VLam(env', var, body) ->
                eval (Cons(var, eval env arg, env')) body
            | vfunc ->
                VApp(vfunc, eval env arg)

    let rec quote v =
        match v with
        | VVar var -> NVar var
        | VLam(env, var, body) ->
            let var' = fresh_var () in
            NLam(var', quote @@ eval (Cons(var, VVar var', env)) body)
        | VApp(func, arg) ->
            NApp(quote func, quote arg)

    let normalize tm = quote (eval Nil tm)
end

let normalizer_list = Normalizer.normalizer_with_alt_term_rep
        ~of_term ~normalize:ListEnv.normalize ~to_term

let normalizer_tree = Normalizer.normalizer_with_alt_term_rep
        ~of_term ~normalize:TreeEnv.normalize ~to_term

let normalizer_adt = Normalizer.normalizer_with_alt_term_rep
        ~of_term ~normalize:ADTEnv.normalize ~to_term
