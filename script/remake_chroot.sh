#!/bin/bash

((`id -u`)) && { echo must be root.; exit 1; }

src=chroot/crazy_pipework


get_lib_path() {
	local name="$1"
	local arch="$2"

	ldconfig -p |
	sed -n "/$name .*(.*$arch.*)/s/.*=> //p"
}



echo searching for dependencies...
bin=(
	`
		./gen_deps.sh \
			$src/bin/client \
			$src/main \
			$src/bin/curses \
			$src/bin/data \
			$src/bin/file \
			$src/bin/include \
			$src/bin/in \
			$src/bin/mod \
			$src/bin/net \
			$src/bin/out \
			$src/bin/user \
			$src/cassettes/galax/games/galax.sh \
			$src/cassettes/galax2/games/galax.sh 
	`

	`
		cat depend.txt 
	`
)

echo making chroot env...
echo "${bin[@]}"
mkdir chroot
./add_chroot_cmd2 chroot "${bin[@]}"

#case `arch` in
#(x86_64)	ln -s lib64 chroot/lib ;;
#(x86)		ln -s lib32 chroot/lib ;;
#(armv7l)	ln -s lib32 chroot/lib ;;
#esac

echo copying misc files...
mkdir -p chroot/etc/perl

perl -e 'print $_."\n" for @INC' |
sed '/^\.$/d' |
while read i
do
	cp -r "$i"/* chroot/etc/perl
done

cp -r --parents /lib/terminfo/ chroot/
cp -r --parents /usr/share/i18n/ chroot/
cp -r --parents /usr/lib/locale/ chroot/
cp -r --parents /usr/lib/python* chroot/
cp -r crazy_pipework chroot/
mkdir -p chroot/home/.my-client/bin

cp chroot/crazy_pipework/bin/py_curses.py chroot/home/.my-client/bin

mkdir chroot/tmp
chmod a+rw chroot/tmp
mkdir chroot/dev
mount chroot/dev
echo done.
