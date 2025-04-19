#!/bin/sh /etc/rc.common
# Copyright (C) 2011 OpenWrt.org
# Copyright (C) 2011 lantiq.com
START=87

AGENT_BIN="/opt/lantiq/bin/gpon_dti_agent"
AGENT_ARGS="-p9000"

start() {
	local gDtiaGentEnable
	gDtiaGentEnable=`fw_printenv gDtiaGentEnable 2>&- | cut -f2 -d=`
	if [ -z "$gDtiaGentEnable" ]; then
		gDtiaGentEnable="false"
	fi

	if [ "$gDtiaGentEnable" == "true" ]; then          
		start-stop-daemon -S -x $AGENT_BIN -b -- $AGENT_ARGS
	fi
}

stop() {
	start-stop-daemon -K -x $AGENT_BIN
}
