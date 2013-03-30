local tweed = require "tweed"
local inspect = require "inspect"

local GET, POST, DELETE, param = tweed.GET, tweed.POST, tweed.DELETE, tweed.param

local site = tweed.make_site {
	[""] = function(context)
		return "index"
	end,
	about = function(context)
		return "about"
	end,
	signup = {
		[GET] = function(context)
			return "signupget"
		end,
		[POST] = function(context)
			return "signuppost"
		end
	},
	[tweed.int 'foo'] = {
		[GET] = function(context)
			return "generic get: " .. context.params.foo
		end,
		[DELETE] = function(context)
			return "generic delete: " .. context.params.foo
		end,
		[tweed.string 'bar'] = function(context)
			return "nested params: " .. context.params.foo .. ' ' .. context.params.bar
		end
	}
}

return site
