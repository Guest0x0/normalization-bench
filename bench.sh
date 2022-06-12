#!/bin/sh

timeout=20
cmd="dune exec ./bench.exe"
normalizers=$($cmd list-normalizers)

run_bench() {
    bench=$1
    shift 1
    echo "=========== bench $bench ==========="
    for size in $*; do
        echo "size $size:"
        for normalizer in $normalizers; do
            msg=$(timeout $timeout $cmd $normalizer $bench $size 2>&1)
            if [ "$?" = "124" ]; then
                echo "> $normalizer: time exceeded"
            else
                echo "> $normalizer: $msg"
            fi
            sleep 0.5
        done
    done
}

# run_bench church_add 10000 50000 100000
run_bench church_mul 80 160 240
# run_bench parigot_add 5 10 11 12
# run_bench iterated_id_L 10000 50000 100000
# run_bench iterated_id_R 10000 50000 100000
for size in 1000 2000 4000; do
    echo "generating random terms of size $size"
    dune exec ./gen_random_terms.exe $size 0 100 data/randterm$size data/term_counts
done
run_bench random 1000 2000 4000
run_bench self_interp_size 100 500 1000 2000
