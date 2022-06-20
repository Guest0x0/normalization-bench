
let normalizers = [
    "subst.naive"     , Subst.normalizer_naive;
    "subst.whead"     , Subst.normalizer_whead;
    "NBE.HOAS.list"   , NBE_HOAS.normalizer_list;
    "NBE.HOAS.tree"   , NBE_HOAS.normalizer_tree;
    "NBE.HOAS.skew"   , NBE_HOAS.normalizer_skew;
    "NBE.closure.list", NBE_Closure.normalizer_list;
    "NBE.closure.tree", NBE_Closure.normalizer_tree;
    "NBE.named.list"  , NBE_Named.normalizer_list;
    "NBE.named.tree"  , NBE_Named.normalizer_tree;
    "NBE.named.ADT"   , NBE_Named.normalizer_adt;
    "NBE.memo.v1"     , NBE_Memo.normalizer_v1;
    "NBE.memo.v2"     , NBE_Memo.normalizer_v2;
    "NBE.memo.v3"     , NBE_Memo.normalizer_v3;
    "NBE.memo.v4"     , NBE_Memo.normalizer_v4;
    "NBE.memo.named"  , NBE_Memo.normalizer_named;
    "NBE.lazy"        , NBE_Lazy.normalizer;
    "NBE.pushenter"   , NBE_Pushenter.normalizer;
    "AM.Crégut.list"  , AbstractMachine.normalizer_list;
    "AM.Crégut.ADT"   , AbstractMachine.normalizer_adt;
    "AM.Crégut.arr"   , AbstractMachine.normalizer_arr;
    "AM.Crégut.CBV"   , AbstractMachine.normalizer_cbv;
    "compiled.HOAS.byte.N"  , Compiled_HOAS.byte_normalize;
    "compiled.HOAS.native.N", Compiled_HOAS.native_normalize;
    "compiled.HOAS.O2.N"    , Compiled_HOAS.o2_normalize;
    "compiled.HOAS.byte.C"  , Compiled_HOAS.byte_compile;
    "compiled.HOAS.native.C", Compiled_HOAS.native_compile;
    "compiled.HOAS.O2.C"    , Compiled_HOAS.o2_compile;
    "compiled.evalapply.byte.N"  , Compiled_Evalapply.byte_normalize;
    "compiled.evalapply.native.N", Compiled_Evalapply.native_normalize;
    "compiled.evalapply.O2.N"    , Compiled_Evalapply.o2_normalize;
    "compiled.evalapply.byte.C"  , Compiled_Evalapply.byte_compile;
    "compiled.evalapply.native.C", Compiled_Evalapply.native_compile;
    "compiled.evalapply.O2.C"    , Compiled_Evalapply.o2_compile;
]
