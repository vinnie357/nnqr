-- AI Evaluator Module
-- Phase 8B: Rule-Based AI - Board evaluation and heuristics

local PowerEffects = require("src.shared.power_effects")
local Powers = require("src.shared.powers")
local Height = require("src.shared.height")
local Logic = require("src.logic")

local Evaluator = {}

-- Scoring weights
Evaluator.WEIGHTS = {
	CENTER_BONUS = 10, -- Max bonus for center position
	HEIGHT_BONUS = 5, -- Bonus per height level
	POWER_BONUS = 8, -- Bonus per power in inventory
	JUMP_PROOF_BONUS = 15, -- Bonus for being jump proof
	DIAGONAL_BONUS = 10, -- Bonus for diagonal movement
	ORB_BASE_VALUE = 15, -- Base value for collecting any orb
	-- Move scoring weights
	CAPTURE_BONUS = 50, -- Base bonus for capturing enemy piece
	CAPTURE_VALUE_MULT = 2, -- Multiplier for captured piece's value
	THREAT_PENALTY = 30, -- Penalty for moving into threatened position
	POSITION_WEIGHT = 1, -- Weight for position improvement
	RISKY_ORB_PENALTY = 20, -- Penalty for risky orb collection
	-- Board evaluation weights (for minimax)
	PIECE_VALUE = 100, -- Base value per piece
	WIN_BONUS = 10000, -- Bonus for winning position
}

-- Power value scores for orb collection priority
Evaluator.POWER_VALUES = {
	-- Offensive powers (high value)
	bomb = 25,
	destroy_row = 20,
	destroy_column = 20,
	recruit = 22,
	-- Defensive powers
	jump_proof = 18,
	-- Movement powers
	move_diagonal = 15,
	move_again = 12,
	relocate = 10,
	-- Terrain powers
	raise_tile = 8,
	lower_tile = 8,
	-- Utility powers
	multiply = 18,
	invisible = 12,
	refurb = 6,
}

--- Get all pieces belonging to a player that can be captured by opponent next turn
---@param state table Game state
---@param player number Player whose pieces to check for threats
---@return table Array of threatened pieces
function Evaluator.getThreatenedPieces(state, player)
	local threatened = {}
	local opponent = player == 1 and 2 or 1

	-- For each opponent piece, get their valid moves (which include captures)
	for _, enemyPiece in ipairs(state.pieces) do
		if enemyPiece.player == opponent then
			local moves = PowerEffects.getValidMovesWithPowers(state, enemyPiece)
			for _, move in ipairs(moves) do
				-- Check if this move captures one of our pieces
				for _, ourPiece in ipairs(state.pieces) do
					if ourPiece.player == player and ourPiece.row == move.row and ourPiece.col == move.col then
						-- Avoid duplicates - check if already in threatened list
						local found = false
						for _, t in ipairs(threatened) do
							if t == ourPiece then
								found = true
								break
							end
						end
						if not found then
							table.insert(threatened, ourPiece)
						end
					end
				end
			end
		end
	end

	return threatened
end

--- Get all capture opportunities for a player
--- Returns moves where the player can capture an enemy piece
---@param state table Game state
---@param player number Player whose capture opportunities to find
---@return table Array of {piece, target, targetPiece} objects
function Evaluator.getCaptureOpportunities(state, player)
	local opportunities = {}

	-- For each of our pieces, check if any valid moves capture an enemy
	for _, piece in ipairs(state.pieces) do
		if piece.player == player then
			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			for _, move in ipairs(moves) do
				-- Check if this move lands on an enemy piece
				for _, enemyPiece in ipairs(state.pieces) do
					if enemyPiece.player ~= player and enemyPiece.row == move.row and enemyPiece.col == move.col then
						table.insert(opportunities, {
							piece = piece,
							target = { row = move.row, col = move.col },
							targetPiece = enemyPiece,
						})
					end
				end
			end
		end
	end

	return opportunities
end

--- Check if piece should use jump_proof power
--- Use when: piece is threatened and has jump_proof in inventory (not already active)
---@param state table Game state
---@param piece table Piece to evaluate
---@return boolean True if should activate jump_proof
function Evaluator.shouldUseJumpProof(state, piece)
	-- Must have jump_proof power and not already active
	if not Powers.hasPower(piece, "jump_proof") then
		return false
	end
	if piece.isJumpProof then
		return false
	end

	-- Check if this piece is threatened
	local threatened = Evaluator.getThreatenedPieces(state, piece.player)
	for _, t in ipairs(threatened) do
		if t == piece then
			return true
		end
	end

	return false
end

--- Check if piece should use destroy_row power
--- Use when: enemy pieces exist in the same row (and will destroy more enemies than allies)
---@param state table Game state
---@param piece table Piece to evaluate
---@return boolean True if should activate, table Targets (enemy pieces that would be destroyed)
function Evaluator.shouldUseDestroyRow(state, piece)
	-- Must have destroy_row power
	if not Powers.hasPower(piece, "destroy_row") then
		return false, {}
	end

	-- Get all pieces in the same row (excluding self)
	local enemiesInRow = {}
	local alliesInRow = 0

	for _, p in ipairs(state.pieces) do
		if p.row == piece.row and p ~= piece then
			if p.player ~= piece.player then
				table.insert(enemiesInRow, p)
			else
				alliesInRow = alliesInRow + 1
			end
		end
	end

	-- Only use if there are enemies and no allies would be destroyed
	if #enemiesInRow > 0 and alliesInRow == 0 then
		return true, enemiesInRow
	end

	return false, {}
end

--- Check if piece should use destroy_column power
--- Use when: enemy pieces exist in the same column (and will destroy more enemies than allies)
---@param state table Game state
---@param piece table Piece to evaluate
---@return boolean True if should activate, table Targets (enemy pieces that would be destroyed)
function Evaluator.shouldUseDestroyColumn(state, piece)
	-- Must have destroy_column power
	if not Powers.hasPower(piece, "destroy_column") then
		return false, {}
	end

	-- Get all pieces in the same column (excluding self)
	local enemiesInCol = {}
	local alliesInCol = 0

	for _, p in ipairs(state.pieces) do
		if p.col == piece.col and p ~= piece then
			if p.player ~= piece.player then
				table.insert(enemiesInCol, p)
			else
				alliesInCol = alliesInCol + 1
			end
		end
	end

	-- Only use if there are enemies and no allies would be destroyed
	if #enemiesInCol > 0 and alliesInCol == 0 then
		return true, enemiesInCol
	end

	return false, {}
end

--- Check if piece should use recruit power
--- Use when: adjacent enemy pieces exist
---@param state table Game state
---@param piece table Piece to evaluate
---@return boolean True if should activate, table Targets (adjacent enemies)
function Evaluator.shouldUseRecruit(state, piece)
	-- Must have recruit power
	if not Powers.hasPower(piece, "recruit") then
		return false, {}
	end

	-- Get adjacent enemy pieces
	local targets = PowerEffects.getRecruitTargets(state, piece)

	if #targets > 0 then
		return true, targets
	end

	return false, {}
end

--- Check if piece should use bomb power
--- Use when: multiple enemies in 3x3 area AND no allies would be destroyed
---@param state table Game state
---@param piece table Piece to evaluate
---@return boolean True if should activate, table Targets (enemy pieces in range)
function Evaluator.shouldUseBomb(state, piece)
	-- Must have bomb power
	if not Powers.hasPower(piece, "bomb") then
		return false, {}
	end

	-- Get all pieces in 3x3 area (excluding self)
	local enemiesInRange = {}
	local alliesInRange = 0

	for _, p in ipairs(state.pieces) do
		if p ~= piece then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				if p.player ~= piece.player then
					table.insert(enemiesInRange, p)
				else
					alliesInRange = alliesInRange + 1
				end
			end
		end
	end

	-- Only use if multiple enemies and no allies would be destroyed
	-- (Single enemy is wasteful - can just capture normally)
	if #enemiesInRange >= 2 and alliesInRange == 0 then
		return true, enemiesInRange
	end

	return false, {}
end

--- Score a board position based on strategic value
--- Higher scores for center positions and high ground
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return number Position score (0 for destroyed tiles)
function Evaluator.scorePosition(state, row, col)
	-- Destroyed tiles have no value
	if state.destroyedTiles and state.destroyedTiles[row .. "," .. col] then
		return 0
	end

	local score = 0

	-- Center bonus: distance from center, closer = better
	-- Board is 10x8, center is around (4.5, 5.5)
	local centerRow = (Logic.BOARD_ROWS + 1) / 2 -- 4.5
	local centerCol = (Logic.BOARD_COLS + 1) / 2 -- 5.5

	local distFromCenter = math.sqrt((row - centerRow) ^ 2 + (col - centerCol) ^ 2)
	local maxDist = math.sqrt(centerRow ^ 2 + centerCol ^ 2) -- Max possible distance

	-- Normalize: 0 at edge, 1 at center
	local centerFactor = 1 - (distFromCenter / maxDist)
	score = score + centerFactor * Evaluator.WEIGHTS.CENTER_BONUS

	-- Height bonus
	local height = Height.getHeight(state.heightMap, row, col)
	score = score + height * Evaluator.WEIGHTS.HEIGHT_BONUS

	return score
end

--- Score a piece's position including its attributes
--- Includes base position score plus bonuses for powers and abilities
---@param state table Game state
---@param piece table Piece to evaluate
---@return number Piece position score
function Evaluator.scorePiecePosition(state, piece)
	-- Start with base position score
	local score = Evaluator.scorePosition(state, piece.row, piece.col)

	-- Bonus for powers in inventory
	if piece.powers then
		score = score + #piece.powers * Evaluator.WEIGHTS.POWER_BONUS
	end

	-- Bonus for activated abilities
	if piece.isJumpProof then
		score = score + Evaluator.WEIGHTS.JUMP_PROOF_BONUS
	end

	if piece.canMoveDiagonally then
		score = score + Evaluator.WEIGHTS.DIAGONAL_BONUS
	end

	return score
end

--- Get all orb collection opportunities for a player
--- Returns moves where a piece can collect an orb in one move
---@param state table Game state
---@param orbs table Array of orb objects {row, col, powerId}
---@param player number Player whose opportunities to find
---@return table Array of {piece, target, orb} objects
function Evaluator.getOrbOpportunities(state, orbs, player)
	local opportunities = {}

	if not orbs or #orbs == 0 then
		return opportunities
	end

	-- Build a map of orb positions for quick lookup
	local orbMap = {}
	for _, orb in ipairs(orbs) do
		orbMap[orb.row .. "," .. orb.col] = orb
	end

	-- For each of our pieces, check if any valid moves land on an orb
	for _, piece in ipairs(state.pieces) do
		if piece.player == player then
			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			for _, move in ipairs(moves) do
				local key = move.row .. "," .. move.col
				local orb = orbMap[key]
				if orb then
					table.insert(opportunities, {
						piece = piece,
						target = { row = move.row, col = move.col },
						orb = orb,
					})
				end
			end
		end
	end

	return opportunities
end

--- Score the value of collecting an orb based on its power
---@param orb table Orb object with powerId
---@return number Value score for the orb
function Evaluator.scoreOrbValue(orb)
	local powerId = orb.powerId
	local powerValue = Evaluator.POWER_VALUES[powerId]

	if powerValue then
		return powerValue
	end

	-- Default value for unknown powers
	return Evaluator.WEIGHTS.ORB_BASE_VALUE
end

--- Check if moving to collect an orb would put the piece at risk
---@param state table Game state
---@param player number Player considering the move
---@param target table Target position {row, col}
---@return boolean True if enemy can capture at target position next turn
function Evaluator.isOrbCollectionRisky(state, player, target)
	local opponent = player == 1 and 2 or 1

	-- Check if any enemy piece can reach the target position
	for _, enemyPiece in ipairs(state.pieces) do
		if enemyPiece.player == opponent then
			local moves = PowerEffects.getValidMovesWithPowers(state, enemyPiece)
			for _, move in ipairs(moves) do
				if move.row == target.row and move.col == target.col then
					return true
				end
			end
		end
	end

	return false
end

--- Get all valid moves for a player
---@param state table Game state
---@param player number Player to get moves for
---@return table Array of {piece, target} move objects
function Evaluator.getAllMoves(state, player)
	local moves = {}

	for _, piece in ipairs(state.pieces) do
		if piece.player == player then
			local validMoves = PowerEffects.getValidMovesWithPowers(state, piece)
			for _, target in ipairs(validMoves) do
				table.insert(moves, {
					piece = piece,
					target = { row = target.row, col = target.col },
				})
			end
		end
	end

	return moves
end

--- Score a single move considering all factors
---@param state table Game state
---@param move table Move object {piece, target}
---@param orbs table Array of orbs on the board
---@return number Score for this move (higher = better)
function Evaluator.scoreMove(state, move, orbs)
	local score = 0
	local piece = move.piece
	local target = move.target
	local player = piece.player

	-- 1. Position improvement score
	local currentPosScore = Evaluator.scorePosition(state, piece.row, piece.col)
	local newPosScore = Evaluator.scorePosition(state, target.row, target.col)
	score = score + (newPosScore - currentPosScore) * Evaluator.WEIGHTS.POSITION_WEIGHT
	-- Add base position score to ensure all moves have positive base
	score = score + newPosScore * 0.5

	-- 2. Capture bonus
	local targetPiece = nil
	for _, p in ipairs(state.pieces) do
		if p.row == target.row and p.col == target.col and p.player ~= player then
			targetPiece = p
			break
		end
	end

	if targetPiece then
		-- Base capture bonus
		score = score + Evaluator.WEIGHTS.CAPTURE_BONUS
		-- Extra value for capturing pieces with powers
		local capturedValue = Evaluator.scorePiecePosition(state, targetPiece)
		score = score + capturedValue * Evaluator.WEIGHTS.CAPTURE_VALUE_MULT
	end

	-- 3. Orb collection bonus
	local orbAtTarget = nil
	for _, orb in ipairs(orbs) do
		if orb.row == target.row and orb.col == target.col then
			orbAtTarget = orb
			break
		end
	end

	if orbAtTarget then
		local orbValue = Evaluator.scoreOrbValue(orbAtTarget)
		score = score + orbValue

		-- Penalize risky orb collection
		if Evaluator.isOrbCollectionRisky(state, player, target) then
			score = score - Evaluator.WEIGHTS.RISKY_ORB_PENALTY
		end
	end

	-- 4. Threat penalty - check if moving here puts us in danger
	-- (Only if we're not capturing, since capturing removes the threat)
	if not targetPiece then
		if Evaluator.isOrbCollectionRisky(state, player, target) then
			score = score - Evaluator.WEIGHTS.THREAT_PENALTY
		end
	end

	return score
end

--- Get the best move for a player using heuristic evaluation
---@param state table Game state
---@param orbs table Array of orbs on the board
---@param player number Player to find best move for
---@return table|nil Best move {piece, target} or nil if no moves
function Evaluator.getBestMove(state, orbs, player)
	local moves = Evaluator.getAllMoves(state, player)

	if #moves == 0 then
		return nil
	end

	local bestMove = nil
	local bestScore = -math.huge

	for _, move in ipairs(moves) do
		local score = Evaluator.scoreMove(state, move, orbs)
		if score > bestScore then
			bestScore = score
			bestMove = move
		end
	end

	return bestMove
end

--- Evaluate the entire board position for a player (for minimax search)
--- Returns a score from the perspective of the given player
--- Positive = good for player, Negative = bad for player
---@param state table Game state
---@param player number Player to evaluate for
---@return number Score (positive = good for player)
function Evaluator.evaluate(state, player)
	if not state.pieces or #state.pieces == 0 then
		return 0
	end

	local opponent = player == 1 and 2 or 1
	local myScore = 0
	local opponentScore = 0

	-- Count pieces and sum their values
	local myPieceCount = 0
	local opponentPieceCount = 0

	for _, piece in ipairs(state.pieces) do
		local pieceScore = Evaluator.WEIGHTS.PIECE_VALUE
		-- Add position score
		pieceScore = pieceScore + Evaluator.scorePiecePosition(state, piece)

		if piece.player == player then
			myScore = myScore + pieceScore
			myPieceCount = myPieceCount + 1
		else
			opponentScore = opponentScore + pieceScore
			opponentPieceCount = opponentPieceCount + 1
		end
	end

	-- Check for winning/losing positions
	if opponentPieceCount == 0 and myPieceCount > 0 then
		return Evaluator.WEIGHTS.WIN_BONUS + myScore
	elseif myPieceCount == 0 and opponentPieceCount > 0 then
		return -Evaluator.WEIGHTS.WIN_BONUS - opponentScore
	end

	-- Return relative score
	return myScore - opponentScore
end

return Evaluator
