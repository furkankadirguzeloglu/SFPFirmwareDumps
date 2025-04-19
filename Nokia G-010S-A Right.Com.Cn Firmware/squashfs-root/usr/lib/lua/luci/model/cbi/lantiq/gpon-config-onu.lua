--[[
LuCI - Lua Configuration Interface

Copyright 2011 Ralph Hempel <ralph.hempel@lantiq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

require("luci.tools.gpon")

local m, s, v

m = Map("gpon", translate("互操作兼容配置"))

local uci = require("luci.model.uci").cursor()
local onu_section = uci:get_all("gpon", "onu")

s = m:section(NamedSection, "onu", "onu", translate("基本认证设置"))
s.anonymous = true
s.addremove = false

v = s:option(Value, "nSerial", translate("GPON SN"), translate("GPON序列号设置"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "omci_loid", translate("LOID"), translate("LOID设置"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "omci_lpwd", translate("LOID CheckCode (Password)"), translate("LOID CheckCode（Password）设置"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "ploam_password", translate("Ploam Password"), translate("Ploam Password设置"))
v.addremove = true
v.rmempty = true

s = m:section(NamedSection, "onu", "onu", translate("VLAN相关设置"))

v = s:option(Flag, "iopmask", translate("互操作兼容模式"), translate("兼容适配模式,切换模式重启后生效"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "uvlan", translate("默认PVID"), translate("将untag的报文添加默认vlan（vlan范围:1-4094），填写“u”即可使用untag转untag模式（原光猫上网vlan为空的，可尝试填写）"))
v.addremove = true
v.rmempty = true
v:depends("iopmask","1")

v = s:option(Flag, "forceuvlan", translate("强制创建默认PVID"), translate("pvid设置后不生效，可尝试勾选"))
v.addremove = true
v:depends("iopmask","1")

v = s:option(Flag, "forcemerule", translate("强制设置ME规则"), translate("o5状态无法拨号，可尝试勾选"))
v.addremove = true
v:depends("iopmask","1")

v = s:option(Value, "mvlansource", translate("下行组播VLAN"), translate("组播数据vlan（填写原光猫中的组播vlan，vlan范围:1-4094）"))
v.addremove = true
v.rmempty = true
v.datatype = "and(uinteger,range(1,4094))"
v:depends("iopmask","1")

v = s:option(Value, "mvlan", translate("下行组播VLAN转换"), translate("将组播数据vlan转换为其他vlan" ..
		"（填写原光猫中iptv的vlan，即可将组播数据vlan转换为iptv认证vlan，vlan范围:1-4094）"))
v.addremove = true
v.rmempty = true
v.datatype = "and(uinteger,range(1,4094))" 
v:depends("iopmask","1")

v = s:option(Value, "tvlan", translate("VLAN转换/绑定"), translate("将下行vlan转换/绑定为其它vlan" ..
		"（可填写多组vlan转换对，填写示例：“2:41,3:43,4:u,5:44@5”，即可将用户侧vlan：2、3、4、5分别转换为网络侧vlan：41、43、utag、44，其中“@5”表示指定网络侧vlan优先级，优先级范围:0-7，vlan范围:1-4094）"))
v.addremove = true
v.rmempty = true
v:depends("iopmask","1")

v = s:option(Flag, "mtvlan", translate("启用 N:1 VLAN转换模式"), translate("启用后，可实现多个用户侧vlan转换/绑定为同一网络侧vlan（注意：需要不同mac对应不同的用户侧vlan）"))
v.addremove = true
v:depends("iopmask","1")

v = s:option(Flag, "vlandebug", translate("VLAN脚本日志"), translate("启用vlan脚本调试日志"))
v.addremove = true
v.rmempty = true
v:depends("iopmask","1")

s = m:section(NamedSection, "onu", "onu", translate("组播相关设置"))

v = s:option(ListValue, "igmp_version", translate("组播版本设置"), translate("更改ME309规则的IGMP版本，基于IPoE的IPTV组播异常，可尝试更改"))
v.default = 3
v:value(3, translate("IGMP v3"))
v:value(2, translate("IGMP v2"))

v = s:option(Flag, "forceme309", translate("强制创建ME309规则"), translate("基于IPoE的IPTV组播异常，可尝试勾选"))
v.addremove = true
v.rmempty = true

s = m:section(NamedSection, "onu", "onu", translate("高级自定义设置"))

v = s:option(Flag, "mib_customized", translate("自定义MIB配置文件"), translate("警告：自定义MIB配置文件可能导致无限重启！！！"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "vendor_id", translate("Vendor ID设置"), translate("一般为GPON SN前四位"))
v.addremove = true
v.rmempty = true
v:depends("mib_customized","1")

v = s:option(Value, "equipment_id", translate("Equipment ID设置"), translate("一般为GPON SN"))
v.addremove = true
v.rmempty = true
v:depends("mib_customized","1")

v = s:option(Value, "ont_version", translate("ONT版本设置"), translate("一般为光猫硬件版本"))
v.addremove = true
v.rmempty = true
v:depends("mib_customized","1")

v = s:option(Flag, "mod_omcid", translate("自定义OMCID版本"), translate("警告：自定义OMCID版本可能导致无限重启！！！"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "omcid_version", translate("OMCID版本设置"), translate("一般为光猫软件版本"))
v.addremove = true
v.rmempty = true
v:depends("mod_omcid","1")

buttona = s:option(Button, "ButtonA", translate("恢复默认OMCID"))
buttona.inputtitle = translate("恢复")
buttona.inputstyle = "apply"
buttona:depends("mod_omcid","")

v = s:option(Flag, "mod_omcc", translate("自定义OMCC版本"), translate("警告：自定义OMCC版本可能导致无限重启！！！"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "omcc_version", translate("OMCC版本设置"), translate("默认版本为160"))
v.addremove = true
v.rmempty = true
v:depends("mod_omcc","1")

v = s:option(Flag, "disable_sigstatus", translate("禁用光纤状态检测"), translate("禁用拔插光纤重置功能"))
v.addremove = true
v.rmempty = true

v = s:option(Flag, "enable_txstatus", translate("启用发光状态检测"), translate("启用发光状态（即运行过程中出现tx_disable，发光功率显示为“--”）的检测功能"))
v.addremove = true
v.rmempty = true

v = s:option(Flag, "disable_rx_los_status", translate("禁用RX_LOS报告"), translate("修改驱动程序，当移除或未插入光纤时，驱动程序不报告RX_LOS状态"))
v.addremove = true
v.rmempty = true

v = s:option(Flag, "ignore_rx_loss", translate("忽略RX_LOSS消息"), translate("使ONU驱动忽略RX_LOSS消息，避免因“PLOAM Rx - message lost”导致的短暂掉线现象（仅推荐存在该问题时尝试启用）"))
v.addremove = true
v.rmempty = true

v = s:option(Flag, "asc", translate("启用TTL控制台（ASC0）"), translate("警告：启用TTL控制台可能导致TX_FAULT"))
v.addremove = true
v.rmempty = true

v = s:option(Flag, "omci_log_to_console", translate("OMCID日志输出至CONSOLE"), translate("将OMCID调试日志输出至/dev/console（需启用TTL控制台并调整OMCID日志级别）"))
v.addremove = true
v.rmempty = true
v:depends("asc","1")

v = s:option(Flag, "mod_omci_log_level", translate("设置OMCID日志级别"), translate("自定义OMCID主程序的日志级别"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "omci_log_level", translate("OMCID日志级别"), translate("设置OMCID主程序的日志级别（1-7，默认级别为3）"))
v.addremove = true
v.rmempty = true
v:depends("mod_omci_log_level","1")

buttonb = s:option(Button, "ButtonB", translate("切换启动分区"))
buttonb.inputtitle = translate("切换")
buttonb.inputstyle = "apply"

s = m:section(NamedSection, "onu", "onu", translate("尝试重启设置"))

v = s:option(Flag, "tryreboot", translate("尝试重启OpenWrt"), translate("接入光纤后，非O5状态尝试重启OpenWrt"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "totalrebootwait", translate("重启OpenWrt前等待次数"), translate("重启OpenWrt（非O5状态）前等待次数，推荐5-10次左右"))
v.addremove = true
v.rmempty = true
v:depends("tryreboot","1")

v = s:option(Value, "totalreboottry", translate("重启OpenWrt次数"), translate("尝试重启OpenWrt（非O5状态）次数，推荐5-10次左右"))
v.addremove = true
v.rmempty = true
v:depends("tryreboot","1")

v = s:option(Flag, "lct_restart_try", translate("尝试重启LCT接口"), translate("当LCT接口无法连接时，尝试重启LCT接口（启用后当两组目标IP同时无法追踪时，即开始尝试重启）"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "total_lct_try", translate("重启LCT接口次数"), translate("尝试重启LCT接口次数，推荐5-10次左右"))
v.addremove = true
v.rmempty = true
v:depends("lct_restart_try","1")

v = s:option(Value, "total_lct_wait", translate("重启LCT接口前等待次数"), translate("重启LCT接口前等待次数，推荐5-10次左右"))
v.addremove = true
v.rmempty = true
v:depends("lct_restart_try","1")

v = s:option(Value, "trackip1", translate("目标IP_1"), translate("使用Ping程序追踪的IP地址，推荐使用局域网IP地址，请确认输入的IP地址可以访问，否则可能导致无限重启！！！"))
v.addremove = true
v.rmempty = true
v.datatype = "ip4addr"
v:depends("lct_restart_try","1")

v = s:option(Value, "trackip2", translate("目标IP_2"), translate("使用Ping程序追踪的IP地址，推荐使用局域网IP地址，请确认输入的IP地址可以访问，否则可能导致无限重启！！！"))
v.addremove = true
v.rmempty = true
v.datatype = "ip4addr"
v:depends("lct_restart_try","1")

v = s:option(Flag, "rebootlog", translate("保存Debug Log"), translate("在重启OpenWrt前，保存Debug Log至/root/"))
v.addremove = true
v.rmempty = true

v = s:option(Flag, "rebootdirect", translate("重启OpenWrt"), translate("达到设置的时间时，直接重启OpenWrt"))
v.addremove = true
v.rmempty = true

v = s:option(Value, "rebootwait", translate("等待重启OpenWrt时间"), translate("重启OpenWrt的等待时间，推荐60-300秒左右"))
v.addremove = true
v.rmempty = true
v:depends("rebootdirect","1")

function buttona.write(self, section, value)
	luci.sys.call("/opt/lantiq/bin/config_onu.sh restore")
end

function buttonb.write(self, section, value)
	luci.sys.call("/opt/lantiq/bin/config_onu.sh switch")
end

function m.on_after_commit(map)
	luci.sys.call("/opt/lantiq/bin/config_onu.sh set")
	luci.sys.call("/opt/lantiq/bin/config_onu.sh mod")
	luci.sys.call("/opt/lantiq/bin/config_onu.sh disable")
	luci.sys.call("/opt/lantiq/bin/config_onu.sh ignore")
	luci.sys.call("/opt/lantiq/bin/config_onu.sh reboot")
	luci.sys.call("/opt/lantiq/bin/config_onu.sh switchasc")
	luci.sys.call("/etc/init.d/iop.sh restart")
	luci.sys.call("/etc/init.d/monitomcid restart")
	luci.sys.call("/etc/init.d/monitoptic restart")
end

return m
