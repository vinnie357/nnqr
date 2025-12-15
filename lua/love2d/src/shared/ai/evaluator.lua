-- AI Evaluator Module
-- Phase 8B: Rule-Based AI - Board evaluation and heuristics

local PowerEffects = require("src.shared.power_effects")

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

return Evaluator
