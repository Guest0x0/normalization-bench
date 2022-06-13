
open Common.Syntax

module V1 = struct
    type value =
        { rep : value_rep
        ; mutable syn : (int * term) option }

    and value_rep =
        | VLvl of int
        | VLam of (value list * term)
        | VApp of value * value


    let mkv rep = { rep; syn = None } [@@inline]

    let rec eval env tm =
        match tm with
        | Idx idx   -> List.nth env idx
        | Lam tm'   -> mkv @@ VLam(env, tm')
        | App(f, a) ->
            match eval env f with
            | {rep=VLam clo; _} -> apply_closure clo (eval env a)
            | vf                -> mkv @@ VApp(vf, eval env a)

    and apply_closure (env, tm') va = eval (va :: env) tm' [@@inline]


    let rec quote level v =
        match v.syn with
        | Some(level', tm) when level' = level ->
            tm
        | _ ->
            let tm = quote_rep level v.rep in
            v.syn <- Some(level, tm);
            tm

    and quote_rep level rep =
        match rep with
        | VLvl lvl   -> Idx(level - 1 - lvl)
        | VLam clo   -> Lam(quote (level + 1) @@ apply_closure clo @@ mkv (VLvl level))
        | VApp(f, a) -> App(quote level f, quote level a)
    [@@inline]

    let normalize tm = quote 0 (eval [] tm)
end


module V2 = struct
    type value =
        { rep         : value_rep
        ; mutable lvl : int
        ; mutable syn : term }

    and value_rep =
        | VLvl of int
        | VLam of (value list * term)
        | VApp of value * value


    let mkv rep = { rep; lvl = -1; syn = Idx 0 } [@@inline]

    let rec eval env tm =
        match tm with
        | Idx idx   -> List.nth env idx
        | Lam tm'   -> mkv @@ VLam(env, tm')
        | App(f, a) ->
            match eval env f with
            | {rep=VLam clo; _} -> apply_closure clo (eval env a)
            | vf                -> mkv @@ VApp(vf, eval env a)

    and apply_closure (env, tm') va = eval (va :: env) tm' [@@inline]


    let rec quote level v =
        if level = v.lvl
        then v.syn
        else
            let syn = quote_rep level v.rep in
            v.lvl <- level; v.syn <- syn;
            syn

    and quote_rep level rep =
        match rep with
        | VLvl lvl   -> Idx(level - 1 - lvl)
        | VLam clo   -> Lam(quote (level + 1) @@ apply_closure clo @@ mkv (VLvl level))
        | VApp(f, a) -> App(quote level f, quote level a)
    [@@inline]

    let normalize tm = quote 0 (eval [] tm)
end


module V3 = struct
    type value =
        | VLvl of
              { mutable lvl : int
              ; mutable syn : term
              ; value       : int }
        | VLam of
              { mutable lvl : int
              ; mutable syn : term
              ; env         : value list
              ; body        : term }
        | VApp of
              { mutable lvl : int
              ; mutable syn : term
              ; func        : value
              ; arg         : value }


    let vlvl value    = VLvl { lvl = -1; syn = Idx 0; value }     [@@inline]
    let vlam env body = VLam { lvl = -1; syn = Idx 0; env; body } [@@inline]
    let vapp func arg = VApp { lvl = -1; syn = Idx 0; func; arg } [@@inline]

    let rec eval env tm =
        match tm with
        | Idx idx   -> List.nth env idx
        | Lam tm'   -> vlam env tm'
        | App(f, a) ->
            match eval env f with
            | VLam{env=env'; body; _} -> eval (eval env a :: env') body
            | vf                      -> vapp vf (eval env a)


    let rec quote level v =
        match v with
        | VLvl r ->
            if level = r.lvl
            then r.syn
            else
                let syn = Idx(level - 1 - r.value) in
                r.lvl <- level; r.syn <- syn;
                syn
        | VLam r ->
            if level = r.lvl
            then r.syn
            else
                let syn = Lam(quote (level + 1) @@ eval (vlvl level :: r.env) r.body) in
                r.lvl <- level; r.syn <- syn;
                syn
        | VApp r ->
            if level = r.lvl
            then r.syn
            else
                let syn = App(quote level r.func, quote level r.arg) in
                r.lvl <- level; r.syn <- syn;
                syn

    let normalize tm = quote 0 (eval [] tm)
end


let normalizer_v1 = Normalizer.simple_normalizer V1.normalize
let normalizer_v2 = Normalizer.simple_normalizer V2.normalize
let normalizer_v3 = Normalizer.simple_normalizer V3.normalize
