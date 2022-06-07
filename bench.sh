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
            msg=$(timeout $timeout $cmd $normalizer $bench $size)
            if [ "$?" = "124" ]; then
                echo "> $normalizer: time exceeded"
            else
                echo "> $normalizer: $msg"
            fi
            sleep 0.5
        done
    done
}

run_bench church_add 10000 50000 100000 500000
run_bench church_mul 80 160 240 360
run_bench iterated_id 10000 50000 100000 500000
run_bench random 1000 2000 4000
