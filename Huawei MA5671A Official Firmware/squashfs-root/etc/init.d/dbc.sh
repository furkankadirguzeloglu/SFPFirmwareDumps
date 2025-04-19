#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2010 lantiq.com
START=66

. $IPKG_INSTROOT/lib/falcon.sh

ONU_BIN=/opt/lantiq/bin/onu
ONU_IFNAME='dbc'
ONU_IP='192.168.2.2'
ONU_NM='255.255.255.0'
ONU_MAC=
OLT_IP='192.168.2.1'
OLT_MAC='06:00:00:00:00:80'

dbc_onu_mac_get() {
	local mac=${ONU_MAC}
	local sn

	# extract ONU MAC from the SN if not specified
	if [ -z "$mac" ]; then
		sn=$(${ONU_BIN} gtc_serial_number_get | awk 'BEGIN{FS="serial_number=\""} {print $2}')
		mac=$(echo $sn | awk 'BEGIN{FS=" "} {printf "02:4C:%02x:%02x:%02x:%02x",$5,$6,$7,$8}')
	fi

	echo $mac
}

dbc_is_expected() {
	case $(falcon_olt_type_get) in
	1|2)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

dbc_net_config_set() {
	# set UCI configuration if not configured yet
	if [ -z `uci get network.$1` ]; then
		uci set network.$1=interface
		uci set network.$1.ifname=$1
		uci set network.$1.ipaddr=$2
		uci set network.$1.netmask=$3
		uci set network.$1.proto='static'
	fi

	# always set MAC address
	uci set network.$1.macaddr=$4

	# enable debug channel network interface
	ifup ${1}

	# add static ARP entry for OLT
	arp -i $1 -s $5 $6
}

dbc_ssh_config_set() {
	local username=$2
	local password=$3
	local public_key=$4

	if ( ! grep -qs '^'${username}':[!x]\?:' /etc/passwd )
	then
		# set new user with ssh_username and ssh_password
		if [ -n "$username" ]; then
			mkdir home
			mkdir home/${username}

			echo ${username}:x:0:0:${username}:/home/${username}:/bin/ash >> /etc/passwd
			echo ${username}:*:0:0:99999:7::: >> /etc/shadow

			echo -e "${password}\n${password}" | (passwd ${ssh_username})
		fi
	fi

	# set SSH public key
	[ -n "$public_key" ] && echo ${public_key} >> /etc/dropbear/authorized_keys

	# disable telnet if username or key authentication exists and restart dropbear
	if [ -n "$username" -o -n "$public_key" ]; then
		killall telnetd
		killall dropbear
		rm -f /etc/dropbear/dropbear_rsa_host_key
		rm -f /etc/dropbear/dropbear_dss_host_key

		uci set dropbear.@dropbear[0].Interface=$1
		./etc/init.d/dropbear start
	fi
}

start() {
	local ssh_username
	local ssh_password
	local ssh_public_key

	# allow all further handling if debug channel is supported
	!(dbc_is_expected) && return

	# configure debug channel network interface
	dbc_net_config_set ${ONU_IFNAME} ${ONU_IP} ${ONU_NM} $(dbc_onu_mac_get) ${OLT_IP} ${OLT_MAC}

	# get SSH credentials
	ssh_username=`fw_printenv ssh_username 2>&- | cut -f2 -d=`
	ssh_password=`fw_printenv ssh_password 2>&- | cut -f2 -d=`
	ssh_public_key=`fw_printenv ssh_public_key 2>&- | awk 'BEGIN{FS="ssh_public_key="} {print$2}'`

	# configure SSH
	dbc_ssh_config_set ${ONU_IFNAME} ${ssh_username} ${ssh_password} "${ssh_public_key}"
}
