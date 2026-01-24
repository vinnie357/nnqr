-- Orb helpers for power executor tests
-- Place and query power orbs on the board

local Orbs = {}

--- Place an orb on the board
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@param powerId string Power contained in orb
---@return table Orb
function Orbs.placeOrb(state, row, col, powerId)
	local orb = {
		row = row,
		col = col,
		powerId = powerId,
	}
	table.insert(state.orbs, orb)
	return orb
end

-- Alias for placeOrb
Orbs.addOrb = Orbs.placeOrb

--- Get orb at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return table|nil Orb or nil
function Orbs.getOrbAt(state, row, col)
	for _, orb in ipairs(state.orbs) do
		if orb.row == row and orb.col == col then
			return orb
		end
	end
	return nil
end

--- Count orbs on the board
---@param state table Game state
---@return number Count
function Orbs.countOrbs(state)
	return #state.orbs
end

--- Remove orb from state
---@param state table Game state
---@param orb table Orb to remove
function Orbs.removeOrb(state, orb)
	for i, o in ipairs(state.orbs) do
		if o == orb then
			table.remove(state.orbs, i)
			return
		end
	end
end

--- Clear all orbs from state
---@param state table Game state
function Orbs.clearOrbs(state)
	state.orbs = {}
end

--- Get all orbs in a row
---@param state table Game state
---@param row number Row to check
---@return table Array of orbs
function Orbs.getOrbsInRow(state, row)
	local orbs = {}
	for _, orb in ipairs(state.orbs) do
		if orb.row == row then
			table.insert(orbs, orb)
		end
	end
	return orbs
end

--- Get all orbs in a column
---@param state table Game state
---@param col number Column to check
---@return table Array of orbs
function Orbs.getOrbsInColumn(state, col)
	local orbs = {}
	for _, orb in ipairs(state.orbs) do
		if orb.col == col then
			table.insert(orbs, orb)
		end
	end
	return orbs
end

return Orbs
