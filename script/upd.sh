#!/bin/bash

dir=crazy_pipework/bin
user=~pipework
cd $user/$dir
for i in *
do
	if [ "$1" = "-c" ]
	then
		cp $i $user/chroot/$dir
	else
		echo "In file $i:"
		diff $i $user/chroot/$dir/$i
	fi
done
