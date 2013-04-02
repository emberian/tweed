

return function(env)
	local request = {}
	request.env = env
	request.method = env.REQUEST_METHOD
	return request
end
