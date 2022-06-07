
let normalizers = [
    "subst.naive"     , NaiveSubst.normalizer;
    "AM.Crégut"       , AbstractMachine.normalizer;
    "NBE.HOAS.list"   , NBE_HOAS.normalizer_list;
    "NBE.HOAS.tree"   , NBE_HOAS.normalizer_tree;
    "NBE.closure.list", NBE_Closure.normalizer_list;
    "NBE.closure.tree", NBE_Closure.normalizer_tree;
    "NBE.lazy"        , NBE_Lazy.normalizer;
    "NBE.pushenter"   , NBE_Pushenter.normalizer;
]
