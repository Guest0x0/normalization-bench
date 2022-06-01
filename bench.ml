
open Syntax

type time_stat =
    { mutable convert   : float
    ; mutable normalize : float
    ; mutable readback  : float }

let bench normalizers ?(n_iter=100) tm =
    let times= normalizers |> Array.map @@ fun _ ->
        { convert = 0.0; normalize = 0.0; readback = 0.0 }
    in
    for _ = 1 to n_iter do
        normalizers |> Array.iteri begin fun i (Norm normalizer) ->
            let t0 = Sys.time () in
            let rep = normalizer.of_term tm in
            let t1 = Sys.time () in
            let rep' = normalizer.normalize rep in
            let t2 = Sys.time () in
            let _ = normalizer.readback rep' in
            let t3 = Sys.time () in
            let time = times.(i) in
            time.convert   <- time.convert   +. t1 -. t0;
            time.normalize <- time.normalize +. t2 -. t1;
            time.readback  <- time.readback  +. t3 -. t2
        end
    done;
    times |> Array.iter begin fun time ->
        time.convert   <- time.convert   /. Float.of_int n_iter;
        time.normalize <- time.normalize /. Float.of_int n_iter;
        time.readback  <- time.readback  /. Float.of_int n_iter;
    end;
    times



let normalizers =
    [| Naive_subst.normalizer
     ; Nbe_hoas.normalizer_list
     ; Nbe_hoas.normalizer_map
     ; Nbe_closure.normalizer_list
     ; Nbe_closure.normalizer_map |]

let terms =
    let open Syntax in
    [| "church/10+10", App(App(church_add, church 10), church 10)
     ; "church/50+50", App(App(church_add, church 50), church 50)
     ; "church/100+100", App(App(church_add, church 100), church 100)
     ; "church/500+500", App(App(church_add, church 500), church 500)
     ; "church/1000+1000", App(App(church_add, church 1000), church 1000)
     ; "church/5000+5000", App(App(church_add, church 5000), church 5000)
     ; "church/10000+10000", App(App(church_add, church 10000), church 10000) |]


let _ =
    let _ = Random.self_init () in
    terms |> Array.iter begin fun (name, term) ->
        let times = bench normalizers ~n_iter:1 term in
        Format.printf "\n===== expr: %s =====\n" name;
        Format.print_flush ();
        normalizers |> Array.iteri @@ fun i (Norm { name; _ }) ->
        let time = times.(i) in
        Format.printf "normalizer %s: conv=%f, norm=%f, rb=%f, tot=%f@ "
            name time.convert time.normalize time.readback
            (time.convert +. time.normalize +. time.readback);
        Format.print_flush ()
    end;
