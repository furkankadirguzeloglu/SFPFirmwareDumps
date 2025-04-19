#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2011 lantiq.com

. $IPKG_INSTROOT/lib/falcon.sh

START=65

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

lct_mac_cfg_set() {
	local lctname=$(uci -q get network.lct.ifname)
	local port="${lctname##lct}"
	local mac=$(uci -q get network.lct.macaddr | sed -e 's/^/0x/' -e 's/:/ 0x/g')

	[ -n "$port" -a -n "$mac" ] && {
		onu lan_port_mac_cfg_set $port $mac
	}
}

gpon_lct_setup() {
	# only use ip addr from u-boot if no dm9000 is connected (as on easy98000)
	if [ -e /proc/cpld/ebu ]; then
		case `cat /proc/cpld/ebu` in
		"Ethernet Controller module"*) # dm9000 module
			echo "Found dm9000, don't change config of lct"
			ifup lct
			return 0
			;;
		*)
			echo "No dm9000"
			;;
		esac
	fi

	echo "Setup lct"
	lct_mac_cfg_set

	local ip=$(awk 'BEGIN{RS=" ";FS="="} $1 == "ip" {print $2}' /proc/cmdline)
	local ipaddr=$(echo $ip | awk 'BEGIN{FS=":"} {print $1}')
	local gateway=$(echo $ip | awk 'BEGIN{FS=":"} {print $3}')
	local netmask=$(echo $ip | awk 'BEGIN{FS=":"} {print $4}')
	[ -n "$ipaddr" ] && uci set network.lct.ipaddr=$ipaddr
	[ -n "$gateway" ] && uci set network.lct.gateway=$gateway
	[ -n "$netmask" ] && uci set network.lct.netmask=$netmask
	[ -n "$ipaddr" -o -n "$gateway" -o -n "$netmask" ] && uci commit network
	ifup lct
}

start() {
	gpon_lct_setup

	[ -f "/etc/config/.fttdp" ] && {
		# on FttDP8, loop detection needs a valid MAC addr for DSL ports
		# we reuse the LCT specific one
		local mac=$(uci -q get network.lct.macaddr | sed -e 's/^/0x/' -e 's/:/ 0x/g')
		onu lan_port_mac_cfg_set 0 $mac
	}

}
