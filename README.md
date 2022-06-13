# Benchmarking Normalization Algorithms

## Framework
Lambda terms are represented using de Brujin index.
Time used to normalize a term is measured.
Some algorithms may use an alternative term representation.
In this case, the time used to convert between different term representations
is not counted.
Note that intermediate data structure like values in NBE
does not count as an alternative term representation
because they cannot be examined.

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

- `subst.naive` (in `Subst.ml`):
naive normal-order capture-avoiding substitution
- `subst.whead` (in `Subst.ml`):
capture-avoiding substitution, but reduce head only to weak head first
before substitution.
- `NBE.HOAS.X` (in `NBE_HOAS.ml`):
Normalization By Evaluation (NBE), using HOAS to represent closures.
`X` is the data structure used to implement the environment,
which includes:
  - `list`: plain list
  - `tree`: `Map` in OCaml's standard library (AVL tree)
  - `skew`: skew binary random access list from Chris Okasaki's
  Purely Functional Data structure [[9]](#9)
- `NBE.memo.v1|v2|v3` (in `NBE_Memo.ml`)
Same as `NBE.closure.list`,
but each value memorizes the term it quotes back to (at some level).
There's only one memorization slot, to reduce constant overhead.
`v1`, `v2` and `v3` uses three different ways to store the extra memorization slot.
`v1` uses a fat pointer storing a mutable `(level * term) option`,
`v2` also uses fat pointer, but uses two separate mutable slots
for the level and the term respectively (the term slot holds garbage initiallly).
`v3` stores the memorization slot inside the block for each case of the value ADT,
and hence has only one layer of indirection.
Turns out that this dirty memory layout optimizations have a significnat effect.
- `NBE.closure.list|tree` (in `NBE_Closure.ml`):
NBE, using raw lambda terms to represent closures.
Come with two flavors of environment data structure too
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
  - `arr`: use a large array as stack with initial size `size`
  - `CBV`: I try to implement a CBV version of the machine here
  (the original one is CBN). Use inlined ADT as stack.

- `compiled.HOAS.byte|native|O2` (in `Compiled_HOAS.ml`):
compile the given term to a OCaml program
that performs normalization directly by tagged HOAS.
The generated OCaml program can be compiled in bytecode, native,
or optimized native mode.
I got the idea from [[10]](#10) and [[11]](#11).
- `compiled.evalapply.byte|native|O2` (in `Compiled_Evalapply.ml`):
compile the given term to a OCaml program
that performs normalization directly by tagged HOAS,
with eval/apply style n-ary function optimization for functions with 1~5 params.
The generated OCaml program can be compiled in bytecode, native,
or optimized native mode.
I got the idea from [[12]](#12).
- (TODO) some bytecode based approaches.
For example the modified ZAM used in Coq [[3]](#3)
- (TODO) fully lazy, in-place, graph reduction,
found in [[4]](#4)
- (TODO) the suspension lambda calculus in [[5]](#5)


## Test Data

- `church_add`: adding two church numerals
- `church_mul`: multiplying two church numerals
- `exponential`: an artificial benchmark of terms whose normal forms'
sizes grow exponentially and have a lot of sharing.
Let `t(0) = x`, `t(n+1) = (\y. y y) t(n)`,
this benchmark normalizes `\x. t(n)`.
Let `r(0) = x`, `r(n+1) = r(n) r(n)`,
`\x. t(n)` will normalize to `\x. r(n)`.
- `parigot_add`: adding two numerals in parigot encoding [[7]](#7).
I read about parigot encoding in [[8]](#8).
This is perhaps a practical example of terms of exponentially growing size.
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

<a id="7">[7]</a>
<https://link.springer.com/chapter/10.1007/3-540-52753-2_47?noAccess=true>

<a id="8">[8]</a>
<https://homepage.cs.uiowa.edu/~astump/papers/cedille-draft.pdf>

<a id="9">[9]</a>
<https://dl.acm.org/doi/10.5555/580840>

<a id="10">[10]</a>
<https://www21.in.tum.de/~nipkow/pubs/tphols08.pdf>

<a id="11">[11]</a>
<https://hal.inria.fr/hal-00650940/document>

<a id="12">[12]</a>
<https://hal.inria.fr/inria-00434283/document>
