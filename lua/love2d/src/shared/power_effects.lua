-- Power Effects Module
-- Implements actual effects for each power type

local Powers = require("src.shared.powers")
local Height = require("src.shared.height")
local Logic = require("src.logic")

local PowerEffects = {}

-- Helper to remove a power from a piece
local function removePower(piece, powerId)
	Powers.removePower(piece, powerId)
end

-- Helper to get pieces at specific positions
local function getPiecesInArea(state, positions, excludePiece)
	local pieces = {}
	for _, pos in ipairs(positions) do
		for _, piece in ipairs(state.pieces) do
			if piece.row == pos.row and piece.col == pos.col then
				if piece ~= excludePiece then
					table.insert(pieces, piece)
				end
			end
		end
	end
	return pieces
end

-- Helper to get empty tiles
local function getEmptyTiles(state)
	local occupied = {}
	for _, piece in ipairs(state.pieces) do
		occupied[piece.row .. "," .. piece.col] = true
	end

	local empty = {}
	for row = 1, state.rows do
		for col = 1, state.cols do
			if not occupied[row .. "," .. col] then
				table.insert(empty, { row = row, col = col })
			end
		end
	end
	return empty
end

--- Get valid moves considering powers (especially move_diagonal)
--- Uses piece flags (canMoveDiagonally, isJumpProof) set by activation
---@param state table Game state
---@param piece table Piece to get moves for
---@return table Array of valid moves
function PowerEffects.getValidMovesWithPowers(state, piece)
	local moves = {}
	local pieceHeight = Height.getHeight(state.heightMap, piece.row, piece.col)

	-- Check for diagonal movement - uses FLAG not power inventory
	local canDiagonal = piece.canMoveDiagonally == true

	-- Orthogonal directions
	local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

	-- Add diagonal directions if piece has activated move_diagonal
	if canDiagonal then
		table.insert(directions, { -1, -1 })
		table.insert(directions, { -1, 1 })
		table.insert(directions, { 1, -1 })
		table.insert(directions, { 1, 1 })
	end

	for _, dir in ipairs(directions) do
		local newRow = piece.row + dir[1]
		local newCol = piece.col + dir[2]

		if Logic.isValidPosition(newRow, newCol) then
			local targetHeight = Height.getHeight(state.heightMap, newRow, newCol)

			-- Check height restriction
			if Height.canMove(pieceHeight, targetHeight) then
				-- Check for pieces
				local targetPiece = nil
				for _, p in ipairs(state.pieces) do
					if p.row == newRow and p.col == newCol then
						targetPiece = p
						break
					end
				end

				-- Can't capture own piece
				if not targetPiece or targetPiece.player ~= piece.player then
					-- Check jump_proof for capture - uses FLAG not power inventory
					if not targetPiece or PowerEffects.canCapture(state, piece, targetPiece) then
						table.insert(moves, { row = newRow, col = newCol })
					end
				end
			end
		end
	end

	return moves
end

--- Check if attacker can capture defender (considering jump_proof)
--- Uses isJumpProof FLAG not power inventory
---@param state table Game state
---@param attacker table Attacking piece
---@param defender table Defending piece
---@return boolean True if capture is allowed
function PowerEffects.canCapture(state, attacker, defender)
	if defender.isJumpProof == true then
		return false
	end
	return true
end

--- Check if a piece can be destroyed by a power (bypasses jump_proof)
---@param defender table Defending piece
---@param powerId string Power being used
---@return boolean True if destruction is allowed
function PowerEffects.canDestroyWithPower(defender, powerId)
	-- Powers like destroy_row bypass jump_proof
	return true
end

--- Get targets for destroy_row power
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of pieces in the row
function PowerEffects.getDestroyRowTargets(state, piece)
	local targets = {}
	for _, p in ipairs(state.pieces) do
		if p.row == piece.row and p ~= piece then
			table.insert(targets, p)
		end
	end
	return targets
end

--- Activate destroy_row power
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDestroyRow(state, piece)
	local targets = PowerEffects.getDestroyRowTargets(state, piece)

	-- Remove targets
	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	-- Remove power
	removePower(piece, "destroy_row")

	return state
end

--- Get targets for destroy_column power
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of pieces in the column
function PowerEffects.getDestroyColumnTargets(state, piece)
	local targets = {}
	for _, p in ipairs(state.pieces) do
		if p.col == piece.col and p ~= piece then
			table.insert(targets, p)
		end
	end
	return targets
end

--- Activate destroy_column power
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDestroyColumn(state, piece)
	local targets = PowerEffects.getDestroyColumnTargets(state, piece)

	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	removePower(piece, "destroy_column")

	return state
end

--- Get targets for raise_tile power (adjacent tiles)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of valid tile positions
function PowerEffects.getRaiseTileTargets(state, piece)
	local targets = {}
	local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

	for _, dir in ipairs(directions) do
		local row = piece.row + dir[1]
		local col = piece.col + dir[2]
		if Logic.isValidPosition(row, col) then
			table.insert(targets, { row = row, col = col })
		end
	end

	return targets
end

--- Activate raise_tile power
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target tile {row, col}
---@return table Updated game state
function PowerEffects.activateRaiseTile(state, piece, target)
	local currentHeight = Height.getHeight(state.heightMap, target.row, target.col)
	Height.setHeight(state.heightMap, target.row, target.col, currentHeight + 1)

	removePower(piece, "raise_tile")

	return state
end

--- Activate lower_tile power
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target tile {row, col}
---@return table Updated game state
function PowerEffects.activateLowerTile(state, piece, target)
	local currentHeight = Height.getHeight(state.heightMap, target.row, target.col)
	Height.setHeight(state.heightMap, target.row, target.col, currentHeight - 1)

	removePower(piece, "lower_tile")

	return state
end

--- Get targets for recruit power (adjacent enemy pieces)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of enemy pieces
function PowerEffects.getRecruitTargets(state, piece)
	local targets = {}
	local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

	for _, dir in ipairs(directions) do
		local row = piece.row + dir[1]
		local col = piece.col + dir[2]
		if Logic.isValidPosition(row, col) then
			for _, p in ipairs(state.pieces) do
				if p.row == row and p.col == col and p.player ~= piece.player then
					table.insert(targets, p)
				end
			end
		end
	end

	return targets
end

--- Activate recruit power
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target enemy piece
---@return table Updated game state
function PowerEffects.activateRecruit(state, piece, target)
	target.player = piece.player

	removePower(piece, "recruit")

	return state
end

--- Get targets for multiply power (adjacent empty tiles)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of empty tile positions
function PowerEffects.getMultiplyTargets(state, piece)
	local targets = {}
	local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

	-- Build occupied map
	local occupied = {}
	for _, p in ipairs(state.pieces) do
		occupied[p.row .. "," .. p.col] = true
	end

	for _, dir in ipairs(directions) do
		local row = piece.row + dir[1]
		local col = piece.col + dir[2]
		if Logic.isValidPosition(row, col) then
			if not occupied[row .. "," .. col] then
				table.insert(targets, { row = row, col = col })
			end
		end
	end

	return targets
end

--- Activate multiply power
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target position {row, col}
---@return table Updated game state
function PowerEffects.activateMultiply(state, piece, target)
	local newPiece = {
		player = piece.player,
		row = target.row,
		col = target.col,
		powers = {},
	}
	table.insert(state.pieces, newPiece)

	removePower(piece, "multiply")

	return state
end

--- Get targets for bomb power (pieces in 3x3 area)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of pieces in area
function PowerEffects.getBombTargets(state, piece)
	local targets = {}

	for _, p in ipairs(state.pieces) do
		if p ~= piece then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				table.insert(targets, p)
			end
		end
	end

	return targets
end

--- Activate bomb power
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateBomb(state, piece)
	-- Get and remove targets
	local targets = PowerEffects.getBombTargets(state, piece)
	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	-- Lower terrain in 3x3 area
	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			if Logic.isValidPosition(row, col) then
				local h = Height.getHeight(state.heightMap, row, col)
				Height.setHeight(state.heightMap, row, col, h - 1)
			end
		end
	end

	removePower(piece, "bomb")

	return state
end

--- Activate relocate power
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateRelocate(state, piece)
	local empty = getEmptyTiles(state)

	if #empty > 0 then
		local target = empty[math.random(#empty)]
		piece.row = target.row
		piece.col = target.col
	end

	removePower(piece, "relocate")

	return state
end

--- Activate move_again power
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateMoveAgain(state, piece)
	state.extraMove = true

	removePower(piece, "move_again")

	return state
end

--- Activate move_diagonal power (permanent effect)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateMoveDiagonal(state, piece)
	piece.canMoveDiagonally = true

	removePower(piece, "move_diagonal")

	return state
end

--- Activate jump_proof power (permanent effect)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateJumpProof(state, piece)
	piece.isJumpProof = true

	removePower(piece, "jump_proof")

	return state
end

--- Activate invisible power (permanent until capture)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInvisible(state, piece)
	piece.isInvisible = true

	removePower(piece, "invisible")

	return state
end

--- Reveal an invisible piece (called when piece captures)
---@param piece table Piece to reveal
function PowerEffects.revealInvisible(piece)
	piece.isInvisible = false
end

return PowerEffects
