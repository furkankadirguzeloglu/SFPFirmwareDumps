--[[
LuCI - Lua Configuration Interface

Copyright 2011 Ralph Hempel <ralph.hempel@lantiq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module("luci.controller.lantiq.gpon", package.seeall)
require("luci.tools.gpon")
require("luci.util")

function index()
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate
	entry({"admin", "gpon"}, alias("admin", "gpon", "config-onu"), i18n("GPON"), 80).index = true
	entry({"admin", "gpon", "config-onu"}, cbi("lantiq/gpon-config-onu"), i18n("互操作兼容配置"), 30).index = true
	entry({"admin", "gpon", "config-goi"}, cbi("lantiq/gpon-config-ipaddr"), i18n("IP/MAC地址配置"), 40).index = true
	entry({"admin", "gpon", "config-cal"}, cbi("lantiq/gpon-config-cal"), i18n("校准信息配置"), 50).index = true
	entry({"admin", "gpon", "config-info"}, call("action_information"), i18n("模块信息"), 60).index = true
end

function action_information()
	luci.template.render("lantiq/gpon-gtc-info")
end

