#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2011 lantiq.com
START=94
flag=1

USE_PROCD=1

start_service() {
	procd_open_instance
	procd_set_param respawn

	iopmaskget=`/sbin/uci get gpon.onu.iopmask`

	if [ "$iopmaskget" == "1" ]; then
		procd_set_param command /opt/lantiq/bin/vlanexec.sh
	else
		logger -t "[iop]" "Normalized ITU standard"
	fi
    
	procd_set_param stdout 1
	procd_set_param stderr 1
	procd_close_instance
}
