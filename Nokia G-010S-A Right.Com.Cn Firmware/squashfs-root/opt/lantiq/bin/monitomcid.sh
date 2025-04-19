#!/bin/sh
onu="/opt/lantiq/bin/onu"
onuflag=0
lctwaitnum=0
lcttrynum=0
omcidtry=0
omcidrestart=`uci -q get gpon.onu.omcidrestart`
lct_restart_try=`uci -q get gpon.onu.lct_restart_try`
total_lct_wait=`uci -q get gpon.onu.total_lct_wait`
total_lct_try=`uci -q get gpon.onu.total_lct_try`
trackip1=`uci -q get gpon.onu.trackip1`
trackip2=`uci -q get gpon.onu.trackip2`
rebootlog=`uci -q get gopn.onu.rebootlog`

onustatus() {
	onustatus=`dmesg | grep -c "FIFO\[device\] overflow"`
	if [ $onustatus -gt 50 ]; then
		if [ "$rebootlog" == "1" ]; then
			/opt/lantiq/bin/debug
			cp /tmp/log/one_click /root
		fi
		fw_setenv rebootcause 2
		reboot -f
	fi
}

resetomcidreboot() {
	omcidrebootnum=`fw_printenv omcidreboot 2>&- | cut -c 13`
	fw_setenv omcidreboot 0
}

omcidreboot() {
	omcidrebootnum=`fw_printenv omcidreboot | cut -c 13 2>&-`
	if [ -z "$omcidrebootnum" ]; then
		omcidrebootnum=0
	fi
	if [ $omcidrebootnum -lt $totalomcidreboot ]; then
		if [ "$rebootlog" == "1" ]; then
			/opt/lantiq/bin/debug
			cp /tmp/log/one_click /root
		fi
		let omcidrebootnum++
		fw_setenv omcidreboot $omcidrebootnum
		fw_setenv rebootcause 3
		reboot -f
		exit 0
	else
		logger -t "[monitomcid]" "OMCID total reboot reached, current omcid try times: $omcidrebootnum, giving up ..."
	fi
}

copreboot() {
	result=`$onu gpetr 10 1`
	status=${result%% *}
	errorcode=${status#*=}
	#errorcode=-4512
	#define ONU_TSE_ERROR_BASE -4000
	#COP_STATUS_ERR_RESP_LEN = 512
	#cop_to_onu_errorcode()	return ONU_TSE_ERROR_BASE - st;
	if [ $errorcode -lt -4000 ]; then
		/opt/lantiq/bin/debug
		cp /tmp/log/one_click /root
		#send_cop_alarm
		#6 ONU self-test failure ONU has failed autonomous self-test
		/opt/lantiq/bin/omci_pipe.sh meas 256 0 6 1
		sleep 10
		fw_setenv rebootcause 4
		reboot -f

		#after rebooting, the alarm sequence number is reset, no need to clear cop alarm
		#At initialization, periodically, or when the OLT detects a gap in the alarm sequence number, it reconciles its view of the ONU's alarm status by sending a get all alarms command targeted at the ONU data ME
		#When it receives the get all alarms request, the ONU resets the alarm sequence number to zero.
		#When the upload is complete, the OLT compares the received alarm statuses with its own alarm table entries for that ONU, along with any alarm notifications received during the upload process, and notifies the network manager of any changes.
		#else
		#clear_cop_alarm
	fi
}

resetlctwait() {
	lctwaitnum=0
}

lctrestart() {
	if [ $lcttrynum -lt $total_lct_try ]; then
		$onu lan_port_disable 0
		sleep 5
		$onu lan_port_enable 0
		sleep 5
		let lcttrynum++
		resetlctwait
	else
		logger -t "[monitomcid]" "LCT total restart reached, current lct try times: $lcttrynum, giving up ..."
	fi
}

lctstatus() {
	status1=`ping -W 1 -c 3 $trackip1 | grep -c "100% packet loss"`
	status2=`ping -W 1 -c 3 $trackip2 | grep -c "100% packet loss"`
	if [ "$lct_restart_try" == "1"  ] && [ -n "$total_lct_wait" ] && [ -n "$trackip1" ] && [ -n "$trackip2" ]; then
		if [ "$status1" == "1" ] && [ "$status2" == "1" ] && [ $lctwaitnum -lt $total_lct_wait ]; then
			logger -t "[monitomcid]" "LCT port link error detected, current lct wait times: $lctwaitnum ,waiting ..."
			let lctwaitnum++
		fi
		if [ "$status1" != "1" ] || [ "$status2" != "1" ]; then
			resetlctwait
		fi
		if [ $lctwaitnum -eq $total_lct_wait ]; then
			logger -t "[monitomcid]" "LCT total wait times: $lctwaitnum reached, restaring ..."
			lctrestart
		fi
	fi
}

monitomcid() {
	while true
	do
		lctstatus
		onustatus
		copreboot
		sleep 15
	done 
}

monitomcid
