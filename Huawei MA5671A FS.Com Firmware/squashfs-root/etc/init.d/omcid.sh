#!/bin/sh /etc/rc.common
# Copyright (C) 2011 OpenWrt.org
# Copyright (C) 2011 lantiq.com

. $IPKG_INSTROOT/lib/falcon.sh

START=85

OMCID_BIN=/opt/lantiq/bin/omcid

status_entry_create() {
	local path=$1
	local base=`basename $path`
	local dir=`dirname $path`

	touch $path

	uci -c $dir set $base.ip_conflicts=status
	uci -c $dir set $base.dhcp_timeouts=status
	uci -c $dir set $base.dns_errors=status
}

wait_for_jffs()
{
	while ! grep overlayfs:/overlay /proc/self/mounts >/dev/null
	do
		sleep 1
	done
}

is_flash_boot()
{
	grep overlayfs /proc/self/mounts >/dev/null
}

start() {
  #(
	local mib_file
	local omcc_version
	local tmp
	local omci_iop_mask
	local lct=""

	config_load omci
	
	tmp=`fw_printenv omci_hw_ver 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		sed "s/256 0 HWTC 0000000000000/256 0 HWTC ${tmp}/" /rom/etc/mibs/data_1g_8q_us1280_ds512.ini > /tmp/auto_generated_mib.ini
		mib_file="/tmp/auto_generated_mib.ini"
	else
		mib_file="/rom/etc/mibs/data_1g_8q_us1280_ds512.ini"
	fi

	tmp=`fw_printenv mib_file_custom 2>&- | cut -f2 -d=`
	if [ -f "/etc/mibs/$tmp" ]; then
		mib_file="/etc/mibs/$tmp"
	fi
	
	tmp=`fw_printenv omci_omcc_ver 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		omcc_version=$tmp
	else
		omcc_version=160
	fi

	config_get tmp "default" "status_file" "/tmp/omci_status"
	status_entry_create "$tmp"

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
	${OMCID_BIN} -d3 -p$mib_file  -o$omcc_version -i$omci_iop_mask ${lct} -l/tmp/log/debug > /dev/console 2> /dev/console &
  #)&
}

stop() {
	killall -q omcid
}
