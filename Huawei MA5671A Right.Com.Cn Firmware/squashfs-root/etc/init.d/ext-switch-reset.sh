#!/bin/sh /etc/rc.common
# Copyright (C) 2016 lantiq.com 

. $IPKG_INSTROOT/lib/falcon.sh
. $IPKG_INSTROOT/opt/lantiq/bin/gpio_setup.sh
LTQ_BIN=/opt/lantiq/bin

# do boot reset at similar time as MOD-DEF-0 pin
START=55

RESET_SWITCH=-1
SPEED_PIN=-1

boardcheck() {
	case $(falcon_board_name) in
	easy98035synce1588) # SFP module with F24S
		RESET_SWITCH=6
		SPEED_PIN=45 # GPIO 113 -> 1*32+13
		return 1
		;;
	esac
	return 0
}

indicate_speed() {
	[ $SPEED_PIN -eq -1 ] && return
	case $(falcon_sgmii_mode) in
	2|5)
		# 2.5G SGMII
		gpio_set_value $SPEED_PIN 1
		;;
	*)
		gpio_set_value $SPEED_PIN 0
		;;
	esac
}

toggle_reset() {
	[ $RESET_SWITCH -eq -1 ] && return
	gpio_set_value $RESET_SWITCH 0
	sleep 1
	gpio_set_value $RESET_SWITCH 1
}

boot() {
	boardcheck && return
	gpio_setup $SPEED_PIN low
	gpio_setup $RESET_SWITCH low
	indicate_speed
	toggle_reset
}

start() {
	echo "use 'boot' or 'restart' only"
}

restart() {
	boardcheck && return
	indicate_speed
	toggle_reset
}
