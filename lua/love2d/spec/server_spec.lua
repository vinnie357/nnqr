-- Busted tests for Server module
-- Phase 10A: Network Multiplayer - Server Core
-- Run with: busted spec/

describe("Server", function()
	local Server
	local Protocol

	setup(function()
		Server = require("server.server")
		Protocol = require("src.shared.protocol")
	end)

	-- 1. Server.create()
	describe("create", function()
		it("returns a table", function()
			local server = Server.create({})
			assert.is_table(server)
		end)

		it("uses default port 7777", function()
			local server = Server.create({})
			assert.are.equal(7777, server.port)
		end)

		it("accepts custom port", function()
			local server = Server.create({ port = 8888 })
			assert.are.equal(8888, server.port)
		end)

		it("uses default maxGames 10", function()
			local server = Server.create({})
			assert.are.equal(10, server.maxGames)
		end)

		it("accepts custom maxGames", function()
			local server = Server.create({ maxGames = 5 })
			assert.are.equal(5, server.maxGames)
		end)

		it("initializes empty clients table", function()
			local server = Server.create({})
			assert.is_table(server.clients)
			local count = 0
			for _ in pairs(server.clients) do
				count = count + 1
			end
			assert.are.equal(0, count)
		end)

		it("initializes lobby", function()
			local server = Server.create({})
			assert.is_table(server.lobby)
			assert.is_table(server.lobby.players)
			assert.is_table(server.lobby.games)
		end)

		it("initializes empty gameSessions table", function()
			local server = Server.create({})
			assert.is_table(server.gameSessions)
		end)

		it("sets running to false initially", function()
			local server = Server.create({})
			assert.is_false(server.running)
		end)
	end)

	-- 2. Server.addClient()
	describe("addClient", function()
		it("adds client to server", function()
			local server = Server.create({})
			local mockSocket = { id = "sock1" }
			local clientId = Server.addClient(server, mockSocket)
			assert.is_string(clientId)
			assert.is_not_nil(server.clients[clientId])
		end)

		it("generates unique client IDs", function()
			local server = Server.create({})
			local clientId1 = Server.addClient(server, { id = "sock1" })
			local clientId2 = Server.addClient(server, { id = "sock2" })
			assert.are_not.equal(clientId1, clientId2)
		end)

		it("stores socket reference", function()
			local server = Server.create({})
			local mockSocket = { id = "sock1" }
			local clientId = Server.addClient(server, mockSocket)
			assert.are.equal(mockSocket, server.clients[clientId].socket)
		end)

		it("sets client state to connected", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			assert.are.equal("connected", server.clients[clientId].state)
		end)

		it("initializes playerId as nil", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			assert.is_nil(server.clients[clientId].playerId)
		end)
	end)

	-- 3. Server.removeClient()
	describe("removeClient", function()
		it("removes client from server", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			assert.is_not_nil(server.clients[clientId])
			Server.removeClient(server, clientId)
			assert.is_nil(server.clients[clientId])
		end)

		it("returns true for existing client", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			local success = Server.removeClient(server, clientId)
			assert.is_true(success)
		end)

		it("returns false for non-existent client", function()
			local server = Server.create({})
			local success = Server.removeClient(server, "nonexistent")
			assert.is_false(success)
		end)

		it("removes player from lobby if authenticated", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			-- Simulate authentication
			local playerId = "player_123"
			server.clients[clientId].playerId = playerId
			server.lobby.players[playerId] = { id = playerId, name = "Alice", gameId = nil }
			-- Remove client
			Server.removeClient(server, clientId)
			assert.is_nil(server.lobby.players[playerId])
		end)
	end)

	-- 4. Server.getClient()
	describe("getClient", function()
		it("returns client data for existing client", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			local client = Server.getClient(server, clientId)
			assert.is_table(client)
			assert.are.equal("connected", client.state)
		end)

		it("returns nil for non-existent client", function()
			local server = Server.create({})
			local client = Server.getClient(server, "nonexistent")
			assert.is_nil(client)
		end)
	end)

	-- 5. Server.getClientCount()
	describe("getClientCount", function()
		it("returns 0 for empty server", function()
			local server = Server.create({})
			assert.are.equal(0, Server.getClientCount(server))
		end)

		it("returns correct count after adding clients", function()
			local server = Server.create({})
			Server.addClient(server, { id = "sock1" })
			Server.addClient(server, { id = "sock2" })
			assert.are.equal(2, Server.getClientCount(server))
		end)
	end)

	-- 6. Server.handleMessage() - Message routing
	describe("handleMessage", function()
		describe("CONNECT message", function()
			it("authenticates client and adds to lobby", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local msg = Protocol.connectMessage("Alice", "0.1.0")
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("WELCOME", response.type)
				assert.is_string(response.payload.player_id)
			end)

			it("sets client playerId after CONNECT", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local msg = Protocol.connectMessage("Alice", "0.1.0")
				local response = Server.handleMessage(server, clientId, msg)
				local client = server.clients[clientId]
				assert.are.equal(response.payload.player_id, client.playerId)
			end)

			it("adds player to lobby after CONNECT", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local msg = Protocol.connectMessage("Alice", "0.1.0")
				local response = Server.handleMessage(server, clientId, msg)
				local playerId = response.payload.player_id
				local player = server.lobby.players[playerId]
				assert.is_table(player)
				assert.are.equal("Alice", player.name)
			end)

			it("rejects duplicate player name", function()
				local server = Server.create({})
				-- First client connects as Alice
				local clientId1 = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId1, Protocol.connectMessage("Alice", "0.1.0"))
				-- Second client tries same name
				local clientId2 = Server.addClient(server, { id = "sock2" })
				local response = Server.handleMessage(server, clientId2, Protocol.connectMessage("Alice", "0.1.0"))
				assert.are.equal("ERROR", response.type)
				assert.are.equal("NAME_TAKEN", response.payload.code)
			end)

			it("rejects CONNECT from already authenticated client", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				-- Try to connect again
				local response = Server.handleMessage(server, clientId, Protocol.connectMessage("Bob", "0.1.0"))
				assert.are.equal("ERROR", response.type)
				assert.are.equal("ALREADY_CONNECTED", response.payload.code)
			end)
		end)

		describe("JOIN_LOBBY message", function()
			it("returns lobby state", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				local msg = Protocol.createMessage("JOIN_LOBBY", {})
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("LOBBY_STATE", response.type)
				assert.is_table(response.payload.games)
			end)

			it("rejects unauthenticated client", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local msg = Protocol.createMessage("JOIN_LOBBY", {})
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("ERROR", response.type)
				assert.are.equal("NOT_AUTHENTICATED", response.payload.code)
			end)
		end)

		describe("CREATE_GAME message", function()
			it("creates game and returns GAME_CREATED", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				local msg = Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("GAME_CREATED", response.type)
				assert.is_string(response.payload.game_id)
			end)

			it("adds game to lobby", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				local msg = Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
				local response = Server.handleMessage(server, clientId, msg)
				local gameId = response.payload.game_id
				assert.is_not_nil(server.lobby.games[gameId])
			end)

			it("rejects unauthenticated client", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local msg = Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("ERROR", response.type)
				assert.are.equal("NOT_AUTHENTICATED", response.payload.code)
			end)

			it("rejects if player already in a game", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				Server.handleMessage(server, clientId, Protocol.createMessage("CREATE_GAME", { game_name = "Game 1" }))
				local response = Server.handleMessage(
					server,
					clientId,
					Protocol.createMessage("CREATE_GAME", { game_name = "Game 2" })
				)
				assert.are.equal("ERROR", response.type)
			end)
		end)

		describe("JOIN_GAME message", function()
			it("joins game and returns GAME_STATE when game starts", function()
				local server = Server.create({})
				-- Player 1 creates game
				local clientId1 = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId1, Protocol.connectMessage("Alice", "0.1.0"))
				local createResp = Server.handleMessage(
					server,
					clientId1,
					Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
				)
				local gameId = createResp.payload.game_id
				-- Player 2 joins
				local clientId2 = Server.addClient(server, { id = "sock2" })
				Server.handleMessage(server, clientId2, Protocol.connectMessage("Bob", "0.1.0"))
				local msg = Protocol.createMessage("JOIN_GAME", { game_id = gameId })
				local response = Server.handleMessage(server, clientId2, msg)
				-- When 2 players join, game starts and returns GAME_STATE
				assert.are.equal("GAME_STATE", response.type)
			end)

			it("rejects if game not found", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				local msg = Protocol.createMessage("JOIN_GAME", { game_id = "nonexistent" })
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("ERROR", response.type)
				assert.are.equal("GAME_NOT_FOUND", response.payload.code)
			end)

			it("rejects if game is full", function()
				local server = Server.create({})
				-- Create game with 2 players
				local clientId1 = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId1, Protocol.connectMessage("Alice", "0.1.0"))
				local createResp = Server.handleMessage(
					server,
					clientId1,
					Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
				)
				local gameId = createResp.payload.game_id
				local clientId2 = Server.addClient(server, { id = "sock2" })
				Server.handleMessage(server, clientId2, Protocol.connectMessage("Bob", "0.1.0"))
				Server.handleMessage(server, clientId2, Protocol.createMessage("JOIN_GAME", { game_id = gameId }))
				-- Third player tries to join
				local clientId3 = Server.addClient(server, { id = "sock3" })
				Server.handleMessage(server, clientId3, Protocol.connectMessage("Charlie", "0.1.0"))
				local response =
					Server.handleMessage(server, clientId3, Protocol.createMessage("JOIN_GAME", { game_id = gameId }))
				assert.are.equal("ERROR", response.type)
			end)
		end)

		describe("LEAVE_GAME message", function()
			it("leaves game successfully", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				Server.handleMessage(
					server,
					clientId,
					Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
				)
				local msg = Protocol.createMessage("LEAVE_GAME", {})
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("LOBBY_STATE", response.type)
			end)

			it("rejects if not in a game", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				local msg = Protocol.createMessage("LEAVE_GAME", {})
				local response = Server.handleMessage(server, clientId, msg)
				assert.are.equal("ERROR", response.type)
			end)
		end)

		describe("invalid messages", function()
			it("rejects message without type", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local response = Server.handleMessage(server, clientId, { payload = {} })
				assert.are.equal("ERROR", response.type)
				assert.are.equal("INVALID_MESSAGE", response.payload.code)
			end)

			it("rejects message without payload", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				local response = Server.handleMessage(server, clientId, { type = "CONNECT" })
				assert.are.equal("ERROR", response.type)
				assert.are.equal("INVALID_MESSAGE", response.payload.code)
			end)

			it("rejects unknown message type", function()
				local server = Server.create({})
				local clientId = Server.addClient(server, { id = "sock1" })
				Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
				local response = Server.handleMessage(server, clientId, Protocol.createMessage("UNKNOWN_TYPE", {}))
				assert.are.equal("ERROR", response.type)
				assert.are.equal("UNKNOWN_MESSAGE_TYPE", response.payload.code)
			end)

			it("rejects message from unknown client", function()
				local server = Server.create({})
				local response = Server.handleMessage(server, "nonexistent", Protocol.connectMessage("Alice", "0.1.0"))
				assert.are.equal("ERROR", response.type)
				assert.are.equal("UNKNOWN_CLIENT", response.payload.code)
			end)
		end)
	end)

	-- 7. Server.broadcastToGame()
	describe("broadcastToGame", function()
		it("returns list of client IDs in game", function()
			local server = Server.create({})
			-- Setup two players in a game
			local clientId1 = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId1, Protocol.connectMessage("Alice", "0.1.0"))
			local createResp = Server.handleMessage(
				server,
				clientId1,
				Protocol.createMessage("CREATE_GAME", { game_name = "Test Game" })
			)
			local gameId = createResp.payload.game_id
			local clientId2 = Server.addClient(server, { id = "sock2" })
			Server.handleMessage(server, clientId2, Protocol.connectMessage("Bob", "0.1.0"))
			Server.handleMessage(server, clientId2, Protocol.createMessage("JOIN_GAME", { game_id = gameId }))
			-- Get clients for broadcast
			local clientIds = Server.getClientsInGame(server, gameId)
			assert.are.equal(2, #clientIds)
		end)

		it("returns empty list for non-existent game", function()
			local server = Server.create({})
			local clientIds = Server.getClientsInGame(server, "nonexistent")
			assert.are.equal(0, #clientIds)
		end)
	end)

	-- 8. Server.findClientByPlayerId()
	describe("findClientByPlayerId", function()
		it("returns clientId for authenticated player", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			local response = Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local playerId = response.payload.player_id
			local foundClientId = Server.findClientByPlayerId(server, playerId)
			assert.are.equal(clientId, foundClientId)
		end)

		it("returns nil for unknown player", function()
			local server = Server.create({})
			local foundClientId = Server.findClientByPlayerId(server, "unknown_player")
			assert.is_nil(foundClientId)
		end)
	end)

	-- 9. CREATE_AI_GAME message - Phase 3: AI Practice
	describe("CREATE_AI_GAME message", function()
		it("creates AI game and returns AI_GAME_CREATED", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local msg = Protocol.createAIGameMessage("medium", "AI Practice")
			local response = Server.handleMessage(server, clientId, msg)
			assert.are.equal("AI_GAME_CREATED", response.type)
			assert.is_string(response.payload.game_id)
			assert.are.equal("medium", response.payload.difficulty)
			assert.are.equal(1, response.payload.player_number)
		end)

		it("creates game session for AI game", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local msg = Protocol.createAIGameMessage("easy")
			local response = Server.handleMessage(server, clientId, msg)
			local gameId = response.payload.game_id
			assert.is_not_nil(server.gameSessions[gameId])
			assert.is_true(server.gameSessions[gameId].isAIGame)
		end)

		it("starts game immediately (no waiting)", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local msg = Protocol.createAIGameMessage("hard")
			local response = Server.handleMessage(server, clientId, msg)
			local gameId = response.payload.game_id
			-- Game should be in playing state
			assert.are.equal("playing", server.gameSessions[gameId].status)
		end)

		it("rejects invalid difficulty", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local msg = Protocol.createMessage("CREATE_AI_GAME", { difficulty = "impossible" })
			local response = Server.handleMessage(server, clientId, msg)
			assert.are.equal("ERROR", response.type)
			assert.are.equal("INVALID_DIFFICULTY", response.payload.code)
		end)

		it("rejects if player already in a game", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			-- Create first game
			Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))
			-- Try to create second game
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("medium"))
			assert.are.equal("ERROR", response.type)
		end)

		it("rejects unauthenticated client", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			local msg = Protocol.createAIGameMessage("easy")
			local response = Server.handleMessage(server, clientId, msg)
			assert.are.equal("ERROR", response.type)
			assert.are.equal("NOT_AUTHENTICATED", response.payload.code)
		end)

		it("includes game_state in AI_GAME_CREATED response", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))

			assert.are.equal("AI_GAME_CREATED", response.type)
			assert.is_not_nil(response.payload.game_state)
		end)

		it("game_state includes current_player and turn", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))

			local gs = response.payload.game_state
			assert.are.equal(1, gs.current_player)
			assert.is_number(gs.turn)
		end)

		it("game_state includes pieces in starting positions", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))

			local pieces = response.payload.game_state.pieces
			assert.is_table(pieces)
			assert.is_true(#pieces > 0)

			-- Verify player 1 and player 2 pieces exist
			local p1Count, p2Count = 0, 0
			for _, piece in ipairs(pieces) do
				if piece.player == 1 then
					p1Count = p1Count + 1
				end
				if piece.player == 2 then
					p2Count = p2Count + 1
				end
			end
			assert.is_true(p1Count > 0)
			assert.is_true(p2Count > 0)
		end)

		it("game_state includes board with terrain", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))

			local board = response.payload.game_state.board
			assert.is_table(board)
			assert.are.equal(10, board.cols)
			assert.are.equal(8, board.rows)
			assert.is_table(board.tiles)

			-- Check that terrain exists (at least one tile with height > 0)
			local hasElevation = false
			for _, tile in ipairs(board.tiles) do
				if tile.height and tile.height > 0 then
					hasElevation = true
					break
				end
			end
			assert.is_true(hasElevation)
		end)

		it("game_state game_id matches response game_id", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))

			assert.are.equal(response.payload.game_id, response.payload.game_state.game_id)
		end)
	end)

	-- 10. Server.updateAIGames() - AI update loop
	describe("updateAIGames", function()
		it("updates AI games and returns moves made", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			-- Create AI game
			local msg = Protocol.createAIGameMessage("easy")
			local response = Server.handleMessage(server, clientId, msg)
			local gameId = response.payload.game_id
			-- Make a human move first so it's AI's turn
			local session = server.gameSessions[gameId]
			session.state.currentPlayer = 2 -- Force AI turn
			-- Update with enough time for AI to move
			local moves = Server.updateAIGames(server, 1.0)
			-- Should return list of games where AI moved
			assert.is_table(moves)
		end)

		it("does nothing for non-AI games", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			-- Create regular game (not AI)
			Server.handleMessage(server, clientId, Protocol.createMessage("CREATE_GAME", { game_name = "Test" }))
			-- Update should not affect anything
			local moves = Server.updateAIGames(server, 1.0)
			assert.are.equal(0, #moves)
		end)

		it("returns game state after AI move", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local msg = Protocol.createAIGameMessage("easy")
			local response = Server.handleMessage(server, clientId, msg)
			local gameId = response.payload.game_id
			local session = server.gameSessions[gameId]
			session.state.currentPlayer = 2
			session.aiThinkTimer = 0.9 -- Almost ready to move
			local moves = Server.updateAIGames(server, 0.2)
			-- If AI made a move, it should include game state
			for _, move in ipairs(moves) do
				if move.gameId == gameId then
					assert.is_table(move.state)
				end
			end
		end)
	end)

	-- 11. Server.getAIGameSession()
	describe("getAIGameSession", function()
		it("returns AI game session by game ID", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))
			local msg = Protocol.createAIGameMessage("medium")
			local response = Server.handleMessage(server, clientId, msg)
			local gameId = response.payload.game_id
			local session = Server.getGameSession(server, gameId)
			assert.is_not_nil(session)
			assert.is_true(session.isAIGame)
		end)

		it("returns nil for non-existent game", function()
			local server = Server.create({})
			local session = Server.getGameSession(server, "nonexistent")
			assert.is_nil(session)
		end)
	end)

	-- 11. MOVE handling for AI games
	describe("MOVE message in AI game", function()
		it("accepts valid move from human player", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			-- Create AI game
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))
			assert.are.equal("AI_GAME_CREATED", response.type)
			local gameId = response.payload.game_id

			-- Get initial piece position (player 1 pieces are in row 1-2)
			local session = Server.getGameSession(server, gameId)
			assert.is_not_nil(session)

			-- Make a valid move (player 1 piece from row 2 to row 3)
			local moveMsg = Protocol.moveMessage({ col = 1, row = 2 }, { col = 1, row = 3 })
			local moveResponse = Server.handleMessage(server, clientId, moveMsg)

			assert.are.equal("GAME_STATE", moveResponse.type)
		end)

		it("rejects move when not your turn", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			-- Create AI game
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))
			local gameId = response.payload.game_id
			local session = Server.getGameSession(server, gameId)

			-- Force it to be AI's turn (player 2)
			session.state.currentPlayer = 2

			-- Try to make a move as player 1
			local moveMsg = Protocol.moveMessage({ col = 1, row = 2 }, { col = 1, row = 3 })
			local moveResponse = Server.handleMessage(server, clientId, moveMsg)

			assert.are.equal("ERROR", moveResponse.type)
			assert.are.equal("NOT_YOUR_TURN", moveResponse.payload.code)
		end)

		it("rejects move for player not in game", function()
			local server = Server.create({})

			-- Create two clients
			local clientId1 = Server.addClient(server, { id = "sock1" })
			local clientId2 = Server.addClient(server, { id = "sock2" })
			Server.handleMessage(server, clientId1, Protocol.connectMessage("Alice", "0.1.0"))
			Server.handleMessage(server, clientId2, Protocol.connectMessage("Bob", "0.1.0"))

			-- Alice creates AI game
			Server.handleMessage(server, clientId1, Protocol.createAIGameMessage("easy"))

			-- Bob tries to move in Alice's game
			local moveMsg = Protocol.moveMessage({ col = 1, row = 2 }, { col = 1, row = 3 })
			local moveResponse = Server.handleMessage(server, clientId2, moveMsg)

			assert.are.equal("ERROR", moveResponse.type)
			assert.are.equal("NOT_IN_GAME", moveResponse.payload.code)
		end)

		it("rejects invalid move", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			-- Create AI game
			Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))

			-- Try invalid move (too far)
			local moveMsg = Protocol.moveMessage({ col = 1, row = 2 }, { col = 1, row = 6 })
			local moveResponse = Server.handleMessage(server, clientId, moveMsg)

			assert.are.equal("ERROR", moveResponse.type)
			assert.are.equal("INVALID_MOVE", moveResponse.payload.code)
		end)

		it("returns updated game state after valid move", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			-- Create AI game
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))
			local gameId = response.payload.game_id

			-- Make a valid move
			local moveMsg = Protocol.moveMessage({ col = 1, row = 2 }, { col = 1, row = 3 })
			local moveResponse = Server.handleMessage(server, clientId, moveMsg)

			assert.are.equal("GAME_STATE", moveResponse.type)
			assert.are.equal(gameId, moveResponse.payload.game_id)
			-- Turn should have advanced (now AI's turn = player 2)
			assert.are.equal(2, moveResponse.payload.current_player)
		end)
	end)

	-- 12. Player Stats Tracking
	describe("Player Stats", function()
		it("creates stats for player on connect", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			local client = Server.getClient(server, clientId)
			assert.is_not_nil(server.playerStats[client.playerId])
			assert.is_not_nil(server.playerStats[client.playerId].ai)
		end)

		it("initializes stats with zero games", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			local client = Server.getClient(server, clientId)
			local stats = server.playerStats[client.playerId]
			assert.are.equal(0, stats.ai.easy.games)
			assert.are.equal(0, stats.ai.medium.games)
		end)

		it("records AI game win when player wins", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			-- Create AI game
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("easy"))
			local gameId = response.payload.game_id
			local session = Server.getGameSession(server, gameId)

			-- Simulate game over with player 1 winning
			session.state.gameState = "gameover"
			session.state.winner = 1
			session.status = "finished"

			-- Record the game result
			local client = Server.getClient(server, clientId)
			Server.recordGameResult(server, gameId)

			local stats = server.playerStats[client.playerId]
			assert.are.equal(1, stats.ai.easy.games)
			assert.are.equal(1, stats.ai.easy.wins)
			assert.are.equal(0, stats.ai.easy.losses)
		end)

		it("records AI game loss when AI wins", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			-- Create AI game
			local response = Server.handleMessage(server, clientId, Protocol.createAIGameMessage("hard"))
			local gameId = response.payload.game_id
			local session = Server.getGameSession(server, gameId)

			-- Simulate game over with AI (player 2) winning
			session.state.gameState = "gameover"
			session.state.winner = 2
			session.status = "finished"

			-- Record the game result
			local client = Server.getClient(server, clientId)
			Server.recordGameResult(server, gameId)

			local stats = server.playerStats[client.playerId]
			assert.are.equal(1, stats.ai.hard.games)
			assert.are.equal(0, stats.ai.hard.wins)
			assert.are.equal(1, stats.ai.hard.losses)
		end)

		it("getPlayerStats returns stats for player", function()
			local server = Server.create({})
			local clientId = Server.addClient(server, { id = "sock1" })
			Server.handleMessage(server, clientId, Protocol.connectMessage("Alice", "0.1.0"))

			local client = Server.getClient(server, clientId)
			local stats = Server.getPlayerStats(server, client.playerId)

			assert.is_not_nil(stats)
			assert.is_not_nil(stats.ai)
			assert.is_not_nil(stats.rating)
		end)
	end)
end)
