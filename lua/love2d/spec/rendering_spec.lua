-- Busted tests for rendering utilities
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("Rendering", function()
	local Rendering

	setup(function()
		Rendering = require("src.shared.rendering")
	end)

	describe("constants", function()
		it("has tile width", function()
			assert.are.equal(64, Rendering.TILE_WIDTH)
		end)

		it("has tile height (isometric half)", function()
			assert.are.equal(32, Rendering.TILE_HEIGHT)
		end)

		it("has height pixels per level", function()
			assert.are.equal(8, Rendering.HEIGHT_PIXELS)
		end)
	end)

	describe("boardToScreen", function()
		it("converts board position to screen coordinates", function()
			local x, y = Rendering.boardToScreen(1, 1, 400, 100)
			assert.is_number(x)
			assert.is_number(y)
		end)

		it("row 1 col 1 at offset 0,0 returns expected coords", function()
			local x, y = Rendering.boardToScreen(1, 1, 0, 0)
			-- (col - row) * (tileWidth/2) = (1-1) * 32 = 0
			-- (col + row) * (tileHeight/2) = (1+1) * 16 = 32
			assert.are.equal(0, x)
			assert.are.equal(32, y)
		end)

		it("different positions give different screen coords", function()
			local x1, y1 = Rendering.boardToScreen(1, 1, 0, 0)
			local x2, y2 = Rendering.boardToScreen(2, 2, 0, 0)
			-- Row 2 col 2: (2-2)*32=0, (2+2)*16=64
			assert.are.equal(0, x2)
			assert.are.equal(64, y2)
		end)

		it("applies offset correctly", function()
			local x, y = Rendering.boardToScreen(1, 1, 100, 50)
			assert.are.equal(100, x)
			assert.are.equal(82, y) -- 50 + 32
		end)
	end)

	describe("screenToBoard", function()
		it("converts screen coordinates to board position", function()
			local row, col = Rendering.screenToBoard(0, 32, 0, 0)
			assert.are.equal(1, row)
			assert.are.equal(1, col)
		end)

		it("round-trips correctly", function()
			local offsetX, offsetY = 400, 100
			for testRow = 1, 8 do
				for testCol = 1, 10 do
					local x, y = Rendering.boardToScreen(testRow, testCol, offsetX, offsetY)
					local row, col = Rendering.screenToBoard(x, y, offsetX, offsetY)
					assert.are.equal(testRow, row, "Row mismatch at " .. testRow .. "," .. testCol)
					assert.are.equal(testCol, col, "Col mismatch at " .. testRow .. "," .. testCol)
				end
			end
		end)
	end)

	describe("getHeightOffset", function()
		it("returns 0 for height 0", function()
			assert.are.equal(0, Rendering.getHeightOffset(0))
		end)

		it("returns negative offset for positive height", function()
			local offset = Rendering.getHeightOffset(2)
			assert.is_true(offset < 0)
		end)

		it("returns larger offset for higher tiles", function()
			local offset1 = Rendering.getHeightOffset(1)
			local offset4 = Rendering.getHeightOffset(4)
			assert.is_true(math.abs(offset4) > math.abs(offset1))
		end)

		it("returns -8 per height level", function()
			assert.are.equal(-8, Rendering.getHeightOffset(1))
			assert.are.equal(-16, Rendering.getHeightOffset(2))
			assert.are.equal(-32, Rendering.getHeightOffset(4))
		end)
	end)

	describe("sortByDepth", function()
		it("sorts pieces by row (back to front)", function()
			local pieces = {
				{ row = 3, col = 1 },
				{ row = 1, col = 1 },
				{ row = 2, col = 1 },
			}
			local sorted = Rendering.sortByDepth(pieces)
			assert.are.equal(1, sorted[1].row)
			assert.are.equal(2, sorted[2].row)
			assert.are.equal(3, sorted[3].row)
		end)

		it("sorts by col as secondary", function()
			local pieces = {
				{ row = 2, col = 3 },
				{ row = 2, col = 1 },
				{ row = 2, col = 2 },
			}
			local sorted = Rendering.sortByDepth(pieces)
			assert.are.equal(1, sorted[1].col)
			assert.are.equal(2, sorted[2].col)
			assert.are.equal(3, sorted[3].col)
		end)

		it("does not modify original array", function()
			local pieces = {
				{ row = 3, col = 1 },
				{ row = 1, col = 1 },
			}
			local sorted = Rendering.sortByDepth(pieces)
			assert.are.equal(3, pieces[1].row) -- Original unchanged
			assert.are.equal(1, sorted[1].row) -- Sorted is different
		end)
	end)

	describe("getTileVertices", function()
		it("returns 8 values (4 points x 2 coords)", function()
			local verts = Rendering.getTileVertices(100, 100)
			assert.are.equal(8, #verts)
		end)

		it("creates diamond shape", function()
			local verts = Rendering.getTileVertices(100, 100)
			-- Top point
			assert.are.equal(100, verts[1])
			assert.are.equal(100 - 16, verts[2]) -- y - halfHeight
			-- Right point
			assert.are.equal(100 + 32, verts[3]) -- x + halfWidth
			assert.are.equal(100, verts[4])
		end)
	end)

	describe("getHeightColor", function()
		it("returns RGB values", function()
			local r, g, b = Rendering.getHeightColor(0)
			assert.is_number(r)
			assert.is_number(g)
			assert.is_number(b)
		end)

		it("returns darker color for height 0", function()
			local r0, _, _ = Rendering.getHeightColor(0)
			local r4, _, _ = Rendering.getHeightColor(4)
			assert.is_true(r0 < r4)
		end)

		it("values are in 0-1 range", function()
			for h = 0, 4 do
				local r, g, b = Rendering.getHeightColor(h)
				assert.is_true(r >= 0 and r <= 1)
				assert.is_true(g >= 0 and g <= 1)
				assert.is_true(b >= 0 and b <= 1)
			end
		end)
	end)

	describe("isPointInTile", function()
		it("returns true for point in center", function()
			assert.is_true(Rendering.isPointInTile(100, 100, 100, 100))
		end)

		it("returns false for point outside", function()
			assert.is_false(Rendering.isPointInTile(200, 200, 100, 100))
		end)

		it("returns true for point near edge", function()
			-- Point slightly inside the diamond
			assert.is_true(Rendering.isPointInTile(100, 100 - 10, 100, 100))
		end)
	end)
end)
