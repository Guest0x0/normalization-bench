
open Common.Syntax

let prelude = "
type value =
    | VLvl of int
    | VLam of (value -> value)
    | VApp of value * value
;;
let rec quote level value =
    match value with
    | VLvl lvl   -> Idx(level - 1 - lvl)
    | VLam f     -> Lam(quote (level + 1) @@ f (VLvl level))
    | VApp(f, a) -> App(quote level f, quote level a)
;;
let app vf va =
    match vf with
    | VLam f -> f va
    | _      -> VApp(vf, va)
[@@inline]
;;
"

let rec compile out level tm =
    match tm with
    | Idx idx ->
        output_string out "x";
        output_string out (string_of_int (level - 1 - idx))
    | Lam tm' ->
        output_string out "(VLam(fun x";
        output_string out (string_of_int level);
        output_string out " -> ";
        compile out (level + 1) tm';
        output_string out "))"
    | App(f, a) ->
        output_string out "(app ";
        compile out level f;
        output_string out " ";
        compile out level a;
        output_string out ")"

let compile out tm =
    output_string out "let v = ";
    compile out 0 tm;
    output_string out ";;\nlet nf = quote 0 v;;"

let normalizer mode = Normalizer.compiled_normalizer ~mode
        (fun out -> output_string out prelude)
        compile

let (byte_compile  , byte_normalize  ) = normalizer "byte"
let (native_compile, native_normalize) = normalizer "native"
let (o2_compile    , o2_normalize    ) = normalizer "O2"
