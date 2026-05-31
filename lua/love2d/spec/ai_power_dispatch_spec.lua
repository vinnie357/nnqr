-- AI Power Dispatch Tests
-- nnqr-20: Verify Hard/Expert AI dispatches power-activation candidates
-- TDD: these tests are written BEFORE the implementation.

describe("AI Power Dispatch", function()
	local AI
	local GameLogic

	setup(function()
		AI = require("src.shared.ai.ai")
		GameLogic = require("src.shared.game_logic")
	end)

	-- Helper: build a minimal game state (no pieces, no orbs)
	local function emptyState()
		local state = GameLogic.createInitialState()
		state.pieces = {}
		state.orbs = {}
		return state
	end

	-- -------------------------------------------------------------------------
	-- AC1: destroy_row / destroy_column activate when ≥2 enemies in the line
	-- -------------------------------------------------------------------------

	describe("destroy_row activation", function()
		it("hard AI activates destroy_row when ≥2 enemies are in the same row", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			-- AI piece with destroy_row at row 5
			state.pieces = {
				{ row = 3, col = 5, player = 1, powers = {} }, -- enemy (different row, not in line)
				{ row = 5, col = 7, player = 1, powers = {} }, -- enemy in row 5
				{ row = 5, col = 9, player = 1, powers = {} }, -- enemy in row 5 (≥2 in row)
				{ row = 5, col = 3, player = 2, powers = { "destroy_row" } }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move, "Hard AI should return a move")
			-- The move should be a power activation, not just a regular move
			assert.is_not_nil(move.powerId, "Hard AI should activate a power")
			assert.are.equal("destroy_row", move.powerId)
		end)

		it("expert AI activates destroy_row when ≥2 enemies are in the same row", function()
			local ai = AI.create("expert", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 5, col = 6, player = 1, powers = {} }, -- enemy in row 5
				{ row = 5, col = 8, player = 1, powers = {} }, -- enemy in row 5 (≥2)
				{ row = 5, col = 2, player = 2, powers = { "destroy_row" } }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move, "Expert AI should return a move")
			assert.is_not_nil(move.powerId, "Expert AI should activate a power")
			assert.are.equal("destroy_row", move.powerId)
		end)

		it("AI does NOT activate destroy_row when fewer than 2 enemies in row", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 5, col = 6, player = 1, powers = {} }, -- only 1 enemy in row 5
				{ row = 3, col = 5, player = 1, powers = {} }, -- enemy in different row
				{ row = 5, col = 2, player = 2, powers = { "destroy_row" } }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			-- destroy_row heuristic requires ≥2 enemies; should not activate it
			if move and move.powerId then
				assert.are_not.equal("destroy_row", move.powerId)
			end
		end)

		it("AI does NOT activate destroy_row when own pieces would be destroyed", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 5, col = 6, player = 1, powers = {} }, -- enemy in row 5
				{ row = 5, col = 8, player = 1, powers = {} }, -- enemy in row 5
				{ row = 5, col = 4, player = 2, powers = {} }, -- own piece also in row 5!
				{ row = 5, col = 2, player = 2, powers = { "destroy_row" } }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			-- Should not activate destroy_row (ally in same row would die)
			if move and move.powerId then
				assert.are_not.equal("destroy_row", move.powerId)
			end
		end)
	end)

	describe("destroy_column activation", function()
		it("hard AI activates destroy_column when ≥2 enemies are in the same column", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 2, col = 5, player = 1, powers = {} }, -- enemy in col 5
				{ row = 6, col = 5, player = 1, powers = {} }, -- enemy in col 5 (≥2)
				{ row = 4, col = 5, player = 2, powers = { "destroy_column" } }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move, "Hard AI should return a move")
			assert.is_not_nil(move.powerId, "Hard AI should activate a power")
			assert.are.equal("destroy_column", move.powerId)
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC2: jump_proof activates ONLY when the piece is threatened
	-- -------------------------------------------------------------------------

	describe("jump_proof activation", function()
		it("hard AI activates jump_proof when the piece is threatened", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			-- AI piece at 5,5 is directly threatened by enemy at 4,5
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- enemy threatening AI piece
				{ row = 5, col = 5, player = 2, powers = { "jump_proof" } }, -- AI piece with power
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move, "Hard AI should return a move")
			assert.is_not_nil(move.powerId, "Hard AI should activate jump_proof when threatened")
			assert.are.equal("jump_proof", move.powerId)
		end)

		it("AI does NOT activate jump_proof when the piece is NOT threatened", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			-- Enemy is far away — AI piece is safe
			state.pieces = {
				{ row = 1, col = 1, player = 1, powers = {} }, -- enemy far away
				{ row = 5, col = 5, player = 2, powers = { "jump_proof" } }, -- AI piece, safe
			}

			local move = AI.chooseMove(ai, state, {})

			-- jump_proof should NOT be activated when piece is not threatened
			if move and move.powerId then
				assert.are_not.equal("jump_proof", move.powerId)
			end
		end)

		it("AI does NOT activate jump_proof when piece already has isJumpProof flag", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- enemy threatening
				{ row = 5, col = 5, player = 2, powers = { "jump_proof" }, isJumpProof = true }, -- already protected
			}

			local move = AI.chooseMove(ai, state, {})

			-- Should not activate jump_proof again
			if move and move.powerId then
				assert.are_not.equal("jump_proof", move.powerId)
			end
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC3: Power activation does not blow up search time budget
	-- -------------------------------------------------------------------------

	describe("search performance with power candidates", function()
		it("expert AI completes within reasonable time with power candidates", function()
			local ai = AI.create("expert", 2)
			local state = emptyState()
			-- Board with powers and multiple pieces
			state.pieces = {
				{ row = 2, col = 3, player = 1, powers = {} },
				{ row = 2, col = 7, player = 1, powers = {} },
				{ row = 3, col = 5, player = 1, powers = {} },
				{ row = 5, col = 3, player = 2, powers = { "destroy_row", "bomb" } },
				{ row = 5, col = 7, player = 2, powers = { "jump_proof" } },
				{ row = 6, col = 5, player = 2, powers = {} },
			}

			local startTime = os.clock()
			local move = AI.chooseMove(ai, state, {})
			local elapsed = os.clock() - startTime

			assert.is_not_nil(move, "Expert AI must return a move")
			-- Generous budget: 5 seconds. Real expectation is well under 1s for this board.
			assert.is_true(elapsed < 5.0, string.format("Expert AI took %.2fs, expected < 5s", elapsed))
		end)

		it("hard AI completes within reasonable time with power candidates", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 2, col = 3, player = 1, powers = {} },
				{ row = 2, col = 7, player = 1, powers = {} },
				{ row = 5, col = 3, player = 2, powers = { "destroy_row" } },
				{ row = 5, col = 7, player = 2, powers = { "destroy_column" } },
			}

			local startTime = os.clock()
			local move = AI.chooseMove(ai, state, {})
			local elapsed = os.clock() - startTime

			assert.is_not_nil(move, "Hard AI must return a move")
			assert.is_true(elapsed < 5.0, string.format("Hard AI took %.2fs, expected < 5s", elapsed))
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC4: Single-use offensive power NOT activated when no worthwhile target
	-- -------------------------------------------------------------------------

	describe("no wasted power activations", function()
		it("AI does NOT activate bomb when fewer than 2 enemies are in 3x3 range", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			-- Only 1 enemy within bomb range (can just capture normally)
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- only 1 enemy adjacent
				{ row = 1, col = 1, player = 1, powers = {} }, -- enemy far away
				{ row = 5, col = 5, player = 2, powers = { "bomb" } }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			-- Bomb should not be used for single target
			if move and move.powerId then
				assert.are_not.equal("bomb", move.powerId)
			end
		end)

		it("AI does NOT activate destroy_row when no enemies in row", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			-- No enemies in AI piece's row
			state.pieces = {
				{ row = 2, col = 5, player = 1, powers = {} }, -- enemy, different row
				{ row = 8, col = 3, player = 1, powers = {} }, -- enemy, different row
				{ row = 5, col = 5, player = 2, powers = { "destroy_row" } }, -- AI piece, row 5
			}

			local move = AI.chooseMove(ai, state, {})

			if move and move.powerId then
				assert.are_not.equal("destroy_row", move.powerId)
			end
		end)

		it("easy AI never activates powers (movement only)", function()
			local ai = AI.create("easy", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 4, col = 7, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = { "destroy_row", "bomb", "jump_proof" } },
			}

			-- Run 20 times to cover randomness
			for _ = 1, 20 do
				local move = AI.chooseMove(ai, state, {})
				if move then
					assert.is_nil(move.powerId, "Easy AI should not activate powers")
				end
			end
		end)

		it("medium AI never activates powers (movement only)", function()
			local ai = AI.create("medium", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 4, col = 7, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = { "destroy_row", "bomb", "jump_proof" } },
			}

			local move = AI.chooseMove(ai, state, {})
			if move then
				assert.is_nil(move.powerId, "Medium AI should not activate powers")
			end
		end)
	end)

	-- -------------------------------------------------------------------------
	-- Regression: existing movement behavior still works after dispatch addition
	-- -------------------------------------------------------------------------

	describe("existing movement behavior preserved", function()
		it("hard AI still prefers capture when no power is better", function()
			local ai = AI.create("hard", 2)
			local state = emptyState()
			-- AI piece with no useful powers; simple capture scenario
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- no powers
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move)
			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
			assert.is_nil(move.powerId, "No power expected when no powers are held")
		end)

		it("expert AI still prefers capture when no power is better", function()
			local ai = AI.create("expert", 2)
			local state = emptyState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move)
			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
		end)

		it("hard AI returns valid move index for the piece", function()
			local ai = AI.create("hard", 2)
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move)
			assert.is_not_nil(move.piece)
			assert.is_number(move.piece)
			local piece = state.pieces[move.piece]
			assert.is_not_nil(piece, "move.piece must be a valid index into state.pieces")
			assert.are.equal(2, piece.player, "Hard AI should only move its own pieces")
		end)
	end)

	-- -------------------------------------------------------------------------
	-- nnqr-44: Power-then-move integration
	-- Simulates the full AI turn (power + follow-up move) using the underlying
	-- modules, since controller.lua requires the love2d runtime.
	-- -------------------------------------------------------------------------

	describe("power-then-move turn semantics (nnqr-44)", function()
		local PowerExecutor

		setup(function()
			PowerExecutor = require("src.shared.power_executor")
		end)

		it("after chooseMove returns powerId, a second chooseMove on post-power state returns a move", function()
			-- Arrange: hard AI piece with destroy_row, ≥2 enemies in same row.
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.currentPlayer = 2
			state.pieces = {
				{ row = 4, col = 8, player = 1, powers = {} }, -- enemy in row 4
				{ row = 4, col = 9, player = 1, powers = {} }, -- enemy in row 4
				{ row = 1, col = 1, player = 1, powers = {} }, -- safe p1 so game doesn't end
				{ row = 4, col = 1, player = 2, powers = { "destroy_row" } }, -- AI piece
			}

			-- Step 1: first chooseMove returns power activation
			local powerMove = AI.chooseMove(ai, state, {})
			assert.is_not_nil(powerMove, "Hard AI should return a power action")
			assert.is_not_nil(powerMove.powerId, "First chooseMove should return power activation")
			assert.are.equal("destroy_row", powerMove.powerId)

			-- Step 2: apply the power (no endTurn) to get post-power state
			local activatingPiece = state.pieces[powerMove.piece]
			assert.is_not_nil(activatingPiece, "powerMove.piece must be a valid index")
			local postPowerState = PowerExecutor.execute(state, activatingPiece, powerMove.powerId, nil)
			assert.is_not_nil(postPowerState, "PowerExecutor.execute should return a state")

			-- Enemies in row 4 should be destroyed
			local row4Survivors = 0
			for _, p in ipairs(postPowerState.pieces) do
				if p.player == 1 and p.row == 4 then
					row4Survivors = row4Survivors + 1
				end
			end
			assert.are.equal(0, row4Survivors, "destroy_row should eliminate row-4 enemies")

			-- Step 3: second chooseMove on post-power state should return a move (not another power)
			local followMove = AI.chooseMove(ai, postPowerState, {})
			assert.is_not_nil(followMove, "AI should return a follow-up move after power activation")
			assert.is_nil(followMove.powerId, "Second chooseMove should return a board move, not another power")
			assert.is_not_nil(followMove.target, "Follow-up move should have a target")
		end)

		it("chooseMove returns a move (not another power) when called on post-power state", function()
			-- After power fires, AI should have a legal board move available.
			-- This validates the guard: second call must not chain powers indefinitely.
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.currentPlayer = 2
			-- AI piece with destroy_row already used (not in inventory), just a safe state.
			state.pieces = {
				{ row = 1, col = 1, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- no powers left after activation
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move, "AI should return a move on the post-power state")
			-- No powerId — this is a pure movement
			assert.is_nil(move.powerId, "No power expected when piece has no powers")
		end)

		it("turn ends exactly once after power+move (no multi-activation runaway)", function()
			-- Simulate the full power-then-move sequence manually and verify
			-- that endTurn is called exactly once.
			local ai = AI.create("hard", 2)
			local state = emptyState()
			state.currentPlayer = 2
			state.pieces = {
				{ row = 4, col = 8, player = 1, powers = {} },
				{ row = 4, col = 9, player = 1, powers = {} },
				{ row = 1, col = 1, player = 1, powers = {} },
				{ row = 4, col = 1, player = 2, powers = { "destroy_row" } },
			}

			-- Power activation
			local powerMove = AI.chooseMove(ai, state, {})
			assert.is_not_nil(powerMove.powerId)
			local piece = state.pieces[powerMove.piece]
			local postPower = PowerExecutor.execute(state, piece, powerMove.powerId, nil)

			-- Follow-up move
			local followMove = AI.chooseMove(ai, postPower, {})
			assert.is_not_nil(followMove)

			-- Apply the follow-up move
			local movePiece = postPower.pieces[followMove.piece]
			assert.is_not_nil(movePiece, "Follow move piece must be valid index")
			GameLogic.movePiece(postPower, movePiece, followMove.target.row, followMove.target.col)

			-- End turn exactly once
			local turnBefore = postPower.turn
			local afterTurn = GameLogic.endTurn(postPower)
			-- Turn should have incremented by 1
			assert.are.equal(turnBefore + 1, afterTurn.turn, "Turn incremented exactly once")
			-- Current player should have flipped
			assert.are.equal(1, afterTurn.currentPlayer, "Current player flipped to 1 after AI turn")
		end)
	end)
end)
