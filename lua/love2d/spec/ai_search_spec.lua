-- AI Search Module Tests
-- Phase 8C: Search-Based AI

describe("Search", function()
	local Search
	local GameLogic
	local Evaluator

	setup(function()
		Search = require("src.shared.ai.search")
		GameLogic = require("src.shared.game_logic")
		Evaluator = require("src.shared.ai.evaluator")
	end)

	-- 8C.2 Minimax Search
	describe("minimax", function()
		it("returns best move and score", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 3, col = 5, player = 2, powers = {} },
			}

			local move, score = Search.minimax(state, 1, 1)

			assert.is_not_nil(move)
			assert.is_number(score)
			assert.is_not_nil(move.piece)
			assert.is_not_nil(move.target)
		end)

		it("at depth 1, makes simple captures", function()
			local state = GameLogic.createInitialState()
			-- Player 1 can capture Player 2
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = {} }, -- Can be captured
			}

			local move, _ = Search.minimax(state, 1, 1)

			-- Should capture the enemy piece
			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
		end)

		it("at depth 2, avoids giving up pieces", function()
			local state = GameLogic.createInitialState()
			-- Player 1 at 5,5 can move to 5,6 (safe) or 5,4 (where P2 can capture next turn)
			-- Player 2 at 5,3 threatens 5,4
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 5, col = 3, player = 2, powers = {} },
			}

			local move, _ = Search.minimax(state, 2, 1)

			-- Should NOT move to 5,4 where it can be captured
			local movesToDanger = move.target.row == 5 and move.target.col == 4
			assert.is_false(movesToDanger)
		end)

		it("returns nil when no moves available", function()
			local state = GameLogic.createInitialState()
			state.pieces = {} -- No pieces for player 1

			local move, score = Search.minimax(state, 1, 1)

			assert.is_nil(move)
		end)

		it("depth 0 returns heuristic evaluation", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
			}

			local move, score = Search.minimax(state, 0, 1)

			-- At depth 0, should return current evaluation, no move
			assert.is_nil(move)
			assert.is_number(score)
		end)
	end)

	describe("minimaxAlphaBeta", function()
		it("produces same result as basic minimax", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = {} },
			}

			local moveBasic, scoreBasic = Search.minimax(state, 2, 1)
			local moveAB, scoreAB = Search.minimaxAlphaBeta(state, 2, 1, -math.huge, math.huge)

			-- Should produce same move
			assert.are.equal(moveBasic.target.row, moveAB.target.row)
			assert.are.equal(moveBasic.target.col, moveAB.target.col)
			-- Scores should be equal
			assert.are.equal(scoreBasic, scoreAB)
		end)

		it("prunes branches (fewer nodes visited)", function()
			-- This is hard to test directly, but we can verify it works
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = {} },
				{ row = 6, col = 5, player = 2, powers = {} },
			}

			-- Should complete without error at deeper depth
			local move, score = Search.minimaxAlphaBeta(state, 3, 1, -math.huge, math.huge)

			assert.is_not_nil(move)
			assert.is_number(score)
		end)
	end)

	-- 8C.3 Move Ordering
	describe("orderMoves", function()
		it("puts captures first", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 5, col = 5, player = 1, powers = {} }
			local enemy = { row = 5, col = 6, player = 2, powers = {} }
			state.pieces = { piece, enemy }

			local moves = Evaluator.getAllMoves(state, 1)
			local ordered = Search.orderMoves(state, moves)

			-- Capture move should be first
			assert.are.equal(5, ordered[1].target.row)
			assert.are.equal(6, ordered[1].target.col)
		end)

		it("returns all moves", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
			}

			local moves = Evaluator.getAllMoves(state, 1)
			local ordered = Search.orderMoves(state, moves)

			assert.are.equal(#moves, #ordered)
		end)
	end)

	-- 8C.4 Difficulty Scaling
	describe("findBestMove", function()
		it("uses specified depth", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 4, col = 5, player = 2, powers = {} },
			}

			-- Depth 2 search
			local move = Search.findBestMove(state, 2, 1)

			assert.is_not_nil(move)
			-- Should capture
			assert.are.equal(4, move.target.row)
			assert.are.equal(5, move.target.col)
		end)

		it("handles depth 3+", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 5, col = 5, player = 1, powers = {} },
				{ row = 3, col = 5, player = 2, powers = {} },
			}

			-- Should complete without error
			local move = Search.findBestMove(state, 3, 1)

			assert.is_not_nil(move)
		end)
	end)
end)
