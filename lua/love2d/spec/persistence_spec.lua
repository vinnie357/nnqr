-- Busted tests for Persistence module
-- Phase 10A: Network Multiplayer - File Persistence
-- Run with: busted spec/

describe("Persistence", function()
	local Persistence
	local testFilePath = "/tmp/nnqr_test_persistence.json"

	setup(function()
		Persistence = require("server.persistence")
	end)

	-- Clean up test file before/after tests
	before_each(function()
		os.remove(testFilePath)
	end)

	after_each(function()
		os.remove(testFilePath)
	end)

	-- 1. Persistence.saveData()
	describe("saveData", function()
		it("saves data to file", function()
			local data = { test = "value", count = 42 }
			local success, err = Persistence.saveData(testFilePath, data)
			assert.is_true(success)
			assert.is_nil(err)
			-- Verify file exists
			local file = io.open(testFilePath, "r")
			assert.is_not_nil(file)
			file:close()
		end)

		it("creates valid JSON", function()
			local data = { name = "test", items = { 1, 2, 3 } }
			Persistence.saveData(testFilePath, data)
			local file = io.open(testFilePath, "r")
			local content = file:read("*all")
			file:close()
			-- Should contain JSON-like content
			assert.is_truthy(content:find('"name"'))
			assert.is_truthy(content:find('"test"'))
		end)

		it("handles nested tables", function()
			local data = {
				player = { name = "Alice", score = 100 },
				game = { id = "g1", status = "playing" },
			}
			local success = Persistence.saveData(testFilePath, data)
			assert.is_true(success)
		end)

		it("returns error for invalid path", function()
			local data = { test = "value" }
			local success, err = Persistence.saveData("/nonexistent/dir/file.json", data)
			assert.is_false(success)
			assert.is_not_nil(err)
		end)
	end)

	-- 2. Persistence.loadData()
	describe("loadData", function()
		it("loads data from file", function()
			local original = { test = "value", count = 42 }
			Persistence.saveData(testFilePath, original)
			local loaded, err = Persistence.loadData(testFilePath)
			assert.is_nil(err)
			assert.is_table(loaded)
			assert.are.equal("value", loaded.test)
			assert.are.equal(42, loaded.count)
		end)

		it("returns nil for missing file", function()
			local loaded, err = Persistence.loadData("/nonexistent/file.json")
			assert.is_nil(loaded)
			assert.is_not_nil(err)
		end)

		it("returns nil for corrupted file", function()
			-- Write invalid JSON
			local file = io.open(testFilePath, "w")
			file:write("not valid json {{{")
			file:close()
			local loaded, err = Persistence.loadData(testFilePath)
			assert.is_nil(loaded)
			assert.is_not_nil(err)
		end)

		it("handles empty file gracefully", function()
			-- Write empty file
			local file = io.open(testFilePath, "w")
			file:write("")
			file:close()
			local loaded, err = Persistence.loadData(testFilePath)
			assert.is_nil(loaded)
			assert.is_not_nil(err)
		end)
	end)

	-- 3. Persistence.saveGames()
	describe("saveGames", function()
		it("saves games table", function()
			local games = {
				game_1 = { id = "game_1", name = "Test Game", status = "waiting" },
				game_2 = { id = "game_2", name = "Another", status = "playing" },
			}
			local success = Persistence.saveGames(testFilePath, games)
			assert.is_true(success)
		end)

		it("preserves game data on round-trip", function()
			local games = {
				game_1 = {
					id = "game_1",
					name = "Test Game",
					hostId = "player_1",
					players = { "player_1", "player_2" },
					status = "playing",
				},
			}
			Persistence.saveGames(testFilePath, games)
			local loaded = Persistence.loadGames(testFilePath)
			assert.is_table(loaded)
			assert.is_table(loaded.game_1)
			assert.are.equal("game_1", loaded.game_1.id)
			assert.are.equal("Test Game", loaded.game_1.name)
			assert.are.equal("playing", loaded.game_1.status)
		end)
	end)

	-- 4. Persistence.loadGames()
	describe("loadGames", function()
		it("returns empty table for missing file", function()
			local games = Persistence.loadGames("/nonexistent/file.json")
			assert.is_table(games)
			local count = 0
			for _ in pairs(games) do
				count = count + 1
			end
			assert.are.equal(0, count)
		end)

		it("returns empty table for corrupted file", function()
			local file = io.open(testFilePath, "w")
			file:write("corrupted data")
			file:close()
			local games = Persistence.loadGames(testFilePath)
			assert.is_table(games)
		end)
	end)

	-- 5. Persistence.saveServerState()
	describe("saveServerState", function()
		it("saves full server state", function()
			local state = {
				lobby = {
					players = { p1 = { id = "p1", name = "Alice" } },
					games = { g1 = { id = "g1", name = "Game" } },
				},
				gameSessions = {},
			}
			local success = Persistence.saveServerState(testFilePath, state)
			assert.is_true(success)
		end)
	end)

	-- 6. Persistence.loadServerState()
	describe("loadServerState", function()
		it("loads full server state", function()
			local original = {
				lobby = {
					players = { p1 = { id = "p1", name = "Alice" } },
					games = {},
				},
				gameSessions = {},
			}
			Persistence.saveServerState(testFilePath, original)
			local loaded = Persistence.loadServerState(testFilePath)
			assert.is_table(loaded)
			assert.is_table(loaded.lobby)
			assert.is_table(loaded.lobby.players)
		end)

		it("returns default state for missing file", function()
			local state = Persistence.loadServerState("/nonexistent/file.json")
			assert.is_table(state)
			assert.is_table(state.lobby)
			assert.is_table(state.gameSessions)
		end)
	end)

	-- 7. Persistence.fileExists()
	describe("fileExists", function()
		it("returns true for existing file", function()
			local file = io.open(testFilePath, "w")
			file:write("test")
			file:close()
			assert.is_true(Persistence.fileExists(testFilePath))
		end)

		it("returns false for non-existent file", function()
			assert.is_false(Persistence.fileExists("/nonexistent/path/file.json"))
		end)
	end)
end)
