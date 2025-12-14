-- Power System Module
-- Power definitions, orb spawning, and power inventory management

local Powers = {}

-- Spawn interval (every N turns)
Powers.SPAWN_INTERVAL = 7

-- Power definitions
Powers.definitions = {
	-- Movement Powers
	move_diagonal = {
		id = "move_diagonal",
		name = "Move Diagonal",
		category = "Movement",
		duration = "permanent",
		description = "Enables diagonal movement for this piece",
		targeting = "self",
	},
	move_again = {
		id = "move_again",
		name = "Move Again",
		category = "Movement",
		duration = "single_use",
		description = "Take another move immediately after this one",
		targeting = "self",
	},
	relocate = {
		id = "relocate",
		name = "Relocate",
		category = "Movement",
		duration = "single_use",
		description = "Teleport to a random empty tile",
		targeting = "self",
	},

	-- Offensive Powers
	destroy_row = {
		id = "destroy_row",
		name = "Destroy Row",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces in this row",
		targeting = "self_row",
	},
	destroy_column = {
		id = "destroy_column",
		name = "Destroy Column",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces in this column",
		targeting = "self_column",
	},
	bomb = {
		id = "bomb",
		name = "Bomb",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy pieces in 3x3 area and lower terrain",
		targeting = "area_3x3",
	},

	-- Defensive Powers
	jump_proof = {
		id = "jump_proof",
		name = "Jump Proof",
		category = "Defensive",
		duration = "permanent",
		description = "Piece cannot be captured by normal movement",
		targeting = "self",
	},

	-- Terrain Powers
	raise_tile = {
		id = "raise_tile",
		name = "Raise Tile",
		category = "Terrain",
		duration = "single_use",
		description = "Increase adjacent tile height by 1",
		targeting = "adjacent",
	},
	lower_tile = {
		id = "lower_tile",
		name = "Lower Tile",
		category = "Terrain",
		duration = "single_use",
		description = "Decrease adjacent tile height by 1",
		targeting = "adjacent",
	},

	-- Strategic Powers
	recruit = {
		id = "recruit",
		name = "Recruit",
		category = "Strategic",
		duration = "single_use",
		description = "Convert one adjacent enemy piece to your side",
		targeting = "adjacent_enemy",
	},
	multiply = {
		id = "multiply",
		name = "Multiply",
		category = "Strategic",
		duration = "single_use",
		description = "Create a copy of this piece on adjacent empty tile",
		targeting = "adjacent_empty",
	},

	-- Utility Powers
	invisible = {
		id = "invisible",
		name = "Invisible",
		category = "Utility",
		duration = "permanent",
		description = "Piece is hidden from opponent until it attacks",
		targeting = "self",
	},
}

-- List of power IDs for random selection
Powers.powerIds = {}
for id, _ in pairs(Powers.definitions) do
	table.insert(Powers.powerIds, id)
end

--- Check if orbs should spawn this turn
---@param turn number Current turn number
---@return boolean True if orbs should spawn
function Powers.shouldSpawnOrbs(turn)
	return turn > 0 and turn % Powers.SPAWN_INTERVAL == 0
end

--- Get number of orbs to spawn
---@return number Number of orbs (2-4)
function Powers.getOrbSpawnCount()
	return math.random(2, 4)
end

--- Get list of empty tiles (no pieces, no orbs)
---@param cols number Board columns
---@param rows number Board rows
---@param pieces table Array of pieces
---@param orbs table Array of existing orbs
---@return table Array of {row, col} empty positions
function Powers.getEmptyTiles(cols, rows, pieces, orbs)
	-- Create occupancy map
	local occupied = {}
	for _, piece in ipairs(pieces) do
		local key = piece.row .. "," .. piece.col
		occupied[key] = true
	end
	for _, orb in ipairs(orbs) do
		local key = orb.row .. "," .. orb.col
		occupied[key] = true
	end

	-- Find empty tiles
	local empty = {}
	for row = 1, rows do
		for col = 1, cols do
			local key = row .. "," .. col
			if not occupied[key] then
				table.insert(empty, { row = row, col = col })
			end
		end
	end

	return empty
end

--- Spawn new orbs on empty tiles
---@param cols number Board columns
---@param rows number Board rows
---@param pieces table Array of pieces
---@param existingOrbs table Array of existing orbs
---@param count number Number of orbs to spawn
---@return table Array of new orb objects
function Powers.spawnOrbs(cols, rows, pieces, existingOrbs, count)
	local empty = Powers.getEmptyTiles(cols, rows, pieces, existingOrbs)
	local newOrbs = {}

	-- Shuffle empty tiles
	for i = #empty, 2, -1 do
		local j = math.random(i)
		empty[i], empty[j] = empty[j], empty[i]
	end

	-- Spawn orbs
	for i = 1, math.min(count, #empty) do
		local tile = empty[i]
		local powerId = Powers.powerIds[math.random(#Powers.powerIds)]
		table.insert(newOrbs, {
			row = tile.row,
			col = tile.col,
			powerId = powerId,
		})
	end

	return newOrbs
end

--- Get random power ID
---@return string Random power ID
function Powers.getRandomPowerId()
	return Powers.powerIds[math.random(#Powers.powerIds)]
end

--- Add power to piece inventory
---@param piece table Piece object
---@param powerId string Power ID to add
function Powers.addPower(piece, powerId)
	if not piece.powers then
		piece.powers = {}
	end
	table.insert(piece.powers, powerId)
end

--- Check if piece has a specific power
---@param piece table Piece object
---@param powerId string Power ID to check
---@return boolean True if piece has the power
function Powers.hasPower(piece, powerId)
	if not piece.powers then
		return false
	end
	for _, p in ipairs(piece.powers) do
		if p == powerId then
			return true
		end
	end
	return false
end

--- Remove power from piece inventory
---@param piece table Piece object
---@param powerId string Power ID to remove
function Powers.removePower(piece, powerId)
	if not piece.powers then
		return
	end
	for i, p in ipairs(piece.powers) do
		if p == powerId then
			table.remove(piece.powers, i)
			return
		end
	end
end

--- Collect orb at piece's position
---@param piece table Piece object
---@param orbs table Array of orbs (will be modified)
---@return boolean True if orb was collected
function Powers.collectOrb(piece, orbs)
	for i, orb in ipairs(orbs) do
		if orb.row == piece.row and orb.col == piece.col then
			Powers.addPower(piece, orb.powerId)
			table.remove(orbs, i)
			return true
		end
	end
	return false
end

--- Check if piece is jump proof
---@param piece table Piece object
---@return boolean True if piece cannot be captured normally
function Powers.isJumpProof(piece)
	return Powers.hasPower(piece, "jump_proof")
end

--- Check if piece can move diagonally
---@param piece table Piece object
---@return boolean True if piece can move diagonally
function Powers.canMoveDiagonally(piece)
	return Powers.hasPower(piece, "move_diagonal")
end

return Powers
