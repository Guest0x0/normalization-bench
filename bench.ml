
open Common.Syntax
open Common.Terms

type property = CBN | NoLargeTerm

let combinations = [
    ( "subst-NBE"
    , []
    , [ "subst.naive"; "subst.whead"; "NBE.closure.list" ] );
    ( "NBE-variants"
    , []
    , [ "NBE.HOAS.list"; "NBE.HOAS.tree"; "NBE.HOAS.skew"
      ; "NBE.closure.list"
      ; "NBE.lazy"
      ; "AM.Crégut.CBV" ] );
    ( "DBI-named"
    , []
    , [ "NBE.closure.list"
      ; "NBE.named.list"
      ; "NBE.named.tree"
      ; "NBE.named.ADT" ] );
    ( "AM-variants"
    , [CBN]
    , [ "AM.Crégut.list"
      ; "AM.Crégut.ADT"
      ; "AM.Crégut.arr" ] );
    ( "NBE-memo"
    , []
    , [ "NBE.closure.list"
      ; "NBE.memo.v1"
      ; "NBE.memo.v2"
      ; "NBE.memo.v3"
      ; "NBE.memo.v4"
      ; "NBE.memo.named" ] );
    ( "compiled-normalize"
    , [NoLargeTerm]
    , [ "NBE.closure.list"
      ; "compiled.HOAS.byte.N"
      ; "compiled.HOAS.native.N"
      ; "compiled.HOAS.O2.N"
      ; "compiled.evalapply.byte.N"
      ; "compiled.evalapply.native.N"
      ; "compiled.evalapply.O2.N" ] );
    ( "compiled-compile"
    , [NoLargeTerm]
    , [ "compiled.HOAS.byte.C"
      ; "compiled.HOAS.native.C"
      ; "compiled.HOAS.O2.C"
      ; "compiled.evalapply.byte.C"
      ; "compiled.evalapply.native.C"
      ; "compiled.evalapply.O2.C" ] );
    ( "NBE-hashcons"
    , []
    , [ "NBE.closure.list"
      ; "NBE.HC.idx"
      ; "NBE.HC.idx.o"
      ; "NBE.HC.lvlidx"
      ; "NBE.HC.lvlidx.o"
      ; "NBE.HC.hashcons" ] );
]

let benches = [
    ( "church_add"
    , [NoLargeTerm]
    , [10000; 25000; 50000; 75000; 100000; 200000; 300000; 400000]
    , fun size ->
          ( apply church_add [church size; church size]
          , Option.some @@ church (size + size) )
    );
    ( "church_mul"
    , []
    , [120; 140; 160; 180; 200; 220; 240; 260; 280; 300; 320]
    , fun size ->
        ( apply church_mul [church size; church size]
        , Option.some @@ church (size * size) )
    );
    ( "parigot_add"
    , []
    , [5; 6; 7; 8; 9; 10; 11; 12]
    , fun size ->
          ( App(App(parigot_add, parigot_shared size), parigot_shared size)
          , Option.some @@ parigot (size + size) )
    );
    ( "exponential"
    , []
    , [18; 19; 20; 21; 22; 23; 24]
    , let rec src size =
          if size <= 0
          then Idx 0
          else App(Lam(App(Idx 0, Idx 0)), src (size - 1))
        in
        let rec expected size =
            if size <= 0
            then Idx 0
            else
                let tm = expected (size - 1) in
                App(tm, tm)
        in
        fun size -> (Lam(src size), Some(Lam(expected size)))
    );
    ( "random"
    , []
    , [1000; 2000; 3000; 4000; 5000; 6000; 7000; 8000]
    , fun size ->
          let file = open_in ("data/randterm" ^ string_of_int size) in
          (Common.Terms.combine_terms (List.init 50 (fun _ -> deserialize file)), None)
    );
    ( "self_interp_size"
    , [CBN; NoLargeTerm]
    , [1000; 2000; 3000; 4000; 5000; 6000]
    , fun size ->
        let tm = church size in
        ( App(church_lam_size, encode_term tm)
        , Some(church (term_size tm)) )
    );
]


let _ =
    match Sys.argv.(1) with
    | "list-combinations" ->
        List.iter (fun (name, _, _) -> Printf.printf "%s " name)
            combinations;
        Printf.printf "\n"
    | "list-benches" ->
        let combi = Sys.argv.(2) in
        let (_, props, _) =
            List.find (fun (name, _, _) -> name = combi) combinations
        in
        benches |> List.iter begin fun (name, exclude, _, _) ->
            if List.for_all (fun prop -> not (List.mem prop exclude)) props then
                Printf.printf "%s " name
        end;
        Printf.printf "\n"
    | "list-normalizers" ->
        let combi = Sys.argv.(2) in
        let (_, _, normalizers) =
            List.find (fun (name, _, _) -> name = combi) combinations
        in
        List.iter (Printf.printf "%s ") normalizers;
        Printf.printf "\n"
    | "list-sizes" ->
        let bench = Sys.argv.(2) in
        let (_, _, sizes, _) =
            List.find (fun (name, _, _, _) -> name = bench) benches
        in
        List.iter (Printf.printf "%d ") sizes;
        Printf.printf "\n"
    | _ ->
        let normalizer = List.assoc Sys.argv.(1) Normalizers.normalizers in
        let bench = Sys.argv.(2) in
        let (_, _, _, terms) =
            List.find (fun (name, _, _, _) -> name = bench) benches
        in
        let size = int_of_string Sys.argv.(3) in
        let tm, expected = terms size in
        normalizer.run tm expected
