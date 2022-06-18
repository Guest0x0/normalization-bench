#!/bin/sh

cmd="dune exec ./bench.exe"

(
echo "set terminal png;"
echo "set datafile missing 'MISSING'"
for combi in $($cmd list-combinations); do
    for bench in $($cmd list-benches $combi); do
        echo "set output 'data/$combi/$bench.png'"
        echo "set title '$combi@$bench' noenhanced"
        column=2
        echo -n "plot"
        for normalizer in $($cmd list-normalizers $combi); do
            echo -n " 'data/$combi/$bench.dat' using 1:$column title columnheader($column) with lines lw 3,"
            column=$((column + 1))
        done
        echo ";"
    done
done
) | gnuplot
