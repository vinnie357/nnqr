-- AI Module
-- Phase 8A: AI Framework
-- Phase 8B: Medium AI with heuristic evaluation

local PowerEffects = require("src.shared.power_effects")
local Evaluator = require("src.shared.ai.evaluator")

local AI = {}

-- Difficulty configurations
local DIFFICULTY_CONFIG = {
	easy = { searchDepth = 0, strategy = "random" },
	medium = { searchDepth = 0, strategy = "heuristic" },
	hard = { searchDepth = 2, strategy = "minimax" },
	expert = { searchDepth = 4, strategy = "minimax" },
}

local VALID_DIFFICULTIES = { easy = true, medium = true, hard = true, expert = true }

--- Create an AI player
---@param difficulty string "easy"|"medium"|"hard"|"expert"
---@param player number? Player number (defaults to 2)
---@return table AI state
function AI.create(difficulty, player)
	-- Default to easy if invalid difficulty
	if not VALID_DIFFICULTIES[difficulty] then
		difficulty = "easy"
	end

	return {
		difficulty = difficulty,
		player = player or 2,
		config = DIFFICULTY_CONFIG[difficulty],
	}
end

--- Get difficulty configuration
---@param difficulty string "easy"|"medium"|"hard"|"expert"
---@return table Configuration with searchDepth and strategy
function AI.getDifficultyConfig(difficulty)
	return DIFFICULTY_CONFIG[difficulty] or DIFFICULTY_CONFIG.easy
end

-- Display names for difficulties (for UI)
local DIFFICULTY_DISPLAY_NAMES = {
	easy = "Easy",
	medium = "Medium",
	hard = "Hard",
	expert = "Expert",
}

--- Get display name for difficulty (for UI indicator)
---@param difficulty string Internal difficulty name
---@return string Human-readable display name
function AI.getDifficultyDisplayName(difficulty)
	return DIFFICULTY_DISPLAY_NAMES[difficulty] or "Unknown"
end

--- Check if it's the AI's turn
---@param aiState table AI state
---@param gameState table Current game state
---@return boolean True if it's AI's turn
function AI.isAITurn(aiState, gameState)
	return gameState.currentPlayer == aiState.player
end

--- Get all valid moves for a player
--- Uses PowerEffects.getValidMovesWithPowers to respect flags like isJumpProof
---@param state table Game state
---@param player number Player to get moves for
---@return table List of {piece=idx, target={row,col}} moves
local function getAllValidMoves(state, player)
	local moves = {}

	for idx, piece in ipairs(state.pieces) do
		if piece.player == player then
			-- Use power-aware move calculation that respects flags like isJumpProof
			local validTargets = PowerEffects.getValidMovesWithPowers(state, piece)
			for _, target in ipairs(validTargets) do
				table.insert(moves, {
					piece = idx,
					target = { row = target.row, col = target.col },
				})
			end
		end
	end

	return moves
end

--- Choose a random move (Easy AI)
---@param moves table List of valid moves
---@return table|nil A random move or nil if no moves
local function chooseRandomMove(moves)
	if #moves == 0 then
		return nil
	end
	return moves[math.random(#moves)]
end

--- Choose a heuristic move using the Evaluator (Medium AI)
---@param gameState table Game state
---@param player number Player to find move for
---@param orbs table Array of orbs on the board
---@return table|nil Move {piece, target} or nil
local function chooseHeuristicMove(gameState, player, orbs)
	local bestMove = Evaluator.getBestMove(gameState, orbs, player)

	if not bestMove then
		return nil
	end

	-- Convert from Evaluator format {piece=object, target={row,col}}
	-- to AI format {piece=index, target={row,col}}
	local pieceIndex = nil
	for idx, p in ipairs(gameState.pieces) do
		if p == bestMove.piece then
			pieceIndex = idx
			break
		end
	end

	if not pieceIndex then
		return nil
	end

	return {
		piece = pieceIndex,
		target = bestMove.target,
	}
end

--- Choose a move for the AI
---@param aiState table AI state
---@param gameState table Current game state
---@param orbs table? Optional array of orbs on the board
---@return table|nil {piece, target, powers} Move to make, or nil if no valid moves
function AI.chooseMove(aiState, gameState, orbs)
	orbs = orbs or {}

	local moves = getAllValidMoves(gameState, aiState.player)

	if #moves == 0 then
		return nil
	end

	local strategy = aiState.config.strategy

	if strategy == "random" then
		return chooseRandomMove(moves)
	elseif strategy == "heuristic" then
		-- Phase 8B: Use rule-based evaluation
		return chooseHeuristicMove(gameState, aiState.player, orbs)
	elseif strategy == "minimax" then
		-- TODO: Phase 8C - implement minimax search
		return chooseRandomMove(moves)
	end

	return chooseRandomMove(moves)
end

return AI
