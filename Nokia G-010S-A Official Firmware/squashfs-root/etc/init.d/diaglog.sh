#!/bin/sh /etc/rc.common
# Copyright (C) 2006 OpenWrt.org

#RCR ALU02298390 Resource Monitor
STOP=88
stop() {
	sync
	tar -zcf /logs/sysinfo.tgz -C /tmp sysinfo.log
}
