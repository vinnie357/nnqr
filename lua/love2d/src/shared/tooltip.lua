-- Tooltip Module
-- Handles tooltip formatting and positioning
-- No Love2D dependencies - fully testable

local Powers = require("src.shared.powers")

local Tooltip = {}

-- Padding around tooltip content
Tooltip.PADDING = 10

-- Offset from cursor
Tooltip.CURSOR_OFFSET = 15

-- Duration format mapping
Tooltip.DURATION_LABELS = {
	permanent = "Permanent",
	single_use = "Single Use",
}

--- Format power info into tooltip lines
---@param powerId string Power ID to format
---@return table|nil Array of lines for tooltip, or nil if invalid power
function Tooltip.formatPowerTooltip(powerId)
	local def = Powers.definitions[powerId]
	if not def then
		return nil
	end

	local lines = {}

	-- Power name (first line)
	table.insert(lines, def.name)

	-- Blank line separator
	table.insert(lines, "")

	-- Description (may be multi-line in future)
	table.insert(lines, def.description)

	-- Blank line separator
	table.insert(lines, "")

	-- Category
	table.insert(lines, "Category: " .. def.category)

	-- Duration with formatted label
	local durationLabel = Tooltip.DURATION_LABELS[def.duration] or def.duration
	table.insert(lines, "Duration: " .. durationLabel)

	return lines
end

--- Calculate tooltip position to stay within screen bounds
---@param cursorX number Cursor X position
---@param cursorY number Cursor Y position
---@param tooltipWidth number Width of tooltip
---@param tooltipHeight number Height of tooltip
---@param screenWidth number Screen width
---@param screenHeight number Screen height
---@return number, number X and Y position for tooltip
function Tooltip.calculatePosition(cursorX, cursorY, tooltipWidth, tooltipHeight, screenWidth, screenHeight)
	local x, y

	-- Default: position to the right of cursor
	x = cursorX + Tooltip.CURSOR_OFFSET

	-- Flip to left if too close to right edge
	if x + tooltipWidth > screenWidth then
		x = cursorX - tooltipWidth - Tooltip.CURSOR_OFFSET
	end

	-- Default: align top with cursor
	y = cursorY

	-- Move up if too close to bottom edge
	if y + tooltipHeight > screenHeight then
		y = cursorY - tooltipHeight
	end

	-- Clamp to screen bounds (minimum 0)
	x = math.max(0, x)
	y = math.max(0, y)

	return x, y
end

--- Calculate tooltip dimensions based on content
---@param lines table Array of text lines
---@param charWidth number Approximate character width in pixels
---@return number, number Width and height of tooltip
function Tooltip.getTooltipDimensions(lines, charWidth)
	if #lines == 0 then
		return 0, 0
	end

	-- Find max line length
	local maxLength = 0
	for _, line in ipairs(lines) do
		maxLength = math.max(maxLength, #line)
	end

	-- Calculate dimensions with padding
	local lineHeight = charWidth * 1.5 -- Approximate line height
	local width = maxLength * charWidth + Tooltip.PADDING * 2
	local height = #lines * lineHeight + Tooltip.PADDING * 2

	return width, height
end

return Tooltip
