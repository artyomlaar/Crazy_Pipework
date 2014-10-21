#!/bin/bash

cd `dirname $0`

INAME=game
inc=1
max=`ls ./games|wc -l`
min=1
a=1

game_from_id()
{
	ls ./games/ | tail -n +$1 | head -n 1
}

drawmenu()
{
	echo scr:print:`clear``tput bold`
	echo -e "scr:print:\e[2;20H $max IN 1\e[2E"

	for ((i=min; i<=max; i++ ))
	do 
		echo -e "scr:print:\e[15C$([ $i = $a ] && echo -e "\e[2D-\e[C")$i `game_from_id $i | xargs -i basename {} .sh |tr a-z A-Z`\e[1E"
	done
}

proc_cmd()
{
	if [[ $1 =~ ^game:key=.* ]]
	then
		k=`echo $1 | sed 's/^game:key=\(.*\)/\1/'`
		if [ "$k" = "w" -a $a -gt $min ]
		then
			((a--))
		elif [ "$k" = "s" -a $a -lt $max ]
		then
			((a++))

		elif [ "$k" = "1" ]
		then
			./games/`game_from_id $a`
		elif [ "$k" = "q" ]
		then
			echo "scr:print:$(tput sgr0; clear)"
			echo -e "scr:print:\x01exit\x02"
			kill -2 -- 0 #-`ps --no-headers  p $$ -o %r`
			exit
		fi
		drawmenu
	fi
}

drawmenu

while read command; do proc_cmd $command; done


