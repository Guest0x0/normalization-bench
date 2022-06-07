# Benchmarking Normalization Algorithms

## Framework
Lambda terms are represented using de Brujin index.
Each algorithm should provide two functions:

- `preprocess`, which converts a lambda term to the algorithm's internal representation
- `normalize`, which normalizes the term and convert it back to syntax

In the future, maybe the time needed to test conversion directly
on the algorithm's internal rep. may be added.

The definition of syntax and common data structures lies in `Common`.

The `bench.ml` executable can be used to run the various test benches.
You should provide it with the name of normalizer,
the name of benchmark and size parameter to the benchmark.

To exclude the effect of previous runs on GC,
every test run should be executed with a fresh process.
This is done through the `bench.sh` script.
It also handles timeout of benchmarks.


## Algorithms
Various normalization algorithms sit in `Normalizers`:

- `subst.naive` (in `NaiveSubst.ml`):
naive normal-order capture-avoiding substitution
- `NBE.HOAS.list|tree` (in `NBE_HOAS.ml`):
Normalization By Evaluation (NBE), using HOAS to represent closures.
There are variants using list and OCaml's binary tree based map
to represent the environment
- `NBE.HOAS.closure.list|tree` (in `NBE_Closure.ml`):
NBE, using raw lambda terms to represent closures.
Come with two favors of environment data structure too
- `NBE.pushenter` (in `NBE_Pushenter.ml`)
NBE with a push/enter style uncurrying.
A separate argument stack is maintained,
and closures are only allocated when the argument stack is empty.
(Currently this does not seem to perform well.
I doubt that I am doing it wrong)
- `NBE.lazy` (in `NBE_Lazy.ml`):
a variant of `NBE.HOAS.list` with lazy evaluation everywhere.
- `AM.Crégut.X` (in `AbstractMachine.ml`):
The strongly reducing krivine abstract machine of Pierre Crégut.
I found it in [[1]](#1),
and the original paper is [[2]](#2).
The variants are:

  - `list`: use lists as stack
  - `ADT`: inline the definition of each stack frame into the definition list
  - `vec@size`: use vector as stack with initial size `size`
  - `CBV`: I try to implement a CBV version of the machine here
  (the original one is CBN). Use inlined ADT as stack.

- (TODO) an eval/apply variant of uncurry optimization
- (TODO) some bytecode based approaches.
For example the modified ZAM used in Coq [[3]](#3)
- (TODO) fully lazy, in-place, graph reduction,
found in [[4]](#4)
- (TODO) the suspension lambda calculus in [[5]](#5)


## Test Data

- `church_add`: adding two church numerals
- `church_mul`: multiplying two church numerals
- `iterated_id_L`: `( ... ((id id) id) ... )`
- `iterated_id_R`: `( ... (id (id id)) ... )`
- `random`: randomly generated (uniformly distributed) lambda terms.
The generation algorithm comes from [[6]](#6).
First, a table of the total number of lambda terms of different sizes
can be generated using `count_terms.ml` (`dune exec ./count_terms.exe`)
(WARNING: very very costly even for modest sizes (< 10000)).
Then `gen_random_terms.ml` (`dune exec ./gen_random_terms.ml`)
can be used to randomly generate uniformly distributed lambda terms
of different sizes and number of free variables
- `self_interp_size`: encode lambda terms using lambda terms with
scott encoding, then calculate the size (in church numeral) of terms
by structural recursion
- (TODO) operations on other inductive types
- (TODO) self interpreter of lambda calculus
- (TODO) maybe make some type-erasured programs from existing code bases?


## References

<a id="1">[1]</a>
<https://oa.upm.es/30153/1/30153nogueiraINVES_MEM_2013.pdf>

<a id="2">[2]</a>
<https://dl.acm.org/doi/10.1007/s10990-007-9015-z>

<a id="3">[3]</a>
<https://hal.inria.fr/hal-01499941/document>

<a id="4">[4]</a>
<https://www.ccs.neu.edu/home/wand/papers/shivers-wand-10.pdf>

<a id="5">[5]</a>
<https://dl.acm.org/doi/book/10.5555/868417>

<a id="6">[6]</a>
<http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.95.2624>
