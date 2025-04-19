module("luci.tools.dsl", package.seeall)
require("luci.util")

--- Trim a string.
-- @return	Trimmed string
function trim(s)
	if s == nil then
		return "n.a."
	else
		return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
	end
end

function trim2(s)
	return (string.gsub(s, "^\"(.-)\"$", "%1"))
end

function return_val(s, val)
	if s == nil then return "table is invalid" end
	if val == nil then return "index is invalid" end
	local v = tonumber(val)
	if v == nil then
		return val
	end
	if s[v] == nil then
		return v
	else
		return s[v]
	end
end

function decode_error_code(val)
	local s = {}
	s[-1]="oops"
	return return_val(s, val)
end

--- Retrieves the output of the "dsl_pipe.sh" command.
-- @return	String containing the current buffer
function cli(command)
	local s = "/opt/lantiq/bin/dsl_pipe " .. command
	return trim(luci.util.exec(s))
end

function assign_value(t, v)
	if t['nReturn'] == nil then
		return "no ret"
	end
	if tonumber(t['nReturn']) >= 0 then
		if t[v] == nil then
			return "na"
		else
			return t[v]
		end
	else
		return decode_error_code(t['nReturn'])
	end
end

function return_val(s, val)
	if s == nil then return "table is invalid" end
	if val == nil then return "index is invalid" end
	local v = tonumber("0x" .. val)
	if v == nil then
		return val
	end
	if s[v] == nil then
		return v
	else
		return s[v]
	end
end

--- Split the CLI string into a table.
-- @return	Value Table
function split_val(s)
	local t = {}
	local s1, s2, s3, s4
	repeat
		s1, s2 = string.match(s, "(.-)  *(.+)")
		s3, s4 = string.match(s1 or s, "(.-)=(.+)")
		t[s3] = s4 or s
		s = s2
	until s1 == nil
	return t
end

function decode_error_code(val)
	local s = {}
	s[-21]="only available in showtime"
	s[-20]="data not available"
	s[15]="DSL_WRN_INCOMPLETE_RETURN_VALUES"
	return return_val(s, val)
end

function decode_line_state(val)
	local s = {}

	s[tonumber('0x000')] = "not initialized"
	s[tonumber('0x001')] = "exception"
	s[tonumber('0x005')] = "hae"
	s[tonumber('0x010')] = "not updated"
	s[tonumber('0x0ff')] = "idle request"
	s[tonumber('0x100')] = "idle"
	s[tonumber('0x1ff')] = "silent request"
	s[tonumber('0x200')] = "silent"
	s[tonumber('0x300')] = "handshake"
	s[tonumber('0x380')] = "full init"
	s[tonumber('0x400')] = "discovery"
	s[tonumber('0x500')] = "training"
	s[tonumber('0x600')] = "analysis"
	s[tonumber('0x700')] = "exchange"
	s[tonumber('0x800')] = "showtime / no sync"
	s[tonumber('0x801')] = "showtime / tc sync"
	s[tonumber('0x900')] = "fastretrain"
	s[tonumber('0xa00')] = "lowpower mode (L2)"
	s[tonumber('0xb00')] = "loopdiagnostic active"
	s[tonumber('0xb10')] = "loopdiagnostic data exchange"
	s[tonumber('0xb20')] = "loopdiagnostic data request"
	s[tonumber('0xc00')] = "loopdiagnostic complete"
	s[tonumber('0xd00')] = "resync"
	
	return return_val(s, val)
end
