#!/bin/sh

timeout=20
cmd="dune exec ./bench.exe"

for combi in $($cmd list-combinations); do
    echo "==== combination $combi"
    if [ ! -d data/$combi ]; then
        mkdir data/$combi
    fi
    for bench in $($cmd list-benches $combi); do
        echo "=== benchmark $bench"
        echo "size $($cmd list-normalizers $combi)" >data/$combi/$bench.dat
        for size in $($cmd list-sizes $bench); do
            if [ "$bench" = "random" ]; then
                echo "generating random terms of size $size"
                dune exec ./gen_random_terms.exe $size 0 51 data/randterm$size data/term_counts
            fi
            echo "size $size"
            echo -n "$size" >>data/$combi/$bench.dat
            for normalizer in $($cmd list-normalizers $combi); do
                msg=$(timeout -s KILL $timeout $cmd $normalizer $bench $size 2>&1)
                if [ "$?" != "0" ]; then
                    echo "> $normalizer: failed ($msg)"
                    echo -n " MISSING" >>data/$combi/$bench.dat
                else
                    echo "> $normalizer: $msg"
                    echo -n " $msg" >>data/$combi/$bench.dat
                fi
                sleep 1
            done
            echo "" >>data/$combi/$bench.dat
        done
    done
done
