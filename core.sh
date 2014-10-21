#!/bin/bash

HOME=${HOME-/home/`whoami`} # home is unset when run from xinetd
PIPEDIR="${pdir-"`dirname $0`/pipe/$$"}" # it can be set from server.bash

#export -n pdir
export pdir="$PIPEDIR"

cd `dirname $0`

[ -d "$PIPEDIR" ] || mkdir "$PIPEDIR"

for i in "$PIPEDIR/../"*; do ps -p ${i##*/} &>/dev/null || rm -r $i; done

to_loop=$PIPEDIR/to_loop
from_loop=$PIPEDIR/from_loop

cfg_ptrn="^main:set_config:"

readconfig1="while (<STDIN>) { /$cfg_ptrn/ && last };"
readconfig2="s/$cfg_ptrn//; \$conf=\$_; print \"evaling\\n\"; eval \$conf;"


exec {stdout}>&1
exec {stdin}<&0

#trap 'tput sgr0; clear; echo killed; kill `ps|sed "1d;s/^ *//"|cut -f1 -d\ |grep -v $PPID`;' EXIT INT QUIT

trap 'tput sgr0; clear; kill 0' EXIT INT QUIT
#trap 'tput sgr0; kill 0' EXIT INT QUIT

source "include.sh"

linebufferedcat()
{
	cat
	# while read a; do echo $a; done
	# grep --line-buffered ''
}

icmds()
{
	echo "main:set_config:`mkptrn_pl`"
	echo "mod:set_io:$stdin:$stdout"
}

mkpipe()
{
	[ ! -p "$PIPEDIR/$1" ] && mkfifo "$PIPEDIR/$1" 
}

mktask()
{
	mkpipe $1
	eval "$2 <$PIPEDIR/$1  &"
	pidbyid[$1]=$!
	cmdbyid[$1]=$2

	for ((i=0;1;i++))
	do
		[ -z "${pattern[i]}" ] && pattern[i]=$1 && break 
	done
}

mkptrn_pl()
{
	for (( i=0; i<${#pattern[@]}; i++ ))
	do
		echo -n 'open '"${pattern[i]}"', ">'"$PIPEDIR"'/'"${pattern[i]}"'"; '
	done
	echo -n 'while(<STDIN>){ '
	for (( i=0; i<${#pattern[@]}; i++ ))
	do
		p="${pattern[i]}"
		echo -n "/^$p:/ && do { print $p; flush $p }; "
	done
	echo -n '/^main:get_config:/ && print ( (/^main:get_config:(.*)/), ":conf=$conf\n" ) ; '
	echo -n "/^main:quit/ && exit 0; "
	echo -n "/^main:set_config/ && last ; "
	echo -n '}; '
	echo -n "$readconfig2"
}

mkpipe "${to_loop##*/}"
mkpipe "${from_loop##*/}"


linebufferedcat <$to_loop >$from_loop &

export stdin stdout

{
	mktask "mod" "./mod.sh"
	mktask "user" "./user.sh"
} >$to_loop


{ icmds; cat <$from_loop; } | tee log/bad-$$ | # tee  >(cat >&$stdout) |
perl -e 'use v5.10; use IO::Handle; $|++; '"$readconfig1$readconfig2" >&$to_loop

rm -r "$PIPEDIR"

echo main loop terminated
