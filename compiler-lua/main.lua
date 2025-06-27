-- COPPER Version 25.6.27
-- Created by @realSky 

local function readFile(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename)
    end
    local content = file:read("*all")
    file:close()
    return content
end 

function PrintTable(tbl, indent)
	indent = indent or 0
	local prefix = string.rep("  ", indent)

	for k, v in pairs(tbl) do
		local key = tostring(k)
		if type(v) == "table" then
			print(prefix .. key .. ":")
			PrintTable(v, indent + 1)
		else
			print(prefix .. key .. ": " .. tostring(v))
		end
	end
end

function PrintTableToFile(tbl, filename)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file for writing: " .. filename)
    end

    local function writeTable(t, indent)
        indent = indent or 0
        local prefix = string.rep("  ", indent)

        for k, v in pairs(t) do
            local key = tostring(k)
            if type(v) == "table" then
                file:write(prefix .. key .. ":\n")
                writeTable(v, indent + 1)
            else
                file:write(prefix .. key .. ": " .. tostring(v) .. "\n")
            end
        end
    end

    writeTable(tbl)
    file:close()
end

local text = readFile("file.cpr")

local Tokenizer = require("compiler-lua.tokenizer")
local Parser = require("compiler-lua.parser")
local Compiler = require("compiler-lua.compiler")

-- TODO: declare @ parameters on top of functions (@info, @warn "text" if param, @dep) (used for the language server when made on IDE)

function Compile(path, endpath)

	if not path then
		error("Invalid path provided!")
	end

	local text = readFile(path)

	local tokenizer = Tokenizer.new(text)

	tokenizer:tokenize()

	if not tokenizer.error then
		print(tokenizer.tokens)
	else
		print(tokenizer.error)
	end

	local parser = Parser.new(tokenizer.tokens)
	local ast = parser:parse()

	print("AST:")
	print(ast)

	local compiler = Compiler.new(ast)

	compiler:compile()

	PrintTableToFile(compiler.instructions, endpath)

end