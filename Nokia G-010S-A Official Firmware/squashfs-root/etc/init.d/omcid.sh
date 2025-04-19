#!/bin/sh /etc/rc.common
# Copyright (C) 2011 OpenWrt.org
# Copyright (C) 2011 lantiq.com

. $IPKG_INSTROOT/lib/falcon.sh

START=85

#OMCID_BIN=/opt/lantiq/bin/omcid
PORT_MGR_BIN=/sbin/portmgr
OMCI_MGR_BIN=/sbin/omciMgr
OMCI_PARSER_BIN=/sbin/parser
DAEMON_BIN=/usr/exe/daemon
MSGMGR_BIN=/sbin/msgmgr
DIAGNOSIS_BIN=/sbin/diagnosis
CFM_MGR_BIN=/sbin/cfmmgr

status_entry_create() {
	local path=$1
	local base=`basename $path`
	local dir=`dirname $path`

	touch $path

	uci -c $dir set $base.ip_conflicts=status
	uci -c $dir set $base.dhcp_timeouts=status
	uci -c $dir set $base.dns_errors=status
}

start() {
	local mib_file
	local omcc_version
	local tmp
	local omci_iop_mask
	local lct=""

	config_load omci

	tmp=`fw_printenv mib_file 2>&- | cut -f2 -d=`
	if [ -f "$tmp" ]; then
		mib_file="$tmp"
	else
		config_get mib_file "default" "mib_file" "/etc/mibs/voice_4g_8q.ini"
	fi

	config_get tmp "default" "status_file" "/tmp/omci_status"
	status_entry_create "$tmp"

	config_get omcc_version "default" "omcc_version" 160

	case $(uci -q get network.lct.ifname) in
	lct0)
		lct=-g1
		;;
	lct1)
		lct=-g2
		;;
	lct2)
		lct=-g3
		;;
	lct3)
		lct=-g4
		;;
	lct8)
		lct=-g9
		;;
	esac

	tmp=`fw_printenv omci_iop_mask 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		omci_iop_mask=$tmp
	else
		config_get omci_iop_mask "default" "omci_iop_mask" 0
	fi

	logger -t omcid "Use OMCI mib file: $mib_file"
	#${OMCID_BIN} -d3 -p$mib_file  -o$omcc_version -i$omci_iop_mask ${lct} > /dev/console 2> /dev/console &
	${PORT_MGR_BIN} > /dev/console 2> /dev/console &
	${OMCI_MGR_BIN} > /dev/console 2> /dev/console &
	${OMCI_PARSER_BIN} > /dev/console 2> /dev/console &
	${MSGMGR_BIN} > /dev/console 2> /dev/console &
	${DIAGNOSIS_BIN} > /dev/console 2> /dev/console &
	${CFM_MGR_BIN} > /dev/console 2> /dev/console &
	#${DAEMON_BIN} > /dev/console 2> /dev/console &

}

stop() {
	#killall -q omcid
	killall -q omciMgr
	killall -q parser
	killall -q cfmmgr
}
