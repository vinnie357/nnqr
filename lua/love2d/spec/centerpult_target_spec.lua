-- Regression: centerpult (targeting="special") crashed when activated without a
-- target because the activation flow skipped target-selection. The effect now
-- no-ops safely on a missing target (defense in depth); the controller fix wires
-- centerpult into targeting mode so a target is always supplied in normal play.

describe("centerpult - missing target safety", function()
	local PowerEffects, PowerExecutor, H

	setup(function()
		PowerEffects = require("src.shared.power_effects")
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)

	it("does not crash when executed with a nil target", function()
		local state = H.state.createEmptyState()
		local piece = H.pieces.addPiece(state, 4, 5, 1)
		H.powers.givePower(piece, "centerpult")

		local result
		assert.has_no.errors(function()
			result = PowerExecutor.execute(state, piece, "centerpult", nil)
		end)

		-- No-op: piece unmoved and power retained (nothing happened).
		assert.is_truthy(result)
		assert.are.equal(4, piece.row)
		assert.are.equal(5, piece.col)
		assert.are.equal(1, H.powers.countPowers(piece, "centerpult"))
	end)

	it("still works normally with a valid target", function()
		local state = H.state.createEmptyState()
		local piece = H.pieces.addPiece(state, 4, 5, 1)
		H.powers.givePower(piece, "centerpult")

		state = PowerExecutor.execute(state, piece, "centerpult", { row = 2, col = 2 })

		assert.are.equal(2, piece.row)
		assert.are.equal(2, piece.col)
		assert.are.equal(0, H.powers.countPowers(piece, "centerpult"))
	end)
end)
