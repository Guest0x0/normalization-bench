
open Common.Syntax
open Common.Terms


let benches = [
    ( "church_add"
    , fun size ->
          List.init 1 @@ Fun.const
              ( apply church_add [church size; church size]
              , Option.some @@ church (size + size) )
    );
    ( "church_mul"
    , fun size ->
          List.init 1 @@ Fun.const
              ( apply church_mul [church size; church size]
              , Option.some @@ church (size * size) )
    );
    ( "parigot_add"
    , fun size ->
          List.init 1 @@ Fun.const
              ( App(App(parigot_add, parigot_shared size), parigot_shared size)
              , Option.some @@ parigot (size + size) )
    );
    ( "iterated_id_L"
    , let rec loop size =
          if size <= 1
          then id
          else App(loop (size - 1), id)
        in fun size -> List.init 1 @@ Fun.const (loop size, Some id)
    );
    ( "iterated_id_R"
    , let rec loop size =
          if size <= 1
          then id
          else App(id, loop (size - 1))
        in fun size -> List.init 1 @@ Fun.const (loop size, Some id)
    );
    ( "random"
    , fun size ->
          let file = open_in ("data/randterm" ^ string_of_int size) in
          List.init 10 (fun _ -> deserialize file, None)
    );
    ( "self_interp_size"
    , fun size ->
        let tm = church size in
        List.init 1 @@ Fun.const (
            App(church_lam_size, encode_term tm),
            Some(church (term_size tm))
        )
    );
]


let _ =
    if Sys.argv.(1) = "list-normalizers" then
        ( List.iter (fun (name, _)  -> print_endline name)
                        Normalizers.normalizers
        ; exit 0 );
    let normalizer = List.assoc Sys.argv.(1) Normalizers.normalizers in
    let terms = List.assoc Sys.argv.(2) benches in
    let size = int_of_string Sys.argv.(3) in
    normalizer.run (terms size)
