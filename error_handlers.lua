return {
	[500] = function(response, ...)
		if not self.debug then
			error_message = "Turn on debugging to see why."
		end
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
	[404] = function(response, ...)
		local request = response.request
		response:reset_output()
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
	default = function(self, status, ...)
		local response = self.context.response
		response:reset_output()
		response:html(( [[
<!doctype html>
<html>
	<body>
		<b>HTTP Error %d</b>
	</body>
</html>
]]):format(status))
	end,
}
