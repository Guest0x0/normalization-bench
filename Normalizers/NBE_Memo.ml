
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


module V4 = struct
    type value =
        | VLvl of int
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
        | VLvl lvl -> Idx(level - 1 - lvl)
        | VLam r ->
            if level = r.lvl
            then r.syn
            else
                let syn = Lam(quote (level + 1) @@ eval (VLvl level :: r.env) r.body) in
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


module Alpha = struct
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
        | _                         -> failwith "NBE_Memo.Alpha.get_idx"

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


    type value =
        | VVar of
              { mutable syn : named_term
              ; var         : int }
        | VLam of
              { mutable syn : named_term
              ; env         : (int * value) list
              ; var         : int
              ; body        : named_term }
        | VApp of
              { mutable syn : named_term
              ; func        : value
              ; arg         : value }

    let garbage = NVar (-1)
    let vvar var          = VVar { syn = garbage; var }
    let vlam env var body = VLam { syn = garbage; env; var; body } [@@inline]
    let vapp func arg     = VApp { syn = garbage; func; arg } [@@inline]

    let rec eval env ntm =
        match ntm with
        | NVar var        -> List.assoc var env
        | NLam(var, body) -> vlam env var body
        | NApp(func, arg) ->
            match eval env func with
            | VLam { env = env'; var; body } ->
                eval ((var, eval env arg) :: env') body
            | vfunc ->
                vapp vfunc (eval env arg)

    let rec quote v =
        match v with
        | VVar r ->
            if r.syn == garbage
            then
                let syn = NVar r.var in
                ( r.syn <- syn; syn )
            else
                r.syn
        | VLam r ->
            if r.syn == garbage
            then
                let var = fresh_var () in
                let syn = NLam(var, quote @@ eval ((r.var, vvar var) :: r.env) r.body) in
                ( r.syn <- syn; syn )
            else
                r.syn
        | VApp r ->
            if r.syn == garbage
            then
                let syn = NApp(quote r.func, quote r.arg) in
                ( r.syn <- syn; syn )
            else
                r.syn

    let of_term = of_term []
    let to_term = to_term []
    let normalize tm = quote (eval [] tm)
end


let normalizer_v1 = Normalizer.simple_normalizer V1.normalize
let normalizer_v2 = Normalizer.simple_normalizer V2.normalize
let normalizer_v3 = Normalizer.simple_normalizer V3.normalize
let normalizer_v4 = Normalizer.simple_normalizer V4.normalize
let normalizer_alpha =
    let open Alpha in
    Normalizer.normalizer_with_alt_term_rep ~of_term ~normalize ~to_term
