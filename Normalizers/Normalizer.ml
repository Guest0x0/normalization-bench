
open Common

type normalizer =
    { run : (Syntax.term * Syntax.term option) list -> unit }

exception Wrong_Answer
let simple_normalizer f =
    let run terms =
        let total = ref 0. in
        terms |> List.iter begin fun (tm, expected) ->
            let t0 = Sys.time () in
            let nf = f tm in
            let t1 = Sys.time () in
            match expected with
            | Some nf' when Hashtbl.hash nf <> Hashtbl.hash nf' ->
                raise Wrong_Answer
            | _ ->
                total := !total +. t1 -. t0
        end;
        Printf.printf "%f\n" !total
    in { run }

let object_normalizer constructor param =
    let run terms =
        let normalizer = constructor param in
        (simple_normalizer (fun tm -> normalizer#normalize tm)).run terms
    in { run }

let normalizer_with_alt_term_rep ~of_term ~normalize ~to_term =
    let run terms =
        let total = ref 0. in
        terms |> List.iter begin fun (tm, expected) ->
            let tm' = of_term tm in
            let t0  = Sys.time () in
            let nf' = normalize tm' in
            let t1  = Sys.time () in
            let nf  = to_term nf' in
            match expected with
            | Some nf' when Hashtbl.hash nf <> Hashtbl.hash nf' ->
                raise Wrong_Answer
            | _ ->
                total := !total +. t1 -. t0
        end;
        Printf.printf "%f\n" !total
    in { run }


let compiled_normalizer ~mode prelude compile =
    let rec output_term out tm =
        match tm with
        | Common.Syntax.Idx idx ->
            output_string out "(Idx ";
            output_string out (string_of_int idx);
            output_string out ")"
        | Common.Syntax.Lam tm' ->
            output_string out "(Lam ";
            output_term out tm';
            output_string out ")"
        | Common.Syntax.App(f, a) ->
            output_string out "(App(";
            output_term out f;
            output_string out ", ";
            output_term out a;
            output_string out "))"
    in
    let run terms =
        let target_file = "_build/tmp.ml" in
        let target = open_out target_file in
        let t0 = Sys.time () in
        output_string target
            "type term = Idx of int | Lam of term | App of term * term;;\n";
        prelude target;
        output_string target "let t0 = Sys.time ();;\n";
        terms |> List.iter begin fun (tm, expected) ->
            compile target tm;
            begin match expected with
            | Some expected ->
                output_string target "let expected = ";
                output_term target expected;
                output_string target ";;\n";
                output_string target "if Hashtbl.hash nf <> Hashtbl.hash expected";
                output_string target " then (print_endline \"wrong answer\"; exit 1);;\n";
            | None ->
                ()
            end
        end;
        output_string target "let t1 = Sys.time ();;\n";
        output_string target "print_float (t1 -. t0);;";
        close_out target;
        let t1 = Sys.time () in
        ignore @@ Sys.command @@ String.concat " " [ "./compile.sh"; mode ];
        Printf.printf " (gen=%.6f)\n" (t1 -. t0)
    in { run }
