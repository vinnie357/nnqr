-- Height system for terrain elevation
-- Handles height levels, movement restrictions, and visual calculations

local Height = {}

-- Constants
Height.MIN_HEIGHT = 0
Height.MAX_HEIGHT = 4
Height.MAX_CLIMB = 1

-- Height per level in pixels (for visual offset)
local HEIGHT_PIXELS = 8

--- Check if a height value is valid
---@param height number The height to validate
---@return boolean True if height is valid (0-4, integer)
function Height.isValidHeight(height)
	if type(height) ~= "number" then
		return false
	end
	if height ~= math.floor(height) then
		return false
	end
	return height >= Height.MIN_HEIGHT and height <= Height.MAX_HEIGHT
end

--- Check if movement between two heights is allowed
--- Pieces can climb max 1 level, but drop any number of levels
---@param fromHeight number Starting height
---@param toHeight number Destination height
---@return boolean True if movement is allowed
function Height.canMove(fromHeight, toHeight)
	local diff = toHeight - fromHeight

	-- Climbing: max 1 level
	if diff > Height.MAX_CLIMB then
		return false
	end

	-- Dropping: any amount is allowed (diff <= 0)
	-- Same level: allowed (diff == 0)
	-- Climbing 1: allowed (diff == 1)
	return true
end

--- Clamp height to valid range
---@param height number The height to clamp
---@return number Clamped height between MIN and MAX
function Height.clampHeight(height)
	if height < Height.MIN_HEIGHT then
		return Height.MIN_HEIGHT
	elseif height > Height.MAX_HEIGHT then
		return Height.MAX_HEIGHT
	end
	return height
end

--- Raise height by amount (default 1)
---@param height number Current height
---@param amount number? Amount to raise (default 1)
---@return number New height (clamped to max)
function Height.raiseHeight(height, amount)
	amount = amount or 1
	return Height.clampHeight(height + amount)
end

--- Lower height by amount (default 1)
---@param height number Current height
---@param amount number? Amount to lower (default 1)
---@return number New height (clamped to min)
function Height.lowerHeight(height, amount)
	amount = amount or 1
	return Height.clampHeight(height - amount)
end

--- Get color for a height level (whiter = higher)
---@param height number The height level (0-4)
---@return number, number, number RGB values (0-1)
function Height.getHeightColor(height)
	-- Base color at height 0, progressively lighter
	local baseValue = 0.3
	local maxValue = 0.95

	local t = height / Height.MAX_HEIGHT
	local value = baseValue + (maxValue - baseValue) * t

	return value, value, value
end

--- Get Y offset for rendering at a height level
--- Higher tiles appear higher on screen (negative Y in screen coords)
---@param height number The height level (0-4)
---@return number Y offset in pixels (negative = up)
function Height.getHeightOffset(height)
	return -height * HEIGHT_PIXELS
end

--- Create a height map for the board
---@param cols number Number of columns
---@param rows number Number of rows
---@param defaultHeight number? Default height for all tiles (default 0)
---@return table 2D array of heights [row][col]
function Height.createHeightMap(cols, rows, defaultHeight)
	defaultHeight = defaultHeight or 0
	local map = {}
	for row = 1, rows do
		map[row] = {}
		for col = 1, cols do
			map[row][col] = defaultHeight
		end
	end
	return map
end

--- Set height at a position
---@param map table The height map
---@param row number Row position
---@param col number Column position
---@param height number New height (will be clamped)
function Height.setHeight(map, row, col, height)
	if map[row] and map[row][col] ~= nil then
		map[row][col] = Height.clampHeight(height)
	end
end

--- Get height at a position
---@param map table The height map
---@param row number Row position
---@param col number Column position
---@return number Height at position (0 if out of bounds)
function Height.getHeight(map, row, col)
	if map[row] and map[row][col] then
		return map[row][col]
	end
	return 0
end

return Height
