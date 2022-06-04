
open Syntax

type time_stat =
    { convert   : float
    ; normalize : float
    ; readback  : float }

type normalizer_state = Fine | TE | WrongAns

type test_bench =
    { name     : string
    ; terms    : int -> term * term }



let benches = [
    { name  = "church_add"
    ; terms = Syntax.(fun size ->
              ( App(App(church_add, church size), church size)
              , church (size + size) )) };
    { name  = "church_mul"
    ; terms = Syntax.(fun size ->
              ( App(App(church_mul, church size), church size)
              , church (size * size) )) };
    { name  = "iterated_id"
    ; terms =
          let rec loop size =
              if size <= 1
              then Syntax.id
              else Syntax.App(loop (size - 1), Syntax.id)
          in fun size -> (loop size, Syntax.id) }
]


let _ =
    Naive_subst.load ();
    Nbe_hoas.load ();
    Nbe_closure.load ();
    Nbe_pushenter.load ();
    Nbe_lazy.load ();
    Abstract_machine.load ();
    Syntax.normalizers := List.rev !Syntax.normalizers;
    if Sys.argv.(1) = "list-normalizers" then
        ( List.iter (fun (name, _)  -> print_endline name)
                    !Syntax.normalizers
        ; exit 0 );
    (* let seed = int_of_string Sys.argv.(1) in *)
    let (Norm normalizer) = List.assoc Sys.argv.(2) !Syntax.normalizers in
    let bench = List.find (fun bench -> bench.name = Sys.argv.(3)) benches in
    let size = int_of_string Sys.argv.(4) in
    let tm, expected = bench.terms size in
    let t0 = Sys.time () in
    let rep = normalizer.of_term tm in
    let t1 = Sys.time () in
    let rep' = normalizer.normalize rep in
    let t2 = Sys.time () in
    let nf = normalizer.readback rep' in
    let t3 = Sys.time () in
    if Hashtbl.hash expected <> Hashtbl.hash nf then
        Format.printf "wrong answer\n"
    else
        Format.printf
            "conv=%f, norm=%f, quote=%f, total=%f\n"
            (t1 -. t0) (t2 -. t1) (t3 -. t2) (t3 -. t0);
    Format.print_flush ()
