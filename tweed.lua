local leafy = require "leafy"
local route, callable = leafy.route, leafy.callable
local M = {}
local inspect = require "inspect"

local GET, POST, PUT, DELETE = {"GET"}, {"POST"}, {"PUT"}, {"DELETE"}

M.GET = GET
M.POST = POST
M.PUT = PUT
M.DELETE = DELETE

local site_mt = {
	__index = {
		-- default function called when there's an error in a controller
		error_handler = function(self, context, ...)
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
			<p>The server has encountered an internal error.</p>
			<pre>%s</pre>
			</body>
			</html>]]):format(error_message))
		end,
		run_ = function(self, wsapi_env)
			local params = {}
			local func = route(self.routing, wsapi_env.PATH_INFO, params)
			-- build context and call func with it
			local context = { params = params}
			local request, response = {}, {}
			context.request = new_request(wsapi_env)
			context.response = new_response()
			context.request.method = wsapi_env.REQUEST_METHOD
			return response.status, response.headers, response:output()
		end
	}
}

local function istable(t)
	return type(t) == 'table'
end

local function new_response()
	return setmetatable({status = 200, headers = {}, }, { __index = {
		
	}})
end

local function contains(tab, val)
	for _, v in ipairs(tab) do
		if v == val then
			return true
		end
	end

	return false
end

-- see rfc 2616 sec10.4.5
local function method_unsup(meth)
	return setmetatable({unsup=true},
	{ __call = function(method, context)
		local res = context.response
		res.status = 405
		local supported = {}
		for k, v in pairs(method) do
			if not v.unsup then
				supported.insert(k)
			end
		end
		res.headers['Allow'] = table.concat(supported, ', ')
	end
	})
end

local function make_default_from_table(t)
	assert(istable(t))
	local newtab = {}
	local method = {
		GET = method_unsup('GET'),
		PUT = method_unsup('PUT'),
		POST = method_unsup('POST'),
		DELETE = method_unsup('DELETE'),
	}
	local params = {}
	for k, v in pairs(t) do
		if istable(v) then
			v = make_default_from_table(v)
		end

		if callable(k) then
			params[k] = v
		elseif istable(k) then
			if contains({M.GET, M.POST, M.PUT, M.DELETE}, k) then
				method[k[1]] = function(method, context) return v(context) end
			else
				error("Unrecognized table key in routing table")
			end
		else
			newtab[k] = v
		end
	end
	
	if next(method) == nil and next(params) == nil then
		-- simple table needing no default handler
		return t
	else
		return setmetatable(newtab, {
		default = function(remainder, extra_params)
			if next(remainder) == nil then
				-- no need to handle any remainder
				return false, function(context)
					return method[context.request.method](method, context)
				end
			else
				for k, v in pairs(params) do
					if k(remainder[1]) then
						extra_params[k.name] = remainder[1]
						if callable(v) then
							return false, v
						end
						return true, v
					end
				end
			end
		end
	})
	end
end

local function make_site(tab, options)
	local site = setmetatable({}, site_mt)		
	site.routing = make_default_from_table(tab)
	site.run = function(wsapi_env)
		return site:run_(wsapi_env)
	end

	for k, v in pairs(options or {}) do
		site[k] = v
	end
	return site
end

M.make_site = make_site
M.param = param

function M.string(val) 
	return setmetatable({name = val}, {
		__call = function(self, segment)
			return type(segment) == 'string'
		end
	})
end

function M.int(val)
	return setmetatable({name = val}, {
		__call = function(self, segment)
			return type(segment) == 'int'
		end
	})
end
return M
