
open Common

type normalizer =
      Norm : (Syntax.term -> 'rep) * ('rep -> Syntax.term) -> normalizer
