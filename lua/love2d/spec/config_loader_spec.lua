-- Tests for server config loader
-- Phase 10A: Network Multiplayer

describe("ConfigLoader", function()
	local ConfigLoader

	setup(function()
		package.path = "./?.lua;./src/?.lua;./server/?.lua;" .. package.path
		ConfigLoader = require("server.config_loader")
	end)

	describe("getDefaults", function()
		it("returns default configuration", function()
			local defaults = ConfigLoader.getDefaults()

			assert.is_table(defaults)
			assert.equals(7777, defaults.port)
			assert.equals(10, defaults.maxGames)
			assert.equals(2, defaults.maxPlayersPerGame)
			assert.equals(60, defaults.disconnectTimeout)
		end)

		it("returns default persistence settings", function()
			local defaults = ConfigLoader.getDefaults()

			assert.is_table(defaults.persistence)
			assert.is_true(defaults.persistence.enabled)
			assert.equals("server_state.json", defaults.persistence.filepath)
			assert.equals(60, defaults.persistence.autoSaveInterval)
		end)

		it("returns default logging settings", function()
			local defaults = ConfigLoader.getDefaults()

			assert.is_table(defaults.logging)
			assert.equals("info", defaults.logging.level)
		end)
	end)

	describe("validate", function()
		it("accepts valid configuration", function()
			local config = {
				port = 8080,
				maxGames = 5,
				maxPlayersPerGame = 2,
				disconnectTimeout = 30,
				persistence = {
					enabled = true,
					filepath = "test.json",
					autoSaveInterval = 120,
				},
				logging = {
					level = "debug",
				},
			}

			local valid, err = ConfigLoader.validate(config)
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("accepts empty configuration", function()
			local valid, err = ConfigLoader.validate({})
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("rejects invalid port type", function()
			local valid, err = ConfigLoader.validate({ port = "8080" })
			assert.is_false(valid)
			assert.equals("port must be a number", err)
		end)

		it("rejects port out of range (low)", function()
			local valid, err = ConfigLoader.validate({ port = 0 })
			assert.is_false(valid)
			assert.equals("port must be between 1 and 65535", err)
		end)

		it("rejects port out of range (high)", function()
			local valid, err = ConfigLoader.validate({ port = 70000 })
			assert.is_false(valid)
			assert.equals("port must be between 1 and 65535", err)
		end)

		it("rejects invalid maxGames type", function()
			local valid, err = ConfigLoader.validate({ maxGames = "10" })
			assert.is_false(valid)
			assert.equals("maxGames must be a number", err)
		end)

		it("rejects maxGames less than 1", function()
			local valid, err = ConfigLoader.validate({ maxGames = 0 })
			assert.is_false(valid)
			assert.equals("maxGames must be at least 1", err)
		end)

		it("rejects invalid maxPlayersPerGame type", function()
			local valid, err = ConfigLoader.validate({ maxPlayersPerGame = "2" })
			assert.is_false(valid)
			assert.equals("maxPlayersPerGame must be a number", err)
		end)

		it("rejects maxPlayersPerGame less than 2", function()
			local valid, err = ConfigLoader.validate({ maxPlayersPerGame = 1 })
			assert.is_false(valid)
			assert.equals("maxPlayersPerGame must be at least 2", err)
		end)

		it("rejects invalid disconnectTimeout type", function()
			local valid, err = ConfigLoader.validate({ disconnectTimeout = "60" })
			assert.is_false(valid)
			assert.equals("disconnectTimeout must be a number", err)
		end)

		it("rejects negative disconnectTimeout", function()
			local valid, err = ConfigLoader.validate({ disconnectTimeout = -1 })
			assert.is_false(valid)
			assert.equals("disconnectTimeout must be non-negative", err)
		end)

		it("rejects invalid persistence type", function()
			local valid, err = ConfigLoader.validate({ persistence = "enabled" })
			assert.is_false(valid)
			assert.equals("persistence must be a table", err)
		end)

		it("rejects invalid autoSaveInterval type", function()
			local valid, err = ConfigLoader.validate({ persistence = { autoSaveInterval = "60" } })
			assert.is_false(valid)
			assert.equals("persistence.autoSaveInterval must be a number", err)
		end)

		it("rejects negative autoSaveInterval", function()
			local valid, err = ConfigLoader.validate({ persistence = { autoSaveInterval = -1 } })
			assert.is_false(valid)
			assert.equals("persistence.autoSaveInterval must be non-negative", err)
		end)

		it("rejects invalid logging type", function()
			local valid, err = ConfigLoader.validate({ logging = "info" })
			assert.is_false(valid)
			assert.equals("logging must be a table", err)
		end)

		it("rejects invalid logging.level type", function()
			local valid, err = ConfigLoader.validate({ logging = { level = 1 } })
			assert.is_false(valid)
			assert.equals("logging.level must be a string", err)
		end)

		it("rejects invalid logging.level value", function()
			local valid, err = ConfigLoader.validate({ logging = { level = "verbose" } })
			assert.is_false(valid)
			assert.equals("logging.level must be one of: debug, info, warn, error", err)
		end)

		it("accepts all valid log levels", function()
			for _, level in ipairs({ "debug", "info", "warn", "error" }) do
				local valid, err = ConfigLoader.validate({ logging = { level = level } })
				assert.is_true(valid, "Should accept level: " .. level)
				assert.is_nil(err)
			end
		end)
	end)

	describe("load", function()
		it("returns defaults when no filepath provided", function()
			local config, err = ConfigLoader.load(nil)

			assert.is_nil(err)
			assert.is_table(config)
			assert.equals(7777, config.port)
			assert.equals(10, config.maxGames)
		end)

		it("returns defaults when file does not exist", function()
			local config, err = ConfigLoader.load("nonexistent_config.lua")

			assert.is_nil(err)
			assert.is_table(config)
			assert.equals(7777, config.port)
		end)

		it("merges user config with defaults", function()
			-- Create a temporary config file
			local tempPath = "/tmp/test_config.lua"
			local f = io.open(tempPath, "w")
			f:write('return { port = 9999, logging = { level = "debug" } }')
			f:close()

			local config, err = ConfigLoader.load(tempPath)

			assert.is_nil(err)
			assert.equals(9999, config.port)
			assert.equals("debug", config.logging.level)
			-- Defaults should still be present
			assert.equals(10, config.maxGames)
			assert.equals(60, config.persistence.autoSaveInterval)

			os.remove(tempPath)
		end)

		it("returns error for invalid config values", function()
			local tempPath = "/tmp/test_config_invalid.lua"
			local f = io.open(tempPath, "w")
			f:write("return { port = 70000 }")
			f:close()

			local config, err = ConfigLoader.load(tempPath)

			assert.is_nil(config)
			assert.equals("port must be between 1 and 65535", err)

			os.remove(tempPath)
		end)

		it("deep merges nested tables", function()
			local tempPath = "/tmp/test_config_nested.lua"
			local f = io.open(tempPath, "w")
			f:write('return { persistence = { filepath = "custom.json" } }')
			f:close()

			local config, err = ConfigLoader.load(tempPath)

			assert.is_nil(err)
			assert.equals("custom.json", config.persistence.filepath)
			-- Other persistence defaults should be present
			assert.is_true(config.persistence.enabled)
			assert.equals(60, config.persistence.autoSaveInterval)

			os.remove(tempPath)
		end)
	end)

	describe("loadFile", function()
		it("loads valid config file", function()
			local tempPath = "/tmp/test_config_load.lua"
			local f = io.open(tempPath, "w")
			f:write("return { port = 8080 }")
			f:close()

			local config, err = ConfigLoader.loadFile(tempPath)

			assert.is_nil(err)
			assert.is_table(config)
			assert.equals(8080, config.port)

			os.remove(tempPath)
		end)

		it("returns error for missing file", function()
			local config, err = ConfigLoader.loadFile("nonexistent.lua")

			assert.is_nil(config)
			assert.is_string(err)
			assert.truthy(err:match("Failed to load config file"))
		end)

		it("returns error for invalid Lua syntax", function()
			local tempPath = "/tmp/test_config_syntax.lua"
			local f = io.open(tempPath, "w")
			f:write("return { port = ")
			f:close()

			local config, err = ConfigLoader.loadFile(tempPath)

			assert.is_nil(config)
			assert.is_string(err)

			os.remove(tempPath)
		end)

		it("returns error when file does not return table", function()
			local tempPath = "/tmp/test_config_notable.lua"
			local f = io.open(tempPath, "w")
			f:write('return "not a table"')
			f:close()

			local config, err = ConfigLoader.loadFile(tempPath)

			assert.is_nil(config)
			assert.equals("Config file must return a table", err)

			os.remove(tempPath)
		end)
	end)
end)
