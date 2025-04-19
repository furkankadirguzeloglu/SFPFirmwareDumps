#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2014 lantiq.com
# Copyright (C) 2017 zaram.com

source $IPKG_INSTROOT/lib/falcon.sh
source $IPKG_INSTROOT/lib/functions.sh

START=41


# override uci variables by value from sys.features.xx
override_uci() {
	# override gtc variable comes from "uci_disable_dying_gasp.sh"
	val=`uci get sys.features.dying_gasp_enabled` || return 1
	uci set gpon.gtc.nDyingGaspEnable=${val}
	serial=`fw_printenv -n ont_serial 2>&-`
	if [ -n "${serial}" ]; then
		prefix=$(echo ${serial:0:4} | hexdump -C | head -1 | awk 'BEGIN{FS=" "} {print "0x"$2" 0x"$3" 0x"$4" 0x"$5""}')
		number=$(echo ${serial:4:2} ${serial:6:2} ${serial:8:2} ${serial:10:2} | awk 'BEGIN{FS=" "} {print "0x"$1" 0x"$2" 0x"$3" 0x"$4""}')
		serial=$(echo \'$prefix $number\')
		eval "uci set gpon.ploam.nSerial=$serial"
	elif [ `uci get sys.features.mib_customized` -eq 1 ] && [ -n `uci get sys.mib.vendor_id` ]; then
		# we will ignore default S/N generation rule which written in "onu.sh"
		prefix=$(uci get sys.mib.vendor_id | hexdump -C | head -1 | awk 'BEGIN{FS=" "} {print "0x"$2" 0x"$3" 0x"$4" 0x"$5""}')
		maclsb=$(awk 'BEGIN{RS=" ";FS="="} $1 == "ethaddr" {print $2}' /proc/cmdline | awk 'BEGIN{FS=":"} {print "0x"$3" 0x"$4" 0x"$5" 0x"$6""}')
		serial=$(echo \'$prefix $maclsb\')
		eval "uci set gpon.ploam.nSerial=$serial"
	fi
	password=`fw_printenv -n ont_password 2>&-`
	# if the variable is not set, default value which is in "/etc/config/gpon" will be used
	if [ -n "${password}" ]; then
		eval "uci set gpon.ploam.nPassword='$password'"
	fi
}

# override uci eeprom variables to the value comes from u-boot parameter
# refer to /etc/init.d/sfp_eeprom.sh
override_eeprom() {
	vendor_name=`fw_printenv -n eeprom_vendor_name 2>&-` && eval "uci set sfp_eeprom.default.vendor_name='${vendor_name}'"
	vendor_partno=`fw_printenv -n eeprom_vendor_partno 2>&-` && eval "uci set sfp_eeprom.default.vendor_partno='${vendor_partno}'"
	vendor_rev=`fw_printenv -n eeprom_vendor_rev 2>&-` && eval "uci set sfp_eeprom.default.vendor_rev='${vendor_rev}'"
	vendor_oui=`fw_printenv -n eeprom_vendor_oui 2>&-` && eval "uci set sfp_eeprom.default.vendor_oui='${vendor_oui}'"
	serial_no=`fw_printenv -n eeprom_serial_no 2>&-` && eval "uci set sfp_eeprom.default.serial_no='${serial_no}'"
	datecode=`fw_printenv -n eeprom_datecode 2>&-` && eval "uci set sfp_eeprom.default.datecode='${datecode}'"
}

start () {
	uenv='target'
	target=`fw_printenv -n ${uenv} 2>&-` || return 1
	case ${target} in
	generic)
		uci set sys.target.name=generic
		uci set sys.features.mib_customized=0
		uci set sys.features.igmp_fast_leave=1
		uci set sys.features.dying_gasp_enabled=0
		uci set sys.features.suppress_power_level=0
		;;
	debug)
		uci set sys.target.name=debug
		uci set sys.features.mib_customized=0
		uci set sys.features.igmp_fast_leave=1
		uci set sys.features.dying_gasp_enabled=0
		uci set sys.features.suppress_power_level=0
		uci set sys.features.eeprom_sync_option='2'
		;;
	oem-generic)
		uci set sys.target.name=oem-generic
		uci set sys.features.mib_customized=1
		uci set sys.features.igmp_fast_leave=1
		uci set sys.features.dying_gasp_enabled=0
		uci set sys.features.suppress_power_level=0
		uci set sys.features.eeprom_sync_option='1'
		uci set sys.mib.vendor_id='ZM\0\0'
		uci set sys.mib.ont_version='SFP-P05\0\0\0\0\0\0\0'
		uci set sys.mib.equipment_id='GPONSTICK\0\0\0\0\0\0\0'
		;;
	bdcom-generic)
		uci set sys.target.name=bdcom-generic
		uci set sys.features.mib_customized=1
		uci set sys.features.igmp_fast_leave=1
		uci set sys.features.dying_gasp_enabled=0
		uci set sys.features.suppress_power_level=0
		uci set sys.features.eeprom_sync_option='1'
		uci set sys.mib.vendor_id='BDCM'
		uci set sys.mib.ont_version='10.10.30G_01\0\0'
		uci set sys.mib.equipment_id='1110\0\0\0\0\0\0\0\0\0\0\0\0'
		;;
	*)
		;;
	esac
	
	override_uci
	override_eeprom
}

