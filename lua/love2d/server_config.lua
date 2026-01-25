-- Server configuration file
-- Edit these values to customize server behavior

return {
	-- Network settings
	port = 7777,
	maxGames = 10,
	maxPlayersPerGame = 2,

	-- Connection settings
	disconnectTimeout = 60, -- seconds before disconnected player forfeits

	-- Persistence settings
	persistence = {
		enabled = true,
		filepath = "server_state.json",
		autoSaveInterval = 60, -- seconds between auto-saves
	},

	-- Logging settings
	logging = {
		level = "info", -- "debug", "info", "warn", "error"
		filepath = "server.log", -- nil to disable file logging
	},
}
