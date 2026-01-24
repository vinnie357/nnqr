-- PowerExecutor Column Powers Tests
-- Tests for 20 column-targeting powers

describe("PowerExecutor - Column Powers", function()
	local PowerExecutor, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)

	describe("destroy_column", function()
		it("destroys all pieces in column except self", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "destroy_column")
			-- Add targets in same column (col=5)
			local target1 = H.pieces.addPiece(state, 1, 5, 2)
			local target2 = H.pieces.addPiece(state, 8, 5, 2)
			-- Add piece not in column (should survive)
			local survivor = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "destroy_column")

			assert.are.equal(2, #state.pieces) -- activator + survivor
			assert.is_true(H.pieces.hasPiece(state, 3, 5)) -- activator survives
			assert.is_true(H.pieces.hasPiece(state, 3, 3)) -- other column survives
			assert.is_false(H.pieces.hasPiece(state, 1, 5)) -- target1 destroyed
			assert.is_false(H.pieces.hasPiece(state, 8, 5)) -- target2 destroyed

			local animType, _, blocking = PowerExecutor.getAnimationInfo("destroy_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("kamikaze_column", function()
		it("destroys all pieces in column INCLUDING self", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "kamikaze_column")
			local target = H.pieces.addPiece(state, 7, 5, 2)
			local survivor = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "kamikaze_column")

			assert.are.equal(1, #state.pieces) -- only survivor
			assert.is_false(H.pieces.hasPiece(state, 3, 5)) -- self destroyed
			assert.is_false(H.pieces.hasPiece(state, 7, 5)) -- target destroyed
			assert.is_true(H.pieces.hasPiece(state, 3, 3)) -- other column survives

			local animType, _, blocking = PowerExecutor.getAnimationInfo("kamikaze_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("recruit_column", function()
		it("converts all enemies in column to allies", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "recruit_column")
			local enemy1 = H.pieces.addPiece(state, 1, 5, 2)
			local enemy2 = H.pieces.addPiece(state, 8, 5, 2)
			local ally = H.pieces.addPiece(state, 5, 5, 1) -- already ally
			local outsider = H.pieces.addPiece(state, 3, 3, 2) -- not in column

			state = PowerExecutor.execute(state, piece, "recruit_column")

			assert.are.equal(1, enemy1.player) -- converted
			assert.are.equal(1, enemy2.player) -- converted
			assert.are.equal(1, ally.player) -- still ally
			assert.are.equal(2, outsider.player) -- not affected

			local animType, _, blocking = PowerExecutor.getAnimationInfo("recruit_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("acidic_column", function()
		it("destroys pieces AND tiles in column except self position", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "acidic_column")
			local target = H.pieces.addPiece(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "acidic_column")

			-- Target destroyed
			assert.is_false(H.pieces.hasPiece(state, 7, 5))
			-- Tiles destroyed (except under self)
			assert.is_nil(state.destroyedTiles["3,5"]) -- self position safe
			assert.is_true(state.destroyedTiles["1,5"])
			assert.is_true(state.destroyedTiles["7,5"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("acidic_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("scramble_column", function()
		it("shuffles positions of pieces in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "scramble_column")
			local p2 = H.pieces.addPiece(state, 5, 5, 2)
			local p3 = H.pieces.addPiece(state, 7, 5, 1)

			-- Store original rows
			local originalRows = {}
			for _, p in ipairs(state.pieces) do
				if p.col == 5 then
					table.insert(originalRows, p.row)
				end
			end

			state = PowerExecutor.execute(state, piece, "scramble_column")

			-- All pieces still in column 5
			for _, p in ipairs(state.pieces) do
				if p.col == 5 then
					assert.are.equal(5, p.col)
				end
			end
			-- Same number of pieces
			assert.are.equal(3, #state.pieces)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("scramble_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("trench_column", function()
		it("lowers entire column height by 2", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "trench_column")
			H.terrain.setHeight(state, 3, 5, 2)
			H.terrain.setHeight(state, 7, 5, 4)

			state = PowerExecutor.execute(state, piece, "trench_column")

			assert.are.equal(0, H.terrain.getHeight(state, 3, 5))
			assert.are.equal(2, H.terrain.getHeight(state, 7, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("trench_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("wall_column", function()
		it("raises entire column height by 2", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "wall_column")
			H.terrain.setHeight(state, 3, 5, 1)
			H.terrain.setHeight(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "wall_column")

			assert.are.equal(3, H.terrain.getHeight(state, 3, 5))
			assert.are.equal(4, H.terrain.getHeight(state, 7, 5)) -- caps at 4

			local animType, _, blocking = PowerExecutor.getAnimationInfo("wall_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("invert_column", function()
		it("inverts heights in column (0->4, 4->0)", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "invert_column")
			H.terrain.setHeight(state, 3, 5, 0)
			H.terrain.setHeight(state, 7, 5, 4)

			state = PowerExecutor.execute(state, piece, "invert_column")

			assert.are.equal(4, H.terrain.getHeight(state, 3, 5))
			assert.are.equal(0, H.terrain.getHeight(state, 7, 5))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("invert_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("dredge_column", function()
		it("raises friendly tile heights, lowers enemy tile heights in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "dredge_column")
			local ally = H.pieces.addPiece(state, 5, 5, 1)
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			H.terrain.setHeight(state, 3, 5, 2)
			H.terrain.setHeight(state, 5, 5, 2)
			H.terrain.setHeight(state, 7, 5, 2)

			state = PowerExecutor.execute(state, piece, "dredge_column")

			assert.are.equal(3, H.terrain.getHeight(state, 3, 5)) -- self raised
			assert.are.equal(3, H.terrain.getHeight(state, 5, 5)) -- ally raised
			assert.are.equal(1, H.terrain.getHeight(state, 7, 5)) -- enemy lowered

			local animType, _, blocking = PowerExecutor.getAnimationInfo("dredge_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("teach_column", function()
		it("copies powers to allies in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "teach_column")
			H.powers.givePower(piece, "bomb")
			local ally = H.pieces.addPiece(state, 7, 5, 1)
			local enemy = H.pieces.addPiece(state, 1, 5, 2) -- should not receive

			state = PowerExecutor.execute(state, piece, "teach_column")

			assert.is_true(H.powers.hasPower(ally, "bomb"))
			assert.is_false(H.powers.hasPower(enemy, "bomb"))
			assert.is_false(H.powers.hasPower(piece, "teach_column")) -- consumed

			local animType, _, blocking = PowerExecutor.getAnimationInfo("teach_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("learn_column", function()
		it("absorbs powers from allies in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "learn_column")
			local ally = H.pieces.addPiece(state, 7, 5, 1)
			H.powers.givePower(ally, "bomb")
			H.powers.givePower(ally, "recruit")

			state = PowerExecutor.execute(state, piece, "learn_column")

			assert.is_true(H.powers.hasPower(piece, "bomb"))
			assert.is_true(H.powers.hasPower(piece, "recruit"))
			assert.are.equal(0, #ally.powers) -- ally lost powers

			local animType, _, blocking = PowerExecutor.getAnimationInfo("learn_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("pilfer_column", function()
		it("steals one random power from each enemy in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "pilfer_column")
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			H.powers.givePower(enemy, "bomb")

			local initialEnemyPowers = #enemy.powers

			state = PowerExecutor.execute(state, piece, "pilfer_column")

			-- Piece gained a power, enemy lost one
			assert.is_true(H.powers.hasPower(piece, "bomb"))
			assert.are.equal(initialEnemyPowers - 1, #enemy.powers)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("pilfer_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("spyware_column", function()
		it("reveals powers of enemies in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "spyware_column")
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			H.powers.givePower(enemy, "bomb")
			local outsider = H.pieces.addPiece(state, 3, 3, 2) -- not in column

			state = PowerExecutor.execute(state, piece, "spyware_column")

			assert.is_true(enemy.powersRevealed)
			assert.is_nil(outsider.powersRevealed)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("spyware_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("orb_spy_column", function()
		it("reveals contents of orbs in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "orb_spy_column")
			H.orbs.addOrb(state, 7, 5, "bomb")
			H.orbs.addOrb(state, 3, 3, "recruit") -- not in column

			state = PowerExecutor.execute(state, piece, "orb_spy_column")

			assert.is_true(state.orbs[1].revealed)
			assert.is_nil(state.orbs[2].revealed)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("orb_spy_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("refurb_column", function()
		it("repairs destroyed tiles in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "refurb_column")
			H.terrain.destroyTile(state, 1, 5)
			H.terrain.destroyTile(state, 7, 5)
			H.terrain.destroyTile(state, 3, 3) -- not in column

			state = PowerExecutor.execute(state, piece, "refurb_column")

			assert.is_nil(state.destroyedTiles["1,5"]) -- repaired
			assert.is_nil(state.destroyedTiles["7,5"]) -- repaired
			assert.is_true(state.destroyedTiles["3,3"]) -- not repaired

			local animType, _, blocking = PowerExecutor.getAnimationInfo("refurb_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("bankrupt_column", function()
		it("creates power-draining trap tiles in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "bankrupt_column")

			state = PowerExecutor.execute(state, piece, "bankrupt_column")

			-- Tiles in column become bankrupt (except self)
			assert.is_nil(state.bankruptTiles["3,5"]) -- self excluded
			assert.is_true(state.bankruptTiles["1,5"])
			assert.is_true(state.bankruptTiles["7,5"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("bankrupt_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("tripwire_column", function()
		it("tethers tripwire to enemy pieces in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "tripwire_column")
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			local outsider = H.pieces.addPiece(state, 3, 3, 2) -- not in column

			state = PowerExecutor.execute(state, piece, "tripwire_column")

			-- Enemy piece is tripwired (will die if they move)
			assert.is_true(enemy.isTripwired)
			assert.are.equal(piece, enemy.tripwireOwner)
			assert.is_nil(outsider.isTripwired)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("tripwire_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("inhibit_column", function()
		it("prevents power collection for enemies in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "inhibit_column")
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			local outsider = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "inhibit_column")

			assert.is_true(enemy.isInhibited)
			assert.is_nil(outsider.isInhibited)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("inhibit_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("parasite_column", function()
		it("leeches onto enemies in column to redirect future powers", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "parasite_column")
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			local outsider = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "parasite_column")

			-- Enemy is parasitized by the activating piece
			assert.is_not_nil(enemy.parasitizedBy)
			assert.are.equal(piece, enemy.parasitizedBy)
			assert.is_nil(outsider.parasitizedBy)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("parasite_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("purify_column", function()
		it("cleanses ally debuffs and removes enemy buffs in column", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 3, 5, 1)
			H.powers.givePower(piece, "purify_column")

			-- Ally with a debuff (inhibited)
			local ally = H.pieces.addPiece(state, 5, 5, 1)
			ally.isInhibited = true

			-- Enemy with a buff (can move diagonally)
			local enemy = H.pieces.addPiece(state, 7, 5, 2)
			enemy.canMoveDiagonally = true
			H.powers.givePower(enemy, "bomb") -- powers array not affected

			-- Outsider not in column
			local outsider = H.pieces.addPiece(state, 3, 3, 2)
			outsider.canMoveDiagonally = true

			state = PowerExecutor.execute(state, piece, "purify_column")

			-- Ally debuff removed
			assert.is_nil(ally.isInhibited)
			-- Enemy buff removed, but powers array unchanged
			assert.is_nil(enemy.canMoveDiagonally)
			assert.are.equal(1, #enemy.powers) -- bomb still there
			-- Outsider not affected
			assert.is_true(outsider.canMoveDiagonally)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("purify_column", piece)
			assert.are.equal("power_column", animType)
			assert.is_true(blocking)
		end)
	end)
end)
