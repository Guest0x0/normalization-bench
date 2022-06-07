
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


    let create ?(init_size=10) ~garbage () =
        { data    = Array.make init_size garbage
        ; len     = 0
        ; garbage = garbage }

    let push value vec =
        if vec.len >= Array.length vec.data then begin
            let data' = Array.make (max 10 (vec.len * 3 / 2)) vec.garbage in
            Array.blit vec.data 0 data' 0 vec.len;
            vec.data <- data';
        end;
        vec.data.(vec.len) <- value;
        vec.len <- vec.len + 1

    let get idx vec = vec.data.(vec.len - idx - 1)
    let last vec = vec.data.(vec.len - 1)

    let pop vec =
        vec.len <- vec.len - 1

    let copy vec = { vec with data = Array.sub vec.data 0 vec.len }

    let to_array vec = Array.init vec.len (fun i -> vec.data.(i))
end



module SkewList = struct
    type 'a tree =
        | Leaf   of 'a
        | Branch of 'a tree * 'a * 'a tree

    type 'a t = (int * 'a tree) list


    let empty = []


    let push elem t =
        match t with
        | (m, l) :: (n, r) :: t' when m = n ->
            (2 * m + 1, Branch(l, elem, r)) :: t'
        | _ ->
            (1, Leaf elem) :: t

    let pop t =
        match t with
        | [] ->
            failwith "SkewList.pop"
        | (_, Leaf _) :: t' ->
            t'
        | (m, Branch(l, _, r)) :: t' ->
            let m' = (m - 1) / 2 in
            (m', l) :: (m', r) :: t'


    let rec get_tree idx (m, tree) =
        match tree with
        | Leaf e
        | Branch(_, e, _) when idx = 0 ->
            e
        | Branch(l, _, r) ->
            let m' = (m - 1) / 2 in
            if idx - 1 < m'
            then get_tree (idx - 1)      (m', l)
            else get_tree (idx - 1 - m') (m', r)
        | _ ->
            failwith "SkewList.get"

    let rec get idx t =
        match t with
        | [] ->
            failwith "SkewList.get"
        | (m, tree) :: _ when idx < m ->
            get_tree idx (m, tree)
        | (m, _) :: t' ->
            get (idx - m) t'
end
