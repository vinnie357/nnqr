-- Network protocol for client-server communication
-- JSON-based message format for game state sync

local Protocol = {}

-- Simple JSON encoder/decoder (minimal implementation for Lua 5.1)
-- In production, use a library like dkjson or cjson
local json = {}

local function encodeValue(val, indent)
	local t = type(val)
	if t == "nil" then
		return "null"
	elseif t == "boolean" then
		return val and "true" or "false"
	elseif t == "number" then
		return tostring(val)
	elseif t == "string" then
		-- Escape special characters
		local escaped = val:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
		return '"' .. escaped .. '"'
	elseif t == "table" then
		-- Check if array or object
		local isArray = #val > 0 or next(val) == nil
		if isArray then
			local parts = {}
			for i, v in ipairs(val) do
				parts[i] = encodeValue(v, indent)
			end
			return "[" .. table.concat(parts, ",") .. "]"
		else
			local parts = {}
			for k, v in pairs(val) do
				if type(k) == "string" then
					table.insert(parts, '"' .. k .. '":' .. encodeValue(v, indent))
				end
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end
	end
	return "null"
end

function json.encode(val)
	return encodeValue(val, 0)
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
	pos = pos + 1 -- skip opening quote
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
	pos = pos + 1 -- skip [
	local arr = {}
	pos = skipWhitespace(str, pos)
	if str:sub(pos, pos) == "]" then
		return arr, pos + 1
	end
	while pos <= #str do
		local val
		val, pos = decodeValue(str, pos)
		if val == nil and type(pos) == "number" then
			-- Error
			return nil, pos
		end
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
	pos = pos + 1 -- skip {
	local obj = {}
	pos = skipWhitespace(str, pos)
	if str:sub(pos, pos) == "}" then
		return obj, pos + 1
	end
	while pos <= #str do
		pos = skipWhitespace(str, pos)
		-- Parse key
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
		-- Parse value
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

function json.decode(str)
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

-- Message types
Protocol.Types = {
	-- Client -> Server
	CONNECT = "CONNECT",
	JOIN_LOBBY = "JOIN_LOBBY",
	CREATE_GAME = "CREATE_GAME",
	CREATE_AI_GAME = "CREATE_AI_GAME", -- Phase 3: AI Practice
	JOIN_GAME = "JOIN_GAME",
	LEAVE_GAME = "LEAVE_GAME",
	MOVE = "MOVE",
	ACTIVATE_POWER = "ACTIVATE_POWER",
	CHAT = "CHAT",

	-- Server -> Client
	WELCOME = "WELCOME",
	ERROR = "ERROR",
	LOBBY_STATE = "LOBBY_STATE",
	GAME_CREATED = "GAME_CREATED",
	AI_GAME_CREATED = "AI_GAME_CREATED", -- Phase 3: AI Practice
	GAME_STATE = "GAME_STATE",
	MOVE_RESULT = "MOVE_RESULT",
	POWER_RESULT = "POWER_RESULT",
	GAME_OVER = "GAME_OVER",
	CHAT_MESSAGE = "CHAT_MESSAGE",
	ORB_SPAWN = "ORB_SPAWN",
}

-- Error codes
Protocol.Errors = {
	INVALID_MOVE = "INVALID_MOVE",
	NOT_YOUR_TURN = "NOT_YOUR_TURN",
	INVALID_POWER = "INVALID_POWER",
	GAME_NOT_FOUND = "GAME_NOT_FOUND",
	GAME_FULL = "GAME_FULL",
	INVALID_MESSAGE = "INVALID_MESSAGE",
}

-- Sequence counter for message ordering
local sequenceCounter = 0

--- Create a protocol message
---@param msgType string Message type from Protocol.Types
---@param payload table Message payload
---@return table Message object
function Protocol.createMessage(msgType, payload)
	sequenceCounter = sequenceCounter + 1
	return {
		type = msgType,
		payload = payload,
		timestamp = os.time() * 1000, -- milliseconds
		seq = sequenceCounter,
	}
end

--- Encode message to JSON string
---@param msg table Message object
---@return string JSON string
function Protocol.encode(msg)
	return json.encode(msg)
end

--- Decode JSON string to message
---@param str string JSON string
---@return table|nil Message object or nil if invalid
function Protocol.decode(str)
	return json.decode(str)
end

-- Message builders

--- Create CONNECT message
---@param playerName string Player's display name
---@param clientVersion string Client version
---@return table Message object
function Protocol.connectMessage(playerName, clientVersion)
	return Protocol.createMessage(Protocol.Types.CONNECT, {
		player_name = playerName,
		client_version = clientVersion,
	})
end

--- Create MOVE message
---@param from table {col, row} Starting position
---@param to table {col, row} Target position
---@return table Message object
function Protocol.moveMessage(from, to)
	return Protocol.createMessage(Protocol.Types.MOVE, {
		from = from,
		to = to,
	})
end

--- Create ACTIVATE_POWER message
---@param piecePos table {col, row} Position of piece with power
---@param powerId string Power identifier
---@param target table|nil Optional target position
---@return table Message object
function Protocol.activatePowerMessage(piecePos, powerId, target)
	return Protocol.createMessage(Protocol.Types.ACTIVATE_POWER, {
		piece_pos = piecePos,
		power_id = powerId,
		target = target,
	})
end

--- Create ERROR message
---@param code string Error code from Protocol.Errors
---@param message string Human-readable error message
---@return table Message object
function Protocol.errorMessage(code, message)
	return Protocol.createMessage(Protocol.Types.ERROR, {
		code = code,
		message = message,
	})
end

--- Create GAME_STATE message
---@param state table Game state object
---@return table Message object
function Protocol.gameStateMessage(state)
	return Protocol.createMessage(Protocol.Types.GAME_STATE, state)
end

--- Create GAME_OVER message
---@param gameId string Game ID
---@param winner number Winning player number (1 or 2)
---@param reason string|nil Optional reason for game end
---@return table Message object
function Protocol.gameOverMessage(gameId, winner, reason)
	return Protocol.createMessage(Protocol.Types.GAME_OVER, {
		game_id = gameId,
		winner = winner,
		reason = reason,
	})
end

-- Validation functions

--- Check if a message object is valid
---@param msg table Message to validate
---@return boolean True if valid
function Protocol.isValidMessage(msg)
	if type(msg) ~= "table" then
		return false
	end
	if not msg.type or type(msg.type) ~= "string" then
		return false
	end
	if not msg.payload or type(msg.payload) ~= "table" then
		return false
	end
	return true
end

--- Validate MOVE message payload
---@param payload table Payload to validate
---@return boolean True if valid
function Protocol.isValidMovePayload(payload)
	if type(payload) ~= "table" then
		return false
	end
	if not payload.from or type(payload.from) ~= "table" then
		return false
	end
	if not payload.to or type(payload.to) ~= "table" then
		return false
	end
	if not payload.from.col or not payload.from.row then
		return false
	end
	if not payload.to.col or not payload.to.row then
		return false
	end
	return true
end

-- AI Game message builders and validators (Phase 3)

-- Valid AI difficulties
Protocol.AI_DIFFICULTIES = {
	easy = true,
	medium = true,
	hard = true,
	expert = true,
}

--- Create CREATE_AI_GAME message
---@param difficulty string AI difficulty (easy/medium/hard/expert)
---@param gameName string|nil Optional game name
---@return table Message object
function Protocol.createAIGameMessage(difficulty, gameName)
	return Protocol.createMessage(Protocol.Types.CREATE_AI_GAME, {
		difficulty = difficulty,
		game_name = gameName,
	})
end

--- Create AI_GAME_CREATED message
---@param gameId string Game ID
---@param difficulty string AI difficulty
---@param playerNumber number Human player number (always 1)
---@param gameState table|nil Optional initial game state
---@return table Message object
function Protocol.aiGameCreatedMessage(gameId, difficulty, playerNumber, gameState)
	return Protocol.createMessage(Protocol.Types.AI_GAME_CREATED, {
		game_id = gameId,
		difficulty = difficulty,
		player_number = playerNumber,
		game_state = gameState,
	})
end

--- Validate CREATE_AI_GAME message payload
---@param payload table Payload to validate
---@return boolean True if valid
function Protocol.isValidAIGamePayload(payload)
	if type(payload) ~= "table" then
		return false
	end
	if not payload.difficulty then
		return false
	end
	if not Protocol.AI_DIFFICULTIES[payload.difficulty] then
		return false
	end
	return true
end

return Protocol
