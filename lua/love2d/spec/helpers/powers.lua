-- Power helpers for power executor tests
-- Add powers and assert power state

local Powers = {}

--- Give a power to a piece
---@param piece table Piece to modify
---@param powerId string Power ID to add
function Powers.givePower(piece, powerId)
	if not piece.powers then
		piece.powers = {}
	end
	table.insert(piece.powers, powerId)
end

--- Give multiple powers to a piece
---@param piece table Piece to modify
---@param powerIds table Array of power IDs
function Powers.givePowers(piece, powerIds)
	for _, powerId in ipairs(powerIds) do
		Powers.givePower(piece, powerId)
	end
end

--- Check if piece has a power (for assertions)
---@param piece table Piece to check
---@param powerId string Power ID
---@return boolean Has power
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

--- Assert piece has a power (use with busted)
---@param piece table Piece to check
---@param powerId string Power ID
function Powers.assertHasPower(piece, powerId)
	assert.is_true(Powers.hasPower(piece, powerId), "Expected piece to have power: " .. powerId)
end

--- Assert piece does not have a power
---@param piece table Piece to check
---@param powerId string Power ID
function Powers.assertNoPower(piece, powerId)
	assert.is_false(Powers.hasPower(piece, powerId), "Expected piece NOT to have power: " .. powerId)
end

--- Count powers on a piece
---@param piece table Piece to count
---@param powerId? string Optional: count only this power
---@return number Count
function Powers.countPowers(piece, powerId)
	if not piece.powers then
		return 0
	end
	if powerId == nil then
		return #piece.powers
	end
	local count = 0
	for _, p in ipairs(piece.powers) do
		if p == powerId then
			count = count + 1
		end
	end
	return count
end

--- Clear all powers from a piece
---@param piece table Piece to clear
function Powers.clearPowers(piece)
	piece.powers = {}
end

--- Remove one instance of a power from piece
---@param piece table Piece to modify
---@param powerId string Power ID to remove
---@return boolean True if removed
function Powers.removePower(piece, powerId)
	if not piece.powers then
		return false
	end
	for i, p in ipairs(piece.powers) do
		if p == powerId then
			table.remove(piece.powers, i)
			return true
		end
	end
	return false
end

return Powers
