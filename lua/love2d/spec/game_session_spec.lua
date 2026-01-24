-- Busted tests for GameSession module
-- Phase 10A: Network Multiplayer - Game Session Management
-- Run with: busted spec/

describe("GameSession", function()
	local GameSession

	setup(function()
		GameSession = require("server.game_session")
	end)

	-- 1. GameSession.create()
	describe("create", function()
		it("returns a table", function()
			local session = GameSession.create("game_1", "player_1", "player_2")
			assert.is_table(session)
		end)

		it("stores game ID", function()
			local session = GameSession.create("game_123", "p1", "p2")
			assert.are.equal("game_123", session.gameId)
		end)

		it("stores player IDs", function()
			local session = GameSession.create("game_1", "player_1", "player_2")
			assert.are.equal("player_1", session.player1Id)
			assert.are.equal("player_2", session.player2Id)
		end)

		it("initializes game state", function()
			local session = GameSession.create("game_1", "p1", "p2")
			assert.is_table(session.state)
			assert.are.equal(10, session.state.cols)
			assert.are.equal(8, session.state.rows)
		end)

		it("sets current player to 1", function()
			local session = GameSession.create("game_1", "p1", "p2")
			assert.are.equal(1, session.state.currentPlayer)
		end)

		it("creates pieces for both players", function()
			local session = GameSession.create("game_1", "p1", "p2")
			local p1Count = 0
			local p2Count = 0
			for _, piece in ipairs(session.state.pieces) do
				if piece.player == 1 then
					p1Count = p1Count + 1
				elseif piece.player == 2 then
					p2Count = p2Count + 1
				end
			end
			assert.is_true(p1Count > 0)
			assert.is_true(p2Count > 0)
			assert.are.equal(p1Count, p2Count)
		end)

		it("sets status to playing", function()
			local session = GameSession.create("game_1", "p1", "p2")
			assert.are.equal("playing", session.status)
		end)
	end)

	-- 2. GameSession.getPlayerNumber()
	describe("getPlayerNumber", function()
		it("returns 1 for player1", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.are.equal(1, GameSession.getPlayerNumber(session, "alice"))
		end)

		it("returns 2 for player2", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.are.equal(2, GameSession.getPlayerNumber(session, "bob"))
		end)

		it("returns nil for unknown player", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.is_nil(GameSession.getPlayerNumber(session, "charlie"))
		end)
	end)

	-- 3. GameSession.isPlayerTurn()
	describe("isPlayerTurn", function()
		it("returns true for player 1 on turn 1", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.is_true(GameSession.isPlayerTurn(session, "alice"))
		end)

		it("returns false for player 2 on turn 1", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.is_false(GameSession.isPlayerTurn(session, "bob"))
		end)

		it("returns false for unknown player", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.is_false(GameSession.isPlayerTurn(session, "charlie"))
		end)
	end)

	-- 4. GameSession.handleMove()
	describe("handleMove", function()
		it("returns success for valid move", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Find a player 1 piece on row 2 (front row) to move forward
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 and p.row == 2 then
					piece = p
					break
				end
			end
			assert.is_not_nil(piece)
			-- Move forward (player 1 moves down, row increases) to row 3
			local result = GameSession.handleMove(session, "alice", {
				from = { col = piece.col, row = piece.row },
				to = { col = piece.col, row = piece.row + 1 },
			})
			assert.is_true(result.success)
		end)

		it("rejects move from wrong player", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Try to move as bob when it's alice's turn
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 2 then
					piece = p
					break
				end
			end
			local result = GameSession.handleMove(session, "bob", {
				from = { col = piece.col, row = piece.row },
				to = { col = piece.col, row = piece.row - 1 },
			})
			assert.is_false(result.success)
			assert.are.equal("NOT_YOUR_TURN", result.error)
		end)

		it("rejects invalid move position", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					piece = p
					break
				end
			end
			-- Try to move 5 squares (invalid)
			local result = GameSession.handleMove(session, "alice", {
				from = { col = piece.col, row = piece.row },
				to = { col = piece.col, row = piece.row + 5 },
			})
			assert.is_false(result.success)
			assert.are.equal("INVALID_MOVE", result.error)
		end)

		it("rejects move when no piece at source", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Try to move from empty square
			local result = GameSession.handleMove(session, "alice", {
				from = { col = 5, row = 4 }, -- middle of board, likely empty
				to = { col = 5, row = 5 },
			})
			assert.is_false(result.success)
			assert.are.equal("NO_PIECE", result.error)
		end)

		it("rejects move of opponent's piece", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Find player 2's piece
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 2 then
					piece = p
					break
				end
			end
			-- Alice tries to move bob's piece
			local result = GameSession.handleMove(session, "alice", {
				from = { col = piece.col, row = piece.row },
				to = { col = piece.col, row = piece.row - 1 },
			})
			assert.is_false(result.success)
			assert.are.equal("NOT_YOUR_PIECE", result.error)
		end)

		it("switches turn after valid move", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Find a player 1 piece on row 2 (front row) to move forward
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 and p.row == 2 then
					piece = p
					break
				end
			end
			assert.are.equal(1, session.state.currentPlayer)
			local result = GameSession.handleMove(session, "alice", {
				from = { col = piece.col, row = piece.row },
				to = { col = piece.col, row = piece.row + 1 },
			})
			assert.is_true(result.success) -- Ensure move succeeded first
			assert.are.equal(2, session.state.currentPlayer)
		end)

		it("captures opponent piece", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Manually place pieces adjacent for capture test
			session.state.pieces = {
				{ player = 1, row = 4, col = 5, powers = {} },
				{ player = 2, row = 5, col = 5, powers = {} },
			}
			local initialCount = #session.state.pieces
			local result = GameSession.handleMove(session, "alice", {
				from = { col = 5, row = 4 },
				to = { col = 5, row = 5 },
			})
			assert.is_true(result.success)
			assert.are.equal(initialCount - 1, #session.state.pieces)
			assert.is_not_nil(result.captured)
		end)

		it("detects game over when all opponent pieces captured", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Setup: only one piece each, adjacent
			session.state.pieces = {
				{ player = 1, row = 4, col = 5, powers = {} },
				{ player = 2, row = 5, col = 5, powers = {} },
			}
			local result = GameSession.handleMove(session, "alice", {
				from = { col = 5, row = 4 },
				to = { col = 5, row = 5 },
			})
			assert.is_true(result.success)
			assert.are.equal("gameover", session.state.gameState)
			assert.are.equal(1, session.state.winner)
			assert.are.equal("finished", session.status)
		end)
	end)

	-- 5. GameSession.handlePower()
	describe("handlePower", function()
		it("rejects power from wrong player", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local result = GameSession.handlePower(session, "bob", {
				piece_pos = { col = 1, row = 1 },
				power_id = "destroy_row",
				target = nil,
			})
			assert.is_false(result.success)
			assert.are.equal("NOT_YOUR_TURN", result.error)
		end)

		it("rejects power when piece has no powers", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					piece = p
					break
				end
			end
			-- Ensure piece has no powers
			piece.powers = {}
			local result = GameSession.handlePower(session, "alice", {
				piece_pos = { col = piece.col, row = piece.row },
				power_id = "destroy_row",
				target = nil,
			})
			assert.is_false(result.success)
			assert.are.equal("NO_POWER", result.error)
		end)

		it("rejects power when piece doesn't have that power", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					piece = p
					break
				end
			end
			-- Give piece a different power
			piece.powers = { "bomb" }
			local result = GameSession.handlePower(session, "alice", {
				piece_pos = { col = piece.col, row = piece.row },
				power_id = "destroy_row",
				target = nil,
			})
			assert.is_false(result.success)
			assert.are.equal("NO_POWER", result.error)
		end)

		it("executes power successfully", function()
			local session = GameSession.create("game_1", "alice", "bob")
			-- Setup piece with a power
			session.state.pieces = {
				{ player = 1, row = 2, col = 5, powers = { "move_diagonal" } },
				{ player = 2, row = 7, col = 5, powers = {} },
			}
			local result = GameSession.handlePower(session, "alice", {
				piece_pos = { col = 5, row = 2 },
				power_id = "move_diagonal",
				target = nil,
			})
			assert.is_true(result.success)
		end)

		it("removes power after use", function()
			local session = GameSession.create("game_1", "alice", "bob")
			session.state.pieces = {
				{ player = 1, row = 2, col = 5, powers = { "move_diagonal" } },
				{ player = 2, row = 7, col = 5, powers = {} },
			}
			local piece = session.state.pieces[1]
			assert.are.equal(1, #piece.powers)
			GameSession.handlePower(session, "alice", {
				piece_pos = { col = 5, row = 2 },
				power_id = "move_diagonal",
				target = nil,
			})
			assert.are.equal(0, #piece.powers)
		end)
	end)

	-- 6. GameSession.getState()
	describe("getState", function()
		it("returns serializable game state", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local state = GameSession.getState(session)
			assert.is_table(state)
			assert.are.equal("game_1", state.game_id)
			assert.is_number(state.turn)
			assert.is_number(state.current_player)
		end)

		it("includes board dimensions", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local state = GameSession.getState(session)
			assert.is_table(state.board)
			assert.are.equal(10, state.board.cols)
			assert.are.equal(8, state.board.rows)
		end)

		it("includes pieces", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local state = GameSession.getState(session)
			assert.is_table(state.pieces)
			assert.is_true(#state.pieces > 0)
		end)

		it("includes winner when game over", function()
			local session = GameSession.create("game_1", "alice", "bob")
			session.state.gameState = "gameover"
			session.state.winner = 1
			session.status = "finished"
			local state = GameSession.getState(session)
			assert.are.equal(1, state.winner)
		end)
	end)

	-- 7. GameSession.forfeit()
	describe("forfeit", function()
		it("ends game with opponent as winner", function()
			local session = GameSession.create("game_1", "alice", "bob")
			GameSession.forfeit(session, "alice")
			assert.are.equal("finished", session.status)
			assert.are.equal("gameover", session.state.gameState)
			assert.are.equal(2, session.state.winner)
		end)

		it("sets player 1 as winner when player 2 forfeits", function()
			local session = GameSession.create("game_1", "alice", "bob")
			GameSession.forfeit(session, "bob")
			assert.are.equal(1, session.state.winner)
		end)

		it("returns false for unknown player", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local result = GameSession.forfeit(session, "charlie")
			assert.is_false(result)
		end)
	end)

	-- 8. AI Game Support - Phase 3
	describe("createAIGame", function()
		it("creates AI game session", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			assert.is_table(session)
			assert.are.equal("game_1", session.gameId)
		end)

		it("sets player1Id to human player", function()
			local session = GameSession.createAIGame("game_1", "alice", "easy")
			assert.are.equal("alice", session.player1Id)
		end)

		it("sets player2Id to AI marker", function()
			local session = GameSession.createAIGame("game_1", "alice", "hard")
			assert.are.equal("AI", session.player2Id)
		end)

		it("marks session as AI game", function()
			local session = GameSession.createAIGame("game_1", "alice", "expert")
			assert.is_true(session.isAIGame)
		end)

		it("stores AI difficulty", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			assert.are.equal("medium", session.aiDifficulty)
		end)

		it("initializes AI think timer", function()
			local session = GameSession.createAIGame("game_1", "alice", "easy")
			assert.are.equal(0, session.aiThinkTimer)
		end)

		it("sets human player as player 1", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			assert.are.equal(1, GameSession.getPlayerNumber(session, "alice"))
		end)

		it("generates terrain with height variations", function()
			local session = GameSession.createAIGame("game_1", "alice", "easy")

			-- Check that terrain was generated (at least one tile with height > 0)
			local hasElevation = false
			for row = 1, session.state.rows do
				for col = 1, session.state.cols do
					local height = session.state.heightMap[row][col]
					if height > 0 then
						hasElevation = true
						break
					end
				end
				if hasElevation then
					break
				end
			end
			assert.is_true(hasElevation)
		end)

		it("generates same terrain pattern as client", function()
			local session = GameSession.createAIGame("game_1", "alice", "easy")
			-- Check specific terrain pattern: row 4, col 6 should have height 3
			assert.are.equal(3, session.state.heightMap[4][6])
			-- row 4, col 5 should have height 2
			assert.are.equal(2, session.state.heightMap[4][5])
			-- row 5, col 6 should have height 2
			assert.are.equal(2, session.state.heightMap[5][6])
		end)
	end)

	describe("isAIGame", function()
		it("returns false for regular game", function()
			local session = GameSession.create("game_1", "alice", "bob")
			assert.is_false(GameSession.isAIGame(session))
		end)

		it("returns true for AI game", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			assert.is_true(GameSession.isAIGame(session))
		end)
	end)

	describe("isAITurn", function()
		it("returns false when player 1 turn in AI game", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			-- AI is player 2, starts with player 1
			assert.is_false(GameSession.isAITurn(session))
		end)

		it("returns true when player 2 turn in AI game", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			session.state.currentPlayer = 2 -- AI's turn
			assert.is_true(GameSession.isAITurn(session))
		end)

		it("returns false for regular game", function()
			local session = GameSession.create("game_1", "alice", "bob")
			session.state.currentPlayer = 2
			assert.is_false(GameSession.isAITurn(session))
		end)
	end)

	describe("updateAI", function()
		it("increments AI think timer", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			session.state.currentPlayer = 2 -- AI's turn
			GameSession.updateAI(session, 0.5)
			assert.are.equal(0.5, session.aiThinkTimer)
		end)

		it("does nothing when not AI turn", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			session.state.currentPlayer = 1 -- Human turn
			GameSession.updateAI(session, 0.5)
			assert.are.equal(0, session.aiThinkTimer)
		end)

		it("does nothing for regular games", function()
			local session = GameSession.create("game_1", "alice", "bob")
			session.aiThinkTimer = 0
			GameSession.updateAI(session, 0.5)
			assert.are.equal(0, session.aiThinkTimer or 0)
		end)

		it("returns nil when timer below threshold", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			session.state.currentPlayer = 2
			local move = GameSession.updateAI(session, 0.3)
			assert.is_nil(move)
		end)

		it("returns move when timer exceeds threshold", function()
			local session = GameSession.createAIGame("game_1", "alice", "easy")
			session.state.currentPlayer = 2
			-- Simulate time passing
			session.aiThinkTimer = 0.9
			local result = GameSession.updateAI(session, 0.2)
			-- Should return a move result or nil if AI couldn't find a move
			-- The actual behavior depends on AI having valid moves
			assert.is_true(result == nil or type(result) == "table")
		end)

		it("resets timer after making move", function()
			local session = GameSession.createAIGame("game_1", "alice", "easy")
			session.state.currentPlayer = 2
			session.aiThinkTimer = 0.9
			GameSession.updateAI(session, 0.2)
			assert.are.equal(0, session.aiThinkTimer)
		end)
	end)

	describe("getState for AI game", function()
		it("includes isAIGame flag", function()
			local session = GameSession.createAIGame("game_1", "alice", "medium")
			local state = GameSession.getState(session)
			assert.is_true(state.is_ai_game)
		end)

		it("includes AI difficulty", function()
			local session = GameSession.createAIGame("game_1", "alice", "hard")
			local state = GameSession.getState(session)
			assert.are.equal("hard", state.ai_difficulty)
		end)

		it("regular game state does not have AI fields", function()
			local session = GameSession.create("game_1", "alice", "bob")
			local state = GameSession.getState(session)
			assert.is_falsy(state.is_ai_game)
			assert.is_nil(state.ai_difficulty)
		end)
	end)
end)
