
type term =
    | Idx of int
    | Lam of term
    | App of term * term


let rec term_size tm =
    match tm with
    | Idx _     -> 0
    | Lam tm'   -> 1 + term_size tm'
    | App(f, a) -> 1 + term_size f + term_size a



let rec pp_term ctx fmt tm =
    let open Format in
    match ctx, tm with
    | _   , Idx idx   -> fprintf fmt "%d" idx
    | `Arg, _         -> fprintf fmt "(%a)" (pp_term `Any) tm
    | `Fun, App(f, a) -> fprintf fmt "%a@ %a"
            (pp_term `Fun) f (pp_term `Arg) a
    | _   , App(f, a) -> fprintf fmt "@[<hov2>%a@ %a@]"
            (pp_term `Fun) f (pp_term `Arg) a
    | `Lam, Lam body  -> fprintf fmt "lam.@ %a" (pp_term `Lam) body
    | `Any, Lam body  -> fprintf fmt "@[<hov2>lam.@ %a@]" (pp_term `Lam) body
    | _   , Lam _     -> fprintf fmt "(%a)" (pp_term `Any) tm

let pp_term = pp_term `Any






let serialize tm =
    let open Printf in
    let buf = Buffer.create 20 in
    let rec loop tm =
        match tm with
        | Idx idx   -> bprintf buf "%08x" idx
        | Lam tm'   -> Buffer.add_char buf 'l'; loop tm'
        | App(f, a) -> Buffer.add_char buf '@'; loop f; loop a
    in
    loop tm; buf

let deserialize src =
    let digit_to_int c =
        match c with
        | '0'..'9' -> Char.code c - Char.code '0'
        | 'a'..'f' -> Char.code c - Char.code 'a' + 10
        | _        -> failwith("Syntax.deserialize: invalid char " ^ String.make 1 c)
    in
    let rec loop () =
        match input_char src with
        | 'l' -> Lam(loop ())
        | '@'  ->
            let tm1 = loop () in
            let tm2 = loop () in
            App(tm1, tm2)
        | c0 ->
            let d0 = digit_to_int c0 in
            let d1 = digit_to_int (input_char src) in
            let d2 = digit_to_int (input_char src) in
            let d3 = digit_to_int (input_char src) in
            let d4 = digit_to_int (input_char src) in
            let d5 = digit_to_int (input_char src) in
            let d6 = digit_to_int (input_char src) in
            let d7 = digit_to_int (input_char src) in
            Idx(d0 lsl 28 + d1 lsr 24 + d2 lsr 20 + d3 lsr 16
                + d4 lsr 12 + d5 lsr 8 + d6 lsr 4 + d7)
    in
    loop ()
