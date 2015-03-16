#!/bin/bash
logpid=`ps --no-header -o sid -p $$ | xargs ps --no-header -o ppid`
sed -n /$logpid/'s/.*from=\(.*\)/\1/p' /var/log/xinetd 
