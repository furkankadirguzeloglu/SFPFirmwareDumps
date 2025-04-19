#!/bin/sh

pipe_no=0

# use specified pipe no
case "$1" in
	0|1|2)
		pipe_no=$1; shift; ;;
esac

while true
do
	if [ -f "/tmp/omci_lock" ]; then
		sleep 1
		continue
	else
		echo $$ > /tmp/omci_lock
		echo "$*" > /tmp/pipe/omci_${pipe_no}_cmd
		result=`cat /tmp/pipe/omci_${pipe_no}_ack`
		rm -f /tmp/omci_lock
		break
	fi
done

echo "$result"
