-- Particle Configuration Module
-- Pure data for particle effect configurations (no Love2D dependencies)

local ParticleConfig = {}

-- Effect definitions with all parameters needed for particle systems
ParticleConfig.effects = {
	explosion = {
		count = 30,
		lifetime = 0.8,
		spread = 360, -- degrees
		speed = { min = 100, max = 250 },
		speedY = 0,
		size = { start = 6, finish = 2 },
		color = { 1, 0.6, 0.2, 1 }, -- Orange
		fadeOut = true,
	},

	teleport = {
		count = 20,
		lifetime = 0.6,
		spread = 360,
		speed = { min = 50, max = 100 },
		speedY = -100, -- Upward float
		size = { start = 4, finish = 1 },
		color = { 0.6, 0.3, 1, 1 }, -- Purple
		fadeOut = true,
	},

	recruit = {
		count = 15,
		lifetime = 0.7,
		spread = 360,
		speed = { min = 30, max = 80 },
		speedY = -50,
		size = { start = 3, finish = 1 },
		color = { 0.3, 0.9, 0.5, 1 }, -- Green
		fadeOut = true,
	},

	multiply = {
		count = 12,
		lifetime = 0.5,
		spread = 180, -- Half circle
		speed = { min = 60, max = 120 },
		speedY = 0,
		size = { start = 4, finish = 2 },
		color = { 0.8, 0.9, 1, 1 }, -- Light blue/white
		fadeOut = true,
	},

	power_activate = {
		count = 10,
		lifetime = 0.4,
		spread = 360,
		speed = { min = 40, max = 80 },
		speedY = -30,
		size = { start = 3, finish = 1 },
		color = { 1, 0.9, 0.3, 1 }, -- Gold
		fadeOut = true,
	},

	orb_collect = {
		count = 8,
		lifetime = 0.5,
		spread = 360,
		speed = { min = 50, max = 100 },
		speedY = -80,
		size = { start = 4, finish = 1 },
		color = { 0.9, 0.8, 0.2, 1 }, -- Gold/yellow
		fadeOut = true,
	},
}

-- Power ID to effect name mapping
ParticleConfig.powerEffects = {
	bomb = "explosion",
	destroy_row = "explosion",
	destroy_column = "explosion",
	relocate = "teleport",
	recruit = "recruit",
	multiply = "multiply",
}

--- Get configuration for a named effect
---@param effectName string Effect name
---@return table|nil Effect configuration or nil if not found
function ParticleConfig.getEffectConfig(effectName)
	return ParticleConfig.effects[effectName]
end

--- Get the particle effect name for a power
---@param powerId string Power ID
---@return string Effect name (defaults to "power_activate")
function ParticleConfig.getPowerEffect(powerId)
	return ParticleConfig.powerEffects[powerId] or "power_activate"
end

return ParticleConfig
