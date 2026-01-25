-- Server core module for multiplayer
-- Handles client connections, message routing, and game management
-- Phase 10A: Network Multiplayer

local Lobby = require("server.lobby")
local Protocol = require("src.shared.protocol")
local GameSession = require("server.game_session")
local Stats = require("server.stats")

local Server = {}

-- Forward declarations
local findPlayerGameSession

-- Client ID counter for unique IDs
local clientIdCounter = 0

--- Generate a unique client ID
---@return string Client ID
local function generateClientId()
	clientIdCounter = clientIdCounter + 1
	return "client_" .. clientIdCounter
end

--- Generate a unique player ID
---@return string Player ID
local function generatePlayerId()
	return "player_" .. os.time() .. "_" .. math.random(1000, 9999)
end

--- Create a new server instance
---@param config table Server configuration
---@return table Server state
function Server.create(config)
	config = config or {}
	return {
		port = config.port or 7777,
		maxGames = config.maxGames or 10,
		clients = {}, -- clientId -> {socket, state, playerId}
		lobby = Lobby.create(),
		gameSessions = {}, -- gameId -> GameSession state
		playerStats = {}, -- playerId -> Stats object
		running = false,
		socket = nil, -- TCP server socket (set by start())
	}
end

--- Add a new client connection
---@param server table Server state
---@param socket table Client socket
---@return string clientId
function Server.addClient(server, socket)
	local clientId = generateClientId()
	server.clients[clientId] = {
		socket = socket,
		state = "connected", -- connected, authenticated
		playerId = nil,
		connectedAt = os.time(),
	}
	return clientId
end

-- Disconnect timeout constant
local DISCONNECT_TIMEOUT = 60

--- Remove a client connection
---@param server table Server state
---@param clientId string Client ID to remove
---@return boolean success
---@return table|nil notification {type, opponentClientId, gameId, opponentName, timeout}
function Server.removeClient(server, clientId)
	local client = server.clients[clientId]
	if not client then
		return false, nil
	end

	local notification = nil

	-- Check if player was in an active game
	if client.playerId then
		local session, gameId = findPlayerGameSession(server, client.playerId)
		if session and session.status == "playing" then
			-- Find opponent
			local opponentId = nil
			local playerNumber = nil
			if session.player1Id == client.playerId then
				opponentId = session.player2Id
				playerNumber = 1
			elseif session.player2Id == client.playerId then
				opponentId = session.player1Id
				playerNumber = 2
			end

			-- Only notify for PvP games (not AI games)
			if opponentId and not GameSession.isAIGame(session) then
				local opponentClientId = Server.findClientByPlayerId(server, opponentId)
				if opponentClientId then
					-- Get disconnecting player's name
					local player = server.lobby.players[client.playerId]
					local playerName = player and player.name or "Opponent"

					-- Mark player as disconnected in session
					session.disconnectedPlayer = playerNumber
					session.disconnectTime = os.time()

					notification = {
						type = "opponent_disconnected",
						opponentClientId = opponentClientId,
						gameId = gameId,
						opponentName = playerName,
						timeout = DISCONNECT_TIMEOUT,
					}
				end
			end
		end

		-- Remove from lobby
		Lobby.removePlayer(server.lobby, client.playerId)
	end

	server.clients[clientId] = nil
	return true, notification
end

--- Get a client by ID
---@param server table Server state
---@param clientId string Client ID
---@return table|nil Client data
function Server.getClient(server, clientId)
	return server.clients[clientId]
end

--- Get the number of connected clients
---@param server table Server state
---@return number Client count
function Server.getClientCount(server)
	local count = 0
	for _ in pairs(server.clients) do
		count = count + 1
	end
	return count
end

--- Find client ID by player ID
---@param server table Server state
---@param playerId string Player ID
---@return string|nil clientId
function Server.findClientByPlayerId(server, playerId)
	for clientId, client in pairs(server.clients) do
		if client.playerId == playerId then
			return clientId
		end
	end
	return nil
end

--- Get all client IDs in a game
---@param server table Server state
---@param gameId string Game ID
---@return table Array of client IDs
function Server.getClientsInGame(server, gameId)
	local clientIds = {}
	local game = server.lobby.games[gameId]
	if not game then
		return clientIds
	end

	for _, playerId in ipairs(game.players) do
		local clientId = Server.findClientByPlayerId(server, playerId)
		if clientId then
			table.insert(clientIds, clientId)
		end
	end

	return clientIds
end

-- Message handlers

--- Handle CONNECT message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleConnect(server, clientId, payload)
	local client = server.clients[clientId]

	-- Reject if already authenticated
	if client.playerId then
		return Protocol.createMessage("ERROR", {
			code = "ALREADY_CONNECTED",
			message = "Client already authenticated",
		})
	end

	local playerName = payload.player_name
	if not playerName or playerName == "" then
		return Protocol.createMessage("ERROR", {
			code = "INVALID_NAME",
			message = "Player name is required",
		})
	end

	-- Generate player ID and try to add to lobby
	local playerId = generatePlayerId()
	local success, err = Lobby.addPlayer(server.lobby, playerId, playerName)

	if not success then
		local code = "NAME_TAKEN"
		if err == "Player already in lobby" then
			code = "ALREADY_CONNECTED"
		end
		return Protocol.createMessage("ERROR", {
			code = code,
			message = err,
		})
	end

	-- Update client state
	client.playerId = playerId
	client.state = "authenticated"

	-- Create stats for new player
	server.playerStats[playerId] = Stats.create()

	return Protocol.createMessage("WELCOME", {
		server_version = "0.1.0",
		player_id = playerId,
	})
end

--- Handle JOIN_LOBBY message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleJoinLobby(server, clientId, payload)
	local games = Lobby.listGames(server.lobby)
	return Protocol.createMessage("LOBBY_STATE", {
		games = games,
		players_online = Lobby.getPlayerCount(server.lobby),
	})
end

--- Handle CREATE_GAME message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleCreateGame(server, clientId, payload)
	local client = server.clients[clientId]
	local gameName = payload.game_name or "Unnamed Game"
	local settings = payload.settings

	local gameId, err = Lobby.createGame(server.lobby, client.playerId, gameName, settings)

	if not gameId then
		return Protocol.createMessage("ERROR", {
			code = "CREATE_GAME_FAILED",
			message = err,
		})
	end

	return Protocol.createMessage("GAME_CREATED", {
		game_id = gameId,
	})
end

--- Handle JOIN_GAME message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleJoinGame(server, clientId, payload)
	local client = server.clients[clientId]
	local gameId = payload.game_id

	if not gameId then
		return Protocol.createMessage("ERROR", {
			code = "INVALID_MESSAGE",
			message = "game_id is required",
		})
	end

	-- Check if game exists
	local game = Lobby.getGame(server.lobby, gameId)
	if not game then
		return Protocol.createMessage("ERROR", {
			code = "GAME_NOT_FOUND",
			message = "Game not found",
		})
	end

	local success, err = Lobby.joinGame(server.lobby, client.playerId, gameId)

	if not success then
		local code = "JOIN_GAME_FAILED"
		if err == "Game is full" or err == "Game already started" then
			code = "GAME_FULL"
		end
		return Protocol.createMessage("ERROR", {
			code = code,
			message = err,
		})
	end

	-- Check if game started (2 players)
	game = Lobby.getGame(server.lobby, gameId)
	if game.status == "playing" then
		-- Return initial game state
		-- TODO: Create actual game session with GameLogic
		return Protocol.createMessage("GAME_STATE", {
			game_id = gameId,
			turn = 1,
			current_player = 1,
			phase = "move",
			board = { cols = 10, rows = 8, tiles = {} },
			pieces = {},
			winner = nil,
		})
	end

	-- Game still waiting for players
	return Protocol.createMessage("GAME_JOINED", {
		game_id = gameId,
		status = "waiting",
	})
end

--- Handle LEAVE_GAME message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleLeaveGame(server, clientId, payload)
	local client = server.clients[clientId]
	local success, err = Lobby.leaveGame(server.lobby, client.playerId)

	if not success then
		return Protocol.createMessage("ERROR", {
			code = "LEAVE_GAME_FAILED",
			message = err,
		})
	end

	-- Return to lobby
	local games = Lobby.listGames(server.lobby)
	return Protocol.createMessage("LOBBY_STATE", {
		games = games,
		players_online = Lobby.getPlayerCount(server.lobby),
	})
end

-- Game ID counter for AI games
local aiGameIdCounter = 0

--- Generate a unique AI game ID
---@return string Game ID
local function generateAIGameId()
	aiGameIdCounter = aiGameIdCounter + 1
	return "ai_game_" .. os.time() .. "_" .. aiGameIdCounter
end

--- Handle CREATE_AI_GAME message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleCreateAIGame(server, clientId, payload)
	local client = server.clients[clientId]

	-- Check if player is already in a game
	for _, session in pairs(server.gameSessions) do
		if session.player1Id == client.playerId or session.player2Id == client.playerId then
			return Protocol.createMessage("ERROR", {
				code = "ALREADY_IN_GAME",
				message = "Already in a game",
			})
		end
	end

	-- Validate difficulty
	if not Protocol.isValidAIGamePayload(payload) then
		return Protocol.createMessage("ERROR", {
			code = "INVALID_DIFFICULTY",
			message = "Invalid AI difficulty",
		})
	end

	local difficulty = payload.difficulty
	local gameId = generateAIGameId()

	-- Create AI game session
	local session = GameSession.createAIGame(gameId, client.playerId, difficulty)
	server.gameSessions[gameId] = session

	-- Get initial game state to include in response
	local initialState = GameSession.getState(session)

	-- Return AI_GAME_CREATED with game state included
	return Protocol.aiGameCreatedMessage(gameId, difficulty, 1, initialState)
end

--- Find game session for a player
---@param server table Server state
---@param playerId string Player ID
---@return table|nil session, string|nil gameId
function findPlayerGameSession(server, playerId)
	for gameId, session in pairs(server.gameSessions) do
		if session.player1Id == playerId or session.player2Id == playerId then
			return session, gameId
		end
	end
	return nil, nil
end

--- Handle MOVE message
---@param server table Server state
---@param clientId string Client ID
---@param payload table Message payload
---@return table Response message
local function handleMove(server, clientId, payload)
	local client = server.clients[clientId]

	-- Find the player's game session
	local session, gameId = findPlayerGameSession(server, client.playerId)
	if not session then
		return Protocol.createMessage("ERROR", {
			code = "NOT_IN_GAME",
			message = "Not in a game",
		})
	end

	-- Validate move payload
	if not Protocol.isValidMovePayload(payload) then
		return Protocol.createMessage("ERROR", {
			code = "INVALID_MESSAGE",
			message = "Invalid move payload",
		})
	end

	-- Execute move via GameSession
	local result = GameSession.handleMove(session, client.playerId, {
		from = payload.from,
		to = payload.to,
	})

	if not result.success then
		return Protocol.createMessage("ERROR", {
			code = result.error,
			message = result.error,
		})
	end

	-- Check if game ended
	if result.gameOver then
		-- Record stats
		Server.recordGameResult(server, gameId)
		-- Return GAME_OVER message
		return Protocol.gameOverMessage(gameId, result.winner)
	end

	-- Return updated game state
	return Protocol.gameStateMessage(GameSession.getState(session))
end

--- Handle incoming message from client
---@param server table Server state
---@param clientId string Client ID
---@param message table Protocol message
---@return table Response message
function Server.handleMessage(server, clientId, message)
	-- Validate client exists
	local client = server.clients[clientId]
	if not client then
		return Protocol.createMessage("ERROR", {
			code = "UNKNOWN_CLIENT",
			message = "Client not found",
		})
	end

	-- Validate message structure
	if not Protocol.isValidMessage(message) then
		return Protocol.createMessage("ERROR", {
			code = "INVALID_MESSAGE",
			message = "Invalid message format",
		})
	end

	local msgType = message.type
	local payload = message.payload

	-- CONNECT is allowed before authentication
	if msgType == "CONNECT" then
		return handleConnect(server, clientId, payload)
	end

	-- All other messages require authentication
	if not client.playerId then
		return Protocol.createMessage("ERROR", {
			code = "NOT_AUTHENTICATED",
			message = "Must send CONNECT first",
		})
	end

	-- Route to appropriate handler
	if msgType == "JOIN_LOBBY" then
		return handleJoinLobby(server, clientId, payload)
	elseif msgType == "CREATE_GAME" then
		return handleCreateGame(server, clientId, payload)
	elseif msgType == "JOIN_GAME" then
		return handleJoinGame(server, clientId, payload)
	elseif msgType == "LEAVE_GAME" then
		return handleLeaveGame(server, clientId, payload)
	elseif msgType == "CREATE_AI_GAME" then
		return handleCreateAIGame(server, clientId, payload)
	elseif msgType == "MOVE" then
		return handleMove(server, clientId, payload)
	elseif msgType == "ACTIVATE_POWER" then
		-- TODO: Implement in GameSession
		return Protocol.createMessage("ERROR", {
			code = "NOT_IMPLEMENTED",
			message = "ACTIVATE_POWER not yet implemented",
		})
	elseif msgType == "CHAT" then
		-- TODO: Implement chat
		return Protocol.createMessage("ERROR", {
			code = "NOT_IMPLEMENTED",
			message = "CHAT not yet implemented",
		})
	else
		return Protocol.createMessage("ERROR", {
			code = "UNKNOWN_MESSAGE_TYPE",
			message = "Unknown message type: " .. tostring(msgType),
		})
	end
end

--- Get a game session by game ID
---@param server table Server state
---@param gameId string Game ID
---@return table|nil GameSession or nil if not found
function Server.getGameSession(server, gameId)
	return server.gameSessions[gameId]
end

--- Update all AI games and return any moves made
---@param server table Server state
---@param dt number Delta time in seconds
---@return table Array of {gameId, state, gameOver?, winner?} for games where AI moved
function Server.updateAIGames(server, dt)
	local moves = {}

	for gameId, session in pairs(server.gameSessions) do
		if GameSession.isAIGame(session) then
			local result = GameSession.updateAI(session, dt)
			if result then
				local moveInfo = {
					gameId = gameId,
					state = GameSession.getState(session),
					move = result,
				}

				-- Check if game ended after AI move
				if result.gameOver then
					moveInfo.gameOver = true
					moveInfo.winner = result.winner
					-- Record stats
					Server.recordGameResult(server, gameId)
				end

				table.insert(moves, moveInfo)
			end
		end
	end

	return moves
end

--- Start the server (TCP listening)
--- Note: Actual socket implementation will use luasocket
---@param server table Server state
---@return boolean success
--- Get player stats
---@param server table Server state
---@param playerId string Player ID
---@return table|nil Stats object or nil if not found
function Server.getPlayerStats(server, playerId)
	return server.playerStats[playerId]
end

--- Record game result and update player stats
---@param server table Server state
---@param gameId string Game ID
---@return boolean success
function Server.recordGameResult(server, gameId)
	local session = server.gameSessions[gameId]
	if not session then
		return false
	end

	-- Only record if game is finished
	if session.status ~= "finished" or not session.state.winner then
		return false
	end

	-- For AI games, record result for the human player
	if GameSession.isAIGame(session) then
		local playerId = session.player1Id -- Human is always player 1
		local playerStats = server.playerStats[playerId]

		if playerStats then
			local won = session.state.winner == 1 -- Human wins if winner is player 1
			Stats.recordAIGame(playerStats, session.aiDifficulty, won)
		end
	else
		-- PvP game - record for both players
		local player1Stats = server.playerStats[session.player1Id]
		local player2Stats = server.playerStats[session.player2Id]

		if player1Stats and player2Stats then
			local player1Won = session.state.winner == 1
			local player1Rating = player1Stats.rating
			local player2Rating = player2Stats.rating

			Stats.recordPvPGame(player1Stats, player2Rating, player1Won)
			Stats.recordPvPGame(player2Stats, player1Rating, not player1Won)
		end
	end

	return true
end

---@return string|nil error message
function Server.start(server)
	if server.running then
		return false, "Server already running"
	end

	-- Socket initialization would happen here with luasocket
	-- For now, just set the running flag
	server.running = true
	return true, nil
end

--- Stop the server
---@param server table Server state
---@return boolean success
function Server.stop(server)
	if not server.running then
		return false
	end

	-- Close all client connections
	for clientId, _ in pairs(server.clients) do
		Server.removeClient(server, clientId)
	end

	-- Close server socket (when implemented)
	server.running = false
	return true
end

--- Check for disconnect timeouts and return games that should end
---@param server table Server state
---@return table Array of {gameId, winnerClientId, winnerId} for games that timed out
function Server.checkDisconnectTimeouts(server)
	local timeouts = {}
	local currentTime = os.time()

	for gameId, session in pairs(server.gameSessions) do
		if session.disconnectedPlayer and session.disconnectTime then
			local elapsed = currentTime - session.disconnectTime
			if elapsed >= DISCONNECT_TIMEOUT then
				-- Determine winner (opponent of disconnected player)
				local winnerId = nil
				local winnerNumber = nil
				if session.disconnectedPlayer == 1 then
					winnerId = session.player2Id
					winnerNumber = 2
				else
					winnerId = session.player1Id
					winnerNumber = 1
				end

				local winnerClientId = Server.findClientByPlayerId(server, winnerId)

				-- End the game
				session.status = "finished"
				session.state.winner = winnerNumber
				session.state.gameOver = true

				-- Clear disconnect state
				session.disconnectedPlayer = nil
				session.disconnectTime = nil

				-- Record stats
				Server.recordGameResult(server, gameId)

				table.insert(timeouts, {
					gameId = gameId,
					winnerClientId = winnerClientId,
					winnerId = winnerId,
					winnerNumber = winnerNumber,
				})
			end
		end
	end

	return timeouts
end

--- Handle player reconnection
---@param server table Server state
---@param clientId string Client ID of reconnecting player
---@param playerId string Player ID
---@return table|nil notification {type, opponentClientId, gameId, opponentName}
function Server.handleReconnection(server, clientId, playerId)
	local session, gameId = findPlayerGameSession(server, playerId)
	if not session then
		return nil
	end

	-- Check if this player was marked as disconnected
	local playerNumber = nil
	if session.player1Id == playerId then
		playerNumber = 1
	elseif session.player2Id == playerId then
		playerNumber = 2
	end

	if not playerNumber or session.disconnectedPlayer ~= playerNumber then
		return nil
	end

	-- Player reconnected - clear disconnect state
	session.disconnectedPlayer = nil
	session.disconnectTime = nil

	-- Find opponent to notify
	local opponentId = playerNumber == 1 and session.player2Id or session.player1Id
	local opponentClientId = Server.findClientByPlayerId(server, opponentId)

	if not opponentClientId then
		return nil
	end

	-- Get reconnecting player's name
	local player = server.lobby.players[playerId]
	local playerName = player and player.name or "Opponent"

	return {
		type = "opponent_reconnected",
		opponentClientId = opponentClientId,
		gameId = gameId,
		opponentName = playerName,
	}
end

return Server
