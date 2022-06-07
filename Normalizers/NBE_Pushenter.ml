
open Common.Syntax




module ListStack = struct
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


    let normalize tm = quote 0 (eval ([], []) tm)
end

module VecStack = struct
    module Vec = Common.Data.Vector

    type value =
        | VLvl of int
        | VLam of value Vec.t * term
        | VApp of value * value Vec.t

    let new_vec () = Vec.create ~init_size:10 ~garbage:(VLvl 0) ()

    let rec eval (env, args) tm =
        match tm, args.Vec.len with
        | Idx idx, 0 -> Vec.get idx env
        | Idx idx, _ -> apply_val (Vec.get idx env) args
        | Lam tm', 0 -> VLam(Vec.copy env, tm')
        | Lam tm', _ ->
            Vec.push (Vec.last args) env;
            Vec.pop args;
            let result = eval (env, args) tm' in
            Vec.pop env;
            result
        | App(f, a), _ ->
            Vec.push (eval (env, new_vec ()) a) args;
            eval (env, args) f

    and apply_val vf args =
        match vf with
        | VLam(env, tm) ->
            Vec.push (Vec.last args) env;
            Vec.pop args; 
            let result = eval (env, args) tm in
            Vec.pop env;
            result
        | _ -> VApp(vf, args)


    let rec quote level value =
        match value with
        | VLvl lvl      -> Idx(level - lvl - 1)
        | VLam(env, tm) ->
            Vec.push (VLvl level) env;
            let result = eval (env, new_vec ()) tm in
            Vec.pop env;
            Lam(quote (level + 1) result)
        | VApp(f, args) ->
            let rec loop f i =
                if i >= args.Vec.len
                then f
                else loop (App(f, quote level (Vec.get i args))) (i + 1)
            in
            loop (quote level f) 0

    let normalize init_env_size tm =
        let env = Vec.create ~init_size:init_env_size ~garbage:(VLvl 0) () in
        quote 0 (eval (env, new_vec ()) tm)
end

let normalizer_list = Normalizer.Norm(Fun.id, ListStack.normalize)
let normalizer_vec size  = Normalizer.Norm(Fun.id, VecStack.normalize size)
