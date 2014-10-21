#!/bin/bash

exec {savedstdout}>&1

INAME=file
declare -A path

offer_file() # args: handle, filename, extension
{
	path[$1]="$2"
	echo "out:send_cli_cmd:file-offer:$1:$3:$(du -b "$2"|cut -f1):$(sha1sum "$2" | sed 's/^\(\S\+\).*/\1/')" 
}

send_file() # args: handle, from, count
{
	echo "out:send_cli_cmd:file:$1:$3"
	# FIXME: test vars
	dd bs=1 if=${path[$1]} skip=$2 count=$3 >&$stdout 2>/dev/null
}

proc_cmd()
{
	if [[ $1 =~ ^file:stdout=.* ]]
	then
		stdout=${1#"file:stdout="} 
		return
	fi

	if [[ $1 =~ ^file:offer ]] # args: handle, filename, extension
	then
		local   handle="$(cut -d: -f3 <<<"$1")"
		local filename="$(cut -d: -f4 <<<"$1")"
		local      ext="$(cut -d: -f5 <<<"$1")"
		offer_file "$handle" "$filename" "$ext"

		return
	fi

	if [[ $1 =~ ^file:send ]]
	then
		local handle="$(cut -d: -f3 <<<"$1")"
		local   from="$(cut -d: -f4 <<<"$1")"
		local  count="$(cut -d: -f5 <<<"$1")"

		send_file "$handle" "$from" "$count" 
	
		return
	fi

	if [[ $1 =~ ^file:accept: ]]
	then
		
		return
	fi

	if [[ $1 =~ ^file:reject: ]]
	then
		echo "user:file-status:${1##*:}:rejected"	
		return
	fi

	if [[ $1 =~ ^file:cached: ]]
	then
		echo "user:file-status:${1##*:}:ok"	
		return
	fi

	if [[ $1 =~ ^file:close: ]]
	then
		echo "user:file-status:${1##*:}:ok"	
		return
	fi

	if [[ $1 =~ ^file:init ]]
	then
		echo "mod:ready:file"
		return
	fi
}
#echo "mod:use:blah blah"

while read command; do proc_cmd "$command"; done

