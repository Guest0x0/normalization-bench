
module TMap = struct
    open Map.Make(Int)

    type nonrec 'a t =
        { data : 'a t
        ; len  : int }

    let empty = { data = empty; len = 0 }

    let push value tmap =
        { data = add tmap.len value tmap.data
        ; len  = tmap.len + 1 }

    let get idx tmap =
        find (tmap.len - idx - 1) tmap.data
end

module Vector = struct
    type 'a t =
        { mutable data : 'a Array.t
        ; mutable len  : int
        ; garbage      : 'a }


    let create ?(init_size=10) garbage () =
        { data    = Array.make init_size garbage
        ; len     = 0
        ; garbage = garbage }

    let push value vec =
        if vec.len >= Array.length vec.data then begin
            let data' = Array.make (vec.len * 3 / 2) vec.garbage in
            Array.blit vec.data 0 data' 0 vec.len;
            vec.data <- data';
        end;
        vec.data.(vec.len) <- value;
        vec.len <- vec.len + 1

    let get idx vec = vec.data.(vec.len - idx - 1)

    let pop vec =
        vec.len <- vec.len - 1;
        vec.data.(vec.len)

    let copy vec = { vec with data = Array.copy vec.data }

    let to_array vec = Array.init vec.len (fun i -> vec.data.(i))
end
