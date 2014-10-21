#!/bin/bash
command=adventure
$command 2>&1 <&$stdin >&$stdout 
echo Press any key to exit... >&$stdout 
read -n1 <&$stdin
exit

echo mod:use:in
sleep 2
while read c
do
	echo -n "${c#user:key=}"
done |
stdbuf -i0 -o0 tr $'\xd' $'\xa' |
$command 2>&1 | sed -u 's/$/\xd\xa/' >&$stdout 
echo Press any key to exit... >&$stdout 
read -n1 <&$stdin
