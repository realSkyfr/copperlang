--!native
local ASTNode = require("compiler-lua.astnode")

-- types
local String = require("compiler-lua.string") -- might need to get rewrite

local Compiler = {}
Compiler.__index = Compiler

local OpCodes = {
	PUSH = 0,
	ADD = 1,
	SUB = 2,
	MUL = 3,
	DIV = 4,
	POW = 5,
	PUSH_VAR = 6,
	DEF_VAR = 7,
	PUSH_COMPARE_EQUALS = 8,
	CALL = 9,
	SKIP_IF_FALSE = 10,
	END_CODEBLOCK = 11,
	START_CODE_BLOCK = 12,
	REPEAT_CODE_BLOCK = 13,
	PUSH_ITERATOR = 14,
	SKIP_IF_NO_NEXT = 15,
	PUSH_NEXT = 16,
	POP_ITERATOR = 17,
	PUSH_COMPARE_NOTEQUAL = 18,
	PUSH_COMPARE_LT = 19,
	PUSH_COMPARE_GT = 20,
	PUSH_COMPARE_LTEQ = 21,
	PUSH_COMPATE_GTEQ = 22,
	MEMBER_ACCESS = 23,
	FUNCTION_DECLARATION = 24,
	START_FN_CODE_BLOCK = 25,
	END_FN_CODE_BLOCK = 26,
	JUMP = 27,
	NO_OP = 28,
	RETURN = 29,
	PUSH_ARRAY = 30
}

local InvertedOpCodes = {}

for k, v in pairs(OpCodes) do
	InvertedOpCodes[v] = k
end

Compiler.OpCodes = OpCodes

function Compiler.new(tree)
	local self = setmetatable({}, Compiler)

	self.tree = tree
	self.instructions = {}

	return self
end

function Compiler:pow()
	table.insert(self.instructions, {OpCodes.POW})
end

function Compiler:mul()
	table.insert(self.instructions, {OpCodes.MUL})
end

function Compiler:div()
	table.insert(self.instructions, {OpCodes.DIV})
end

function Compiler:add()
	table.insert(self.instructions, {OpCodes.ADD})
end

function Compiler:sub()
	table.insert(self.instructions, {OpCodes.SUB})
end

function Compiler:push(value)
	table.insert(self.instructions, {OpCodes.PUSH, value})
end

function Compiler:pushVar(varname)
	table.insert(self.instructions, {OpCodes.PUSH_VAR, varname})
end

function Compiler:defVar(varname)
	table.insert(self.instructions, {OpCodes.DEF_VAR, varname})
end

function Compiler:compareEquals()
	table.insert(self.instructions, {OpCodes.PUSH_COMPARE_EQUALS})
end

function Compiler:compareNotEquals()
	table.insert(self.instructions, {OpCodes.PUSH_COMPARE_NOTEQUAL})
end

function Compiler:compareNotEqual()
	table.insert(self.instructions, {OpCodes.PUSH_COMPARE_NOTEQUAL})
end

function Compiler:compareGTEQ()
	table.insert(self.instructions, {OpCodes.PUSH_COMPATE_GTEQ})
end

function Compiler:compareLREQ()
	table.insert(self.instructions, {OpCodes.PUSH_COMPARE_LTEQ})
end

function Compiler:compareGT()
	table.insert(self.instructions, {OpCodes.PUSH_COMPARE_GT})
end

function Compiler:compareLT()
	table.insert(self.instructions, {OpCodes.PUSH_COMPARE_LT})
end

function Compiler:call(argCount)
	table.insert(self.instructions, {OpCodes.CALL, argCount})
end

function Compiler:ifStatement()
	-- boolean read thing add to code
	-- if not boolean then jump
	-- else dont jump and run the compiled code
	table.insert(self.instructions, {OpCodes.SKIP_IF_FALSE})
end

function Compiler:makeFunction(bytecodes)
	table.insert(self.instructions, {OpCodes.FUNCTION_DECLARATION, bytecodes})
end

function Compiler:whileStatementEnd()
	-- boolean read thing add to code
	-- if not boolean then jump
	-- else dont jump and run the compiled code
	table.insert(self.instructions, {OpCodes.REPEAT_CODE_BLOCK})
end

function Compiler:endCodeBlock()
	table.insert(self.instructions, {OpCodes.END_CODEBLOCK})
end

function Compiler:repeatCodeBlock()
	table.insert(self.instructions, {OpCodes.REPEAT_CODE_BLOCK})
end

function Compiler:startCodeBlock()
	table.insert(self.instructions, {OpCodes.START_CODE_BLOCK})
end

function Compiler:forEachStatementStart(name)
	table.insert(self.instructions, {OpCodes.SKIP_IF_FALSE, name})
end

function Compiler:forEachStatementEnd(name)
	table.insert(self.instructions, {OpCodes.REPEAT_CODE_BLOCK, name})
end

function Compiler:pushIterator(name)
	table.insert(self.instructions, {OpCodes.PUSH_ITERATOR})
end

function Compiler:pushNext()
	table.insert(self.instructions, {OpCodes.PUSH_NEXT})
end

function Compiler:skipIfNoNext()
	table.insert(self.instructions, {OpCodes.SKIP_IF_NO_NEXT})
end

function Compiler:memberAccess(memberName)
	table.insert(self.instructions, {OpCodes.MEMBER_ACCESS, memberName})
end

function Compiler:startFnCodeBlock(fnName, argNames)
	table.insert(self.instructions, {OpCodes.START_FN_CODE_BLOCK, fnName, argNames})
end

function Compiler:endFnCodeBlock(fnName)
	table.insert(self.instructions, {OpCodes.END_FN_CODE_BLOCK, fnName})
end

function Compiler:returnStatement()
	table.insert(self.instructions, {OpCodes.RETURN})
end

function Compiler:noOp()
	table.insert(self.instructions, {OpCodes.NO_OP})
end

function Compiler:pushArray(length)
	table.insert(self.instructions, {OpCodes.PUSH_ARRAY, length})
end

function Compiler:compile()
	local function visit(visitFunctions, node)
		--print(node)
		if node.visited then
			return
		end

		local enterFunc = visitFunctions["ENTER_" .. (node.kind or 'nil')]
		if enterFunc then
			enterFunc(node)
		end

		for i, v in pairs(node.children or {}) do
			visit(visitFunctions, v)
		end

		local func = visitFunctions[node.kind]
		if func then
			func(node)
		end


		node.visited = true
	end

	local visitFunctions
	visitFunctions = {
		['number'] = function(node)
			self:push(tonumber(node.value))
		end,

		['BinaryOp'] = function(node)
			if node.value == "mul" then
				self:mul()
			elseif node.value == "div" then
				self:div()
			elseif node.value == "add" then
				self:add()
			elseif node.value == "sub" then
				self:sub()
			elseif node.value == "pow" then
				self:pow()
			else
				error("encountered invalid operator ast:" .. {node.value})
			end
		end,

		['identifier'] = function(node)
			self:pushVar(node.value)
		end,

		['defvar'] = function(node)
			self:defVar(node.value)
		end,

		['compare'] = function(node)
			if node.value == "==" then
				self:compareEquals()
			elseif node.value == "!=" then
				self:compareNotEquals()
			elseif node.value == ">" then
				self:compareGT()
			elseif node.value == "<" then
				self:compareLT()
			elseif node.value == ">=" then
				self:compareGTEq()
			elseif node.value == "<=" then
				self:compareLTEq()
			else
				error("invalid comparison:" .. node.value)
			end
		end,

		['string'] = function(node)
			self:push(String.new(node.value))
		end,

		['boolean'] = function(node)
			self:push(node.value)
		end,

		['call'] = function(node)
			self:call(node.argCount)
		end,

		['ENTER_if_statement'] = function(node)
			visit(visitFunctions, node.children[1])
			self:startCodeBlock()
			self:ifStatement()
		end,

		['if_statement'] = function(node)
			self:endCodeBlock()
		end,

		['ENTER_while_statement'] = function(node)
			self:startCodeBlock()
			visit(visitFunctions, node.children[1])
			self:ifStatement()
		end,

		['while_statement'] = function(node)
			self:whileStatementEnd()
			self:endCodeBlock()
		end,

		['ENTER_foreach_statement'] = function(node)
			visit(visitFunctions, node.children[1])
			self:pushIterator()
			self:startCodeBlock()
			self:skipIfNoNext()
			self:pushNext()
			self:defVar(node.value)
		end,

		['foreach_statement'] = function(node)
			self:repeatCodeBlock()
			self:endCodeBlock()
		end,

		['member_access'] = function(node)
			self:memberAccess(node.value)
		end,

		['ENTER_fn_declarefinition'] = function(node)
			print(node.value)
			self:startFnCodeBlock(node.value.name, node.value.argNames)
			self:noOp()
		end,
		
		['fn_declarefinition'] = function(node)
			self:endFnCodeBlock(node.value.name)
		end,
		
		['return'] = function(node)
			self:returnStatement()
		end,
		
		['array'] = function(node)
			self:pushArray(#node.children)
		end,
	}

	visit(visitFunctions, self.tree)

	--self.tree:traverse(visitFunctions)
end

function Compiler:printCompilation()
	for idx, instruction in pairs(self.instructions) do
		local s = idx
		s = s .. InvertedOpCodes[instruction[1]] .. "("
		for i = 2, #instruction do
			s = s .. tostring(instruction[i]) .. ", "
		end
		if (s:sub(#s, #s) ~= "(") then
			s = s:sub(1, #s - 2)
		end
		s = s .. ")"
		print(s)
	end
end


return Compiler
