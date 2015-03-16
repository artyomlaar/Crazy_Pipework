#!/bin/bash

export pdir=./pipe/$$
export STANDALONE_SERVER=1
main=./core.sh
port=8090
[ -d "$pdir" ] || mkdir "$pdir" 
[ -p "$pdir/netcat_send" ] || mkfifo "$pdir/netcat_send" 
[ -p "$pdir/netcat_recv" ] || mkfifo "$pdir/netcat_recv" 

$main            < "$pdir/netcat_send" > "$pdir/netcat_recv" & 
netcat -lp $port > "$pdir/netcat_send" < "$pdir/netcat_recv" 
