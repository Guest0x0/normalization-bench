
open Common.Syntax

let prelude = "
type value =
    | VLvl of int
    | VApp of value * value
    | VLam1 of (value -> value)
    | VLam2 of (value -> value -> value)
    | VLam3 of (value -> value -> value -> value)
    | VLam4 of (value -> value -> value -> value -> value)
    | VLam5 of (value -> value -> value -> value -> value -> value)
let rec quote level value =
    match value with
    | VLvl lvl   -> Idx(level - 1 - lvl)
    | VApp(f, a) -> App(quote level f, quote level a)
    | VLam1 f    -> Lam(quote (level + 1) @@ f (VLvl level))
    | VLam2 f    -> Lam(Lam(quote (level + 2) @@ f (VLvl level) (VLvl (level + 1))))
    | VLam3 f    -> Lam(Lam(Lam(quote (level + 3) @@ f (VLvl level) (VLvl (level + 1)) (VLvl (level + 2)))))
    | VLam4 f    -> Lam(Lam(Lam(Lam(quote (level + 4) @@ f (VLvl level) (VLvl (level + 1)) (VLvl (level + 2)) (VLvl (level + 3))))))
    | VLam5 f    -> Lam(Lam(Lam(Lam(Lam(quote (level + 5) @@ f (VLvl level) (VLvl (level + 1)) (VLvl (level + 2)) (VLvl (level + 3)) (VLvl (level + 4)))))))
let app1 vf va =
    match vf with
    | VLam1 f -> f va
    | VLam2 f -> VLam1(fun x -> f va x)
    | VLam3 f -> VLam2(fun x y -> f va x y)
    | VLam4 f -> VLam3(fun x y z -> f va x y z)
    | VLam5 f -> VLam4(fun x y z w -> f va x y z w)
    | _       -> VApp(vf, va)
[@@inline]
let app2 vf va vb =
    match vf with
    | VLam1 f -> app1 (f va) vb
    | VLam2 f -> f va vb
    | VLam3 f -> VLam1(fun x -> f va vb x)
    | VLam4 f -> VLam2(fun x y -> f va vb x y)
    | VLam5 f -> VLam3(fun x y z -> f va vb x y z)
    | _       -> VApp(VApp(vf, va), vb)
[@@inline]
let app3 vf va vb vc =
    match vf with
    | VLam1 f -> app2 (f va) vb vc
    | VLam2 f -> app1 (f va vb) vc
    | VLam3 f -> f va vb vc
    | VLam4 f -> VLam1(fun x -> f va vb vc x)
    | VLam5 f -> VLam2(fun x y -> f va vb vc x y)
    | _       -> VApp(VApp(VApp(vf, va), vb), vc)
[@@inline]
let app4 vf va vb vc vd =
    match vf with
    | VLam1 f -> app3 (f va) vb vc vd
    | VLam2 f -> app2 (f va vb) vc vd
    | VLam3 f -> app1 (f va vb vc) vd
    | VLam4 f -> f va vb vc vd
    | VLam5 f -> VLam1(fun x -> f va vb vc vd x)
    | _       -> VApp(VApp(VApp(VApp(vf, va), vb), vc), vd)
[@@inline]
let app5 vf va vb vc vd ve =
    match vf with
    | VLam1 f -> app4 (f va) vb vc vd ve
    | VLam2 f -> app3 (f va vb) vc vd ve
    | VLam3 f -> app2 (f va vb vc) vd ve
    | VLam4 f -> app1 (f va vb vc vd) ve
    | VLam5 f -> f va vb vc vd ve
    | _       -> VApp(VApp(VApp(VApp(VApp(vf, va), vb), vc), vd), ve)
[@@inline]
;;
"


type ctx =
    | CtxRoot
    | CtxApp of int * (out_channel -> unit) list
    | CtxLam of int * int

let dump_ctx out ctx content =
    match ctx with
    | CtxRoot ->
        content out
    | CtxLam(n, level) ->
        output_string out "(VLam";
        output_string out (string_of_int n);
        output_string out "(fun";
        for i = 0 to n - 1 do
            output_string out " x";
            output_string out (string_of_int (level + i))
        done;
        output_string out " -> ";
        content out;
        output_string out "))"
    | CtxApp(n, args) ->
        output_string out "(app";
        output_string out (string_of_int n);
        output_string out " ";
        content out;
        args |> List.iter begin fun arg ->
            output_string out " ";
            arg out
        end;
        output_string out ")"


let rec compile out level ctx tm =
    match tm, ctx with
    | Idx idx, _ ->
        dump_ctx out ctx 
            (fun out ->
                    output_string out "x";
                    output_string out (string_of_int (level - 1 - idx)))
    | Lam tm', CtxLam(n, l0) when n < 5 ->
        compile out (level + 1) (CtxLam(n + 1, l0)) tm'
    | Lam tm', CtxRoot ->
        compile out (level + 1) (CtxLam(1, level)) tm'
    | App(f, a), CtxApp(n, args) when n < 5 ->
        let arg out = compile out level CtxRoot a in
        compile out level (CtxApp(n + 1, arg :: args)) f
    | App(f, a), CtxRoot ->
        let arg out = compile out level CtxRoot a in
        compile out level (CtxApp(1, [arg])) f
    | _, _ ->
        dump_ctx out ctx (fun out -> compile out level CtxRoot tm)

let compile out tm =
    output_string out "let v = ";
    compile out 0 CtxRoot tm;
    output_string out ";;\nlet nf = quote 0 v;;"

let normalizer mode = Normalizer.compiled_normalizer ~mode
        (fun out -> output_string out prelude)
        compile
