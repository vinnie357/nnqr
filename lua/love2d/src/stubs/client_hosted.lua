-- Client-hosted server stub
-- Future implementation where one player acts as server

local ClientHosted = {}

-- Status: STUB - Not implemented
ClientHosted.IMPLEMENTED = false

--- Initialize client-hosted mode
--- @return boolean False (not implemented)
function ClientHosted.init()
	print("[ClientHosted] Stub: Client-hosted mode not yet implemented")
	return false
end

--- Start hosting a game (becomes server + client)
--- @param port number Port to listen on
--- @return boolean False (not implemented)
function ClientHosted.startHosting(port)
	print("[ClientHosted] Stub: startHosting() not implemented")
	return false
end

--- Join a client-hosted game
--- @param address string Host address
--- @param port number Port to connect to
--- @return boolean False (not implemented)
function ClientHosted.joinGame(address, port)
	print("[ClientHosted] Stub: joinGame() not implemented")
	return false
end

--- Check if we are the host
--- @return boolean False (not implemented)
function ClientHosted.isHost()
	return false
end

--- Stop hosting/disconnect
function ClientHosted.stop()
	print("[ClientHosted] Stub: stop() not implemented")
end

--[[
Implementation Notes:
---------------------
Client-hosted is a middle ground between P2P and dedicated server:
- One player runs server + client in same process
- Other player connects as pure client
- Host has authoritative game state

Advantages:
- No dedicated server infrastructure needed
- Lower latency for host
- Works on LAN without internet

Disadvantages:
- Host has slight advantage (no latency)
- If host disconnects, game ends
- Host needs to open ports/deal with NAT

Architecture:
- Reuse protocol.lua for message format
- Embed server logic in client
- Host runs game loop, sends state to guest
- Guest sends inputs, receives state
]]

return ClientHosted
