-- Match History Module
-- Persistent game result logging for vs-AI, two-player, and multiplayer games.
-- Pure logic, no Love2D draw dependencies.
-- IO is injected so the module is testable headless.

local MatchHistory = {}

-- ---------------------------------------------------------------------------
-- JSON encode/decode (reuses the same minimal approach as protocol.lua)
-- ---------------------------------------------------------------------------

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
		-- Detect array vs object
		local isArray = true
		local maxN = 0
		for k, _ in pairs(val) do
			if type(k) ~= "number" or math.floor(k) ~= k or k < 1 then
				isArray = false
				break
			end
			if k > maxN then
				maxN = k
			end
		end
		if isArray then
			for i = 1, maxN do
				if val[i] == nil then
					isArray = false
					break
				end
			end
		end

		if isArray then
			local parts = {}
			for i = 1, maxN do
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

local function jsonEncode(val)
	return encodeValue(val)
end

-- Minimal recursive-descent JSON decoder sufficient for our data shape.
local parseValue

local function skipWS(s, pos)
	local found = s:find("[^ \t\r\n]", pos)
	return found or (pos + 1)
end

local function parseString(s, pos)
	pos = pos + 1 -- skip opening quote
	local result = {}
	local i = pos
	while i <= #s do
		local c = s:sub(i, i)
		if c == '"' then
			return table.concat(result), i + 1
		elseif c == "\\" then
			local esc = s:sub(i + 1, i + 1)
			local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", n = "\n", r = "\r", t = "\t" }
			table.insert(result, map[esc] or esc)
			i = i + 2
		else
			table.insert(result, c)
			i = i + 1
		end
	end
	error("unterminated string")
end

local function parseArray(s, pos)
	local arr = {}
	local i = pos + 1
	while true do
		i = skipWS(s, i)
		if s:sub(i, i) == "]" then
			return arr, i + 1
		end
		if s:sub(i, i) == "," then
			i = i + 1
		end
		local val, after = parseValue(s, i)
		table.insert(arr, val)
		i = after
	end
end

local function parseObject(s, pos)
	local obj = {}
	local i = pos + 1
	while true do
		i = skipWS(s, i)
		if s:sub(i, i) == "}" then
			return obj, i + 1
		end
		if s:sub(i, i) == "," then
			i = i + 1
			i = skipWS(s, i)
		end
		local key, afterKey = parseString(s, i)
		afterKey = s:find(":", afterKey)
		local val, afterVal = parseValue(s, afterKey + 1)
		obj[key] = val
		i = afterVal
	end
end

parseValue = function(s, pos)
	pos = skipWS(s, pos)
	local ch = s:sub(pos, pos)
	if ch == '"' then
		return parseString(s, pos)
	elseif ch == "[" then
		return parseArray(s, pos)
	elseif ch == "{" then
		return parseObject(s, pos)
	elseif s:sub(pos, pos + 3) == "true" then
		return true, pos + 4
	elseif s:sub(pos, pos + 4) == "false" then
		return false, pos + 5
	elseif s:sub(pos, pos + 3) == "null" then
		return nil, pos + 4
	else
		local numStr = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
		if numStr then
			return tonumber(numStr), pos + #numStr
		end
		error("unexpected char '" .. ch .. "' at pos " .. tostring(pos))
	end
end

local function jsonDecode(s)
	if not s or s == "" then
		return nil, "empty input"
	end
	local ok, result = pcall(function()
		local val, _ = parseValue(s, 1)
		return val
	end)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil
end

-- ---------------------------------------------------------------------------
-- Default Love2D-backed IO adapter (used when running inside the game).
-- In tests, callers inject a temp-file adapter instead.
-- ---------------------------------------------------------------------------

local SAVE_PATH = "match_history.json"

local function makeLoveIOAdapter()
	return {
		path = SAVE_PATH,
		write = function(content)
			-- love.filesystem.write returns true on success, nil+err on failure
			local ok, err = love.filesystem.write(SAVE_PATH, content)
			if not ok then
				return false, err
			end
			return true
		end,
		read = function()
			local data, _ = love.filesystem.read(SAVE_PATH)
			return data
		end,
	}
end

-- Return the default Love2D adapter (lazy so we don't crash when love is absent)
local function defaultIO()
	-- love may not be present in busted headless tests; guard with pcall
	local hasLove = type(love) == "table" and type(love.filesystem) == "table"
	if hasLove then
		return makeLoveIOAdapter()
	end
	-- Fallback: no-op adapter (records will not persist, but won't crash)
	return {
		path = nil,
		write = function(_)
			return false, "love.filesystem not available"
		end,
		read = function()
			return nil
		end,
	}
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- Load the raw records array from the IO adapter. Returns {} on any error.
local function loadRaw(io_adapter)
	local adapter = io_adapter or defaultIO()
	local raw = adapter.read()
	if not raw or raw == "" then
		return {}
	end
	local decoded, err = jsonDecode(raw)
	if err or type(decoded) ~= "table" then
		return {}
	end
	local records = decoded.records
	if type(records) ~= "table" then
		return {}
	end
	return records
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Record a game result, appending it to persistent storage.
--- @param result table {date, opponent, mode, result, duration_seconds, player_name}
--- @param io_adapter table|nil injected IO (uses love.filesystem when nil)
--- @return boolean, string|nil ok, errmsg
function MatchHistory.record(result, io_adapter)
	local adapter = io_adapter or defaultIO()
	local records = loadRaw(adapter)

	local entry = {
		date = result.date or "",
		opponent = result.opponent or "",
		mode = result.mode or "vsai",
		result = result.result or "loss",
		duration_seconds = result.duration_seconds or 0,
		player_name = result.player_name or "Player",
	}
	table.insert(records, entry)

	local payload = jsonEncode({ records = records })
	local ok, err = adapter.write(payload)
	if not ok then
		return false, err
	end
	return true
end

--- Load all past game results.
--- Returns an empty table (not nil) when the file is absent or corrupt.
--- @param io_adapter table|nil injected IO (uses love.filesystem when nil)
--- @return table, nil (records, err always nil — errors yield {})
function MatchHistory.load(io_adapter)
	local records = loadRaw(io_adapter or defaultIO())
	return records, nil
end

--- Compute aggregate win/loss/draw stats for a player across all recorded games.
--- @param player_name string The player name to aggregate for
--- @param io_adapter table|nil injected IO (uses love.filesystem when nil)
--- @return table {wins, losses, draws, total, by_opponent}
function MatchHistory.stats(player_name, io_adapter)
	local records = loadRaw(io_adapter or defaultIO())
	local wins, losses, draws, total = 0, 0, 0, 0
	local by_opponent = {}

	for _, r in ipairs(records) do
		total = total + 1
		local res = r.result
		if res == "win" then
			wins = wins + 1
		elseif res == "loss" then
			losses = losses + 1
		elseif res == "draw" then
			draws = draws + 1
		end

		-- Per-opponent breakdown
		local opp = r.opponent or "Unknown"
		if not by_opponent[opp] then
			by_opponent[opp] = { wins = 0, losses = 0, draws = 0 }
		end
		if res == "win" then
			by_opponent[opp].wins = by_opponent[opp].wins + 1
		elseif res == "loss" then
			by_opponent[opp].losses = by_opponent[opp].losses + 1
		elseif res == "draw" then
			by_opponent[opp].draws = by_opponent[opp].draws + 1
		end
	end

	return {
		wins = wins,
		losses = losses,
		draws = draws,
		total = total,
		by_opponent = by_opponent,
	}
end

--- Create a record guard for preventing double-recording on game-over.
--- @return table guard with .recorded field
function MatchHistory.createRecordGuard()
	return { recorded = false }
end

--- Record a result exactly once via a guard. Subsequent calls are no-ops.
--- @param guard table created by createRecordGuard()
--- @param result table game result
--- @param io_adapter table|nil injected IO
--- @return boolean, string|nil
function MatchHistory.recordOnce(guard, result, io_adapter)
	if guard.recorded then
		return false, "already recorded"
	end
	guard.recorded = true
	return MatchHistory.record(result, io_adapter)
end

return MatchHistory
