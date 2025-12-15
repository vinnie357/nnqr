-- Particles Module
-- Manages active particle effects (pure logic, no Love2D dependencies)

local ParticleConfig = require("src.shared.particle_config")

local Particles = {}

--- Create a new particle system state
---@return table Particle system state
function Particles.create()
	return {
		active = {},
	}
end

--- Spawn a particle effect at a position
---@param ps table Particle system state
---@param effectType string Effect type name from ParticleConfig
---@param x number X position
---@param y number Y position
function Particles.spawn(ps, effectType, x, y)
	local config = ParticleConfig.getEffectConfig(effectType)
	if not config then
		-- Unknown effect type - use generic power_activate
		config = ParticleConfig.getEffectConfig("power_activate")
	end

	local effect = {
		type = effectType,
		x = x,
		y = y,
		elapsed = 0,
		lifetime = config.lifetime,
		count = config.count,
		spread = config.spread,
		speed = config.speed,
		speedY = config.speedY,
		size = config.size,
		color = config.color,
		fadeOut = config.fadeOut,
	}

	table.insert(ps.active, effect)
end

--- Update all active effects
---@param ps table Particle system state
---@param dt number Delta time in seconds
function Particles.update(ps, dt)
	-- Update elapsed time and remove expired effects
	local i = 1
	while i <= #ps.active do
		local effect = ps.active[i]
		effect.elapsed = effect.elapsed + dt

		if effect.elapsed >= effect.lifetime then
			table.remove(ps.active, i)
		else
			i = i + 1
		end
	end
end

--- Get all active effects
---@param ps table Particle system state
---@return table Array of active effects
function Particles.getActiveEffects(ps)
	return ps.active
end

--- Get progress of an effect (0 to 1)
---@param effect table Effect data
---@return number Progress from 0 to 1
function Particles.getProgress(effect)
	if effect.lifetime <= 0 then
		return 1
	end
	return math.min(1, effect.elapsed / effect.lifetime)
end

--- Clear all active effects
---@param ps table Particle system state
function Particles.clear(ps)
	ps.active = {}
end

return Particles
