-- Stats Module Tests
-- Phase 2: Stats & Ranking System

describe("Stats", function()
	local Stats

	setup(function()
		Stats = require("server.stats")
	end)

	describe("create", function()
		it("returns a valid stats structure", function()
			local stats = Stats.create()
			assert.is_table(stats)
			assert.is_table(stats.ai)
			assert.is_table(stats.pvp)
			assert.is_number(stats.rating)
		end)

		it("initializes AI stats for all difficulties", function()
			local stats = Stats.create()
			assert.is_table(stats.ai.easy)
			assert.is_table(stats.ai.medium)
			assert.is_table(stats.ai.hard)
			assert.is_table(stats.ai.expert)
		end)

		it("initializes AI difficulty stats with zeros", function()
			local stats = Stats.create()
			assert.are.equal(0, stats.ai.easy.wins)
			assert.are.equal(0, stats.ai.easy.losses)
			assert.are.equal(0, stats.ai.easy.games)
		end)

		it("initializes PvP stats with zeros", function()
			local stats = Stats.create()
			assert.are.equal(0, stats.pvp.wins)
			assert.are.equal(0, stats.pvp.losses)
			assert.are.equal(0, stats.pvp.games)
		end)

		it("initializes rating at 1000", function()
			local stats = Stats.create()
			assert.are.equal(1000, stats.rating)
		end)
	end)

	describe("recordAIGame", function()
		it("increments games count for correct difficulty", function()
			local stats = Stats.create()
			Stats.recordAIGame(stats, "easy", true)
			assert.are.equal(1, stats.ai.easy.games)
			assert.are.equal(0, stats.ai.medium.games)
		end)

		it("increments wins on win", function()
			local stats = Stats.create()
			Stats.recordAIGame(stats, "medium", true)
			assert.are.equal(1, stats.ai.medium.wins)
			assert.are.equal(0, stats.ai.medium.losses)
		end)

		it("increments losses on loss", function()
			local stats = Stats.create()
			Stats.recordAIGame(stats, "hard", false)
			assert.are.equal(0, stats.ai.hard.wins)
			assert.are.equal(1, stats.ai.hard.losses)
		end)

		it("accumulates multiple games", function()
			local stats = Stats.create()
			Stats.recordAIGame(stats, "expert", true)
			Stats.recordAIGame(stats, "expert", true)
			Stats.recordAIGame(stats, "expert", false)
			assert.are.equal(3, stats.ai.expert.games)
			assert.are.equal(2, stats.ai.expert.wins)
			assert.are.equal(1, stats.ai.expert.losses)
		end)

		it("does not affect rating", function()
			local stats = Stats.create()
			Stats.recordAIGame(stats, "easy", true)
			assert.are.equal(1000, stats.rating) -- Rating unchanged
		end)

		it("handles invalid difficulty gracefully", function()
			local stats = Stats.create()
			-- Should not crash
			Stats.recordAIGame(stats, "invalid", true)
			-- Stats should remain unchanged
			assert.are.equal(0, stats.ai.easy.games)
		end)
	end)

	describe("recordPvPGame", function()
		it("increments games count", function()
			local stats = Stats.create()
			Stats.recordPvPGame(stats, 1000, true)
			assert.are.equal(1, stats.pvp.games)
		end)

		it("increments wins on win", function()
			local stats = Stats.create()
			Stats.recordPvPGame(stats, 1000, true)
			assert.are.equal(1, stats.pvp.wins)
			assert.are.equal(0, stats.pvp.losses)
		end)

		it("increments losses on loss", function()
			local stats = Stats.create()
			Stats.recordPvPGame(stats, 1000, false)
			assert.are.equal(0, stats.pvp.wins)
			assert.are.equal(1, stats.pvp.losses)
		end)

		it("increases rating on win", function()
			local stats = Stats.create()
			local oldRating = stats.rating
			Stats.recordPvPGame(stats, 1000, true)
			assert.is_true(stats.rating > oldRating)
		end)

		it("decreases rating on loss", function()
			local stats = Stats.create()
			local oldRating = stats.rating
			Stats.recordPvPGame(stats, 1000, false)
			assert.is_true(stats.rating < oldRating)
		end)

		it("returns rating change", function()
			local stats = Stats.create()
			local change = Stats.recordPvPGame(stats, 1000, true)
			assert.is_number(change)
			assert.is_true(change > 0)
		end)

		it("returns negative rating change on loss", function()
			local stats = Stats.create()
			local change = Stats.recordPvPGame(stats, 1000, false)
			assert.is_number(change)
			assert.is_true(change < 0)
		end)
	end)

	describe("calculateRating", function()
		it("gives +16 for win vs equal opponent with K=32", function()
			local newRating = Stats.calculateRating(1000, 1000, true, 32)
			assert.are.equal(1016, newRating)
		end)

		it("gives -16 for loss vs equal opponent with K=32", function()
			local newRating = Stats.calculateRating(1000, 1000, false, 32)
			assert.are.equal(984, newRating)
		end)

		it("gives more for win vs higher opponent", function()
			local vsEqual = Stats.calculateRating(1000, 1000, true, 32)
			local vsHigher = Stats.calculateRating(1000, 1200, true, 32)
			assert.is_true(vsHigher > vsEqual)
		end)

		it("gives less for win vs lower opponent", function()
			local vsEqual = Stats.calculateRating(1000, 1000, true, 32)
			local vsLower = Stats.calculateRating(1000, 800, true, 32)
			assert.is_true(vsLower < vsEqual)
		end)

		it("loses less vs higher opponent", function()
			local lossVsEqual = 1000 - Stats.calculateRating(1000, 1000, false, 32)
			local lossVsHigher = 1000 - Stats.calculateRating(1000, 1200, false, 32)
			assert.is_true(lossVsHigher < lossVsEqual)
		end)

		it("loses more vs lower opponent", function()
			local lossVsEqual = 1000 - Stats.calculateRating(1000, 1000, false, 32)
			local lossVsLower = 1000 - Stats.calculateRating(1000, 800, false, 32)
			assert.is_true(lossVsLower > lossVsEqual)
		end)

		it("respects minimum rating of 0", function()
			local newRating = Stats.calculateRating(10, 2000, false, 32)
			assert.is_true(newRating >= 0)
		end)

		it("uses default K-factor of 32 when not specified", function()
			local withK = Stats.calculateRating(1000, 1000, true, 32)
			local withoutK = Stats.calculateRating(1000, 1000, true)
			assert.are.equal(withK, withoutK)
		end)
	end)

	describe("getRank", function()
		it("returns Bronze for rating below 800", function()
			assert.are.equal("Bronze", Stats.getRank(0))
			assert.are.equal("Bronze", Stats.getRank(500))
			assert.are.equal("Bronze", Stats.getRank(799))
		end)

		it("returns Silver for rating 800-1199", function()
			assert.are.equal("Silver", Stats.getRank(800))
			assert.are.equal("Silver", Stats.getRank(1000))
			assert.are.equal("Silver", Stats.getRank(1199))
		end)

		it("returns Gold for rating 1200-1599", function()
			assert.are.equal("Gold", Stats.getRank(1200))
			assert.are.equal("Gold", Stats.getRank(1400))
			assert.are.equal("Gold", Stats.getRank(1599))
		end)

		it("returns Platinum for rating 1600-1999", function()
			assert.are.equal("Platinum", Stats.getRank(1600))
			assert.are.equal("Platinum", Stats.getRank(1800))
			assert.are.equal("Platinum", Stats.getRank(1999))
		end)

		it("returns Diamond for rating 2000+", function()
			assert.are.equal("Diamond", Stats.getRank(2000))
			assert.are.equal("Diamond", Stats.getRank(2500))
			assert.are.equal("Diamond", Stats.getRank(3000))
		end)
	end)

	describe("getWinRate", function()
		it("returns 0 for zero games", function()
			local stats = Stats.create()
			assert.are.equal(0, Stats.getWinRate(stats, "pvp"))
			assert.are.equal(0, Stats.getWinRate(stats, "ai_easy"))
		end)

		it("calculates PvP win rate correctly", function()
			local stats = Stats.create()
			stats.pvp.wins = 3
			stats.pvp.losses = 1
			stats.pvp.games = 4
			assert.are.equal(75, Stats.getWinRate(stats, "pvp"))
		end)

		it("calculates AI win rate correctly", function()
			local stats = Stats.create()
			stats.ai.hard.wins = 2
			stats.ai.hard.losses = 2
			stats.ai.hard.games = 4
			assert.are.equal(50, Stats.getWinRate(stats, "ai_hard"))
		end)

		it("returns 100 for all wins", function()
			local stats = Stats.create()
			stats.pvp.wins = 5
			stats.pvp.losses = 0
			stats.pvp.games = 5
			assert.are.equal(100, Stats.getWinRate(stats, "pvp"))
		end)

		it("returns 0 for all losses", function()
			local stats = Stats.create()
			stats.ai.expert.wins = 0
			stats.ai.expert.losses = 3
			stats.ai.expert.games = 3
			assert.are.equal(0, Stats.getWinRate(stats, "ai_expert"))
		end)

		it("handles invalid category gracefully", function()
			local stats = Stats.create()
			assert.are.equal(0, Stats.getWinRate(stats, "invalid"))
		end)
	end)

	describe("getTotalAIStats", function()
		it("returns combined stats across all difficulties", function()
			local stats = Stats.create()
			stats.ai.easy.wins = 5
			stats.ai.easy.losses = 2
			stats.ai.easy.games = 7
			stats.ai.hard.wins = 3
			stats.ai.hard.losses = 4
			stats.ai.hard.games = 7

			local total = Stats.getTotalAIStats(stats)
			assert.are.equal(8, total.wins)
			assert.are.equal(6, total.losses)
			assert.are.equal(14, total.games)
		end)

		it("returns zeros for no AI games", function()
			local stats = Stats.create()
			local total = Stats.getTotalAIStats(stats)
			assert.are.equal(0, total.wins)
			assert.are.equal(0, total.losses)
			assert.are.equal(0, total.games)
		end)
	end)
end)
