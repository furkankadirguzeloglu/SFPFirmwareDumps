#!/bin/sh /etc/rc.common

START=11

boot() {
	[ -e /proc/mips/mtsched ] && {
		echo "MIPS: configuring HW scheduling 33/66"
		echo "t0 0x0" > /proc/mips/mtsched
		echo "t1 0x1" > /proc/mips/mtsched
		echo "v0 0x0" > /proc/mips/mtsched
	}
}
