-- Terrain helpers for power executor tests
-- Height manipulation and destroyed tile tracking

local Height = require("src.shared.height")

local Terrain = {}

--- Set height at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@param height number Height value (0-4)
function Terrain.setHeight(state, row, col, height)
	Height.setHeight(state.heightMap, row, col, height)
end

--- Get height at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return number Height
function Terrain.getHeight(state, row, col)
	return Height.getHeight(state.heightMap, row, col)
end

--- Destroy a tile
---@param state table Game state
---@param row number Row position
---@param col number Column position
function Terrain.destroyTile(state, row, col)
	local key = row .. "," .. col
	state.destroyedTiles[key] = true
end

--- Check if tile is destroyed
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return boolean True if destroyed
function Terrain.isTileDestroyed(state, row, col)
	local key = row .. "," .. col
	return state.destroyedTiles[key] == true
end

--- Repair a destroyed tile
---@param state table Game state
---@param row number Row position
---@param col number Column position
function Terrain.repairTile(state, row, col)
	local key = row .. "," .. col
	state.destroyedTiles[key] = nil
end

--- Count destroyed tiles
---@param state table Game state
---@return number Count
function Terrain.countDestroyedTiles(state)
	local count = 0
	for _ in pairs(state.destroyedTiles) do
		count = count + 1
	end
	return count
end

--- Set heights for an entire row
---@param state table Game state
---@param row number Row to set
---@param height number Height value
function Terrain.setRowHeight(state, row, height)
	for col = 1, state.cols do
		Terrain.setHeight(state, row, col, height)
	end
end

--- Set heights for an entire column
---@param state table Game state
---@param col number Column to set
---@param height number Height value
function Terrain.setColumnHeight(state, col, height)
	for row = 1, state.rows do
		Terrain.setHeight(state, row, col, height)
	end
end

return Terrain
