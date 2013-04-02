package = "tweed"
version = "scm-0"
source = {
   url = "git://github.com/cmr/tweed.git"
}
description = {
   summary = 'Lua web framework using tables for routing',
   homepage = "http://github.com/cmr/tweed",
   license = "MIT/X11"
}
dependencies = {
   "lua ~> 5.1",
   "leafy >= 0.3"
}
build = {
	type = "builtin",
	modules = {
		["tweed.filters"] = "filters.lua",
		["tweed.response"] = "response.lua",
		["tweed.request"] = "request.lua",
		["tweed.error_handlers"] = "error_handlers.lua",
		["tweed"] = "tweed.lua",
	}
}
