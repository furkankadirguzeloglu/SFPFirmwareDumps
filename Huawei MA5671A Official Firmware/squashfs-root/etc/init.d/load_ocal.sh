#!/bin/sh /etc/rc.common
# Copyright (C) 2007 OpenWrt.org
START=89

bindir=/opt/lantiq/bin

optic() {
	#echo "optic $*"
	result=`/opt/lantiq/bin/optic $*`
	#echo "result $result"
	status=${result%% *}
	key=$(echo $status | cut -d= -f1)
	val=$(echo $status | cut -d= -f2)
	if [ "$key" == "errorcode" -a "$val" != "0" ]; then
		echo "optic $* failed: $result"
	fi
}

onu () {
        #echo "onu $*"
        result=`/opt/lantiq/bin/onu $*`
        #echo "result $result"
        status=${result%% *}
        if [ "$status" != "errorcode=0" ]; then
                echo "onu $* failed: $result"
        fi
}

start() {
        local bertEnable
        local isTod_init
        local asc0
        local is1PPS_mode
        ${bindir}/ocal > /dev/console 2> /dev/console &
        bertEnable=`fw_printenv bertEnable 2>&- | cut -f2 -d=`
        if [ -n "$bertEnable" ]; then
            if [ "$bertEnable" == "1" ]; then
                sleep 10
                optic bertms 23
                optic berte
            fi
        fi
        is1PPS_mode=`fw_printenv is1PPS_mode 2>&- | cut -f2 -d=`
        if [ -n "$is1PPS_mode" ]; then
                if [ "$is1PPS_mode" == "true" ]; then
                        onu gpetpcs 2 0 0 0 0
                fi
        fi
        asc0=`fw_printenv asc0 2>&- | cut -f2 -d=`          
        isTod_init=`fw_printenv isTod_init 2>&- | cut -f2 -d=`
        if [ -n "$isTod_init" ]; then
                if [ "$isTod_init" == "true" ]; then
                        if [ "$is1PPS_mode" == "true" ]; then
                                onu gpetpcs 2 3 0 0 0
                        else
                                onu gpetpcs 0 3 0 0 0
                        fi
                        stty -F /dev/ttyLTQ0 9600
                        sleep 2
                        onu gpeti 4095 100 1
                else
                        if [ "$asc0" == "1" ]; then
                                echo 2 > /sys/class/gpio/export
                                echo low > /sys/class/gpio/gpio2/direction
                                echo 32 > /sys/class/gpio/export
                                echo low > /sys/class/gpio/gpio32/direction  
                        fi
                fi
        else
                if [ "$asc0" == "1" ]; then
                        echo 2 > /sys/class/gpio/export
                        echo low > /sys/class/gpio/gpio2/direction
                        echo 32 > /sys/class/gpio/export
                        echo low > /sys/class/gpio/gpio32/direction  
                 fi
        fi
}
