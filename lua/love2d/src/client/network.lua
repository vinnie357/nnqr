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

--- Create a new network state
---@param config table|nil Optional configuration {host, port}
---@return table Network state
function Network.create(config)
	config = config or {}
	return {
		host = config.host or "localhost",
		port = config.port or 7777,
		socket = nil,
		state = "disconnected", -- disconnected, connecting, connected, error
		lastError = nil,
		messageQueue = {}, -- Incoming messages
		sendBuffer = "", -- Partial send buffer
		receiveBuffer = "", -- Partial receive buffer
		playerId = nil,
		playerName = nil,
		lastActivity = 0,
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
			Network.setState(net, "disconnected")
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
		Network.setState(net, "disconnected")
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

return Network
