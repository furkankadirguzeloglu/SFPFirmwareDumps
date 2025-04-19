#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2011 lantiq.com
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.

#run fisrt_boot.sh
commit=`fw_printenv commit | awk -F "=" '{print $2}'`
ret=`cat /proc/mtd | grep image | awk -F ':' '{print $2}' | awk -F " " '{print $3}'`
value=`echo ${ret:6:1}`

if [ $value = '0' ];then
	active=1;
else
	active=0;
fi

if [ $commit -ne $active ];then
	echo "run first_boot.sh"
	/usr/exe/first_boot.sh
fi

current_build_date=`cat /usr/etc/buildinfo  | sed -n '/BUILDDATE/p' | awk -F = '{print $2}'`
if [ "$current_build_date" = "" ]; then
	echo "******* buildinfo format error!*******"
fi

if [ -f /configs/last_buildinfo_img$actived ]; then
	last_build_date=`cat /configs/last_buildinfo_img$actived  | sed -n '/BUILDDATE/p' | awk -F = '{print $2}'`
fi

if [ "$current_build_date" != ""$last_build_date"" ]; then
	/usr/exe/first_boot.sh
	cp -f /usr/etc/buildinfo  /configs/last_buildinfo_img$actived
fi

#just fix HDR5601/HDR57 BB247 bug for uboot env
if [ $active = 0 ];then
	image0_is_valid=`fw_printenv image0_is_valid | awk -F "=" '{print $2}'`
	fw_setenv image0_is_vaild 
	fw_setenv image1_is_vaild
	if [ $image0_is_valid = 0 ];then
		fw_setenv image0_is_valid 1
	fi	
fi

if [ $active = 1 ];then
	image1_is_valid=`fw_printenv image1_is_valid | awk -F "=" '{print $2}'`
	fw_setenv image0_is_vaild
	fw_setenv image1_is_vaild
	if [ $image1_is_valid = 0 ];then
		fw_setenv image1_is_valid 1
	fi	
fi

/etc/init.d/syslog start

mknod /dev/scfg c 70 0
insmod /lib/modules/3.10.49/scfg.ko
insmod /lib/modules/3.10.49/kigmp.ko
mknod /dev/igmpdrv c 75 2

insmod /lib/modules/3.10.49/hcfg.ko
mknod /dev/hcfg c 218 0

insmod /lib/modules/3.10.49/i2c-gpio-custom bus0=0,37,38,5
mknod /dev/i2c_driver c 247 0 
insmod /lib/modules/3.10.49/i2c_driver.ko

if [ ! -d "/logs/kmsg" ];then
	mkdir -p /logs/kmsg
fi
insmod /lib/modules/3.10.49/kmsg_collect.ko

source /usr/exe/configfs.sh
/usr/exe/daemon &

/sbin/lcfgmgr &

