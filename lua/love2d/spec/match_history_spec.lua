-- Match History Tests (TDD - written BEFORE implementation)
-- Phase 10C.3: Game result logging and history view
-- Run with: busted spec/

package.path = package.path .. ";./?.lua;./?/init.lua"

describe("MatchHistory", function()
	local MatchHistory
	local tmpDir

	-- Create a unique temp directory per test run to avoid cross-test pollution.
	setup(function()
		MatchHistory = require("src.shared.match_history")
		-- Unique directory using a process-time integer to isolate test state
		tmpDir = "/tmp/nnqr_match_history_" .. tostring(math.floor(os.time() * 1000) + math.random(100000))
		os.execute('mkdir -p "' .. tmpDir .. '"')
	end)

	-- Remove the temp directory after all tests complete.
	teardown(function()
		os.execute('rm -rf "' .. tmpDir .. '"')
	end)

	-- Helper: build an injected writer table that uses a temp file path.
	local function makeIO(filename)
		local path = tmpDir .. "/" .. filename
		return {
			path = path,
			write = function(content)
				local f, err = io.open(path, "w")
				if not f then
					return false, err
				end
				f:write(content)
				f:close()
				return true
			end,
			read = function()
				local f = io.open(path, "r")
				if not f then
					return nil
				end
				local data = f:read("*a")
				f:close()
				return data
			end,
		}
	end

	-- -------------------------------------------------------------------------
	-- AC 1: record then load round-trips a result
	-- -------------------------------------------------------------------------
	describe("record and load round-trip", function()
		it("record writes a result that load returns", function()
			local io_adapter = makeIO("roundtrip.json")
			local result = {
				date = "2026-05-30",
				opponent = "AI-easy",
				mode = "vsai",
				result = "win",
				duration_seconds = 120,
				player_name = "Player1",
			}
			local ok, err = MatchHistory.record(result, io_adapter)
			assert.is_true(ok, "record should succeed: " .. tostring(err))

			local records, load_err = MatchHistory.load(io_adapter)
			assert.is_nil(load_err, "load should not return error: " .. tostring(load_err))
			assert.is_table(records)
			assert.are.equal(1, #records)
			assert.are.equal("2026-05-30", records[1].date)
			assert.are.equal("AI-easy", records[1].opponent)
			assert.are.equal("vsai", records[1].mode)
			assert.are.equal("win", records[1].result)
			assert.are.equal(120, records[1].duration_seconds)
			assert.are.equal("Player1", records[1].player_name)
		end)

		it("multiple records round-trip in order", function()
			local io_adapter = makeIO("multi.json")
			local r1 = {
				date = "2026-05-01",
				opponent = "Player2",
				mode = "twoplayer",
				result = "loss",
				duration_seconds = 60,
				player_name = "Alice",
			}
			local r2 = {
				date = "2026-05-02",
				opponent = "AI-hard",
				mode = "vsai",
				result = "win",
				duration_seconds = 300,
				player_name = "Alice",
			}

			local ok1 = MatchHistory.record(r1, io_adapter)
			local ok2 = MatchHistory.record(r2, io_adapter)
			assert.is_true(ok1)
			assert.is_true(ok2)

			local records = MatchHistory.load(io_adapter)
			assert.is_table(records)
			assert.are.equal(2, #records)
			assert.are.equal("twoplayer", records[1].mode)
			assert.are.equal("vsai", records[2].mode)
		end)

		it("all three modes round-trip correctly", function()
			local io_adapter = makeIO("modes.json")
			MatchHistory.record({
				date = "d1",
				opponent = "AI",
				mode = "vsai",
				result = "win",
				duration_seconds = 10,
				player_name = "P",
			}, io_adapter)
			MatchHistory.record({
				date = "d2",
				opponent = "P2",
				mode = "twoplayer",
				result = "loss",
				duration_seconds = 20,
				player_name = "P",
			}, io_adapter)
			MatchHistory.record({
				date = "d3",
				opponent = "Foe",
				mode = "multiplayer",
				result = "draw",
				duration_seconds = 30,
				player_name = "P",
			}, io_adapter)

			local records = MatchHistory.load(io_adapter)
			assert.are.equal(3, #records)
			assert.are.equal("vsai", records[1].mode)
			assert.are.equal("twoplayer", records[2].mode)
			assert.are.equal("multiplayer", records[3].mode)
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC 2: load on missing file returns {} (no crash)
	-- -------------------------------------------------------------------------
	describe("load on missing file", function()
		it("returns empty table when file does not exist", function()
			local io_adapter = makeIO("nonexistent_" .. tostring(math.random(99999)) .. ".json")
			-- Do NOT call record — file never created
			local records, err = MatchHistory.load(io_adapter)
			assert.is_nil(err)
			assert.is_table(records)
			assert.are.equal(0, #records)
		end)

		it("returns empty table via nil-read adapter", function()
			local missing_io = {
				path = tmpDir .. "/does_not_exist.json",
				write = function()
					return false, "not used"
				end,
				read = function()
					return nil
				end,
			}
			local records, err = MatchHistory.load(missing_io)
			assert.is_nil(err)
			assert.is_table(records)
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC 3: load on corrupt file returns {} (no crash)
	-- -------------------------------------------------------------------------
	describe("load on corrupt file", function()
		it("returns empty table for invalid JSON", function()
			local io_adapter = makeIO("corrupt.json")
			-- Write garbage bytes directly (io.open pattern-match, not bang)
			local f = io.open(io_adapter.path, "w")
			f:write("{{{not valid json at all!!!")
			f:close()

			local records, err = MatchHistory.load(io_adapter)
			assert.is_nil(err)
			assert.is_table(records)
			assert.are.equal(0, #records)
		end)

		it("returns empty table for empty file", function()
			local io_adapter = makeIO("empty.json")
			local f = io.open(io_adapter.path, "w")
			f:write("")
			f:close()

			local records, err = MatchHistory.load(io_adapter)
			assert.is_nil(err)
			assert.is_table(records)
			assert.are.equal(0, #records)
		end)

		it("returns empty table for partial JSON", function()
			local io_adapter = makeIO("partial.json")
			local f = io.open(io_adapter.path, "w")
			f:write('{"records":[{"date":"2026')
			f:close()

			local records, err = MatchHistory.load(io_adapter)
			assert.is_nil(err)
			assert.is_table(records)
			assert.are.equal(0, #records)
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC 4: stats computes correct win/loss/draw counts
	-- -------------------------------------------------------------------------
	describe("stats", function()
		it("returns zero counts with no history", function()
			local io_adapter = makeIO("stats_empty.json")
			local s = MatchHistory.stats("Alice", io_adapter)
			assert.is_table(s)
			assert.are.equal(0, s.wins)
			assert.are.equal(0, s.losses)
			assert.are.equal(0, s.draws)
			assert.are.equal(0, s.total)
		end)

		it("counts wins correctly", function()
			local io_adapter = makeIO("stats_wins.json")
			MatchHistory.record({
				date = "d1",
				opponent = "AI",
				mode = "vsai",
				result = "win",
				duration_seconds = 10,
				player_name = "Alice",
			}, io_adapter)
			MatchHistory.record({
				date = "d2",
				opponent = "P2",
				mode = "twoplayer",
				result = "win",
				duration_seconds = 20,
				player_name = "Alice",
			}, io_adapter)
			MatchHistory.record({
				date = "d3",
				opponent = "Foe",
				mode = "multiplayer",
				result = "loss",
				duration_seconds = 30,
				player_name = "Alice",
			}, io_adapter)

			local s = MatchHistory.stats("Alice", io_adapter)
			assert.are.equal(2, s.wins)
			assert.are.equal(1, s.losses)
			assert.are.equal(0, s.draws)
			assert.are.equal(3, s.total)
		end)

		it("counts draws correctly", function()
			local io_adapter = makeIO("stats_draws.json")
			MatchHistory.record({
				date = "d1",
				opponent = "A",
				mode = "vsai",
				result = "draw",
				duration_seconds = 5,
				player_name = "Bob",
			}, io_adapter)
			MatchHistory.record({
				date = "d2",
				opponent = "B",
				mode = "vsai",
				result = "draw",
				duration_seconds = 5,
				player_name = "Bob",
			}, io_adapter)
			MatchHistory.record({
				date = "d3",
				opponent = "C",
				mode = "vsai",
				result = "win",
				duration_seconds = 5,
				player_name = "Bob",
			}, io_adapter)

			local s = MatchHistory.stats("Bob", io_adapter)
			assert.are.equal(1, s.wins)
			assert.are.equal(0, s.losses)
			assert.are.equal(2, s.draws)
			assert.are.equal(3, s.total)
		end)

		it("counts all three result types from mixed history", function()
			local io_adapter = makeIO("stats_mixed.json")
			for _ = 1, 3 do
				MatchHistory.record({
					date = "d",
					opponent = "X",
					mode = "vsai",
					result = "win",
					duration_seconds = 1,
					player_name = "Eve",
				}, io_adapter)
			end
			for _ = 1, 2 do
				MatchHistory.record({
					date = "d",
					opponent = "X",
					mode = "vsai",
					result = "loss",
					duration_seconds = 1,
					player_name = "Eve",
				}, io_adapter)
			end
			MatchHistory.record({
				date = "d",
				opponent = "X",
				mode = "vsai",
				result = "draw",
				duration_seconds = 1,
				player_name = "Eve",
			}, io_adapter)

			local s = MatchHistory.stats("Eve", io_adapter)
			assert.are.equal(3, s.wins)
			assert.are.equal(2, s.losses)
			assert.are.equal(1, s.draws)
			assert.are.equal(6, s.total)
		end)

		it("per-opponent breakdown is included when records exist", function()
			local io_adapter = makeIO("stats_per_opp.json")
			MatchHistory.record({
				date = "d",
				opponent = "AI-easy",
				mode = "vsai",
				result = "win",
				duration_seconds = 1,
				player_name = "P",
			}, io_adapter)
			MatchHistory.record({
				date = "d",
				opponent = "AI-easy",
				mode = "vsai",
				result = "loss",
				duration_seconds = 1,
				player_name = "P",
			}, io_adapter)
			MatchHistory.record({
				date = "d",
				opponent = "AI-hard",
				mode = "vsai",
				result = "win",
				duration_seconds = 1,
				player_name = "P",
			}, io_adapter)

			local s = MatchHistory.stats("P", io_adapter)
			assert.is_table(s.by_opponent)
			assert.is_table(s.by_opponent["AI-easy"])
			assert.are.equal(1, s.by_opponent["AI-easy"].wins)
			assert.are.equal(1, s.by_opponent["AI-easy"].losses)
			assert.is_table(s.by_opponent["AI-hard"])
			assert.are.equal(1, s.by_opponent["AI-hard"].wins)
		end)
	end)

	-- -------------------------------------------------------------------------
	-- AC 5: game-over hook records exactly one result (no double-record)
	-- -------------------------------------------------------------------------
	describe("game-over hook: no double-record", function()
		it("recordOnce records only one entry even if called twice", function()
			local io_adapter = makeIO("once.json")
			local guard = MatchHistory.createRecordGuard()

			local result = {
				date = "d",
				opponent = "AI",
				mode = "vsai",
				result = "win",
				duration_seconds = 10,
				player_name = "P",
			}

			-- Call twice simulating two code paths both calling record
			MatchHistory.recordOnce(guard, result, io_adapter)
			MatchHistory.recordOnce(guard, result, io_adapter)

			local records = MatchHistory.load(io_adapter)
			assert.are.equal(1, #records)
		end)

		it("a fresh guard allows exactly one record", function()
			local io_adapter = makeIO("guard_fresh.json")
			local guard = MatchHistory.createRecordGuard()
			assert.is_false(guard.recorded)

			local result = {
				date = "d",
				opponent = "X",
				mode = "twoplayer",
				result = "loss",
				duration_seconds = 5,
				player_name = "Q",
			}
			MatchHistory.recordOnce(guard, result, io_adapter)
			assert.is_true(guard.recorded)

			-- Second call should be a no-op
			MatchHistory.recordOnce(guard, result, io_adapter)

			local records = MatchHistory.load(io_adapter)
			assert.are.equal(1, #records)
		end)

		it("different guards are independent (no shared state)", function()
			local io1 = makeIO("guard_ind1.json")
			local io2 = makeIO("guard_ind2.json")
			local guard1 = MatchHistory.createRecordGuard()
			local guard2 = MatchHistory.createRecordGuard()

			local r = {
				date = "d",
				opponent = "A",
				mode = "vsai",
				result = "win",
				duration_seconds = 1,
				player_name = "P",
			}
			MatchHistory.recordOnce(guard1, r, io1)
			MatchHistory.recordOnce(guard2, r, io2)

			local recs1 = MatchHistory.load(io1)
			local recs2 = MatchHistory.load(io2)
			assert.are.equal(1, #recs1)
			assert.are.equal(1, #recs2)
		end)
	end)
end)
