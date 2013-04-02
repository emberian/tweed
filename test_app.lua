local tweed = require "tweed"
local inspect = require "inspect"

local GET, POST, DELETE, param = tweed.GET, tweed.POST, tweed.DELETE, tweed.param

local site = tweed.make_site {
	[""] = function(context)
		context.response:text("root")
	end,
	about = function(context)
		context.response:text("about")
	end,
	signup = {
		[GET] = function(context)
			context.response:text("GET signup")
		end,
		[POST] = function(context)
			context.response:text("POST signup")
		end
	},
	[tweed.int 'foo'] = {
		[GET] = function(context)
			context.response:text("generic get: " .. context.params.foo)
		end,
		[DELETE] = function(context)
			context.response:text("generic delete: " .. context.params.foo)
		end,
		[tweed.string 'bar'] = function(context)
			context.response:text("nested params: " .. context.params.foo .. ' ' .. context.params.bar)
		end
	}
}

site.debug = true
return site
