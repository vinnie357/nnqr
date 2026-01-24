-- Particle Configuration Tests
-- Pure data module for particle effect configurations (no Love2D dependencies)

describe("ParticleConfig", function()
	local ParticleConfig

	before_each(function()
		package.loaded["src.shared.particle_config"] = nil
		ParticleConfig = require("src.shared.particle_config")
	end)

	describe("effect definitions", function()
		it("should have explosion effect config", function()
			local config = ParticleConfig.effects.explosion
			assert.is_table(config)
			assert.is_number(config.count)
			assert.is_number(config.lifetime)
			assert.is_table(config.color)
		end)

		it("should have teleport effect config", function()
			local config = ParticleConfig.effects.teleport
			assert.is_table(config)
			assert.is_number(config.count)
			assert.is_number(config.lifetime)
		end)

		it("should have recruit effect config", function()
			local config = ParticleConfig.effects.recruit
			assert.is_table(config)
			assert.is_number(config.count)
		end)

		it("should have multiply effect config", function()
			local config = ParticleConfig.effects.multiply
			assert.is_table(config)
			assert.is_number(config.count)
		end)

		it("should have power_activate effect config", function()
			local config = ParticleConfig.effects.power_activate
			assert.is_table(config)
			assert.is_number(config.count)
		end)

		it("should have orb_collect effect config", function()
			local config = ParticleConfig.effects.orb_collect
			assert.is_table(config)
			assert.is_number(config.count)
		end)
	end)

	describe("getEffectConfig", function()
		it("should return config for known effect", function()
			local config = ParticleConfig.getEffectConfig("explosion")
			assert.is_table(config)
			assert.equals(ParticleConfig.effects.explosion, config)
		end)

		it("should return nil for unknown effect", function()
			local config = ParticleConfig.getEffectConfig("unknown_effect")
			assert.is_nil(config)
		end)
	end)

	describe("effect properties", function()
		it("explosion should have high particle count", function()
			local config = ParticleConfig.effects.explosion
			assert.is_true(config.count >= 20)
		end)

		it("explosion should have outward spread", function()
			local config = ParticleConfig.effects.explosion
			assert.is_number(config.spread)
			assert.is_true(config.spread > 0)
		end)

		it("teleport should have vertical movement", function()
			local config = ParticleConfig.effects.teleport
			assert.is_number(config.speedY)
		end)

		it("orb_collect should have gold color", function()
			local config = ParticleConfig.effects.orb_collect
			assert.is_table(config.color)
			-- Gold/yellow: high R and G, lower B
			assert.is_true(config.color[1] >= 0.8)
			assert.is_true(config.color[2] >= 0.6)
		end)

		it("effects should have reasonable lifetimes", function()
			for name, config in pairs(ParticleConfig.effects) do
				assert.is_true(
					config.lifetime > 0 and config.lifetime <= 3,
					name .. " lifetime should be between 0 and 3 seconds"
				)
			end
		end)
	end)

	describe("power effect mapping", function()
		it("should map bomb to explosion effect", function()
			local effectName = ParticleConfig.getPowerEffect("bomb")
			assert.equals("explosion", effectName)
		end)

		it("should map relocate to teleport effect", function()
			local effectName = ParticleConfig.getPowerEffect("relocate")
			assert.equals("teleport", effectName)
		end)

		it("should map recruit to recruit effect", function()
			local effectName = ParticleConfig.getPowerEffect("recruit")
			assert.equals("recruit", effectName)
		end)

		it("should map multiply to multiply effect", function()
			local effectName = ParticleConfig.getPowerEffect("multiply")
			assert.equals("multiply", effectName)
		end)

		it("should return power_activate for unmapped powers", function()
			local effectName = ParticleConfig.getPowerEffect("unknown_power")
			assert.equals("power_activate", effectName)
		end)
	end)
end)
