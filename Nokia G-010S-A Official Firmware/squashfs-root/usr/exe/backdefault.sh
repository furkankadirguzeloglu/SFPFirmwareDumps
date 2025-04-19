#!/bin/sh

format_partition()
{
	echo "MSG: format partition $1 ..."
	configfs_mtd=$(cat /proc/mtd  | grep configfs | awk '{print $1}' |sed 's/mtd/mtdblock/'|sed 's/://')
	logfs_mtd=$(cat /proc/mtd  | grep logfs | awk '{print $1}' |sed 's/mtd/mtdblock/'|sed 's/://')

	echo "MSG: format partition $1 starting ..."
	
	if [ "X$1" = "Xconfigs" ]; then
		umount /configs
		cn=`echo $configfs_mtd | cut -c 9 `
		mtd erase /dev/mtd$cn
		rm /tmp/mount.log 2>/dev/null
		echo "format configs parition and mount again" >> /tmp/mount.log
		mtd jffs2write /tmp/mount.log /dev/mtd$cn
		mount -t jffs2  /dev/$configfs_mtd /configs
		source /usr/exe/first_boot.sh
	fi

	if [ "X$1" = "Xlogs" ]; then
		umount /logs
		ln=`echo $logfs_mtd | cut -c 9 `
		mtd erase /dev/mtd$ln
		rm /tmp/mount.log 2>/dev/null
		echo "format logs parition and mount again" >> /tmp/mount.log
		mtd jffs2write /tmp/mount.log /dev/mtd$ln
		mount -t jffs2  /dev/$logfs_mtd /logs
	fi

	echo "MSG: format partition $1 done ..."
}

backup_files()
{
	if [ "X$1" = "Xlogs" ] && [ "X$2" = "Xconfigs" ]; then
		srcdir=/logs/configs_key_data_bak
		dstdir=/configs
	elif [ "X$1" = "Xconfigs" ] && [ "X$2" = "Xlogs" ]; then
		srcdir=/configs
		dstdir=/logs/configs_key_data_bak
	else
		exit 1
	fi

	mkdir /logs/configs_key_data_bak &>/dev/null
	echo "MSG: backup ${srcdir} to ${dstdir} ..."
	cat /usr/cfg/vendor_meta.lst | while read line
	do
		if [ -f ${srcdir}/${line} ]; then
			cp ${srcdir}/${line} ${dstdir}/ -af
		fi
	done

	if [ "X$3" != "Xdepth" ]; then
		cat /usr/cfg/custom_meta.lst | while read line
		do
			if [ -f ${srcdir}/${line} ]; then
				cp ${srcdir}/${line} ${dstdir}/ -af
			fi
		done
	fi
	sync
	echo "MSG: backup ${srcdir} to ${dstdir} done ..."
}

ontType=`cat /usr/etc/buildinfo | grep ONT_TYPE | cut -c10-`
if [ "${ontType}" = "g010ga" ] || [ "${ontType}" = "g010pa" ]; then
	ls -A /configs > /tmp/remove.lst
	if [ -f /configs/flag.factory-default.dep ]; then
		echo "MSG: factory-default.dep ..."
		cat /tmp/remove.lst | while read line
		do
			grep "\<${line}\>" /usr/cfg/vendor_meta.lst || rm -rf /configs/${line}
		done
		echo "MSG: factory-default.dep done ..."
	elif [ -f /configs/flag.factory-default ]; then
		echo "MSG: factory-default ..."
		cat /tmp/remove.lst | while read line
		do
			grep "\<${line}\>" /usr/cfg/vendor_meta.lst || grep "\<${line}\>" /usr/cfg/custom_meta.lst || rm -rf /configs/${line}
		done
		echo "MSG: factory-default done ..."
	fi

	rm -rf /tmp/remove.lst
	sync
	exit 0;
fi

if [ -f /configs/flag.factory-default.dep ]; then
	rm -rf /configs/flag.factory-default /configs/flag.format /configs/flag.backup*
	format_partition logs force
	backup_files configs logs depth
	touch /logs/flag.format
	touch /logs/flag.backup.dep
	sync
fi

if [ -f /configs/flag.factory-default ]; then
	rm -rf /configs/flag.format /configs/flag.backup*
	format_partition logs
	backup_files configs logs
	touch /logs/flag.format
	touch /logs/flag.backup
	sync
fi

if [ -f /logs/flag.factory-default.dep ]; then
	rm -rf /logs/flag.factory-default /logs/flag.format /logs/flag.backup*
	backup_files configs logs depth
	format_partition configs force
	backup_files logs configs depth
	touch /configs/flag.format
	touch /configs/flag.backup.dep
	sync
fi

if [ -f /logs/flag.factory-default ]; then
	rm -rf /logs.format /logs/flag.backup*
	backup_files configs logs
	format_partition configs
	backup_files logs configs
	touch /configs/flag.format
	touch /configs/flag.backup
	sync
fi

if [ -f /configs/flag.format ]; then
	if [ ! -f /configs/flag.backup ] && [ ! -f /configs/flag.backup.dep ]; then
		touch /configs/flag.backup
	fi

	if [ -f /configs/flag.backup ]; then
		format_partition logs
		backup_files configs logs
		rm -rf /configs/flag.backup
	else
		format_partition logs force
		backup_files configs logs depth
		rm -rf /configs/flag.backup.dep
	fi

	rm -rf /configs/flag.format
	sync
fi

if [ -f /logs/flag.format ]; then
	if [ ! -f /logs/flag.backup ] && [ ! -f /logs/flag.backup.dep ]; then
		touch /logs/flag.backup
	fi

	if [ -f /logs/flag.backup ]; then
		format_partition configs
		backup_files logs configs
		rm -rf /logs/flag.backup
	else
		format_partition configs force
		backup_files logs configs depth
		rm -rf /logs/flag.backup.dep
	fi

	rm -rf /logs/flag.format
	sync
fi
