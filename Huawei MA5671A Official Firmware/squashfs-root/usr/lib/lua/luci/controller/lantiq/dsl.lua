--[[
LuCI - Lua Configuration Interface

Copyright 2011 Ralph Hempel <ralph.hempel@infineon.com>
Copyright 2016 INgo Rah <INgo.Rah@intel.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
module("luci.controller.lantiq.dsl", package.seeall)
require("luci.util")
fs = require "nixio.fs"
dsl = require("luci.tools.dsl")

function index()
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate
	if fs.access ("/tmp/pipe/dms0_cmd") then
		entry({"admin", "dsl"},  alias("admin", "dsl", "status"), "DSL", 81).index = true
		entry({"admin", "dsl", "status"}, template("lantiq/dsl-status"), "Status", 40).index = true
		entry({"admin", "dsl", "status_update"}, call("action_status")).leaf = true
		entry({"admin", "dsl", "config"}, cbi("lantiq/dsl-config", {hideresetbtn=true} ), "Configuration", 60).index = true
	end
end

function action_status()
	local res

	luci.http.prepare_content("application/json")
	luci.http.write("[")
	for i = 0, 7 do
		res = dsl.cli("lsg " .. i)
		local lsg = dsl.split_val(res)
		luci.http.write("[")
		if lsg['nLineState'] == "100" then
			luci.http.write ("'OFF', '") 
		else
			luci.http.write ("'ON', '") 
		end
		luci.http.write (dsl.decode_line_state(lsg['nLineState'])) 
		luci.http.write("', ")
		res = dsl.cli("g997csg " .. i .. " 0 0")
		local g997csg_0 = dsl.split_val(res)
		luci.http.write (dsl.assign_value(g997csg_0,'ActualDataRate')) 
		luci.http.write(", ")
		res = dsl.cli("g997csg " .. i .. " 0 1")
		local g997csg_1 = dsl.split_val(res)
		luci.http.write (dsl.assign_value(g997csg_1,'ActualDataRate')) 
		luci.http.write(", ")
		if lsg['nLineState'] == "800" or lsg['nLineState'] == "801" then
			local counter
			res = dsl.cli("LinePathCounterTotalGet " .. i .. " 0")
			counter = dsl.split_val(res)
			luci.http.write (dsl.assign_value(counter,'OctetsTx')) 
			luci.http.write(", ")
			luci.http.write (dsl.assign_value(counter,'OctetsRx')) 
		else
			luci.http.write ("'n.a.', 'n.a.' ") 
		end
		luci.http.write ("], ") 
	end

	luci.http.write("]")
end
