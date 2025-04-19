--[[
LuCI - Lua Configuration Interface

Copyright 2016 INgo Rah <INgo.Rah@intel.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

require("luci.util")
require("luci.tools.gpon")

m = Map("fttdp")

s = m:section(TypedSection, "line", "Lines", "DSL Lines Configuration")
s.template = "cbi/tblsection"

p = s:option(ListValue, "profile", translate("Profile"))
p:value ("17", "17a")
p:value ("30", "30a")
p.widget = "radio"

ru = s:option(Value, "data_rate_us", translate("Data Rate US"))
ru.size = 10
rd = s:option(Value, "data_rate_ds", translate("Data Rate DS"))
rd.size = 10

b = s:option(Button, "apply", translate("Apply"))
b.inputstyle = "apply"

-- Write this DSL line
function b.write(self, section)
	m.uci:commit("fttdp")
	luci.util.exec(". /lib/dsl.sh && setup_dsl " .. section - 1)
end

return m
