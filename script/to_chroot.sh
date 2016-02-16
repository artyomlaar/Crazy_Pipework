#!/bin/bash
/usr/sbin/chroot --userspec=$CHROOTUID:$CHROOTGID chroot/ bash -c 'cd crazy_pipework; XSID='$XSID' ./main'
clear
reset
