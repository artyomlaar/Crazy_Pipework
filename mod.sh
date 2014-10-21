#!/bin/bash

while='while(<STDIN>){ '
end=' /^main:get_config:/ && print ( (/^main:get_config:(.*)/), ":conf=$conf\n" ) ; /^main:quit/ && exit 0; /^main:set_config/ && last ; }; s/^main:set_config://; $conf=$_; print "evaling\n"; eval $conf;'

declare -A pid pipe 


md_set_io()
{
	stdin="`cut -d: -f1 <<<"$1"`"
	stdout="`cut -d: -f2 <<<"$1"`"
}

md_give_stdin()
{
	echo "$1:stdin=$stdin"
}
md_give_stdout()
{
	scr_writers+="$1 "
	echo "$1:stdout=$stdout"
	if [ $outpipe ]
	then
		echo "$1:set_new_output:$outpipe"
	fi
}
mkconfig()
{
	for file in "${close[@]}"
	do
		echo -n "close $file; "
	done

	for file in "${open[@]}"
	do
		echo -n "open $file, \">${pipe[$file]}\"; "
	done

	echo -n "$while"

	for address in "${mod[@]}"
	do
	       echo -n "/^$address:/ && do { print $address; flush $address; next }; "
	done

	echo -n "$end"
}

md_load()
{
	pipe[$1]="$pdir/$1"
	[ -p "${pipe[$1]}" ] || mkfifo "${pipe[$1]}" 
	./$1.sh <$pdir/$1 &
	pid[$1]=$!
	open="$1"
	mod[${#mod[@]}]=$1 
	echo "main:set_config:`mkconfig`"
	echo "$1:init"
	open=()
}
mod_use_step()
{
		[ -z "$tmp_use_mods" ] && 
		{
			echo "user:init"
			return
		}
		cur_mod="${tmp_use_mods%%&&*}"
		echo "mod:load:$cur_mod"
		
		[[ "$tmp_use_mods" =~ "&&" ]] || tmp_use_mods=""
		tmp_use_mods="${tmp_use_mods#*&&}"
}
set_piped_output()
{
	outpipe="$pdir/all_output"
	mkfifo $outpipe
	echo "$1:all_output:$outpipe:$stdout"
	for i in $scr_writers
	do
		echo "$i:set_new_output:$outpipe"
	done
}
proc_cmd()
{
	case "$1" in
	mod:use:*) use_mods="`rm_ws "${1#mod:use:}"`";
		 tmp_use_mods="$use_mods"; mod_use_step;;
	mod:load:*) md_load "${1#mod:load:}";;
	mod:ready:*) mod_use_step;;
	mod:free:*) :;;
	mod:add:*) :;;
	mod:use:*) md_use "${1#mod:use:}";;
	mod:get_stdin:*) md_give_stdin "${1#mod:get_stdin:}";;
	mod:get_stdout:*) md_give_stdout "${1#mod:get_stdout:}";;
	mod:set_io:*) md_set_io "${1#mod:set_io:}";;
	mod:set_piped_output:*) set_piped_output "${1#mod:set_piped_output:}";;
	esac
}
mod_init()
{
	mod[${#mod[@]}]=user; pipe[user]="$pdir/user"; pid[user]=$$
	# FIXME: wrong pid 
	mod[${#mod[@]}]=mod; pipe[user]="$pdir/mod"; pid[mod]=$$ 
}

mod_init

while read cmd; do proc_cmd "$cmd"; done
