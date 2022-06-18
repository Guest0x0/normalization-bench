#!/bin/sh

mode=$1
target=$2
tgen=$3
t1=0
t2=0

if [ "$mode" = "byte" ]; then
    t1=$(date +%s.%N)
    ocamlc _build/tmp.ml -o _build/tmp.out || exit 1
    t2=$(date +%s.%N)
elif [ "$mode" = "native" ]; then
    t1=$(date +%s.%N)
    ocamlopt _build/tmp.ml -o _build/tmp.out || exit 1
    t2=$(date +%s.%N)
elif [ "$mode" = "O2" ]; then
    t1=$(date +%s.%N)
    ocamlopt -O2 _build/tmp.ml -o _build/tmp.out || exit 1
    t2=$(date +%s.%N)
fi
if [ "$target" = "normalize" ]; then
    _build/tmp.out
elif [ "$target" = "compile" ]; then
    echo "Printf.printf \"%.6f\" ($tgen +. $t2 -. $t1)" | ocaml -stdin
else
    exit 1
fi
