#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2010 lantiq.com
START=68

. $IPKG_INSTROOT/lib/falcon.sh

log() {
	logger -s -p daemon.err -t "[onu]" "$*" 2> /dev/console
}

onu () {
	#echo "onu $*"
	result=`/opt/lantiq/bin/onu $*`
	#echo "result $result"
	status=${result%% *}
	if [ "$status" != "errorcode=0" ]; then
		log "onu $* failed: $result"
	fi
}

ssb_check() {
	local result

	# wait until ONU CLI is ready, just wait 1min
	sleep 60
	echo "start ssb check" > /tmp/ssb_check.txt

	#check for RAR in uboot variables
	store=`fw_printenv rar`
	test=`echo $store | grep "rar="`
	if [ -n "$test" ]; then
		rar=${test#*rar='"'}
		rar=${rar%%'"'}
		onu onu_rar_set $rar
		echo "uboot vars -> init RAR: $test" >> /tmp/ssb_check.txt
	else
		echo "no RAR setting stored in uboot vars" >> /tmp/ssb_check.txt
	fi
	
	while (true) ; do
		sleep 1

		onu onu_ssb_check 8 0
		test=`echo $result | grep "damaged_cnt=0"`

		if [ -z "$test" ]; then
			# damaged_cnt > 0 !
			echo "onu_ssb_check: $result" >> /tmp/ssb_check.txt
			log "SSB error found"
			fw_setenv ssb_error_found 1
			
			if [ "$status" = "errorcode=0" ]; then
				onu onu_rar_get

				if [ "$status" = "errorcode=0" ]; then
					rar=${result#*rar=}

					fw_setenv rar $rar
					echo "RAR -> uboot vars: $rar" >> /tmp/ssb_check.txt
					log "SSB error covered by RAR"
				fi
			fi
		fi
	done
}

start() {
	# ssb_check &
}
