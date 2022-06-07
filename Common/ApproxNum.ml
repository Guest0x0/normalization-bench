
(* (mantissa, exponent) *)
type t = float * int

let of_int i = Float.frexp (Float.of_int i)

let (<+>) (m1, e1) (m2, e2) =
    let (m1, m2, e) =
        match Int.compare e1 e2 with
        | 0  -> (m1, m2, e1)
        | -1 -> (Float.ldexp m1 (e1 - e2), m2, e2)
        | _  -> (m1, Float.ldexp m2 (e2 - e1), e1)
    in
    let m' = m1 +. m2 in
    if m' >= 1. || m' <= -1.
    then (m' *. 0.5, e + 1)
    else if -0.5 < m' && m' < 0.5
    then (m' *. 2., e - 1)
    else (m', e)

let (<->) (m1, e1) (m2, e2) =
    let (m1, m2, e) =
        match Int.compare e1 e2 with
        | 0  -> (m1, m2, e1)
        | -1 -> (Float.ldexp m1 (e1 - e2), m2, e2)
        | _  -> (m1, Float.ldexp m2 (e2 - e1), e1)
    in
    let m' = m1 -. m2 in
    if m' >= 1. || m' <= -1.
    then (m' *. 0.5, e + 1)
    else if -0.5 < m' && m' < 0.5
    then (m' *. 2., e - 1)
    else (m', e)

let (<*>) (m1, e1) (m2, e2) =
    let m' = m1 *. m2 in
    if -0.5 < m' && m' < 0.5
    then (m' *. 2., e1 + e2 - 1)
    else (m', e1 + e2)

let ( *> ) f (m, e) =
    let ff, fe = Float.frexp f in
    let m' = ff *. m in
    if -0.5 < m' && m' < 0.5
    then (m' *. 2., fe + e - 1)
    else (m', fe + e)

let compare (m1, e1) (m2, e2) =
    match Int.compare e1 e2 with
    | 0 -> Float.compare m1 m2
    | o -> o


let pp fmt (m, e) =
    let r, k = Float.modf (Float.of_int e *. Float.log 2. /. Float.log 10.) in
    Format.fprintf fmt "%fe%d"
        (m *. Float.exp (r *. Float.log 10.)) (Float.to_int k)
