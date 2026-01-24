-- Lobby management for multiplayer server
-- Handles player registration and game room creation/joining

local Lobby = {}

--- Create a new lobby state
---@return table Lobby state
function Lobby.create()
	return {
		players = {}, -- playerId -> {id, name, gameId}
		games = {}, -- gameId -> {id, name, hostId, players, status, settings}
		nextGameId = 1,
	}
end

--- Generate a unique game ID
---@param lobby table Lobby state
---@return string Game ID
local function generateGameId(lobby)
	local id = "game_" .. lobby.nextGameId
	lobby.nextGameId = lobby.nextGameId + 1
	return id
end

--- Add a player to the lobby
---@param lobby table Lobby state
---@param playerId string Unique player ID
---@param name string Player display name
---@return boolean success
---@return string|nil error message if failed
function Lobby.addPlayer(lobby, playerId, name)
	-- Check if player already exists
	if lobby.players[playerId] then
		return false, "Player already in lobby"
	end

	-- Check for duplicate names
	for _, player in pairs(lobby.players) do
		if player.name == name then
			return false, "Name already taken"
		end
	end

	lobby.players[playerId] = {
		id = playerId,
		name = name,
		gameId = nil,
	}

	return true, nil
end

--- Remove a player from the lobby
---@param lobby table Lobby state
---@param playerId string Player ID to remove
---@return boolean success
function Lobby.removePlayer(lobby, playerId)
	local player = lobby.players[playerId]
	if not player then
		return false
	end

	-- Leave game if in one
	if player.gameId then
		Lobby.leaveGame(lobby, playerId)
	end

	lobby.players[playerId] = nil
	return true
end

--- Get a player by ID
---@param lobby table Lobby state
---@param playerId string Player ID
---@return table|nil Player data
function Lobby.getPlayer(lobby, playerId)
	return lobby.players[playerId]
end

--- Get player count
---@param lobby table Lobby state
---@return number Number of players
function Lobby.getPlayerCount(lobby)
	local count = 0
	for _ in pairs(lobby.players) do
		count = count + 1
	end
	return count
end

--- Create a new game room
---@param lobby table Lobby state
---@param playerId string Host player ID
---@param gameName string Display name for the game
---@param settings table|nil Optional game settings
---@return string|nil gameId if successful
---@return string|nil error message if failed
function Lobby.createGame(lobby, playerId, gameName, settings)
	local player = lobby.players[playerId]
	if not player then
		return nil, "Player not in lobby"
	end

	if player.gameId then
		return nil, "Player already in a game"
	end

	local gameId = generateGameId(lobby)

	lobby.games[gameId] = {
		id = gameId,
		name = gameName,
		hostId = playerId,
		players = { playerId },
		status = "waiting", -- waiting, playing, finished
		settings = settings or {},
	}

	player.gameId = gameId
	return gameId, nil
end

--- Join an existing game
---@param lobby table Lobby state
---@param playerId string Player ID
---@param gameId string Game ID to join
---@return boolean success
---@return string|nil error message if failed
function Lobby.joinGame(lobby, playerId, gameId)
	local player = lobby.players[playerId]
	if not player then
		return false, "Player not in lobby"
	end

	if player.gameId then
		return false, "Player already in a game"
	end

	local game = lobby.games[gameId]
	if not game then
		return false, "Game not found"
	end

	if game.status ~= "waiting" then
		return false, "Game already started"
	end

	if #game.players >= 2 then
		return false, "Game is full"
	end

	table.insert(game.players, playerId)
	player.gameId = gameId

	-- Start game when 2 players join
	if #game.players == 2 then
		game.status = "playing"
	end

	return true, nil
end

--- Leave current game
---@param lobby table Lobby state
---@param playerId string Player ID
---@return boolean success
---@return string|nil error message if failed
function Lobby.leaveGame(lobby, playerId)
	local player = lobby.players[playerId]
	if not player then
		return false, "Player not in lobby"
	end

	if not player.gameId then
		return false, "Player not in a game"
	end

	local game = lobby.games[player.gameId]
	if game then
		-- Remove player from game
		for i, pid in ipairs(game.players) do
			if pid == playerId then
				table.remove(game.players, i)
				break
			end
		end

		-- Handle game state based on remaining players
		if #game.players == 0 then
			-- No players left, remove game
			lobby.games[game.id] = nil
		elseif game.status == "playing" then
			-- Game was in progress, mark as finished (other player wins)
			game.status = "finished"
		elseif game.status == "waiting" then
			-- Still waiting, update host if needed
			if game.hostId == playerId and #game.players > 0 then
				game.hostId = game.players[1]
			end
		end
	end

	player.gameId = nil
	return true, nil
end

--- Get a game by ID
---@param lobby table Lobby state
---@param gameId string Game ID
---@return table|nil Game data
function Lobby.getGame(lobby, gameId)
	return lobby.games[gameId]
end

--- List all available games (waiting for players)
---@param lobby table Lobby state
---@return table Array of game info
function Lobby.listGames(lobby)
	local games = {}
	for _, game in pairs(lobby.games) do
		-- Include game info with player names
		local playerNames = {}
		for _, playerId in ipairs(game.players) do
			local player = lobby.players[playerId]
			if player then
				table.insert(playerNames, player.name)
			end
		end

		table.insert(games, {
			game_id = game.id,
			game_name = game.name,
			players = playerNames,
			status = game.status,
		})
	end
	return games
end

--- Start a game (change status from waiting to playing)
---@param lobby table Lobby state
---@param gameId string Game ID
---@return boolean success
---@return string|nil error message if failed
function Lobby.startGame(lobby, gameId)
	local game = lobby.games[gameId]
	if not game then
		return false, "Game not found"
	end

	if game.status ~= "waiting" then
		return false, "Game not in waiting state"
	end

	if #game.players < 2 then
		return false, "Not enough players"
	end

	game.status = "playing"
	return true, nil
end

--- End a game
---@param lobby table Lobby state
---@param gameId string Game ID
---@param winnerId string|nil Winner player ID (nil for draw)
---@return boolean success
function Lobby.endGame(lobby, gameId, winnerId)
	local game = lobby.games[gameId]
	if not game then
		return false
	end

	game.status = "finished"
	game.winnerId = winnerId

	-- Remove players from game
	for _, playerId in ipairs(game.players) do
		local player = lobby.players[playerId]
		if player then
			player.gameId = nil
		end
	end

	return true
end

--- Remove finished games from lobby
---@param lobby table Lobby state
---@return number Number of games removed
function Lobby.cleanupFinishedGames(lobby)
	local removed = 0
	for gameId, game in pairs(lobby.games) do
		if game.status == "finished" then
			lobby.games[gameId] = nil
			removed = removed + 1
		end
	end
	return removed
end

--- Get count of players not currently in a game
---@param lobby table Lobby state
---@return number Number of available players
function Lobby.getAvailablePlayerCount(lobby)
	local count = 0
	for _, player in pairs(lobby.players) do
		if not player.gameId then
			count = count + 1
		end
	end
	return count
end

--- Get list of players not currently in a game
---@param lobby table Lobby state
---@return table Array of {id, name} for available players
function Lobby.getAvailablePlayers(lobby)
	local available = {}
	for _, player in pairs(lobby.players) do
		if not player.gameId then
			table.insert(available, {
				id = player.id,
				name = player.name,
			})
		end
	end
	return available
end

return Lobby
