#!/bin/bash

declare -A mod_by_group
declare -A group

sys_net_join()				# args: group, pgid_of_sender
{
	[[ "${group["$1"]}" =~ (^| )$2($| ) ]] ||
	{
		group["$1"]+=" $2"
		echo "net:rejoin:$1"
		echo "${mod_by_group[$1]}:net:new:$2"
	}
}

sys_net_leave()				# args: group, pgid_of_sender
{
	unset group["$1"]
	group["$1"]="${!t/"$2"/}"
}

net_join()				# args: group, module_name
{
	mod_by_group["$1"]="$2"
	for i in "$pdir/../"[0-9]*/net
	do
		echo "net:sys_join:$1:${pdir##*/}" > "$i"
	done
}

rejoin()				# args: group, pgid_of_sender 
{
	for i in "$pdir/../"[0-9]*/net
	do
		echo "net:sys_rejoin:$1:${pdir##*/}" > "$i"
	done
}

sys_net_rejoin()				# args: group, pgid_of_sender
{
	[[ "${group["$1"]}" =~ (^| )$2($| ) ]] ||
	{
		group["$1"]+=" $2"
		echo "${mod_by_group[$1]}:net:new:$2"
	}
}

net_leave()				# args: group
{
	unset mod_by_group[$1]
	echo "net:sys_leave:$1:${pdir##*/}" > "$pdir/net"
}

net_send()				# args: group, pgid_of_sender(??), msg
{
	local t=group["$1"]
	for i in ${!t}
	do
		echo "net:gr:$1:$2:$3" > "$pdir/../$i/net"
	done
}

net_recv()				# args: group, pgid_of_sender(??), msg
{
	echo "${mod_by_group[$1]}:net:msg:$2:$3"
}

proc_cmd()
{
	case "$1" in
	net:join:*) net_join "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" ;;
	net:leave:*) net_leave "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" ;;
	net:send:*) net_send "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" "`cut -d: -f5 <<<"$1"`" ;;
	net:gr:*) net_recv "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" "`cut -d: -f5 <<<"$1"`" ;;
	net:sys_join:*) sys_net_join "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" ;;
	net:sys_leave:*) sys_net_leave "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" ;;
	net:rejoin:*) rejoin "`cut -d: -f3 <<<"$1"`" ;;
	net:sys_rejoin:*) sys_net_rejoin "`cut -d: -f3 <<<"$1"`" "`cut -d: -f4 <<<"$1"`" ;;
	net:init*) echo "mod:ready:net" ;;
	esac
}

#echo "mod:use:blah blah"

while read cmd; do proc_cmd "$cmd"; done
