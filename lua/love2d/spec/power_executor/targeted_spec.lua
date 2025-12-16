-- Tests for PowerExecutor targeted power dispatch
-- Phase 9B-F: Targeted Powers (6 powers)

describe("PowerExecutor - Targeted Powers", function()
	local PowerExecutor, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)

	describe("raise_tile", function()
		it("raises target tile height by 1", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "raise_tile")
			H.terrain.setHeight(state, 2, 5, 1)
			local target = { row = 2, col = 5 }

			state = PowerExecutor.execute(state, piece, "raise_tile", target)

			assert.are.equal(2, H.terrain.getHeight(state, 2, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("raise_tile", piece)
			assert.are.equal("power_self", animType) -- targeted uses self anim
			assert.is_true(blocking)
		end)
	end)

	describe("lower_tile", function()
		it("lowers target tile height by 1", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "lower_tile")
			H.terrain.setHeight(state, 2, 5, 2)
			local target = { row = 2, col = 5 }

			state = PowerExecutor.execute(state, piece, "lower_tile", target)

			assert.are.equal(1, H.terrain.getHeight(state, 2, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("lower_tile", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("recruit", function()
		it("converts adjacent enemy piece to ally", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "recruit")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			local target = { row = 2, col = 5 }

			state = PowerExecutor.execute(state, piece, "recruit", target)

			-- Enemy converted to player 1
			assert.are.equal(1, enemy.player)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("recruit", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("multiply", function()
		it("creates new piece at adjacent empty tile", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "multiply")
			local target = { row = 2, col = 5 }

			local initialCount = #state.pieces
			state = PowerExecutor.execute(state, piece, "multiply", target)

			-- New piece created
			assert.are.equal(initialCount + 1, #state.pieces)
			-- Find new piece at target
			local newPiece = nil
			for _, p in ipairs(state.pieces) do
				if p.row == 2 and p.col == 5 then
					newPiece = p
					break
				end
			end
			assert.is_not_nil(newPiece)
			assert.are.equal(1, newPiece.player)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("multiply", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("refurb", function()
		it("repairs a single destroyed tile", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "refurb")
			H.terrain.destroyTile(state, 2, 5)
			local target = { row = 2, col = 5 }

			state = PowerExecutor.execute(state, piece, "refurb", target)

			assert.is_nil(state.destroyedTiles["2,5"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("refurb", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("switcheroo", function()
		it("swaps positions with target piece", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "switcheroo")
			local other = H.pieces.addPiece(state, 2, 5, 2)
			local target = { row = 2, col = 5 }

			state = PowerExecutor.execute(state, piece, "switcheroo", target)

			-- Positions swapped
			assert.are.equal(2, piece.row)
			assert.are.equal(5, piece.col)
			assert.are.equal(3, other.row)
			assert.are.equal(5, other.col)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("switcheroo", piece)
			assert.are.equal("power_self", animType)
			assert.is_true(blocking)
		end)
	end)
end)
