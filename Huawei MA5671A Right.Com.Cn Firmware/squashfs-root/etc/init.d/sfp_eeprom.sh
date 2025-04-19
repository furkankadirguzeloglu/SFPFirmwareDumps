#!/bin/sh /etc/rc.common
# Copyright (C) 2013 OpenWrt.org
# Copyright (C) 2013 lantiq.com

. $IPKG_INSTROOT/lib/falcon.sh
. $IPKG_INSTROOT/lib/functions.sh

START=62
SFP_I2C_BINARY=/opt/lantiq/bin/sfp_i2c

sfp_i2c() {
	#echo "sfp_i2c $*"
	$SFP_I2C_BINARY $*
}

# don't used wrapper above to ensure correct quoting of string
set_string () {
	$SFP_I2C_BINARY -i $1 -s "$2"
}

vendor_config() {
	local name
	local partno
	local revision
	local datecode
	local oui
	local oui_hex

	config_get name default vendor_name "Lantiq"
	config_get partno default vendor_partno "Part Number"
	config_get revision default vendor_rev "0000"
	config_get datecode default datecode "150414"
	config_get oui default vendor_oui "$(falcon_oui_get)"

	set_string 0 "$name"
	set_string 1 "$partno"
	set_string 2 "$revision"
	set_string 4 "$datecode"

	oui_hex=$(echo $oui | awk 'BEGIN{FS=":"} {printf "0x%2s%2s%2s",$1,$2,$3}')

	$SFP_I2C_BINARY -i 36 -w $oui_hex -4 -m 0x00FFFFFF
}

serialnumber_config() {
	local nSerial

	# get serial number from onu driver?
	#onu ...
	#logger -t sfp "Using sfp serial number: $nSerial"

	config_get nSerial default serial_no "no serial number"

	set_string 3 "$nSerial"
}

bitrate_config() {
	local nBitrate

	case $(falcon_sgmii_mode) in
	2|5) # sgmii_fast or sgmii_fast_auto
		nBitrate=25
		;;
	*) # default mode
		nBitrate=10
		;;
	esac

	sfp_i2c -1 -l 1 -i 12 -w $nBitrate
}

eeprom_addr_get() {
	local tmp
	local addr

	tmp=`fw_printenv sfp_i2c_addr_eeprom_$1 2>&- | cut -f2 -d=`
	if [ -n "$tmp" ]; then
		addr="$tmp"
	else
		config_get addr default addr_eeprom_$1
	fi

	echo $addr
}

eeprom_addr_config() {
	local addr

	addr=$(eeprom_addr_get 0)
	[ -n "$addr" ] && sfp_i2c -b $addr

	addr=$(eeprom_addr_get 1)
	[ -n "$addr" ] && sfp_i2c -B $addr
}

boot() {
	local eeprom

	config_load sfp_eeprom

	# reset to default values
	sfp_i2c -d yes
	#vendor_config
	#serialnumber_config
	#bitrate_config
	# configure I2C EEPROM addresses
	#eeprom_addr_config
	# activate write protection
	#sfp_i2c -i 0 -l 128 -p 1
	#sfp_i2c -i 256 -l 128 -p 1
	# activate write protection for dedicated fields
	#sfp_i2c -i 366 -p 2 -m 0x87

	config_get eeprom default eeprom 1

	# set current EEPROM
	sfp_i2c -e $eeprom

	# enable processing
	sfp_i2c -P enable

	start "$@"
}

start() {
	# don't use wrapper to avoid leaving this script active in background
	$SFP_I2C_BINARY -a > /dev/console &
}

stop() {
	killall -TERM sfp_i2c
}

debug() {
	killall -USR1 sfp_i2c
}

peek() {
	killall -USR2 sfp_i2c
}

EXTRA_COMMANDS="debug peek"
EXTRA_HELP="	debug	toggle debug output of monitoring daemon
	peek	trigger single debug output of monitoring daemon
"
