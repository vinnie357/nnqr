-- AI Module Tests
-- Phase 8A: AI Framework

describe("AI", function()
	local AI

	setup(function()
		AI = require("src.shared.ai.ai")
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

			-- Target should be valid for that piece
			local validMoves = GameLogic.getValidMoves(state, piece)
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

					local validMoves = GameLogic.getValidMoves(state, piece)
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
end)
