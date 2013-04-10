local response_mt = {}

function response_mt:reset_output()
	self.output = {}
end

function response_mt:write(data)
	assert(data)
	table.insert(self.output, data)
end

function response_mt:err(status, ...)
	self.status = status
	local handler = rawget(self.error_handlers, status)
	if handler == nil then
		self.error_handlers.default(self, status, ...)
	else
		handler(self, ...)
	end
end

function response_mt:redirect(path, status, body, mimetype)
	self.headers['Location'] = path
	self.status = status or 302
	if body then
	-- TODO: refine
		self:reset_output()
		self.headers['Content-Type'] = mimetype
		self:write(body)
	end
end

local function make_writer(mimetype)
	return function(self, data)
		if self.headers['Content-Type'] ~= mimetype then
			self:reset_output()
			self.headers['Content-Type'] = mimetype
		end
		self:write(data)
	end
end

response_mt.html = make_writer('text/html')
response_mt.json = make_writer('application/json')
response_mt.text = make_writer('text/plain')
response_mt.xml = make_writer('application/xml')

response_mt.status = 200
response_mt.headers = {}

local function make_response(req)
	return setmetatable({output = {}, request = req}, {__index = response_mt})
end

return make_response
