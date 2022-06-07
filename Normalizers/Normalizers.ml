
let normalizers = [
    "subst.naive"       , NaiveSubst.normalizer;
    "AM.Crégut.list"    , AbstractMachine.normalizer_list;
    "AM.Crégut.ADT"     , AbstractMachine.normalizer_adt;
    "AM.Crégut.vec@200" , AbstractMachine.normalizer_vec 200;
    "AM.Crégut.vec@2000", AbstractMachine.normalizer_vec 2000;
    "AM.Crégut.CBV"     , AbstractMachine.normalizer_cbv;
    "NBE.HOAS.list"     , NBE_HOAS.normalizer_list;
    "NBE.HOAS.tree"     , NBE_HOAS.normalizer_tree;
    "NBE.closure.list"  , NBE_Closure.normalizer_list;
    "NBE.closure.tree"  , NBE_Closure.normalizer_tree;
    "NBE.lazy"          , NBE_Lazy.normalizer;
    "NBE.pushenter.list", NBE_Pushenter.normalizer_list;
    "NBE.pushenter.vec@100" , NBE_Pushenter.normalizer_vec 200;
    "NBE.pushenter.vec@2000", NBE_Pushenter.normalizer_vec 2000;
]
