-- Busted tests for Network module
-- Phase 10B: Client Networking
-- Run with: busted spec/

describe("Network", function()
	local Network
	local Protocol

	setup(function()
		Network = require("src.client.network")
		Protocol = require("src.shared.protocol")
	end)

	-- 1. Network.create()
	describe("create", function()
		it("returns a table", function()
			local net = Network.create()
			assert.is_table(net)
		end)

		it("sets state to disconnected", function()
			local net = Network.create()
			assert.are.equal("disconnected", net.state)
		end)

		it("initializes empty message queue", function()
			local net = Network.create()
			assert.is_table(net.messageQueue)
			assert.are.equal(0, #net.messageQueue)
		end)

		it("initializes nil socket", function()
			local net = Network.create()
			assert.is_nil(net.socket)
		end)

		it("stores default host and port", function()
			local net = Network.create()
			assert.are.equal("localhost", net.host)
			assert.are.equal(7777, net.port)
		end)

		it("accepts custom host and port", function()
			local net = Network.create({ host = "192.168.1.100", port = 8888 })
			assert.are.equal("192.168.1.100", net.host)
			assert.are.equal(8888, net.port)
		end)
	end)

	-- 2. Network.getState()
	describe("getState", function()
		it("returns current connection state", function()
			local net = Network.create()
			assert.are.equal("disconnected", Network.getState(net))
		end)
	end)

	-- 3. Network.isConnected()
	describe("isConnected", function()
		it("returns false when disconnected", function()
			local net = Network.create()
			assert.is_false(Network.isConnected(net))
		end)

		it("returns true when connected", function()
			local net = Network.create()
			net.state = "connected"
			assert.is_true(Network.isConnected(net))
		end)
	end)

	-- 4. Network.queueMessage() (internal helper for testing)
	describe("queueMessage", function()
		it("adds message to queue", function()
			local net = Network.create()
			local msg = Protocol.createMessage("WELCOME", { player_id = "p1" })
			Network.queueMessage(net, msg)
			assert.are.equal(1, #net.messageQueue)
		end)

		it("preserves message order", function()
			local net = Network.create()
			Network.queueMessage(net, Protocol.createMessage("MSG1", {}))
			Network.queueMessage(net, Protocol.createMessage("MSG2", {}))
			Network.queueMessage(net, Protocol.createMessage("MSG3", {}))
			assert.are.equal("MSG1", net.messageQueue[1].type)
			assert.are.equal("MSG2", net.messageQueue[2].type)
			assert.are.equal("MSG3", net.messageQueue[3].type)
		end)
	end)

	-- 5. Network.receive()
	describe("receive", function()
		it("returns nil when queue is empty", function()
			local net = Network.create()
			local msg = Network.receive(net)
			assert.is_nil(msg)
		end)

		it("returns and removes first message from queue", function()
			local net = Network.create()
			Network.queueMessage(net, Protocol.createMessage("MSG1", {}))
			Network.queueMessage(net, Protocol.createMessage("MSG2", {}))
			local msg = Network.receive(net)
			assert.are.equal("MSG1", msg.type)
			assert.are.equal(1, #net.messageQueue)
		end)

		it("returns messages in FIFO order", function()
			local net = Network.create()
			Network.queueMessage(net, Protocol.createMessage("FIRST", {}))
			Network.queueMessage(net, Protocol.createMessage("SECOND", {}))
			assert.are.equal("FIRST", Network.receive(net).type)
			assert.are.equal("SECOND", Network.receive(net).type)
			assert.is_nil(Network.receive(net))
		end)
	end)

	-- 6. Network.hasMessages()
	describe("hasMessages", function()
		it("returns false when queue is empty", function()
			local net = Network.create()
			assert.is_false(Network.hasMessages(net))
		end)

		it("returns true when queue has messages", function()
			local net = Network.create()
			Network.queueMessage(net, Protocol.createMessage("TEST", {}))
			assert.is_true(Network.hasMessages(net))
		end)
	end)

	-- 7. Network.createConnectMessage()
	describe("createConnectMessage", function()
		it("creates CONNECT message with player name", function()
			local msg = Network.createConnectMessage("Alice")
			assert.are.equal("CONNECT", msg.type)
			assert.are.equal("Alice", msg.payload.player_name)
		end)

		it("includes client version", function()
			local msg = Network.createConnectMessage("Bob")
			assert.is_string(msg.payload.client_version)
		end)
	end)

	-- 8. Network.parseResponse() (helper for processing server responses)
	describe("parseResponse", function()
		it("parses valid JSON response", function()
			local json = '{"type":"WELCOME","payload":{"player_id":"p1"},"timestamp":0,"seq":1}'
			local msg = Network.parseResponse(json)
			assert.is_table(msg)
			assert.are.equal("WELCOME", msg.type)
			assert.are.equal("p1", msg.payload.player_id)
		end)

		it("returns nil for invalid JSON", function()
			local msg = Network.parseResponse("not json")
			assert.is_nil(msg)
		end)

		it("returns nil for empty string", function()
			local msg = Network.parseResponse("")
			assert.is_nil(msg)
		end)
	end)

	-- 9. Network state transitions
	describe("state transitions", function()
		it("transitions from disconnected to connecting", function()
			local net = Network.create()
			assert.are.equal("disconnected", net.state)
			Network.setState(net, "connecting")
			assert.are.equal("connecting", net.state)
		end)

		it("transitions from connecting to connected", function()
			local net = Network.create()
			Network.setState(net, "connecting")
			Network.setState(net, "connected")
			assert.are.equal("connected", net.state)
		end)

		it("can transition to error state", function()
			local net = Network.create()
			Network.setState(net, "connecting")
			Network.setState(net, "error")
			assert.are.equal("error", net.state)
		end)

		it("stores error message on error state", function()
			local net = Network.create()
			Network.setState(net, "error", "Connection refused")
			assert.are.equal("error", net.state)
			assert.are.equal("Connection refused", net.lastError)
		end)
	end)

	-- 10. Network.getPlayerId()
	describe("getPlayerId", function()
		it("returns nil before authentication", function()
			local net = Network.create()
			assert.is_nil(Network.getPlayerId(net))
		end)

		it("returns player ID after set", function()
			local net = Network.create()
			net.playerId = "player_123"
			assert.are.equal("player_123", Network.getPlayerId(net))
		end)
	end)

	-- 11. Network.setPlayerId()
	describe("setPlayerId", function()
		it("stores player ID", function()
			local net = Network.create()
			Network.setPlayerId(net, "player_456")
			assert.are.equal("player_456", net.playerId)
		end)
	end)

	-- 12. Network.encodeMessage()
	describe("encodeMessage", function()
		it("encodes message to JSON string", function()
			local msg = Protocol.createMessage("TEST", { value = 42 })
			local encoded = Network.encodeMessage(msg)
			assert.is_string(encoded)
			assert.is_truthy(encoded:find('"type"'))
			assert.is_truthy(encoded:find('"TEST"'))
		end)
	end)

	-- 13. Network.isReconnecting()
	describe("isReconnecting", function()
		it("returns false when disconnected", function()
			local net = Network.create()
			assert.is_false(Network.isReconnecting(net))
		end)

		it("returns true when reconnecting", function()
			local net = Network.create()
			net.state = "reconnecting"
			assert.is_true(Network.isReconnecting(net))
		end)

		it("returns false when connected", function()
			local net = Network.create()
			net.state = "connected"
			assert.is_false(Network.isReconnecting(net))
		end)
	end)

	-- 14. Network.startReconnection()
	describe("startReconnection", function()
		it("returns false if reconnection disabled", function()
			local net = Network.create()
			net.reconnectEnabled = false
			net.wasConnected = true
			assert.is_false(Network.startReconnection(net))
		end)

		it("returns false if never connected", function()
			local net = Network.create()
			net.wasConnected = false
			assert.is_false(Network.startReconnection(net))
		end)

		it("returns false if already reconnecting", function()
			local net = Network.create()
			net.wasConnected = true
			net.state = "reconnecting"
			assert.is_false(Network.startReconnection(net))
		end)

		it("starts reconnection when enabled and was connected", function()
			local net = Network.create()
			net.wasConnected = true
			local result = Network.startReconnection(net)
			assert.is_true(result)
			assert.are.equal("reconnecting", net.state)
			assert.are.equal(0, net.reconnectAttempts)
		end)

		it("closes existing socket", function()
			local net = Network.create()
			net.wasConnected = true
			local closed = false
			net.socket = {
				close = function()
					closed = true
				end,
			}
			Network.startReconnection(net)
			assert.is_true(closed)
			assert.is_nil(net.socket)
		end)
	end)

	-- 15. Network.cancelReconnection()
	describe("cancelReconnection", function()
		it("cancels reconnection and sets state to disconnected", function()
			local net = Network.create()
			net.state = "reconnecting"
			net.reconnectAttempts = 3
			net.reconnectStartTime = 12345
			Network.cancelReconnection(net)
			assert.are.equal("disconnected", net.state)
			assert.are.equal(0, net.reconnectAttempts)
			assert.is_nil(net.reconnectStartTime)
		end)

		it("does nothing if not reconnecting", function()
			local net = Network.create()
			net.state = "connected"
			Network.cancelReconnection(net)
			assert.are.equal("connected", net.state)
		end)
	end)

	-- 16. Network.getReconnectionStatus()
	describe("getReconnectionStatus", function()
		it("returns not attempting when not reconnecting", function()
			local net = Network.create()
			local status = Network.getReconnectionStatus(net)
			assert.is_false(status.attempting)
			assert.are.equal(0, status.attempts)
			assert.are.equal(5, status.maxAttempts)
		end)

		it("returns status when reconnecting", function()
			local net = Network.create()
			net.state = "reconnecting"
			net.reconnectAttempts = 2
			net.reconnectStartTime = os.time()
			local status = Network.getReconnectionStatus(net)
			assert.is_true(status.attempting)
			assert.are.equal(2, status.attempts)
			assert.are.equal(5, status.maxAttempts)
		end)
	end)

	-- 17. Network.setReconnectEnabled()
	describe("setReconnectEnabled", function()
		it("enables reconnection", function()
			local net = Network.create()
			net.reconnectEnabled = false
			Network.setReconnectEnabled(net, true)
			assert.is_true(net.reconnectEnabled)
		end)

		it("disables reconnection", function()
			local net = Network.create()
			Network.setReconnectEnabled(net, false)
			assert.is_false(net.reconnectEnabled)
		end)
	end)

	-- 18. Reconnection state in create
	describe("reconnection state initialization", function()
		it("initializes reconnection enabled by default", function()
			local net = Network.create()
			assert.is_true(net.reconnectEnabled)
		end)

		it("initializes reconnect attempts to zero", function()
			local net = Network.create()
			assert.are.equal(0, net.reconnectAttempts)
		end)

		it("initializes wasConnected to false", function()
			local net = Network.create()
			assert.is_false(net.wasConnected)
		end)
	end)
end)
