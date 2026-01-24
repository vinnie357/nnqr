-- Busted tests for GameClient module
-- Phase 10B: Client Networking - Game Operations
-- Run with: busted spec/

describe("GameClient", function()
	local GameClient
	local Protocol

	setup(function()
		GameClient = require("src.client.game_client")
		Protocol = require("src.shared.protocol")
	end)

	-- 1. GameClient.createMoveMessage()
	describe("createMoveMessage", function()
		it("creates MOVE message with from/to positions", function()
			local msg = GameClient.createMoveMessage({ col = 3, row = 2 }, { col = 3, row = 3 })
			assert.are.equal("MOVE", msg.type)
			assert.are.equal(3, msg.payload.from.col)
			assert.are.equal(2, msg.payload.from.row)
			assert.are.equal(3, msg.payload.to.col)
			assert.are.equal(3, msg.payload.to.row)
		end)
	end)

	-- 2. GameClient.createPowerMessage()
	describe("createPowerMessage", function()
		it("creates ACTIVATE_POWER message", function()
			local msg = GameClient.createPowerMessage({ col = 5, row = 2 }, "destroy_row")
			assert.are.equal("ACTIVATE_POWER", msg.type)
			assert.are.equal(5, msg.payload.piece_pos.col)
			assert.are.equal(2, msg.payload.piece_pos.row)
			assert.are.equal("destroy_row", msg.payload.power_id)
		end)

		it("includes target when provided", function()
			local msg = GameClient.createPowerMessage({ col = 5, row = 2 }, "raise_tile", { col = 6, row = 2 })
			assert.are.equal(6, msg.payload.target.col)
			assert.are.equal(2, msg.payload.target.row)
		end)

		it("sets target to nil when not provided", function()
			local msg = GameClient.createPowerMessage({ col = 5, row = 2 }, "bomb")
			assert.is_nil(msg.payload.target)
		end)
	end)

	-- 3. GameClient.createChatMessage()
	describe("createChatMessage", function()
		it("creates CHAT message", function()
			local msg = GameClient.createChatMessage("Good game!")
			assert.are.equal("CHAT", msg.type)
			assert.are.equal("Good game!", msg.payload.message)
		end)
	end)

	-- 4. GameClient.handleMoveResult()
	describe("handleMoveResult", function()
		it("parses successful move result", function()
			local result = GameClient.handleMoveResult({
				type = "MOVE_RESULT",
				payload = {
					success = true,
					captured = nil,
					orb_collected = "bomb",
				},
			})
			assert.is_true(result.success)
			assert.is_nil(result.captured)
			assert.are.equal("bomb", result.orbCollected)
		end)

		it("parses move with capture", function()
			local result = GameClient.handleMoveResult({
				type = "MOVE_RESULT",
				payload = {
					success = true,
					captured = { piece_id = "p5", player = 2 },
				},
			})
			assert.is_true(result.success)
			assert.is_table(result.captured)
			assert.are.equal(2, result.captured.player)
		end)

		it("parses failed move", function()
			local result = GameClient.handleMoveResult({
				type = "MOVE_RESULT",
				payload = {
					success = false,
					error = "INVALID_MOVE",
				},
			})
			assert.is_false(result.success)
			assert.are.equal("INVALID_MOVE", result.error)
		end)
	end)

	-- 5. GameClient.handlePowerResult()
	describe("handlePowerResult", function()
		it("parses successful power result", function()
			local result = GameClient.handlePowerResult({
				type = "POWER_RESULT",
				payload = {
					success = true,
					power_id = "destroy_row",
					effects = {
						{ type = "piece_destroyed", piece_id = "p5" },
						{ type = "piece_destroyed", piece_id = "p12" },
					},
				},
			})
			assert.is_true(result.success)
			assert.are.equal("destroy_row", result.powerId)
			assert.are.equal(2, #result.effects)
		end)

		it("parses failed power", function()
			local result = GameClient.handlePowerResult({
				type = "POWER_RESULT",
				payload = {
					success = false,
					error = "NO_POWER",
				},
			})
			assert.is_false(result.success)
			assert.are.equal("NO_POWER", result.error)
		end)
	end)

	-- 6. GameClient.handleGameState()
	describe("handleGameState", function()
		it("extracts turn info", function()
			local state = GameClient.handleGameState({
				type = "GAME_STATE",
				payload = {
					game_id = "g1",
					turn = 15,
					current_player = 2,
					phase = "move",
				},
			})
			assert.are.equal(15, state.turn)
			assert.are.equal(2, state.currentPlayer)
			assert.are.equal("move", state.phase)
		end)

		it("extracts board info", function()
			local state = GameClient.handleGameState({
				type = "GAME_STATE",
				payload = {
					board = { cols = 10, rows = 8, tiles = {} },
					pieces = {},
				},
			})
			assert.is_table(state.board)
			assert.are.equal(10, state.board.cols)
			assert.are.equal(8, state.board.rows)
		end)

		it("extracts pieces", function()
			local state = GameClient.handleGameState({
				type = "GAME_STATE",
				payload = {
					pieces = {
						{ col = 3, row = 2, player = 1, powers = { "bomb" } },
						{ col = 5, row = 7, player = 2, powers = {} },
					},
				},
			})
			assert.are.equal(2, #state.pieces)
			assert.are.equal(1, state.pieces[1].player)
		end)

		it("extracts winner when game over", function()
			local state = GameClient.handleGameState({
				type = "GAME_STATE",
				payload = {
					winner = 1,
					game_over = true,
				},
			})
			assert.are.equal(1, state.winner)
			assert.is_true(state.gameOver)
		end)
	end)

	-- 7. GameClient.handleGameOver()
	describe("handleGameOver", function()
		it("parses winner and reason", function()
			local result = GameClient.handleGameOver({
				type = "GAME_OVER",
				payload = {
					winner = 2,
					reason = "elimination",
				},
			})
			assert.are.equal(2, result.winner)
			assert.are.equal("elimination", result.reason)
		end)
	end)

	-- 8. GameClient.handleChatMessage()
	describe("handleChatMessage", function()
		it("parses chat message", function()
			local chat = GameClient.handleChatMessage({
				type = "CHAT_MESSAGE",
				payload = {
					player_name = "Alice",
					message = "Nice move!",
				},
			})
			assert.are.equal("Alice", chat.playerName)
			assert.are.equal("Nice move!", chat.message)
		end)
	end)

	-- 9. GameClient.handleOrbSpawn()
	describe("handleOrbSpawn", function()
		it("parses orb spawn locations", function()
			local orbs = GameClient.handleOrbSpawn({
				type = "ORB_SPAWN",
				payload = {
					orbs = {
						{ col = 5, row = 3, power_id = "bomb" },
						{ col = 2, row = 5, power_id = "recruit" },
					},
				},
			})
			assert.are.equal(2, #orbs)
			assert.are.equal("bomb", orbs[1].powerId)
			assert.are.equal(5, orbs[1].col)
		end)
	end)

	-- 10. GameClient.isMyTurn()
	describe("isMyTurn", function()
		it("returns true when it is player's turn", function()
			local gameState = { currentPlayer = 1 }
			assert.is_true(GameClient.isMyTurn(gameState, 1))
		end)

		it("returns false when it is not player's turn", function()
			local gameState = { currentPlayer = 2 }
			assert.is_false(GameClient.isMyTurn(gameState, 1))
		end)

		it("returns false for nil game state", function()
			assert.is_false(GameClient.isMyTurn(nil, 1))
		end)
	end)

	-- 11. GameClient.getPieceAt()
	describe("getPieceAt", function()
		it("finds piece at position", function()
			local gameState = {
				pieces = {
					{ col = 3, row = 2, player = 1 },
					{ col = 5, row = 7, player = 2 },
				},
			}
			local piece = GameClient.getPieceAt(gameState, 3, 2)
			assert.is_table(piece)
			assert.are.equal(1, piece.player)
		end)

		it("returns nil when no piece at position", function()
			local gameState = {
				pieces = {
					{ col = 3, row = 2, player = 1 },
				},
			}
			local piece = GameClient.getPieceAt(gameState, 5, 5)
			assert.is_nil(piece)
		end)
	end)

	-- 12. GameClient.getMyPieces()
	describe("getMyPieces", function()
		it("filters pieces by player", function()
			local gameState = {
				pieces = {
					{ col = 1, row = 1, player = 1 },
					{ col = 2, row = 1, player = 1 },
					{ col = 1, row = 8, player = 2 },
				},
			}
			local myPieces = GameClient.getMyPieces(gameState, 1)
			assert.are.equal(2, #myPieces)
		end)
	end)

	-- 13. GameClient.countPieces()
	describe("countPieces", function()
		it("counts pieces for each player", function()
			local gameState = {
				pieces = {
					{ player = 1 },
					{ player = 1 },
					{ player = 1 },
					{ player = 2 },
					{ player = 2 },
				},
			}
			local p1, p2 = GameClient.countPieces(gameState)
			assert.are.equal(3, p1)
			assert.are.equal(2, p2)
		end)
	end)
end)
