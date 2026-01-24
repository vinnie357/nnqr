-- GameClient module for client-side multiplayer
-- Handles game-specific protocol messages and state
-- Phase 10B: Client Networking

local Protocol = require("src.shared.protocol")

local GameClient = {}

--- Create MOVE message
---@param from table {col, row} Starting position
---@param to table {col, row} Target position
---@return table Protocol message
function GameClient.createMoveMessage(from, to)
	return Protocol.moveMessage(from, to)
end

--- Create ACTIVATE_POWER message
---@param piecePos table {col, row} Position of piece with power
---@param powerId string Power identifier
---@param target table|nil Optional target position for targeted powers
---@return table Protocol message
function GameClient.createPowerMessage(piecePos, powerId, target)
	return Protocol.activatePowerMessage(piecePos, powerId, target)
end

--- Create CHAT message
---@param message string Chat message text
---@return table Protocol message
function GameClient.createChatMessage(message)
	return Protocol.createMessage(Protocol.Types.CHAT, {
		message = message,
	})
end

--- Handle MOVE_RESULT message
---@param message table MOVE_RESULT message
---@return table Parsed result {success, captured, orbCollected, error}
function GameClient.handleMoveResult(message)
	local payload = message.payload or {}
	return {
		success = payload.success == true,
		captured = payload.captured,
		orbCollected = payload.orb_collected,
		error = payload.error,
	}
end

--- Handle POWER_RESULT message
---@param message table POWER_RESULT message
---@return table Parsed result {success, powerId, effects, error}
function GameClient.handlePowerResult(message)
	local payload = message.payload or {}
	return {
		success = payload.success == true,
		powerId = payload.power_id,
		effects = payload.effects or {},
		error = payload.error,
	}
end

--- Handle GAME_STATE message
---@param message table GAME_STATE message
---@return table Parsed game state
function GameClient.handleGameState(message)
	local payload = message.payload or {}
	return {
		gameId = payload.game_id,
		turn = payload.turn,
		currentPlayer = payload.current_player,
		phase = payload.phase,
		board = payload.board,
		pieces = payload.pieces or {},
		winner = payload.winner,
		gameOver = payload.game_over == true,
	}
end

--- Handle GAME_OVER message
---@param message table GAME_OVER message
---@return table Parsed result {winner, reason}
function GameClient.handleGameOver(message)
	local payload = message.payload or {}
	return {
		winner = payload.winner,
		reason = payload.reason,
	}
end

--- Handle CHAT_MESSAGE message
---@param message table CHAT_MESSAGE message
---@return table Parsed chat {playerName, message}
function GameClient.handleChatMessage(message)
	local payload = message.payload or {}
	return {
		playerName = payload.player_name,
		message = payload.message,
	}
end

--- Handle ORB_SPAWN message
---@param message table ORB_SPAWN message
---@return table Array of orb info {col, row, powerId}
function GameClient.handleOrbSpawn(message)
	local payload = message.payload or {}
	local orbs = {}
	for _, orb in ipairs(payload.orbs or {}) do
		table.insert(orbs, {
			col = orb.col,
			row = orb.row,
			powerId = orb.power_id,
		})
	end
	return orbs
end

--- Check if it's the local player's turn
---@param gameState table Game state
---@param playerNumber number Local player number (1 or 2)
---@return boolean True if it's local player's turn
function GameClient.isMyTurn(gameState, playerNumber)
	if not gameState then
		return false
	end
	return gameState.currentPlayer == playerNumber
end

--- Get piece at position from game state
---@param gameState table Game state
---@param col number Column
---@param row number Row
---@return table|nil Piece or nil
function GameClient.getPieceAt(gameState, col, row)
	if not gameState or not gameState.pieces then
		return nil
	end
	for _, piece in ipairs(gameState.pieces) do
		if piece.col == col and piece.row == row then
			return piece
		end
	end
	return nil
end

--- Get all pieces belonging to a player
---@param gameState table Game state
---@param playerNumber number Player number (1 or 2)
---@return table Array of pieces
function GameClient.getMyPieces(gameState, playerNumber)
	local pieces = {}
	if not gameState or not gameState.pieces then
		return pieces
	end
	for _, piece in ipairs(gameState.pieces) do
		if piece.player == playerNumber then
			table.insert(pieces, piece)
		end
	end
	return pieces
end

--- Count pieces for each player
---@param gameState table Game state
---@return number, number Player 1 count, Player 2 count
function GameClient.countPieces(gameState)
	local p1, p2 = 0, 0
	if not gameState or not gameState.pieces then
		return p1, p2
	end
	for _, piece in ipairs(gameState.pieces) do
		if piece.player == 1 then
			p1 = p1 + 1
		elseif piece.player == 2 then
			p2 = p2 + 1
		end
	end
	return p1, p2
end

--- Check if game is over
---@param gameState table Game state
---@return boolean True if game is over
function GameClient.isGameOver(gameState)
	if not gameState then
		return false
	end
	return gameState.gameOver == true or gameState.winner ~= nil
end

--- Get winner from game state
---@param gameState table Game state
---@return number|nil Winner player number or nil
function GameClient.getWinner(gameState)
	if not gameState then
		return nil
	end
	return gameState.winner
end

--- Get tile height at position
---@param gameState table Game state
---@param col number Column
---@param row number Row
---@return number Height (default 0)
function GameClient.getTileHeight(gameState, col, row)
	if not gameState or not gameState.board or not gameState.board.tiles then
		return 0
	end
	for _, tile in ipairs(gameState.board.tiles) do
		if tile.col == col and tile.row == row then
			return tile.height or 0
		end
	end
	return 0
end

--- Check if tile is destroyed
---@param gameState table Game state
---@param col number Column
---@param row number Row
---@return boolean True if tile is destroyed
function GameClient.isTileDestroyed(gameState, col, row)
	if not gameState or not gameState.board or not gameState.board.tiles then
		return false
	end
	for _, tile in ipairs(gameState.board.tiles) do
		if tile.col == col and tile.row == row then
			return tile.destroyed == true
		end
	end
	return false
end

--- Get orb at position
---@param gameState table Game state
---@param col number Column
---@param row number Row
---@return string|nil Power ID or nil
function GameClient.getOrbAt(gameState, col, row)
	if not gameState or not gameState.board or not gameState.board.tiles then
		return nil
	end
	for _, tile in ipairs(gameState.board.tiles) do
		if tile.col == col and tile.row == row then
			return tile.orb
		end
	end
	return nil
end

return GameClient
