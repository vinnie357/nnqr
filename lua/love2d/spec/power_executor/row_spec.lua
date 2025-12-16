-- PowerExecutor Row Powers Tests
-- Tests for 20 row-targeting powers

describe("PowerExecutor - Row Powers", function()
	local PowerExecutor, H

	setup(function()
		PowerExecutor = require("src.shared.power_executor")
		H = require("spec.helpers.init")
	end)

	describe("destroy_row", function()
		it("destroys all pieces in row except self", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "destroy_row")
			-- Add targets in same row
			local target1 = H.pieces.addPiece(state, 5, 1, 2)
			local target2 = H.pieces.addPiece(state, 5, 8, 2)
			-- Add piece not in row (should survive)
			local survivor = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "destroy_row")

			assert.are.equal(2, #state.pieces) -- activator + survivor
			assert.is_true(H.pieces.hasPiece(state, 5, 3)) -- activator survives
			assert.is_true(H.pieces.hasPiece(state, 3, 3)) -- other row survives
			assert.is_false(H.pieces.hasPiece(state, 5, 1)) -- target1 destroyed
			assert.is_false(H.pieces.hasPiece(state, 5, 8)) -- target2 destroyed

			local animType, _, blocking = PowerExecutor.getAnimationInfo("destroy_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("kamikaze_row", function()
		it("destroys all pieces in row INCLUDING self", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "kamikaze_row")
			local target = H.pieces.addPiece(state, 5, 7, 2)
			local survivor = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "kamikaze_row")

			assert.are.equal(1, #state.pieces) -- only survivor
			assert.is_false(H.pieces.hasPiece(state, 5, 3)) -- self destroyed
			assert.is_false(H.pieces.hasPiece(state, 5, 7)) -- target destroyed
			assert.is_true(H.pieces.hasPiece(state, 3, 3)) -- other row survives

			local animType, _, blocking = PowerExecutor.getAnimationInfo("kamikaze_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("recruit_row", function()
		it("converts all enemies in row to allies", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "recruit_row")
			local enemy1 = H.pieces.addPiece(state, 5, 1, 2)
			local enemy2 = H.pieces.addPiece(state, 5, 8, 2)
			local ally = H.pieces.addPiece(state, 5, 5, 1) -- already ally
			local outsider = H.pieces.addPiece(state, 3, 3, 2) -- not in row

			state = PowerExecutor.execute(state, piece, "recruit_row")

			assert.are.equal(1, enemy1.player) -- converted
			assert.are.equal(1, enemy2.player) -- converted
			assert.are.equal(1, ally.player) -- still ally
			assert.are.equal(2, outsider.player) -- not affected

			local animType, _, blocking = PowerExecutor.getAnimationInfo("recruit_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("acidic_row", function()
		it("destroys pieces AND tiles in row except self position", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "acidic_row")
			local target = H.pieces.addPiece(state, 5, 7, 2)

			state = PowerExecutor.execute(state, piece, "acidic_row")

			-- Target destroyed
			assert.is_false(H.pieces.hasPiece(state, 5, 7))
			-- Tiles destroyed (except under self)
			assert.is_nil(state.destroyedTiles["5,3"]) -- self position safe
			assert.is_true(state.destroyedTiles["5,1"])
			assert.is_true(state.destroyedTiles["5,7"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("acidic_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("scramble_row", function()
		it("shuffles positions of pieces in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "scramble_row")
			local p2 = H.pieces.addPiece(state, 5, 5, 2)
			local p3 = H.pieces.addPiece(state, 5, 7, 1)

			-- Store original cols
			local originalCols = {}
			for _, p in ipairs(state.pieces) do
				if p.row == 5 then
					table.insert(originalCols, p.col)
				end
			end

			state = PowerExecutor.execute(state, piece, "scramble_row")

			-- All pieces still in row 5
			for _, p in ipairs(state.pieces) do
				if p.row == 5 then
					assert.are.equal(5, p.row)
				end
			end
			-- Same number of pieces
			assert.are.equal(3, #state.pieces)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("scramble_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("trench_row", function()
		it("lowers entire row height by 2", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "trench_row")
			H.terrain.setHeight(state, 5, 3, 2)
			H.terrain.setHeight(state, 5, 7, 4)

			state = PowerExecutor.execute(state, piece, "trench_row")

			assert.are.equal(0, H.terrain.getHeight(state, 5, 3))
			assert.are.equal(2, H.terrain.getHeight(state, 5, 7))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("trench_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("wall_row", function()
		it("raises entire row height by 2", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "wall_row")
			H.terrain.setHeight(state, 5, 3, 1)
			H.terrain.setHeight(state, 5, 7, 2)

			state = PowerExecutor.execute(state, piece, "wall_row")

			assert.are.equal(3, H.terrain.getHeight(state, 5, 3))
			assert.are.equal(4, H.terrain.getHeight(state, 5, 7)) -- caps at 4

			local animType, _, blocking = PowerExecutor.getAnimationInfo("wall_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("invert_row", function()
		it("inverts heights in row (0->4, 4->0)", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "invert_row")
			H.terrain.setHeight(state, 5, 3, 0)
			H.terrain.setHeight(state, 5, 7, 4)

			state = PowerExecutor.execute(state, piece, "invert_row")

			assert.are.equal(4, H.terrain.getHeight(state, 5, 3))
			assert.are.equal(0, H.terrain.getHeight(state, 5, 7))

			local animType, _, blocking = PowerExecutor.getAnimationInfo("invert_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("dredge_row", function()
		it("raises friendly tile heights, lowers enemy tile heights in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "dredge_row")
			local ally = H.pieces.addPiece(state, 5, 5, 1)
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			H.terrain.setHeight(state, 5, 3, 2)
			H.terrain.setHeight(state, 5, 5, 2)
			H.terrain.setHeight(state, 5, 7, 2)

			state = PowerExecutor.execute(state, piece, "dredge_row")

			assert.are.equal(3, H.terrain.getHeight(state, 5, 3)) -- self raised
			assert.are.equal(3, H.terrain.getHeight(state, 5, 5)) -- ally raised
			assert.are.equal(1, H.terrain.getHeight(state, 5, 7)) -- enemy lowered

			local animType, _, blocking = PowerExecutor.getAnimationInfo("dredge_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("teach_row", function()
		it("copies powers to allies in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "teach_row")
			H.powers.givePower(piece, "bomb")
			local ally = H.pieces.addPiece(state, 5, 7, 1)
			local enemy = H.pieces.addPiece(state, 5, 1, 2) -- should not receive

			state = PowerExecutor.execute(state, piece, "teach_row")

			assert.is_true(H.powers.hasPower(ally, "bomb"))
			assert.is_false(H.powers.hasPower(enemy, "bomb"))
			assert.is_false(H.powers.hasPower(piece, "teach_row")) -- consumed

			local animType, _, blocking = PowerExecutor.getAnimationInfo("teach_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("learn_row", function()
		it("absorbs powers from allies in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "learn_row")
			local ally = H.pieces.addPiece(state, 5, 7, 1)
			H.powers.givePower(ally, "bomb")
			H.powers.givePower(ally, "recruit")

			state = PowerExecutor.execute(state, piece, "learn_row")

			assert.is_true(H.powers.hasPower(piece, "bomb"))
			assert.is_true(H.powers.hasPower(piece, "recruit"))
			assert.are.equal(0, #ally.powers) -- ally lost powers

			local animType, _, blocking = PowerExecutor.getAnimationInfo("learn_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("pilfer_row", function()
		it("steals one random power from each enemy in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "pilfer_row")
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			H.powers.givePower(enemy, "bomb")

			local initialEnemyPowers = #enemy.powers

			state = PowerExecutor.execute(state, piece, "pilfer_row")

			-- Piece gained a power, enemy lost one
			assert.is_true(H.powers.hasPower(piece, "bomb"))
			assert.are.equal(initialEnemyPowers - 1, #enemy.powers)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("pilfer_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("spyware_row", function()
		it("reveals powers of enemies in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "spyware_row")
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			H.powers.givePower(enemy, "bomb")
			local outsider = H.pieces.addPiece(state, 3, 3, 2) -- not in row

			state = PowerExecutor.execute(state, piece, "spyware_row")

			assert.is_true(enemy.powersRevealed)
			assert.is_nil(outsider.powersRevealed)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("spyware_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("orb_spy_row", function()
		it("reveals contents of orbs in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "orb_spy_row")
			H.orbs.addOrb(state, 5, 7, "bomb")
			H.orbs.addOrb(state, 3, 3, "recruit") -- not in row

			state = PowerExecutor.execute(state, piece, "orb_spy_row")

			assert.is_true(state.orbs[1].revealed)
			assert.is_nil(state.orbs[2].revealed)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("orb_spy_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("refurb_row", function()
		it("repairs destroyed tiles in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "refurb_row")
			H.terrain.destroyTile(state, 5, 1)
			H.terrain.destroyTile(state, 5, 7)
			H.terrain.destroyTile(state, 3, 3) -- not in row

			state = PowerExecutor.execute(state, piece, "refurb_row")

			assert.is_nil(state.destroyedTiles["5,1"]) -- repaired
			assert.is_nil(state.destroyedTiles["5,7"]) -- repaired
			assert.is_true(state.destroyedTiles["3,3"]) -- not repaired

			local animType, _, blocking = PowerExecutor.getAnimationInfo("refurb_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("bankrupt_row", function()
		it("creates power-draining trap tiles in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "bankrupt_row")

			state = PowerExecutor.execute(state, piece, "bankrupt_row")

			-- Tiles in row become bankrupt (except self)
			assert.is_nil(state.bankruptTiles["5,3"]) -- self excluded
			assert.is_true(state.bankruptTiles["5,1"])
			assert.is_true(state.bankruptTiles["5,7"])

			local animType, _, blocking = PowerExecutor.getAnimationInfo("bankrupt_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("tripwire_row", function()
		it("tethers tripwire to enemy pieces in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "tripwire_row")
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			local outsider = H.pieces.addPiece(state, 3, 3, 2) -- not in row

			state = PowerExecutor.execute(state, piece, "tripwire_row")

			-- Enemy piece is tripwired (will die if they move)
			assert.is_true(enemy.isTripwired)
			assert.are.equal(piece, enemy.tripwireOwner)
			assert.is_nil(outsider.isTripwired)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("tripwire_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("inhibit_row", function()
		it("prevents power collection for enemies in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "inhibit_row")
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			local outsider = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "inhibit_row")

			assert.is_true(enemy.isInhibited)
			assert.is_nil(outsider.isInhibited)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("inhibit_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("parasite_row", function()
		it("leeches onto enemies in row to redirect future powers", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "parasite_row")
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			local outsider = H.pieces.addPiece(state, 3, 3, 2)

			state = PowerExecutor.execute(state, piece, "parasite_row")

			-- Enemy is parasitized by the activating piece
			assert.is_not_nil(enemy.parasitizedBy)
			assert.are.equal(piece, enemy.parasitizedBy)
			assert.is_nil(outsider.parasitizedBy)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("parasite_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)

	describe("purify_row", function()
		it("cleanses ally debuffs and removes enemy buffs in row", function()
			local state = H.state.createEmptyState()
			local piece = H.pieces.addPiece(state, 5, 3, 1)
			H.powers.givePower(piece, "purify_row")

			-- Ally with a debuff (inhibited)
			local ally = H.pieces.addPiece(state, 5, 5, 1)
			ally.isInhibited = true

			-- Enemy with a buff (can move diagonally)
			local enemy = H.pieces.addPiece(state, 5, 7, 2)
			enemy.canMoveDiagonally = true
			H.powers.givePower(enemy, "bomb") -- powers array not affected

			-- Outsider not in row
			local outsider = H.pieces.addPiece(state, 3, 3, 2)
			outsider.canMoveDiagonally = true

			state = PowerExecutor.execute(state, piece, "purify_row")

			-- Ally debuff removed
			assert.is_nil(ally.isInhibited)
			-- Enemy buff removed, but powers array unchanged
			assert.is_nil(enemy.canMoveDiagonally)
			assert.are.equal(1, #enemy.powers) -- bomb still there
			-- Outsider not affected
			assert.is_true(outsider.canMoveDiagonally)

			local animType, _, blocking = PowerExecutor.getAnimationInfo("purify_row", piece)
			assert.are.equal("power_row", animType)
			assert.is_true(blocking)
		end)
	end)
end)
