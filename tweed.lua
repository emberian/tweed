local leafy = require "leafy"
local route, callable = leafy.route, leafy.callable
local M = {}
local inspect = require "inspect"

local new_response = require "tweed.response"
local new_request = require "tweed.request"
local filters = require "tweed.filters"
local error_handlers = require "tweed.error_handlers"

local GET, POST, PUT, DELETE = {"GET"}, {"POST"}, {"PUT"}, {"DELETE"}

M.GET = GET
M.POST = POST
M.PUT = PUT
M.DELETE = DELETE

local site_mt = {
	__index = {
		-- default function called when there's an error in a controller
		error_handlers = error_handlers,

		err = function(self, status, ...)
			self.context.response.status = status
			local handler = rawget(self.error_handlers, status)
			if handler == nil then
				self.error_handlers.default(self, status, ...)
			else
				handler(self, ...)
			end
		end,

		run_ = function(self, wsapi_env)
			local params = {}
			local func = route(self.routing, wsapi_env.PATH_INFO, params)
			-- build context
			local context = { params = params}
			local request = new_request(wsapi_env)
			local response = new_response(request)
			response.error_handlers = self.error_handlers

			local output

			context.request = request
			context.response = response
			response.request = request

			self.context = context
			-- call func or 404
			if not func then
				response:err(404)
			else
				local suc, err = pcall(func, context)
				if not suc then
					response:err(500, err)
				end
			end

			-- return the output to wsapi
			if type(output) ~= 'function' then
				output = coroutine.wrap(function()
					for _, v in ipairs(response.output) do
						coroutine.yield(v)
					end
				end)
			end

			return response.status, response.headers, output
		end
	}
}


local function istable(t)
	return type(t) == 'table'
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
	{ __call = function(self, method, context)
		local res = context.response
		res.status = 405
		local supported = {}
		for k, v in pairs(method) do
			if not istable(v) or not v.unsup then
				table.insert(supported, k)
			end
		end
		res.headers['Allow'] = table.concat(supported, ', ')
	end
	})
end

local function make_default_from_table(t)
	assert(istable(t))
	local newtab = {}
	local method = setmetatable({
		GET = method_unsup('GET'),
		PUT = method_unsup('PUT'),
		POST = method_unsup('POST'),
		DELETE = method_unsup('DELETE'),
		HEAD = function(method, ctx)
			method.GET(method, ctx)
			ctx.response:reset_output()
		end
	}, {__index = function(tab, key)
			local rawk = rawget(tab, key)
			if rawk then return rawk end
			tab[key] = method_unsup(key)
			return rawget(tab, key)
		end
	})

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
					method[context.request.method](method, context)
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

M.int = filters.int
M.string = filters.string

return M
