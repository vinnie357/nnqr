-- Persistence module for multiplayer server
-- Handles saving and loading game state to JSON files
-- Phase 10A: Network Multiplayer

local Protocol = require("src.shared.protocol")

local Persistence = {}

-- Use Protocol's JSON encoder/decoder for consistency
local json = {
	encode = function(data)
		return Protocol.encode({ type = "DATA", payload = data, timestamp = 0, seq = 0 })
	end,
	decode = function(str)
		local msg = Protocol.decode(str)
		if msg and msg.payload then
			return msg.payload
		end
		return nil
	end,
}

-- Simple JSON encoder that handles our data structures
-- More robust than using Protocol wrapper
local function encodeValue(val)
	local t = type(val)
	if t == "nil" then
		return "null"
	elseif t == "boolean" then
		return val and "true" or "false"
	elseif t == "number" then
		return tostring(val)
	elseif t == "string" then
		local escaped = val:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
		return '"' .. escaped .. '"'
	elseif t == "table" then
		-- Check if array or object
		local isArray = false
		local maxIndex = 0
		local count = 0
		for k, _ in pairs(val) do
			count = count + 1
			if type(k) == "number" and k > 0 and math.floor(k) == k then
				maxIndex = math.max(maxIndex, k)
			end
		end
		isArray = (maxIndex == count and count > 0) or (count == 0)

		if isArray and count > 0 then
			local parts = {}
			for i = 1, maxIndex do
				parts[i] = encodeValue(val[i])
			end
			return "[" .. table.concat(parts, ",") .. "]"
		else
			local parts = {}
			for k, v in pairs(val) do
				if type(k) == "string" then
					table.insert(parts, '"' .. k .. '":' .. encodeValue(v))
				end
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end
	end
	return "null"
end

-- Simple JSON decoder
local function skipWhitespace(str, pos)
	while pos <= #str do
		local c = str:sub(pos, pos)
		if c ~= " " and c ~= "\t" and c ~= "\n" and c ~= "\r" then
			break
		end
		pos = pos + 1
	end
	return pos
end

local decodeValue -- forward declaration

local function decodeString(str, pos)
	pos = pos + 1
	local result = ""
	while pos <= #str do
		local c = str:sub(pos, pos)
		if c == '"' then
			return result, pos + 1
		elseif c == "\\" then
			pos = pos + 1
			local escape = str:sub(pos, pos)
			if escape == "n" then
				result = result .. "\n"
			elseif escape == "r" then
				result = result .. "\r"
			elseif escape == "t" then
				result = result .. "\t"
			elseif escape == '"' then
				result = result .. '"'
			elseif escape == "\\" then
				result = result .. "\\"
			else
				result = result .. escape
			end
		else
			result = result .. c
		end
		pos = pos + 1
	end
	return nil, pos
end

local function decodeNumber(str, pos)
	local startPos = pos
	local c = str:sub(pos, pos)
	if c == "-" then
		pos = pos + 1
	end
	while pos <= #str do
		c = str:sub(pos, pos)
		if c:match("[0-9%.eE%+%-]") then
			pos = pos + 1
		else
			break
		end
	end
	local num = tonumber(str:sub(startPos, pos - 1))
	return num, pos
end

local function decodeArray(str, pos)
	pos = pos + 1
	local arr = {}
	pos = skipWhitespace(str, pos)
	if str:sub(pos, pos) == "]" then
		return arr, pos + 1
	end
	while pos <= #str do
		local val
		val, pos = decodeValue(str, pos)
		table.insert(arr, val)
		pos = skipWhitespace(str, pos)
		local c = str:sub(pos, pos)
		if c == "]" then
			return arr, pos + 1
		elseif c == "," then
			pos = skipWhitespace(str, pos + 1)
		else
			return nil, pos
		end
	end
	return nil, pos
end

local function decodeObject(str, pos)
	pos = pos + 1
	local obj = {}
	pos = skipWhitespace(str, pos)
	if str:sub(pos, pos) == "}" then
		return obj, pos + 1
	end
	while pos <= #str do
		pos = skipWhitespace(str, pos)
		if str:sub(pos, pos) ~= '"' then
			return nil, pos
		end
		local key
		key, pos = decodeString(str, pos)
		if key == nil then
			return nil, pos
		end
		pos = skipWhitespace(str, pos)
		if str:sub(pos, pos) ~= ":" then
			return nil, pos
		end
		pos = skipWhitespace(str, pos + 1)
		local val
		val, pos = decodeValue(str, pos)
		obj[key] = val
		pos = skipWhitespace(str, pos)
		local c = str:sub(pos, pos)
		if c == "}" then
			return obj, pos + 1
		elseif c == "," then
			pos = pos + 1
		else
			return nil, pos
		end
	end
	return nil, pos
end

function decodeValue(str, pos)
	pos = skipWhitespace(str, pos)
	local c = str:sub(pos, pos)
	if c == '"' then
		return decodeString(str, pos)
	elseif c == "{" then
		return decodeObject(str, pos)
	elseif c == "[" then
		return decodeArray(str, pos)
	elseif c == "t" and str:sub(pos, pos + 3) == "true" then
		return true, pos + 4
	elseif c == "f" and str:sub(pos, pos + 4) == "false" then
		return false, pos + 5
	elseif c == "n" and str:sub(pos, pos + 3) == "null" then
		return nil, pos + 4
	elseif c == "-" or c:match("[0-9]") then
		return decodeNumber(str, pos)
	end
	return nil, pos
end

local function jsonEncode(data)
	return encodeValue(data)
end

local function jsonDecode(str)
	if not str or str == "" then
		return nil
	end
	local ok, result = pcall(function()
		local val, _ = decodeValue(str, 1)
		return val
	end)
	if ok then
		return result
	end
	return nil
end

--- Check if a file exists
---@param filepath string Path to file
---@return boolean True if file exists
function Persistence.fileExists(filepath)
	local file = io.open(filepath, "r")
	if file then
		file:close()
		return true
	end
	return false
end

--- Save data to a JSON file
---@param filepath string Path to save file
---@param data table Data to save
---@return boolean success
---@return string|nil error message
function Persistence.saveData(filepath, data)
	local encoded = jsonEncode(data)
	if not encoded then
		return false, "Failed to encode data"
	end

	local file, err = io.open(filepath, "w")
	if not file then
		return false, "Failed to open file: " .. (err or "unknown error")
	end

	file:write(encoded)
	file:close()
	return true, nil
end

--- Load data from a JSON file
---@param filepath string Path to load file
---@return table|nil data
---@return string|nil error message
function Persistence.loadData(filepath)
	local file, err = io.open(filepath, "r")
	if not file then
		return nil, "Failed to open file: " .. (err or "unknown error")
	end

	local content = file:read("*all")
	file:close()

	if not content or content == "" then
		return nil, "Empty file"
	end

	local data = jsonDecode(content)
	if not data then
		return nil, "Failed to decode JSON"
	end

	return data, nil
end

--- Save games table to file
---@param filepath string Path to save file
---@param games table Games table (gameId -> game data)
---@return boolean success
function Persistence.saveGames(filepath, games)
	local success, _ = Persistence.saveData(filepath, games)
	return success
end

--- Load games table from file
---@param filepath string Path to load file
---@return table Games table (empty if file missing/corrupted)
function Persistence.loadGames(filepath)
	local data, _ = Persistence.loadData(filepath)
	if not data or type(data) ~= "table" then
		return {}
	end
	return data
end

--- Save full server state to file
---@param filepath string Path to save file
---@param state table Server state {lobby, gameSessions}
---@return boolean success
function Persistence.saveServerState(filepath, state)
	local success, _ = Persistence.saveData(filepath, state)
	return success
end

--- Load full server state from file
---@param filepath string Path to load file
---@return table Server state (default empty state if file missing)
function Persistence.loadServerState(filepath)
	local data, _ = Persistence.loadData(filepath)
	if not data or type(data) ~= "table" then
		-- Return default empty state
		return {
			lobby = {
				players = {},
				games = {},
			},
			gameSessions = {},
		}
	end

	-- Ensure required fields exist
	if not data.lobby then
		data.lobby = { players = {}, games = {} }
	end
	if not data.gameSessions then
		data.gameSessions = {}
	end

	return data
end

return Persistence
