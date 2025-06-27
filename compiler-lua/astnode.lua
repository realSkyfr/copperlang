local ASTNode = {}
ASTNode.__index = ASTNode

function ASTNode.new(kind, value, ...)
	local self = setmetatable({}, ASTNode)
	
	self.kind = kind
	self.value = value
	self.children = {...}
	
	return self
end

function ASTNode:add(child)
	table.insert(self.children, child)
end

function ASTNode:traverse(visitFunctions)
	local function visit(node)
		--print(node.kind)
		local enterFunc = visitFunctions["ENTER_" .. node.kind]
		if enterFunc then
			enterFunc(node)
		end
		
		for i, v in pairs(node.children) do
			visit(v)
		end

		local func = visitFunctions[node.kind]
		if func then
			func(node)
		end
	end

	visit(self)
end

function ASTNode:__tostring()
	local children = tostring(self.value) .. ', '
	for _, v in ipairs(self.children) do
		children = children .. tostring(v) .. ', '
	end
	
	local content = children:sub(1, #children - 2) -- strip trailing comma/space
	return self.kind .. "(" .. content .. ")"
end


return ASTNode
