# Benchmarking Normalization Algorithms

## Framework
Lambda terms are represented using de Brujin index.
Each algorithm should provide three functions:

- `convert`, which converts a lambda term to the algorithm's internal representation
- `normalize`, which normalizes the algorithm's internal representation
- `readback`, which read the algorithm's internal representation back to syntax

In the future, maybe the time needed to test conversion directly
on the algorithm's internal rep. may be added.


## Algorithms

- `naive_subst`: naive normal-order capture-avoiding substitution
- `nbe_hoas`: Normalization By Evaluation (NBE), using HOAS to represent closures.
There are variants using list and OCaml's map to represent the environment
- `nbe_closure`: NBE, using raw lambda terms to representi closures。
Come with two favors of environment data structure too
- (TODO) NBE with uncurry optimization (eval/apply or push/enter)
- (TODO) fully lazy, in-place, graph reduction


## Test Data

- adding or multiplying two church numerals
- (TODO) randomly generated (uniformly distributed) lambda terms
- (TODO) operations on other inductive types
- (TODO) maybe make some type-erasured programs from existing code bases?
