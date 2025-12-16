-- Tests for PowerExecutor special targeted power dispatch
-- Phase 9B-H: Special Targeted Powers (2 powers)

describe("PowerExecutor - Special Targeted Powers", function()
	local PowerExecutor, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)

	describe("hotspot_teleport", function()
		it("teleports piece to target hotspot tile", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "hotspot")
			-- Mark target as a hotspot tile
			state.hotspots = state.hotspots or {}
			state.hotspots["1,1"] = true
			local target = { row = 1, col = 1 }

			state = PowerExecutor.execute(state, piece, "hotspot_teleport", target)

			-- Piece teleported to target
			assert.are.equal(1, piece.row)
			assert.are.equal(1, piece.col)
			-- Power consumed
			assert.is_false(H.powers.hasPower(piece, "hotspot"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("hotspot_teleport", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("centerpult", function()
		it("moves piece to 2x2 corner and destroys occupant", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 5, 1)
			H.powers.givePower(piece, "centerpult")
			-- Create a 2x2 formation with an enemy at target corner
			local enemy = H.pieces.addPiece(state, 1, 1, 2)
			H.pieces.addPiece(state, 1, 2, 2)
			H.pieces.addPiece(state, 2, 1, 2)
			H.pieces.addPiece(state, 2, 2, 2)
			local target = { row = 1, col = 1 }

			local initialCount = #state.pieces
			state = PowerExecutor.execute(state, piece, "centerpult", target)

			-- Piece moved to target
			assert.are.equal(1, piece.row)
			assert.are.equal(1, piece.col)
			-- Enemy at target destroyed
			assert.are.equal(initialCount - 1, #state.pieces)
			-- Power consumed
			assert.is_false(H.powers.hasPower(piece, "centerpult"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("centerpult", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)
end)
