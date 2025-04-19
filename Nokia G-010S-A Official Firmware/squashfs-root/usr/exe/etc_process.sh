#!/bin/sh

if [ -e /tmp/first_boot/first_boot_flag_etc_process ]; then
#	rm /tmp/first_boot/first_boot_flag_etc_process
	mkdir -p /configs/etc/
	cp -a /etc/static/* /configs/etc/
fi

# dealing with case '3X switch over to 5301'
#   since it's a switch over(or rollback), not upgrade,
#   there won't be first_boot flag
grep ONTUSER /etc/passwd | grep vtysh > /dev/null
if [ $? == 0 ]; then
    echo 2x/3x switch/rollback to 5x
    cp -a /etc/static/* /configs/etc/
fi
sync
