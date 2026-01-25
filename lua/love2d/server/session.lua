-- Player session management for multiplayer server
-- Handles session creation, validation, and guest name generation

local Session = {}

-- Guest name components for unique name generation
local ADJECTIVES = {
	"Swift",
	"Brave",
	"Clever",
	"Mighty",
	"Silent",
	"Golden",
	"Shadow",
	"Storm",
	"Iron",
	"Crystal",
	"Frost",
	"Thunder",
	"Ember",
	"Mystic",
	"Noble",
	"Phantom",
	"Rogue",
	"Cosmic",
	"Ancient",
	"Blazing",
}

local NOUNS = {
	"Knight",
	"Wizard",
	"Dragon",
	"Phoenix",
	"Titan",
	"Ranger",
	"Warrior",
	"Sage",
	"Hunter",
	"Guardian",
	"Nomad",
	"Raven",
	"Wolf",
	"Hawk",
	"Lion",
	"Bear",
	"Viper",
	"Falcon",
	"Panther",
	"Tiger",
}

-- Session counter for unique IDs
local sessionCounter = 0

-- Track used guest names to avoid duplicates
local usedGuestNames = {}

--- Generate a unique session ID
---@return string Session ID
local function generateSessionId()
	sessionCounter = sessionCounter + 1
	return "session_" .. os.time() .. "_" .. sessionCounter
end

--- Generate a unique guest name
---@return string Unique guest name
function Session.generateGuestName()
	local maxAttempts = 100

	for _ = 1, maxAttempts do
		local adjective = ADJECTIVES[math.random(#ADJECTIVES)]
		local noun = NOUNS[math.random(#NOUNS)]
		local number = math.random(1, 999)
		local name = adjective .. noun .. number

		if not usedGuestNames[name] then
			usedGuestNames[name] = true
			return name
		end
	end

	-- Fallback: use timestamp for guaranteed uniqueness
	local name = "Guest_" .. os.time() .. "_" .. math.random(1000, 9999)
	usedGuestNames[name] = true
	return name
end

--- Release a guest name for reuse
---@param name string Guest name to release
function Session.releaseGuestName(name)
	usedGuestNames[name] = nil
end

--- Check if a name is a generated guest name
---@param name string Name to check
---@return boolean isGuest
function Session.isGuestName(name)
	-- Check if it matches the pattern of generated names
	if name:match("^Guest_%d+_%d+$") then
		return true
	end

	-- Check if it matches Adjective + Noun + Number pattern
	for _, adj in ipairs(ADJECTIVES) do
		if name:sub(1, #adj) == adj then
			local rest = name:sub(#adj + 1)
			for _, noun in ipairs(NOUNS) do
				if rest:sub(1, #noun) == noun then
					local numPart = rest:sub(#noun + 1)
					if numPart:match("^%d+$") then
						return true
					end
				end
			end
		end
	end

	return false
end

--- Create a new session
---@param playerId string Unique player ID
---@param name string Player display name
---@param config table|nil Optional session configuration
---@return table Session object
function Session.create(playerId, name, config)
	config = config or {}

	return {
		id = generateSessionId(),
		playerId = playerId,
		name = name,
		createdAt = os.time(),
		lastActivity = os.time(),
		connectionState = "connected", -- connected, disconnected, reconnecting
		isGuest = Session.isGuestName(name),
		disconnectTimeout = config.disconnectTimeout or 60,
		metadata = {},
	}
end

--- Validate a session
---@param session table Session to validate
---@return boolean valid
---@return string|nil error message
function Session.validate(session)
	if not session then
		return false, "Session is nil"
	end

	if not session.id then
		return false, "Session missing id"
	end

	if not session.playerId then
		return false, "Session missing playerId"
	end

	if not session.name or session.name == "" then
		return false, "Session missing name"
	end

	if not session.createdAt then
		return false, "Session missing createdAt"
	end

	if not session.connectionState then
		return false, "Session missing connectionState"
	end

	return true, nil
end

--- Check if session is expired (disconnected past timeout)
---@param session table Session to check
---@param currentTime number|nil Current time (defaults to os.time())
---@return boolean expired
function Session.isExpired(session, currentTime)
	currentTime = currentTime or os.time()

	if session.connectionState ~= "disconnected" then
		return false
	end

	local disconnectDuration = currentTime - session.lastActivity
	return disconnectDuration > session.disconnectTimeout
end

--- Update session activity timestamp
---@param session table Session to update
function Session.touch(session)
	session.lastActivity = os.time()
end

--- Set session connection state
---@param session table Session to update
---@param state string New connection state
---@return boolean success
---@return string|nil error message
function Session.setConnectionState(session, state)
	local validStates = {
		connected = true,
		disconnected = true,
		reconnecting = true,
	}

	if not validStates[state] then
		return false, "Invalid connection state: " .. tostring(state)
	end

	session.connectionState = state
	session.lastActivity = os.time()
	return true, nil
end

--- Get session duration in seconds
---@param session table Session
---@param currentTime number|nil Current time (defaults to os.time())
---@return number Duration in seconds
function Session.getDuration(session, currentTime)
	currentTime = currentTime or os.time()
	return currentTime - session.createdAt
end

--- Set session metadata
---@param session table Session
---@param key string Metadata key
---@param value any Metadata value
function Session.setMetadata(session, key, value)
	session.metadata[key] = value
end

--- Get session metadata
---@param session table Session
---@param key string Metadata key
---@return any|nil Metadata value
function Session.getMetadata(session, key)
	return session.metadata[key]
end

--- Validate a player name
---@param name string Name to validate
---@return boolean valid
---@return string|nil error message
function Session.validateName(name)
	if not name then
		return false, "Name is required"
	end

	if type(name) ~= "string" then
		return false, "Name must be a string"
	end

	-- Trim whitespace
	local trimmed = name:match("^%s*(.-)%s*$")

	if trimmed == "" then
		return false, "Name cannot be empty"
	end

	if #trimmed < 2 then
		return false, "Name must be at least 2 characters"
	end

	if #trimmed > 20 then
		return false, "Name cannot exceed 20 characters"
	end

	-- Check for invalid characters (allow alphanumeric, spaces, underscores, hyphens)
	if not trimmed:match("^[%w%s_%-]+$") then
		return false, "Name contains invalid characters"
	end

	return true, nil
end

--- Reset the session module state (for testing)
function Session.reset()
	sessionCounter = 0
	usedGuestNames = {}
end

return Session
