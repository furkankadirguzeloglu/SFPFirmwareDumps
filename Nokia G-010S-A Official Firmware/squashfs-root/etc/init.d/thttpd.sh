#!/bin/sh /etc/rc.common
# Copyright (C) 2009 OpenWrt.org
# Copyright (C) 2011 lantiq.com
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.
if [ -f /webs/thttpd ]; then
	/webs/thttpd -dd /webs/
fi
exit 0
