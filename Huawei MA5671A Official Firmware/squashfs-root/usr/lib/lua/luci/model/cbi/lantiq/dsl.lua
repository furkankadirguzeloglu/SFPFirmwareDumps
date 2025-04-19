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
require("luci.tools.dsl")

function index()
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate
	entry({"admin", "dsl"},  alias("admin", "dsl", "status"), "DSL", 81).index = true
	entry({"admin", "dsl", "status"}, template("lantiq/dsl-status"), "Status", 40).index = true
	entry({"admin", "dsl", "status_update"}, call("action_dsl_status")).leaf = true
	entry({"admin", "dsl", "config"}, cbi("lantiq/dsl-config"), "Configuration", 60).index = true
end

function action_dsl_status()
	luci.http.prepare_content("application/json")

	luci.http.write("{ lsg: 100")
	--luci.http.write_json()
	luci.http.write(" }")
end
