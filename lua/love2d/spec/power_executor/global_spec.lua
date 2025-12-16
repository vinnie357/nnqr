-- Tests for PowerExecutor global power dispatch
-- Phase 9B-G: Global Powers (2 powers)

describe("PowerExecutor - Global Powers", function()
	local PowerExecutor, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)

	describe("orbic_rehash", function()
		it("reshuffles all orbs on the board", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "orbic_rehash")
			-- Add some orbs
			H.orbs.addOrb(state, 1, 1, "bomb")
			H.orbs.addOrb(state, 2, 2, "recruit")
			H.orbs.addOrb(state, 5, 5, "multiply")

			-- Just verify it runs without error and power is removed
			state = PowerExecutor.execute(state, piece, "orbic_rehash")

			-- Orbs should still exist (count unchanged)
			assert.are.equal(3, #state.orbs)
			assert.is_false(H.powers.hasPower(piece, "orbic_rehash"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("orbic_rehash", piece)
			assert.are.equal("power_global", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("cancel_multiply", function()
		it("removes all multiplied pieces globally", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "cancel_multiply")

			-- Add some multiplied pieces
			local p1 = H.pieces.addPiece(state, 1, 1, 1)
			p1.isMultiplied = true
			local p2 = H.pieces.addPiece(state, 2, 2, 2)
			p2.isMultiplied = true
			local normal = H.pieces.addPiece(state, 4, 4, 1) -- not multiplied

			local initialCount = #state.pieces

			state = PowerExecutor.execute(state, piece, "cancel_multiply")

			-- Multiplied pieces removed
			assert.are.equal(initialCount - 2, #state.pieces)
			-- Normal pieces still exist
			local foundNormal = false
			local foundActivator = false
			for _, p in ipairs(state.pieces) do
				if p == normal then
					foundNormal = true
				end
				if p == piece then
					foundActivator = true
				end
			end
			assert.is_true(foundNormal)
			assert.is_true(foundActivator)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("cancel_multiply", piece)
			assert.are.equal("power_global", animType)
			assert.is_true(blocking)
		end)
	end)
end)
