-- AI Evaluator Module Tests
-- Phase 8B: Rule-Based AI

describe("Evaluator", function()
	local Evaluator
	local GameLogic

	setup(function()
		Evaluator = require("src.shared.ai.evaluator")
		GameLogic = require("src.shared.game_logic")
	end)

	-- 8B.1 Threat Detection
	describe("getThreatenedPieces", function()
		it("returns empty table when no threats exist", function()
			local state = GameLogic.createInitialState()
			-- Initial board setup has no adjacent enemy pieces
			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(0, #threatened)
		end)

		it("finds single threatened piece", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 1 piece at (4,5), Player 2 piece at (5,5) can capture it
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(1, #threatened)
			assert.are.equal(4, threatened[1].row)
			assert.are.equal(5, threatened[1].col)
		end)

		it("finds multiple threatened pieces", function()
			local state = GameLogic.createInitialState()
			-- Setup: Two Player 1 pieces that can be captured
			state.pieces = {
				{ row = 4, col = 3, player = 1, powers = {} }, -- Threatened by piece at 5,3
				{ row = 4, col = 7, player = 1, powers = {} }, -- Threatened by piece at 5,7
				{ row = 5, col = 3, player = 2, powers = {} },
				{ row = 5, col = 7, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(2, #threatened)
		end)

		it("respects jump_proof flag", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 1 piece with jump_proof, Player 2 adjacent
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {}, isJumpProof = true },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(0, #threatened) -- Protected piece not threatened
		end)

		it("does not include duplicates when multiple enemies can capture same piece", function()
			local state = GameLogic.createInitialState()
			-- Setup: One Player 1 piece that can be captured by two Player 2 pieces
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- Can capture
				{ row = 4, col = 6, player = 2, powers = {} }, -- Can also capture
			}

			local threatened = Evaluator.getThreatenedPieces(state, 1)
			assert.are.equal(1, #threatened) -- Only one entry, not duplicated
		end)

		it("works for player 2 as well", function()
			local state = GameLogic.createInitialState()
			-- Setup: Player 2 piece threatened by Player 1
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local threatened = Evaluator.getThreatenedPieces(state, 2)
			assert.are.equal(1, #threatened)
			assert.are.equal(5, threatened[1].row)
			assert.are.equal(5, threatened[1].col)
		end)
	end)
end)
