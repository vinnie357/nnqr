-- Busted tests for terrain height system
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("Height", function()
	local Height

	setup(function()
		Height = require("src.shared.height")
	end)

	describe("constants", function()
		it("has minimum height of 0", function()
			assert.are.equal(0, Height.MIN_HEIGHT)
		end)

		it("has maximum height of 4", function()
			assert.are.equal(4, Height.MAX_HEIGHT)
		end)

		it("has max climb of 1", function()
			assert.are.equal(1, Height.MAX_CLIMB)
		end)
	end)

	describe("isValidHeight", function()
		it("accepts height 0", function()
			assert.is_true(Height.isValidHeight(0))
		end)

		it("accepts height 4", function()
			assert.is_true(Height.isValidHeight(4))
		end)

		it("accepts middle heights", function()
			assert.is_true(Height.isValidHeight(1))
			assert.is_true(Height.isValidHeight(2))
			assert.is_true(Height.isValidHeight(3))
		end)

		it("rejects negative heights", function()
			assert.is_false(Height.isValidHeight(-1))
		end)

		it("rejects heights above max", function()
			assert.is_false(Height.isValidHeight(5))
		end)

		it("rejects non-integer heights", function()
			assert.is_false(Height.isValidHeight(1.5))
		end)
	end)

	describe("canMove", function()
		describe("climbing rules", function()
			it("allows climbing 1 level", function()
				assert.is_true(Height.canMove(0, 1))
			end)

			it("rejects climbing 2 levels", function()
				assert.is_false(Height.canMove(0, 2))
			end)

			it("rejects climbing 3 levels", function()
				assert.is_false(Height.canMove(0, 3))
			end)

			it("rejects climbing 4 levels", function()
				assert.is_false(Height.canMove(0, 4))
			end)
		end)

		describe("dropping rules", function()
			it("allows dropping 1 level", function()
				assert.is_true(Height.canMove(1, 0))
			end)

			it("allows dropping 2 levels", function()
				assert.is_true(Height.canMove(2, 0))
			end)

			it("allows dropping 3 levels", function()
				assert.is_true(Height.canMove(3, 0))
			end)

			it("allows dropping 4 levels", function()
				assert.is_true(Height.canMove(4, 0))
			end)
		end)

		describe("same level movement", function()
			it("allows moving on same level", function()
				assert.is_true(Height.canMove(0, 0))
				assert.is_true(Height.canMove(2, 2))
				assert.is_true(Height.canMove(4, 4))
			end)
		end)
	end)

	describe("clampHeight", function()
		it("clamps negative to 0", function()
			assert.are.equal(0, Height.clampHeight(-1))
			assert.are.equal(0, Height.clampHeight(-100))
		end)

		it("clamps above max to max", function()
			assert.are.equal(4, Height.clampHeight(5))
			assert.are.equal(4, Height.clampHeight(100))
		end)

		it("preserves valid heights", function()
			assert.are.equal(0, Height.clampHeight(0))
			assert.are.equal(2, Height.clampHeight(2))
			assert.are.equal(4, Height.clampHeight(4))
		end)
	end)

	describe("raiseHeight", function()
		it("increases height by 1", function()
			assert.are.equal(1, Height.raiseHeight(0))
			assert.are.equal(2, Height.raiseHeight(1))
			assert.are.equal(3, Height.raiseHeight(2))
		end)

		it("caps at max height", function()
			assert.are.equal(4, Height.raiseHeight(4))
		end)

		it("accepts custom amount", function()
			assert.are.equal(2, Height.raiseHeight(0, 2))
		end)

		it("caps custom amount at max", function()
			assert.are.equal(4, Height.raiseHeight(2, 10))
		end)
	end)

	describe("lowerHeight", function()
		it("decreases height by 1", function()
			assert.are.equal(3, Height.lowerHeight(4))
			assert.are.equal(2, Height.lowerHeight(3))
			assert.are.equal(1, Height.lowerHeight(2))
		end)

		it("caps at min height", function()
			assert.are.equal(0, Height.lowerHeight(0))
		end)

		it("accepts custom amount", function()
			assert.are.equal(2, Height.lowerHeight(4, 2))
		end)

		it("caps custom amount at min", function()
			assert.are.equal(0, Height.lowerHeight(2, 10))
		end)
	end)

	describe("getHeightColor", function()
		it("returns darker color for height 0", function()
			local r, g, b = Height.getHeightColor(0)
			assert.is_true(r < 1 and g < 1 and b < 1)
		end)

		it("returns lighter color for height 4", function()
			local r, g, b = Height.getHeightColor(4)
			assert.is_true(r >= 0.9 and g >= 0.9 and b >= 0.9)
		end)

		it("returns progressively lighter colors", function()
			local r0, g0, b0 = Height.getHeightColor(0)
			local r2, g2, b2 = Height.getHeightColor(2)
			local r4, g4, b4 = Height.getHeightColor(4)

			assert.is_true(r0 < r2)
			assert.is_true(r2 < r4)
		end)
	end)

	describe("getHeightOffset", function()
		it("returns 0 offset for height 0", function()
			assert.are.equal(0, Height.getHeightOffset(0))
		end)

		it("returns negative offset for higher tiles (moves up on screen)", function()
			local offset1 = Height.getHeightOffset(1)
			local offset2 = Height.getHeightOffset(2)

			assert.is_true(offset1 < 0)
			assert.is_true(offset2 < offset1)
		end)

		it("returns larger offset for higher heights", function()
			local offset1 = Height.getHeightOffset(1)
			local offset4 = Height.getHeightOffset(4)

			assert.is_true(math.abs(offset4) > math.abs(offset1))
		end)
	end)

	describe("createHeightMap", function()
		it("creates a map with correct dimensions", function()
			local map = Height.createHeightMap(10, 8)
			assert.are.equal(8, #map)
			assert.are.equal(10, #map[1])
		end)

		it("initializes all tiles to height 0 by default", function()
			local map = Height.createHeightMap(10, 8)
			for row = 1, 8 do
				for col = 1, 10 do
					assert.are.equal(0, map[row][col])
				end
			end
		end)

		it("accepts custom default height", function()
			local map = Height.createHeightMap(10, 8, 2)
			for row = 1, 8 do
				for col = 1, 10 do
					assert.are.equal(2, map[row][col])
				end
			end
		end)
	end)

	describe("setHeight", function()
		it("sets height at position", function()
			local map = Height.createHeightMap(10, 8)
			Height.setHeight(map, 3, 4, 2)
			assert.are.equal(2, map[3][4])
		end)

		it("clamps height to valid range", function()
			local map = Height.createHeightMap(10, 8)
			Height.setHeight(map, 3, 4, 10)
			assert.are.equal(4, map[3][4])

			Height.setHeight(map, 3, 4, -5)
			assert.are.equal(0, map[3][4])
		end)
	end)

	describe("getHeight", function()
		it("gets height at position", function()
			local map = Height.createHeightMap(10, 8, 0)
			map[3][4] = 3
			assert.are.equal(3, Height.getHeight(map, 3, 4))
		end)

		it("returns 0 for out of bounds", function()
			local map = Height.createHeightMap(10, 8)
			assert.are.equal(0, Height.getHeight(map, 0, 0))
			assert.are.equal(0, Height.getHeight(map, 100, 100))
		end)
	end)
end)
