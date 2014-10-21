#!/bin/bash

exec {savedstdout}>&1

INAME=out

init_srv()
{

	echo -e "\e[?25l" # - HIDES CURSOR
}
onexit()
{

	echo -e "\e[?25h" # - SHOWS CURSOR
}

send_cli_cmd()
{
	echo -ne "\x01$1\x02" >&$stdout
}

telnet_set_raw()
{
	echo -n $'\377\372\042\001\000\377\360'
	echo $'\377\375\42\377\373\001'

}

telnet_unset_raw()
{
	echo -n $'\377\374\001'
	echo -n $'\377\372\042\001\001\377\360'
	#sb=\372
	#se=\360
}

set_new_output()
{
	exec {stdout}>"$1"
}
 
proc_cmd()
{
	if [[ $1 =~ ^out:print:.* ]]
	then
		echo -ne "${1#"out:print:"}" >&$stdout
		return
	fi

	if [[ $1 =~ ^out:printe:.* ]]
	then
		echo -ne "${1#"out:printe:"}" >&$stdout
		return
	fi

	if [[ $1 =~ ^out:telnet_set_raw ]]
	then
		telnet_set_raw >&$stdout
		return
	fi

	if [[ $1 =~ ^out:telnet_unset_raw ]]
	then
		telnet_unset_raw >&$stdout
		return
	fi

	if [[ $1 =~ ^out:cat-client ]]
	then
		cat ./client.sh >&$stdout
		return
	fi

	if [[ $1 =~ ^out:set_new_output ]]
	then
		set_new_output "${1#"out:set_new_output:"}"
		return
	fi

	if [[ $1 =~ ^out:send_cli_cmd ]]
	then
		send_cli_cmd "${1#"out:send_cli_cmd:"}"
		return
	fi

	if [[ $1 =~ ^out:init ]]
	then
		echo "mod:get_stdout:out"
		wait_for out:stdout= stdout
		init_srv >&$stdout
		echo "mod:ready:out"
		return
	fi
}

#echo "mod:use:blah blah"

trap 'onexit' EXIT INT QUIT TERM

while read command; do proc_cmd "$command"; done

onexit
exit
