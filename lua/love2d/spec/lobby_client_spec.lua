-- Busted tests for LobbyClient module
-- Phase 10B: Client Networking - Lobby Operations
-- Run with: busted spec/

describe("LobbyClient", function()
	local LobbyClient
	local Network
	local Protocol

	-- Mock network that captures sent messages
	local function createMockNetwork()
		return {
			state = "connected",
			playerId = "player_123",
			sentMessages = {},
			messageQueue = {},
		}
	end

	setup(function()
		LobbyClient = require("src.client.lobby_client")
		Network = require("src.client.network")
		Protocol = require("src.shared.protocol")
	end)

	-- 1. LobbyClient.create()
	describe("create", function()
		it("returns a table", function()
			local lobby = LobbyClient.create()
			assert.is_table(lobby)
		end)

		it("initializes empty games list", function()
			local lobby = LobbyClient.create()
			assert.is_table(lobby.games)
			assert.are.equal(0, #lobby.games)
		end)

		it("initializes nil current game", function()
			local lobby = LobbyClient.create()
			assert.is_nil(lobby.currentGameId)
		end)

		it("sets state to browsing", function()
			local lobby = LobbyClient.create()
			assert.are.equal("browsing", lobby.state)
		end)
	end)

	-- 2. LobbyClient.createJoinLobbyMessage()
	describe("createJoinLobbyMessage", function()
		it("creates JOIN_LOBBY message", function()
			local msg = LobbyClient.createJoinLobbyMessage()
			assert.are.equal("JOIN_LOBBY", msg.type)
			assert.is_table(msg.payload)
		end)
	end)

	-- 3. LobbyClient.createCreateGameMessage()
	describe("createCreateGameMessage", function()
		it("creates CREATE_GAME message with name", function()
			local msg = LobbyClient.createCreateGameMessage("My Game")
			assert.are.equal("CREATE_GAME", msg.type)
			assert.are.equal("My Game", msg.payload.game_name)
		end)

		it("includes optional settings", function()
			local settings = { power_spawn_interval = 5 }
			local msg = LobbyClient.createCreateGameMessage("Test", settings)
			assert.are.equal(5, msg.payload.settings.power_spawn_interval)
		end)
	end)

	-- 4. LobbyClient.createJoinGameMessage()
	describe("createJoinGameMessage", function()
		it("creates JOIN_GAME message with game ID", function()
			local msg = LobbyClient.createJoinGameMessage("game_123")
			assert.are.equal("JOIN_GAME", msg.type)
			assert.are.equal("game_123", msg.payload.game_id)
		end)
	end)

	-- 5. LobbyClient.createLeaveGameMessage()
	describe("createLeaveGameMessage", function()
		it("creates LEAVE_GAME message", function()
			local msg = LobbyClient.createLeaveGameMessage()
			assert.are.equal("LEAVE_GAME", msg.type)
		end)
	end)

	-- 6. LobbyClient.handleLobbyState()
	describe("handleLobbyState", function()
		it("updates games list from LOBBY_STATE", function()
			local lobby = LobbyClient.create()
			local msg = {
				type = "LOBBY_STATE",
				payload = {
					games = {
						{ game_id = "g1", game_name = "Game 1", players = { "Alice" }, status = "waiting" },
						{ game_id = "g2", game_name = "Game 2", players = { "Bob", "Carol" }, status = "playing" },
					},
					players_online = 5,
				},
			}
			LobbyClient.handleLobbyState(lobby, msg)
			assert.are.equal(2, #lobby.games)
			assert.are.equal("g1", lobby.games[1].game_id)
			assert.are.equal("Game 1", lobby.games[1].game_name)
		end)

		it("stores player count", function()
			local lobby = LobbyClient.create()
			local msg = {
				type = "LOBBY_STATE",
				payload = {
					games = {},
					players_online = 10,
				},
			}
			LobbyClient.handleLobbyState(lobby, msg)
			assert.are.equal(10, lobby.playersOnline)
		end)
	end)

	-- 7. LobbyClient.handleGameCreated()
	describe("handleGameCreated", function()
		it("stores current game ID", function()
			local lobby = LobbyClient.create()
			local msg = {
				type = "GAME_CREATED",
				payload = {
					game_id = "game_456",
				},
			}
			LobbyClient.handleGameCreated(lobby, msg)
			assert.are.equal("game_456", lobby.currentGameId)
		end)

		it("sets state to waiting", function()
			local lobby = LobbyClient.create()
			LobbyClient.handleGameCreated(lobby, {
				type = "GAME_CREATED",
				payload = { game_id = "g1" },
			})
			assert.are.equal("waiting", lobby.state)
		end)
	end)

	-- 8. LobbyClient.handleGameJoined()
	describe("handleGameJoined", function()
		it("stores current game ID", function()
			local lobby = LobbyClient.create()
			LobbyClient.handleGameJoined(lobby, {
				type = "GAME_JOINED",
				payload = { game_id = "game_789", status = "waiting" },
			})
			assert.are.equal("game_789", lobby.currentGameId)
		end)

		it("sets state based on game status", function()
			local lobby = LobbyClient.create()
			LobbyClient.handleGameJoined(lobby, {
				type = "GAME_JOINED",
				payload = { game_id = "g1", status = "waiting" },
			})
			assert.are.equal("waiting", lobby.state)
		end)
	end)

	-- 9. LobbyClient.handleGameState()
	describe("handleGameState", function()
		it("sets state to playing when game starts", function()
			local lobby = LobbyClient.create()
			lobby.currentGameId = "g1"
			LobbyClient.handleGameState(lobby, {
				type = "GAME_STATE",
				payload = { game_id = "g1", turn = 1 },
			})
			assert.are.equal("playing", lobby.state)
		end)

		it("stores game state", function()
			local lobby = LobbyClient.create()
			local gameState = {
				type = "GAME_STATE",
				payload = {
					game_id = "g1",
					turn = 5,
					current_player = 2,
					pieces = {},
				},
			}
			LobbyClient.handleGameState(lobby, gameState)
			assert.are.equal(5, lobby.gameState.turn)
			assert.are.equal(2, lobby.gameState.current_player)
		end)
	end)

	-- 10. LobbyClient.handleError()
	describe("handleError", function()
		it("stores error message", function()
			local lobby = LobbyClient.create()
			LobbyClient.handleError(lobby, {
				type = "ERROR",
				payload = { code = "GAME_FULL", message = "Game is full" },
			})
			assert.are.equal("GAME_FULL", lobby.lastError.code)
			assert.are.equal("Game is full", lobby.lastError.message)
		end)
	end)

	-- 11. LobbyClient.processMessage()
	describe("processMessage", function()
		it("routes LOBBY_STATE to handler", function()
			local lobby = LobbyClient.create()
			LobbyClient.processMessage(lobby, {
				type = "LOBBY_STATE",
				payload = { games = {}, players_online = 3 },
			})
			assert.are.equal(3, lobby.playersOnline)
		end)

		it("routes GAME_CREATED to handler", function()
			local lobby = LobbyClient.create()
			LobbyClient.processMessage(lobby, {
				type = "GAME_CREATED",
				payload = { game_id = "test_game" },
			})
			assert.are.equal("test_game", lobby.currentGameId)
		end)

		it("routes ERROR to handler", function()
			local lobby = LobbyClient.create()
			LobbyClient.processMessage(lobby, {
				type = "ERROR",
				payload = { code = "TEST", message = "Test error" },
			})
			assert.are.equal("TEST", lobby.lastError.code)
		end)

		it("returns false for unknown message type", function()
			local lobby = LobbyClient.create()
			local result = LobbyClient.processMessage(lobby, {
				type = "UNKNOWN_TYPE",
				payload = {},
			})
			assert.is_false(result)
		end)
	end)

	-- 12. LobbyClient.getGames()
	describe("getGames", function()
		it("returns games list", function()
			local lobby = LobbyClient.create()
			lobby.games = {
				{ game_id = "g1", game_name = "Test" },
			}
			local games = LobbyClient.getGames(lobby)
			assert.are.equal(1, #games)
			assert.are.equal("g1", games[1].game_id)
		end)
	end)

	-- 13. LobbyClient.getWaitingGames()
	describe("getWaitingGames", function()
		it("filters to only waiting games", function()
			local lobby = LobbyClient.create()
			lobby.games = {
				{ game_id = "g1", status = "waiting" },
				{ game_id = "g2", status = "playing" },
				{ game_id = "g3", status = "waiting" },
			}
			local waiting = LobbyClient.getWaitingGames(lobby)
			assert.are.equal(2, #waiting)
		end)
	end)

	-- 14. LobbyClient.isInGame()
	describe("isInGame", function()
		it("returns false when not in game", function()
			local lobby = LobbyClient.create()
			assert.is_false(LobbyClient.isInGame(lobby))
		end)

		it("returns true when in game", function()
			local lobby = LobbyClient.create()
			lobby.currentGameId = "g1"
			assert.is_true(LobbyClient.isInGame(lobby))
		end)
	end)

	-- 15. LobbyClient.leaveCurrentGame()
	describe("leaveCurrentGame", function()
		it("clears current game ID", function()
			local lobby = LobbyClient.create()
			lobby.currentGameId = "g1"
			lobby.state = "playing"
			LobbyClient.leaveCurrentGame(lobby)
			assert.is_nil(lobby.currentGameId)
		end)

		it("sets state to browsing", function()
			local lobby = LobbyClient.create()
			lobby.state = "playing"
			LobbyClient.leaveCurrentGame(lobby)
			assert.are.equal("browsing", lobby.state)
		end)

		it("clears game state", function()
			local lobby = LobbyClient.create()
			lobby.gameState = { turn = 5 }
			LobbyClient.leaveCurrentGame(lobby)
			assert.is_nil(lobby.gameState)
		end)
	end)

	-- 16. Available Player Count - Phase 1
	describe("getAvailablePlayerCount", function()
		it("returns 0 by default", function()
			local lobby = LobbyClient.create()
			assert.are.equal(0, LobbyClient.getAvailablePlayerCount(lobby))
		end)

		it("returns stored count", function()
			local lobby = LobbyClient.create()
			lobby.availablePlayers = 5
			assert.are.equal(5, LobbyClient.getAvailablePlayerCount(lobby))
		end)
	end)

	describe("handleLobbyState with availablePlayers", function()
		it("stores available player count from message", function()
			local lobby = LobbyClient.create()
			LobbyClient.handleLobbyState(lobby, {
				type = "LOBBY_STATE",
				payload = {
					games = {},
					players_online = 10,
					available_players = 7,
				},
			})
			assert.are.equal(7, lobby.availablePlayers)
		end)

		it("defaults to 0 if not provided", function()
			local lobby = LobbyClient.create()
			LobbyClient.handleLobbyState(lobby, {
				type = "LOBBY_STATE",
				payload = {
					games = {},
					players_online = 10,
				},
			})
			assert.are.equal(0, lobby.availablePlayers)
		end)
	end)
end)
