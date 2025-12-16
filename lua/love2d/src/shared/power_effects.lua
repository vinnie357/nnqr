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

--- Helper to wrap a position around the board edges
---@param row number Row position
---@param col number Column position
---@param rows number Board rows
---@param cols number Board columns
---@return number Wrapped row, number Wrapped column
local function wrapPosition(row, col, rows, cols)
	local wrappedRow = row
	local wrappedCol = col

	if row < 1 then
		wrappedRow = rows
	elseif row > rows then
		wrappedRow = 1
	end

	if col < 1 then
		wrappedCol = cols
	elseif col > cols then
		wrappedCol = 1
	end

	return wrappedRow, wrappedCol
end

--- Get valid moves considering powers (especially move_diagonal)
--- Uses piece flags (canMoveDiagonally, isJumpProof, canClimbAny, canWrap) set by activation
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
	-- Check for wraparound movement - uses FLAG not power inventory
	local canWrap = piece.canWrap == true

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

		-- Handle wraparound if canWrap is true
		if canWrap then
			newRow, newCol = wrapPosition(newRow, newCol, state.rows, state.cols)
		end

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
		isMultiplied = true, -- Track for cancel_multiply
	}
	table.insert(state.pieces, newPiece)

	-- Track multiplied pieces for cancel_multiply
	if not state.multipliedPieces then
		state.multipliedPieces = {}
	end
	table.insert(state.multipliedPieces, newPiece)

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

-- Phase 9C: Power Transfer Powers

-- 9C.1 Teach (Share to allies)

--- Helper to copy powers to a target piece (excluding the power being used)
---@param source table Source piece
---@param target table Target piece
---@param excludePower string Power to exclude (the teach power being consumed)
local function copyPowersTo(source, target, excludePower)
	if not source.powers then
		return
	end
	if not target.powers then
		target.powers = {}
	end

	for _, power in ipairs(source.powers) do
		if power ~= excludePower then
			table.insert(target.powers, power)
		end
	end
end

--- Activate teach_radial power (copy powers to adjacent allies)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTeachRadial(state, piece)
	-- Find adjacent allies
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player == piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				copyPowersTo(piece, p, "teach_radial")
			end
		end
	end

	removePower(piece, "teach_radial")

	return state
end

--- Activate teach_row power (copy powers to allies in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTeachRow(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player == piece.player and p.row == piece.row then
			copyPowersTo(piece, p, "teach_row")
		end
	end

	removePower(piece, "teach_row")

	return state
end

--- Activate teach_column power (copy powers to allies in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTeachColumn(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player == piece.player and p.col == piece.col then
			copyPowersTo(piece, p, "teach_column")
		end
	end

	removePower(piece, "teach_column")

	return state
end

-- 9C.2 Learn (Absorb from allies)

--- Helper to absorb all powers from a source piece
---@param source table Source piece (will lose powers)
---@param target table Target piece (will gain powers)
local function absorbPowersFrom(source, target)
	if not source.powers or #source.powers == 0 then
		return
	end
	if not target.powers then
		target.powers = {}
	end

	-- Copy all powers to target
	for _, power in ipairs(source.powers) do
		table.insert(target.powers, power)
	end

	-- Clear source powers
	source.powers = {}
end

--- Activate learn_radial power (absorb powers from adjacent allies)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateLearnRadial(state, piece)
	-- Remove the learn power first
	removePower(piece, "learn_radial")

	-- Find adjacent allies and absorb their powers
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player == piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				absorbPowersFrom(p, piece)
			end
		end
	end

	return state
end

--- Activate learn_row power (absorb powers from allies in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateLearnRow(state, piece)
	removePower(piece, "learn_row")

	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player == piece.player and p.row == piece.row then
			absorbPowersFrom(p, piece)
		end
	end

	return state
end

--- Activate learn_column power (absorb powers from allies in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateLearnColumn(state, piece)
	removePower(piece, "learn_column")

	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player == piece.player and p.col == piece.col then
			absorbPowersFrom(p, piece)
		end
	end

	return state
end

-- 9C.3 Pilfer (Steal from enemies)

--- Helper to steal one random power from a source piece
---@param source table Source piece (enemy)
---@param target table Target piece (will gain power)
---@return boolean True if a power was stolen
local function stealRandomPower(source, target)
	if not source.powers or #source.powers == 0 then
		return false
	end
	if not target.powers then
		target.powers = {}
	end

	-- Pick random power
	local idx = math.random(#source.powers)
	local stolenPower = source.powers[idx]

	-- Add to target
	table.insert(target.powers, stolenPower)

	-- Remove from source
	table.remove(source.powers, idx)

	return true
end

--- Activate pilfer_radial power (steal one power from each adjacent enemy)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePilferRadial(state, piece)
	removePower(piece, "pilfer_radial")

	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				stealRandomPower(p, piece)
			end
		end
	end

	return state
end

--- Activate pilfer_row power (steal one power from each enemy in row)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePilferRow(state, piece)
	removePower(piece, "pilfer_row")

	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.row == piece.row then
			stealRandomPower(p, piece)
		end
	end

	return state
end

--- Activate pilfer_column power (steal one power from each enemy in column)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePilferColumn(state, piece)
	removePower(piece, "pilfer_column")

	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.col == piece.col then
			stealRandomPower(p, piece)
		end
	end

	return state
end

-- Phase 9D: Meta Powers

--- Activate double_powers (2x) - doubles all powers on the piece
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateDoublePowers(state, piece)
	-- Remove the 2x power first
	removePower(piece, "double_powers")

	-- Get current powers (after removing double_powers)
	if not piece.powers then
		piece.powers = {}
		return state
	end

	-- Duplicate each remaining power
	local currentPowers = {}
	for _, p in ipairs(piece.powers) do
		table.insert(currentPowers, p)
	end

	for _, p in ipairs(currentPowers) do
		table.insert(piece.powers, p)
	end

	return state
end

--- Activate orbic_rehash - respawn all orbs at new random locations
---@param state table Game state
---@param piece table Piece activating power
---@param orbs table Array of existing orbs
---@return table Updated game state, table New orbs array
function PowerEffects.activateOrbicRehash(state, piece, orbs)
	removePower(piece, "orbic_rehash")

	if not orbs or #orbs == 0 then
		return state, orbs or {}
	end

	-- Collect all power IDs from existing orbs
	local powerIds = {}
	for _, orb in ipairs(orbs) do
		table.insert(powerIds, orb.powerId)
	end

	-- Get empty tiles (excluding pieces and destroyed tiles)
	local empty = {}
	local occupied = {}
	for _, p in ipairs(state.pieces) do
		occupied[p.row .. "," .. p.col] = true
	end

	for row = 1, state.rows do
		for col = 1, state.cols do
			local key = row .. "," .. col
			local isDestroyed = state.destroyedTiles and state.destroyedTiles[key]
			if not occupied[key] and not isDestroyed then
				table.insert(empty, { row = row, col = col })
			end
		end
	end

	-- Shuffle empty tiles
	for i = #empty, 2, -1 do
		local j = math.random(i)
		empty[i], empty[j] = empty[j], empty[i]
	end

	-- Create new orbs at random positions
	local newOrbs = {}
	for i, powerId in ipairs(powerIds) do
		if i <= #empty then
			table.insert(newOrbs, {
				row = empty[i].row,
				col = empty[i].col,
				powerId = powerId,
			})
		end
	end

	return state, newOrbs
end

--- Activate cancel_multiply - destroy the most recently multiplied piece
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateCancelMultiply(state, piece)
	removePower(piece, "cancel_multiply")

	-- Remove all pieces with isMultiplied flag
	for i = #state.pieces, 1, -1 do
		if state.pieces[i].isMultiplied then
			table.remove(state.pieces, i)
		end
	end

	-- Also clear the multipliedPieces list if it exists
	if state.multipliedPieces then
		state.multipliedPieces = {}
	end

	return state
end

--- Activate grow_quadradius - extend power range by 1 (stacks up to 3)
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateGrowQuadradius(state, piece)
	removePower(piece, "grow_quadradius")

	-- Initialize level if not present
	if not piece.growQuadradiusLevel then
		piece.growQuadradiusLevel = 0
	end

	-- Increase level, cap at 3
	if piece.growQuadradiusLevel < 3 then
		piece.growQuadradiusLevel = piece.growQuadradiusLevel + 1
	end

	return state
end

--- Activate beneficiary - all allied pieces' powers transfer to this piece when they die
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateBeneficiary(state, piece)
	removePower(piece, "beneficiary")

	-- Set the beneficiary flag
	piece.isBeneficiary = true

	return state
end

-- Phase 9E: Movement & Control Powers

-- 9E.1 Special Movement

--- Get valid targets for switcheroo (all adjacent pieces)
---@param state table Game state
---@param piece table Piece activating power
---@return table Array of adjacent pieces
function PowerEffects.getSwitcherooTargets(state, piece)
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

--- Activate switcheroo - swap positions with target piece
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target piece to swap with
---@return table Updated game state
function PowerEffects.activateSwitcheroo(state, piece, target)
	-- Swap positions
	local tempRow, tempCol = piece.row, piece.col
	piece.row, piece.col = target.row, target.col
	target.row, target.col = tempRow, tempCol

	removePower(piece, "switcheroo")

	return state
end

--- Activate scavenger - piece inherits powers from captured enemies
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateScavenger(state, piece)
	piece.isScavenger = true

	removePower(piece, "scavenger")

	return state
end

--- Activate flat_to_sphere - enable wraparound movement
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateFlatToSphere(state, piece)
	piece.canWrap = true

	removePower(piece, "flat_to_sphere")

	return state
end

-- 9E.5 Intelligence Powers

--- Activate spyware_radial - reveal powers of adjacent enemy pieces
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateSpywareRadial(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				p.powersRevealed = true
			end
		end
	end

	removePower(piece, "spyware_radial")

	return state
end

--- Activate spyware_row - reveal powers of enemy pieces in row
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateSpywareRow(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.row == piece.row then
			p.powersRevealed = true
		end
	end

	removePower(piece, "spyware_row")

	return state
end

--- Activate spyware_column - reveal powers of enemy pieces in column
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateSpywareColumn(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.col == piece.col then
			p.powersRevealed = true
		end
	end

	removePower(piece, "spyware_column")

	return state
end

--- Activate orb_spy_radial - reveal contents of adjacent orbs
---@param state table Game state
---@param piece table Piece activating power
---@param orbs table Array of orbs
---@return table Updated game state, table Updated orbs
function PowerEffects.activateOrbSpyRadial(state, piece, orbs)
	for _, orb in ipairs(orbs) do
		local dr = math.abs(orb.row - piece.row)
		local dc = math.abs(orb.col - piece.col)
		if dr <= 1 and dc <= 1 then
			orb.revealed = true
		end
	end

	removePower(piece, "orb_spy_radial")

	return state, orbs
end

--- Activate orb_spy_row - reveal contents of orbs in row
---@param state table Game state
---@param piece table Piece activating power
---@param orbs table Array of orbs
---@return table Updated game state, table Updated orbs
function PowerEffects.activateOrbSpyRow(state, piece, orbs)
	for _, orb in ipairs(orbs) do
		if orb.row == piece.row then
			orb.revealed = true
		end
	end

	removePower(piece, "orb_spy_row")

	return state, orbs
end

--- Activate orb_spy_column - reveal contents of orbs in column
---@param state table Game state
---@param piece table Piece activating power
---@param orbs table Array of orbs
---@return table Updated game state, table Updated orbs
function PowerEffects.activateOrbSpyColumn(state, piece, orbs)
	for _, orb in ipairs(orbs) do
		if orb.col == piece.col then
			orb.revealed = true
		end
	end

	removePower(piece, "orb_spy_column")

	return state, orbs
end

-- 9E.6 Restoration Powers

--- Activate refurb_radial - repair destroyed tiles in 3x3 area
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateRefurbRadial(state, piece)
	if not state.destroyedTiles then
		removePower(piece, "refurb_radial")
		return state
	end

	for dr = -1, 1 do
		for dc = -1, 1 do
			local row = piece.row + dr
			local col = piece.col + dc
			if Logic.isValidPosition(row, col) then
				local key = row .. "," .. col
				if state.destroyedTiles[key] then
					state.destroyedTiles[key] = nil
					Height.setHeight(state.heightMap, row, col, 0)
				end
			end
		end
	end

	removePower(piece, "refurb_radial")

	return state
end

--- Activate refurb_row - repair destroyed tiles in row
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateRefurbRow(state, piece)
	if not state.destroyedTiles then
		removePower(piece, "refurb_row")
		return state
	end

	for col = 1, state.cols do
		local key = piece.row .. "," .. col
		if state.destroyedTiles[key] then
			state.destroyedTiles[key] = nil
			Height.setHeight(state.heightMap, piece.row, col, 0)
		end
	end

	removePower(piece, "refurb_row")

	return state
end

--- Activate refurb_column - repair destroyed tiles in column
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateRefurbColumn(state, piece)
	if not state.destroyedTiles then
		removePower(piece, "refurb_column")
		return state
	end

	for row = 1, state.rows do
		local key = row .. "," .. piece.col
		if state.destroyedTiles[key] then
			state.destroyedTiles[key] = nil
			Height.setHeight(state.heightMap, row, piece.col, 0)
		end
	end

	removePower(piece, "refurb_column")

	return state
end

-- Phase 9 Remaining Powers

-- 9E.4 Bankrupt Powers (power-draining trap tiles)

--- Activate bankrupt_radial - create power-draining traps in 3x3 area
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateBankruptRadial(state, piece)
	-- Initialize bankruptTiles if not present
	if not state.bankruptTiles then
		state.bankruptTiles = {}
	end

	for dr = -1, 1 do
		for dc = -1, 1 do
			-- Skip the piece's own position
			if not (dr == 0 and dc == 0) then
				local row = piece.row + dr
				local col = piece.col + dc
				if Logic.isValidPosition(row, col) then
					state.bankruptTiles[row .. "," .. col] = true
				end
			end
		end
	end

	removePower(piece, "bankrupt_radial")

	return state
end

--- Activate bankrupt_row - create power-draining traps in entire row
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateBankruptRow(state, piece)
	if not state.bankruptTiles then
		state.bankruptTiles = {}
	end

	for col = 1, state.cols do
		if col ~= piece.col then
			state.bankruptTiles[piece.row .. "," .. col] = true
		end
	end

	removePower(piece, "bankrupt_row")

	return state
end

--- Activate bankrupt_column - create power-draining traps in entire column
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateBankruptColumn(state, piece)
	if not state.bankruptTiles then
		state.bankruptTiles = {}
	end

	for row = 1, state.rows do
		if row ~= piece.row then
			state.bankruptTiles[row .. "," .. piece.col] = true
		end
	end

	removePower(piece, "bankrupt_column")

	return state
end

--- Apply bankrupt tile effect when piece lands on it
---@param state table Game state
---@param piece table Piece landing on tile
---@param row number Row position
---@param col number Column position
---@return boolean True if a power was lost
function PowerEffects.applyBankruptTile(state, piece, row, col)
	-- Check if tile is bankrupt
	if not state.bankruptTiles then
		return false
	end

	local key = row .. "," .. col
	if not state.bankruptTiles[key] then
		return false
	end

	-- Check if piece has powers to lose
	if not piece.powers or #piece.powers == 0 then
		return false
	end

	-- Remove a random power
	local idx = math.random(#piece.powers)
	table.remove(piece.powers, idx)

	return true
end

-- 9E.2 Tripwire Powers

--- Activate tripwire_radial - adjacent enemies die if they move
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTripwireRadial(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				p.isTripwired = true
				p.tripwireOwner = piece
			end
		end
	end

	removePower(piece, "tripwire_radial")

	return state
end

--- Activate tripwire_row - row enemies die if they move
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTripwireRow(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.row == piece.row then
			p.isTripwired = true
			p.tripwireOwner = piece
		end
	end

	removePower(piece, "tripwire_row")

	return state
end

--- Activate tripwire_column - column enemies die if they move
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateTripwireColumn(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.col == piece.col then
			p.isTripwired = true
			p.tripwireOwner = piece
		end
	end

	removePower(piece, "tripwire_column")

	return state
end

--- Check if a piece should die from tripwire when moving
---@param piece table Piece attempting to move
---@return boolean True if piece should die
function PowerEffects.checkTripwire(piece)
	return piece.isTripwired == true
end

-- 9E.3 Inhibit Powers

--- Activate inhibit_radial - adjacent enemies can't collect powers
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInhibitRadial(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				p.isInhibited = true
			end
		end
	end

	removePower(piece, "inhibit_radial")

	return state
end

--- Activate inhibit_row - row enemies can't collect powers
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInhibitRow(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.row == piece.row then
			p.isInhibited = true
		end
	end

	removePower(piece, "inhibit_row")

	return state
end

--- Activate inhibit_column - column enemies can't collect powers
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateInhibitColumn(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.col == piece.col then
			p.isInhibited = true
		end
	end

	removePower(piece, "inhibit_column")

	return state
end

--- Check if a piece can collect an orb
---@param piece table Piece attempting to collect
---@return boolean True if piece can collect orbs
function PowerEffects.canCollectOrb(piece)
	return not (piece.isInhibited == true)
end

-- 9C.4 Parasite Powers

--- Activate parasite_radial - adjacent enemies' future powers go to you
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateParasiteRadial(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				p.parasitizedBy = piece
			end
		end
	end

	removePower(piece, "parasite_radial")

	return state
end

--- Activate parasite_row - row enemies' future powers go to you
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateParasiteRow(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.row == piece.row then
			p.parasitizedBy = piece
		end
	end

	removePower(piece, "parasite_row")

	return state
end

--- Activate parasite_column - column enemies' future powers go to you
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateParasiteColumn(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.player ~= piece.player and p.col == piece.col then
			p.parasitizedBy = piece
		end
	end

	removePower(piece, "parasite_column")

	return state
end

--- Get the piece that should receive redirected powers (if parasitized)
---@param piece table Piece that would normally receive a power
---@return table|nil The parasite owner, or nil if not parasitized
function PowerEffects.getParasiteRedirect(piece)
	return piece.parasitizedBy
end

-- 9E.6 Purify Powers

--- Helper to remove all debuffs from a piece (ally cleansing)
--- Debuffs: Spyware bugging, Tripwire, Inhibit, Parasite infection
---@param piece table Piece to purify
local function removeDebuffs(piece)
	piece.powersRevealed = nil -- Spyware bugging device
	piece.isTripwired = nil
	piece.tripwireOwner = nil
	piece.isInhibited = nil
	piece.parasitizedBy = nil
end

--- Helper to remove all buffs from a piece (enemy debuffing)
--- Buffs: Grow Quadradius, Climb Tile, Move Diagonal, Jump Proof,
---        Flat To Sphere, Invisible, Scavenger, Beneficiary
---@param piece table Piece to strip buffs from
local function removeBuffs(piece)
	piece.growQuadradiusLevel = nil
	piece.canClimbAny = nil
	piece.canMoveDiagonally = nil
	piece.isJumpProof = nil
	piece.canWrap = nil
	piece.isInvisible = nil
	piece.isScavenger = nil
	piece.isBeneficiary = nil
end

--- Activate purify_radial - remove debuffs from adjacent allies, buffs from adjacent enemies
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePurifyRadial(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece then
			local dr = math.abs(p.row - piece.row)
			local dc = math.abs(p.col - piece.col)
			if dr <= 1 and dc <= 1 then
				if p.player == piece.player then
					removeDebuffs(p) -- Allies: remove bad stuff
				else
					removeBuffs(p) -- Enemies: remove good stuff
				end
			end
		end
	end

	removePower(piece, "purify_radial")

	return state
end

--- Activate purify_row - remove debuffs from allies in row, buffs from enemies in row
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePurifyRow(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.row == piece.row then
			if p.player == piece.player then
				removeDebuffs(p) -- Allies: remove bad stuff
			else
				removeBuffs(p) -- Enemies: remove good stuff
			end
		end
	end

	removePower(piece, "purify_row")

	return state
end

--- Activate purify_column - remove debuffs from allies in column, buffs from enemies in column
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activatePurifyColumn(state, piece)
	for _, p in ipairs(state.pieces) do
		if p ~= piece and p.col == piece.col then
			if p.player == piece.player then
				removeDebuffs(p) -- Allies: remove bad stuff
			else
				removeBuffs(p) -- Enemies: remove good stuff
			end
		end
	end

	removePower(piece, "purify_column")

	return state
end

-- 9E.1 Hotspot Power

--- Get hotspot targets for teleportation (existing hotspots owned by player)
---@param state table Game state
---@param piece table Piece with hotspot power
---@return table Array of {row, col} hotspot positions
function PowerEffects.getHotspotTargets(state, piece)
	local targets = {}

	if not state.hotspotTiles then
		return targets
	end

	for key, owner in pairs(state.hotspotTiles) do
		if owner == piece.player then
			local row, col = key:match("(%d+),(%d+)")
			table.insert(targets, { row = tonumber(row), col = tonumber(col) })
		end
	end

	return targets
end

--- Activate hotspot - create a hotspot at piece position
---@param state table Game state
---@param piece table Piece activating power
---@return table Updated game state
function PowerEffects.activateHotspot(state, piece)
	if not state.hotspotTiles then
		state.hotspotTiles = {}
	end

	local key = piece.row .. "," .. piece.col
	state.hotspotTiles[key] = piece.player

	removePower(piece, "hotspot")

	return state
end

--- Teleport piece to an existing hotspot
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target position {row, col}
---@return table Updated game state
function PowerEffects.activateHotspotTeleport(state, piece, target)
	piece.row = target.row
	piece.col = target.col

	removePower(piece, "hotspot")

	return state
end

-- 9E.1 Centerpult Power

--- Find all 2x2 square formations on the board
---@param state table Game state
---@param piece table Piece with centerpult power
---@return table Array of {row, col} top-left corners of 2x2 formations
function PowerEffects.getCenterpultTargets(state, piece)
	local targets = {}

	-- Create occupancy map
	local occupied = {}
	for _, p in ipairs(state.pieces) do
		occupied[p.row .. "," .. p.col] = true
	end

	-- Check every possible 2x2 square (top-left corner)
	for row = 1, state.rows - 1 do
		for col = 1, state.cols - 1 do
			-- Check if all 4 positions are occupied
			local topLeft = occupied[row .. "," .. col]
			local topRight = occupied[row .. "," .. (col + 1)]
			local bottomLeft = occupied[(row + 1) .. "," .. col]
			local bottomRight = occupied[(row + 1) .. "," .. (col + 1)]

			if topLeft and topRight and bottomLeft and bottomRight then
				table.insert(targets, { row = row, col = col })
			end
		end
	end

	return targets
end

--- Activate centerpult - teleport to a 2x2 square formation
---@param state table Game state
---@param piece table Piece activating power
---@param target table Target position {row, col} - top-left of 2x2
---@return table Updated game state
function PowerEffects.activateCenterpult(state, piece, target)
	-- Move piece to the top-left corner of the 2x2
	-- The piece at target gets displaced (destroyed)
	for i = #state.pieces, 1, -1 do
		local p = state.pieces[i]
		if p.row == target.row and p.col == target.col and p ~= piece then
			table.remove(state.pieces, i)
			break
		end
	end

	piece.row = target.row
	piece.col = target.col

	removePower(piece, "centerpult")

	return state
end

return PowerEffects
