-- Busted tests for power system
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("Powers", function()
	local Powers

	setup(function()
		Powers = require("src.shared.powers")
	end)

	describe("power definitions", function()
		it("has MOVE_DIAGONAL power", function()
			assert.is_table(Powers.definitions.move_diagonal)
			assert.are.equal("Movement", Powers.definitions.move_diagonal.category)
		end)

		it("has MOVE_AGAIN power", function()
			assert.is_table(Powers.definitions.move_again)
		end)

		it("has DESTROY_ROW power", function()
			assert.is_table(Powers.definitions.destroy_row)
			assert.are.equal("Offensive", Powers.definitions.destroy_row.category)
		end)

		it("has DESTROY_COLUMN power", function()
			assert.is_table(Powers.definitions.destroy_column)
		end)

		it("has JUMP_PROOF power", function()
			assert.is_table(Powers.definitions.jump_proof)
			assert.are.equal("Defensive", Powers.definitions.jump_proof.category)
		end)

		it("has RAISE_TILE power", function()
			assert.is_table(Powers.definitions.raise_tile)
			assert.are.equal("Terrain", Powers.definitions.raise_tile.category)
		end)

		it("has LOWER_TILE power", function()
			assert.is_table(Powers.definitions.lower_tile)
		end)

		it("has RECRUIT power", function()
			assert.is_table(Powers.definitions.recruit)
			assert.are.equal("Strategic", Powers.definitions.recruit.category)
		end)

		it("has at least 10 powers defined", function()
			local count = 0
			for _ in pairs(Powers.definitions) do
				count = count + 1
			end
			assert.is_true(count >= 10)
		end)
	end)

	describe("power properties", function()
		it("each power has required fields", function()
			for id, power in pairs(Powers.definitions) do
				assert.is_string(power.name, "Power " .. id .. " missing name")
				assert.is_string(power.category, "Power " .. id .. " missing category")
				assert.is_string(power.duration, "Power " .. id .. " missing duration")
				assert.is_string(power.description, "Power " .. id .. " missing description")
			end
		end)

		it("duration is valid value", function()
			local validDurations = { permanent = true, single_use = true }
			for id, power in pairs(Powers.definitions) do
				assert.is_true(
					validDurations[power.duration],
					"Power " .. id .. " has invalid duration: " .. power.duration
				)
			end
		end)
	end)

	describe("orb spawning", function()
		it("shouldSpawnOrbs returns true every 7 turns", function()
			assert.is_false(Powers.shouldSpawnOrbs(1))
			assert.is_false(Powers.shouldSpawnOrbs(6))
			assert.is_true(Powers.shouldSpawnOrbs(7))
			assert.is_false(Powers.shouldSpawnOrbs(8))
			assert.is_true(Powers.shouldSpawnOrbs(14))
			assert.is_true(Powers.shouldSpawnOrbs(21))
		end)

		it("getEmptyTiles returns tiles without pieces", function()
			local pieces = {
				{ row = 1, col = 1 },
				{ row = 1, col = 2 },
			}
			local orbs = {}
			local empty = Powers.getEmptyTiles(10, 8, pieces, orbs)
			-- 80 total - 2 pieces = 78 empty
			assert.are.equal(78, #empty)
		end)

		it("getEmptyTiles excludes tiles with orbs", function()
			local pieces = {}
			local orbs = {
				{ row = 4, col = 5 },
				{ row = 4, col = 6 },
			}
			local empty = Powers.getEmptyTiles(10, 8, pieces, orbs)
			-- 80 total - 2 orbs = 78 empty
			assert.are.equal(78, #empty)
		end)

		it("spawnOrbs creates orbs on empty tiles", function()
			local pieces = {
				{ row = 1, col = 1 },
			}
			local existingOrbs = {}
			local newOrbs = Powers.spawnOrbs(10, 8, pieces, existingOrbs, 3)
			assert.are.equal(3, #newOrbs)
		end)

		it("spawnOrbs assigns random power types", function()
			local pieces = {}
			local orbs = {}
			local newOrbs = Powers.spawnOrbs(10, 8, pieces, orbs, 5)
			for _, orb in ipairs(newOrbs) do
				assert.is_string(orb.powerId)
				assert.is_table(Powers.definitions[orb.powerId])
			end
		end)

		it("spawnOrbs places orbs at valid positions", function()
			local pieces = {}
			local orbs = {}
			local newOrbs = Powers.spawnOrbs(10, 8, pieces, orbs, 5)
			for _, orb in ipairs(newOrbs) do
				assert.is_true(orb.row >= 1 and orb.row <= 8)
				assert.is_true(orb.col >= 1 and orb.col <= 10)
			end
		end)

		it("getOrbSpawnCount returns 2-4 orbs", function()
			for _ = 1, 20 do
				local count = Powers.getOrbSpawnCount()
				assert.is_true(count >= 2 and count <= 4)
			end
		end)
	end)

	describe("power inventory", function()
		it("addPower adds power to piece", function()
			local piece = { powers = {} }
			Powers.addPower(piece, "move_diagonal")
			assert.are.equal(1, #piece.powers)
			assert.are.equal("move_diagonal", piece.powers[1])
		end)

		it("addPower allows multiple powers", function()
			local piece = { powers = {} }
			Powers.addPower(piece, "move_diagonal")
			Powers.addPower(piece, "jump_proof")
			assert.are.equal(2, #piece.powers)
		end)

		it("hasPower returns true if piece has power", function()
			local piece = { powers = { "move_diagonal", "jump_proof" } }
			assert.is_true(Powers.hasPower(piece, "move_diagonal"))
			assert.is_true(Powers.hasPower(piece, "jump_proof"))
		end)

		it("hasPower returns false if piece lacks power", function()
			local piece = { powers = { "move_diagonal" } }
			assert.is_false(Powers.hasPower(piece, "jump_proof"))
		end)

		it("removePower removes power from piece", function()
			local piece = { powers = { "move_diagonal", "jump_proof" } }
			Powers.removePower(piece, "move_diagonal")
			assert.are.equal(1, #piece.powers)
			assert.is_false(Powers.hasPower(piece, "move_diagonal"))
			assert.is_true(Powers.hasPower(piece, "jump_proof"))
		end)

		it("removePower handles missing power gracefully", function()
			local piece = { powers = { "move_diagonal" } }
			Powers.removePower(piece, "jump_proof") -- Not present
			assert.are.equal(1, #piece.powers)
		end)
	end)

	describe("orb collection", function()
		it("collectOrb adds power to piece and removes orb", function()
			local piece = { row = 4, col = 5, powers = {} }
			local orbs = {
				{ row = 4, col = 5, powerId = "move_diagonal" },
				{ row = 4, col = 6, powerId = "jump_proof" },
			}
			local collected = Powers.collectOrb(piece, orbs)
			assert.is_true(collected)
			assert.are.equal(1, #piece.powers)
			assert.are.equal("move_diagonal", piece.powers[1])
			assert.are.equal(1, #orbs)
		end)

		it("collectOrb returns false if no orb at position", function()
			local piece = { row = 4, col = 5, powers = {} }
			local orbs = {
				{ row = 4, col = 6, powerId = "move_diagonal" },
			}
			local collected = Powers.collectOrb(piece, orbs)
			assert.is_false(collected)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("power effects", function()
		describe("isJumpProof", function()
			it("returns true if piece has jump_proof", function()
				local piece = { powers = { "jump_proof" } }
				assert.is_true(Powers.isJumpProof(piece))
			end)

			it("returns false if piece lacks jump_proof", function()
				local piece = { powers = { "move_diagonal" } }
				assert.is_false(Powers.isJumpProof(piece))
			end)
		end)

		describe("canMoveDiagonally", function()
			it("returns true if piece has move_diagonal", function()
				local piece = { powers = { "move_diagonal" } }
				assert.is_true(Powers.canMoveDiagonally(piece))
			end)

			it("returns false if piece lacks move_diagonal", function()
				local piece = { powers = {} }
				assert.is_false(Powers.canMoveDiagonally(piece))
			end)
		end)
	end)

	describe("overheat mechanic", function()
		describe("countPowerById", function()
			it("returns 0 for piece with no powers", function()
				local piece = { powers = {} }
				assert.are.equal(0, Powers.countPowerById(piece, "move_diagonal"))
			end)

			it("returns 0 for piece with nil powers", function()
				local piece = {}
				assert.are.equal(0, Powers.countPowerById(piece, "move_diagonal"))
			end)

			it("returns 1 for piece with one of that power", function()
				local piece = { powers = { "move_diagonal" } }
				assert.are.equal(1, Powers.countPowerById(piece, "move_diagonal"))
			end)

			it("returns correct count for multiple of same power", function()
				local piece = { powers = { "bomb", "bomb", "bomb" } }
				assert.are.equal(3, Powers.countPowerById(piece, "bomb"))
			end)

			it("counts only the specified power", function()
				local piece = { powers = { "bomb", "move_diagonal", "bomb", "jump_proof", "bomb" } }
				assert.are.equal(3, Powers.countPowerById(piece, "bomb"))
				assert.are.equal(1, Powers.countPowerById(piece, "move_diagonal"))
				assert.are.equal(1, Powers.countPowerById(piece, "jump_proof"))
			end)

			it("returns 0 for power not on piece", function()
				local piece = { powers = { "bomb", "move_diagonal" } }
				assert.are.equal(0, Powers.countPowerById(piece, "jump_proof"))
			end)
		end)

		describe("checkOverheat", function()
			it("returns nil when no powers", function()
				local piece = { powers = {} }
				assert.is_nil(Powers.checkOverheat(piece))
			end)

			it("returns nil when under threshold (9 of same)", function()
				local piece = { powers = {} }
				for _ = 1, 9 do
					table.insert(piece.powers, "bomb")
				end
				assert.is_nil(Powers.checkOverheat(piece))
			end)

			it("returns powerId when at threshold (10 of same)", function()
				local piece = { powers = {} }
				for _ = 1, 10 do
					table.insert(piece.powers, "bomb")
				end
				assert.are.equal("bomb", Powers.checkOverheat(piece))
			end)

			it("returns powerId when over threshold (11+ of same)", function()
				local piece = { powers = {} }
				for _ = 1, 12 do
					table.insert(piece.powers, "move_diagonal")
				end
				assert.are.equal("move_diagonal", Powers.checkOverheat(piece))
			end)

			it("returns first overheated power when multiple at threshold", function()
				local piece = { powers = {} }
				-- Add 10 bombs and 10 move_diagonals
				for _ = 1, 10 do
					table.insert(piece.powers, "bomb")
				end
				for _ = 1, 10 do
					table.insert(piece.powers, "move_diagonal")
				end
				-- Should return one of them (first found)
				local result = Powers.checkOverheat(piece)
				assert.is_true(result == "bomb" or result == "move_diagonal")
			end)

			it("handles nil powers gracefully", function()
				local piece = {}
				assert.is_nil(Powers.checkOverheat(piece))
			end)
		end)
	end)
end)
