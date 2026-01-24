-- Multiplayer Integration Module
-- Bridges client networking with game UI
-- Phase 10B: Client Networking

local Network = require("src.client.network")
local LobbyClient = require("src.client.lobby_client")
local GameClient = require("src.client.game_client")
local Protocol = require("src.shared.protocol")

local Multiplayer = {}

--- Create multiplayer state
---@return table Multiplayer state
function Multiplayer.create()
	return {
		network = Network.create(),
		lobby = LobbyClient.create(),
		-- Connection settings
		serverHost = "localhost",
		serverPort = 7777,
		playerName = "Player",
		-- Text input state
		inputField = "name", -- "name", "host", "port", "gamename"
		inputText = "",
		-- Game state
		playerNumber = nil, -- 1 or 2 once game starts
		gameState = nil, -- Synced game state from server
		-- Status
		statusMessage = "",
		errorMessage = "",
		-- Game list selection
		selectedGameIndex = 1,
	}
end

--- Initialize with default player name
---@param mp table Multiplayer state
---@param defaultName string Default player name
function Multiplayer.init(mp, defaultName)
	mp.playerName = defaultName or "Player"
	mp.inputText = mp.playerName
end

--- Connect to server
---@param mp table Multiplayer state
---@return boolean success
function Multiplayer.connect(mp)
	mp.errorMessage = ""
	mp.statusMessage = "Connecting..."

	local success, err = Network.connect(mp.network, mp.serverHost, mp.serverPort)
	if not success then
		mp.errorMessage = err or "Connection failed"
		mp.statusMessage = ""
		return false
	end

	-- Send authentication
	mp.statusMessage = "Authenticating..."
	local authSuccess, authErr = Network.authenticate(mp.network, mp.playerName)
	if not authSuccess then
		mp.errorMessage = authErr or "Authentication failed"
		mp.statusMessage = ""
		Network.disconnect(mp.network)
		return false
	end

	mp.statusMessage = "Connected"
	return true
end

--- Disconnect from server
---@param mp table Multiplayer state
function Multiplayer.disconnect(mp)
	Network.disconnect(mp.network)
	mp.lobby = LobbyClient.create()
	mp.playerNumber = nil
	mp.gameState = nil
	mp.statusMessage = ""
	mp.errorMessage = ""
end

--- Check if connected
---@param mp table Multiplayer state
---@return boolean
function Multiplayer.isConnected(mp)
	return Network.isConnected(mp.network)
end

--- Request lobby state
---@param mp table Multiplayer state
function Multiplayer.requestLobby(mp)
	if not Multiplayer.isConnected(mp) then
		return
	end
	Network.send(mp.network, LobbyClient.createJoinLobbyMessage())
end

--- Create a new game
---@param mp table Multiplayer state
---@param gameName string Game name
function Multiplayer.createGame(mp, gameName)
	if not Multiplayer.isConnected(mp) then
		return
	end
	Network.send(mp.network, LobbyClient.createCreateGameMessage(gameName or "Game"))
end

--- Join a game
---@param mp table Multiplayer state
---@param gameId string Game ID to join
function Multiplayer.joinGame(mp, gameId)
	if not Multiplayer.isConnected(mp) then
		return
	end
	Network.send(mp.network, LobbyClient.createJoinGameMessage(gameId))
end

--- Leave current game
---@param mp table Multiplayer state
function Multiplayer.leaveGame(mp)
	if not Multiplayer.isConnected(mp) then
		return
	end
	Network.send(mp.network, LobbyClient.createLeaveGameMessage())
	LobbyClient.leaveCurrentGame(mp.lobby)
	mp.playerNumber = nil
	mp.gameState = nil
end

--- Send a move
---@param mp table Multiplayer state
---@param from table {col, row}
---@param to table {col, row}
function Multiplayer.sendMove(mp, from, to)
	if not Multiplayer.isConnected(mp) then
		return
	end
	Network.send(mp.network, GameClient.createMoveMessage(from, to))
end

--- Send a power activation
---@param mp table Multiplayer state
---@param piecePos table {col, row}
---@param powerId string
---@param target table|nil Optional target
function Multiplayer.sendPower(mp, piecePos, powerId, target)
	if not Multiplayer.isConnected(mp) then
		return
	end
	Network.send(mp.network, GameClient.createPowerMessage(piecePos, powerId, target))
end

--- Update - poll network and process messages
---@param mp table Multiplayer state
---@return string|nil Event type if something significant happened
function Multiplayer.update(mp)
	if not Multiplayer.isConnected(mp) then
		return nil
	end

	-- Poll for incoming data
	Network.poll(mp.network)

	-- Process all pending messages
	local event = nil
	while Network.hasMessages(mp.network) do
		local msg = Network.receive(mp.network)
		if msg then
			event = Multiplayer.processMessage(mp, msg) or event
		end
	end

	-- Check for disconnect
	if mp.network.state == "disconnected" or mp.network.state == "error" then
		mp.errorMessage = mp.network.lastError or "Disconnected"
		return "disconnected"
	end

	return event
end

--- Process a server message
---@param mp table Multiplayer state
---@param msg table Protocol message
---@return string|nil Event type
function Multiplayer.processMessage(mp, msg)
	if not msg or not msg.type then
		return nil
	end

	local msgType = msg.type

	if msgType == "WELCOME" then
		Network.handleWelcome(mp.network, msg)
		mp.statusMessage = "Connected as " .. mp.playerName
		return "connected"
	elseif msgType == "LOBBY_STATE" then
		LobbyClient.handleLobbyState(mp.lobby, msg)
		return "lobby_updated"
	elseif msgType == "GAME_CREATED" then
		LobbyClient.handleGameCreated(mp.lobby, msg)
		mp.playerNumber = 1 -- Creator is player 1
		return "game_created"
	elseif msgType == "AI_GAME_CREATED" then
		-- AI game created - set player number and game ID
		mp.playerNumber = msg.payload.player_number or 1 -- Human is always player 1
		LobbyClient.setCurrentGame(mp.lobby, msg.payload.game_id)
		-- Store game state from server for client to sync
		if msg.payload.game_state then
			mp.gameState = msg.payload.game_state
		end
		mp.statusMessage = "AI Game Started (" .. (msg.payload.difficulty or "unknown") .. ")"
		return "ai_game_created"
	elseif msgType == "GAME_JOINED" then
		LobbyClient.handleGameJoined(mp.lobby, msg)
		return "game_joined"
	elseif msgType == "GAME_STATE" then
		LobbyClient.handleGameState(mp.lobby, msg)
		local previousState = mp.gameState
		mp.gameState = GameClient.handleGameState(msg)
		-- Determine player number from game state if not set
		if not mp.playerNumber then
			mp.playerNumber = 2 -- Joiner is player 2
		end
		-- If we already had a game state, this is an update (e.g., AI moved)
		-- Otherwise it's the initial game start
		if previousState then
			return "game_state_updated"
		else
			return "game_started"
		end
	elseif msgType == "MOVE_RESULT" then
		local result = GameClient.handleMoveResult(msg)
		if not result.success then
			mp.errorMessage = result.error or "Move failed"
		end
		return "move_result"
	elseif msgType == "POWER_RESULT" then
		local result = GameClient.handlePowerResult(msg)
		if not result.success then
			mp.errorMessage = result.error or "Power failed"
		end
		return "power_result"
	elseif msgType == "GAME_OVER" then
		LobbyClient.handleGameOver(mp.lobby, msg)
		local result = GameClient.handleGameOver(msg)
		mp.gameState = mp.gameState or {}
		mp.gameState.winner = result.winner
		mp.gameState.gameOver = true
		return "game_over"
	elseif msgType == "ERROR" then
		LobbyClient.handleError(mp.lobby, msg)
		mp.errorMessage = msg.payload.message or msg.payload.code or "Error"
		return "error"
	end

	return nil
end

--- Get available games
---@param mp table Multiplayer state
---@return table Games list
function Multiplayer.getGames(mp)
	return LobbyClient.getGames(mp.lobby)
end

--- Get waiting games only
---@param mp table Multiplayer state
---@return table Waiting games
function Multiplayer.getWaitingGames(mp)
	return LobbyClient.getWaitingGames(mp.lobby)
end

--- Check if in a game
---@param mp table Multiplayer state
---@return boolean
function Multiplayer.isInGame(mp)
	return LobbyClient.isInGame(mp.lobby)
end

--- Check if it's local player's turn
---@param mp table Multiplayer state
---@return boolean
function Multiplayer.isMyTurn(mp)
	if not mp.gameState or not mp.playerNumber then
		return false
	end
	return mp.gameState.currentPlayer == mp.playerNumber
end

--- Get lobby state string
---@param mp table Multiplayer state
---@return string
function Multiplayer.getStateString(mp)
	return LobbyClient.getStateString(mp.lobby)
end

--- Handle text input for connection fields
---@param mp table Multiplayer state
---@param text string Input text
function Multiplayer.textInput(mp, text)
	mp.inputText = mp.inputText .. text
	-- Update the appropriate field
	if mp.inputField == "name" then
		mp.playerName = mp.inputText
	elseif mp.inputField == "host" then
		mp.serverHost = mp.inputText
	elseif mp.inputField == "port" then
		local port = tonumber(mp.inputText)
		if port then
			mp.serverPort = port
		end
	end
end

--- Handle backspace for text input
---@param mp table Multiplayer state
function Multiplayer.backspace(mp)
	if #mp.inputText > 0 then
		mp.inputText = mp.inputText:sub(1, -2)
		-- Update field
		if mp.inputField == "name" then
			mp.playerName = mp.inputText
		elseif mp.inputField == "host" then
			mp.serverHost = mp.inputText
		elseif mp.inputField == "port" then
			local port = tonumber(mp.inputText)
			if port then
				mp.serverPort = port
			end
		end
	end
end

--- Set active input field
---@param mp table Multiplayer state
---@param field string Field name
function Multiplayer.setInputField(mp, field)
	mp.inputField = field
	if field == "name" then
		mp.inputText = mp.playerName
	elseif field == "host" then
		mp.inputText = mp.serverHost
	elseif field == "port" then
		mp.inputText = tostring(mp.serverPort)
	else
		mp.inputText = ""
	end
end

--- Select next game in list
---@param mp table Multiplayer state
function Multiplayer.selectNextGame(mp)
	local games = Multiplayer.getWaitingGames(mp)
	if #games > 0 then
		mp.selectedGameIndex = mp.selectedGameIndex + 1
		if mp.selectedGameIndex > #games then
			mp.selectedGameIndex = 1
		end
	end
end

--- Select previous game in list
---@param mp table Multiplayer state
function Multiplayer.selectPrevGame(mp)
	local games = Multiplayer.getWaitingGames(mp)
	if #games > 0 then
		mp.selectedGameIndex = mp.selectedGameIndex - 1
		if mp.selectedGameIndex < 1 then
			mp.selectedGameIndex = #games
		end
	end
end

--- Get selected game
---@param mp table Multiplayer state
---@return table|nil Selected game
function Multiplayer.getSelectedGame(mp)
	local games = Multiplayer.getWaitingGames(mp)
	return games[mp.selectedGameIndex]
end

--- Clear error message
---@param mp table Multiplayer state
function Multiplayer.clearError(mp)
	mp.errorMessage = ""
end

--- Get count of available players (not in a game)
---@param mp table Multiplayer state
---@return number Available player count
function Multiplayer.getAvailablePlayerCount(mp)
	return LobbyClient.getAvailablePlayerCount(mp.lobby)
end

--- Create an AI practice game
---@param mp table Multiplayer state
---@param difficulty string AI difficulty (easy/medium/hard/expert)
function Multiplayer.createAIGame(mp, difficulty)
	if not Multiplayer.isConnected(mp) then
		return
	end
	local gameName = mp.playerName .. "'s AI Game"
	Network.send(mp.network, Protocol.createAIGameMessage(difficulty, gameName))
end

return Multiplayer
