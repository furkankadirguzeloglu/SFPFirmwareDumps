#!/bin/sh

pipe_no=0

# use specified pipe no
case "$1" in
	0|1|2)
		pipe_no=$1; shift; ;;
esac

while true
do
	if [ -f "/tmp/ocal_lock" ]; then
		sleep 1
		continue
	else
		echo $$ > /tmp/ocal_lock
		echo $* > /tmp/pipe/ocal_${pipe_no}_cmd
		result=`cat /tmp/pipe/ocal_${pipe_no}_ack`
		rm -f /tmp/ocal_lock
	fi
done
echo "$result"
