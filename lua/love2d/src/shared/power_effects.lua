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
--- Uses piece flags (canMoveDiagonally, isJumpProof, canClimbAny) set by activation
---@param state table Game state
---@param piece table Piece to get moves for
---@return table Array of valid moves
function PowerEffects.getValidMovesWithPowers(state, piece)
	local moves = {}
	local pieceHeight = Height.getHeight(state.heightMap, piece.row, piece.col)

	-- Check for diagonal movement - uses FLAG not power inventory
	local canDiagonal = piece.canMoveDiagonally == true
	-- Check for climb any height - uses FLAG not power inventory
	local canClimbAny = piece.canClimbAny == true

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
			-- Check if tile is destroyed (cannot move to destroyed tiles)
			local isDestroyed = state.destroyedTiles and state.destroyedTiles[newRow .. "," .. newCol] == true
			if not isDestroyed then
				local targetHeight = Height.getHeight(state.heightMap, newRow, newCol)

				-- Check height restriction (unless canClimbAny is set)
				local canMoveToHeight = canClimbAny or Height.canMove(pieceHeight, targetHeight)
				if canMoveToHeight then
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

	-- Lower terrain in 3x3 area and destroy tiles at min height
	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			if Logic.isValidPosition(row, col) then
				local h = Height.getHeight(state.heightMap, row, col)
				local newHeight = h - 1
				Height.setHeight(state.heightMap, row, col, newHeight)

				-- Destroy tile if it reaches minimum height (0 or below)
				if newHeight <= 0 then
					-- Initialize destroyedTiles if not present
					if not state.destroyedTiles then
						state.destroyedTiles = {}
					end
					local key = row .. "," .. col
					state.destroyedTiles[key] = true
				end
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

--- Get targets for refurb power (adjacent destroyed tiles)
---@param state table Game state
---@param piece table Piece with refurb power
---@return table Array of {row, col} positions of adjacent destroyed tiles
function PowerEffects.getRefurbTargets(state, piece)
	local targets = {}

	-- Check all adjacent tiles (including diagonals)
	local directions = {
		{ -1, 0 },
		{ 1, 0 },
		{ 0, -1 },
		{ 0, 1 },
		{ -1, -1 },
		{ -1, 1 },
		{ 1, -1 },
		{ 1, 1 },
	}

	for _, dir in ipairs(directions) do
		local row = piece.row + dir[1]
		local col = piece.col + dir[2]

		if Logic.isValidPosition(row, col) then
			-- Check if tile is destroyed
			if state.destroyedTiles and state.destroyedTiles[row .. "," .. col] then
				table.insert(targets, { row = row, col = col })
			end
		end
	end

	return targets
end

--- Activate refurb power to repair a destroyed tile
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target position {row, col} to repair
---@return table Updated game state
function PowerEffects.activateRefurb(state, piece, target)
	if not target then
		return state
	end

	local key = target.row .. "," .. target.col

	-- Remove tile from destroyed list
	if state.destroyedTiles then
		state.destroyedTiles[key] = nil
	end

	-- Reset tile height to 0
	Height.setHeight(state.heightMap, target.row, target.col, 0)

	removePower(piece, "refurb")

	return state
end

-- Phase 9A.1: Destroy Variants

--- Get targets for destroy_radial power (pieces in 3x3 area, excluding activator)
--- Unlike bomb, this only affects pieces, not terrain
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of pieces in 3x3 area
function PowerEffects.getDestroyRadialTargets(state, piece)
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

--- Activate destroy_radial power (destroys pieces in 3x3 area, no terrain damage)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDestroyRadial(state, piece)
	local targets = PowerEffects.getDestroyRadialTargets(state, piece)

	-- Remove targets
	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	removePower(piece, "destroy_radial")

	return state
end

--- Activate kamikaze_radial power (destroys pieces in 3x3 INCLUDING self)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateKamikazeRadial(state, piece)
	-- Get all pieces in 3x3 area INCLUDING activator
	local targets = {}

	for _, p in ipairs(state.pieces) do
		local dr = math.abs(p.row - piece.row)
		local dc = math.abs(p.col - piece.col)
		if dr <= 1 and dc <= 1 then
			table.insert(targets, p)
		end
	end

	-- Remove all targets (including self)
	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	return state
end

--- Activate kamikaze_row power (destroys all pieces in row INCLUDING self)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateKamikazeRow(state, piece)
	local targetRow = piece.row

	-- Remove all pieces in the row (including self)
	for i = #state.pieces, 1, -1 do
		if state.pieces[i].row == targetRow then
			table.remove(state.pieces, i)
		end
	end

	return state
end

--- Activate kamikaze_column power (destroys all pieces in column INCLUDING self)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateKamikazeColumn(state, piece)
	local targetCol = piece.col

	-- Remove all pieces in the column (including self)
	for i = #state.pieces, 1, -1 do
		if state.pieces[i].col == targetCol then
			table.remove(state.pieces, i)
		end
	end

	return state
end

-- Phase 9A.3: Extended Recruitment

--- Get targets for recruit_row power (enemy pieces in same row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of enemy pieces in row
function PowerEffects.getRecruitRowTargets(state, piece)
	local targets = {}

	for _, p in ipairs(state.pieces) do
		if p.row == piece.row and p.player ~= piece.player then
			table.insert(targets, p)
		end
	end

	return targets
end

--- Activate recruit_row power (convert all enemies in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateRecruitRow(state, piece)
	local targets = PowerEffects.getRecruitRowTargets(state, piece)

	for _, target in ipairs(targets) do
		target.player = piece.player
	end

	removePower(piece, "recruit_row")

	return state
end

--- Get targets for recruit_column power (enemy pieces in same column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of enemy pieces in column
function PowerEffects.getRecruitColumnTargets(state, piece)
	local targets = {}

	for _, p in ipairs(state.pieces) do
		if p.col == piece.col and p.player ~= piece.player then
			table.insert(targets, p)
		end
	end

	return targets
end

--- Activate recruit_column power (convert all enemies in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateRecruitColumn(state, piece)
	local targets = PowerEffects.getRecruitColumnTargets(state, piece)

	for _, target in ipairs(targets) do
		target.player = piece.player
	end

	removePower(piece, "recruit_column")

	return state
end

-- Phase 9A.4: Scramble Powers

--- Activate scramble_radial power (shuffle positions of pieces in 3x3 area)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateScrambleRadial(state, piece)
	-- Find all pieces in 3x3 area
	local piecesInArea = {}
	local positions = {}

	for _, p in ipairs(state.pieces) do
		local dr = math.abs(p.row - piece.row)
		local dc = math.abs(p.col - piece.col)
		if dr <= 1 and dc <= 1 then
			table.insert(piecesInArea, p)
			table.insert(positions, { row = p.row, col = p.col })
		end
	end

	-- Shuffle positions
	for i = #positions, 2, -1 do
		local j = math.random(i)
		positions[i], positions[j] = positions[j], positions[i]
	end

	-- Assign shuffled positions to pieces
	for i, p in ipairs(piecesInArea) do
		p.row = positions[i].row
		p.col = positions[i].col
	end

	removePower(piece, "scramble_radial")

	return state
end

-- Phase 9A.5: Smart Bombs

--- Get targets for smart_bombs power (enemy pieces in 3x3 area only)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of enemy pieces in area
function PowerEffects.getSmartBombsTargets(state, piece)
	local targets = {}

	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				table.insert(targets, p)
			end
		end
	end

	return targets
end

--- Activate smart_bombs power (destroy enemies in 3x3, spare allies)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateSmartBombs(state, piece)
	local targets = PowerEffects.getSmartBombsTargets(state, piece)

	-- Remove only enemy targets
	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	removePower(piece, "smart_bombs")

	return state
end

-- Phase 9A.2: Acidic Powers

--- Activate acidic_radial power (destroy pieces AND tiles in 3x3 area)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateAcidicRadial(state, piece)
	-- First destroy pieces (excluding activator)
	local targets = PowerEffects.getDestroyRadialTargets(state, piece)
	for _, target in ipairs(targets) do
		for i = #state.pieces, 1, -1 do
			if state.pieces[i] == target then
				table.remove(state.pieces, i)
				break
			end
		end
	end

	-- Initialize destroyedTiles if needed
	if not state.destroyedTiles then
		state.destroyedTiles = {}
	end

	-- Destroy tiles in 3x3 area (except under activator)
	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			-- Skip activator's tile
			if not (dr == 0 and dc == 0) then
				if Logic.isValidPosition(row, col) then
					state.destroyedTiles[row .. "," .. col] = true
				end
			end
		end
	end

	removePower(piece, "acidic_radial")

	return state
end

--- Activate acidic_row power (destroy pieces AND tiles in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateAcidicRow(state, piece)
	local targetRow = piece.row

	-- Destroy pieces in row (except activator)
	for i = #state.pieces, 1, -1 do
		local p = state.pieces[i]
		if p.row == targetRow and p ~= piece then
			table.remove(state.pieces, i)
		end
	end

	-- Initialize destroyedTiles if needed
	if not state.destroyedTiles then
		state.destroyedTiles = {}
	end

	-- Destroy tiles in row (except under activator)
	for col = 1, state.cols do
		if col ~= piece.col then
			state.destroyedTiles[targetRow .. "," .. col] = true
		end
	end

	removePower(piece, "acidic_row")

	return state
end

--- Activate acidic_column power (destroy pieces AND tiles in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateAcidicColumn(state, piece)
	local targetCol = piece.col

	-- Destroy pieces in column (except activator)
	for i = #state.pieces, 1, -1 do
		local p = state.pieces[i]
		if p.col == targetCol and p ~= piece then
			table.remove(state.pieces, i)
		end
	end

	-- Initialize destroyedTiles if needed
	if not state.destroyedTiles then
		state.destroyedTiles = {}
	end

	-- Destroy tiles in column (except under activator)
	for row = 1, state.rows do
		if row ~= piece.row then
			state.destroyedTiles[row .. "," .. targetCol] = true
		end
	end

	removePower(piece, "acidic_column")

	return state
end

-- Phase 9A.4: Scramble Row/Column

--- Activate scramble_row power (shuffle positions of pieces in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateScrambleRow(state, piece)
	local targetRow = piece.row

	-- Find all pieces in row
	local piecesInRow = {}
	local cols = {}

	for _, p in ipairs(state.pieces) do
		if p.row == targetRow then
			table.insert(piecesInRow, p)
			table.insert(cols, p.col)
		end
	end

	-- Shuffle columns
	for i = #cols, 2, -1 do
		local j = math.random(i)
		cols[i], cols[j] = cols[j], cols[i]
	end

	-- Assign shuffled columns to pieces
	for i, p in ipairs(piecesInRow) do
		p.col = cols[i]
	end

	removePower(piece, "scramble_row")

	return state
end

--- Activate scramble_column power (shuffle positions of pieces in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateScrambleColumn(state, piece)
	local targetCol = piece.col

	-- Find all pieces in column
	local piecesInCol = {}
	local rows = {}

	for _, p in ipairs(state.pieces) do
		if p.col == targetCol then
			table.insert(piecesInCol, p)
			table.insert(rows, p.row)
		end
	end

	-- Shuffle rows
	for i = #rows, 2, -1 do
		local j = math.random(i)
		rows[i], rows[j] = rows[j], rows[i]
	end

	-- Assign shuffled rows to pieces
	for i, p in ipairs(piecesInCol) do
		p.row = rows[i]
	end

	removePower(piece, "scramble_column")

	return state
end

-- Phase 9B: Terrain Powers

-- 9B.1 Area Effects

--- Activate plateau power (raise 3x3 area to max height)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePlateau(state, piece)
	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			if Logic.isValidPosition(row, col) then
				Height.setHeight(state.heightMap, row, col, Height.MAX_HEIGHT)
			end
		end
	end

	removePower(piece, "plateau")

	return state
end

--- Activate moat power (raise center to max, lower surrounding ring)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateMoat(state, piece)
	-- Raise center to max
	Height.setHeight(state.heightMap, piece.row, piece.col, Height.MAX_HEIGHT)

	-- Lower surrounding ring by 1
	for dr = -1, 1 do
		for dc = -1, 1 do
			if not (dr == 0 and dc == 0) then
				local row = piece.row + dr
				local col = piece.col + dc
				if Logic.isValidPosition(row, col) then
					local currentHeight = Height.getHeight(state.heightMap, row, col)
					Height.setHeight(state.heightMap, row, col, currentHeight - 1)
				end
			end
		end
	end

	removePower(piece, "moat")

	return state
end

--- Activate climb_tile power (piece ignores height restrictions)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateClimbTile(state, piece)
	piece.canClimbAny = true

	removePower(piece, "climb_tile")

	return state
end

-- 9B.2 Line Effects

--- Activate trench_row power (lower entire row by 2)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTrenchRow(state, piece)
	local targetRow = piece.row

	for col = 1, state.cols do
		local currentHeight = Height.getHeight(state.heightMap, targetRow, col)
		Height.setHeight(state.heightMap, targetRow, col, currentHeight - 2)
	end

	removePower(piece, "trench_row")

	return state
end

--- Activate trench_column power (lower entire column by 2)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTrenchColumn(state, piece)
	local targetCol = piece.col

	for row = 1, state.rows do
		local currentHeight = Height.getHeight(state.heightMap, row, targetCol)
		Height.setHeight(state.heightMap, row, targetCol, currentHeight - 2)
	end

	removePower(piece, "trench_column")

	return state
end

--- Activate wall_row power (raise entire row by 2)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateWallRow(state, piece)
	local targetRow = piece.row

	for col = 1, state.cols do
		local currentHeight = Height.getHeight(state.heightMap, targetRow, col)
		Height.setHeight(state.heightMap, targetRow, col, currentHeight + 2)
	end

	removePower(piece, "wall_row")

	return state
end

--- Activate wall_column power (raise entire column by 2)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateWallColumn(state, piece)
	local targetCol = piece.col

	for row = 1, state.rows do
		local currentHeight = Height.getHeight(state.heightMap, row, targetCol)
		Height.setHeight(state.heightMap, row, targetCol, currentHeight + 2)
	end

	removePower(piece, "wall_column")

	return state
end

-- 9B.3 Invert Powers

--- Invert a height value (4 becomes 0, 0 becomes 4, etc.)
---@param height number Current height (0-4)
---@return number Inverted height
local function invertHeight(height)
	return Height.MAX_HEIGHT - height
end

--- Activate invert_radial power (flip heights in 3x3)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInvertRadial(state, piece)
	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			if Logic.isValidPosition(row, col) then
				local currentHeight = Height.getHeight(state.heightMap, row, col)
				Height.setHeight(state.heightMap, row, col, invertHeight(currentHeight))
			end
		end
	end

	removePower(piece, "invert_radial")

	return state
end

--- Activate invert_row power (flip heights in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInvertRow(state, piece)
	local targetRow = piece.row

	for col = 1, state.cols do
		local currentHeight = Height.getHeight(state.heightMap, targetRow, col)
		Height.setHeight(state.heightMap, targetRow, col, invertHeight(currentHeight))
	end

	removePower(piece, "invert_row")

	return state
end

--- Activate invert_column power (flip heights in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInvertColumn(state, piece)
	local targetCol = piece.col

	for row = 1, state.rows do
		local currentHeight = Height.getHeight(state.heightMap, row, targetCol)
		Height.setHeight(state.heightMap, row, targetCol, invertHeight(currentHeight))
	end

	removePower(piece, "invert_column")

	return state
end

-- 9B.4 Dredge Powers

--- Helper to get piece at position
---@param state table Game state
---@param row number Row
---@param col number Column
---@return table|nil Piece at position or nil
local function getPieceAtPosition(state, row, col)
	for _, p in ipairs(state.pieces) do
		if p.row == row and p.col == col then
			return p
		end
	end
	return nil
end

--- Activate dredge_radial power (raise friendly tiles, lower enemy tiles in 3x3)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDredgeRadial(state, piece)
	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			if Logic.isValidPosition(row, col) then
				local pieceOnTile = getPieceAtPosition(state, row, col)
				if pieceOnTile then
					local currentHeight = Height.getHeight(state.heightMap, row, col)
					if pieceOnTile.player == piece.player then
						-- Friendly: raise
						Height.setHeight(state.heightMap, row, col, currentHeight + 1)
					else
						-- Enemy: lower
						Height.setHeight(state.heightMap, row, col, currentHeight - 1)
					end
				end
			end
		end
	end

	removePower(piece, "dredge_radial")

	return state
end

--- Activate dredge_row power (raise friendly tiles, lower enemy tiles in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDredgeRow(state, piece)
	local targetRow = piece.row

	for col = 1, state.cols do
		local pieceOnTile = getPieceAtPosition(state, targetRow, col)
		if pieceOnTile then
			local currentHeight = Height.getHeight(state.heightMap, targetRow, col)
			if pieceOnTile.player == piece.player then
				Height.setHeight(state.heightMap, targetRow, col, currentHeight + 1)
			else
				Height.setHeight(state.heightMap, targetRow, col, currentHeight - 1)
			end
		end
	end

	removePower(piece, "dredge_row")

	return state
end

--- Activate dredge_column power (raise friendly tiles, lower enemy tiles in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDredgeColumn(state, piece)
	local targetCol = piece.col

	for row = 1, state.rows do
		local pieceOnTile = getPieceAtPosition(state, row, targetCol)
		if pieceOnTile then
			local currentHeight = Height.getHeight(state.heightMap, row, targetCol)
			if pieceOnTile.player == piece.player then
				Height.setHeight(state.heightMap, row, targetCol, currentHeight + 1)
			else
				Height.setHeight(state.heightMap, row, targetCol, currentHeight - 1)
			end
		end
	end

	removePower(piece, "dredge_column")

	return state
end

return PowerEffects
