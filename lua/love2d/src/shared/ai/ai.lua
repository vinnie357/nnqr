-- AI Module
-- Phase 8A: AI Framework
-- Phase 8B: Medium AI with heuristic evaluation
-- Phase 9B (nnqr-20): Power dispatch for Hard/Expert AI

local PowerEffects = require("src.shared.power_effects")
local Evaluator = require("src.shared.ai.evaluator")
local Search = require("src.shared.ai.search")

local AI = {}

-- Maximum power-activation candidates folded into move selection per turn.
-- Keeps search breadth bounded so expert depth-4 stays within budget.
local MAX_POWER_CANDIDATES = 3

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

--- Convert a move from {piece=object, target} format to {piece=index, target} format
---@param gameState table Game state
---@param move table Move with piece object reference
---@return table|nil Move with piece index, or nil if piece not found
local function convertMoveToIndex(gameState, move)
	if not move then
		return nil
	end

	local pieceIndex = nil
	for idx, p in ipairs(gameState.pieces) do
		if p == move.piece then
			pieceIndex = idx
			break
		end
	end

	if not pieceIndex then
		return nil
	end

	return {
		piece = pieceIndex,
		target = move.target,
	}
end

--- Choose a heuristic move using the Evaluator (Medium AI)
---@param gameState table Game state
---@param player number Player to find move for
---@param orbs table Array of orbs on the board
---@return table|nil Move {piece, target} or nil
local function chooseHeuristicMove(gameState, player, orbs)
	local bestMove = Evaluator.getBestMove(gameState, orbs, player)
	return convertMoveToIndex(gameState, bestMove)
end

--- Score a power activation candidate for pre-dispatch heuristic comparison.
--- Returns a numeric score; higher = more valuable activation.
---@param state table Game state
---@param piece table Piece with the power
---@param powerId string Power to evaluate
---@return number score, boolean approved
local function scorePowerCandidate(state, piece, powerId)
	if powerId == "jump_proof" then
		local ok = Evaluator.shouldUseJumpProof(state, piece)
		if ok then
			-- Score is high: protecting a threatened piece is urgent
			return 80, true
		end
		return 0, false
	elseif powerId == "destroy_row" then
		local ok, targets = Evaluator.shouldUseDestroyRow(state, piece)
		-- Dispatch threshold: require ≥2 enemies — single target can be captured normally
		if ok and #targets >= 2 then
			return 50 + #targets * Evaluator.WEIGHTS.CAPTURE_BONUS, true
		end
		return 0, false
	elseif powerId == "destroy_column" then
		local ok, targets = Evaluator.shouldUseDestroyColumn(state, piece)
		-- Dispatch threshold: require ≥2 enemies
		if ok and #targets >= 2 then
			return 50 + #targets * Evaluator.WEIGHTS.CAPTURE_BONUS, true
		end
		return 0, false
	elseif powerId == "recruit" then
		local ok, targets = Evaluator.shouldUseRecruit(state, piece)
		if ok then
			return 45 + #targets * 10, true
		end
		return 0, false
	elseif powerId == "bomb" then
		local ok, targets = Evaluator.shouldUseBomb(state, piece)
		if ok then
			-- Bomb hits multiple enemies: highly valuable
			return 55 + #targets * Evaluator.WEIGHTS.CAPTURE_BONUS, true
		end
		return 0, false
	end
	-- Unknown power: do not auto-activate
	return 0, false
end

--- Build a list of approved power-activation candidates for a player.
--- Only powers whose heuristic approves are included (no wasted single-use powers).
--- Returns at most MAX_POWER_CANDIDATES entries, sorted by score descending.
---@param state table Game state
---@param player number Player to generate candidates for
---@return table Array of {piece=idx, powerId=string, score=number}
local function getPowerActivationCandidates(state, player)
	local candidates = {}

	for idx, piece in ipairs(state.pieces) do
		if piece.player == player and piece.powers and #piece.powers > 0 then
			for _, powerId in ipairs(piece.powers) do
				local score, approved = scorePowerCandidate(state, piece, powerId)
				if approved then
					table.insert(candidates, { piece = idx, powerId = powerId, score = score })
				end
			end
		end
	end

	-- Sort descending by score
	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)

	-- Cap breadth so search doesn't explode
	local capped = {}
	for i = 1, math.min(#candidates, MAX_POWER_CANDIDATES) do
		table.insert(capped, candidates[i])
	end
	return capped
end

--- Choose a move using minimax search (Hard/Expert AI) with power-dispatch.
--- Power-activation candidates are evaluated alongside movement candidates.
--- The best overall action (move or power) is returned.
---@param gameState table Game state
---@param player number Player to find move for
---@param depth number Search depth
---@return table|nil Move {piece, target} or power {piece, powerId} or nil
local function chooseMinimaxMove(gameState, player, depth)
	-- 1. Evaluate power candidates using the heuristics (pre-dispatch, no search overhead)
	local powerCandidates = getPowerActivationCandidates(gameState, player)

	-- 2. Get the best regular movement via minimax
	local bestMovePiece = Search.findBestMove(gameState, depth, player)
	local bestMoveIndexed = convertMoveToIndex(gameState, bestMovePiece)

	-- 3. If there are no approved power candidates, return the movement
	if #powerCandidates == 0 then
		return bestMoveIndexed
	end

	-- 4. Pick the highest-scored power candidate
	local topPower = powerCandidates[1]

	-- 5. Compare top power score vs movement value.
	-- We use the power's heuristic score directly.
	-- If no movement is available, definitely use the power.
	if not bestMoveIndexed then
		return { piece = topPower.piece, powerId = topPower.powerId }
	end

	-- 6. Estimate movement value for comparison using the evaluator scoreMove.
	-- We need the piece object for scoreMove.
	local movePiece = gameState.pieces[bestMoveIndexed.piece]
	local moveScore = 0
	if movePiece then
		local moveObj = { piece = movePiece, target = bestMoveIndexed.target }
		moveScore = Evaluator.scoreMove(gameState, moveObj, {})
	end

	-- Use the power when its heuristic score beats the best move score
	if topPower.score > moveScore then
		return { piece = topPower.piece, powerId = topPower.powerId }
	end

	return bestMoveIndexed
end

--- Choose a move for the AI
---@param aiState table AI state
---@param gameState table Current game state
---@param orbs table? Optional array of orbs on the board
---@return table|nil {piece, target} or {piece, powerId} or nil
function AI.chooseMove(aiState, gameState, orbs)
	orbs = orbs or {}

	local moves = getAllValidMoves(gameState, aiState.player)

	if #moves == 0 then
		return nil
	end

	local strategy = aiState.config.strategy

	if strategy == "random" then
		-- Easy AI: movement only, no power dispatch
		return chooseRandomMove(moves)
	elseif strategy == "heuristic" then
		-- Medium AI: rule-based movement, no power dispatch
		return chooseHeuristicMove(gameState, aiState.player, orbs)
	elseif strategy == "minimax" then
		-- Hard/Expert AI: minimax movement + power dispatch via heuristics
		return chooseMinimaxMove(gameState, aiState.player, aiState.config.searchDepth)
	end

	return chooseRandomMove(moves)
end

return AI
