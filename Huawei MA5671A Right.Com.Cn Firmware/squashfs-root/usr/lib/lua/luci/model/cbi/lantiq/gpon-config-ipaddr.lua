--[[
LuCI - Lua Configuration Interface

Copyright 2011 Ralph Hempel <ralph.hempel@lantiq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

require("luci.tools.gpon")

m = Map("network", translate("IP/MAC地址配置"))

s = m:section(NamedSection, "host", "host")
s.anonymous = true
s.addremove = false

v = s:option(Value, "macaddr", translate("HOST接口（WAN）MAC地址"), translate("HOST接口MAC地址设置（克隆光猫MAC，适用于绑定MAC地址认证的地区）"))
v.addremove = true
v.rmempty = false
v.datatype = "macaddr"

s = m:section(NamedSection, "lct", "lct")
s.anonymous = true
s.addremove = false

v = s:option(Value, "ipaddr", translate("LCT接口（LAN）IP地址"), translate("LCT接口IP地址设置"))
v.addremove = true
v.rmempty = false
v.datatype = "ip4addr"

v = s:option(Value, "gateway", translate("LCT接口（LAN）网关地址"), translate("LCT接口网关地址设置"))
v.addremove = true
v.rmempty = false
v.datatype = "ip4addr"

v = s:option(Value, "macaddr", translate("LCT接口（LAN） MAC地址"), translate("LCT接口MAC地址设置"))
v.addremove = true
v.rmempty = false
v.datatype = "macaddr"

function m.on_after_commit(map)
    luci.sys.call("/opt/lantiq/bin/config_onu.sh setip")
end

return m
