-- Tests that PowerExecutor's dispatch stays in sync with Powers.definitions.
-- Guards the drift class where a power gains a definition but no handler (or a
-- handler exists with no backing definition) -- the centerpult/hotspot bug.

describe("PowerExecutor - dispatch completeness", function()
	local PowerExecutor, Powers, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		Powers = require("src.shared.powers")
		H = require("spec.helpers.init")
	end)

	-- Dispatchable ids that are deliberately NOT standalone power definitions.
	local SECONDARY_ACTIONS = { hotspot_teleport = true }

	it("registers a handler for every defined power", function()
		for id in pairs(Powers.definitions) do
			assert.is_true(PowerExecutor.isRegistered(id), "missing dispatch handler for power: " .. id)
		end
	end)

	it("has no orphan handlers lacking a definition or known secondary action", function()
		for _, id in ipairs(PowerExecutor.registeredIds()) do
			local known = Powers.definitions[id] ~= nil or SECONDARY_ACTIONS[id] == true
			assert.is_true(known, "dispatch handler has no backing power definition: " .. id)
		end
	end)

	it("registers exactly the defined powers plus known secondary actions", function()
		local expected = 0
		for _ in pairs(Powers.definitions) do
			expected = expected + 1
		end
		for _ in pairs(SECONDARY_ACTIONS) do
			expected = expected + 1
		end
		assert.are.equal(expected, #PowerExecutor.registeredIds())
	end)

	it("routes execute() to a real effect (not a silent no-op)", function()
		-- Activating jump_proof sets the isJumpProof flag and consumes the power.
		local state = H.state.createEmptyState()
		local piece = H.pieces.addPiece(state, 4, 5, 1)
		H.powers.givePower(piece, "jump_proof")
		state = PowerExecutor.execute(state, piece, "jump_proof", nil)
		assert.is_true(piece.isJumpProof)
		assert.are.equal(0, Powers.countPowerById(piece, "jump_proof"))
	end)
end)
