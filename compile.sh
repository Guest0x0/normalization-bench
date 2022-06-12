#!/bin/sh

mode=$1
t1=0
t2=0

if [ "$mode" = "byte" ]; then
    t1=$(date +%s.%N)
    ocamlc _build/tmp.ml -o _build/tmp.out
    t2=$(date +%s.%N)
elif [ "$mode" = "native" ]; then
    t1=$(date +%s.%N)
    ocamlopt _build/tmp.ml -o _build/tmp.out
    t2=$(date +%s.%N)
elif [ "$mode" = "O2" ]; then
    t1=$(date +%s.%N)
    ocamlopt -O2 _build/tmp.ml -o _build/tmp.out
    t2=$(date +%s.%N)
fi
_build/tmp.out
echo "Printf.printf \" (compile=%.6f)\" ($t2 -. $t1)" | ocaml -stdin
