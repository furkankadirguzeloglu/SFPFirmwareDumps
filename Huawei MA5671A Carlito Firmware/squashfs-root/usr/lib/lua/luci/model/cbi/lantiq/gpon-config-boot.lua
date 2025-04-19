--[[
LuCI - Lua Configuration Interface

Copyright 2011 Ralph Hempel <ralph.hempel@lantiq.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

]]--

-- written by inode(jyeom@zaram.com)

require("luci.tools.gpon")


m = Map("boot", translate("BOOT Configuration"), translate("Here you can configure the GPONSTICK Boot Option(The system will reboot)."))

s = m:section(TypedSection, "omci", translate("OMCI Authentication Configuration"))
s.addremove = false
s.anonymous = true

local handle
local omci_loid = s:option(Value, "omci_loid", translate("loid"))
local omci_lpwd = s:option(Value, "omci_lpwd", translate("lpwd"))

handle = io.popen("fw_printenv -n omci_loid")
omci_loid.value = handle:read("*a")
omci_loid.addremove = false
omci_loid.rmempty = true
handle:close()

handle = io.popen("fw_printenv -n omci_lpwd")
omci_lpwd.value = handle:read("*a")
omci_lpwd.addremove = false
omci_lpwd.rmempty = true
handle:close()

function s.cfgsections()
	return { "_omci" }
end

function m.on_commit(map)
	local val0 = omci_loid:formvalue("_omci")
	local val1 = omci_lpwd:formvalue("_omci")

	if not val0 or #val0 <= 0 then
		os.execute("fw_setenv omci_loid")
	else
		os.execute("fw_setenv omci_loid %s" %val0)
	end
	
	if not val1 or #val1 <= 0 then
		os.execute("fw_setenv omci_lpwd")
	else
		os.execute("fw_setenv omci_lpwd %s" %val1)
	end

	omci_loid.value = val0
	omci_lpwd.value = val1
end

function m.on_after_commit(map)
	m.template = "admin_system/applyreboot"
	luci.sys.reboot()
end


return m

