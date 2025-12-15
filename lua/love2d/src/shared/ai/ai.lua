-- AI Module
-- Phase 8A: AI Framework

local PowerEffects = require("src.shared.power_effects")

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

--- Choose a move for the AI
---@param aiState table AI state
---@param gameState table Current game state
---@return table|nil {piece, target, powers} Move to make, or nil if no valid moves
function AI.chooseMove(aiState, gameState)
	local moves = getAllValidMoves(gameState, aiState.player)

	if #moves == 0 then
		return nil
	end

	-- For now, all difficulties use random move selection
	-- Medium, Hard, Expert will be implemented in phases 8B and 8C
	local strategy = aiState.config.strategy

	if strategy == "random" then
		return chooseRandomMove(moves)
	elseif strategy == "heuristic" then
		-- TODO: Phase 8B - implement rule-based evaluation
		return chooseRandomMove(moves)
	elseif strategy == "minimax" then
		-- TODO: Phase 8C - implement minimax search
		return chooseRandomMove(moves)
	end

	return chooseRandomMove(moves)
end

return AI
