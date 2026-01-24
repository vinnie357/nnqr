-- LobbyClient module for client-side multiplayer
-- Handles lobby operations and game list management
-- Phase 10B: Client Networking

local Protocol = require("src.shared.protocol")

local LobbyClient = {}

--- Create a new lobby client state
---@return table LobbyClient state
function LobbyClient.create()
	return {
		state = "browsing", -- browsing, waiting, playing
		games = {}, -- List of available games
		playersOnline = 0,
		availablePlayers = 0, -- Players not in a game
		currentGameId = nil,
		gameState = nil, -- Current game state when playing
		lastError = nil,
		lastRefresh = 0,
	}
end

--- Create JOIN_LOBBY message
---@return table Protocol message
function LobbyClient.createJoinLobbyMessage()
	return Protocol.createMessage(Protocol.Types.JOIN_LOBBY, {})
end

--- Create CREATE_GAME message
---@param gameName string Game display name
---@param settings table|nil Optional game settings
---@return table Protocol message
function LobbyClient.createCreateGameMessage(gameName, settings)
	return Protocol.createMessage(Protocol.Types.CREATE_GAME, {
		game_name = gameName,
		settings = settings or {},
	})
end

--- Create JOIN_GAME message
---@param gameId string Game ID to join
---@return table Protocol message
function LobbyClient.createJoinGameMessage(gameId)
	return Protocol.createMessage(Protocol.Types.JOIN_GAME, {
		game_id = gameId,
	})
end

--- Create LEAVE_GAME message
---@return table Protocol message
function LobbyClient.createLeaveGameMessage()
	return Protocol.createMessage(Protocol.Types.LEAVE_GAME, {})
end

--- Handle LOBBY_STATE message
---@param lobby table LobbyClient state
---@param message table LOBBY_STATE message
function LobbyClient.handleLobbyState(lobby, message)
	if message.payload then
		lobby.games = message.payload.games or {}
		lobby.playersOnline = message.payload.players_online or 0
		lobby.availablePlayers = message.payload.available_players or 0
		lobby.lastRefresh = os.time()
	end
end

--- Handle GAME_CREATED message
---@param lobby table LobbyClient state
---@param message table GAME_CREATED message
function LobbyClient.handleGameCreated(lobby, message)
	if message.payload and message.payload.game_id then
		lobby.currentGameId = message.payload.game_id
		lobby.state = "waiting"
	end
end

--- Handle GAME_JOINED message (waiting for game to start)
---@param lobby table LobbyClient state
---@param message table GAME_JOINED message
function LobbyClient.handleGameJoined(lobby, message)
	if message.payload then
		lobby.currentGameId = message.payload.game_id
		if message.payload.status == "waiting" then
			lobby.state = "waiting"
		else
			lobby.state = "playing"
		end
	end
end

--- Handle GAME_STATE message (game started or update)
---@param lobby table LobbyClient state
---@param message table GAME_STATE message
function LobbyClient.handleGameState(lobby, message)
	if message.payload then
		lobby.gameState = message.payload
		lobby.state = "playing"
		if message.payload.game_id then
			lobby.currentGameId = message.payload.game_id
		end
	end
end

--- Handle ERROR message
---@param lobby table LobbyClient state
---@param message table ERROR message
function LobbyClient.handleError(lobby, message)
	if message.payload then
		lobby.lastError = {
			code = message.payload.code,
			message = message.payload.message,
		}
	end
end

--- Handle GAME_OVER message
---@param lobby table LobbyClient state
---@param message table GAME_OVER message
function LobbyClient.handleGameOver(lobby, message)
	if message.payload then
		lobby.gameOver = {
			winner = message.payload.winner,
			reason = message.payload.reason,
		}
	end
end

--- Process incoming message and route to appropriate handler
---@param lobby table LobbyClient state
---@param message table Protocol message
---@return boolean True if message was handled
function LobbyClient.processMessage(lobby, message)
	if not message or not message.type then
		return false
	end

	local msgType = message.type

	if msgType == "LOBBY_STATE" then
		LobbyClient.handleLobbyState(lobby, message)
		return true
	elseif msgType == "GAME_CREATED" then
		LobbyClient.handleGameCreated(lobby, message)
		return true
	elseif msgType == "GAME_JOINED" then
		LobbyClient.handleGameJoined(lobby, message)
		return true
	elseif msgType == "GAME_STATE" then
		LobbyClient.handleGameState(lobby, message)
		return true
	elseif msgType == "ERROR" then
		LobbyClient.handleError(lobby, message)
		return true
	elseif msgType == "GAME_OVER" then
		LobbyClient.handleGameOver(lobby, message)
		return true
	elseif msgType == "WELCOME" then
		-- Handled by Network module
		return true
	end

	return false
end

--- Get all games
---@param lobby table LobbyClient state
---@return table Games list
function LobbyClient.getGames(lobby)
	return lobby.games
end

--- Get only waiting games (joinable)
---@param lobby table LobbyClient state
---@return table Waiting games list
function LobbyClient.getWaitingGames(lobby)
	local waiting = {}
	for _, game in ipairs(lobby.games) do
		if game.status == "waiting" then
			table.insert(waiting, game)
		end
	end
	return waiting
end

--- Check if currently in a game
---@param lobby table LobbyClient state
---@return boolean True if in a game
function LobbyClient.isInGame(lobby)
	return lobby.currentGameId ~= nil
end

--- Leave current game (local state update)
---@param lobby table LobbyClient state
function LobbyClient.leaveCurrentGame(lobby)
	lobby.currentGameId = nil
	lobby.gameState = nil
	lobby.gameOver = nil
	lobby.state = "browsing"
end

--- Set current game ID (for AI games)
---@param lobby table LobbyClient state
---@param gameId string Game ID
function LobbyClient.setCurrentGame(lobby, gameId)
	lobby.currentGameId = gameId
	lobby.state = "playing" -- AI games start immediately
end

--- Get current game state
---@param lobby table LobbyClient state
---@return table|nil Game state
function LobbyClient.getGameState(lobby)
	return lobby.gameState
end

--- Check if it's the local player's turn
---@param lobby table LobbyClient state
---@param playerNumber number Local player number (1 or 2)
---@return boolean True if local player's turn
function LobbyClient.isMyTurn(lobby, playerNumber)
	if not lobby.gameState then
		return false
	end
	return lobby.gameState.current_player == playerNumber
end

--- Clear last error
---@param lobby table LobbyClient state
function LobbyClient.clearError(lobby)
	lobby.lastError = nil
end

--- Get state as string for UI
---@param lobby table LobbyClient state
---@return string State description
function LobbyClient.getStateString(lobby)
	if lobby.state == "browsing" then
		return "Browsing Games"
	elseif lobby.state == "waiting" then
		return "Waiting for Opponent"
	elseif lobby.state == "playing" then
		return "In Game"
	else
		return "Unknown"
	end
end

--- Get count of available players (not in a game)
---@param lobby table LobbyClient state
---@return number Available player count
function LobbyClient.getAvailablePlayerCount(lobby)
	return lobby.availablePlayers or 0
end

return LobbyClient
