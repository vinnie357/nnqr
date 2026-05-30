-- Coverage for the overheat mechanic: a piece holding OVERHEAT_THRESHOLD (10)
-- copies of the same power explodes. Used by the game loop in executeAIMove.

describe("Powers - overheat", function()
	local Powers

	setup(function()
		Powers = require("src.shared.powers")
	end)

	local function pieceWith(powers)
		return { row = 1, col = 1, player = 1, powers = powers }
	end

	it("threshold is 10", function()
		assert.are.equal(10, Powers.OVERHEAT_THRESHOLD)
	end)

	describe("countPowerById", function()
		it("returns 0 for a piece with no powers", function()
			assert.are.equal(0, Powers.countPowerById({}, "bomb"))
		end)

		it("counts repeated copies of a power", function()
			local piece = pieceWith({ "bomb", "bomb", "moat", "bomb" })
			assert.are.equal(3, Powers.countPowerById(piece, "bomb"))
			assert.are.equal(1, Powers.countPowerById(piece, "moat"))
			assert.are.equal(0, Powers.countPowerById(piece, "relocate"))
		end)
	end)

	describe("checkOverheat", function()
		it("returns nil for a piece with no powers", function()
			assert.is_nil(Powers.checkOverheat({}))
		end)

		it("returns nil below the threshold", function()
			local powers = {}
			for _ = 1, Powers.OVERHEAT_THRESHOLD - 1 do
				table.insert(powers, "bomb")
			end
			assert.is_nil(Powers.checkOverheat(pieceWith(powers)))
		end)

		it("returns the power id at exactly the threshold", function()
			local powers = {}
			for _ = 1, Powers.OVERHEAT_THRESHOLD do
				table.insert(powers, "bomb")
			end
			assert.are.equal("bomb", Powers.checkOverheat(pieceWith(powers)))
		end)

		it("does not overheat when copies are spread across different powers", function()
			-- 5 bomb + 5 moat: neither id reaches the per-id threshold of 10.
			local powers = { "bomb", "bomb", "bomb", "bomb", "bomb", "moat", "moat", "moat", "moat", "moat" }
			assert.is_nil(Powers.checkOverheat(pieceWith(powers)))
		end)
	end)
end)
