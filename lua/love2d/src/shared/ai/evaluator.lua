-- AI Evaluator Module
-- Phase 8B: Rule-Based AI - Board evaluation and heuristics

local PowerEffects = require("src.shared.power_effects")
local Powers = require("src.shared.powers")

local Evaluator = {}

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

return Evaluator
