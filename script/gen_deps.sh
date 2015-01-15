#!/bin/bash

cat "$@" |
sed '/^[ \t]*#/d' |
sed 's/[^ ]*=[^ ]*//' |
sed 's/^[ \t]*\(if\|elif\|while\|until\)[ \t]//' |
sed 's/\([^ ]*\).*/\1/' |
sed 's/^[ \t]*//' |
sort -u |
while read c
do 
	which "$c"
done
