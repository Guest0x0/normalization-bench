#!/bin/sh

timeout=20
seed=$(date +%N)
cmd="dune exec ./bench.exe"
normalizers=$($cmd list-normalizers)

run_bench() {
    bench=$1
    shift 1
    echo "=========== bench $bench ==========="
    for size in $*; do
        echo "size $size:"
        for normalizer in $normalizers; do
            msg=$(timeout $timeout $cmd 0 $normalizer $bench $size)
            if [ "$?" = "124" ]; then
                echo "> $normalizer: time exceeded"
            else
                echo "> $normalizer: $msg"
            fi
            sleep 0.5
        done
    done
}

run_bench church_add 100 500 1000 5000 10000 50000
run_bench church_mul 20 40 80 160
run_bench iterated_id 500 1000 5000 10000 50000
