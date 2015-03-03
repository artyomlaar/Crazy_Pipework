#!/bin/bash

get_elf_class()
{
#	readelf -h "$1" |
#	sed -n "s/^\s*Class:\s*//p"
	file -b $1 | cut -d\  -f1,2
}

mkdir chroot
cd chroot/
mkdir bin lib32 lib64
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
while read l
do
	case "`get_elf_class $l`" in
	(ELF\ 32-bit)	cp -v $l lib32 ;;
	(ELF\ 64-bit)	cp -v $l lib64 ;;
	esac
done

