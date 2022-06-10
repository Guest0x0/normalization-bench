
open Common.Syntax



type term_id = int
type uplink_kind = Fun | Arg | Lam

type term =
    { term_id         : term_id
    ; mutable parents : (uplink_kind * term_id) list
    ; mutable shape   : term_shape }

and term_shape =
    | GVar
    | GLam of term_id * term_id
    | GApp of term_id * term_id

type dag =
    { terms  : (term_id, term) Hashtbl.t
    ; mutable id_cnt : int }

let get_term dag id = Hashtbl.find dag.terms id

let new_term dag f =
    let id = dag.id_cnt in
    dag.id_cnt <- id + 1;
    let tm = f id in
    Hashtbl.add dag.terms id tm;
    tm


let rec subst cache dag root var target =
    let rec phase1 orig dst =
        orig.parents |> List.iter begin fun (kind, parent_id) ->
            let parent = get_term dag parent_id in
            let cached, parent' =
                match Hashtbl.find cache parent_id with
                | parent' ->
                    true, parent'
                | exception Not_found ->
                    let parent' = new_term dag @@ fun id ->
                        { parent with term_id = id }
                    in
                    Hashtbl.add cache parent_id parent';
                    false, parent'
            in
            begin match kind, parent'.shape with
            | Fun, GApp(_, a) -> parent'.shape <- GApp(dst.term_id, a)
            | Arg, GApp(f, _) -> parent'.shape <- GApp(f, dst.term_id)
            | Lam, GLam(_, v) ->
                let v' = new_term dag @@ fun id ->
                    { term_id = id
                    ; parents = []
                    ; shape   = GVar }
                in
                subst cache dag parent_id (get_term dag v) v';
                parent'.shape <- GLam(dst.term_id, v'.term_id)
            | _  ->
                failwith "GraphReduction.subst"
            end;
            dst.parents <- (kind, parent'.term_id) :: dst.parents;
            if not cached && parent_id <> root then
                phase1 parent parent'
        end
    in
    let rec phase2 orig dst =
        assert false
    in
    assert false
