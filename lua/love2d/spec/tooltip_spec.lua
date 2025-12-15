-- Tooltip Module Tests
-- Tests for tooltip formatting and positioning
-- TDD: Write tests first (RED), then implement (GREEN)

package.path = package.path .. ";./?.lua;./?/init.lua"

describe("Tooltip", function()
	local Tooltip
	local Powers

	setup(function()
		Tooltip = require("src.shared.tooltip")
		Powers = require("src.shared.powers")
	end)

	describe("formatPowerTooltip", function()
		it("returns nil for invalid power id", function()
			local result = Tooltip.formatPowerTooltip("invalid_power_id")
			assert.is_nil(result)
		end)

		it("returns table with formatted lines for valid power", function()
			local result = Tooltip.formatPowerTooltip("bomb")
			assert.is_table(result)
			assert.is_true(#result > 0)
		end)

		it("includes power name as first line", function()
			local result = Tooltip.formatPowerTooltip("bomb")
			assert.are.equal("Bomb", result[1])
		end)

		it("includes description", function()
			local result = Tooltip.formatPowerTooltip("bomb")
			local hasDescription = false
			for _, line in ipairs(result) do
				if line:match("Destroy pieces") then
					hasDescription = true
					break
				end
			end
			assert.is_true(hasDescription, "Tooltip should include description")
		end)

		it("includes category label", function()
			local result = Tooltip.formatPowerTooltip("bomb")
			local hasCategory = false
			for _, line in ipairs(result) do
				if line:match("Category:") and line:match("Offensive") then
					hasCategory = true
					break
				end
			end
			assert.is_true(hasCategory, "Tooltip should include category")
		end)

		it("includes duration label", function()
			local result = Tooltip.formatPowerTooltip("bomb")
			local hasDuration = false
			for _, line in ipairs(result) do
				if line:match("Duration:") then
					hasDuration = true
					break
				end
			end
			assert.is_true(hasDuration, "Tooltip should include duration")
		end)

		it("formats permanent duration as 'Permanent'", function()
			local result = Tooltip.formatPowerTooltip("move_diagonal")
			local hasPermanent = false
			for _, line in ipairs(result) do
				if line:match("Duration:") and line:match("Permanent") then
					hasPermanent = true
					break
				end
			end
			assert.is_true(hasPermanent, "Permanent powers should show 'Permanent'")
		end)

		it("formats single_use duration as 'Single Use'", function()
			local result = Tooltip.formatPowerTooltip("bomb")
			local hasSingleUse = false
			for _, line in ipairs(result) do
				if line:match("Duration:") and line:match("Single Use") then
					hasSingleUse = true
					break
				end
			end
			assert.is_true(hasSingleUse, "Single use powers should show 'Single Use'")
		end)
	end)

	describe("calculatePosition", function()
		it("positions tooltip to right of cursor by default", function()
			local x, y = Tooltip.calculatePosition(100, 100, 150, 80, 800, 600)
			assert.is_true(x > 100, "Tooltip should be to the right of cursor")
		end)

		it("flips to left when cursor near right edge", function()
			-- Cursor at x=700, tooltip width=150, screen width=800
			-- 700 + 150 + offset > 800, so should flip
			local x, y = Tooltip.calculatePosition(700, 100, 150, 80, 800, 600)
			assert.is_true(x < 700, "Tooltip should flip to left near right edge")
		end)

		it("moves up when cursor near bottom edge", function()
			-- Cursor at y=550, tooltip height=80, screen height=600
			-- 550 + 80 > 600, so should move up
			local x, y = Tooltip.calculatePosition(100, 550, 150, 80, 800, 600)
			assert.is_true(y < 550, "Tooltip should move up near bottom edge")
		end)

		it("clamps x to minimum of 0", function()
			-- Edge case: cursor at far left, flip would go negative
			local x, y = Tooltip.calculatePosition(10, 100, 150, 80, 800, 600)
			assert.is_true(x >= 0, "Tooltip x should not be negative")
		end)

		it("clamps y to minimum of 0", function()
			-- Edge case: cursor at top, adjustment would go negative
			local x, y = Tooltip.calculatePosition(100, 10, 150, 80, 800, 600)
			assert.is_true(y >= 0, "Tooltip y should not be negative")
		end)
	end)

	describe("getTooltipDimensions", function()
		it("returns width and height for tooltip lines", function()
			local lines = { "Test Line 1", "Longer Test Line 2", "Short" }
			local width, height = Tooltip.getTooltipDimensions(lines, 8)
			assert.is_number(width)
			assert.is_number(height)
			assert.is_true(width > 0)
			assert.is_true(height > 0)
		end)

		it("uses max line length for width calculation", function()
			local lines = { "Short", "This is a much longer line", "Med" }
			local width, height = Tooltip.getTooltipDimensions(lines, 8)
			-- Width should be based on longest line (26 chars * ~8 pixels + padding)
			assert.is_true(width >= 26 * 8, "Width should accommodate longest line")
		end)

		it("calculates height based on line count", function()
			local lines2 = { "Line 1", "Line 2" }
			local lines4 = { "Line 1", "Line 2", "Line 3", "Line 4" }
			local _, height2 = Tooltip.getTooltipDimensions(lines2, 8)
			local _, height4 = Tooltip.getTooltipDimensions(lines4, 8)
			assert.is_true(height4 > height2, "More lines should result in greater height")
		end)

		it("returns zero dimensions for empty lines", function()
			local width, height = Tooltip.getTooltipDimensions({}, 8)
			assert.are.equal(0, width)
			assert.are.equal(0, height)
		end)
	end)
end)
