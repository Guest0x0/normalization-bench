
open Common

type normalizer =
    { run : Syntax.term -> Syntax.term * float * (string * float) list }

let simple_normalizer f =
    let run tm =
        let t0 = Sys.time () in
        let nf = f tm in
        let t1 = Sys.time () in
        (nf, t1 -. t0, [])
    in { run }

let object_normalizer constructor param =
    let run tm =
        let normalizer = constructor param in
        let t0 = Sys.time () in
        let nf = normalizer#normalize tm in
        let t1 = Sys.time () in
        (nf, t1 -. t0, [])
    in { run }

let normalizer_with_alt_term_rep ~of_term ~normalize ~to_term =
    let run tm =
        let tm' = of_term tm in
        let t0  = Sys.time () in
        let nf' = normalize tm' in
        let t1  = Sys.time () in
        let nf  = to_term nf' in
        (nf, t1 -. t0, [])
    in { run }

let normalizer_with_compilation ~compile ~normalize ~readback =
    let run tm =
        let t0 = Sys.time () in
        let compiled = compile tm in
        let t1  = Sys.time () in
        let nf' = normalize compiled in
        let t2  = Sys.time () in
        let nf  = readback nf' in
        let t3  = Sys.time () in
        ( nf, t3 -. t0
        , [ "compile"  , t1 -. t0
          ; "normalize", t2 -. t1
          ; "readback" , t3 -. t2 ] )
    in { run }
