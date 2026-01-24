-- State creation helpers for power executor tests
-- Creates minimal game state for testing powers

local Height = require("src.shared.height")

local State = {}

-- Board dimensions
State.BOARD_COLS = 10
State.BOARD_ROWS = 8

--- Create a minimal game state with no pieces
---@param opts? table Optional overrides {currentPlayer, turn}
---@return table Game state
function State.createEmptyState(opts)
	opts = opts or {}
	return {
		cols = State.BOARD_COLS,
		rows = State.BOARD_ROWS,
		heightMap = Height.createHeightMap(State.BOARD_COLS, State.BOARD_ROWS, 0),
		pieces = {},
		currentPlayer = opts.currentPlayer or 1,
		selectedPiece = nil,
		validMoves = {},
		gameState = "playing",
		winner = nil,
		turn = opts.turn or 0,
		destroyedTiles = {},
		orbs = {},
	}
end

--- Create game state with initial pieces (full setup)
---@param opts? table Optional overrides
---@return table Game state
function State.createState(opts)
	local GameLogic = require("src.shared.game_logic")
	local state = GameLogic.createInitialState()
	opts = opts or {}
	if opts.currentPlayer then
		state.currentPlayer = opts.currentPlayer
	end
	if opts.turn then
		state.turn = opts.turn
	end
	return state
end

--- Create a minimal state for testing a specific power
--- Places just the activating piece
---@param row number Piece row
---@param col number Piece column
---@param player? number Player (default 1)
---@return table state, table piece
function State.createStateWithPiece(row, col, player)
	player = player or 1
	local state = State.createEmptyState({ currentPlayer = player })
	local piece = {
		row = row,
		col = col,
		player = player,
		powers = {},
	}
	table.insert(state.pieces, piece)
	return state, piece
end

return State
