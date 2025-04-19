#!/bin/sh /etc/rc.common
# Copyright (C) 2011 OpenWrt.org
# Copyright (C) 2011 lantiq.com
START=87

AGENT_BIN="/opt/lantiq/bin/gpon_dti_agent"
AGENT_ARGS="-p9000"

start() {
	OperatorID=$(ritool get OperatorID | awk -F ':' '{print $2}');
	if [ $OperatorID = "0000" ];then
		start-stop-daemon -S -x $AGENT_BIN -b -- $AGENT_ARGS
	fi
}

stop() {
	OperatorID=$(ritool get OperatorID | awk -F ':' '{print $2}');
	if [ $OperatorID = "0000" ];then
		start-stop-daemon -K -x $AGENT_BIN
	fi
}
