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

	-- Restoration Powers
	refurb = {
		id = "refurb",
		name = "Refurb",
		category = "Restoration",
		duration = "single_use",
		description = "Repair an adjacent destroyed tile",
		targeting = "adjacent_destroyed",
	},

	-- Phase 9A.1: Destroy Variants
	destroy_radial = {
		id = "destroy_radial",
		name = "Destroy Radial",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces in 3x3 area (does not affect terrain)",
		targeting = "area_3x3",
	},
	kamikaze_radial = {
		id = "kamikaze_radial",
		name = "Kamikaze Radial",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces in 3x3 area including self",
		targeting = "area_3x3",
	},
	kamikaze_row = {
		id = "kamikaze_row",
		name = "Kamikaze Row",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces in this row including self",
		targeting = "self_row",
	},
	kamikaze_column = {
		id = "kamikaze_column",
		name = "Kamikaze Column",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces in this column including self",
		targeting = "self_column",
	},

	-- Phase 9A.3: Extended Recruitment
	recruit_row = {
		id = "recruit_row",
		name = "Recruit Row",
		category = "Strategic",
		duration = "single_use",
		description = "Convert all enemy pieces in this row to your side",
		targeting = "self_row",
	},
	recruit_column = {
		id = "recruit_column",
		name = "Recruit Column",
		category = "Strategic",
		duration = "single_use",
		description = "Convert all enemy pieces in this column to your side",
		targeting = "self_column",
	},

	-- Phase 9A.4: Scramble Powers
	scramble_radial = {
		id = "scramble_radial",
		name = "Scramble Radial",
		category = "Chaos",
		duration = "single_use",
		description = "Randomly swap positions of all pieces in 3x3 area",
		targeting = "area_3x3",
	},

	-- Phase 9A.5: Smart Bombs
	smart_bombs = {
		id = "smart_bombs",
		name = "Smart Bombs",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all enemy pieces in 3x3 area (allies unaffected)",
		targeting = "area_3x3",
	},

	-- Phase 9A.2: Acidic Powers
	acidic_radial = {
		id = "acidic_radial",
		name = "Acidic Radial",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy pieces and tiles in 3x3 area",
		targeting = "area_3x3",
	},
	acidic_row = {
		id = "acidic_row",
		name = "Acidic Row",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces and tiles in row (except under self)",
		targeting = "self_row",
	},
	acidic_column = {
		id = "acidic_column",
		name = "Acidic Column",
		category = "Offensive",
		duration = "single_use",
		description = "Destroy all pieces and tiles in column (except under self)",
		targeting = "self_column",
	},

	-- Phase 9A.4: Scramble Row/Column
	scramble_row = {
		id = "scramble_row",
		name = "Scramble Row",
		category = "Chaos",
		duration = "single_use",
		description = "Randomly swap positions of all pieces in row",
		targeting = "self_row",
	},
	scramble_column = {
		id = "scramble_column",
		name = "Scramble Column",
		category = "Chaos",
		duration = "single_use",
		description = "Randomly swap positions of all pieces in column",
		targeting = "self_column",
	},

	-- Phase 9B: Terrain Powers

	-- 9B.1 Area Effects
	plateau = {
		id = "plateau",
		name = "Plateau",
		category = "Terrain",
		duration = "single_use",
		description = "Raise 3x3 area to maximum height",
		targeting = "area_3x3",
	},
	moat = {
		id = "moat",
		name = "Moat",
		category = "Terrain",
		duration = "single_use",
		description = "Raise center to max, lower surrounding ring",
		targeting = "area_3x3",
	},
	climb_tile = {
		id = "climb_tile",
		name = "Climb Tile",
		category = "Movement",
		duration = "permanent",
		description = "Piece ignores height restrictions permanently",
		targeting = "self",
	},

	-- 9B.2 Line Effects
	trench_row = {
		id = "trench_row",
		name = "Trench Row",
		category = "Terrain",
		duration = "single_use",
		description = "Lower entire row by 2 levels",
		targeting = "self_row",
	},
	trench_column = {
		id = "trench_column",
		name = "Trench Column",
		category = "Terrain",
		duration = "single_use",
		description = "Lower entire column by 2 levels",
		targeting = "self_column",
	},
	wall_row = {
		id = "wall_row",
		name = "Wall Row",
		category = "Terrain",
		duration = "single_use",
		description = "Raise entire row by 2 levels",
		targeting = "self_row",
	},
	wall_column = {
		id = "wall_column",
		name = "Wall Column",
		category = "Terrain",
		duration = "single_use",
		description = "Raise entire column by 2 levels",
		targeting = "self_column",
	},

	-- 9B.3 Invert Powers
	invert_radial = {
		id = "invert_radial",
		name = "Invert Radial",
		category = "Terrain",
		duration = "single_use",
		description = "Flip heights in 3x3 area (4 becomes 0, etc.)",
		targeting = "area_3x3",
	},
	invert_row = {
		id = "invert_row",
		name = "Invert Row",
		category = "Terrain",
		duration = "single_use",
		description = "Flip heights in entire row",
		targeting = "self_row",
	},
	invert_column = {
		id = "invert_column",
		name = "Invert Column",
		category = "Terrain",
		duration = "single_use",
		description = "Flip heights in entire column",
		targeting = "self_column",
	},

	-- 9B.4 Dredge Powers
	dredge_radial = {
		id = "dredge_radial",
		name = "Dredge Radial",
		category = "Terrain",
		duration = "single_use",
		description = "Raise friendly tiles, lower enemy tiles in 3x3",
		targeting = "area_3x3",
	},
	dredge_row = {
		id = "dredge_row",
		name = "Dredge Row",
		category = "Terrain",
		duration = "single_use",
		description = "Raise friendly tiles, lower enemy tiles in row",
		targeting = "self_row",
	},
	dredge_column = {
		id = "dredge_column",
		name = "Dredge Column",
		category = "Terrain",
		duration = "single_use",
		description = "Raise friendly tiles, lower enemy tiles in column",
		targeting = "self_column",
	},

	-- Phase 9C: Power Transfer Powers

	-- 9C.1 Teach (Share to allies)
	teach_radial = {
		id = "teach_radial",
		name = "Teach Radial",
		category = "Strategic",
		duration = "single_use",
		description = "Copy all your powers to adjacent allies",
		targeting = "area_3x3",
	},
	teach_row = {
		id = "teach_row",
		name = "Teach Row",
		category = "Strategic",
		duration = "single_use",
		description = "Copy all your powers to allies in row",
		targeting = "self_row",
	},
	teach_column = {
		id = "teach_column",
		name = "Teach Column",
		category = "Strategic",
		duration = "single_use",
		description = "Copy all your powers to allies in column",
		targeting = "self_column",
	},

	-- 9C.2 Learn (Absorb from allies)
	learn_radial = {
		id = "learn_radial",
		name = "Learn Radial",
		category = "Strategic",
		duration = "single_use",
		description = "Take all powers from adjacent allies",
		targeting = "area_3x3",
	},
	learn_row = {
		id = "learn_row",
		name = "Learn Row",
		category = "Strategic",
		duration = "single_use",
		description = "Take all powers from allies in row",
		targeting = "self_row",
	},
	learn_column = {
		id = "learn_column",
		name = "Learn Column",
		category = "Strategic",
		duration = "single_use",
		description = "Take all powers from allies in column",
		targeting = "self_column",
	},

	-- 9C.3 Pilfer (Steal from enemies)
	pilfer_radial = {
		id = "pilfer_radial",
		name = "Pilfer Radial",
		category = "Offensive",
		duration = "single_use",
		description = "Steal one random power from each adjacent enemy",
		targeting = "area_3x3",
	},
	pilfer_row = {
		id = "pilfer_row",
		name = "Pilfer Row",
		category = "Offensive",
		duration = "single_use",
		description = "Steal one random power from each enemy in row",
		targeting = "self_row",
	},
	pilfer_column = {
		id = "pilfer_column",
		name = "Pilfer Column",
		category = "Offensive",
		duration = "single_use",
		description = "Steal one random power from each enemy in column",
		targeting = "self_column",
	},

	-- Phase 9D: Meta Powers
	double_powers = {
		id = "double_powers",
		name = "2x",
		category = "Meta",
		duration = "single_use",
		description = "Double all powers on this piece",
		targeting = "self",
	},
	orbic_rehash = {
		id = "orbic_rehash",
		name = "Orbic Rehash",
		category = "Meta",
		duration = "single_use",
		description = "Respawn all orbs at new random locations",
		targeting = "global",
	},
	cancel_multiply = {
		id = "cancel_multiply",
		name = "Cancel Multiply",
		category = "Meta",
		duration = "single_use",
		description = "Destroy the most recently multiplied piece",
		targeting = "global",
	},
	grow_quadradius = {
		id = "grow_quadradius",
		name = "Grow Quadradius",
		category = "Meta",
		duration = "permanent",
		description = "Extend power range by 1 (stacks up to 3x)",
		targeting = "self",
	},
	beneficiary = {
		id = "beneficiary",
		name = "Beneficiary",
		category = "Meta",
		duration = "permanent",
		description = "All allied pieces' powers transfer to this piece when they die",
		targeting = "self",
	},

	-- Phase 9E: Movement & Control Powers

	-- 9E.1 Special Movement
	switcheroo = {
		id = "switcheroo",
		name = "Switcheroo",
		category = "Movement",
		duration = "single_use",
		description = "Swap positions with an adjacent piece",
		targeting = "adjacent",
	},
	scavenger = {
		id = "scavenger",
		name = "Scavenger",
		category = "Strategic",
		duration = "permanent",
		description = "Inherit powers from captured enemies",
		targeting = "self",
	},
	flat_to_sphere = {
		id = "flat_to_sphere",
		name = "Flat To Sphere",
		category = "Movement",
		duration = "permanent",
		description = "Enable wraparound movement (edges connect)",
		targeting = "self",
	},

	-- 9E.5 Intelligence Powers
	spyware_radial = {
		id = "spyware_radial",
		name = "Spyware Radial",
		category = "Intelligence",
		duration = "single_use",
		description = "Reveal powers of adjacent enemy pieces",
		targeting = "area_3x3",
	},
	spyware_row = {
		id = "spyware_row",
		name = "Spyware Row",
		category = "Intelligence",
		duration = "single_use",
		description = "Reveal powers of enemy pieces in row",
		targeting = "self_row",
	},
	spyware_column = {
		id = "spyware_column",
		name = "Spyware Column",
		category = "Intelligence",
		duration = "single_use",
		description = "Reveal powers of enemy pieces in column",
		targeting = "self_column",
	},
	orb_spy_radial = {
		id = "orb_spy_radial",
		name = "Orb Spy Radial",
		category = "Intelligence",
		duration = "single_use",
		description = "Reveal contents of adjacent orbs",
		targeting = "area_3x3",
	},
	orb_spy_row = {
		id = "orb_spy_row",
		name = "Orb Spy Row",
		category = "Intelligence",
		duration = "single_use",
		description = "Reveal contents of orbs in row",
		targeting = "self_row",
	},
	orb_spy_column = {
		id = "orb_spy_column",
		name = "Orb Spy Column",
		category = "Intelligence",
		duration = "single_use",
		description = "Reveal contents of orbs in column",
		targeting = "self_column",
	},

	-- 9E.6 Restoration Powers
	refurb_radial = {
		id = "refurb_radial",
		name = "Refurb Radial",
		category = "Restoration",
		duration = "single_use",
		description = "Repair all destroyed tiles in 3x3 area",
		targeting = "area_3x3",
	},
	refurb_row = {
		id = "refurb_row",
		name = "Refurb Row",
		category = "Restoration",
		duration = "single_use",
		description = "Repair all destroyed tiles in row",
		targeting = "self_row",
	},
	refurb_column = {
		id = "refurb_column",
		name = "Refurb Column",
		category = "Restoration",
		duration = "single_use",
		description = "Repair all destroyed tiles in column",
		targeting = "self_column",
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

-- Overheat threshold (10+ of same power causes explosion)
Powers.OVERHEAT_THRESHOLD = 10

--- Count occurrences of a specific power on a piece
---@param piece table Piece to check
---@param powerId string Power ID to count
---@return number Count of power
function Powers.countPowerById(piece, powerId)
	if not piece.powers then
		return 0
	end
	local count = 0
	for _, p in ipairs(piece.powers) do
		if p == powerId then
			count = count + 1
		end
	end
	return count
end

--- Check if piece has overheated (10+ of same power)
---@param piece table Piece to check
---@return string|nil Power ID that caused overheat, or nil
function Powers.checkOverheat(piece)
	if not piece.powers then
		return nil
	end

	-- Count each unique power
	local counts = {}
	for _, powerId in ipairs(piece.powers) do
		counts[powerId] = (counts[powerId] or 0) + 1
		-- Early return if threshold reached
		if counts[powerId] >= Powers.OVERHEAT_THRESHOLD then
			return powerId
		end
	end

	return nil
end

return Powers
