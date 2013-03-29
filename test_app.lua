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
	[tweed.string] = {
		[GET] = function(context)
			return "generic get"
		end,
		[DELETE] = function(context)
			return "generic delete"
		end,
		[tweed.string] = function(context)
			return "nested params!"
		end
	}
}

return site
