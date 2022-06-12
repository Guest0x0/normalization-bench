
let normalizers = [
    (*
    "subst.naive"     , Subst.normalizer_naive;
    "subst.whead"     , Subst.normalizer_whead;
    "NBE.HOAS.list"   , NBE_HOAS.normalizer_list;
    "NBE.HOAS.tree"   , NBE_HOAS.normalizer_tree;
    "NBE.HOAS.skew"   , NBE_HOAS.normalizer_skew;
   *)
    "NBE.closure.list", NBE_Closure.normalizer_list;
    (*
    "NBE.closure.tree", NBE_Closure.normalizer_tree;
    "NBE.memo"        , NBE_Memo.normalizer;
    "NBE.lazy"        , NBE_Lazy.normalizer;
    "NBE.pushenter"   , NBE_Pushenter.normalizer;
    "AM.Crégut.list"  , AbstractMachine.normalizer_list;
    "AM.Crégut.ADT"   , AbstractMachine.normalizer_adt;
    "AM.Crégut.arr"   , AbstractMachine.normalizer_arr;
    "AM.Crégut.CBV"   , AbstractMachine.normalizer_cbv;
   *)
    "compiled.HOAS.byte"   , Compiled_HOAS.normalizer "byte";
    "compiled.HOAS.native"   , Compiled_HOAS.normalizer "native";
    "compiled.HOAS.O2"   , Compiled_HOAS.normalizer "O2";
    "compiled.evalapply.byte", Compiled_Evalapply.normalizer "byte";
    "compiled.evalapply.native", Compiled_Evalapply.normalizer "native";
    "compiled.evalapply.O2", Compiled_Evalapply.normalizer "O2";
]
