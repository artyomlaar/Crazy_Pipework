#!/bin/bash

exec {savedstdout}>&1

INAME=curses

init_srv()
{

	: #echo -e "\e[?25l" # - HIDES CURSOR
}
onexit()
{

	: #echo -e "\e[?25h" # - SHOWS CURSOR
}

proc_cmd()
{
	if [[ $1 =~ ^curses:init ]]
	then
		echo "mod:get_stdout:curses"
		wait_for curses:stdout= stdout
		init_srv >&$stdout
		echo "mod:ready:curses"
		perl -e '$|++; while(<>){ if (/^curses:set_new_output:.*/){ exit }; s/^curses:/\x01curses:/; s/$/\x02/; chomp; print }' >&$stdout
		perl -e '$|++; while(<>){ s/^curses:/\x01curses:/; s/$/\x02/; chomp; print }' >$pdir/all_output
		return
	fi
}

#echo "mod:use:blah blah"


trap 'onexit' EXIT INT QUIT TERM

while read command; do proc_cmd "$command"; done

onexit
exit
