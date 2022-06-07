
let _ =
    let size    = int_of_string Sys.argv.(1) in
    let env_len = int_of_string Sys.argv.(2) in
    let num_terms   = int_of_string Sys.argv.(3) in
    let target_file = Sys.argv.(4) in

    let term_count_file =
        open_in_bin (try Sys.argv.(5) with _ -> "data/term_counts")
    in
    let table : Common.ApproxNum.t array array = input_value term_count_file in
    close_in term_count_file;

    let max_size    = Array.length table in
    let max_env_len = Array.length table.(0) in
    if  size <= 0 then
        raise(Invalid_argument "gen_random_terms: non-positive size");
    if  env_len < 0 then
        raise(Invalid_argument "gen_random_terms: negative number of free variables");
    if  size >= max_size then
        raise(Invalid_argument "gen_random_terms: size too large");
    if  env_len >= max_env_len then
        raise(Invalid_argument "gen_random_terms: free variable number too large");

    let exception Fail in
    let rec gen size env_len =
        let open Common.ApproxNum in
        let open Common.Syntax in
        match size with
        | 1 ->
            Idx(Random.int env_len)
        | _ ->
            let count = table.(size).(env_len) in
            let p = Random.float 1. in
            let nth = p *> count in
            let n_lam =
                if env_len + 1 < max_env_len
                then table.(size - 1).(env_len + 1)
                else of_int 0
            in
            if compare nth n_lam <= 0
            then
                Lam(gen (size - 1) (env_len + 1))
            else if size > 2 then
                let rec loop acc i =
                    let n_func = table.(i           ).(env_len) in
                    let n_arg  = table.(size - 1 - i).(env_len) in
                    let acc' = acc <+> (n_func <*> n_arg) in
                    if compare nth acc' <= 0
                    then App( gen i              env_len
                            , gen (size - 1 - i) env_len )
                    else loop acc' (i + 1)
                in
                loop n_lam 1
            else
                raise Fail
    in
    let out = open_out target_file in
    let rec loop i =
        if i >= num_terms
        then ()
        else
            let i' =
                match gen size env_len with
                | tm ->
                    let buf = Common.Syntax.serialize tm in
                    Buffer.output_buffer out buf;
                    i + 1
                | exception Fail ->
                    i
            in
            loop i'
    in
    loop 1;
    close_out out
