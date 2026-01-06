-- Indicators Module Tests
-- Tests for piece visual indicator tracking

package.path = package.path .. ";./?.lua;./?/init.lua"

describe("Indicators", function()
	local Indicators

	setup(function()
		Indicators = require("src.shared.indicators")
	end)

	describe("getPieceIndicators", function()
		it("returns empty table for piece with no flags", function()
			local piece = { row = 1, col = 1, player = 1 }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.same({}, indicators)
		end)

		it("returns jump_proof when piece.isJumpProof is true", function()
			local piece = { row = 1, col = 1, player = 1, isJumpProof = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("jump_proof", indicators[1])
		end)

		it("returns move_diagonal when piece.canMoveDiagonally is true", function()
			local piece = { row = 1, col = 1, player = 1, canMoveDiagonally = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("move_diagonal", indicators[1])
		end)

		it("returns invisible when piece.isInvisible is true", function()
			local piece = { row = 1, col = 1, player = 1, isInvisible = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("invisible", indicators[1])
		end)

		it("returns multiple indicators when piece has multiple flags", function()
			local piece = {
				row = 1,
				col = 1,
				player = 1,
				isJumpProof = true,
				canMoveDiagonally = true,
			}
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(2, #indicators)

			-- Check both are present (order may vary)
			local hasJumpProof = false
			local hasMoveDiagonal = false
			for _, ind in ipairs(indicators) do
				if ind == "jump_proof" then
					hasJumpProof = true
				end
				if ind == "move_diagonal" then
					hasMoveDiagonal = true
				end
			end
			assert.is_true(hasJumpProof)
			assert.is_true(hasMoveDiagonal)
		end)

		it("returns climb_tile when piece.canClimbAny is true", function()
			local piece = { row = 1, col = 1, player = 1, canClimbAny = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("climb_tile", indicators[1])
		end)

		it("returns flat_to_sphere when piece.canWrap is true", function()
			local piece = { row = 1, col = 1, player = 1, canWrap = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("flat_to_sphere", indicators[1])
		end)

		it("returns beneficiary when piece.isBeneficiary is true", function()
			local piece = { row = 1, col = 1, player = 1, isBeneficiary = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("beneficiary", indicators[1])
		end)

		it("returns scavenger when piece.isScavenger is true", function()
			local piece = { row = 1, col = 1, player = 1, isScavenger = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("scavenger", indicators[1])
		end)

		it("returns tripwire when piece.isTripwired is true", function()
			local piece = { row = 1, col = 1, player = 1, isTripwired = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("tripwire", indicators[1])
		end)

		it("returns inhibited when piece.isInhibited is true", function()
			local piece = { row = 1, col = 1, player = 1, isInhibited = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("inhibited", indicators[1])
		end)

		it("returns multiplied when piece.isMultiplied is true", function()
			local piece = { row = 1, col = 1, player = 1, isMultiplied = true }
			local indicators = Indicators.getPieceIndicators(piece)
			assert.are.equal(1, #indicators)
			assert.are.equal("multiplied", indicators[1])
		end)
	end)
end)
