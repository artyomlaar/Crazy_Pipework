#!/bin/bash

exec {savedstdout}>&1


cd "`dirname $0`"
INAME=user
inc=1
max=80
min=1
a=5

gswidth=80
gsheight=24
delay=1
hit=0
miss=0
bulletchar=*
saucerchar=*
shipchar=m
let b=0

initscr()
{
	echo curses:bkgd:stdscr:1:6
	echo curses:clear
	echo curses:spr:ship:1:1
	echo curses:prc:ship:0:0:7:6:$shipchar
	drawship
}

fixthrash()
{
	./fixthrash.sh
}

flyoutofscreen()
{
	((flies[$1]=0))
	((miss++))
}


shothit()
{
	((flies[$1]=0))
	((shots[$1]=0))
	((hit++))
}

drawship()
{
	echo curses:mvs:ship:$((a-1)):$((gsheight-1))
	echo curses:ref
}

render()
{
	echo "curses:clear"
	echo "curses:prc:stdscr:19:1:6:1:$hit HIT, $miss MISSED, $c SECONDS, b=$b"	
	for (( i=1; i<=gswidth; i++ ))
	do
		if ((flies[i])); 
		then
			echo "curses:prc:stdscr:$((i-1)):$((flies[i]-1)):1:6:$saucerchar"
		fi
	done

	for (( i=1; i<=gswidth; i++ ))
	do
		if ((shots[i]))
		then
			echo "curses:prc:stdscr:$((i-1)):$((shots[i]-1)):3:6:$bulletchar"
		fi
	done

	drawship
}

mvshipleft()
{
	drawship
	echo -e "out:print:_"
}

mvshipright()
{
	echo -e "_"
	drawship
}
addfly()
{
	local a
	while :
	do
		a=$((RANDOM%gswidth))
		((flies[a])) || { ((flies[a]++)); break; }
	done
}
upd()
{
	for (( i=1; i<=gswidth; i++ ))
	do
		if ((shots[i])); then ((shots[i]--)); fi 
		if ((shots[i] && (shots[i]==flies[i] || shots[i]+1==flies[i]) ))
		then 
			shothit $i 
		fi
	done	


	for (( i=1; i<=gswidth; i++ ))
	do
		if ((flies[i])); then ((flies[i]++)); fi
		if ((flies[i]>=gsheight)); then flyoutofscreen $i; fi
	done	

	if ((RANDOM%c>5))
	then
		addfly
	fi
	render

	{ sleep $delay; echo "user:update"; } &
}

proc_cmd()
{

	if [[ $1 =~ ^user:key=.* ]]
	then
		k=`echo $1 | sed 's/^user:key=\(.*\)/\1/'`
		if [ "$k" = "a" -a $a -gt $min ]
		then
			((a--))
			drawship
		elif [ "$k" = "d" -a $a -lt $max ]
		then
			((a++))
			drawship
		elif [ "$k" = "b" ]
		then
			echo "net:send:galaxnet:0:+"
		elif [ "$k" = "B" ]
		then
			echo "net:join:galaxnet:user"
		elif [ "$k" = "q" ]
		then
			echo "out:print:$(tput sgr0; clear)"
			echo -e "out:print:\x01exit\x02"
			exit
		elif [ "$k" = "Q" ]
		then
			echo "out:print:$(tput sgr0; clear)"
			echo -e "out:print:\x01exit\x02"
		elif [ "$k" = "6" ]
		then
			addfly
		elif [ "$k" = "1" ]
		then
			((shots[a]=gsheight-2))
			render
		elif [ "$k" = "x" ]
		then
			fixthrash
		elif [ "$k" = "m" ]
		then
			./menu.sh
			upd
		elif [ "$k" = "u" ]
		then
			echo "user:update"
		elif [ "$k" = "o" ]
		then
			echo -e "out:print:\x01music:start:mus:pause\x02"
		elif [ "$k" = "i" ]
		then
			echo -e "out:print:\x01music:on\x02"
		elif [ "$k" = "I" ]
		then
			echo -e "out:print:\x01music:off\x02"
		elif [ "$k" = "r" ]
		then
			echo "main:get_config:user"
			read -r servconfig
			servconfig="${servconfig#user:conf=}"
			echo "main:set_config:${servconfig##*file\";}"
			echo "nc====main:set_config:${servconfig##*file\";}" >&2
			echo -ne "out:print:\e[31m"
			echo "main:config:${servconfig##*file\";}"
			sleep 10
		elif [ "$k" = "R" ]
		then
			local c
			echo "main:get_config:user"
			read -r c
			echo -ne "out:print:\e[31m"
			echo "${c}"
			sleep 3
		elif [ "$k" = "f" ]
		then
			echo "mod:use:mddb"
		fi

	elif [[ $1 =~ ^user:update.* ]]
	then
		upd $((c++))
	elif [[ "$1" =~ ^user:init.* ]]
	then
		sleep .1
		echo "out:send_cli_cmd:curses:start"
		echo "curses:cstart"
		initscr
		upd 1
		echo -e "file:offer:mus:$PWD/../data/music.mod:mod"
	elif [[ "$1" =~ ^user:net:msg ]]
	then
		let b++
	fi
}

echo "mod:use:out&&in&&net&&file&&curses"

while read command; do proc_cmd "$command"; done 

