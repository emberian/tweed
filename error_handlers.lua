return setmetatable({
	[500] = function(self, ...)
		local response = self.context.response
		if not self.debug then
			error_message = "Turn on debugging to see why."
		end
		response.status = 500
		response:reset_output()
		local error_template = [[
<!doctype html>
<html>
	<body>
		<b>Internal Error</b>
		<p>The server has encountered an internal error.</p>
		<pre>%s</pre>
	</body>
</html>
]]
		response:html(error_template:format(table.concat({...})))
	end,
	[404] = function(self, ...)
		local response, request = self.context.response, self.context.request
		local error_template = [[
<!doctype html>
<html>
	<body>
		<b>404 Not Found</b>
		<p>The requested resource was not found</p>
		<pre>%s</pre>
	</body>
</html>
]]
		response:html(error_template:format(request.env.REQUEST_URI))
	end,
}, { __index = function(tab, key)
	local rawk = rawget(tab, key)
	if not rawk
		then return function(self, ...)
			self.context.response:html(([[
<!doctype html>
<html>
	<body>
		<b>HTTP Error %d</b>
	</body>
</html>
]]):format(key))
	end
	else
		return rawk
	end
end})
