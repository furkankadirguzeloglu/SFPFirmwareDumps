#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2014 lantiq.com

. $IPKG_INSTROOT/lib/falcon.sh

START=40

file="/etc/fw_env.config"
# list of supported partition names
part_names="uboot_env Env"

get_uboot_mtd_part() {
	local LINE="$(grep "\"$1\"" /proc/mtd )"
	echo "$LINE"
}

new_write_fw_env_config() {
	local PART=`echo ${1} | cut -d: -f1`
	local part_size=${2}
	local erase_size=${3}
	local env_size="0x10000"
	local PREFIX=/dev/mtd
	local REDUNDANT=`expr ${erase_size} \< ${part_size}`
	local half_part_size=$(printf "%x" $(expr $(printf "%d" 0x$part_size) / 2))

	PART="${PART##mtd}"
	[ -d /dev/mtd ] && PREFIX=/dev/mtd/
	PART="${PART:+$PREFIX$PART}"

	echo "# MTD device name;Device offset;Env. size;Flash sector size" > $file
	echo "# board: $(falcon_board_name)" >> $file
	echo "$PART 0x0 $env_size 0x$erase_size" >> $file
	[ $REDUNDANT -ne 0 ] && \
		echo "$PART 0x$half_part_size $env_size 0x$erase_size" >> $file
}

boot() {
	local part
	local UENV
	for part in $part_names; do
		if [ ! -e $file ]; then
			UENV="$(get_uboot_mtd_part ${part})"
			if [ -n "$UENV" ]; then
				new_write_fw_env_config ${UENV}
			fi
		fi
	done
	insmod i2c-dev
	insmod i2c-gpio-custom bus0=0,37,38,5
}
