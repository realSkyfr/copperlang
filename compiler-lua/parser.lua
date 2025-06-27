--!native

--[[
"First they ignore you
then they laugh at you
then they fight you
then you nuke them
then you win"
	-Mahatma Ghandi
]]

local ASTNode = require("compiler-lua.astnode")

local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
	local self = setmetatable({}, Parser)
	
	self.tokens = tokens
	self.position = 1
	self.size = #tokens
	
	return self
end

function Parser:current()
	--print(self.position)
	return self.tokens[self.position]
end

function Parser:peek()
	return self.tokens[self.position + 1]
end

function Parser:advance()
	self.position = self.position + 1
end

function Parser:consume(tokenType, tokenValue)
	local token = self.tokens[self.position]
	--print(token.kind)
	
	if ((not tokenType) or (token.kind == tokenType)) and ((not tokenValue) or (token.value == tokenValue)) then
		self:advance()
		return token
	else
		error("expected token of type '" .. (tokenType or "any") .. "' with value '" .. (tokenValue or "any") .. "' but got '" .. token.kind .. "' with value '" .. (token.value or "nil") .. "' at position " .. self.position)
		--return nil
	end
end

-- basics: numbers, idents, other values
function Parser:parsePrimary()
	local token = self:current()
	if token.kind == "number" then
		self:advance()
		return ASTNode.new('number', tonumber(token.value))
	elseif token.kind == "ident" then
		self:advance()
		local ident = ASTNode.new('identifier', token.value)
		if self:current().kind == 'lparen' then
			-- function call
			self:consume('lparen')
			local call = ASTNode.new("call", token.value, ident)
			local argCount = 0
			while self:current().kind ~= "rparen" do
				argCount = argCount + 1
				call:add(self:parseExpression())
				if self:current().kind ~= "rparen" then
					self:consume("comma")
				end
			end
			self:consume('rparen')
			call.argCount = argCount
			return call
		else
			return ident
		end
	elseif token.kind == "keyword" then
		self:advance()
		-- i know this is bad dont tell me
		if token.value == "true" then
			return ASTNode.new('boolean', true)
		elseif token.value == "false" then
			return ASTNode.new('boolean', false)
		elseif token.value == "if" then -- if boolean { code; }
			local condition = self:parseExpression()
			local codeBlock = self:parseCodeBlock()
			
			return ASTNode.new('if_statement', "", condition, codeBlock)
		elseif token.value == "while" then
			local condition = self:parseExpression()
			local codeBlock = self:parseCodeBlock()
			
			return ASTNode.new('while_statement', "", condition, codeBlock)
		elseif token.value == "foreach" then
			local ident = self:consume("ident")
			local inKeyword = self:consume("keyword", "in")
			local list = self:parseExpression()
			local codeBlock = self:parseCodeBlock()
			
			return ASTNode.new('foreach_statement', ident.value, list, codeBlock)
		elseif token.value == "fn" then
			local fnName = self:consume("ident")
			local args = {}
			self:consume("lparen")
			while self:current().kind ~= "rparen" do
				table.insert(args, self:consume("ident").value)
				if self:current().kind ~= "rparen" then
					self:consume("comma")
				end
			end
			self:consume("rparen")
			local codeBlock = self:parseCodeBlock('fn_code_block')
			
			return ASTNode.new('fn_declarefinition', {name = fnName.value, argNames = args}, codeBlock) -- i love declarefinitioning functions
		elseif token.value == "return" then
			return ASTNode.new('return', '', self:parseExpression())
		end
		
		return ASTNode.new('keyword', token.value)
	elseif token.kind == "string" then
		self:advance()
		return ASTNode.new('string', token.value) -- profound mental intelligence
	--elseif token.kind == "comparison" then
		--return ASTNode.new('compare', token.value)
	elseif token.kind == "equal" then
		self:advance()
		return ASTNode.new('defvar', token.value)
	elseif token.kind == "lparen" then
		self:advance()
		local parenExpr = self:parseExpression()
		print(self:current().kind)
		local rparen = self:consume('rparen')
		
		return parenExpr
	elseif token.kind == "lbracket" then
		return self:parseArray()
	elseif token.kind == "lbrk" then
		self:advance()
		return
	else
		error("CPR201: Invalid token type! " .. token.kind .. " at position " .. self.position .. " with value '" .. (token.value or "") .. "'")
	end
end

-- pow math
function Parser:parseOperationPrec2()
	local node = self:parsePrimary()

	while self.position <= self.size do
		local tok = self:current()
		if tok.kind == "pow" then
			self:advance()
			local right = self:parsePrimary()
			node = ASTNode.new("BinaryOp", tok.kind, node, right)
		elseif tok.kind == "member_access" then
			self:advance()
			local memberName = self:consume('ident')
			node = ASTNode.new('member_access', memberName.value, node)
			if self:current().kind == "lparen" then
				self:consume('lparen')
				local call = ASTNode.new("call", node.value, node)
				local argCount = 0
				while self:current().kind ~= "rparen" do
					argCount = argCount + 1
					call:add(self:parseExpression())
					if self:current().kind ~= "rparen" then
						self:consume("comma")
					end
				end
				self:consume('rparen')
				call.argCount = argCount
				node = call
			end
		else
			break
		end
	end

	return node
end

-- multiply + divide math
function Parser:parseOperationPrec1()
	local node = self:parseOperationPrec2()

	while self.position <= self.size do
		local tok = self:current()
		if tok.kind == "mul" or tok.kind == "div" then
			self:advance()
			local right = self:parsePrimary()
			node = ASTNode.new("BinaryOp", tok.kind, node, right)
		else
			break
		end
	end

	return node
end

-- add + subtract math
function Parser:parseOperationPrec0()
	local node = self:parseOperationPrec1()
	while self.position <= self.size do
		local tok = self:current()
		if tok.kind == "add" or tok.kind == "sub" then
			self:advance()
			local right = self:parseOperationPrec1()
			node = ASTNode.new("BinaryOp", tok.kind, node, right)
		else
			break
		end
	end
	return node
end

function Parser:parseMakeEquals() 
	local node = self:parseOperationPrec0()
	if self.position <= self.size then
		local tok = self:current()
		if tok.kind == "equal" then -- ServerScriptService.PoS.NotCrapParser:122: attempt to index nil with 'kind'
			self:advance()
			local right = self:parseOperationPrec0()
			node = ASTNode.new("defvar", node.value, right)
		elseif tok.kind == "comparison" then
			self:advance()
			local right = self:parseOperationPrec0()
			node = ASTNode.new("compare", tok.value, node, right)
		end
	end
	return node
end

function Parser:parseExpression()
	return self:parseMakeEquals()
end

function Parser:parse()
	local expressions = {}
	while self.position < self.size do
		table.insert(expressions, self:parseExpression())
	end
	return ASTNode.new("Program", "", unpack(expressions))
end

function Parser:parseCodeBlock(blockKind)
	self:consume('lcurly')
	local expressions = {}
	while self:current().kind ~= 'icarly' do
		table.insert(expressions, self:parseExpression())
	end
	self:consume('icarly')
	return ASTNode.new(blockKind or "code_block", "", unpack(expressions))
end

function Parser:parseArray()
	self:consume('lbracket')
	local expressions = {}
	while self:current().kind ~= 'rbracket' do
		table.insert(expressions, self:parseExpression())
		if self:current().kind ~= 'rbracket' then
			self:consume('comma')
		end
	end
	self:consume('rbracket')
	return ASTNode.new("array", "", unpack(expressions))
end

return Parser
