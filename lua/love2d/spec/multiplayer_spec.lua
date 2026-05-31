-- Busted tests for Multiplayer integration and server handlers
-- nnqr-21: server-authoritative multiplayer (Phase 10B/10C)
-- Run with: busted spec/

describe("Server handlers (nnqr-21)", function()
	local Server
	local Protocol
	local GameSession

	setup(function()
		Server = require("server.server")
		Protocol = require("src.shared.protocol")
		GameSession = require("server.game_session")
	end)

	-- Helper: connect two players and start a PvP game.
	-- Returns server, clientId1, clientId2, playerId1, playerId2, gameId.
	local function setupPvPGame()
		local server = Server.create({})

		local cid1 = Server.addClient(server, { id = "s1" })
		local r1 = Server.handleMessage(server, cid1, Protocol.connectMessage("Alice", "0.1.0"))
		local pid1 = r1.payload.player_id

		local cid2 = Server.addClient(server, { id = "s2" })
		local r2 = Server.handleMessage(server, cid2, Protocol.connectMessage("Bob", "0.1.0"))
		local pid2 = r2.payload.player_id

		local cr = Server.handleMessage(server, cid1, Protocol.createMessage("CREATE_GAME", { game_name = "PvP" }))
		local gameId = cr.payload.game_id

		-- Second player joins -> game starts
		Server.handleMessage(server, cid2, Protocol.createMessage("JOIN_GAME", { game_id = gameId }))

		return server, cid1, cid2, pid1, pid2, gameId
	end

	-- -----------------------------------------------------------------------
	-- 1. JOIN_GAME creates a real GameLogic-backed PvP session
	-- -----------------------------------------------------------------------
	describe("JOIN_GAME - real session creation", function()
		it("creates a GameSession when second player joins", function()
			local server, _, _, _, _, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			assert.is_not_nil(session)
			assert.are.equal("playing", session.status)
		end)

		it("session is NOT an AI game", function()
			local server, _, _, _, _, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			assert.is_false(GameSession.isAIGame(session))
		end)

		it("session stores correct player IDs", function()
			local server, _, _, pid1, pid2, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			-- Player 1 created the game, player 2 joined
			assert.are.equal(pid1, session.player1Id)
			assert.are.equal(pid2, session.player2Id)
		end)

		it("JOIN_GAME response is GAME_STATE with board and pieces", function()
			local server = Server.create({})
			local cid1 = Server.addClient(server, { id = "s1" })
			Server.handleMessage(server, cid1, Protocol.connectMessage("Alice", "0.1.0"))
			local cr = Server.handleMessage(server, cid1, Protocol.createMessage("CREATE_GAME", { game_name = "G" }))
			local gameId = cr.payload.game_id

			local cid2 = Server.addClient(server, { id = "s2" })
			Server.handleMessage(server, cid2, Protocol.connectMessage("Bob", "0.1.0"))
			local resp = Server.handleMessage(server, cid2, Protocol.createMessage("JOIN_GAME", { game_id = gameId }))

			assert.are.equal("GAME_STATE", resp.type)
			assert.is_table(resp.payload.board)
			assert.is_table(resp.payload.pieces)
			assert.is_true(#resp.payload.pieces > 0)
		end)

		it("GAME_STATE response includes current_player = 1", function()
			local server = Server.create({})
			local cid1 = Server.addClient(server, { id = "s1" })
			Server.handleMessage(server, cid1, Protocol.connectMessage("Alice", "0.1.0"))
			local cr = Server.handleMessage(server, cid1, Protocol.createMessage("CREATE_GAME", { game_name = "G" }))
			local gameId = cr.payload.game_id

			local cid2 = Server.addClient(server, { id = "s2" })
			Server.handleMessage(server, cid2, Protocol.connectMessage("Bob", "0.1.0"))
			local resp = Server.handleMessage(server, cid2, Protocol.createMessage("JOIN_GAME", { game_id = gameId }))

			assert.are.equal(1, resp.payload.current_player)
		end)

		it("server rejects an out-of-turn move from player 2", function()
			local server, _, cid2 = setupPvPGame()
			-- It is player 1's turn; player 2 tries to move
			local moveMsg = Protocol.moveMessage({ col = 1, row = 7 }, { col = 1, row = 6 })
			local resp = Server.handleMessage(server, cid2, moveMsg)
			assert.are.equal("ERROR", resp.type)
			assert.are.equal("NOT_YOUR_TURN", resp.payload.code)
		end)

		it("server accepts a legal move from player 1 and returns GAME_STATE", function()
			local server, cid1 = setupPvPGame()
			-- Player 1 pieces start in rows 1-2; row 2 -> row 3 is one step forward
			local moveMsg = Protocol.moveMessage({ col = 1, row = 2 }, { col = 1, row = 3 })
			local resp = Server.handleMessage(server, cid1, moveMsg)
			assert.are.equal("GAME_STATE", resp.type)
			-- Turn passed to player 2
			assert.are.equal(2, resp.payload.current_player)
		end)
	end)

	-- -----------------------------------------------------------------------
	-- 2. ACTIVATE_POWER handler
	-- -----------------------------------------------------------------------
	describe("ACTIVATE_POWER", function()
		-- Helper: set up a PvP game where player 1 has at least one power
		local function setupGameWithPower(powerId)
			local server, cid1, cid2, pid1, pid2, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			-- Inject a known power onto the first piece belonging to player 1
			local targetPiece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					targetPiece = p
					break
				end
			end
			assert.is_not_nil(targetPiece, "No player-1 piece found in test setup")
			targetPiece.powers = targetPiece.powers or {}
			table.insert(targetPiece.powers, powerId)
			return server, cid1, cid2, pid1, pid2, gameId, targetPiece
		end

		it("returns ERROR NOT_IMPLEMENTED replaced: ACTIVATE_POWER now routes properly", function()
			-- After implementation, ACTIVATE_POWER must NOT return NOT_IMPLEMENTED
			local server, cid1, _, _, _, _, piece = setupGameWithPower("move_diagonal")
			local msg = Protocol.activatePowerMessage({ col = piece.col, row = piece.row }, "move_diagonal", nil)
			local resp = Server.handleMessage(server, cid1, msg)
			-- Must NOT be the old stub
			assert.are_not.equal("NOT_IMPLEMENTED", resp.payload and resp.payload.code or "")
		end)

		it("rejects ACTIVATE_POWER when not player's turn", function()
			local server, _, cid2, _, _, _, piece = setupGameWithPower("move_diagonal")
			-- It is player 1's turn; player 2 tries to activate
			local msg = Protocol.activatePowerMessage({ col = piece.col, row = piece.row }, "move_diagonal", nil)
			local resp = Server.handleMessage(server, cid2, msg)
			assert.are.equal("ERROR", resp.type)
			assert.are.equal("NOT_YOUR_TURN", resp.payload.code)
		end)

		it("rejects ACTIVATE_POWER when piece not owned by player", function()
			local server, cid1, cid2, _, _, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			-- Give a power to a player-2 piece, then try to activate as player 1
			local p2Piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 2 then
					p2Piece = p
					break
				end
			end
			assert.is_not_nil(p2Piece, "No player-2 piece found in test setup")
			p2Piece.powers = p2Piece.powers or {}
			table.insert(p2Piece.powers, "move_diagonal")

			local msg = Protocol.activatePowerMessage({ col = p2Piece.col, row = p2Piece.row }, "move_diagonal", nil)
			local resp = Server.handleMessage(server, cid1, msg)
			assert.are.equal("ERROR", resp.type)
		end)

		it("rejects ACTIVATE_POWER when piece does not have the power", function()
			local server, cid1, _, _, _, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			local p1Piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					p1Piece = p
					break
				end
			end
			-- Piece has NO powers
			p1Piece.powers = {}
			local msg = Protocol.activatePowerMessage({ col = p1Piece.col, row = p1Piece.row }, "move_diagonal", nil)
			local resp = Server.handleMessage(server, cid1, msg)
			assert.are.equal("ERROR", resp.type)
			assert.are.equal("NO_POWER", resp.payload.code)
		end)

		it("successful ACTIVATE_POWER returns GAME_STATE (or POWER_RESULT)", function()
			local server, cid1, _, _, _, _, piece = setupGameWithPower("move_diagonal")
			local msg = Protocol.activatePowerMessage({ col = piece.col, row = piece.row }, "move_diagonal", nil)
			local resp = Server.handleMessage(server, cid1, msg)
			-- Must be either GAME_STATE or POWER_RESULT on success
			assert.is_true(
				resp.type == "GAME_STATE" or resp.type == "POWER_RESULT",
				"Expected GAME_STATE or POWER_RESULT but got: " .. tostring(resp.type)
			)
		end)

		it("power is consumed (removed from piece) after activation", function()
			local server, cid1, _, _, _, gameId, piece = setupGameWithPower("move_diagonal")
			local msg = Protocol.activatePowerMessage({ col = piece.col, row = piece.row }, "move_diagonal", nil)
			Server.handleMessage(server, cid1, msg)
			-- Piece should no longer have the power
			local session = server.gameSessions[gameId]
			local updatedPiece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.col == piece.col and p.row == piece.row then
					updatedPiece = p
					break
				end
			end
			if updatedPiece then
				local found = false
				for _, pw in ipairs(updatedPiece.powers or {}) do
					if pw == "move_diagonal" then
						found = true
						break
					end
				end
				assert.is_false(found, "Power should be consumed after activation")
			end
		end)
	end)

	-- -----------------------------------------------------------------------
	-- 3. CHAT handler
	-- -----------------------------------------------------------------------
	describe("CHAT", function()
		local function makeChat(server, clientId, text)
			return Server.handleMessage(server, clientId, Protocol.createMessage("CHAT", { text = text }))
		end

		it("returns ERROR NOT_IMPLEMENTED replaced: CHAT now routes properly", function()
			local server, cid1 = setupPvPGame()
			local resp = makeChat(server, cid1, "hello")
			assert.are_not.equal("NOT_IMPLEMENTED", resp.payload and resp.payload.code or "")
		end)

		it("player not in a game cannot send chat", function()
			local server = Server.create({})
			local cid = Server.addClient(server, { id = "s1" })
			Server.handleMessage(server, cid, Protocol.connectMessage("Alice", "0.1.0"))
			-- Not in a game
			local resp = makeChat(server, cid, "hello")
			assert.are.equal("ERROR", resp.type)
		end)

		it("chat returns CHAT_MESSAGE broadcast info", function()
			local server, cid1 = setupPvPGame()
			local resp = makeChat(server, cid1, "Good game!")
			-- Either a CHAT_MESSAGE echo or a {type, opponentClientId} broadcast descriptor
			-- The handler returns the message to broadcast; type must be CHAT_MESSAGE
			assert.are.equal("CHAT_MESSAGE", resp.type)
		end)

		it("CHAT_MESSAGE payload includes sender name and text", function()
			local server, cid1 = setupPvPGame()
			local resp = makeChat(server, cid1, "hello there")
			assert.are.equal("CHAT_MESSAGE", resp.type)
			assert.is_string(resp.payload.sender_name)
			assert.are.equal("hello there", resp.payload.text)
		end)
	end)

	-- -----------------------------------------------------------------------
	-- 4. Disconnect timeout enforcement via Server.update
	-- -----------------------------------------------------------------------
	describe("Server.update - disconnect timeout enforcement", function()
		it("Server.update exists and accepts dt + optional nowFn", function()
			local server = Server.create({})
			local ok = pcall(function()
				Server.update(server, 0.016, nil)
			end)
			assert.is_true(ok, "Server.update should not raise an error")
		end)

		it("Server.update returns empty results when no sessions", function()
			local server = Server.create({})
			local results = Server.update(server, 0.016, nil)
			assert.is_table(results)
			assert.are.equal(0, #results)
		end)

		it("injected nowFn is used for timeout check (no real sleep)", function()
			local server, cid1, cid2, pid1, pid2, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]

			-- Simulate player 1 disconnecting 61 seconds ago
			local fakeDisconnectTime = 1000
			session.disconnectedPlayer = 1
			session.disconnectTime = fakeDisconnectTime

			-- Inject a clock that says "now = 1061" (61s after disconnect)
			local fakeNow = fakeDisconnectTime + 61
			local results = Server.update(server, 0.016, function()
				return fakeNow
			end)

			-- Should produce one timeout result
			assert.is_true(#results >= 1)
			local found = false
			for _, r in ipairs(results) do
				if r.gameId == gameId then
					found = true
					assert.are.equal("timeout", r.type)
					assert.are.equal(2, r.winnerNumber)
				end
			end
			assert.is_true(found, "Expected timeout result for gameId " .. gameId)
		end)

		it("does NOT fire timeout before 60s with injected clock", function()
			local server, _, _, _, _, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]

			local fakeDisconnectTime = 1000
			session.disconnectedPlayer = 1
			session.disconnectTime = fakeDisconnectTime

			-- Only 30 seconds have elapsed
			local fakeNow = fakeDisconnectTime + 30
			local results = Server.update(server, 0.016, function()
				return fakeNow
			end)

			for _, r in ipairs(results) do
				assert.are_not.equal(gameId, r.gameId, "Should not timeout before 60s for game " .. gameId)
			end
		end)

		it("session is marked finished after timeout", function()
			local server, _, _, _, _, gameId = setupPvPGame()
			local session = server.gameSessions[gameId]
			local fakeNow = 2000
			session.disconnectedPlayer = 1
			session.disconnectTime = fakeNow - 65

			Server.update(server, 0.016, function()
				return fakeNow
			end)

			assert.are.equal("finished", session.status)
		end)
	end)

	-- -----------------------------------------------------------------------
	-- 5. Multiplayer module - connect -> lobby -> sync -> move -> disconnect
	-- -----------------------------------------------------------------------
	describe("Multiplayer module", function()
		local Multiplayer

		setup(function()
			Multiplayer = require("src.client.multiplayer")
		end)

		it("Multiplayer.create returns a table with expected fields", function()
			local mp = Multiplayer.create()
			assert.is_table(mp)
			assert.is_table(mp.network)
			assert.is_table(mp.lobby)
			assert.is_string(mp.playerName)
			assert.is_nil(mp.playerNumber)
			assert.is_nil(mp.gameState)
		end)

		it("Multiplayer.isConnected returns false before connect", function()
			local mp = Multiplayer.create()
			assert.is_false(Multiplayer.isConnected(mp))
		end)

		it("processMessage WELCOME sets statusMessage", function()
			local mp = Multiplayer.create()
			mp.playerName = "Alice"
			-- Simulate WELCOME message from server
			local welcomeMsg = Protocol.createMessage("WELCOME", { player_id = "p_test" })
			mp.network.playerId = nil
			mp.network.state = "connected"
			local event = Multiplayer.processMessage(mp, welcomeMsg)
			assert.are.equal("connected", event)
			assert.is_truthy(mp.statusMessage:find("Connected"))
		end)

		it("processMessage LOBBY_STATE returns lobby_updated", function()
			local mp = Multiplayer.create()
			local msg = Protocol.createMessage("LOBBY_STATE", { games = {}, players_online = 0 })
			local event = Multiplayer.processMessage(mp, msg)
			assert.are.equal("lobby_updated", event)
		end)

		it("processMessage GAME_STATE sets gameState and returns game_started", function()
			local mp = Multiplayer.create()
			mp.playerNumber = nil
			local statePayload = {
				game_id = "g1",
				turn = 1,
				current_player = 1,
				phase = "move",
				board = { cols = 10, rows = 8, tiles = {} },
				pieces = {},
				winner = nil,
			}
			local msg = Protocol.createMessage("GAME_STATE", statePayload)
			local event = Multiplayer.processMessage(mp, msg)
			assert.are.equal("game_started", event)
			assert.is_not_nil(mp.gameState)
		end)

		it("processMessage GAME_STATE second time returns game_state_updated", function()
			local mp = Multiplayer.create()
			mp.playerNumber = 2
			local statePayload = {
				game_id = "g1",
				turn = 1,
				current_player = 2,
				phase = "move",
				board = { cols = 10, rows = 8, tiles = {} },
				pieces = {},
				winner = nil,
			}
			-- First time
			Multiplayer.processMessage(mp, Protocol.createMessage("GAME_STATE", statePayload))
			-- Second time (update)
			local event = Multiplayer.processMessage(mp, Protocol.createMessage("GAME_STATE", statePayload))
			assert.are.equal("game_state_updated", event)
		end)

		it("processMessage OPPONENT_DISCONNECTED sets disconnect state", function()
			local mp = Multiplayer.create()
			local msg = Protocol.createMessage("OPPONENT_DISCONNECTED", {
				game_id = "g1",
				opponent_name = "Bob",
				reconnect_timeout = 60,
			})
			local event = Multiplayer.processMessage(mp, msg)
			assert.are.equal("opponent_disconnected", event)
			assert.is_true(mp.opponentDisconnected)
			assert.are.equal("Bob", mp.opponentName)
			assert.is_not_nil(mp.disconnectTime)
		end)

		it("processMessage OPPONENT_RECONNECTED clears disconnect state", function()
			local mp = Multiplayer.create()
			mp.opponentDisconnected = true
			mp.opponentName = "Bob"
			mp.disconnectTime = os.time()

			local msg = Protocol.createMessage("OPPONENT_RECONNECTED", {
				game_id = "g1",
				opponent_name = "Bob",
			})
			local event = Multiplayer.processMessage(mp, msg)
			assert.are.equal("opponent_reconnected", event)
			assert.is_false(mp.opponentDisconnected)
			assert.is_nil(mp.disconnectTime)
		end)

		it("Multiplayer.isMyTurn returns false when not in game", function()
			local mp = Multiplayer.create()
			assert.is_false(Multiplayer.isMyTurn(mp))
		end)

		it("Multiplayer.isMyTurn returns true when it is player's turn", function()
			local mp = Multiplayer.create()
			mp.playerNumber = 1
			mp.gameState = { currentPlayer = 1 }
			assert.is_true(Multiplayer.isMyTurn(mp))
		end)

		it("Multiplayer.isMyTurn returns false when not player's turn", function()
			local mp = Multiplayer.create()
			mp.playerNumber = 1
			mp.gameState = { currentPlayer = 2 }
			assert.is_false(Multiplayer.isMyTurn(mp))
		end)

		it("Multiplayer.disconnect resets game state", function()
			local mp = Multiplayer.create()
			mp.playerNumber = 1
			mp.gameState = { currentPlayer = 1 }
			-- Set network state directly without real socket
			mp.network.state = "disconnected"
			Multiplayer.disconnect(mp)
			assert.is_nil(mp.playerNumber)
			assert.is_nil(mp.gameState)
		end)

		it("getDisconnectStatus returns disconnected=false when no disconnect", function()
			local mp = Multiplayer.create()
			local status = Multiplayer.getDisconnectStatus(mp)
			assert.is_false(status.disconnected)
		end)

		it("getDisconnectStatus returns correct data when opponent disconnected", function()
			local mp = Multiplayer.create()
			mp.opponentDisconnected = true
			mp.opponentName = "Charlie"
			mp.disconnectTime = os.time()
			mp.reconnectTimeout = 60
			local status = Multiplayer.getDisconnectStatus(mp)
			assert.is_true(status.disconnected)
			assert.are.equal("Charlie", status.opponentName)
			assert.is_true(status.timeRemaining >= 0)
		end)

		it("processMessage GAME_OVER sets winner on gameState", function()
			local mp = Multiplayer.create()
			mp.gameState = { currentPlayer = 1 }
			local msg = Protocol.createMessage("GAME_OVER", { game_id = "g1", winner = 2 })
			local event = Multiplayer.processMessage(mp, msg)
			assert.are.equal("game_over", event)
			assert.are.equal(2, mp.gameState.winner)
			assert.is_true(mp.gameState.gameOver)
		end)
	end)

	-- -----------------------------------------------------------------------
	-- 6. Protocol - POWER_RESULT and CHAT_MESSAGE message builders
	-- -----------------------------------------------------------------------
	describe("Protocol message builders", function()
		it("Protocol.powerResultMessage creates POWER_RESULT message", function()
			local msg = Protocol.powerResultMessage("g1", true, "move_diagonal", {})
			assert.are.equal("POWER_RESULT", msg.type)
			assert.are.equal("g1", msg.payload.game_id)
			assert.is_true(msg.payload.success)
			assert.are.equal("move_diagonal", msg.payload.power_id)
		end)

		it("Protocol.chatMessage creates CHAT_MESSAGE message", function()
			local msg = Protocol.chatMessage("g1", "Alice", "Hello!")
			assert.are.equal("CHAT_MESSAGE", msg.type)
			assert.are.equal("g1", msg.payload.game_id)
			assert.are.equal("Alice", msg.payload.sender_name)
			assert.are.equal("Hello!", msg.payload.text)
		end)
	end)

	-- -----------------------------------------------------------------------
	-- 7. GameSession.handleActivatePower (mirrors handleMove pattern)
	-- -----------------------------------------------------------------------
	describe("GameSession.handleActivatePower", function()
		local function sessionWithPower(powerId)
			local session = GameSession.create("g1", "p1", "p2")
			-- Give player 1's first piece the requested power
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					p.powers = p.powers or {}
					table.insert(p.powers, powerId)
					return session, p
				end
			end
			error("No player-1 piece found")
		end

		it("exists as a function on GameSession", function()
			assert.are.equal("function", type(GameSession.handleActivatePower))
		end)

		it("returns error when not player's turn", function()
			local session = GameSession.create("g1", "p1", "p2")
			-- It is player 1's turn; try as player 2
			local p2Piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 2 then
					p2Piece = p
					break
				end
			end
			p2Piece.powers = { "move_diagonal" }
			local result = GameSession.handleActivatePower(session, "p2", {
				piece_pos = { col = p2Piece.col, row = p2Piece.row },
				power_id = "move_diagonal",
			})
			assert.is_false(result.success)
			assert.are.equal("NOT_YOUR_TURN", result.error)
		end)

		it("returns error when piece not owned by player", function()
			local session = GameSession.create("g1", "p1", "p2")
			-- Give p2's piece a power; player 1 tries to activate it
			local p2Piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 2 then
					p2Piece = p
					break
				end
			end
			p2Piece.powers = { "move_diagonal" }
			local result = GameSession.handleActivatePower(session, "p1", {
				piece_pos = { col = p2Piece.col, row = p2Piece.row },
				power_id = "move_diagonal",
			})
			assert.is_false(result.success)
			assert.are.equal("NOT_YOUR_PIECE", result.error)
		end)

		it("returns error when piece has no such power", function()
			local session = GameSession.create("g1", "p1", "p2")
			local p1Piece = nil
			for _, p in ipairs(session.state.pieces) do
				if p.player == 1 then
					p1Piece = p
					break
				end
			end
			p1Piece.powers = {}
			local result = GameSession.handleActivatePower(session, "p1", {
				piece_pos = { col = p1Piece.col, row = p1Piece.row },
				power_id = "move_diagonal",
			})
			assert.is_false(result.success)
			assert.are.equal("NO_POWER", result.error)
		end)

		it("succeeds for a valid power activation", function()
			local session, piece = sessionWithPower("move_diagonal")
			local result = GameSession.handleActivatePower(session, "p1", {
				piece_pos = { col = piece.col, row = piece.row },
				power_id = "move_diagonal",
			})
			assert.is_true(result.success)
		end)

		it("power is consumed after activation", function()
			local session, piece = sessionWithPower("move_diagonal")
			GameSession.handleActivatePower(session, "p1", {
				piece_pos = { col = piece.col, row = piece.row },
				power_id = "move_diagonal",
			})
			local found = false
			for _, pw in ipairs(piece.powers or {}) do
				if pw == "move_diagonal" then
					found = true
				end
			end
			assert.is_false(found, "Power should be consumed after activation")
		end)
	end)
end)
