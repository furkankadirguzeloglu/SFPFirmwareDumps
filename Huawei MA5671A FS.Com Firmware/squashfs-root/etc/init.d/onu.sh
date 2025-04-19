#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2010 lantiq.com
START=61

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

ploam_config() {
	local onu_serial

	tmp=`fw_printenv onu_serial 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		onu_serial="$tmp"
	else
		# create out of lantiq OID and ether mac the serial number
		logger -t "[onu]" "Using fallback ONU serial generated with ether mac"
		ethaddr=$(awk 'BEGIN{RS=" ";FS="="} $1 == "ethaddr" {print $2}' /proc/cmdline)
		onu_serial=$(echo $ethaddr | awk 'BEGIN{FS=":"} {print "SPTC"$3""$4""$5""$6""}')
	fi
	
	onu ploam_init
	logger -t "[onu]" "Using ploam serial number: $onu_serial"
	onu gtcsns $onu_serial
}


generate_ploam_password_hex() {
    local ploam_string=$1
    local ploam_len=${#ploam_string}

    # We have to add NUL (0x00) characters to the end of the ploam if it is less than 10 characters
    for c in $(seq $ploam_len 9); do
        ploam_string="${ploam_string}\x00"
    done

    # Return ploam in hex
    echo -ne "${ploam_string}" | hexdump -v -e '/1 "0x%02X "' | xargs
}

#
# bool bDlosEnable
# bool bDlosInversion
# uint8_t nDlosWindowSize
# uint32_t nDlosTriggerThreshold
# uint8_t nLaserGap
# uint8_t nLaserOffset
# uint8_t nLaserEnEndExt
# uint8_t nLaserEnStartExt
#
# GTC_powerSavingMode_t ePower
#    GPON_POWER_SAVING_MODE_OFF = 0
#    GPON_POWER_SAVING_DOZE = 1,
#    GPON_POWER_SAVING_CYCLIC_SLEEP = 2,
#    GPON_POWER_SAVING_WATCHFUL_SLEEP = 4,
#
gtc_config() {
	local bDlosEnable
	local bDlosInversion
	local nDlosWindowSize
	local nDlosTriggerThreshold
	local ePower
	local nLaserGap
	local nLaserOffset
	local nLaserEnEndExt
	local nLaserEnStartExt
	local onu_ploam
	local onu_ploam_hex
	local nT01
	local nT02

	local nDyingGaspEnable
	local nDyingGaspHyst
	local nDyingGaspMsg

	config_get bDlosEnable "gtc" bDlosEnable
	config_get bDlosInversion "gtc" bDlosInversion
	config_get nDlosWindowSize "gtc" nDlosWindowSize
	config_get nDlosTriggerThreshold "gtc" nDlosTriggerThreshold
	config_get ePower "gtc" ePower
	config_get nLaserGap "gtc" nLaserGap
	config_get nLaserOffset "gtc" nLaserOffset
	config_get nLaserEnEndExt "gtc" nLaserEnEndExt
	config_get nLaserEnStartExt "gtc" nLaserEnStartExt
	
	tmp=`fw_printenv onu_ploam 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		onu_ploam="$tmp"
	else
		logger -t "[onu]" "Using fallback ONU ploam (0000000000)"
		onu_ploam="0000000000"
	fi
	
	onu_ploam_hex=$(generate_ploam_password_hex "${onu_ploam}")
	
	tmp=`fw_printenv onu_loid 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		fw_setenv omci_loid "$tmp"
	else
		fw_setenv omci_loid "user"
	fi
	
	tmp=`fw_printenv onu_loid_password 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		fw_setenv omci_lpwd "$tmp"
	else
		fw_setenv omci_lpwd "password"
	fi
	
	config_get nRogueMsgIdUpstreamReset "ploam" nRogueMsgIdUpstreamReset
	config_get nRogueMsgRepeatUpstreamReset "ploam" nRogueMsgRepeatUpstreamReset
	config_get nRogueMsgIdDeviceReset "ploam" nRogueMsgIdDeviceReset
	config_get nRogueMsgRepeatDeviceReset "ploam" nRogueMsgRepeatDeviceReset
	config_get nRogueEnable "ploam" nRogueEnable
	config_get nT01 "ploam" nT01
	config_get nT02 "ploam" nT02

	nDyingGaspEnable=""
	nDyingGaspEnable=`fw_printenv nDyingGaspEnable 2>&- | cut -f2 -d=`
	if [ "$nDyingGaspEnable" != "1" -a "$nDyingGaspEnable" != "0" ]; then
	     config_get nDyingGaspEnable "gtc" nDyingGaspEnable
	fi
	config_get nDyingGaspHyst "gtc" nDyingGaspHyst
	config_get nDyingGaspMsg "gtc" nDyingGaspMsg

	onu gtccs 3600000 5 9 10 $nRogueMsgIdUpstreamReset $nRogueMsgRepeatUpstreamReset $nRogueMsgIdDeviceReset $nRogueMsgRepeatDeviceReset $nRogueEnable $nT01 $nT02 $(falcon_ploam_emergency_stop_state_get) $onu_ploam_hex
	onu gtci $bDlosEnable $bDlosInversion $nDlosWindowSize $nDlosTriggerThreshold $nLaserGap $nLaserOffset $nLaserEnEndExt $nLaserEnStartExt

	onu gtc_dying_gasp_cfg_set $nDyingGaspEnable $nDyingGaspHyst $nDyingGaspMsg

	onu psmcs $ePower 0 0 0 0 0 0 0 0 0
}

nmea_config() {
	local nmea_format
	local time_offset

	config_load nmea
	config_get nmea_format		"message" nmea_format
	config_get time_offset		"message" time_offset
	onu gpe_tod_nmea_cfg_set $nmea_format $time_offset
}

start() {
	local cfg="ethernet"
	local bUNI_PortEnable0
	local bUNI_PortEnable1
	local bUNI_PortEnable2
	local bUNI_PortEnable3
	local nPeNumber
	local fw="falcon_gpe_fw.bin"

	config_load gpon

	config_get bUNI_PortEnable0 "$cfg" bUNI_PortEnable0
	config_get bUNI_PortEnable1 "$cfg" bUNI_PortEnable1
	config_get bUNI_PortEnable2 "$cfg" bUNI_PortEnable2
	config_get bUNI_PortEnable3 "$cfg" bUNI_PortEnable3

	config_get nPeNumber "gpe" nPeNumber

	ploam_config

	# config GTC
	gtc_config

	# download GPHY firmware, if file is available
	[ -f /lib/firmware/phy11g.bin -o -f /lib/firmware/a1x/phy11g.bin -o -f /lib/firmware/a2x/phy11g.bin ] && onu langfd "phy11g.bin"

	# log the enabled hw modules before gpe_init, for debugging purpose
	cat /proc/driver/onu/sys

	# init GPE
	[ -f /lib/firmware/hgu/falcon_gpe_fw1.bin ] && fw="falcon_gpe_fw1.bin"
	onu gpei $fw 1 1 1 $bUNI_PortEnable0 $bUNI_PortEnable1 $bUNI_PortEnable2 $bUNI_PortEnable3 $bUNI_PortEnable0 $bUNI_PortEnable1 $bUNI_PortEnable2 $bUNI_PortEnable3 1 1 0 $nPeNumber 0 0 $(falcon_olt_type_get)

	nmea_config

	if [ -f "/etc/config/.fttdp" ]; then
		# for FTTdp: 8800 segments

		# Input Parameter
		# - uint32_t iqm_global_segments_max
		# - uint32_t tmu_global_segments_max
		# - uint32_t tmu_global_segments_green
		# - uint32_t tmu_global_segments_yellow
		# - uint32_t tmu_global_segments_red
		onu gpe_shared_buffer_cfg_set 1024 8800 8800 8800 8800
	else
		# default TMU goth = 3000 segments

		# Input Parameter
		# - uint32_t iqm_global_segments_max
		# - uint32_t tmu_global_segments_max
		# - uint32_t tmu_global_segments_green
		# - uint32_t tmu_global_segments_yellow
		# - uint32_t tmu_global_segments_red
		onu gpe_shared_buffer_cfg_set 1024 12288 12288 12288 12288
	fi

	if [ $(falcon_goi_calibrated_get) -ge 1 ]; then
		onu gtc_watchdog_set 1
	fi
}

stop() {
	# disable line
	onu onules 0
}
