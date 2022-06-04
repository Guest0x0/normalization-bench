
open Syntax

type value =
    | VLvl of int
    | VLam of value list * term
    | VApp of value * value list




let rec eval (env, args) tm =
    match tm, args with
    | Idx idx, [] -> List.nth env idx
    | Idx idx, _  -> apply_val (List.nth env idx) args
    | Lam tm', [] -> VLam(env, tm')
    | Lam tm', arg :: args' ->
        eval (arg :: env, args') tm'
    | App(f, a), _ ->
        eval (env, (eval (env, []) a) :: args) f

and apply_val vf args =
    match vf, args with
    | VLam(env, tm), arg :: args' -> eval (arg :: env, args') tm
    | _                           -> VApp(vf, args)


let rec quote level value =
    match value with
    | VLvl lvl      -> Idx(level - lvl - 1)
    | VLam(env, tm) ->
        Lam(quote (level + 1) (eval (VLvl level :: env, []) tm))
    | VApp(f, args) ->
        List.fold_left (fun f a -> App(f, quote level a))
            (quote level f) args


let load () =
    register_normalizer "NBE.pushenter" @@ Norm {
        of_term   = eval ([], []);
        normalize = Fun.id;
        readback  = quote 0
    }
