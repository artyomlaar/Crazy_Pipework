#!/bin/bash
mkdir chroot
cd chroot/
mkdir bin lib
cp `which $@` bin
(
	for i in $@
	do
		ldd `which $i` |
		sed 's/\([^ ]*\/\)*\([^ ]*\) .*/\2/' |
		xargs -I@ find / -name @ 2>/dev/null
	done
	cat ../lib_depend.txt |
	xargs -I@ find / -name @ 2>/dev/null
) |
tee /dev/stdout |
sort -u |
xargs -I@ cp -v @ lib
