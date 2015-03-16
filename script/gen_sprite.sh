#!/bin/bash
name=${1:-no_name}
spr="`cat`"
h=`wc -l <<<"$spr"`
w=$(head -n1 <<< "$spr" | wc -c ); ((w--))
lhalf=`echo -n $'\xe2\x96\x84'|iconv -f utf8`

if [[ $name = *.+1 ]]
then
	spr="$(perl -e 'print "0"x'$w)"$'\n'"$spr"
	((h++))
fi

((h+=h%2, h/=2))

echo curses:spr:$name:$w:$h

echo "$spr" |
for ((y=0; y<h; y++))
do
	read a && read b
	for ((x=0; x<w; x++))
	do
		t=${b:$x:1}
		t2=${a:$x:1}
		echo curses:prc:$name:$x:$y:${t:-0}:${t2:-0}:$lhalf
	done
done 

echo curses:hide:"$name"
echo curses:progsprinc:load

