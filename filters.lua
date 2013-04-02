local M = {}

function M.string(val) 
	return setmetatable({name = val}, {
		__call = function(self, segment)
			return type(segment) == 'string'
		end
	})
end

function M.int(val)
	return setmetatable({name = val}, {
		__call = function(self, segment)
			if segment:find('[.e]') then
				return false
			end
			return type(tonumber(segment)) == 'number'
		end
	})
end

return M
