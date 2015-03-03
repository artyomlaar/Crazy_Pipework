#!/bin/bash

((`id -u`)) && { echo must be root.; exit 1; }

echo searching for dependencies...
bin=(
	`
		./gen_deps.sh \
			crazy_pipework/bin/client \
			crazy_pipework/main \
			crazy_pipework/bin/curses \
			crazy_pipework/bin/data \
			crazy_pipework/bin/file \
			crazy_pipework/bin/include \
			crazy_pipework/bin/in \
			crazy_pipework/bin/mod \
			crazy_pipework/bin/net \
			crazy_pipework/bin/out \
			crazy_pipework/bin/user \
			crazy_pipework/cassettes/galax/games/galax.sh \
			crazy_pipework/cassettes/galax2/games/galax.sh 
	`

	`
		cat depend.txt 
	`
)

echo making chroot env...
echo "${bin[@]}"
./add_chroot_cmd.sh "${bin[@]}"

case `arch` in
(x86_64)	ln -s lib64 chroot/lib ;;
(x86)		ln -s lib32 chroot/lib ;;
(armv7l)	ln -s lib32 chroot/lib ;;
esac

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
