#!/bin/bash
((`id -u`)) && { echo must be root.; exit 1; }
echo searching dependencies...
bin=(`
./gen_deps.sh \
crazy_pipework/client.sh \
crazy_pipework/core.sh \
crazy_pipework/curses.sh \
crazy_pipework/data.sh \
crazy_pipework/file.sh \
crazy_pipework/include.sh \
crazy_pipework/in.sh \
crazy_pipework/mod.sh \
crazy_pipework/net.sh \
crazy_pipework/out.sh \
crazy_pipework/user.sh \
crazy_pipework/cassettes/galax/games/galax.sh \
crazy_pipework/cassettes/galax2/games/galax.sh 
` `
cat depend.txt 
`)
echo making chroot env...
echo "${bin[@]}"
./add_chroot_cmd.sh "${bin[@]}"
echo copying misc files...
mkdir -p chroot/etc/perl
perl -e 'print $_."\n" for @INC' | sed '/^\.$/d' | while read i; do cp -r "$i"/* chroot/etc/perl; done
#export PERL5LIB=/perl
cp -r --parents /lib/terminfo/ chroot/
cp -r --parents /usr/share/i18n/ chroot/
cp -r --parents /usr/lib/locale/ chroot/
cp -r --parents /usr/lib/python* chroot/
cp -r crazy_pipework chroot/
mkdir -p chroot/home/.my-client/bin
cp chroot/crazy_pipework/bin/py_curses.py chroot/home/.my-client/bin
chown -R pipework chroot/home/.my-client/
chown -R pipework chroot/crazy_pipework/pipe/
chown -R pipework chroot/crazy_pipework/log/
chown pipework chroot/crazy_pipework/ 
mkdir chroot/tmp
chmod a+rw chroot/tmp
mkdir chroot/dev
#mknod chroot/dev/null c 1 3
mount --bind /dev chroot/dev
echo done.
