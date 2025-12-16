-- Tests for PowerExecutor radial/area_3x3 power dispatch
-- Phase 9B-E: Radial Powers (21 powers)

describe("PowerExecutor - Radial Powers", function()
	local PowerExecutor, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)
	-- Combat powers
	describe("bomb", function()
		it("destroys enemy pieces in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "bomb")
			local enemy1 = H.pieces.addPiece(state, 2, 5, 2) -- adjacent
			local enemy2 = H.pieces.addPiece(state, 4, 6, 2) -- adjacent
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2) -- not adjacent

			state = PowerExecutor.execute(state, piece, "bomb")

			-- Adjacent enemies destroyed
			local foundEnemy1 = false
			local foundEnemy2 = false
			local foundFar = false
			for _, p in ipairs(state.pieces) do
				if p == enemy1 then
					foundEnemy1 = true
				end
				if p == enemy2 then
					foundEnemy2 = true
				end
				if p == farEnemy then
					foundFar = true
				end
			end
			assert.is_false(foundEnemy1)
			assert.is_false(foundEnemy2)
			assert.is_true(foundFar)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("bomb", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("destroy_radial", function()
		it("destroys enemies in 3x3 area including self", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "destroy_radial")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "destroy_radial")

			-- Enemy destroyed, far enemy survives
			local foundEnemy = false
			local foundFar = false
			for _, p in ipairs(state.pieces) do
				if p == enemy then
					foundEnemy = true
				end
				if p == farEnemy then
					foundFar = true
				end
			end
			assert.is_false(foundEnemy)
			assert.is_true(foundFar)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("destroy_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("kamikaze_radial", function()
		it("destroys all pieces in 3x3 area including self", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "kamikaze_radial")
			local ally = H.pieces.addPiece(state, 2, 5, 1)
			local enemy = H.pieces.addPiece(state, 4, 5, 2)

			state = PowerExecutor.execute(state, piece, "kamikaze_radial")

			-- All pieces in area destroyed (including self)
			local foundPiece = false
			local foundAlly = false
			local foundEnemy = false
			for _, p in ipairs(state.pieces) do
				if p == piece then
					foundPiece = true
				end
				if p == ally then
					foundAlly = true
				end
				if p == enemy then
					foundEnemy = true
				end
			end
			assert.is_false(foundPiece)
			assert.is_false(foundAlly)
			assert.is_false(foundEnemy)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("kamikaze_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("smart_bombs", function()
		it("destroys only enemy pieces in 3x3 area (allies safe)", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "smart_bombs")
			local ally = H.pieces.addPiece(state, 2, 5, 1)
			local enemy = H.pieces.addPiece(state, 4, 5, 2)

			state = PowerExecutor.execute(state, piece, "smart_bombs")

			-- Ally survives, enemy destroyed
			local foundPiece = false
			local foundAlly = false
			local foundEnemy = false
			for _, p in ipairs(state.pieces) do
				if p == piece then
					foundPiece = true
				end
				if p == ally then
					foundAlly = true
				end
				if p == enemy then
					foundEnemy = true
				end
			end
			assert.is_true(foundPiece) -- self survives
			assert.is_true(foundAlly) -- ally survives
			assert.is_false(foundEnemy) -- enemy destroyed

			local animType, _, blocking = PowerExecutor.getAnimationInfo("smart_bombs", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("scramble_radial", function()
		it("randomizes positions of pieces in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "scramble_radial")
			H.pieces.addPiece(state, 2, 4, 2)
			H.pieces.addPiece(state, 4, 6, 2)

			-- Just verify it runs without error and power is removed
			state = PowerExecutor.execute(state, piece, "scramble_radial")

			assert.are.equal(3, #state.pieces)
			assert.is_false(H.powers.hasPower(piece, "scramble_radial"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("scramble_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	-- Terrain powers
	describe("acidic_radial", function()
		it("destroys tiles in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "acidic_radial")

			state = PowerExecutor.execute(state, piece, "acidic_radial")

			-- Adjacent tiles destroyed
			assert.is_true(state.destroyedTiles["2,4"])
			assert.is_true(state.destroyedTiles["2,5"])
			assert.is_true(state.destroyedTiles["4,6"])
			-- Far tile not destroyed
			assert.is_nil(state.destroyedTiles["7,5"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("acidic_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("plateau", function()
		it("raises tiles in 3x3 area to max height", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "plateau")

			state = PowerExecutor.execute(state, piece, "plateau")

			-- Adjacent tiles raised to max (4)
			assert.are.equal(4, H.terrain.getHeight(state, 2, 4))
			assert.are.equal(4, H.terrain.getHeight(state, 3, 5))
			assert.are.equal(4, H.terrain.getHeight(state, 4, 6))
			-- Far tile unchanged (default 0)
			assert.are.equal(0, H.terrain.getHeight(state, 7, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("plateau", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("moat", function()
		it("raises center and lowers surrounding ring", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "moat")
			-- Start with height 2 for surrounding
			H.terrain.setHeight(state, 2, 4, 2)
			H.terrain.setHeight(state, 2, 5, 2)
			H.terrain.setHeight(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "moat")

			-- Center raised to max
			assert.are.equal(4, H.terrain.getHeight(state, 3, 5))
			-- Surrounding ring lowered by 1
			assert.are.equal(1, H.terrain.getHeight(state, 2, 4))
			assert.are.equal(1, H.terrain.getHeight(state, 2, 5))
			-- Far tile unchanged
			assert.are.equal(2, H.terrain.getHeight(state, 7, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("moat", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("invert_radial", function()
		it("inverts tile heights in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "invert_radial")
			-- Set initial heights: 2 and 3
			H.terrain.setHeight(state, 2, 4, 2)
			H.terrain.setHeight(state, 3, 5, 3)

			state = PowerExecutor.execute(state, piece, "invert_radial")

			-- Heights inverted around midpoint (2): 2->2, 3->1, etc.
			-- Actually invert works relative to max/min: h -> (MAX - h)
			-- So 2 -> 2, 3 -> 1
			assert.are.equal(2, H.terrain.getHeight(state, 2, 4))
			assert.are.equal(1, H.terrain.getHeight(state, 3, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("invert_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("dredge_radial", function()
		it("raises ally tiles and lowers enemy tiles in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "dredge_radial")
			-- Add ally and enemy in range
			local ally = H.pieces.addPiece(state, 2, 5, 1)
			local enemy = H.pieces.addPiece(state, 4, 5, 2)
			-- Set initial heights
			H.terrain.setHeight(state, 3, 5, 1) -- activator
			H.terrain.setHeight(state, 2, 5, 1) -- ally
			H.terrain.setHeight(state, 4, 5, 2) -- enemy

			state = PowerExecutor.execute(state, piece, "dredge_radial")

			-- Activator tile raised (ally)
			assert.are.equal(2, H.terrain.getHeight(state, 3, 5))
			-- Ally tile raised
			assert.are.equal(2, H.terrain.getHeight(state, 2, 5))
			-- Enemy tile lowered
			assert.are.equal(1, H.terrain.getHeight(state, 4, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("dredge_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("refurb_radial", function()
		it("repairs destroyed tiles in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "refurb_radial")
			H.terrain.destroyTile(state, 2, 4)
			H.terrain.destroyTile(state, 3, 5)
			H.terrain.destroyTile(state, 7, 5) -- far tile

			state = PowerExecutor.execute(state, piece, "refurb_radial")

			-- Adjacent tiles repaired
			assert.is_nil(state.destroyedTiles["2,4"])
			assert.is_nil(state.destroyedTiles["3,5"])
			-- Far tile still destroyed
			assert.is_true(state.destroyedTiles["7,5"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("refurb_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("bankrupt_radial", function()
		it("creates power-draining trap tiles in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "bankrupt_radial")

			state = PowerExecutor.execute(state, piece, "bankrupt_radial")

			-- Adjacent tiles become bankrupt traps (except self)
			assert.is_nil(state.bankruptTiles["3,5"]) -- self excluded
			assert.is_true(state.bankruptTiles["2,4"])
			assert.is_true(state.bankruptTiles["4,6"])
			-- Far tile not affected
			assert.is_nil(state.bankruptTiles["7,5"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("bankrupt_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	-- Power transfer
	describe("teach_radial", function()
		it("copies one power to adjacent allies", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "teach_radial")
			H.powers.givePower(piece, "bomb") -- power to teach
			local ally = H.pieces.addPiece(state, 2, 5, 1)
			local enemy = H.pieces.addPiece(state, 4, 5, 2)

			state = PowerExecutor.execute(state, piece, "teach_radial")

			-- Ally receives copy of bomb
			assert.is_true(H.powers.hasPower(ally, "bomb"))
			-- Enemy doesn't receive
			assert.is_false(H.powers.hasPower(enemy, "bomb"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("teach_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("learn_radial", function()
		it("copies one power from each adjacent ally", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "learn_radial")
			local ally = H.pieces.addPiece(state, 2, 5, 1)
			H.powers.givePower(ally, "bomb")

			state = PowerExecutor.execute(state, piece, "learn_radial")

			-- Piece learns bomb from ally
			assert.is_true(H.powers.hasPower(piece, "bomb"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("learn_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("pilfer_radial", function()
		it("steals one power from each adjacent enemy", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "pilfer_radial")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			H.powers.givePower(enemy, "bomb")

			state = PowerExecutor.execute(state, piece, "pilfer_radial")

			-- Piece steals bomb from enemy
			assert.is_true(H.powers.hasPower(piece, "bomb"))
			assert.is_false(H.powers.hasPower(enemy, "bomb"))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("pilfer_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	-- Intelligence
	describe("spyware_radial", function()
		it("reveals powers of adjacent enemies", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "spyware_radial")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			H.powers.givePower(enemy, "bomb")
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "spyware_radial")

			assert.is_true(enemy.powersRevealed)
			assert.is_nil(farEnemy.powersRevealed)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("spyware_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_false(blocking) -- Intelligence powers are non-blocking
		end)
	end)

	describe("orb_spy_radial", function()
		it("reveals contents of adjacent orbs", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "orb_spy_radial")
			H.orbs.addOrb(state, 2, 5, "bomb")
			H.orbs.addOrb(state, 7, 5, "recruit") -- far orb

			state = PowerExecutor.execute(state, piece, "orb_spy_radial")

			assert.is_true(state.orbs[1].revealed)
			assert.is_nil(state.orbs[2].revealed)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("orb_spy_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_false(blocking) -- Intelligence powers are non-blocking
		end)
	end)

	-- Control
	describe("tripwire_radial", function()
		it("tethers tripwire to adjacent enemies", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "tripwire_radial")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "tripwire_radial")

			assert.is_true(enemy.isTripwired)
			assert.are.equal(piece, enemy.tripwireOwner)
			assert.is_nil(farEnemy.isTripwired)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("tripwire_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("inhibit_radial", function()
		it("prevents power collection for adjacent enemies", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "inhibit_radial")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "inhibit_radial")

			assert.is_true(enemy.isInhibited)
			assert.is_nil(farEnemy.isInhibited)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("inhibit_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_false(blocking) -- Control powers are non-blocking
		end)
	end)

	describe("parasite_radial", function()
		it("leeches onto adjacent enemies to redirect future powers", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "parasite_radial")
			local enemy = H.pieces.addPiece(state, 2, 5, 2)
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "parasite_radial")

			assert.is_not_nil(enemy.parasitizedBy)
			assert.are.equal(piece, enemy.parasitizedBy)
			assert.is_nil(farEnemy.parasitizedBy)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("parasite_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_false(blocking) -- Control powers are non-blocking
		end)
	end)

	describe("purify_radial", function()
		it("cleanses ally debuffs and removes enemy buffs in 3x3 area", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "purify_radial")

			-- Ally with debuff
			local ally = H.pieces.addPiece(state, 2, 5, 1)
			ally.isInhibited = true

			-- Enemy with buff
			local enemy = H.pieces.addPiece(state, 4, 5, 2)
			enemy.canMoveDiagonally = true
			H.powers.givePower(enemy, "bomb")

			-- Far outsider
			local farEnemy = H.pieces.addPiece(state, 7, 5, 2)
			farEnemy.canMoveDiagonally = true

			state = PowerExecutor.execute(state, piece, "purify_radial")

			-- Ally debuff removed
			assert.is_nil(ally.isInhibited)
			-- Enemy buff removed, but powers array unchanged
			assert.is_nil(enemy.canMoveDiagonally)
			assert.are.equal(1, #enemy.powers)
			-- Far enemy unaffected
			assert.is_true(farEnemy.canMoveDiagonally)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("purify_radial", piece)
			assert.are.equal("power_radial", animType)
			assert.is_false(blocking) -- Restoration purify is non-blocking
		end)
	end)
end)
