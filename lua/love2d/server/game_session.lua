-- Game Session module for multiplayer
-- Manages active game state and integrates with GameLogic
-- Phase 10A: Network Multiplayer
-- Phase 3: Server-side AI Games

local GameLogic = require("src.shared.game_logic")
local PowerEffects = require("src.shared.power_effects")
local AI = require("src.shared.ai.ai")

local GameSession = {}

-- AI think delay in seconds
GameSession.AI_THINK_DELAY = 0.8

--- Create a new game session
---@param gameId string Game ID
---@param player1Id string Player 1 ID
---@param player2Id string Player 2 ID
---@param settings table|nil Optional game settings
---@return table GameSession state
function GameSession.create(gameId, player1Id, player2Id, settings)
	local state = GameLogic.createInitialState()

	return {
		gameId = gameId,
		player1Id = player1Id,
		player2Id = player2Id,
		state = state,
		status = "playing", -- playing, finished
		settings = settings or {},
		createdAt = os.time(),
		lastActivity = os.time(),
	}
end

--- Create a PvP game session (alias for create)
---@param gameId string Game ID
---@param player1Id string Player 1 ID
---@param player2Id string Player 2 ID
---@param settings table|nil Optional game settings
---@return table GameSession state
function GameSession.createPvPGame(gameId, player1Id, player2Id, settings)
	return GameSession.create(gameId, player1Id, player2Id, settings)
end

--- Get player number (1 or 2) for a player ID
---@param session table GameSession state
---@param playerId string Player ID
---@return number|nil Player number (1 or 2) or nil if not in game
function GameSession.getPlayerNumber(session, playerId)
	if playerId == session.player1Id then
		return 1
	elseif playerId == session.player2Id then
		return 2
	end
	return nil
end

--- Check if it's a player's turn
---@param session table GameSession state
---@param playerId string Player ID
---@return boolean True if it's this player's turn
function GameSession.isPlayerTurn(session, playerId)
	local playerNum = GameSession.getPlayerNumber(session, playerId)
	if not playerNum then
		return false
	end
	return session.state.currentPlayer == playerNum
end

--- Get piece at position
---@param session table GameSession state
---@param col number Column
---@param row number Row
---@return table|nil Piece or nil
local function getPieceAt(session, col, row)
	return GameLogic.getPieceAt(session.state, row, col)
end

--- Find power index in piece's powers array
---@param piece table Piece
---@param powerId string Power ID to find
---@return number|nil Index or nil if not found
local function findPowerIndex(piece, powerId)
	if not piece.powers then
		return nil
	end
	for i, power in ipairs(piece.powers) do
		if power == powerId then
			return i
		end
	end
	return nil
end

--- Handle a move request
---@param session table GameSession state
---@param playerId string Player making the move
---@param moveData table Move data {from: {col, row}, to: {col, row}}
---@return table Result {success: boolean, error?: string, captured?: table}
function GameSession.handleMove(session, playerId, moveData)
	-- Check if game is still active
	if session.status ~= "playing" then
		return { success = false, error = "GAME_OVER" }
	end

	-- Check if it's this player's turn
	if not GameSession.isPlayerTurn(session, playerId) then
		return { success = false, error = "NOT_YOUR_TURN" }
	end

	local playerNum = GameSession.getPlayerNumber(session, playerId)
	local from = moveData.from
	local to = moveData.to

	-- Get piece at source
	local piece = getPieceAt(session, from.col, from.row)
	if not piece then
		return { success = false, error = "NO_PIECE" }
	end

	-- Check piece belongs to current player
	if piece.player ~= playerNum then
		return { success = false, error = "NOT_YOUR_PIECE" }
	end

	-- Select piece to calculate valid moves
	GameLogic.selectPiece(session.state, piece)

	-- Check if destination is valid
	local isValid = false
	for _, move in ipairs(session.state.validMoves) do
		if move.row == to.row and move.col == to.col then
			isValid = true
			break
		end
	end

	if not isValid then
		GameLogic.selectPiece(session.state, nil) -- Clear selection
		return { success = false, error = "INVALID_MOVE" }
	end

	-- Check for capture
	local targetPiece = getPieceAt(session, to.col, to.row)
	local captured = nil
	if targetPiece then
		captured = {
			player = targetPiece.player,
			col = targetPiece.col,
			row = targetPiece.row,
		}
	end

	-- Execute move
	GameLogic.movePiece(session.state, piece, to.row, to.col)

	-- End turn
	GameLogic.endTurn(session.state)

	-- Update last activity
	session.lastActivity = os.time()

	-- Check for game over
	if session.state.gameState == "gameover" then
		session.status = "finished"
	end

	return {
		success = true,
		captured = captured,
		gameOver = session.state.gameState == "gameover",
		winner = session.state.winner,
	}
end

--- Handle a power activation request
---@param session table GameSession state
---@param playerId string Player activating power
---@param powerData table Power data {piece_pos: {col, row}, power_id: string, target?: {col, row}}
---@return table Result {success: boolean, error?: string, effects?: table}
function GameSession.handlePower(session, playerId, powerData)
	-- Check if game is still active
	if session.status ~= "playing" then
		return { success = false, error = "GAME_OVER" }
	end

	-- Check if it's this player's turn
	if not GameSession.isPlayerTurn(session, playerId) then
		return { success = false, error = "NOT_YOUR_TURN" }
	end

	local playerNum = GameSession.getPlayerNumber(session, playerId)
	local piecePos = powerData.piece_pos
	local powerId = powerData.power_id
	local target = powerData.target

	-- Get piece at position
	local piece = getPieceAt(session, piecePos.col, piecePos.row)
	if not piece then
		return { success = false, error = "NO_PIECE" }
	end

	-- Check piece belongs to current player
	if piece.player ~= playerNum then
		return { success = false, error = "NOT_YOUR_PIECE" }
	end

	-- Check piece has the power
	local powerIndex = findPowerIndex(piece, powerId)
	if not powerIndex then
		return { success = false, error = "NO_POWER" }
	end

	-- Execute the power effect
	-- For now, we just apply the power flag using PowerEffects
	-- More complex powers would need additional handling
	local effects = {}

	-- Apply power effect based on type
	-- Self-targeting powers that set flags
	local flagPowers = {
		move_diagonal = "canMoveDiagonally",
		jump_proof = "isJumpProof",
		invisible = "isInvisible",
		move_again = "canMoveAgain",
	}

	if flagPowers[powerId] then
		local flag = flagPowers[powerId]
		piece[flag] = true
		table.insert(effects, { type = "flag_set", flag = flag, piece_col = piece.col, piece_row = piece.row })
	else
		-- For other powers, use PowerEffects if available
		-- This is a simplified implementation - full integration would use PowerExecutor
		table.insert(effects, { type = "power_used", power_id = powerId })
	end

	-- Remove power from piece
	table.remove(piece.powers, powerIndex)

	-- Update last activity
	session.lastActivity = os.time()

	-- Check for game over (some powers can end the game)
	if session.state.gameState == "gameover" then
		session.status = "finished"
	end

	return {
		success = true,
		power_id = powerId,
		effects = effects,
		gameOver = session.state.gameState == "gameover",
		winner = session.state.winner,
	}
end

--- Get serializable game state for network transmission
---@param session table GameSession state
---@return table Serializable state object
function GameSession.getState(session)
	local state = session.state

	-- Build tiles array with height info
	local tiles = {}
	for row = 1, state.rows do
		for col = 1, state.cols do
			local height = GameLogic.getHeight(state, row, col)
			local isDestroyed = GameLogic.isTileDestroyed(state, row, col)
			-- Get orb at position if any
			local orb = nil
			if state.orbs then
				for _, o in ipairs(state.orbs) do
					if o.row == row and o.col == col then
						orb = o.power_id
						break
					end
				end
			end
			table.insert(tiles, {
				col = col,
				row = row,
				height = height,
				destroyed = isDestroyed or nil,
				orb = orb,
			})
		end
	end

	-- Build pieces array
	local pieces = {}
	for _, piece in ipairs(state.pieces) do
		table.insert(pieces, {
			col = piece.col,
			row = piece.row,
			player = piece.player,
			powers = piece.powers or {},
			visible = not piece.isInvisible,
			-- Include flags relevant to gameplay
			canMoveDiagonally = piece.canMoveDiagonally or nil,
			isJumpProof = piece.isJumpProof or nil,
		})
	end

	local result = {
		game_id = session.gameId,
		turn = state.turn,
		current_player = state.currentPlayer,
		phase = "move", -- Could be expanded for power phase
		board = {
			cols = state.cols,
			rows = state.rows,
			tiles = tiles,
		},
		pieces = pieces,
		winner = state.winner,
		game_over = state.gameState == "gameover",
	}

	-- Add AI game info if applicable
	if session.isAIGame then
		result.is_ai_game = true
		result.ai_difficulty = session.aiDifficulty
	end

	return result
end

--- Forfeit the game (player surrenders)
---@param session table GameSession state
---@param playerId string Player forfeiting
---@return boolean success
function GameSession.forfeit(session, playerId)
	local playerNum = GameSession.getPlayerNumber(session, playerId)
	if not playerNum then
		return false
	end

	-- Set the other player as winner
	local winner = playerNum == 1 and 2 or 1
	session.state.gameState = "gameover"
	session.state.winner = winner
	session.status = "finished"
	session.lastActivity = os.time()

	return true
end

--- Create a new AI game session
---@param gameId string Game ID
---@param playerId string Human player ID
---@param difficulty string AI difficulty (easy/medium/hard/expert)
---@param settings table|nil Optional game settings
---@return table GameSession state
function GameSession.createAIGame(gameId, playerId, difficulty, settings)
	local state = GameLogic.createInitialState()

	-- Generate terrain (same pattern as client Game.generateTerrain)
	for row = 3, 6 do
		for col = 4, 7 do
			GameLogic.setHeight(state, row, col, 1)
		end
	end
	GameLogic.setHeight(state, 4, 5, 2)
	GameLogic.setHeight(state, 5, 6, 2)
	GameLogic.setHeight(state, 4, 6, 3)

	return {
		gameId = gameId,
		player1Id = playerId, -- Human is always player 1
		player2Id = "AI", -- AI marker
		state = state,
		status = "playing",
		settings = settings or {},
		createdAt = os.time(),
		lastActivity = os.time(),
		-- AI-specific fields
		isAIGame = true,
		aiDifficulty = difficulty,
		aiThinkTimer = 0,
		ai = AI.create(difficulty, 2), -- AI plays as player 2
	}
end

--- Check if session is an AI game
---@param session table GameSession state
---@return boolean True if AI game
function GameSession.isAIGame(session)
	return session.isAIGame == true
end

--- Check if it's the AI's turn
---@param session table GameSession state
---@return boolean True if AI should move
function GameSession.isAITurn(session)
	if not GameSession.isAIGame(session) then
		return false
	end
	return session.state.currentPlayer == 2 -- AI is always player 2
end

--- Update AI and make move if ready
---@param session table GameSession state
---@param dt number Delta time in seconds
---@return table|nil Move result if AI made a move
function GameSession.updateAI(session, dt)
	-- Only process AI games when it's AI's turn
	if not GameSession.isAIGame(session) or not GameSession.isAITurn(session) then
		return nil
	end

	-- Check if game is still active
	if session.status ~= "playing" then
		return nil
	end

	-- Increment think timer
	session.aiThinkTimer = session.aiThinkTimer + dt

	-- Check if enough time has passed
	if session.aiThinkTimer < GameSession.AI_THINK_DELAY then
		return nil
	end

	-- Reset timer
	session.aiThinkTimer = 0

	-- Get AI move
	local move = AI.chooseMove(session.ai, session.state)
	if not move then
		-- AI can't move - might be stalemate or error
		return nil
	end

	-- Execute the move
	local movingPiece = session.state.pieces[move.piece]
	if not movingPiece then
		return nil
	end

	-- Check for capture
	local targetPiece = GameLogic.getPieceAt(session.state, move.target.row, move.target.col)
	local captured = nil
	if targetPiece then
		captured = {
			player = targetPiece.player,
			col = targetPiece.col,
			row = targetPiece.row,
		}
	end

	-- Execute move
	GameLogic.movePiece(session.state, movingPiece, move.target.row, move.target.col)

	-- End turn
	GameLogic.endTurn(session.state)

	-- Update last activity
	session.lastActivity = os.time()

	-- Check for game over
	if session.state.gameState == "gameover" then
		session.status = "finished"
	end

	return {
		success = true,
		from = { col = movingPiece.col, row = movingPiece.row },
		to = move.target,
		captured = captured,
		gameOver = session.state.gameState == "gameover",
		winner = session.state.winner,
	}
end

return GameSession
