-- Busted tests for network protocol
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("Protocol", function()
	local Protocol

	setup(function()
		Protocol = require("src.shared.protocol")
	end)

	describe("message types", function()
		it("has CONNECT type", function()
			assert.are.equal("CONNECT", Protocol.Types.CONNECT)
		end)

		it("has WELCOME type", function()
			assert.are.equal("WELCOME", Protocol.Types.WELCOME)
		end)

		it("has MOVE type", function()
			assert.are.equal("MOVE", Protocol.Types.MOVE)
		end)

		it("has GAME_STATE type", function()
			assert.are.equal("GAME_STATE", Protocol.Types.GAME_STATE)
		end)

		it("has ERROR type", function()
			assert.are.equal("ERROR", Protocol.Types.ERROR)
		end)
	end)

	describe("createMessage", function()
		it("creates a message with type and payload", function()
			local msg = Protocol.createMessage("MOVE", { from = { col = 1, row = 1 } })
			assert.are.equal("MOVE", msg.type)
			assert.is_table(msg.payload)
			assert.are.equal(1, msg.payload.from.col)
		end)

		it("includes timestamp", function()
			local msg = Protocol.createMessage("MOVE", {})
			assert.is_number(msg.timestamp)
			assert.is_true(msg.timestamp > 0)
		end)

		it("includes sequence number", function()
			local msg1 = Protocol.createMessage("MOVE", {})
			local msg2 = Protocol.createMessage("MOVE", {})
			assert.is_number(msg1.seq)
			assert.is_true(msg2.seq > msg1.seq)
		end)
	end)

	describe("encode", function()
		it("serializes message to JSON string", function()
			local msg = Protocol.createMessage("MOVE", { from = { col = 1, row = 1 } })
			local encoded = Protocol.encode(msg)
			assert.is_string(encoded)
			assert.is_true(#encoded > 0)
		end)

		it("produces valid JSON", function()
			local msg = Protocol.createMessage("CONNECT", { player_name = "Test" })
			local encoded = Protocol.encode(msg)
			-- Should contain expected strings
			assert.is_truthy(encoded:find('"type"'))
			assert.is_truthy(encoded:find('"CONNECT"'))
		end)
	end)

	describe("decode", function()
		it("deserializes JSON string to message", function()
			local original = Protocol.createMessage("MOVE", { from = { col = 3, row = 4 } })
			local encoded = Protocol.encode(original)
			local decoded = Protocol.decode(encoded)

			assert.are.equal(original.type, decoded.type)
			assert.are.equal(original.payload.from.col, decoded.payload.from.col)
			assert.are.equal(original.payload.from.row, decoded.payload.from.row)
		end)

		it("returns nil for invalid JSON", function()
			local decoded = Protocol.decode("not valid json")
			assert.is_nil(decoded)
		end)

		it("returns nil for empty string", function()
			local decoded = Protocol.decode("")
			assert.is_nil(decoded)
		end)
	end)

	describe("message builders", function()
		describe("connectMessage", function()
			it("creates a CONNECT message", function()
				local msg = Protocol.connectMessage("Player1", "0.1.0")
				assert.are.equal("CONNECT", msg.type)
				assert.are.equal("Player1", msg.payload.player_name)
				assert.are.equal("0.1.0", msg.payload.client_version)
			end)
		end)

		describe("moveMessage", function()
			it("creates a MOVE message", function()
				local msg = Protocol.moveMessage({ col = 3, row = 2 }, { col = 3, row = 3 })
				assert.are.equal("MOVE", msg.type)
				assert.are.equal(3, msg.payload.from.col)
				assert.are.equal(2, msg.payload.from.row)
				assert.are.equal(3, msg.payload.to.col)
				assert.are.equal(3, msg.payload.to.row)
			end)
		end)

		describe("activatePowerMessage", function()
			it("creates an ACTIVATE_POWER message", function()
				local msg = Protocol.activatePowerMessage({ col = 3, row = 2 }, "destroy_row", nil)
				assert.are.equal("ACTIVATE_POWER", msg.type)
				assert.are.equal("destroy_row", msg.payload.power_id)
				assert.is_nil(msg.payload.target)
			end)

			it("includes target when provided", function()
				local msg = Protocol.activatePowerMessage({ col = 3, row = 2 }, "raise_tile", { col = 4, row = 2 })
				assert.are.equal(4, msg.payload.target.col)
			end)
		end)

		describe("errorMessage", function()
			it("creates an ERROR message", function()
				local msg = Protocol.errorMessage("INVALID_MOVE", "Cannot move there")
				assert.are.equal("ERROR", msg.type)
				assert.are.equal("INVALID_MOVE", msg.payload.code)
				assert.are.equal("Cannot move there", msg.payload.message)
			end)
		end)

		describe("gameStateMessage", function()
			it("creates a GAME_STATE message", function()
				local state = {
					game_id = "abc123",
					turn = 5,
					current_player = 1,
					board = {},
					pieces = {},
				}
				local msg = Protocol.gameStateMessage(state)
				assert.are.equal("GAME_STATE", msg.type)
				assert.are.equal("abc123", msg.payload.game_id)
				assert.are.equal(5, msg.payload.turn)
			end)
		end)
	end)

	describe("validation", function()
		describe("isValidMessage", function()
			it("accepts valid messages", function()
				local msg = Protocol.createMessage("MOVE", { from = {}, to = {} })
				assert.is_true(Protocol.isValidMessage(msg))
			end)

			it("rejects messages without type", function()
				local msg = { payload = {} }
				assert.is_false(Protocol.isValidMessage(msg))
			end)

			it("rejects messages without payload", function()
				local msg = { type = "MOVE" }
				assert.is_false(Protocol.isValidMessage(msg))
			end)

			it("rejects nil", function()
				assert.is_false(Protocol.isValidMessage(nil))
			end)
		end)

		describe("isValidMovePayload", function()
			it("accepts valid move payload", function()
				local payload = {
					from = { col = 1, row = 1 },
					to = { col = 1, row = 2 },
				}
				assert.is_true(Protocol.isValidMovePayload(payload))
			end)

			it("rejects missing from", function()
				local payload = { to = { col = 1, row = 2 } }
				assert.is_false(Protocol.isValidMovePayload(payload))
			end)

			it("rejects missing to", function()
				local payload = { from = { col = 1, row = 1 } }
				assert.is_false(Protocol.isValidMovePayload(payload))
			end)

			it("rejects missing col in from", function()
				local payload = {
					from = { row = 1 },
					to = { col = 1, row = 2 },
				}
				assert.is_false(Protocol.isValidMovePayload(payload))
			end)
		end)
	end)
end)
