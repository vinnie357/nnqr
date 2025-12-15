-- Particles Module Tests
-- Manages active particle effects (pure logic, no Love2D dependencies)

describe("Particles", function()
	local Particles

	before_each(function()
		package.loaded["src.shared.particles"] = nil
		Particles = require("src.shared.particles")
	end)

	describe("create", function()
		it("should create a particle system state", function()
			local ps = Particles.create()
			assert.is_table(ps)
			assert.is_table(ps.active)
		end)

		it("should start with no active effects", function()
			local ps = Particles.create()
			assert.are.equal(0, #ps.active)
		end)
	end)

	describe("spawn", function()
		it("should add an effect to active list", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			assert.are.equal(1, #ps.active)
		end)

		it("should store effect type and position", function()
			local ps = Particles.create()
			Particles.spawn(ps, "teleport", 150, 250)
			local effect = ps.active[1]
			assert.are.equal("teleport", effect.type)
			assert.are.equal(150, effect.x)
			assert.are.equal(250, effect.y)
		end)

		it("should initialize elapsed time to 0", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			assert.are.equal(0, ps.active[1].elapsed)
		end)

		it("should copy config from ParticleConfig", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			local effect = ps.active[1]
			assert.is_number(effect.lifetime)
			assert.is_number(effect.count)
			assert.is_true(effect.lifetime > 0)
		end)
	end)

	describe("update", function()
		it("should advance elapsed time", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			Particles.update(ps, 0.1)
			assert.are.equal(0.1, ps.active[1].elapsed)
		end)

		it("should remove expired effects", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			-- Advance past lifetime
			Particles.update(ps, 10.0)
			assert.are.equal(0, #ps.active)
		end)

		it("should keep active effects", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			Particles.update(ps, 0.1)
			assert.are.equal(1, #ps.active)
		end)
	end)

	describe("getActiveEffects", function()
		it("should return all active effects", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			Particles.spawn(ps, "teleport", 150, 250)
			local effects = Particles.getActiveEffects(ps)
			assert.are.equal(2, #effects)
		end)
	end)

	describe("getProgress", function()
		it("should return 0 at start", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			local progress = Particles.getProgress(ps.active[1])
			assert.are.equal(0, progress)
		end)

		it("should return 0.5 at halfway", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			local effect = ps.active[1]
			effect.elapsed = effect.lifetime / 2
			local progress = Particles.getProgress(effect)
			assert.is_true(math.abs(progress - 0.5) < 0.01)
		end)

		it("should return 1 at end", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			local effect = ps.active[1]
			effect.elapsed = effect.lifetime
			local progress = Particles.getProgress(effect)
			assert.is_true(math.abs(progress - 1.0) < 0.01)
		end)
	end)

	describe("clear", function()
		it("should remove all active effects", function()
			local ps = Particles.create()
			Particles.spawn(ps, "explosion", 100, 200)
			Particles.spawn(ps, "teleport", 150, 250)
			Particles.clear(ps)
			assert.are.equal(0, #ps.active)
		end)
	end)
end)
