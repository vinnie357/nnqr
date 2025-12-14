-- Game Logic Module
-- Pure game state management with height system integration
-- No Love2D dependencies - fully testable

local Height = require("src.shared.height")
local Logic = require("src.logic")
local PowerEffects = require("src.shared.power_effects")

local GameLogic = {}

-- Board dimensions
GameLogic.BOARD_COLS = 10
GameLogic.BOARD_ROWS = 8

--- Create initial game state
---@return table Game state object
function GameLogic.createInitialState()
	local state = {
		cols = GameLogic.BOARD_COLS,
		rows = GameLogic.BOARD_ROWS,
		heightMap = Height.createHeightMap(GameLogic.BOARD_COLS, GameLogic.BOARD_ROWS, 0),
		pieces = {},
		currentPlayer = 1,
		selectedPiece = nil,
		validMoves = {},
		gameState = "playing",
		winner = nil,
		turn = 0,
	}

	-- Create pieces for both players
	local p1Pieces = Logic.createInitialPieces(1)
	local p2Pieces = Logic.createInitialPieces(2)

	for _, piece in ipairs(p1Pieces) do
		table.insert(state.pieces, piece)
	end
	for _, piece in ipairs(p2Pieces) do
		table.insert(state.pieces, piece)
	end

	return state
end

--- Get piece at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return table|nil Piece or nil if empty
function GameLogic.getPieceAt(state, row, col)
	for _, piece in ipairs(state.pieces) do
		if piece.row == row and piece.col == col then
			return piece
		end
	end
	return nil
end

--- Get height at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return number Height at position
function GameLogic.getHeight(state, row, col)
	return Height.getHeight(state.heightMap, row, col)
end

--- Set height at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@param height number New height
---@return table Updated game state
function GameLogic.setHeight(state, row, col, height)
	Height.setHeight(state.heightMap, row, col, height)
	return state
end

--- Check if a move is valid
---@param state table Game state
---@param piece table Piece to move
---@param toRow number Destination row
---@param toCol number Destination column
---@return boolean True if move is valid
function GameLogic.isValidMove(state, piece, toRow, toCol)
	-- Get heights
	local fromHeight = GameLogic.getHeight(state, piece.row, piece.col)
	local toHeight = GameLogic.getHeight(state, toRow, toCol)

	-- Get target piece (if any)
	local targetPiece = GameLogic.getPieceAt(state, toRow, toCol)
	local targetPlayer = targetPiece and targetPiece.player or nil

	-- Use height-aware validation
	return Logic.isValidMoveWithHeight(
		piece.row,
		piece.col,
		toRow,
		toCol,
		piece.player,
		targetPlayer,
		fromHeight,
		toHeight
	)
end

--- Get all valid moves for a piece
---@param state table Game state
---@param piece table Piece to get moves for
---@return table Array of {row, col} valid move positions
function GameLogic.getValidMoves(state, piece)
	local pieceHeight = GameLogic.getHeight(state, piece.row, piece.col)

	return Logic.getValidMovesWithHeight(piece.row, piece.col, piece.player, function(r, c)
		return GameLogic.getPieceAt(state, r, c)
	end, function(r, c)
		return GameLogic.getHeight(state, r, c)
	end, pieceHeight)
end

--- Select a piece and calculate its valid moves
--- Uses PowerEffects.getValidMovesWithPowers to consider piece flags
---@param state table Game state
---@param piece table|nil Piece to select, or nil to deselect
---@return table Updated game state
function GameLogic.selectPiece(state, piece)
	if piece == nil then
		state.selectedPiece = nil
		state.validMoves = {}
		return state
	end

	-- Only allow selecting current player's pieces
	if piece.player ~= state.currentPlayer then
		return state
	end

	state.selectedPiece = piece
	-- Use power-aware move calculation that considers flags like canMoveDiagonally, isJumpProof
	state.validMoves = PowerEffects.getValidMovesWithPowers(state, piece)
	return state
end

--- Move a piece to a new position
---@param state table Game state
---@param piece table Piece to move
---@param toRow number Destination row
---@param toCol number Destination column
---@return table Updated game state
function GameLogic.movePiece(state, piece, toRow, toCol)
	-- Check for capture
	local targetPiece = GameLogic.getPieceAt(state, toRow, toCol)
	if targetPiece then
		-- Reveal invisible attacker if capturing
		if piece.isInvisible then
			PowerEffects.revealInvisible(piece)
		end

		-- Remove captured piece
		for i, p in ipairs(state.pieces) do
			if p == targetPiece then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	-- Move piece
	piece.row = toRow
	piece.col = toCol

	-- Clear selection
	state.selectedPiece = nil
	state.validMoves = {}

	return state
end

--- End the current turn
---@param state table Game state
---@return table Updated game state
function GameLogic.endTurn(state)
	-- Switch player
	state.currentPlayer = state.currentPlayer == 1 and 2 or 1
	state.turn = state.turn + 1

	-- Check for game over
	local p1Count, p2Count = Logic.countPieces(state.pieces)

	if p1Count == 0 then
		state.gameState = "gameover"
		state.winner = 2
	elseif p2Count == 0 then
		state.gameState = "gameover"
		state.winner = 1
	end

	return state
end

return GameLogic
