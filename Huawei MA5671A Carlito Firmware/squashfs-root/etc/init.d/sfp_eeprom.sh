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

#config_get name default vendor_name "Lantiq"
#config_get partno default vendor_partno "Part Number"
#config_get revision default vendor_rev "0000"
#config_get datecode default datecode "150414"
#config_get oui default vendor_oui "$(falcon_oui_get)"

	config_get name default vendor_name "Zaram"
	config_get partno default vendor_partno "Part Number"
	config_get revision default vendor_rev "00P5"
	config_get datecode default datecode "180309"
	config_get oui default vendor_oui "00:0b:6f"

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

eeprom_load_data() {
	local idx
	local data
	local beg
	local end
	local off

	data=$1
	inst=$2
	beg=$3
	end=$(expr $4 + $3 - 1)

	for idx in $(seq ${beg} 1 ${end});
	do
		off=$(expr $idx \* 2)
		sfp_i2c -i $(expr 256 \* $inst + $idx) -w `echo 0x`${data:${off}:2} -1
	done
}

eeprom_load_data_default() {
	# reset to default values
	sfp_i2c -d yes

	vendor_config
	serialnumber_config
	bitrate_config
}

eeprom_load_data_restricted() {
	local data_a0=`uci get sfp_eeprom.default.data_eeprom_0`
	local data_a2=`uci get sfp_eeprom.default.data_eeprom_1`

	# reset to default values
	sfp_i2c -d yes
	bitrate_config

	eeprom_load_data ${data_a0} 0 20 16
	eeprom_load_data ${data_a0} 0 40 16
	eeprom_load_data ${data_a0} 0 56 4
	eeprom_load_data ${data_a0} 0 68 16
	eeprom_load_data ${data_a0} 0 84 8
	eeprom_load_data ${data_a0} 0 96 32
	eeprom_load_data ${data_a0} 0 128 128
	eeprom_load_data ${data_a2} 1 128 128
}

eeprom_load_data_unrestricted() {
	local data_a0=`uci get sfp_eeprom.default.data_eeprom_0`
	local data_a2=`uci get sfp_eeprom.default.data_eeprom_1`

	# reset to default values
	sfp_i2c -d yes

	eeprom_load_data ${data_a0} 0 0 256
	eeprom_load_data ${data_a2} 1 128 128
}

boot() {
	local eeprom
	local option

	option=`uci get sys.features.eeprom_sync_option`

	config_load sfp_eeprom

	case $option in
		1|0x01|restricted)
			eeprom_load_data_restricted
			eeprom_addr_config

			# activate write protection for A0
			sfp_i2c -i 0 -l 128 -p 1
			# deactivate write protection for A0
			sfp_i2c -i 20 -l 16 -p 0
			sfp_i2c -i 40 -l 16 -p 0
			sfp_i2c -i 56 -l 4 -p 0
			sfp_i2c -i 68 -l 16 -p 0
			sfp_i2c -i 84 -l 8 -p 0
			sfp_i2c -i 96 -l 32 -p 0
			# activate write protection for A2
			sfp_i2c -i 256 -l 128 -p 1
			# activate write protection for dedicated fields
			sfp_i2c -i 366 -p 2 -m 0x87
			;;
		2|0x02|unrestricted)
			eeprom_load_data_unrestricted
			eeprom_addr_config

			# activate write protection for A2
			sfp_i2c -i 256 -l 128 -p 1
			# activate write protection for dedicated fields
			sfp_i2c -i 366 -p 2 -m 0x87
			;;
		*)
			eeprom_load_data_default
			eeprom_addr_config

			# activate write protection for A0
			sfp_i2c -i 0 -l 128 -p 1
			# activate write protection for A2
			sfp_i2c -i 256 -l 128 -p 1
			# activate write protection for dedicated fields
			sfp_i2c -i 366 -p 2 -m 0x87
			;;
	esac

	config_get eeprom default eeprom 0

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
