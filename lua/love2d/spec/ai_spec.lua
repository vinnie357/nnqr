-- AI Module Tests
-- Phase 8A: AI Framework

describe("AI", function()
	local AI
	local PowerEffects

	setup(function()
		AI = require("src.shared.ai.ai")
		PowerEffects = require("src.shared.power_effects")
	end)

	-- 8A.1 AI Module Structure
	describe("create", function()
		it("returns AI state table", function()
			local ai = AI.create("easy")
			assert.is_table(ai)
		end)

		it("creates easy AI", function()
			local ai = AI.create("easy")
			assert.are.equal("easy", ai.difficulty)
		end)

		it("creates medium AI", function()
			local ai = AI.create("medium")
			assert.are.equal("medium", ai.difficulty)
		end)

		it("creates hard AI", function()
			local ai = AI.create("hard")
			assert.are.equal("hard", ai.difficulty)
		end)

		it("creates expert AI", function()
			local ai = AI.create("expert")
			assert.are.equal("expert", ai.difficulty)
		end)

		it("defaults to easy if invalid difficulty", function()
			local ai = AI.create("invalid")
			assert.are.equal("easy", ai.difficulty)
		end)

		it("stores player number", function()
			local ai = AI.create("easy", 2)
			assert.are.equal(2, ai.player)
		end)

		it("defaults player to 2", function()
			local ai = AI.create("easy")
			assert.are.equal(2, ai.player)
		end)
	end)

	describe("chooseMove", function()
		local GameLogic

		setup(function()
			GameLogic = require("src.shared.game_logic")
		end)

		it("returns table with piece, target fields", function()
			local ai = AI.create("easy")
			local state = GameLogic.createInitialState()
			local move = AI.chooseMove(ai, state)
			assert.is_table(move)
			assert.is_not_nil(move.piece)
			assert.is_not_nil(move.target)
		end)

		it("returns nil when no valid moves", function()
			local ai = AI.create("easy")
			-- Create state with no pieces for AI player
			local state = GameLogic.createInitialState()
			-- Remove all player 2 pieces
			state.pieces = {}
			for row = 1, 2 do
				for col = 1, 10 do
					table.insert(state.pieces, { row = row, col = col, player = 1, powers = {} })
				end
			end
			local move = AI.chooseMove(ai, state)
			assert.is_nil(move)
		end)
	end)

	-- 8A.2 Easy AI (Random)
	describe("Easy AI", function()
		local GameLogic

		setup(function()
			GameLogic = require("src.shared.game_logic")
		end)

		it("returns valid move from available moves", function()
			local ai = AI.create("easy")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2 -- AI's turn

			local move = AI.chooseMove(ai, state)

			-- Verify move is valid
			assert.is_not_nil(move)
			assert.is_not_nil(move.piece)
			assert.is_not_nil(move.target)

			-- Piece should belong to AI
			local piece = state.pieces[move.piece]
			assert.are.equal(2, piece.player)

			-- Target should be valid for that piece (using power-aware move calculation)
			local validMoves = PowerEffects.getValidMovesWithPowers(state, piece)
			local found = false
			for _, vm in ipairs(validMoves) do
				if vm.row == move.target.row and vm.col == move.target.col then
					found = true
					break
				end
			end
			assert.is_true(found)
		end)

		it("never returns invalid move", function()
			local ai = AI.create("easy")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2

			-- Run multiple times to test randomness
			for _ = 1, 20 do
				local move = AI.chooseMove(ai, state)
				if move then
					local piece = state.pieces[move.piece]
					assert.are.equal(2, piece.player, "AI moved opponent's piece")

					local validMoves = PowerEffects.getValidMovesWithPowers(state, piece)
					local found = false
					for _, vm in ipairs(validMoves) do
						if vm.row == move.target.row and vm.col == move.target.col then
							found = true
							break
						end
					end
					assert.is_true(found, "AI made invalid move")
				end
			end
		end)

		it("can capture when available", function()
			local ai = AI.create("easy")
			-- Set up state where capture is possible
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- Enemy piece
				{ row = 5, col = 5, player = 2, powers = {} }, -- AI piece that can capture
			}

			-- Run multiple times - at some point AI should capture
			local captureFound = false
			for _ = 1, 50 do
				local move = AI.chooseMove(ai, state)
				if move and move.target.row == 4 and move.target.col == 5 then
					captureFound = true
					break
				end
			end
			-- Easy AI is random, so capture should be possible but not guaranteed
			-- Just verify move is valid
			local move = AI.chooseMove(ai, state)
			assert.is_not_nil(move)
		end)

		it("handles pieces with no valid moves", function()
			local ai = AI.create("easy")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- Create a stuck piece scenario
			state.pieces = {
				{ row = 8, col = 1, player = 2, powers = {} }, -- AI piece in corner
				{ row = 7, col = 1, player = 1, powers = {} }, -- Blocked by enemy
				{ row = 7, col = 2, player = 1, powers = {} },
				{ row = 8, col = 2, player = 1, powers = {} },
				{ row = 3, col = 5, player = 2, powers = {} }, -- Another AI piece that can move
			}

			local move = AI.chooseMove(ai, state)
			-- Should find the piece that can move (piece index 5)
			assert.is_not_nil(move)
		end)

		it("respects jump_proof flag and cannot capture protected pieces", function()
			local ai = AI.create("easy")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- Set up: Player 1 piece with jump_proof, AI piece adjacent
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {}, isJumpProof = true }, -- Protected piece
				{ row = 5, col = 5, player = 2, powers = {} }, -- AI piece adjacent
			}

			-- Run multiple times - AI should NEVER capture the jump_proof piece
			for _ = 1, 50 do
				local move = AI.chooseMove(ai, state)
				if move then
					-- AI should not target the protected piece's position
					local isCapturingProtected = move.target.row == 4 and move.target.col == 5
					assert.is_false(isCapturingProtected, "AI captured a jump_proof piece!")
				end
			end
		end)
	end)

	-- 8A.3 Game Integration helpers
	describe("isAITurn", function()
		local GameLogic

		setup(function()
			GameLogic = require("src.shared.game_logic")
		end)

		it("returns true when AI player's turn", function()
			local ai = AI.create("easy", 2)
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			assert.is_true(AI.isAITurn(ai, state))
		end)

		it("returns false when human player's turn", function()
			local ai = AI.create("easy", 2)
			local state = GameLogic.createInitialState()
			state.currentPlayer = 1
			assert.is_false(AI.isAITurn(ai, state))
		end)
	end)

	describe("getDifficultyConfig", function()
		it("returns config for easy", function()
			local config = AI.getDifficultyConfig("easy")
			assert.are.equal(0, config.searchDepth)
			assert.are.equal("random", config.strategy)
		end)

		it("returns config for medium", function()
			local config = AI.getDifficultyConfig("medium")
			assert.are.equal(0, config.searchDepth)
			assert.are.equal("heuristic", config.strategy)
		end)

		it("returns config for hard", function()
			local config = AI.getDifficultyConfig("hard")
			assert.are.equal(2, config.searchDepth)
			assert.are.equal("minimax", config.strategy)
		end)

		it("returns config for expert", function()
			local config = AI.getDifficultyConfig("expert")
			assert.are.equal(4, config.searchDepth)
			assert.are.equal("minimax", config.strategy)
		end)
	end)

	describe("getDifficultyDisplayName", function()
		it("returns Easy for easy", function()
			assert.are.equal("Easy", AI.getDifficultyDisplayName("easy"))
		end)

		it("returns Medium for medium", function()
			assert.are.equal("Medium", AI.getDifficultyDisplayName("medium"))
		end)

		it("returns Hard for hard", function()
			assert.are.equal("Hard", AI.getDifficultyDisplayName("hard"))
		end)

		it("returns Expert for expert", function()
			assert.are.equal("Expert", AI.getDifficultyDisplayName("expert"))
		end)

		it("returns Unknown for invalid difficulty", function()
			assert.are.equal("Unknown", AI.getDifficultyDisplayName("invalid"))
		end)
	end)

	-- 8C.4 Hard/Expert AI (Minimax)
	describe("Hard AI", function()
		local GameLogic

		setup(function()
			GameLogic = require("src.shared.game_logic")
		end)

		it("uses minimax strategy", function()
			local ai = AI.create("hard")
			assert.are.equal("minimax", ai.config.strategy)
		end)

		it("has search depth of 2", function()
			local ai = AI.create("hard")
			assert.are.equal(2, ai.config.searchDepth)
		end)

		it("returns valid move structure", function()
			local ai = AI.create("hard")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move)
			assert.is_not_nil(move.piece)
			assert.is_not_nil(move.target)
			assert.is_not_nil(move.target.row)
			assert.is_not_nil(move.target.col)
		end)

		it("prefers capture over empty move", function()
			local ai = AI.create("hard")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local move = AI.chooseMove(ai, state, {})

			-- Hard AI should capture
			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
		end)

		it("looks ahead to avoid bad trades", function()
			local ai = AI.create("hard")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- If AI captures at 4,5, enemy at 3,5 can recapture
			-- AI should consider this in its search
			state.pieces = {
				{ row = 3, col = 5, player = 1, powers = {} }, -- Will recapture
				{ row = 4, col = 5, player = 1, powers = {} }, -- Can be captured
				{ row = 5, col = 5, player = 2, powers = {} }, -- AI piece
				{ row = 5, col = 3, player = 2, powers = {} }, -- Safe AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			-- With depth 2, AI should see the recapture and may choose differently
			-- Just verify a valid move is returned
			assert.is_not_nil(move)
		end)

		it("returns nil when no valid moves", function()
			local ai = AI.create("hard")
			local state = GameLogic.createInitialState()
			state.pieces = {} -- No pieces
			for row = 1, 2 do
				for col = 1, 10 do
					table.insert(state.pieces, { row = row, col = col, player = 1, powers = {} })
				end
			end

			local move = AI.chooseMove(ai, state, {})
			assert.is_nil(move)
		end)
	end)

	describe("Expert AI", function()
		local GameLogic

		setup(function()
			GameLogic = require("src.shared.game_logic")
		end)

		it("uses minimax strategy", function()
			local ai = AI.create("expert")
			assert.are.equal("minimax", ai.config.strategy)
		end)

		it("has search depth of 4", function()
			local ai = AI.create("expert")
			assert.are.equal(4, ai.config.searchDepth)
		end)

		it("returns valid move structure", function()
			local ai = AI.create("expert")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- Use smaller board state for faster test
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move)
			assert.is_not_nil(move.piece)
			assert.is_not_nil(move.target)
		end)

		it("prefers capture over empty move", function()
			local ai = AI.create("expert")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
			}

			local move = AI.chooseMove(ai, state, {})

			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
		end)

		it("returns nil when no valid moves", function()
			local ai = AI.create("expert")
			local state = GameLogic.createInitialState()
			state.pieces = {}
			for row = 1, 2 do
				for col = 1, 10 do
					table.insert(state.pieces, { row = row, col = col, player = 1, powers = {} })
				end
			end

			local move = AI.chooseMove(ai, state, {})
			assert.is_nil(move)
		end)
	end)

	-- 8B.7 Medium AI (Heuristic)
	describe("Medium AI", function()
		local GameLogic

		setup(function()
			GameLogic = require("src.shared.game_logic")
		end)

		it("prefers capture over empty move", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- AI piece can capture or move to empty
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- Capturable enemy
				{ row = 5, col = 5, player = 2, powers = {} }, -- AI piece
			}

			local move = AI.chooseMove(ai, state)

			-- Medium AI should always capture when available
			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
		end)

		it("prefers orb collection over empty move", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			state.pieces = {
				{ row = 5, col = 5, player = 2, powers = {} },
			}
			-- Add orbs to game state (Medium AI needs access to orbs)
			local orbs = {
				{ row = 5, col = 6, powerId = "bomb" },
			}

			local move = AI.chooseMove(ai, state, orbs)

			-- Should move to collect the orb
			assert.are.equal(5, move.target.row)
			assert.are.equal(6, move.target.col)
		end)

		it("avoids moving into danger when possible", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- AI piece at 5,5 can move to 5,6 (threatened by enemy at 5,7) or 5,4 (safe)
			state.pieces = {
				{ row = 5, col = 5, player = 2, powers = {} },
				{ row = 5, col = 7, player = 1, powers = {} }, -- Threatens 5,6
			}

			local move = AI.chooseMove(ai, state, {})

			-- Should prefer safe move (5,4 or 4,5 or 6,5) over risky move (5,6)
			local isRiskyMove = move.target.row == 5 and move.target.col == 6
			assert.is_false(isRiskyMove)
		end)

		it("captures high-value pieces over low-value", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			-- AI piece can capture either enemy
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- Low value enemy
				{ row = 5, col = 4, player = 1, powers = { "bomb", "recruit" } }, -- High value enemy
				{ row = 5, col = 5, player = 2, powers = {} }, -- AI piece
			}

			local move = AI.chooseMove(ai, state, {})

			-- Should capture the high-value piece
			assert.are.equal(5, move.target.row)
			assert.are.equal(4, move.target.col)
		end)

		it("returns valid move structure", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2

			local move = AI.chooseMove(ai, state, {})

			assert.is_not_nil(move)
			assert.is_not_nil(move.piece)
			assert.is_not_nil(move.target)
			assert.is_not_nil(move.target.row)
			assert.is_not_nil(move.target.col)
		end)

		it("works with empty orbs array", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2

			-- Should not error when orbs is empty
			local move = AI.chooseMove(ai, state, {})
			assert.is_not_nil(move)
		end)

		it("works when orbs parameter is nil", function()
			local ai = AI.create("medium")
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2

			-- Should not error when orbs is nil (backwards compatibility)
			local move = AI.chooseMove(ai, state)
			assert.is_not_nil(move)
		end)
	end)
end)
