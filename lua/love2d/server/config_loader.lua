-- Config loader module for server
-- Loads, validates, and applies defaults for server configuration

local ConfigLoader = {}

-- Default configuration values
ConfigLoader.DEFAULTS = {
	port = 7777,
	maxGames = 10,
	maxPlayersPerGame = 2,
	disconnectTimeout = 60,
	persistence = {
		enabled = true,
		filepath = "server_state.json",
		autoSaveInterval = 60,
	},
	logging = {
		level = "info",
		filepath = nil,
	},
}

-- Valid log levels
local VALID_LOG_LEVELS = {
	debug = true,
	info = true,
	warn = true,
	error = true,
}

--- Deep merge two tables, with source overriding target
---@param target table Target table (defaults)
---@param source table Source table (user config)
---@return table Merged table
local function deepMerge(target, source)
	local result = {}

	-- Copy target first
	for k, v in pairs(target) do
		if type(v) == "table" then
			result[k] = deepMerge(v, {})
		else
			result[k] = v
		end
	end

	-- Override with source
	if source then
		for k, v in pairs(source) do
			if type(v) == "table" and type(result[k]) == "table" then
				result[k] = deepMerge(result[k], v)
			else
				result[k] = v
			end
		end
	end

	return result
end

--- Validate a configuration table
---@param config table Configuration to validate
---@return boolean valid
---@return string|nil error message
function ConfigLoader.validate(config)
	-- Validate port
	if config.port then
		if type(config.port) ~= "number" then
			return false, "port must be a number"
		end
		if config.port < 1 or config.port > 65535 then
			return false, "port must be between 1 and 65535"
		end
	end

	-- Validate maxGames
	if config.maxGames then
		if type(config.maxGames) ~= "number" then
			return false, "maxGames must be a number"
		end
		if config.maxGames < 1 then
			return false, "maxGames must be at least 1"
		end
	end

	-- Validate maxPlayersPerGame
	if config.maxPlayersPerGame then
		if type(config.maxPlayersPerGame) ~= "number" then
			return false, "maxPlayersPerGame must be a number"
		end
		if config.maxPlayersPerGame < 2 then
			return false, "maxPlayersPerGame must be at least 2"
		end
	end

	-- Validate disconnectTimeout
	if config.disconnectTimeout then
		if type(config.disconnectTimeout) ~= "number" then
			return false, "disconnectTimeout must be a number"
		end
		if config.disconnectTimeout < 0 then
			return false, "disconnectTimeout must be non-negative"
		end
	end

	-- Validate persistence
	if config.persistence then
		if type(config.persistence) ~= "table" then
			return false, "persistence must be a table"
		end
		if config.persistence.autoSaveInterval then
			if type(config.persistence.autoSaveInterval) ~= "number" then
				return false, "persistence.autoSaveInterval must be a number"
			end
			if config.persistence.autoSaveInterval < 0 then
				return false, "persistence.autoSaveInterval must be non-negative"
			end
		end
	end

	-- Validate logging
	if config.logging then
		if type(config.logging) ~= "table" then
			return false, "logging must be a table"
		end
		if config.logging.level then
			if type(config.logging.level) ~= "string" then
				return false, "logging.level must be a string"
			end
			if not VALID_LOG_LEVELS[config.logging.level] then
				return false, "logging.level must be one of: debug, info, warn, error"
			end
		end
	end

	return true, nil
end

--- Load configuration from a file path
---@param filepath string Path to config file
---@return table|nil config
---@return string|nil error message
function ConfigLoader.loadFile(filepath)
	-- Try to load the file
	local chunk, loadErr = loadfile(filepath)
	if not chunk then
		return nil, "Failed to load config file: " .. (loadErr or "unknown error")
	end

	-- Execute the chunk to get the config table
	local ok, config = pcall(chunk)
	if not ok then
		return nil, "Failed to execute config file: " .. (config or "unknown error")
	end

	if type(config) ~= "table" then
		return nil, "Config file must return a table"
	end

	return config, nil
end

--- Load configuration with defaults and validation
---@param filepath string|nil Path to config file (nil to use defaults only)
---@return table config Merged and validated configuration
---@return string|nil error message (nil if successful)
function ConfigLoader.load(filepath)
	local userConfig = {}

	-- Load user config if filepath provided
	if filepath then
		local loaded, err = ConfigLoader.loadFile(filepath)
		if loaded then
			userConfig = loaded
		elseif err then
			-- File doesn't exist or failed to load - use defaults
			-- This is not an error, just a warning condition
			return deepMerge(ConfigLoader.DEFAULTS, {}), nil
		end
	end

	-- Validate user config before merging
	local valid, validErr = ConfigLoader.validate(userConfig)
	if not valid then
		return nil, validErr
	end

	-- Merge with defaults
	local config = deepMerge(ConfigLoader.DEFAULTS, userConfig)

	return config, nil
end

--- Get the default configuration
---@return table defaults
function ConfigLoader.getDefaults()
	return deepMerge(ConfigLoader.DEFAULTS, {})
end

return ConfigLoader
