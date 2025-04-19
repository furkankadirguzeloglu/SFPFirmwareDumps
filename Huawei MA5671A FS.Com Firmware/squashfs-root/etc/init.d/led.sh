#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2011 lantiq.com

. $IPKG_INSTROOT/lib/functions/leds.sh

START=65

gpon_led_tx=""
gpon_led_rx=""
mac0_led_act=""
mac0_led_link=""
mac1_led_act=""
mac1_led_link=""

find_led() {
	led_file=$(find /sys/class/leds/ -name "*$1*" |head -n1)
	if [ ! -f $led_file ]; then
		status_led=$(basename $led_file)
	fi;
	echo "$status_led"
}

led_cfg_set() {
	led_set_attr $1 "trigger" "onu"
	led_set_attr $1 "device_name" "$2"
	led_set_attr $1 "mode" "$3"
}

get_led_configuration() {
	mac0_led_act=$(find_led "ge0_act")
	mac0_led_link=$(find_led "ge0_link")
	mac1_led_act=$(find_led "ge1_act")
	mac1_led_link=$(find_led "ge1_link")

	gpon_led_tx=$(find_led "gpon_tx")
	if [ -z "$gpon_led_tx" ]; then
		gpon_led_tx=$(find_led "easy98000:green:2")
	fi
	gpon_led_rx=$(find_led "gpon_rx")
	if [ -z "$gpon_led_rx" ]; then
		gpon_led_rx=$(find_led "easy98000:green:3")
	fi

}

start() {
	get_led_configuration
	led_cfg_set $gpon_led_tx "gpon" "tx"
	led_cfg_set $gpon_led_rx "gpon" "rx"
	led_cfg_set $mac0_led_act "mac0" "tx rx"
	led_cfg_set $mac0_led_link "mac0" "link"
	led_cfg_set $mac1_led_act "mac1" "tx rx"
	led_cfg_set $mac1_led_link "mac1" "link"
}

stop() {
	get_led_configuration
	led_off $gpon_led_tx
	led_off $gpon_led_rx
}
