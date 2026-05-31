-- ScenarioRunner — see-harness for the AI QA loop.
--
-- Invoked via love with --scenario <path>:
--   love . --scenario scenarios/initial.json
--
-- Reads the scenario JSON, builds the real game state, renders ONE frame to a
-- Love2D canvas, saves the canvas pixels as .qa/frame.png, dumps the resulting
-- state as .qa/state.json, then calls love.event.quit().
--
-- When --scenario is absent, this module is inactive and the normal game runs.

local GameLogic = require("src.shared.game_logic")
local Height = require("src.shared.height")

local ScenarioRunner = {}

-- Capture the process working directory at module load time (before Love2D
-- changes it).  os.popen("pwd") is available in Love2D 11.x on macOS/Linux.
-- This is the CWD at the time `love .` was invoked, i.e. lua/love2d/.
local _cwd = nil
local function getCwd()
	if not _cwd then
		local handle = io.popen("pwd")
		if handle then
			_cwd = handle:read("*l")
			handle:close()
		end
	end
	return _cwd or "."
end

-- Absolute path to the game/project directory on disk.
-- We derive this from the process CWD captured at module load time, because
-- love.filesystem.getSource() on macOS returns the directory *passed* to the
-- love executable (which may not include the trailing component when using
-- a relative path like ".").
local function projectRoot()
	return getCwd()
end

-- Resolve the abs filesystem path for a file inside the project.
local function projectPath(rel)
	return projectRoot() .. "/" .. rel
end

-- Ensure a directory exists via io (love.filesystem.createDirectory only works
-- inside the save directory, not the project directory).
local function ensureDir(absPath)
	-- os.execute is available in Love2D 11.x
	os.execute('mkdir -p "' .. absPath .. '"')
end

-- Write text to an absolute filesystem path.
local function writeFile(absPath, content)
	local f = io.open(absPath, "w")
	if not f then
		error("ScenarioRunner: cannot open for write: " .. absPath)
	end
	f:write(content)
	f:close()
end

-- Write binary data (string of bytes) to an absolute filesystem path.
local function writeBinaryFile(absPath, data)
	local f = io.open(absPath, "wb")
	if not f then
		error("ScenarioRunner: cannot open for binary write: " .. absPath)
	end
	f:write(data)
	f:close()
end

-- Simple JSON serialiser (no external dependency).
-- Handles strings, numbers, booleans, nil, arrays (tables with integer keys),
-- and objects (tables with string keys).
local function toJson(val, indent)
	indent = indent or ""
	local nextIndent = indent .. "  "
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
		-- Detect array vs object: array has consecutive integer keys starting at 1
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
		-- Also check no gaps
		if isArray then
			for i = 1, maxN do
				if val[i] == nil then
					isArray = false
					break
				end
			end
		end

		if isArray and maxN == 0 then
			return "[]"
		elseif isArray then
			local parts = {}
			for i = 1, maxN do
				table.insert(parts, nextIndent .. toJson(val[i], nextIndent))
			end
			return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
		else
			local parts = {}
			for k, v in pairs(val) do
				if type(k) == "string" then
					table.insert(parts, nextIndent .. '"' .. k .. '": ' .. toJson(v, nextIndent))
				end
			end
			table.sort(parts)
			return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
		end
	end
	return '"[unsupported:' .. t .. ']"'
end

-- Parse --scenario <path> from love.load arg table.
-- Love2D 11.x passes the arg table from the command line; custom args follow
-- the directory/file argument. The arg table is indexed from 1.
local function parseScenarioArg(arg)
	if not arg then
		return nil
	end
	for i = 1, #arg do
		if arg[i] == "--scenario" and arg[i + 1] then
			return arg[i + 1]
		end
	end
	return nil
end

-- Load and parse a JSON file using Love2D's filesystem OR io.open (for paths
-- outside the save directory).
local function loadJsonFile(path)
	-- Try love.filesystem first (works for relative paths inside the game dir)
	local data, size = love.filesystem.read(path)
	if not data then
		-- Fall back to absolute path via io
		local f = io.open(path, "r")
		if not f then
			-- Try relative to project root
			local absPath = projectPath(path)
			f = io.open(absPath, "r")
		end
		if not f then
			return nil, "cannot open: " .. path
		end
		data = f:read("*a")
		f:close()
	end

	-- Minimal JSON parser using Lua pattern matching.
	-- We use a recursive descent approach sufficient for our scenario format.
	local ok, result = pcall(function()
		return ScenarioRunner.parseJson(data)
	end)
	if not ok then
		return nil, "JSON parse error: " .. tostring(result)
	end
	return result, nil
end

-- ---------------------------------------------------------------------------
-- Minimal JSON parser
-- ---------------------------------------------------------------------------

-- Returns parsed Lua value and the position after it.
local function parseValue(s, pos)
	-- Skip whitespace
	pos = s:find("[^ \t\r\n]", pos) or (pos + 1)

	local ch = s:sub(pos, pos)

	if ch == '"' then
		-- String
		local result = {}
		local i = pos + 1
		while i <= #s do
			local c = s:sub(i, i)
			if c == '"' then
				return table.concat(result), i + 1
			elseif c == "\\" then
				local esc = s:sub(i + 1, i + 1)
				local map = {
					['"'] = '"',
					["\\"] = "\\",
					["/"] = "/",
					["n"] = "\n",
					["r"] = "\r",
					["t"] = "\t",
				}
				table.insert(result, map[esc] or esc)
				i = i + 2
			else
				table.insert(result, c)
				i = i + 1
			end
		end
		error("unterminated string at pos " .. pos)
	elseif ch == "{" then
		-- Object
		local obj = {}
		local i = pos + 1
		while true do
			i = s:find("[^ \t\r\n]", i) or (i + 1)
			if s:sub(i, i) == "}" then
				return obj, i + 1
			end
			if s:sub(i, i) == "," then
				i = i + 1
				i = s:find("[^ \t\r\n]", i) or (i + 1)
			end
			-- Key
			local key, afterKey = parseValue(s, i)
			-- Colon
			afterKey = s:find(":", afterKey)
			-- Value
			local val, afterVal = parseValue(s, afterKey + 1)
			obj[key] = val
			i = afterVal
		end
	elseif ch == "[" then
		-- Array
		local arr = {}
		local i = pos + 1
		while true do
			i = s:find("[^ \t\r\n]", i) or (i + 1)
			if s:sub(i, i) == "]" then
				return arr, i + 1
			end
			if s:sub(i, i) == "," then
				i = i + 1
			end
			local val, afterVal = parseValue(s, i)
			table.insert(arr, val)
			i = afterVal
		end
	elseif s:sub(pos, pos + 3) == "true" then
		return true, pos + 4
	elseif s:sub(pos, pos + 4) == "false" then
		return false, pos + 5
	elseif s:sub(pos, pos + 3) == "null" then
		return nil, pos + 4
	else
		-- Number
		local numStr = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
		if numStr then
			return tonumber(numStr), pos + #numStr
		end
		error("unexpected character '" .. ch .. "' at pos " .. pos)
	end
end

function ScenarioRunner.parseJson(s)
	local val, _ = parseValue(s, 1)
	return val
end

-- ---------------------------------------------------------------------------
-- Build game state from scenario dict
-- ---------------------------------------------------------------------------

local function buildStateFromScenario(dict)
	-- Start with a clean initial state (creates pieces, heightMap, etc.)
	local state = GameLogic.createInitialState()

	-- Override board dimensions if provided
	if dict.rows then
		state.rows = dict.rows
	end
	if dict.cols then
		state.cols = dict.cols
	end

	-- Override current player
	if dict.current_player then
		state.currentPlayer = dict.current_player
	end

	-- Override turn
	if dict.turn then
		state.turn = dict.turn
	end

	-- Override pieces if provided (replaces auto-generated ones)
	if dict.pieces then
		state.pieces = {}
		for _, p in ipairs(dict.pieces) do
			table.insert(state.pieces, {
				player = p.player or 1,
				row = p.row or 1,
				col = p.col or 1,
				powers = p.powers or {},
			})
		end
	end

	-- Apply height overrides
	if dict.heights then
		for _, h in ipairs(dict.heights) do
			if h.row and h.col and h.height then
				GameLogic.setHeight(state, h.row, h.col, h.height)
			end
		end
	end

	-- Apply destroyed tiles
	if dict.destroyed_tiles then
		for _, t in ipairs(dict.destroyed_tiles) do
			if t.row and t.col then
				GameLogic.destroyTile(state, t.row, t.col)
			end
		end
	end

	return state
end

-- ---------------------------------------------------------------------------
-- State serialisation for state.json
-- ---------------------------------------------------------------------------

local function serializeState(state)
	-- Build a plain table representation safe for JSON serialisation.
	-- Avoid serialising function references or cyclic references.
	local out = {
		rows = state.rows,
		cols = state.cols,
		currentPlayer = state.currentPlayer,
		turn = state.turn,
		gameState = state.gameState,
		winner = state.winner,
		pieces = {},
		heightMap = {},
		destroyedTiles = {},
	}

	for _, p in ipairs(state.pieces or {}) do
		table.insert(out.pieces, {
			player = p.player,
			row = p.row,
			col = p.col,
			powers = p.powers or {},
		})
	end

	-- Flatten heightMap to a list of non-zero entries for compactness
	if state.heightMap then
		for r = 1, state.rows do
			for c = 1, state.cols do
				local h = GameLogic.getHeight(state, r, c)
				if h ~= 0 then
					table.insert(out.heightMap, { row = r, col = c, height = h })
				end
			end
		end
	end

	-- Flatten destroyedTiles
	if state.destroyedTiles then
		for key, _ in pairs(state.destroyedTiles) do
			table.insert(out.destroyedTiles, key)
		end
	end

	return out
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Detect --scenario in args and return the path, or nil.
function ScenarioRunner.detect(arg)
	return parseScenarioArg(arg)
end

-- Run the scenario: load state, render one frame to canvas, save artifacts, quit.
-- Called from love.load() when --scenario is detected.
-- Returns the Game state so the render callback can draw it.
function ScenarioRunner.run(arg, Game)
	local scenarioPath = parseScenarioArg(arg)
	if not scenarioPath then
		return nil
	end

	print("ScenarioRunner: loading scenario: " .. scenarioPath)

	local dict, err = loadJsonFile(scenarioPath)
	if not dict then
		error("ScenarioRunner: failed to load scenario: " .. tostring(err))
	end

	-- Build game state from scenario
	local state = buildStateFromScenario(dict)

	-- Initialise game rendering infrastructure that main.lua's Game.init() sets up,
	-- but we call directly here so we don't run the full init (which resets state).
	love.graphics.setBackgroundColor(Game.colors.background)
	Game.boardOffsetX = love.graphics.getWidth() / 2
	Game.boardOffsetY = 120
	local UI = require("src.shared.ui")
	Game.uiState = UI.createState()

	-- Allow scenario to specify a non-playing screen (e.g. history)
	local targetScreen = dict.screen or "playing"
	if not UI.SCREENS[targetScreen] then
		targetScreen = "playing"
	end
	UI.setScreen(Game.uiState, targetScreen)

	-- Seed match history data for history-screen scenarios
	if dict.seed_history then
		local MatchHistory = require("src.shared.match_history")
		-- Build a temporary in-memory IO adapter that writes to the Love2D save dir
		-- We use a known temp name so we can pre-populate it before the draw call.
		local seedPath = "scenario_seed_history.json"
		local seedIO = {
			path = seedPath,
			write = function(content)
				local ok, err = love.filesystem.write(seedPath, content)
				return ok, err
			end,
			read = function()
				local data, _ = love.filesystem.read(seedPath)
				return data
			end,
		}
		local sampleGames = {
			{
				date = "2026-05-28",
				opponent = "AI-easy",
				mode = "vsai",
				result = "win",
				duration_seconds = 142,
				player_name = "Player",
			},
			{
				date = "2026-05-28",
				opponent = "Player 2",
				mode = "twoplayer",
				result = "loss",
				duration_seconds = 87,
				player_name = "Player",
			},
			{
				date = "2026-05-29",
				opponent = "AI-hard",
				mode = "vsai",
				result = "loss",
				duration_seconds = 310,
				player_name = "Player",
			},
			{
				date = "2026-05-29",
				opponent = "Online opponent",
				mode = "multiplayer",
				result = "win",
				duration_seconds = 203,
				player_name = "Player",
			},
			{
				date = "2026-05-30",
				opponent = "AI-medium",
				mode = "vsai",
				result = "win",
				duration_seconds = 178,
				player_name = "Player",
			},
			{
				date = "2026-05-30",
				opponent = "Player 2",
				mode = "twoplayer",
				result = "draw",
				duration_seconds = 410,
				player_name = "Player",
			},
		}
		for _, entry in ipairs(sampleGames) do
			MatchHistory.record(entry, seedIO)
		end
		-- Override the default IO so the history screen reads from our seed
		Game._scenarioHistoryIO = seedIO
	end

	Game.state = state
	Game.hoveredTile = nil
	Game.orbs = {}
	Game.animations = require("src.shared.game_animations").create()
	Game.soundManager = nil
	Game.loadedSounds = {}
	Game.particles = require("src.shared.particles").create()
	Game.powerMode = nil
	Game.powerTargets = {}
	Game.ai = nil
	Game.multiplayer = nil
	Game.turnBanner = { active = false, timer = 0, duration = 2.0, player = 1 }

	print(
		string.format(
			"ScenarioRunner: state built — %d pieces, currentPlayer=%d, turn=%d",
			#state.pieces,
			state.currentPlayer,
			state.turn
		)
	)

	return state
end

-- Called from love.draw() when in scenario mode: renders to canvas, saves PNG + JSON, quits.
-- scenarioState is the state returned from ScenarioRunner.run().
-- Game is the Game module.
-- qaDir is the absolute path to the .qa/ output directory.
function ScenarioRunner.captureAndQuit(Game, qaDir)
	-- Render game to an offscreen canvas at the window resolution
	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()
	local canvas = love.graphics.newCanvas(w, h)

	love.graphics.setCanvas(canvas)
	love.graphics.clear(Game.colors.background)
	Game.draw()
	love.graphics.setCanvas()

	-- Save PNG
	ensureDir(qaDir)
	local pngPath = qaDir .. "/frame.png"

	-- canvas:newImageData() gives us pixel data; encode to PNG string
	local imageData = canvas:newImageData()
	local fileData = imageData:encode("png")
	-- fileData is a love.FileData; get its raw bytes
	local bytes = fileData:getString()
	writeBinaryFile(pngPath, bytes)

	local info = love.filesystem.getInfo and love.filesystem.getInfo(pngPath)
	-- Confirm via io.open since pngPath is an abs path
	local fcheck = io.open(pngPath, "rb")
	local pngSize = 0
	if fcheck then
		fcheck:seek("end")
		pngSize = fcheck:seek()
		fcheck:close()
	end
	print(string.format("ScenarioRunner: frame.png saved — %d bytes at %s", pngSize, pngPath))

	-- Save state.json
	local jsonPath = qaDir .. "/state.json"
	local stateOut = serializeState(Game.state)
	writeFile(jsonPath, toJson(stateOut))
	print("ScenarioRunner: state.json saved at " .. jsonPath)

	-- Quit
	love.event.quit()
end

return ScenarioRunner
