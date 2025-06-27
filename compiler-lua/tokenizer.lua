--!native

-- tokenizer by sky (everything else) and irludure (the base)


local Tokenizer = nil
if 2 + 2 ~= "fish" then
	Tokenizer = {}
end
Tokenizer.__index = Tokenizer

print("debug statements everywhere")

-- note: its generally good practice to have definitions as short as possible

-- pretend this is optimized

local TokenTypes = {
	number = "0123456789", 
	add = "+", 
	sub = "-", 
	mul = "*", 
	div = "/",
	pow = "^",
	sucks = "%",
	lparen = "(",
	rparen = ")",
	--compare = "==", 
	ident = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
	--vardef = "var",
	lcurly = "{",
	icarly = "}",
	equal = "=",
	strident = '"',
	lbrk = ";",
	comma = ",",
	isnt = "!",
	funcinfo = "@",
	gt = ">",
	lt = "<",
	member_access = ".",
	comment = "`",
	lbracket = "[",
	rbracket = "]"
}

-- iterate iterates over every character without a lbrk/space of the same type, single only accepts 1
-- set is set to however long the string is (ex ">=" would be 2)
local TokenRules = {
	number = "iterate", 
	add = "single", 
	sub = "single", 
	mul = "single",
	div = "single", 
	pow = "single",
	sucks = "single",
	lparen = "wrapper", 
	rparen = "wrapper",
	--compare = "set", 
	ident = "iterate",
	--vardef = "set",
	lcurly = "wrapper",
	icarly = "wrapper",
	equal = "iterate",
	strident = "single",
	lbrk = "single",
	comma = "single",
	isnt = "iterate",
	funcinfo = "single",
	gt = "iterate",
	lt = "iterate",
	member_access = "single",
	comment = "single",
	lbracket = "single",
	rbracket = "single"
}

local compareTypes = {
	["=="] = true,
	["!="] = true,
	[">"] = true,
	["<"] = true,
	[">="] = true,
	["<="] = true
	
}

local keyWords = {
	--var = true, NOTE: deemed unneccesary
	["true"] = true,
	["false"] = true,
	["if"] = true,
	["elif"] = true,
	["else"] = true,
	['while'] = true,
	['foreach'] = true,
	['in'] = true,
	['fn'] = true,
	['import'] = true,
	['return'] = true
	-- ['@'] = true, not neccesary for roblox as there isnt a language server
}

--[[ foreach var in list {
	codeblock
}
]]

local function matches(char, group)
	for i = 1, group:len() do
		if (char == group:sub(i, i)) then
			return true
		end
	end
	return false
end

function Tokenizer.new(input)
	local self = setmetatable({}, Tokenizer)
	
	self.input = input
	self.tokens = {}
	self.buffer = ""
	self.bufferType = ""
	self.stringState = false

	return self
end

function Tokenizer:tryAppendNumber()
	--print('trying buffer append')
	--shut up it works
	
	if self.buffer ~= "" then
		--print('buffer appending')
		if compareTypes[self.buffer] then
			table.insert(self.tokens, {
				kind = "comparison",
				value = self.buffer
			})
			self.buffer = ""
		elseif keyWords[self.buffer] then
			table.insert(self.tokens, {
				kind = "keyword",
				value = self.buffer
			})
			self.buffer = ""
		else
			if self.bufferType == nil then
				error("ruh roh buffertype not real")
			end
			table.insert(self.tokens, {
				kind = self.bufferType,
				value = self.buffer
			})
			self.buffer = ""
		end
	end
end

function Tokenizer:iterate(char)
	if char == TokenTypes.strident then
		self.stringState = not self.stringState
		if not self.stringState then
			table.insert(self.tokens, {
				kind = "string",
				value = self.buffer
			})
			self.buffer = ""
		end
		return
	end
	
	if char == TokenTypes.comment then
		self.stringState = not self.stringState
		if not self.stringState then
			table.insert(self.tokens, {
				kind = "comment",
				value = self.buffer
			})
			self.buffer = ""
		end
		return
	end
	
	if self.stringState then
		self.buffer = self.buffer .. char
		return
	end
	
	if char == " " or char == "/n" then
		self:tryAppendNumber()
		return
	end
	
	for kind, charGroup in pairs(TokenTypes) do
		if TokenRules[kind] == "single" then
			if matches(char, charGroup) then
				self:tryAppendNumber()
				--print('appending single ' .. char)
				table.insert(self.tokens, {
					kind = kind,
					value = char
				})
				return
			end
		
		elseif TokenRules[kind] == "iterate" then
			--print('iterate')
			if matches(char, charGroup) then
				--print(`char {char} matches group {charGroup}`)
				
				--if matches(char:lower(), TokenTypes.ident) then
				--	self.buffertype = "words"
				--elseif matches(char, TokenTypes.number) then
				--	self.buffertype = "number"
				--else 
				--	error("veri veri bad happen")
				--end
				
				local scs = false
				
				for typename, typeRule in pairs(TokenTypes) do
					if matches(char:lower(), typeRule) then
						self.bufferType = typename
						scs = true
						break --your legs
					end
				end
				
				if scs then
					self.buffer = self.buffer .. char
					return
				end

			end
		elseif TokenRules[kind] == "wrapper" then
			if matches(char, charGroup) then
				self:tryAppendNumber()
				--print('appending single ' .. char)
				table.insert(self.tokens, {
					kind = kind,
					value = char
				})
				return
			end
		end
	end
	--error(`Invalid character encountered: {char} does not match any expected token`)
end

function Tokenizer:tokenize()
	for i = 1, self.input:len() do
		self:iterate(self.input:sub(i, i))
	end
	self:tryAppendNumber()
end

if Tokenizer then
	print("tokenizer success")
	return Tokenizer
else
	error("something bad has happened and your pc will explode in the next 12 seconds. 12. 11. 10. 9. 8. 7. 6. 5. 4. 3. 2. 1. 1/2. 1/4. 1/8. 1/16. 1/32. 1/64. 1/128. 1/256. 1/512. 1/1024")
end
