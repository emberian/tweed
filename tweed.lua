local route = require "leafy".route
local inspect = require "inspect"

local M = {}

M.GET = {"GET"}
M.POST = {"POST"}
M.PUT = {"PUT"}
M.DELETE = {"DELETE"}

local site_mt = {
	__index = {
		error_handler = function(self, context, error_message)
			local response = context.response
			if not self.debug then
				error_message = "Turn on debugging to see why."
			end
			response.status = 500
			response:reset_output()
			response:html(([[
			<!doctype html>
			<html>
			<body>
			<b>Internal Error</b>
			<p>The server has encountered and internal error.</p>
			<p>%s</p>
			</body>
			</html>]]):format(error_message))
		end,
		run_ = function(self, wsapi_env)
			return 200, {}, coroutine.wrap(function() coroutine.yield(inspect(self.routing)) end)
		end
	}
}

local function param(string)
	return {type = "param", value = string}
end

local function make_site(tab)
	local site = setmetatable({}, site_mt)		
	for k, v in pairs(tab) do
		if type(k) == "table" and k.type == "param"
	site.run = function(wsapi_env)
		return site:run_(wsapi_env)
	end
	return site
end

M.make_site = make_site

return M
