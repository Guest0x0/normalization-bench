
open Syntax

module Make(Env : sig
        type 'a t

        val add  : int -> 'a -> 'a t -> 'a t
        val find : int -> 'a t -> 'a
    end) =
struct
    type value =
        | VLvl of int
        | VLam of (value Env.t * int * term)
        | VApp of value * value


    let rec eval (env, level) tm =
        match tm with
        | Idx idx ->
            begin match Env.find idx env with
            | value               -> value
            | exception Not_found -> VLvl(level - idx - 1)
            end
        | Lam tm' ->
            VLam(env, level, tm')
        | App(tf, ta) ->
            apply_val (eval (env, level) tf) (eval (env, level) ta)

    and apply_val vf va =
        match vf with
        | VLam clo -> apply_clo clo va
        | _        -> VApp(vf, va)

    and apply_clo (env, level, body) va =
        eval (Env.add level va env, level + 1) body

    let rec quote level value =
        match value with
        | VLvl lvl     -> Idx(level - lvl - 1)
        | VLam clo     -> Lam(quote (level + 1) (apply_clo clo (VLvl level)))
        | VApp(vf, va) -> App(quote level vf, quote level va)
end


module ListEnv = Make(struct
        type 'a t = 'a list
        let add _ v env = v :: env
        let find idx env = List.nth env idx
    end)

let normalizer_list =
    Norm { name      = "NBE/closure/list"
         ; of_term   = ListEnv.eval ([], 0)
         ; normalize = Fun.id
         ; readback  = ListEnv.quote 0 }


module IMap = Map.Make(Int)
module MapEnv = Make(IMap)

let normalizer_map =
    Norm { name      = "NBE/closure/map"
         ; of_term   = MapEnv.eval (IMap.empty, 0)
         ; normalize = Fun.id
         ; readback  = MapEnv.quote 0 }
