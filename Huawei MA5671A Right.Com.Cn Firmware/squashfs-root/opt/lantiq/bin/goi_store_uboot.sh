#!/bin/sh

CONFIG_FILE='/etc/goiupgrade.conf'
ENV_VARIABLE='goi_config'
FILE_LIST=""

if [ -f ${CONFIG_FILE} ]
then
	for i in `cat ${CONFIG_FILE}`; do
		if [ -f /$i ]
		then
			FILE_LIST="$FILE_LIST $i"
		fi
	done
fi

if [ -f /etc/fw_env.config ]
then
	fw_setenv ${ENV_VARIABLE} `tar cz -C / ${FILE_LIST} | uuencode -m ${ENV_VARIABLE} | tr '\n' '@'`
fi

logger -t "[goi_store_uboot]" "Files packed into uboot variables: $FILE_LIST."
