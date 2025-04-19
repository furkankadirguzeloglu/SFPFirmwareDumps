#!/bin/sh

. /lib/falcon.sh

default_lct=$(falcon_default_lct_get)

optic="/opt/lantiq/bin/optic"
i2c="/opt/lantiq/bin/sfp_i2c"
uci="/sbin/uci"
sigstatenum=0

sig_status() {
	disable_sigstatus=`uci -q get gpon.onu.disable_sigstatus`
	if [ -z $disable_sigstatus ]; then
		sigstate=`$optic bosa_rx_status_get | cut -f 8 -d ' ' | cut -f 2 -d '=' | sed s/[[:space:]]//g`
		if [ "$sigstate" == "0" ]; then
			sleep 1
			sigstate=`$optic bosa_rx_status_get | cut -f 8 -d ' ' | cut -f 2 -d '=' | sed s/[[:space:]]//g`
			if [ "$sigstate" == "1" ] && [ $sigstatenum -lt 5 ]; then
				let sigstatenum++
				continue
			elif [ "$sigstatenum" == "5" ]; then
				sleep 1
				sigstate=`$optic bosa_rx_status_get | cut -f 8 -d ' ' | cut -f 2 -d '=' | sed s/[[:space:]]//g`
				if [ "$sigstate" == "true" ]; then
					logger -t "[monit_optic]" "Cancelling restore default settings ..."
					sigstatenum=0
					break
				else
					logger -t "[monit_optic]" "Restoring default settings and rebooting ..."
					fw_setenv ipaddr '192.168.1.10'
					fw_setenv netmask '255.255.255.0'
					fw_setenv gatewayip '192.168.2.0'
					fw_setenv ethaddr 'ac:9a:96:00:00:00'
					uci set network.lct.macaddr=$(falcon_mac_get $default_lct)
					uci set network.host.macaddr=$(falcon_mac_get host)
					uci commit network
					passwd -d root
					reboot -f
				fi
			fi
		fi
	fi
}

tx_status() {
	enable_txstatus=`uci -q get gpon.onu.enable_txstatus`
	if [ -n "$enable_txstatus" ]; then
		txstate=`$optic bosa_tx_status_get | cut -f 2 -d ' ' | cut -f 2 -d '=' | sed s/[[:space:]]//g`
		if [ "$txstate" != "1" ]; then
			$optic bosa_tx_enable 2>&-
			logger -t "[monit_optic]" "optic tx disabled detected, re-renabled tx ..."
		fi
	fi
}

while true
do
	sig_status
	tx_status
	sleep 1
done
