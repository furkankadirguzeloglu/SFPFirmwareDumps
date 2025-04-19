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

generate_custom_mib()
{
	vendor_id=`uci get sys.mib.vendor_id` || return 1
	ont_version=`uci get sys.mib.ont_version` || return 1
	equipment_id=`uci get sys.mib.equipment_id` || return 1

	mibsrc='/etc/mibs/nameless.ini'
	mibtgt='/etc/mibs/custom.ini'

	if [ ! -f ${mibsrc} ]; then
		exit 1
	fi

	if [ -f ${mibtgt} ]; then
		rm -f ${mibtgt}
	fi

	cp ${mibsrc} ${mibtgt}
	echo "# ONT-G" >> ${mibtgt}
	echo "256 0 ${vendor_id} ${ont_version} 00000000 2 0 0 0 0 #0" >> ${mibtgt}
	echo "# ONT2-G" >> ${mibtgt}
	echo "257 0 ${equipment_id} 0xa0 0 1 1 64 64 1 128 0 0x007f 0 0 48" >> ${mibtgt}
}

start() {
  (
	local mib_file
	local omcc_version
	local tmp
	local omci_iop_mask
	local lct=""

	is_flash_boot && wait_for_jffs

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

	
	mc=`uci get sys.features.mib_customized` || return 1
	if [ ${mc} == '1' ]; then
		generate_custom_mib
		config_set mib_file "default" "mib_file" ${mib_file}
		mib_file='/etc/mibs/custom.ini'
	fi

	logger -t omcid "Use OMCI mib file: $mib_file"
	${OMCID_BIN} -d3 -p$mib_file  -o$omcc_version -i$omci_iop_mask ${lct} > /dev/console 2> /dev/console &
  )&
}

stop() {
	killall -q omcid
}
