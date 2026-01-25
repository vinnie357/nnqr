-- Tests for player session management
-- Phase 10A: Network Multiplayer

describe("Session", function()
	local Session

	setup(function()
		package.path = "./?.lua;./src/?.lua;./server/?.lua;" .. package.path
		Session = require("server.session")
	end)

	before_each(function()
		Session.reset()
	end)

	describe("create", function()
		it("creates session with valid name", function()
			local session = Session.create("player1", "TestPlayer")

			assert.is_table(session)
			assert.is_string(session.id)
			assert.equals("player1", session.playerId)
			assert.equals("TestPlayer", session.name)
			assert.equals("connected", session.connectionState)
			assert.is_number(session.createdAt)
			assert.is_number(session.lastActivity)
		end)

		it("creates unique session IDs", function()
			local session1 = Session.create("player1", "Player1")
			local session2 = Session.create("player2", "Player2")

			assert.is_not.equals(session1.id, session2.id)
		end)

		it("marks guest names correctly", function()
			-- First generate a guest name
			local guestName = Session.generateGuestName()
			local guestSession = Session.create("player1", guestName)
			local regularSession = Session.create("player2", "RegularPlayer")

			assert.is_true(guestSession.isGuest)
			assert.is_false(regularSession.isGuest)
		end)

		it("uses default disconnect timeout", function()
			local session = Session.create("player1", "TestPlayer")
			assert.equals(60, session.disconnectTimeout)
		end)

		it("accepts custom disconnect timeout", function()
			local session = Session.create("player1", "TestPlayer", { disconnectTimeout = 120 })
			assert.equals(120, session.disconnectTimeout)
		end)

		it("initializes empty metadata", function()
			local session = Session.create("player1", "TestPlayer")
			assert.is_table(session.metadata)
			assert.equals(0, #session.metadata)
		end)
	end)

	describe("validate", function()
		it("validates correct session", function()
			local session = Session.create("player1", "TestPlayer")
			local valid, err = Session.validate(session)

			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("rejects nil session", function()
			local valid, err = Session.validate(nil)

			assert.is_false(valid)
			assert.equals("Session is nil", err)
		end)

		it("rejects session missing id", function()
			local session = { playerId = "p1", name = "Test", createdAt = os.time(), connectionState = "connected" }
			local valid, err = Session.validate(session)

			assert.is_false(valid)
			assert.equals("Session missing id", err)
		end)

		it("rejects session missing playerId", function()
			local session = { id = "s1", name = "Test", createdAt = os.time(), connectionState = "connected" }
			local valid, err = Session.validate(session)

			assert.is_false(valid)
			assert.equals("Session missing playerId", err)
		end)

		it("rejects session missing name", function()
			local session = { id = "s1", playerId = "p1", createdAt = os.time(), connectionState = "connected" }
			local valid, err = Session.validate(session)

			assert.is_false(valid)
			assert.equals("Session missing name", err)
		end)

		it("rejects session with empty name", function()
			local session =
				{ id = "s1", playerId = "p1", name = "", createdAt = os.time(), connectionState = "connected" }
			local valid, err = Session.validate(session)

			assert.is_false(valid)
			assert.equals("Session missing name", err)
		end)

		it("rejects session missing createdAt", function()
			local session = { id = "s1", playerId = "p1", name = "Test", connectionState = "connected" }
			local valid, err = Session.validate(session)

			assert.is_false(valid)
			assert.equals("Session missing createdAt", err)
		end)

		it("rejects session missing connectionState", function()
			local session = { id = "s1", playerId = "p1", name = "Test", createdAt = os.time() }
			local valid, err = Session.validate(session)

			assert.is_false(valid)
			assert.equals("Session missing connectionState", err)
		end)
	end)

	describe("generateGuestName", function()
		it("generates unique names", function()
			local names = {}
			for i = 1, 50 do
				local name = Session.generateGuestName()
				assert.is_nil(names[name], "Duplicate name generated: " .. name)
				names[name] = true
			end
		end)

		it("generates non-empty names", function()
			local name = Session.generateGuestName()
			assert.is_string(name)
			assert.is_true(#name > 0)
		end)

		it("generates names matching expected pattern", function()
			local name = Session.generateGuestName()
			-- Should be Adjective + Noun + Number or Guest_timestamp_random
			assert.is_true(
				name:match("^%a+%d+$") ~= nil or name:match("^Guest_%d+_%d+$") ~= nil,
				"Name doesn't match pattern: " .. name
			)
		end)
	end)

	describe("releaseGuestName", function()
		it("allows reuse of released name", function()
			-- Generate many names to increase chance of collision
			local firstName = Session.generateGuestName()
			Session.releaseGuestName(firstName)

			-- The name should be available again (though we can't guarantee it will be picked)
			-- At minimum, releasing shouldn't cause errors
			assert.has_no.errors(function()
				Session.releaseGuestName(firstName)
			end)
		end)
	end)

	describe("isGuestName", function()
		it("identifies generated guest names", function()
			local guestName = Session.generateGuestName()
			assert.is_true(Session.isGuestName(guestName))
		end)

		it("rejects regular player names", function()
			assert.is_false(Session.isGuestName("JohnDoe"))
			assert.is_false(Session.isGuestName("Player123"))
			assert.is_false(Session.isGuestName("xXx_Gamer_xXx"))
		end)

		it("identifies fallback guest names", function()
			assert.is_true(Session.isGuestName("Guest_1234567890_1234"))
		end)
	end)

	describe("isExpired", function()
		it("returns false for connected sessions", function()
			local session = Session.create("player1", "Test")
			session.connectionState = "connected"

			assert.is_false(Session.isExpired(session))
		end)

		it("returns false for recently disconnected sessions", function()
			local session = Session.create("player1", "Test")
			session.connectionState = "disconnected"
			session.lastActivity = os.time()

			assert.is_false(Session.isExpired(session))
		end)

		it("returns true for expired disconnected sessions", function()
			local session = Session.create("player1", "Test")
			session.connectionState = "disconnected"
			session.disconnectTimeout = 60
			session.lastActivity = os.time() - 120 -- 2 minutes ago

			assert.is_true(Session.isExpired(session, os.time()))
		end)

		it("respects custom timeout", function()
			local session = Session.create("player1", "Test", { disconnectTimeout = 10 })
			session.connectionState = "disconnected"
			session.lastActivity = os.time() - 15

			assert.is_true(Session.isExpired(session))
		end)
	end)

	describe("touch", function()
		it("updates lastActivity", function()
			local session = Session.create("player1", "Test")
			local originalTime = session.lastActivity

			-- Wait a tiny bit to ensure time changes
			session.lastActivity = originalTime - 10

			Session.touch(session)

			assert.is_true(session.lastActivity >= originalTime)
		end)
	end)

	describe("setConnectionState", function()
		it("sets valid connection state", function()
			local session = Session.create("player1", "Test")

			local success, err = Session.setConnectionState(session, "disconnected")

			assert.is_true(success)
			assert.is_nil(err)
			assert.equals("disconnected", session.connectionState)
		end)

		it("accepts all valid states", function()
			local session = Session.create("player1", "Test")

			for _, state in ipairs({ "connected", "disconnected", "reconnecting" }) do
				local success, err = Session.setConnectionState(session, state)
				assert.is_true(success, "Should accept state: " .. state)
				assert.is_nil(err)
			end
		end)

		it("rejects invalid state", function()
			local session = Session.create("player1", "Test")

			local success, err = Session.setConnectionState(session, "invalid")

			assert.is_false(success)
			assert.equals("Invalid connection state: invalid", err)
		end)

		it("updates lastActivity", function()
			local session = Session.create("player1", "Test")
			session.lastActivity = os.time() - 100

			Session.setConnectionState(session, "disconnected")

			assert.is_true(session.lastActivity > os.time() - 10)
		end)
	end)

	describe("getDuration", function()
		it("returns session duration", function()
			local session = Session.create("player1", "Test")
			session.createdAt = os.time() - 300 -- 5 minutes ago

			local duration = Session.getDuration(session)

			assert.is_true(duration >= 300)
		end)

		it("accepts custom current time", function()
			local session = Session.create("player1", "Test")
			session.createdAt = 1000

			local duration = Session.getDuration(session, 1500)

			assert.equals(500, duration)
		end)
	end)

	describe("metadata", function()
		it("sets and gets metadata", function()
			local session = Session.create("player1", "Test")

			Session.setMetadata(session, "score", 100)
			local value = Session.getMetadata(session, "score")

			assert.equals(100, value)
		end)

		it("returns nil for missing metadata", function()
			local session = Session.create("player1", "Test")

			local value = Session.getMetadata(session, "nonexistent")

			assert.is_nil(value)
		end)

		it("overwrites existing metadata", function()
			local session = Session.create("player1", "Test")

			Session.setMetadata(session, "key", "value1")
			Session.setMetadata(session, "key", "value2")

			assert.equals("value2", Session.getMetadata(session, "key"))
		end)
	end)

	describe("validateName", function()
		it("accepts valid names", function()
			local valid, err = Session.validateName("TestPlayer")
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("accepts names with spaces", function()
			local valid, err = Session.validateName("Test Player")
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("accepts names with underscores", function()
			local valid, err = Session.validateName("Test_Player")
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("accepts names with hyphens", function()
			local valid, err = Session.validateName("Test-Player")
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("accepts names with numbers", function()
			local valid, err = Session.validateName("Player123")
			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("rejects nil name", function()
			local valid, err = Session.validateName(nil)
			assert.is_false(valid)
			assert.equals("Name is required", err)
		end)

		it("rejects non-string name", function()
			local valid, err = Session.validateName(123)
			assert.is_false(valid)
			assert.equals("Name must be a string", err)
		end)

		it("rejects empty name", function()
			local valid, err = Session.validateName("")
			assert.is_false(valid)
			assert.equals("Name cannot be empty", err)
		end)

		it("rejects whitespace-only name", function()
			local valid, err = Session.validateName("   ")
			assert.is_false(valid)
			assert.equals("Name cannot be empty", err)
		end)

		it("rejects name too short", function()
			local valid, err = Session.validateName("A")
			assert.is_false(valid)
			assert.equals("Name must be at least 2 characters", err)
		end)

		it("rejects name too long", function()
			local valid, err = Session.validateName("ThisNameIsWayTooLongForOurSystem")
			assert.is_false(valid)
			assert.equals("Name cannot exceed 20 characters", err)
		end)

		it("rejects names with special characters", function()
			local valid, err = Session.validateName("Player@123")
			assert.is_false(valid)
			assert.equals("Name contains invalid characters", err)
		end)
	end)
end)
