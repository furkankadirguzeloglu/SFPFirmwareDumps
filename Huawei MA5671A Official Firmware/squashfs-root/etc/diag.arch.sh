#!/bin/sh
#
# Copyright (C) 2010 OpenWrt.org
#

. /lib/functions/leds.sh

find_led() {
	led_file=$(find /sys/class/leds/ -name "*$1*" |head -n1)
	if [ ! -f $led_file ]; then
		_status_led=$(basename $led_file)
	fi;
	echo "$_status_led"
}

get_status_led() {
	status_led=$(find_led "status")
	if [ -n "$status_led" ]; then
		return
	fi
	status_led=$(find_led "power")
	if [ -n "$status_led" ]; then
		return
	fi

	# old board specific assignments as fall-back
	status_led=$(find_led "easy88388:green:2")
	if [ -n "$status_led" ]; then
		return
	fi
	status_led=$(find_led "easy98020:green:3")
	if [ -n "$status_led" ]; then
		return
	fi
	status_led=$(find_led "easy98000:green:5")
	if [ -n "$status_led" ]; then
		return
	fi
}

set_state() {
	get_status_led

	case "$1" in
	preinit)
		status_led_blink_preinit
		;;
	failsafe)
		status_led_blink_failsafe
		;;
	preinit_regular)
		status_led_blink_preinit_regular
		;;
	done)
		status_led_on
		;;
	esac
}
