
open Common.Syntax
open Common.Terms

type time_stat =
    { preprocess : float
    ; normalize  : float }

type test_bench =
    { name     : string
    ; terms    : int -> (term * term option) list }



let benches = [
    { name  = "church_add"
    ; terms = (fun size ->
          List.init 100 @@ Fun.const @@
              ( App(App(church_add, church size), church size)
              , Option.some @@ church (size + size) )) };
    { name  = "church_mul"
    ; terms = (fun size ->
          List.init 100 @@ Fun.const @@
              ( App(App(church_mul, church size), church size)
              , Option.some @@ church (size * size) )) };
    { name  = "iterated_id"
    ; terms =
          let rec loop size =
              if size <= 1
              then id
              else App(loop (size - 1), id)
          in fun size -> List.init 100 @@ Fun.const (loop size, Some id) };
    { name = "random"
    ; terms = fun size ->
          let file = open_in ("data/randterm" ^ string_of_int size) in
          List.init 99 (fun _ -> deserialize file, None) };
]


let _ =
    if Sys.argv.(1) = "list-normalizers" then
        ( List.iter (fun (name, _)  -> print_endline name)
                        Normalizers.normalizers
        ; exit 0 );
    let (Norm(preprocess, normalize)) =
        List.assoc Sys.argv.(1) Normalizers.normalizers
    in
    let bench = List.find (fun bench -> bench.name = Sys.argv.(2)) benches in
    let size = int_of_string Sys.argv.(3) in
    let preprocess_t = ref 0. in
    let normalize_t  = ref 0. in
    bench.terms size |> List.iter begin fun (tm, expected) ->
        let t0  = Sys.time () in
        let rep = preprocess tm in
        let t1  = Sys.time () in
        let nf  = normalize rep in
        let t2  = Sys.time () in
        match expected with
        | Some expected when Hashtbl.hash expected <> Hashtbl.hash nf ->
            failwith "wrong answer\n"
        | _ ->
            preprocess_t := !preprocess_t +. t1 -. t0;
            normalize_t  := !normalize_t  +. t2 -. t1
    end;
    Format.printf
        "preprocess=%f, normalize=%f, total=%f\n"
        !preprocess_t !normalize_t (!preprocess_t +. !normalize_t);
    Format.print_flush ()
