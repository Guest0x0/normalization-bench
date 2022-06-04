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

- `subst.naive` (in `naive_subst.ml`):
naive normal-order capture-avoiding substitution
- `NBE.HOAS.list|tree` (in `nbe_hoas.ml`):
Normalization By Evaluation (NBE), using HOAS to represent closures.
There are variants using list and OCaml's binary tree based map
to represent the environment
- `NBE.HOAS.closure.list|tree` (in `nbe_closure.ml`):
NBE, using raw lambda terms to represent closures.
Come with two favors of environment data structure too
- `NBE.pushenter` (in `nbe_pushenter.ml`)
NBE with a push/enter style uncurrying.
A separate argument stack is maintained,
and closures are only allocated when the argument stack is empty.
(Currently this does not seem to perform well.
I doubt that I am doing it wrong)
- `AM.Crégut` (in `abstract_machine.ml`):
The strongly reducing krivine abstract machine of Pierre Crégut.
I found it in [[1]](#1),
and the original paper is [[2]](#2).
- (TODO) an eval/apply variant of uncurry optimization
- (TODO) some bytecode based approaches.
For example the modified ZAM used in Coq [[3]](#3)
- (TODO) fully lazy, in-place, graph reduction,
found in [[4]](#4)
- (TODO) the suspension lambda calculus in [[5]](#5)


## Test Data

- adding or multiplying two church numerals
- (TODO) randomly generated (uniformly distributed) lambda terms
- (TODO) operations on other inductive types
- (TODO) maybe make some type-erasured programs from existing code bases?


## References

<a id="1">[1]</a>
[](https://oa.upm.es/30153/1/30153nogueiraINVES_MEM_2013.pdf)

<a id="2">[2]</a>
[](https://dl.acm.org/doi/10.1007/s10990-007-9015-z)

<a id="3">[3]</a>
[](https://hal.inria.fr/hal-01499941/document)

<a id="4">[4]</a>
[](https://www.ccs.neu.edu/home/wand/papers/shivers-wand-10.pdf)

<a id="5">[5]</a>
[](https://dl.acm.org/doi/book/10.5555/868417)
