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

		it("actually moves orbs to new positions", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 5, 1)
			H.powers.givePower(piece, "orbic_rehash")

			-- Add orbs at known positions in a cluster
			H.orbs.addOrb(state, 1, 1, "bomb")
			H.orbs.addOrb(state, 1, 2, "recruit")
			H.orbs.addOrb(state, 1, 3, "multiply")

			-- Record original positions
			local originalPositions = {}
			for _, orb in ipairs(state.orbs) do
				originalPositions[orb.row .. "," .. orb.col] = true
			end

			-- Execute power
			state = PowerExecutor.execute(state, piece, "orbic_rehash")

			-- Count how many orbs are still in original positions
			local samePositionCount = 0
			for _, orb in ipairs(state.orbs) do
				if originalPositions[orb.row .. "," .. orb.col] then
					samePositionCount = samePositionCount + 1
				end
			end

			-- With 80 empty tiles and 3 orbs, probability all 3 land in same spots is tiny
			-- At least one orb should have moved (statistically near-certain)
			assert.is_true(samePositionCount < 3, "Expected at least one orb to move to a new position")
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
