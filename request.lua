local querystring = require "tweed.querystring"

return function(env)
	local request = {}
	request.env = env
	request.method = env.REQUEST_METHOD
	setmetatable(request, {__index = function(tab, key)
		local rawk = rawget(tab, key)
		if rawk then return rawk end
		if key == 'body' then
			tab[key] = env.input:read()
			return rawget(tab, key)
		elseif key == "qs" then
			tab[key] = querystring.parse(env.QUERY_STRING)
			return rawget(tab, key)
		end
	end})
	return request
end
