#!/bin/sh
#### /dev configuration deal with for the target system

SYS_SOCINFO="/proc/socinfo"
SYS_DEVTYPE=$(test -e ${SYS_SOCINFO} && cat ${SYS_SOCINFO} |grep -q 6858 && echo 6858)
SYS_DEV_CFG="/usr/cfg/dev.cfg${SYS_DEVTYPE}"

while read line
do
	test -z $(echo "$line" |sed "s/[ \t\r\n]//g" |sed "s/^#.*//g") && continue
	mknod ${line}
done < ${SYS_DEV_CFG}

