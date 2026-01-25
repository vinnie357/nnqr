-- NNQR Multiplayer Server
-- Phase 10A: Network Multiplayer
-- Run with: cd lua/love2d/server && love .
--       or: mise run server (from lua/love2d)

-- Set up package path to find modules in parent directory
-- Love2D runs from the server/ directory, so we need to reach ../
local info = debug.getinfo(1, "S")
local scriptDir = info.source:match("@(.*/)")
if scriptDir then
	local parentDir = scriptDir:gsub("/server/$", "/")
	package.path = parentDir
		.. "?.lua;"
		.. parentDir
		.. "?/init.lua;"
		.. parentDir
		.. "src/?.lua;"
		.. parentDir
		.. "src/?/init.lua;"
		.. parentDir
		.. "server/?.lua;"
		.. package.path
end

-- Fallback paths for running from different locations
package.path = "../?.lua;../src/?.lua;../server/?.lua;" .. package.path
package.path = "./?.lua;./src/?.lua;./server/?.lua;" .. package.path

-- Now require our modules
local Server = require("server.server")
local Protocol = require("src.shared.protocol")
local Persistence = require("server.persistence")
local GameSession = require("server.game_session")
local ConfigLoader = require("server.config_loader")
local AdminGui = require("server.admin_gui")

-- Try to load luasocket
local socket
local hasSocket = pcall(function()
	socket = require("socket")
end)

-- Server configuration (loaded from file or defaults)
local CONFIG = nil -- Set in love.load()

-- Global server state
local server = nil
local tcpServer = nil
local clients = {} -- socket -> clientId mapping
local clientSockets = {} -- clientId -> socket mapping
local running = false
local guiMode = false
local lastAutoSave = 0

-- Log levels
local LOG_DEBUG = 1
local LOG_INFO = 2
local LOG_WARN = 3
local LOG_ERROR = 4
local logLevel = LOG_INFO

local logMessages = {} -- For GUI display
local MAX_LOG_MESSAGES = 100

--- Log a message
---@param level number Log level
---@param message string Message to log
local function log(level, message)
	if level < logLevel then
		return
	end

	local levelNames = { "DEBUG", "INFO", "WARN", "ERROR" }
	local timestamp = os.date("%H:%M:%S")
	local formatted = string.format("[%s] [%s] %s", timestamp, levelNames[level] or "?", message)

	print(formatted)

	-- Store for GUI
	table.insert(logMessages, formatted)
	if #logMessages > MAX_LOG_MESSAGES then
		table.remove(logMessages, 1)
	end
end

--- Send a message to a client
---@param clientId string Client ID
---@param message table Protocol message
local function sendToClient(clientId, message)
	local sock = clientSockets[clientId]
	if not sock then
		log(LOG_WARN, "Cannot send to client " .. clientId .. ": socket not found")
		return false
	end

	local encoded = Protocol.encode(message) .. "\n"
	local success, err = sock:send(encoded)
	if not success then
		log(LOG_WARN, "Failed to send to client " .. clientId .. ": " .. (err or "unknown"))
		return false
	end
	return true
end

--- Handle a new client connection
---@param clientSocket table Client socket
local function handleNewConnection(clientSocket)
	clientSocket:settimeout(0) -- Non-blocking
	local clientId = Server.addClient(server, clientSocket)
	clients[clientSocket] = clientId
	clientSockets[clientId] = clientSocket

	local ip, port = clientSocket:getpeername()
	log(LOG_INFO, "New connection from " .. (ip or "?") .. ":" .. (port or "?") .. " (client: " .. clientId .. ")")
end

--- Handle client disconnection
---@param clientSocket table Client socket
local function handleDisconnect(clientSocket)
	local clientId = clients[clientSocket]
	if clientId then
		log(LOG_INFO, "Client disconnected: " .. clientId)
		Server.removeClient(server, clientId)
		clients[clientSocket] = nil
		clientSockets[clientId] = nil
	end
	clientSocket:close()
end

--- Handle incoming data from a client
---@param clientSocket table Client socket
---@param data string Received data
local function handleClientData(clientSocket, data)
	local clientId = clients[clientSocket]
	if not clientId then
		log(LOG_WARN, "Data from unknown socket")
		return
	end

	-- Parse JSON message
	local message = Protocol.decode(data)
	if not message then
		log(LOG_WARN, "Invalid JSON from client " .. clientId)
		sendToClient(clientId, Protocol.errorMessage("INVALID_MESSAGE", "Invalid JSON"))
		return
	end

	log(LOG_DEBUG, "Received from " .. clientId .. ": " .. (message.type or "?"))

	-- Handle message
	local response = Server.handleMessage(server, clientId, message)
	if response then
		sendToClient(clientId, response)

		-- If game started, notify both players
		if response.type == "GAME_STATE" and message.type == "JOIN_GAME" then
			-- Notify the game creator too
			local gameId = message.payload.game_id
			local game = server.lobby.games[gameId]
			if game and #game.players >= 2 then
				local otherPlayerId = game.players[1]
				local otherClientId = Server.findClientByPlayerId(server, otherPlayerId)
				if otherClientId and otherClientId ~= clientId then
					sendToClient(otherClientId, response)
				end
			end
		end
	end
end

--- Poll all client sockets for data
local function pollClients()
	if not tcpServer then
		return
	end

	-- Check for new connections
	local newClient = tcpServer:accept()
	if newClient then
		handleNewConnection(newClient)
	end

	-- Check existing clients for data
	local toRemove = {}
	for clientSocket, _ in pairs(clients) do
		local data, err, partial = clientSocket:receive("*l")

		if data then
			handleClientData(clientSocket, data)
		elseif partial and #partial > 0 then
			-- Partial data received (incomplete line)
			-- In production, buffer this
		elseif err == "closed" then
			table.insert(toRemove, clientSocket)
		end
		-- "timeout" is normal for non-blocking sockets
	end

	-- Remove disconnected clients
	for _, sock in ipairs(toRemove) do
		handleDisconnect(sock)
	end
end

--- Auto-save server state
local function autoSave()
	local now = love.timer.getTime()
	if now - lastAutoSave >= CONFIG.persistence.autoSaveInterval then
		log(LOG_DEBUG, "Auto-saving server state...")
		local state = {
			lobby = server.lobby,
			gameSessions = server.gameSessions,
		}
		Persistence.saveServerState(CONFIG.persistence.filepath, state)
		lastAutoSave = now
	end
end

--- Love2D load callback
function love.load(args)
	-- Load configuration from file
	local configPath = "../server_config.lua"
	local loadedConfig, configErr = ConfigLoader.load(configPath)
	if loadedConfig then
		CONFIG = loadedConfig
	else
		-- Use defaults if config failed to load
		print("Warning: Failed to load config: " .. (configErr or "unknown"))
		CONFIG = ConfigLoader.getDefaults()
	end

	-- Check for command-line flags (override config file)
	for _, arg in ipairs(args or {}) do
		if arg == "--gui" then
			guiMode = true
		elseif arg:match("^%-%-port=(%d+)$") then
			CONFIG.port = tonumber(arg:match("^%-%-port=(%d+)$"))
		elseif arg == "--debug" then
			CONFIG.logging.level = "debug"
		elseif arg:match("^%-%-config=(.+)$") then
			-- Allow specifying a different config file
			local customPath = arg:match("^%-%-config=(.+)$")
			local customConfig, customErr = ConfigLoader.load(customPath)
			if customConfig then
				CONFIG = customConfig
			else
				print("Warning: Failed to load custom config: " .. (customErr or "unknown"))
			end
		end
	end

	-- Set log level from config
	local levelMap = { debug = LOG_DEBUG, info = LOG_INFO, warn = LOG_WARN, error = LOG_ERROR }
	logLevel = levelMap[CONFIG.logging.level] or LOG_INFO

	log(LOG_INFO, "NNQR Server starting...")
	log(LOG_INFO, "GUI mode: " .. tostring(guiMode))
	log(LOG_INFO, "Config loaded from: " .. configPath)

	-- Create server
	server = Server.create(CONFIG)

	-- Load persisted state if available
	if Persistence.fileExists(CONFIG.persistence.filepath) then
		log(LOG_INFO, "Loading saved state from " .. CONFIG.persistence.filepath)
		local state = Persistence.loadServerState(CONFIG.persistence.filepath)
		server.lobby = state.lobby or server.lobby
		server.gameSessions = state.gameSessions or server.gameSessions
	end

	-- Initialize TCP server
	if hasSocket then
		tcpServer = socket.tcp()
		tcpServer:settimeout(0) -- Non-blocking
		local success, err = tcpServer:bind("*", CONFIG.port)
		if success then
			tcpServer:listen(10)
			running = true
			log(LOG_INFO, "Server listening on port " .. CONFIG.port)
		else
			log(LOG_ERROR, "Failed to bind to port " .. CONFIG.port .. ": " .. (err or "unknown"))
		end
	else
		log(LOG_ERROR, "luasocket not available - server cannot accept connections")
		log(LOG_INFO, "Install luasocket: luarocks install luasocket")
	end

	lastAutoSave = love.timer.getTime()
end

--- Update AI games and broadcast state changes
local function updateAIGames(dt)
	local moves = Server.updateAIGames(server, dt)

	-- Broadcast game state to clients for each AI move
	for _, moveInfo in ipairs(moves) do
		local gameId = moveInfo.gameId
		local session = server.gameSessions[gameId]

		if session then
			-- Find the human player's client
			local clientId = Server.findClientByPlayerId(server, session.player1Id)
			if clientId then
				if moveInfo.gameOver then
					-- Send GAME_OVER message
					local gameOverMsg = Protocol.gameOverMessage(gameId, moveInfo.winner)
					sendToClient(clientId, gameOverMsg)
					log(LOG_INFO, "Game " .. gameId .. " ended. Winner: Player " .. moveInfo.winner)
				else
					-- Send updated game state
					local stateMsg = Protocol.gameStateMessage(moveInfo.state)
					sendToClient(clientId, stateMsg)
					log(LOG_DEBUG, "AI moved in game " .. gameId)
				end
			end
		end
	end
end

--- Love2D update callback
function love.update(dt)
	if running then
		pollClients()
		updateAIGames(dt)
		autoSave()
	end
end

--- Kick a player from the server
---@param playerId string Player ID to kick
local function kickPlayer(playerId)
	local clientId = Server.findClientByPlayerId(server, playerId)
	if clientId then
		local sock = clientSockets[clientId]
		if sock then
			log(LOG_INFO, "Kicking player: " .. playerId)
			handleDisconnect(sock)
		end
	end
end

--- End a game forcefully
---@param gameId string Game ID to end
local function endGame(gameId)
	local Lobby = require("server.lobby")
	log(LOG_INFO, "Ending game: " .. gameId)
	Lobby.endGame(server.lobby, gameId, nil)
end

--- Toggle server running state
local function toggleServer()
	if running then
		log(LOG_INFO, "Stopping server...")
		running = false
		if tcpServer then
			tcpServer:close()
			tcpServer = nil
		end
	else
		log(LOG_INFO, "Starting server...")
		if hasSocket then
			tcpServer = socket.tcp()
			tcpServer:settimeout(0)
			local success, err = tcpServer:bind("*", CONFIG.port)
			if success then
				tcpServer:listen(10)
				running = true
				log(LOG_INFO, "Server listening on port " .. CONFIG.port)
			else
				log(LOG_ERROR, "Failed to bind: " .. (err or "unknown"))
			end
		end
	end
end

--- Love2D draw callback (GUI mode only)
function love.draw()
	if not guiMode then
		return
	end

	AdminGui.draw(CONFIG, server, running, logMessages, {
		kick = kickPlayer,
		endGame = endGame,
		toggleServer = toggleServer,
	})
end

--- Love2D mouse wheel callback
function love.wheelmoved(x, y)
	if guiMode then
		AdminGui.wheelmoved(x, y)
	end
end

--- Love2D keypressed callback (GUI mode only)
function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "s" then
		-- Manual save
		log(LOG_INFO, "Manual save triggered")
		local saveState = {
			lobby = server.lobby,
			gameSessions = server.gameSessions,
		}
		Persistence.saveServerState(CONFIG.persistence.filepath, saveState)
	elseif guiMode then
		AdminGui.keypressed(key)
	end
end

--- Love2D quit callback
function love.quit()
	log(LOG_INFO, "Server shutting down...")

	-- Save state
	if server then
		local state = {
			lobby = server.lobby,
			gameSessions = server.gameSessions,
		}
		Persistence.saveServerState(CONFIG.persistence.filepath, state)
		log(LOG_INFO, "State saved")
	end

	-- Close all client connections
	for clientSocket, _ in pairs(clients) do
		clientSocket:close()
	end

	-- Close server socket
	if tcpServer then
		tcpServer:close()
	end

	log(LOG_INFO, "Server stopped")
end
