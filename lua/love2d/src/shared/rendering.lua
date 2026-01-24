-- Rendering Utilities Module
-- Coordinate conversion, depth sorting, and visual helpers
-- No Love2D dependencies - pure math functions

local Rendering = {}

-- Visual constants
Rendering.TILE_WIDTH = 64
Rendering.TILE_HEIGHT = 32 -- Isometric half-height
Rendering.HEIGHT_PIXELS = 8 -- Pixels per height level

--- Convert board coordinates to screen coordinates (isometric)
---@param row number Board row (1-indexed)
---@param col number Board column (1-indexed)
---@param offsetX number Screen X offset
---@param offsetY number Screen Y offset
---@return number, number Screen X and Y coordinates
function Rendering.boardToScreen(row, col, offsetX, offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0
	local x = offsetX + (col - row) * (Rendering.TILE_WIDTH / 2)
	local y = offsetY + (col + row) * (Rendering.TILE_HEIGHT / 2)
	return x, y
end

--- Convert screen coordinates to board coordinates
---@param screenX number Screen X coordinate
---@param screenY number Screen Y coordinate
---@param offsetX number Screen X offset
---@param offsetY number Screen Y offset
---@return number, number Board row and column (rounded to nearest)
function Rendering.screenToBoard(screenX, screenY, offsetX, offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0
	local x = screenX - offsetX
	local y = screenY - offsetY

	local col = (x / (Rendering.TILE_WIDTH / 2) + y / (Rendering.TILE_HEIGHT / 2)) / 2
	local row = (y / (Rendering.TILE_HEIGHT / 2) - x / (Rendering.TILE_WIDTH / 2)) / 2

	return math.floor(row + 0.5), math.floor(col + 0.5)
end

--- Get Y offset for rendering at a height level
---@param height number Height level (0-4)
---@return number Y offset in pixels (negative = up on screen)
function Rendering.getHeightOffset(height)
	return -height * Rendering.HEIGHT_PIXELS
end

--- Sort objects by depth for proper rendering order (back to front)
---@param objects table Array of objects with row and col fields
---@return table New sorted array (original unchanged)
function Rendering.sortByDepth(objects)
	local sorted = {}
	for _, obj in ipairs(objects) do
		table.insert(sorted, obj)
	end

	table.sort(sorted, function(a, b)
		if a.row ~= b.row then
			return a.row < b.row
		end
		return a.col < b.col
	end)

	return sorted
end

--- Get vertices for an isometric diamond tile
---@param x number Center X coordinate
---@param y number Center Y coordinate
---@return table Array of vertex coordinates {x1, y1, x2, y2, ...}
function Rendering.getTileVertices(x, y)
	local hw = Rendering.TILE_WIDTH / 2
	local hh = Rendering.TILE_HEIGHT / 2

	return {
		x,
		y - hh, -- Top
		x + hw,
		y, -- Right
		x,
		y + hh, -- Bottom
		x - hw,
		y, -- Left
	}
end

--- Get color for a height level (lighter = higher)
---@param height number Height level (0-4)
---@return number, number, number RGB values (0-1)
function Rendering.getHeightColor(height)
	local baseValue = 0.35
	local maxValue = 0.9
	local maxHeight = 4

	local t = math.min(height, maxHeight) / maxHeight
	local value = baseValue + (maxValue - baseValue) * t

	-- Slight blue tint for cool modern look
	return value * 0.95, value * 0.97, value
end

--- Check if a point is inside an isometric tile
---@param px number Point X coordinate
---@param py number Point Y coordinate
---@param tileX number Tile center X
---@param tileY number Tile center Y
---@return boolean True if point is inside tile
function Rendering.isPointInTile(px, py, tileX, tileY)
	local hw = Rendering.TILE_WIDTH / 2
	local hh = Rendering.TILE_HEIGHT / 2

	-- Transform point relative to tile center
	local dx = math.abs(px - tileX)
	local dy = math.abs(py - tileY)

	-- Diamond shape: |x/hw| + |y/hh| <= 1
	return (dx / hw + dy / hh) <= 1
end

--- Get vertices for tile side (3D effect)
---@param x number Tile center X
---@param y number Tile center Y
---@param height number Tile height
---@param side string "left" or "right"
---@return table Array of vertex coordinates
function Rendering.getTileSideVertices(x, y, height, side)
	local hw = Rendering.TILE_WIDTH / 2
	local hh = Rendering.TILE_HEIGHT / 2
	local sideHeight = height * Rendering.HEIGHT_PIXELS

	if side == "left" then
		return {
			x - hw,
			y, -- Top left of tile
			x,
			y + hh, -- Bottom of tile
			x,
			y + hh + sideHeight, -- Bottom extended
			x - hw,
			y + sideHeight, -- Left extended
		}
	else -- right
		return {
			x,
			y + hh, -- Bottom of tile
			x + hw,
			y, -- Top right of tile
			x + hw,
			y + sideHeight, -- Right extended
			x,
			y + hh + sideHeight, -- Bottom extended
		}
	end
end

--- Calculate draw order depth value
---@param row number Board row
---@param col number Board column
---@return number Depth value (higher = drawn later/on top)
function Rendering.getDepthValue(row, col)
	return row * 100 + col
end

return Rendering
