#!/bin/sh
# Copyright (C) 2011 OpenWrt.org
# Copyright (C) 2011 lantiq.com

falcon_board_name() {
	local machine
	local name

	# take board name from cmdline
	name=$(awk 'BEGIN{RS=" ";FS="="} /boardname/ {print $2}' /proc/cmdline)
	[ -z "$name" ] && {
		# if not defined, use cpuinfo
		machine=$(awk 'BEGIN{FS="[ \t]+:[ \t]"} /machine/ {print $2}' /proc/cpuinfo)
		[ -z "$machine" ] && {
			# or directly the device tree
			[ -e /proc/device-tree/model ] && {
				machine=$(cat /proc/device-tree/model)
			}
		}
		# use first word in lower case
		name=$(echo $machine | awk '{print tolower($1);}')

		# to stay backward compatible, these names must be upper case:
		case "$name" in
		mdu)
			name="MDU"
			;;
		sfp)
			name="SFP"
			;;
		esac
	}

	echo "$name"
}

# return the (board specific) number of lan ports
falcon_get_number_of_lan_ports() {
	local num="4"

	case $(falcon_board_name) in
	SFP|easy98010|easy98035*)
		num="1"
		;;
	MDU2|MDU3|easy88384*|easy88388*)
		num="1"
		;;
	MDU*|easy98021)
		num="2"
		;;
	esac

	echo $num
}

# return the (board specific) default interface used for "lct"
falcon_default_lct_get() {
	if [ -f "/etc/config/.hgu" ]; then
		# HGU (lan, but no extra lct)
		echo ""
		return
	fi

	case $(falcon_board_name) in
	CTTDP*|easy98020_CTTDP8|GFAST*)
		echo "lctX"
		return
		;;
	*)
		if [ -f "/etc/config/.fttdp" ]; then
			# FTTDP
			echo "lct2"
			return
		fi
		;;
	esac

	case $(falcon_get_number_of_lan_ports) in
	1)
		echo "lct0"
		;;
	2)
		echo "lct1"
		;;
	*)
		echo "lct3"
		;;
	esac
}

falcon_sgmii_mode() {
	local retval="0"
	local sgmii_mode=`fw_printenv sgmii_mode 2>&- | cut -f2 -d=`

	case "$sgmii_mode" in
	1|sgmii)
		retval="1"
		;;
	2|sgmii_fast)
		retval="2"
		;;
	3|serdes)
		retval="3"
		;;
	4|serdes_noaneg)
		retval="4"
		;;
	5|sgmii_fast_auto)
		retval="5"
		;;
	esac
	echo $retval
}

falcon_base_mac_get() {
	local mac_env=$(awk 'BEGIN{RS=" ";FS="="} $1 == "ethaddr" {print $2}' /proc/cmdline)
	local mac_addr=`echo $mac_env | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'`
	if [ "${#mac_addr}" != "17" ]; then
		mac_addr='ac:9a:96:00:00:00'
	fi
	echo $mac_addr
}

falcon_mac_get() {
	local mac_offset
	local macm
	local off

	case "$1" in
	host)
		mac_offset=0
		;;
	lan1)
		mac_offset=1
		;;
	lct*|lan|lan0)
		mac_offset=2
		;;
	wan)
		mac_offset=3
		;;
	*)
		mac_offset=-1
		;;
	esac

	macm=`echo $(falcon_base_mac_get) | cut -f5 -d:`
	if [ "$macm" == "ff" ] || [ "$macm" == "FF" ] || [ "$macm" == "fF" ] || [ "$macm" == "Ff" ] || [ "$macm" == "fe" ] || [ "$macm" == "FE" ] || [ "$macm" == "fE" ] || [ "$macm" == "Fe" ]; then
		off=-
	else
		off=+
	fi

	[ $mac_offset -ge 0 ] && \
		echo $(falcon_base_mac_get) | awk -v offs=$mac_offset 'BEGIN{FS=":"} {printf "%s:%s:%s:%s:%02x:%s\n", $1,$2,$3,$4,("0x"$5)'$off'offs,$6}'
}

falcon_oui_get() {
	echo $(falcon_base_mac_get) | awk 'BEGIN{FS=":"} {printf "%s:%s:%s\n", $1,$2,$3}'
}

falcon_asc0_pin_mode() {
	local retval="0"
	local asc0_mode=`fw_printenv asc0 2>&- | cut -f 2 -d '='`

	case "$asc0_mode" in
	0|1|2|3)
		retval="$asc0_mode"
		;;
	esac
	echo $retval
}

falcon_olt_type_get() {
	local tmp
	local olt_type

	tmp=`fw_printenv olt_type 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		olt_type=$tmp
	else
		config_load gpon
		config_get olt_type "default" "olt_type" 0
	fi

	echo $olt_type
}

falcon_ploam_emergency_stop_state_get() {
	local retval="0"
	local state=`fw_printenv ploam_emergency_stop_state 2>&- | cut -f 2 -d '='`

	case "$state" in
	0)
		retval="0"
		;;
	1)
		retval="1"
		;;
	esac
	echo $retval
}

falcon_goi_calibrated_get() {
	local retval="0"
	local goi_calibrated=`fw_printenv goi_calibrated 2>&- | cut -f 2 -d '='`

	case "$goi_calibrated" in
	0)
		retval="0"
		;;
	1)
		retval="1"
		;;
	esac
	echo $retval
}

