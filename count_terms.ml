

open Common

let _ =
    let max_size    = int_of_string Sys.argv.(1) in
    let max_env_len = int_of_string Sys.argv.(2) in
    let table = Array.make_matrix max_size max_env_len (ApproxNum.of_int 0) in
    let count_terms size env_len =
        let open ApproxNum in
        match size with
        | 0 -> of_int 0
        | 1 -> of_int env_len
        | _ ->
            let n_lam =
                if env_len + 1 < max_env_len
                then table.(size - 1).(env_len + 1)
                else of_int 0
            in
            let n_app = ref (of_int 0) in
            for i = 1 to size - 2 do
                let n_fun = table.(i           ).(env_len) in
                let n_arg = table.(size - 1 - i).(env_len) in
                n_app := !n_app <+> (n_fun <*> n_arg)
            done;
            n_lam <+> !n_app
    in

    let prog = ref 1 in
    let t0   = Sys.time () in
    for size = 0 to max_size - 1 do
        if size * size * 1000 > max_size * max_size * !prog then begin
            let t = Sys.time () in
            let eta = Float.to_int (t -. t0) * (1000 - !prog) / !prog in
            Printf.printf "counting terms: %03d%%%%, ETA %dh%dm%ds\n%!"
                !prog (eta / 3600) (eta mod 3600 / 60) (eta mod 60);
            incr prog
        end;
        for env_len = 0 to max_env_len - 1 do
            table.(size).(env_len) <- count_terms size env_len
        done
    done;

    let target_file = try Sys.argv.(3) with _ -> "data/term_counts" in
    let out = open_out_bin target_file in
    output_value out table;
    close_out out
