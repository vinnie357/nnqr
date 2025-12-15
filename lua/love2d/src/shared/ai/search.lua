-- AI Search Module
-- Phase 8C: Search-Based AI - Minimax with alpha-beta pruning

local Evaluator = require("src.shared.ai.evaluator")

local Search = {}

--- Deep copy a game state for simulation
---@param state table Original state
---@return table Copied state
local function copyState(state)
	local copy = {
		cols = state.cols,
		rows = state.rows,
		currentPlayer = state.currentPlayer,
		turn = state.turn,
		gameState = state.gameState,
		winner = state.winner,
		pieces = {},
		heightMap = {},
		destroyedTiles = {},
	}

	-- Copy pieces
	for _, piece in ipairs(state.pieces) do
		local pieceCopy = {
			row = piece.row,
			col = piece.col,
			player = piece.player,
			powers = {},
			isJumpProof = piece.isJumpProof,
			canMoveDiagonally = piece.canMoveDiagonally,
			isInvisible = piece.isInvisible,
		}
		-- Copy powers
		if piece.powers then
			for _, power in ipairs(piece.powers) do
				table.insert(pieceCopy.powers, power)
			end
		end
		table.insert(copy.pieces, pieceCopy)
	end

	-- Copy height map
	for row = 1, state.rows do
		copy.heightMap[row] = {}
		for col = 1, state.cols do
			copy.heightMap[row][col] = state.heightMap[row][col] or 0
		end
	end

	-- Copy destroyed tiles
	if state.destroyedTiles then
		for key, value in pairs(state.destroyedTiles) do
			copy.destroyedTiles[key] = value
		end
	end

	return copy
end

--- Apply a move to a state (modifies state in place)
---@param state table Game state
---@param move table Move {piece, target}
local function applyMove(state, move)
	local piece = move.piece
	local target = move.target

	-- Find and remove captured piece
	for i = #state.pieces, 1, -1 do
		local p = state.pieces[i]
		if p.row == target.row and p.col == target.col and p ~= piece then
			table.remove(state.pieces, i)
			break
		end
	end

	-- Move the piece
	piece.row = target.row
	piece.col = target.col
end

--- Order moves for better alpha-beta pruning
--- Captures first, then other moves
---@param state table Game state
---@param moves table Array of moves
---@return table Ordered moves
function Search.orderMoves(state, moves)
	local captures = {}
	local others = {}

	for _, move in ipairs(moves) do
		local isCapture = false
		for _, piece in ipairs(state.pieces) do
			if piece.row == move.target.row and piece.col == move.target.col and piece.player ~= move.piece.player then
				isCapture = true
				break
			end
		end

		if isCapture then
			table.insert(captures, move)
		else
			table.insert(others, move)
		end
	end

	-- Captures first
	local ordered = {}
	for _, m in ipairs(captures) do
		table.insert(ordered, m)
	end
	for _, m in ipairs(others) do
		table.insert(ordered, m)
	end

	return ordered
end

--- Minimax search without alpha-beta pruning
---@param state table Game state
---@param depth number Search depth
---@param player number Player to find move for
---@return table|nil Best move, number Score
function Search.minimax(state, depth, player)
	-- Terminal: evaluate position
	if depth == 0 then
		return nil, Evaluator.evaluate(state, player)
	end

	local moves = Evaluator.getAllMoves(state, player)

	if #moves == 0 then
		-- No moves available
		return nil, Evaluator.evaluate(state, player)
	end

	local orderedMoves = Search.orderMoves(state, moves)
	local bestMove = nil
	local bestScore = -math.huge
	local opponent = player == 1 and 2 or 1

	for _, move in ipairs(orderedMoves) do
		-- Create state copy and apply move
		local stateCopy = copyState(state)

		-- Find the piece in the copied state
		local pieceCopy = nil
		for _, p in ipairs(stateCopy.pieces) do
			if p.row == move.piece.row and p.col == move.piece.col and p.player == move.piece.player then
				pieceCopy = p
				break
			end
		end

		if pieceCopy then
			applyMove(stateCopy, { piece = pieceCopy, target = move.target })

			-- Recursive search (opponent's turn)
			local _, score = Search.minimax(stateCopy, depth - 1, opponent)

			-- Negate score (opponent's good = our bad)
			score = -score

			if score > bestScore then
				bestScore = score
				bestMove = move
			end
		end
	end

	return bestMove, bestScore
end

--- Minimax search with alpha-beta pruning
---@param state table Game state
---@param depth number Search depth
---@param player number Player to find move for
---@param alpha number Alpha bound
---@param beta number Beta bound
---@return table|nil Best move, number Score
function Search.minimaxAlphaBeta(state, depth, player, alpha, beta)
	-- Terminal: evaluate position
	if depth == 0 then
		return nil, Evaluator.evaluate(state, player)
	end

	local moves = Evaluator.getAllMoves(state, player)

	if #moves == 0 then
		return nil, Evaluator.evaluate(state, player)
	end

	local orderedMoves = Search.orderMoves(state, moves)
	local bestMove = nil
	local bestScore = -math.huge
	local opponent = player == 1 and 2 or 1

	for _, move in ipairs(orderedMoves) do
		local stateCopy = copyState(state)

		local pieceCopy = nil
		for _, p in ipairs(stateCopy.pieces) do
			if p.row == move.piece.row and p.col == move.piece.col and p.player == move.piece.player then
				pieceCopy = p
				break
			end
		end

		if pieceCopy then
			applyMove(stateCopy, { piece = pieceCopy, target = move.target })

			local _, score = Search.minimaxAlphaBeta(stateCopy, depth - 1, opponent, -beta, -alpha)
			score = -score

			if score > bestScore then
				bestScore = score
				bestMove = move
			end

			alpha = math.max(alpha, score)
			if alpha >= beta then
				break -- Beta cutoff
			end
		end
	end

	return bestMove, bestScore
end

--- Find the best move for a player using minimax with alpha-beta pruning
---@param state table Game state
---@param depth number Search depth
---@param player number Player to find move for
---@return table|nil Best move {piece, target}
function Search.findBestMove(state, depth, player)
	local move, _ = Search.minimaxAlphaBeta(state, depth, player, -math.huge, math.huge)
	return move
end

return Search
