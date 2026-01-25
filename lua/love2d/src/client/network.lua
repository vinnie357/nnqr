-- Network module for client-side multiplayer
-- Handles TCP connection to server
-- Phase 10B: Client Networking

local Protocol = require("src.shared.protocol")

local Network = {}

-- Client version
local CLIENT_VERSION = "0.1.0"

-- Try to load luasocket
local socket
local hasSocket = pcall(function()
	socket = require("socket")
end)

-- Reconnection constants
local RECONNECT_DELAY = 2 -- seconds between reconnect attempts
local MAX_RECONNECT_ATTEMPTS = 5
local RECONNECT_TIMEOUT = 60 -- total time before giving up

--- Create a new network state
---@param config table|nil Optional configuration {host, port}
---@return table Network state
function Network.create(config)
	config = config or {}
	return {
		host = config.host or "localhost",
		port = config.port or 7777,
		socket = nil,
		state = "disconnected", -- disconnected, connecting, connected, reconnecting, error
		lastError = nil,
		messageQueue = {}, -- Incoming messages
		sendBuffer = "", -- Partial send buffer
		receiveBuffer = "", -- Partial receive buffer
		playerId = nil,
		playerName = nil,
		lastActivity = 0,
		-- Reconnection state
		reconnectEnabled = true,
		reconnectAttempts = 0,
		reconnectStartTime = nil,
		lastReconnectAttempt = 0,
		wasConnected = false, -- Track if we were previously connected
	}
end

--- Get current connection state
---@param net table Network state
---@return string State: "disconnected", "connecting", "connected", "error"
function Network.getState(net)
	return net.state
end

--- Set connection state
---@param net table Network state
---@param state string New state
---@param errorMsg string|nil Optional error message
function Network.setState(net, state, errorMsg)
	net.state = state
	if errorMsg then
		net.lastError = errorMsg
	end
end

--- Check if connected
---@param net table Network state
---@return boolean True if connected
function Network.isConnected(net)
	return net.state == "connected"
end

--- Get player ID (after authentication)
---@param net table Network state
---@return string|nil Player ID
function Network.getPlayerId(net)
	return net.playerId
end

--- Set player ID
---@param net table Network state
---@param playerId string Player ID
function Network.setPlayerId(net, playerId)
	net.playerId = playerId
end

--- Add message to receive queue (used internally and for testing)
---@param net table Network state
---@param message table Protocol message
function Network.queueMessage(net, message)
	table.insert(net.messageQueue, message)
end

--- Check if there are pending messages
---@param net table Network state
---@return boolean True if messages available
function Network.hasMessages(net)
	return #net.messageQueue > 0
end

--- Receive next message from queue
---@param net table Network state
---@return table|nil Next message or nil
function Network.receive(net)
	if #net.messageQueue == 0 then
		return nil
	end
	return table.remove(net.messageQueue, 1)
end

--- Parse JSON response from server
---@param json string JSON string
---@return table|nil Parsed message or nil
function Network.parseResponse(json)
	if not json or json == "" then
		return nil
	end
	return Protocol.decode(json)
end

--- Encode message for sending
---@param message table Protocol message
---@return string JSON string
function Network.encodeMessage(message)
	return Protocol.encode(message)
end

--- Create CONNECT message
---@param playerName string Player display name
---@return table Protocol message
function Network.createConnectMessage(playerName)
	return Protocol.connectMessage(playerName, CLIENT_VERSION)
end

--- Connect to server
---@param net table Network state
---@param host string|nil Optional host override
---@param port number|nil Optional port override
---@return boolean success
---@return string|nil error message
function Network.connect(net, host, port)
	if not hasSocket then
		Network.setState(net, "error", "luasocket not available")
		return false, "luasocket not available"
	end

	if net.state == "connected" or net.state == "connecting" then
		return false, "Already connected or connecting"
	end

	host = host or net.host
	port = port or net.port

	Network.setState(net, "connecting")

	local sock = socket.tcp()
	sock:settimeout(5) -- 5 second timeout for connect

	local success, err = sock:connect(host, port)
	if not success then
		sock:close()
		Network.setState(net, "error", err)
		return false, err
	end

	sock:settimeout(0) -- Non-blocking for normal operation
	net.socket = sock
	net.host = host
	net.port = port
	net.lastActivity = socket.gettime()

	Network.setState(net, "connected")
	net.wasConnected = true
	net.reconnectAttempts = 0
	net.reconnectStartTime = nil
	return true, nil
end

--- Disconnect from server
---@param net table Network state
function Network.disconnect(net)
	if net.socket then
		net.socket:close()
		net.socket = nil
	end

	net.playerId = nil
	net.messageQueue = {}
	net.receiveBuffer = ""
	Network.setState(net, "disconnected")
end

--- Send a message to server
---@param net table Network state
---@param message table Protocol message
---@return boolean success
---@return string|nil error message
function Network.send(net, message)
	if not Network.isConnected(net) then
		return false, "Not connected"
	end

	if not net.socket then
		return false, "Socket not available"
	end

	local encoded = Network.encodeMessage(message) .. "\n"
	local success, err = net.socket:send(encoded)

	if not success then
		if err == "closed" then
			-- Connection lost - try to reconnect if enabled
			if net.reconnectEnabled and net.wasConnected then
				Network.startReconnection(net)
			else
				Network.setState(net, "disconnected")
			end
		else
			Network.setState(net, "error", err)
		end
		return false, err
	end

	if hasSocket then
		net.lastActivity = socket.gettime()
	end

	return true, nil
end

--- Poll for incoming data (call in update loop)
---@param net table Network state
function Network.poll(net)
	if not Network.isConnected(net) or not net.socket then
		return
	end

	-- Try to receive data
	local data, err, partial = net.socket:receive("*l")

	if data then
		-- Complete line received
		local message = Network.parseResponse(data)
		if message then
			Network.queueMessage(net, message)
		end
		if hasSocket then
			net.lastActivity = socket.gettime()
		end
	elseif partial and #partial > 0 then
		-- Partial data - buffer it
		net.receiveBuffer = net.receiveBuffer .. partial
		-- Check if buffer contains complete line
		local newline = net.receiveBuffer:find("\n")
		if newline then
			local line = net.receiveBuffer:sub(1, newline - 1)
			net.receiveBuffer = net.receiveBuffer:sub(newline + 1)
			local message = Network.parseResponse(line)
			if message then
				Network.queueMessage(net, message)
			end
		end
	elseif err == "closed" then
		-- Connection lost - try to reconnect if enabled
		if net.reconnectEnabled and net.wasConnected then
			Network.startReconnection(net)
		else
			Network.setState(net, "disconnected")
		end
	end
	-- "timeout" is normal for non-blocking socket
end

--- Authenticate with server
---@param net table Network state
---@param playerName string Player display name
---@return boolean success
---@return string|nil error message
function Network.authenticate(net, playerName)
	if not Network.isConnected(net) then
		return false, "Not connected"
	end

	net.playerName = playerName
	local msg = Network.createConnectMessage(playerName)
	return Network.send(net, msg)
end

--- Process WELCOME response
---@param net table Network state
---@param message table WELCOME message
function Network.handleWelcome(net, message)
	if message.type == "WELCOME" and message.payload then
		net.playerId = message.payload.player_id
	end
end

--- Get connection info string
---@param net table Network state
---@return string Connection info
function Network.getConnectionInfo(net)
	if Network.isConnected(net) then
		return net.host .. ":" .. net.port
	else
		return "Not connected"
	end
end

--- Check if luasocket is available
---@return boolean True if socket available
function Network.hasSocketSupport()
	return hasSocket
end

--- Check if currently reconnecting
---@param net table Network state
---@return boolean True if reconnecting
function Network.isReconnecting(net)
	return net.state == "reconnecting"
end

--- Start reconnection process
---@param net table Network state
---@return boolean True if reconnection started
function Network.startReconnection(net)
	if not net.reconnectEnabled then
		return false
	end

	if not net.wasConnected then
		-- Never connected successfully, don't auto-reconnect
		return false
	end

	if net.state == "reconnecting" then
		-- Already reconnecting
		return false
	end

	-- Close existing socket if any
	if net.socket then
		net.socket:close()
		net.socket = nil
	end

	net.state = "reconnecting"
	net.reconnectAttempts = 0
	net.reconnectStartTime = hasSocket and socket.gettime() or os.time()
	net.lastReconnectAttempt = 0

	return true
end

--- Attempt a single reconnection
---@param net table Network state
---@return boolean success
---@return string|nil error message
function Network.attemptReconnect(net)
	if not hasSocket then
		return false, "luasocket not available"
	end

	net.reconnectAttempts = net.reconnectAttempts + 1
	net.lastReconnectAttempt = socket.gettime()

	-- Try to connect
	local sock = socket.tcp()
	sock:settimeout(5)

	local success, err = sock:connect(net.host, net.port)
	if not success then
		sock:close()
		return false, err
	end

	-- Connection successful
	sock:settimeout(0)
	net.socket = sock
	net.lastActivity = socket.gettime()
	net.state = "connected"

	-- Re-authenticate if we have a player name
	if net.playerName then
		local msg = Network.createConnectMessage(net.playerName)
		Network.send(net, msg)
	end

	return true, nil
end

--- Update reconnection state (call in update loop)
---@param net table Network state
---@param dt number Delta time in seconds
---@return string|nil Event: "reconnected", "failed", "attempting", or nil
function Network.updateReconnection(net, dt)
	if net.state ~= "reconnecting" then
		return nil
	end

	if not hasSocket then
		net.state = "error"
		net.lastError = "luasocket not available"
		return "failed"
	end

	local currentTime = socket.gettime()

	-- Check total timeout
	local elapsed = currentTime - net.reconnectStartTime
	if elapsed >= RECONNECT_TIMEOUT then
		net.state = "error"
		net.lastError = "Reconnection timeout"
		return "failed"
	end

	-- Check max attempts
	if net.reconnectAttempts >= MAX_RECONNECT_ATTEMPTS then
		net.state = "error"
		net.lastError = "Max reconnection attempts reached"
		return "failed"
	end

	-- Check if it's time for another attempt
	local timeSinceAttempt = currentTime - net.lastReconnectAttempt
	if timeSinceAttempt < RECONNECT_DELAY then
		return nil
	end

	-- Attempt reconnection
	local success, err = Network.attemptReconnect(net)
	if success then
		return "reconnected"
	end

	return "attempting"
end

--- Cancel reconnection
---@param net table Network state
function Network.cancelReconnection(net)
	if net.state == "reconnecting" then
		net.state = "disconnected"
		net.reconnectAttempts = 0
		net.reconnectStartTime = nil
	end
end

--- Get reconnection status for UI
---@param net table Network state
---@return table Status {attempting, attempts, maxAttempts, timeRemaining}
function Network.getReconnectionStatus(net)
	if net.state ~= "reconnecting" then
		return {
			attempting = false,
			attempts = 0,
			maxAttempts = MAX_RECONNECT_ATTEMPTS,
			timeRemaining = 0,
		}
	end

	local elapsed = 0
	if hasSocket and net.reconnectStartTime then
		elapsed = socket.gettime() - net.reconnectStartTime
	end

	return {
		attempting = true,
		attempts = net.reconnectAttempts,
		maxAttempts = MAX_RECONNECT_ATTEMPTS,
		timeRemaining = math.max(0, RECONNECT_TIMEOUT - elapsed),
	}
end

--- Enable or disable auto-reconnection
---@param net table Network state
---@param enabled boolean Enable reconnection
function Network.setReconnectEnabled(net, enabled)
	net.reconnectEnabled = enabled
end

return Network
