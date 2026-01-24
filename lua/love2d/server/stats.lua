-- Stats Module
-- Tracks player statistics and ranking for multiplayer games
-- Phase 2: Stats & Ranking System

local Stats = {}

-- Rank tier thresholds
Stats.RANKS = {
	{ threshold = 2000, name = "Diamond" },
	{ threshold = 1600, name = "Platinum" },
	{ threshold = 1200, name = "Gold" },
	{ threshold = 800, name = "Silver" },
	{ threshold = 0, name = "Bronze" },
}

-- Default K-factor for ELO calculations
Stats.DEFAULT_K_FACTOR = 32

-- Starting rating for new players
Stats.STARTING_RATING = 1000

-- Minimum rating (can't go below this)
Stats.MIN_RATING = 0

--- Create a new stats object for a player
---@return table stats New stats structure
function Stats.create()
	return {
		ai = {
			easy = { wins = 0, losses = 0, games = 0 },
			medium = { wins = 0, losses = 0, games = 0 },
			hard = { wins = 0, losses = 0, games = 0 },
			expert = { wins = 0, losses = 0, games = 0 },
		},
		pvp = {
			wins = 0,
			losses = 0,
			games = 0,
		},
		rating = Stats.STARTING_RATING,
	}
end

--- Record an AI game result
---@param stats table Player stats object
---@param difficulty string AI difficulty (easy/medium/hard/expert)
---@param won boolean Whether the player won
function Stats.recordAIGame(stats, difficulty, won)
	local diffStats = stats.ai[difficulty]
	if not diffStats then
		return -- Invalid difficulty, ignore
	end

	diffStats.games = diffStats.games + 1
	if won then
		diffStats.wins = diffStats.wins + 1
	else
		diffStats.losses = diffStats.losses + 1
	end
end

--- Record a PvP game result and update rating
---@param stats table Player stats object
---@param opponentRating number Opponent's rating
---@param won boolean Whether the player won
---@return number ratingChange The change in rating (positive or negative)
function Stats.recordPvPGame(stats, opponentRating, won)
	stats.pvp.games = stats.pvp.games + 1
	if won then
		stats.pvp.wins = stats.pvp.wins + 1
	else
		stats.pvp.losses = stats.pvp.losses + 1
	end

	local oldRating = stats.rating
	stats.rating = Stats.calculateRating(stats.rating, opponentRating, won)
	return stats.rating - oldRating
end

--- Calculate new ELO rating
---@param currentRating number Player's current rating
---@param opponentRating number Opponent's rating
---@param won boolean Whether the player won
---@param kFactor number|nil K-factor (default 32)
---@return number newRating The new rating
function Stats.calculateRating(currentRating, opponentRating, won, kFactor)
	kFactor = kFactor or Stats.DEFAULT_K_FACTOR

	-- Calculate expected score using ELO formula
	local exponent = (opponentRating - currentRating) / 400
	local expectedScore = 1 / (1 + math.pow(10, exponent))

	-- Actual score: 1 for win, 0 for loss
	local actualScore = won and 1 or 0

	-- Calculate new rating
	local newRating = currentRating + kFactor * (actualScore - expectedScore)

	-- Ensure rating doesn't go below minimum
	newRating = math.max(Stats.MIN_RATING, math.floor(newRating + 0.5))

	return newRating
end

--- Get rank name for a given rating
---@param rating number Player's rating
---@return string rank Rank name (Bronze/Silver/Gold/Platinum/Diamond)
function Stats.getRank(rating)
	for _, tier in ipairs(Stats.RANKS) do
		if rating >= tier.threshold then
			return tier.name
		end
	end
	return "Bronze" -- Fallback
end

--- Calculate win rate for a category
---@param stats table Player stats object
---@param category string Category: "pvp", "ai_easy", "ai_medium", "ai_hard", "ai_expert"
---@return number winRate Win rate as percentage (0-100)
function Stats.getWinRate(stats, category)
	local categoryStats

	if category == "pvp" then
		categoryStats = stats.pvp
	elseif category:sub(1, 3) == "ai_" then
		local difficulty = category:sub(4)
		categoryStats = stats.ai[difficulty]
	end

	if not categoryStats or categoryStats.games == 0 then
		return 0
	end

	return math.floor((categoryStats.wins / categoryStats.games) * 100 + 0.5)
end

--- Get total AI stats across all difficulties
---@param stats table Player stats object
---@return table total Combined stats {wins, losses, games}
function Stats.getTotalAIStats(stats)
	local total = { wins = 0, losses = 0, games = 0 }

	for _, diffStats in pairs(stats.ai) do
		total.wins = total.wins + diffStats.wins
		total.losses = total.losses + diffStats.losses
		total.games = total.games + diffStats.games
	end

	return total
end

return Stats
