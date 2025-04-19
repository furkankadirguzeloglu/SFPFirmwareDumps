#!/bin/sh
#mount etc as tmpfs for R/W,ybzhang,2017.3.28
cp -rfd /etc /tmp/etc_tmp
mount tmpfs /etc -t tmpfs -o size=32m
mv /tmp/etc_tmp/* /etc
rm -rf /tmp/etc_tmp
sync
/usr/exe/cfgdev.sh
