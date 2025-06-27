local String = {}
String.__index = String

function String.new(value)
	local self = setmetatable({['value'] = value, ['_typeName'] = 'string'}, String)
	
	return self
end

function String:__add(other)
	return String.new(self.value .. tostring(other))
end

function String:__mul(other)
	if type(other) == "number" then
		return string.rep(self.value, other)
	else
		error("attempt to perform arithmetic multiply on string and" .. {type(other)})
	end
end

function String:__eq(other)
	if type(other) == "table" and other._typeName == "string" then
		return self.value == other.value
	else
		return false
	end
end

function String:__tostring()
	return self.value
end

return String
