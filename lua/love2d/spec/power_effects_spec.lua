-- Busted tests for power effects
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("PowerEffects", function()
	local PowerEffects
	local GameLogic

	setup(function()
		PowerEffects = require("src.shared.power_effects")
		GameLogic = require("src.shared.game_logic")
	end)

	describe("move_diagonal", function()
		it("enables diagonal movement for piece with flag", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			-- Flag is set after activation, not by having power in inventory
			piece.canMoveDiagonally = true

			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			-- Should include diagonal moves
			local hasDiagonal = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 6 then
					hasDiagonal = true
				end
			end
			assert.is_true(hasDiagonal)
		end)

		it("still allows orthogonal movement", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.canMoveDiagonally = true

			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			local hasOrthogonal = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 5 then
					hasOrthogonal = true
				end
			end
			assert.is_true(hasOrthogonal)
		end)

		it("respects height restrictions for diagonal", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.canMoveDiagonally = true
			-- Set diagonal tile too high
			state.heightMap[3][6] = 3

			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			local hasBadDiagonal = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 6 then
					hasBadDiagonal = true
				end
			end
			assert.is_false(hasBadDiagonal)
		end)
	end)

	describe("jump_proof", function()
		it("prevents capture by normal movement when flag is set", function()
			local state = GameLogic.createInitialState()
			-- Get P2 piece and give it jump_proof flag (set after activation)
			local defender = GameLogic.getPieceAt(state, 7, 5)
			defender.isJumpProof = true

			-- Move P1 piece adjacent
			local attacker = GameLogic.getPieceAt(state, 2, 5)
			attacker.row = 6

			-- Check if capture move is valid
			local canCapture = PowerEffects.canCapture(state, attacker, defender)
			assert.is_false(canCapture)
		end)

		it("allows capture by destroy powers", function()
			local defender = { isJumpProof = true }
			local canDestroy = PowerEffects.canDestroyWithPower(defender, "destroy_row")
			assert.is_true(canDestroy)
		end)

		it("does not affect non-jump-proof pieces", function()
			local state = GameLogic.createInitialState()
			local defender = GameLogic.getPieceAt(state, 7, 5)
			defender.isJumpProof = false

			local attacker = GameLogic.getPieceAt(state, 2, 5)
			attacker.row = 6

			local canCapture = PowerEffects.canCapture(state, attacker, defender)
			assert.is_true(canCapture)
		end)
	end)

	describe("destroy_row", function()
		it("returns all pieces in row except activator", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			local targets = PowerEffects.getDestroyRowTargets(state, piece)
			-- Row 1 has 10 P1 pieces, minus self = 9
			assert.are.equal(9, #targets)
		end)

		it("includes enemy pieces", function()
			local state = GameLogic.createInitialState()
			-- Move a piece to row 4
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			-- Move enemy to same row
			local enemy = GameLogic.getPieceAt(state, 7, 3)
			enemy.row = 4

			local targets = PowerEffects.getDestroyRowTargets(state, piece)
			local hasEnemy = false
			for _, t in ipairs(targets) do
				if t.player == 2 then
					hasEnemy = true
				end
			end
			assert.is_true(hasEnemy)
		end)

		it("excludes the activating piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			local targets = PowerEffects.getDestroyRowTargets(state, piece)
			local hasSelf = false
			for _, t in ipairs(targets) do
				if t == piece then
					hasSelf = true
				end
			end
			assert.is_false(hasSelf)
		end)

		it("applies destruction correctly", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)
			piece.powers = { "destroy_row" }

			local initialCount = #state.pieces
			state = PowerEffects.activateDestroyRow(state, piece)

			-- Should remove 9 pieces (10 in row minus the activator)
			assert.are.equal(initialCount - 9, #state.pieces)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)
			piece.powers = { "destroy_row" }

			state = PowerEffects.activateDestroyRow(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("destroy_column", function()
		it("returns all pieces in column except activator", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			local targets = PowerEffects.getDestroyColumnTargets(state, piece)
			-- Column 5 has 4 pieces (2 P1 at rows 1,2 and 2 P2 at rows 7,8), minus self = 3
			assert.are.equal(3, #targets)
		end)

		it("excludes the activating piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			local targets = PowerEffects.getDestroyColumnTargets(state, piece)
			local hasSelf = false
			for _, t in ipairs(targets) do
				if t == piece then
					hasSelf = true
				end
			end
			assert.is_false(hasSelf)
		end)

		it("applies destruction correctly", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)
			piece.powers = { "destroy_column" }

			local initialCount = #state.pieces
			state = PowerEffects.activateDestroyColumn(state, piece)

			-- Should remove 3 pieces (4 in column minus the activator)
			assert.are.equal(initialCount - 3, #state.pieces)
		end)
	end)

	describe("raise_tile", function()
		it("returns adjacent tiles as valid targets", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 4, col = 5 }

			local targets = PowerEffects.getRaiseTileTargets(state, piece)
			assert.are.equal(4, #targets) -- 4 orthogonal neighbors
		end)

		it("excludes out-of-bounds tiles", function()
			local state = GameLogic.createInitialState()
			local piece = { row = 1, col = 1 }

			local targets = PowerEffects.getRaiseTileTargets(state, piece)
			assert.are.equal(2, #targets) -- Only down and right
		end)

		it("raises target tile by 1", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "raise_tile" }

			local target = { row = 3, col = 5 }
			local initialHeight = state.heightMap[3][5]

			state = PowerEffects.activateRaiseTile(state, piece, target)
			assert.are.equal(initialHeight + 1, state.heightMap[3][5])
		end)

		it("caps at max height", function()
			local state = GameLogic.createInitialState()
			state.heightMap[3][5] = 4 -- Already max
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "raise_tile" }

			local target = { row = 3, col = 5 }
			state = PowerEffects.activateRaiseTile(state, piece, target)
			assert.are.equal(4, state.heightMap[3][5])
		end)
	end)

	describe("lower_tile", function()
		it("lowers target tile by 1", function()
			local state = GameLogic.createInitialState()
			state.heightMap[3][5] = 2
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "lower_tile" }

			local target = { row = 3, col = 5 }
			state = PowerEffects.activateLowerTile(state, piece, target)
			assert.are.equal(1, state.heightMap[3][5])
		end)

		it("caps at min height", function()
			local state = GameLogic.createInitialState()
			state.heightMap[3][5] = 0
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "lower_tile" }

			local target = { row = 3, col = 5 }
			state = PowerEffects.activateLowerTile(state, piece, target)
			assert.are.equal(0, state.heightMap[3][5])
		end)
	end)

	describe("recruit", function()
		it("returns adjacent enemy pieces as targets", function()
			local state = GameLogic.createInitialState()
			-- Move P1 piece next to P2
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 6

			local targets = PowerEffects.getRecruitTargets(state, piece)
			-- Should find P2 piece at row 7
			assert.are.equal(1, #targets)
			assert.are.equal(2, targets[1].player)
		end)

		it("excludes own pieces", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			local targets = PowerEffects.getRecruitTargets(state, piece)
			-- Adjacent piece at row 2 is own piece
			for _, t in ipairs(targets) do
				assert.are_not.equal(1, t.player)
			end
		end)

		it("converts enemy piece to own team", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 6
			piece.powers = { "recruit" }

			local enemy = GameLogic.getPieceAt(state, 7, 5)
			assert.are.equal(2, enemy.player)

			state = PowerEffects.activateRecruit(state, piece, enemy)
			assert.are.equal(1, enemy.player)
		end)
	end)

	describe("multiply", function()
		it("returns adjacent empty tiles as targets", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)

			local targets = PowerEffects.getMultiplyTargets(state, piece)
			-- Row 3 is empty, row 1 has pieces
			local hasRow3 = false
			for _, t in ipairs(targets) do
				if t.row == 3 then
					hasRow3 = true
				end
			end
			assert.is_true(hasRow3)
		end)

		it("creates a copy of the piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "multiply" }

			local initialCount = #state.pieces
			local target = { row = 3, col = 5 }

			state = PowerEffects.activateMultiply(state, piece, target)
			assert.are.equal(initialCount + 1, #state.pieces)
		end)

		it("new piece has same player", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "multiply" }

			local target = { row = 3, col = 5 }
			state = PowerEffects.activateMultiply(state, piece, target)

			local newPiece = GameLogic.getPieceAt(state, 3, 5)
			assert.are.equal(piece.player, newPiece.player)
		end)

		it("new piece has no powers", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "multiply", "jump_proof" }

			local target = { row = 3, col = 5 }
			state = PowerEffects.activateMultiply(state, piece, target)

			local newPiece = GameLogic.getPieceAt(state, 3, 5)
			assert.are.equal(0, #newPiece.powers)
		end)
	end)

	describe("bomb", function()
		it("returns pieces in 3x3 area", function()
			local state = GameLogic.createInitialState()
			-- Move piece to center area
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5

			-- Add some nearby pieces
			local nearby = GameLogic.getPieceAt(state, 2, 4)
			nearby.row = 4
			nearby.col = 4

			local targets = PowerEffects.getBombTargets(state, piece)
			assert.is_true(#targets >= 1)
		end)

		it("excludes the activating piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)

			local targets = PowerEffects.getBombTargets(state, piece)
			local hasSelf = false
			for _, t in ipairs(targets) do
				if t == piece then
					hasSelf = true
				end
			end
			assert.is_false(hasSelf)
		end)

		it("lowers terrain in 3x3 area", function()
			local state = GameLogic.createInitialState()
			-- Set some heights
			for r = 3, 5 do
				for c = 4, 6 do
					state.heightMap[r][c] = 2
				end
			end

			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "bomb" }

			state = PowerEffects.activateBomb(state, piece)

			-- Check heights were lowered
			assert.are.equal(1, state.heightMap[4][5])
			assert.are.equal(1, state.heightMap[3][4])
		end)

		it("destroys tiles at minimum height (0)", function()
			local state = GameLogic.createInitialState()
			-- All tiles start at height 0

			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "bomb" }

			state = PowerEffects.activateBomb(state, piece)

			-- Center tile at height 0 should be destroyed after lowering
			assert.is_true(GameLogic.isTileDestroyed(state, 4, 5))
		end)

		it("destroys adjacent tiles at height 0 in blast radius", function()
			local state = GameLogic.createInitialState()
			-- All tiles at height 0

			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "bomb" }

			state = PowerEffects.activateBomb(state, piece)

			-- Adjacent tiles should also be destroyed
			assert.is_true(GameLogic.isTileDestroyed(state, 3, 5))
			assert.is_true(GameLogic.isTileDestroyed(state, 5, 5))
			assert.is_true(GameLogic.isTileDestroyed(state, 4, 4))
			assert.is_true(GameLogic.isTileDestroyed(state, 4, 6))
		end)

		it("only destroys tiles that reach min height after lowering", function()
			local state = GameLogic.createInitialState()
			-- Set center to height 2, edges to height 1
			state.heightMap[4][5] = 2
			for dr = -1, 1 do
				for dc = -1, 1 do
					if dr ~= 0 or dc ~= 0 then
						state.heightMap[4 + dr][5 + dc] = 1
					end
				end
			end

			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "bomb" }

			state = PowerEffects.activateBomb(state, piece)

			-- Center was height 2, now height 1 - NOT destroyed
			assert.is_false(GameLogic.isTileDestroyed(state, 4, 5))
			-- Edges were height 1, now height 0 - destroyed
			assert.is_true(GameLogic.isTileDestroyed(state, 3, 5))
		end)
	end)

	describe("relocate", function()
		it("moves piece to random empty tile", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "relocate" }

			local oldRow, oldCol = piece.row, piece.col
			state = PowerEffects.activateRelocate(state, piece)

			-- Piece should have moved
			assert.is_true(piece.row ~= oldRow or piece.col ~= oldCol)
		end)

		it("moves to valid board position", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "relocate" }

			state = PowerEffects.activateRelocate(state, piece)

			assert.is_true(piece.row >= 1 and piece.row <= 8)
			assert.is_true(piece.col >= 1 and piece.col <= 10)
		end)

		it("does not land on another piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "relocate" }

			state = PowerEffects.activateRelocate(state, piece)

			-- Check no other piece at same location
			local count = 0
			for _, p in ipairs(state.pieces) do
				if p.row == piece.row and p.col == piece.col then
					count = count + 1
				end
			end
			assert.are.equal(1, count)
		end)
	end)

	describe("move_again", function()
		it("grants extra move flag", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "move_again" }

			state = PowerEffects.activateMoveAgain(state, piece)
			assert.is_true(state.extraMove)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "move_again" }

			state = PowerEffects.activateMoveAgain(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("activateMoveDiagonal", function()
		it("sets piece canMoveDiagonally flag", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "move_diagonal" }

			state = PowerEffects.activateMoveDiagonal(state, piece)
			assert.is_true(piece.canMoveDiagonally)
		end)

		it("removes power from inventory after activation", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "move_diagonal" }

			state = PowerEffects.activateMoveDiagonal(state, piece)
			assert.are.equal(0, #piece.powers)
		end)

		it("flag persists permanently on piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "move_diagonal" }

			state = PowerEffects.activateMoveDiagonal(state, piece)
			assert.is_true(piece.canMoveDiagonally)
			-- Power consumed but effect remains
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("activateJumpProof", function()
		it("sets piece isJumpProof flag", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "jump_proof" }

			state = PowerEffects.activateJumpProof(state, piece)
			assert.is_true(piece.isJumpProof)
		end)

		it("removes power from inventory after activation", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "jump_proof" }

			state = PowerEffects.activateJumpProof(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("activateInvisible", function()
		it("sets piece isInvisible flag", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "invisible" }

			state = PowerEffects.activateInvisible(state, piece)
			assert.is_true(piece.isInvisible)
		end)

		it("removes power from inventory after activation", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.powers = { "invisible" }

			state = PowerEffects.activateInvisible(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("revealInvisible", function()
		it("clears isInvisible flag when piece captures", function()
			local piece = { isInvisible = true }
			PowerEffects.revealInvisible(piece)
			assert.is_false(piece.isInvisible)
		end)

		it("does nothing if piece is not invisible", function()
			local piece = { isInvisible = false }
			PowerEffects.revealInvisible(piece)
			assert.is_false(piece.isInvisible)
		end)
	end)

	describe("refurb", function()
		it("getRefurbTargets returns adjacent destroyed tiles", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5

			-- Destroy adjacent tile
			state = GameLogic.destroyTile(state, 4, 6)

			local targets = PowerEffects.getRefurbTargets(state, piece)
			assert.are.equal(1, #targets)
			assert.are.equal(4, targets[1].row)
			assert.are.equal(6, targets[1].col)
		end)

		it("getRefurbTargets returns empty if no adjacent destroyed tiles", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5

			local targets = PowerEffects.getRefurbTargets(state, piece)
			assert.are.equal(0, #targets)
		end)

		it("activateRefurb repairs target tile", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "refurb" }

			-- Destroy adjacent tile
			state = GameLogic.destroyTile(state, 4, 6)
			assert.is_true(GameLogic.isTileDestroyed(state, 4, 6))

			-- Repair it
			state = PowerEffects.activateRefurb(state, piece, { row = 4, col = 6 })
			assert.is_false(GameLogic.isTileDestroyed(state, 4, 6))
		end)

		it("repaired tile has height 0", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "refurb" }

			-- Destroy adjacent tile (which may have lowered height)
			state = GameLogic.destroyTile(state, 4, 6)

			-- Repair it
			state = PowerEffects.activateRefurb(state, piece, { row = 4, col = 6 })
			assert.are.equal(0, state.heightMap[4][6])
		end)

		it("removes power from inventory after activation", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5
			piece.powers = { "refurb" }

			state = GameLogic.destroyTile(state, 4, 6)
			state = PowerEffects.activateRefurb(state, piece, { row = 4, col = 6 })
			assert.are.equal(0, #piece.powers)
		end)
	end)

	-- Phase 9A.1: Destroy Variants
	describe("destroy_radial", function()
		it("returns pieces in 3x3 area excluding activator", function()
			local state = GameLogic.createInitialState()
			-- Move piece to center and add neighbors
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5

			-- Add some nearby pieces
			local neighbor1 = GameLogic.getPieceAt(state, 2, 4)
			neighbor1.row = 4
			neighbor1.col = 4

			local neighbor2 = GameLogic.getPieceAt(state, 2, 6)
			neighbor2.row = 3
			neighbor2.col = 5

			local targets = PowerEffects.getDestroyRadialTargets(state, piece)
			assert.is_true(#targets >= 2)
		end)

		it("excludes the activating piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 4
			piece.col = 5

			local targets = PowerEffects.getDestroyRadialTargets(state, piece)
			for _, t in ipairs(targets) do
				assert.are_not.equal(piece, t)
			end
		end)

		it("includes pieces in all 8 directions", function()
			local state = GameLogic.createInitialState()
			-- Create isolated test state
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {} }, -- Activator
				{ row = 3, col = 5, player = 2, powers = {} }, -- North
				{ row = 5, col = 5, player = 2, powers = {} }, -- South
				{ row = 4, col = 4, player = 2, powers = {} }, -- West
				{ row = 4, col = 6, player = 2, powers = {} }, -- East
				{ row = 3, col = 4, player = 2, powers = {} }, -- NW
				{ row = 3, col = 6, player = 2, powers = {} }, -- NE
				{ row = 5, col = 4, player = 2, powers = {} }, -- SW
				{ row = 5, col = 6, player = 2, powers = {} }, -- SE
			}
			local piece = state.pieces[1]

			local targets = PowerEffects.getDestroyRadialTargets(state, piece)
			assert.are.equal(8, #targets)
		end)

		it("destroys all pieces in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "destroy_radial" } },
				{ row = 3, col = 5, player = 2, powers = {} },
				{ row = 4, col = 4, player = 2, powers = {} },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDestroyRadial(state, piece)
			-- Only activator should remain
			assert.are.equal(1, #state.pieces)
			assert.are.equal(piece, state.pieces[1])
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "destroy_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDestroyRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)

		it("does NOT lower terrain (unlike bomb)", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][5] = 2
			state.heightMap[3][5] = 2
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "destroy_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDestroyRadial(state, piece)
			-- Heights should be unchanged
			assert.are.equal(2, state.heightMap[4][5])
			assert.are.equal(2, state.heightMap[3][5])
		end)
	end)

	describe("kamikaze_radial", function()
		it("destroys all pieces in 3x3 area INCLUDING self", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "kamikaze_radial" } },
				{ row = 3, col = 5, player = 2, powers = {} },
				{ row = 4, col = 4, player = 2, powers = {} },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateKamikazeRadial(state, piece)
			-- ALL pieces destroyed including activator
			assert.are.equal(0, #state.pieces)
		end)

		it("includes enemies and allies", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "kamikaze_radial" } },
				{ row = 3, col = 5, player = 1, powers = {} }, -- Ally
				{ row = 4, col = 4, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateKamikazeRadial(state, piece)
			assert.are.equal(0, #state.pieces)
		end)
	end)

	describe("kamikaze_row", function()
		it("destroys all pieces in row INCLUDING self", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "kamikaze_row" } },
				{ row = 4, col = 1, player = 2, powers = {} },
				{ row = 4, col = 10, player = 2, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- Different row - survives
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateKamikazeRow(state, piece)
			-- Only piece in different row survives
			assert.are.equal(1, #state.pieces)
			assert.are.equal(5, state.pieces[1].row)
		end)
	end)

	describe("kamikaze_column", function()
		it("destroys all pieces in column INCLUDING self", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "kamikaze_column" } },
				{ row = 1, col = 5, player = 2, powers = {} },
				{ row = 8, col = 5, player = 2, powers = {} },
				{ row = 4, col = 6, player = 2, powers = {} }, -- Different column - survives
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateKamikazeColumn(state, piece)
			-- Only piece in different column survives
			assert.are.equal(1, #state.pieces)
			assert.are.equal(6, state.pieces[1].col)
		end)
	end)

	-- Phase 9A.3: Extended Recruitment
	describe("recruit_row", function()
		it("returns all enemy pieces in same row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_row" } },
				{ row = 4, col = 1, player = 2, powers = {} }, -- Enemy in row
				{ row = 4, col = 10, player = 2, powers = {} }, -- Enemy in row
				{ row = 5, col = 5, player = 2, powers = {} }, -- Enemy different row
				{ row = 4, col = 3, player = 1, powers = {} }, -- Ally in row (excluded)
			}
			local piece = state.pieces[1]

			local targets = PowerEffects.getRecruitRowTargets(state, piece)
			assert.are.equal(2, #targets)
		end)

		it("excludes own pieces", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_row" } },
				{ row = 4, col = 3, player = 1, powers = {} }, -- Ally
				{ row = 4, col = 7, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]

			local targets = PowerEffects.getRecruitRowTargets(state, piece)
			for _, t in ipairs(targets) do
				assert.are_not.equal(1, t.player)
			end
		end)

		it("converts all enemies in row to own team", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_row" } },
				{ row = 4, col = 1, player = 2, powers = {} },
				{ row = 4, col = 10, player = 2, powers = {} },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRecruitRow(state, piece)

			-- All pieces should now be player 1
			for _, p in ipairs(state.pieces) do
				if p.row == 4 then
					assert.are.equal(1, p.player)
				end
			end
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRecruitRow(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("recruit_column", function()
		it("returns all enemy pieces in same column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_column" } },
				{ row = 1, col = 5, player = 2, powers = {} }, -- Enemy in column
				{ row = 8, col = 5, player = 2, powers = {} }, -- Enemy in column
				{ row = 4, col = 6, player = 2, powers = {} }, -- Enemy different column
				{ row = 2, col = 5, player = 1, powers = {} }, -- Ally in column (excluded)
			}
			local piece = state.pieces[1]

			local targets = PowerEffects.getRecruitColumnTargets(state, piece)
			assert.are.equal(2, #targets)
		end)

		it("converts all enemies in column to own team", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_column" } },
				{ row = 1, col = 5, player = 2, powers = {} },
				{ row = 8, col = 5, player = 2, powers = {} },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRecruitColumn(state, piece)

			-- All pieces in column 5 should now be player 1
			for _, p in ipairs(state.pieces) do
				if p.col == 5 then
					assert.are.equal(1, p.player)
				end
			end
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "recruit_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRecruitColumn(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	-- Phase 9A.4: Scramble Powers
	describe("scramble_radial", function()
		it("shuffles positions of all pieces in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_radial" } },
				{ row = 3, col = 5, player = 2, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} },
				{ row = 4, col = 4, player = 2, powers = {} },
			}

			-- Record original positions
			local originalPositions = {}
			for _, p in ipairs(state.pieces) do
				table.insert(originalPositions, { row = p.row, col = p.col })
			end

			local piece = state.pieces[1]
			state = PowerEffects.activateScrambleRadial(state, piece)

			-- Same number of pieces
			assert.are.equal(4, #state.pieces)

			-- All pieces should still be on original positions (just shuffled among them)
			local newPositions = {}
			for _, p in ipairs(state.pieces) do
				newPositions[p.row .. "," .. p.col] = true
			end
			for _, pos in ipairs(originalPositions) do
				assert.is_true(newPositions[pos.row .. "," .. pos.col])
			end
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateScrambleRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)

		it("does not affect pieces outside 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_radial" } },
				{ row = 1, col = 1, player = 2, powers = {} }, -- Far away
			}
			local farPiece = state.pieces[2]
			local originalRow, originalCol = farPiece.row, farPiece.col

			state = PowerEffects.activateScrambleRadial(state, state.pieces[1])

			-- Far piece unchanged
			assert.are.equal(originalRow, farPiece.row)
			assert.are.equal(originalCol, farPiece.col)
		end)
	end)

	-- Phase 9A.5: Smart Bombs
	describe("smart_bombs", function()
		it("returns only enemy pieces in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "smart_bombs" } },
				{ row = 3, col = 5, player = 2, powers = {} }, -- Enemy
				{ row = 4, col = 4, player = 1, powers = {} }, -- Ally (excluded)
				{ row = 5, col = 5, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]

			local targets = PowerEffects.getSmartBombsTargets(state, piece)
			assert.are.equal(2, #targets)
			for _, t in ipairs(targets) do
				assert.are.equal(2, t.player)
			end
		end)

		it("destroys only enemy pieces in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "smart_bombs" } },
				{ row = 3, col = 5, player = 2, powers = {} }, -- Enemy - destroyed
				{ row = 4, col = 4, player = 1, powers = {} }, -- Ally - survives
				{ row = 5, col = 5, player = 2, powers = {} }, -- Enemy - destroyed
			}
			local piece = state.pieces[1]
			local ally = state.pieces[3]

			state = PowerEffects.activateSmartBombs(state, piece)

			-- Should have 2 pieces left (activator + ally)
			assert.are.equal(2, #state.pieces)
			-- Ally should survive
			local allyFound = false
			for _, p in ipairs(state.pieces) do
				if p == ally then
					allyFound = true
				end
			end
			assert.is_true(allyFound)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "smart_bombs" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateSmartBombs(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	-- Phase 9A.2: Acidic Powers
	describe("acidic_radial", function()
		it("destroys all pieces in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_radial" } },
				{ row = 3, col = 5, player = 2, powers = {} },
				{ row = 4, col = 4, player = 2, powers = {} },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicRadial(state, piece)
			-- Only activator remains
			assert.are.equal(1, #state.pieces)
		end)

		it("destroys tiles in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicRadial(state, piece)

			-- All tiles in 3x3 area should be destroyed
			assert.is_true(GameLogic.isTileDestroyed(state, 3, 4))
			assert.is_true(GameLogic.isTileDestroyed(state, 3, 5))
			assert.is_true(GameLogic.isTileDestroyed(state, 4, 4))
			assert.is_true(GameLogic.isTileDestroyed(state, 4, 6))
			assert.is_true(GameLogic.isTileDestroyed(state, 5, 5))
		end)

		it("does NOT destroy tile under activator", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicRadial(state, piece)

			-- Activator's tile should NOT be destroyed
			assert.is_false(GameLogic.isTileDestroyed(state, 4, 5))
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("acidic_row", function()
		it("destroys all pieces in row except activator", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_row" } },
				{ row = 4, col = 1, player = 2, powers = {} },
				{ row = 4, col = 10, player = 2, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- Different row - survives
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicRow(state, piece)
			-- Activator + piece in different row
			assert.are.equal(2, #state.pieces)
		end)

		it("destroys all tiles in row except under activator", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicRow(state, piece)

			-- All tiles in row except activator's tile destroyed
			for col = 1, 10 do
				if col ~= 5 then
					assert.is_true(
						GameLogic.isTileDestroyed(state, 4, col),
						"Tile at 4," .. col .. " should be destroyed"
					)
				else
					assert.is_false(GameLogic.isTileDestroyed(state, 4, 5), "Activator's tile should NOT be destroyed")
				end
			end
		end)
	end)

	describe("acidic_column", function()
		it("destroys all pieces in column except activator", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_column" } },
				{ row = 1, col = 5, player = 2, powers = {} },
				{ row = 8, col = 5, player = 2, powers = {} },
				{ row = 4, col = 6, player = 2, powers = {} }, -- Different column - survives
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicColumn(state, piece)
			-- Activator + piece in different column
			assert.are.equal(2, #state.pieces)
		end)

		it("destroys all tiles in column except under activator", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "acidic_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateAcidicColumn(state, piece)

			-- All tiles in column except activator's tile destroyed
			for row = 1, 8 do
				if row ~= 4 then
					assert.is_true(
						GameLogic.isTileDestroyed(state, row, 5),
						"Tile at " .. row .. ",5 should be destroyed"
					)
				else
					assert.is_false(GameLogic.isTileDestroyed(state, 4, 5), "Activator's tile should NOT be destroyed")
				end
			end
		end)
	end)

	-- Phase 9A.4: Scramble Row/Column
	describe("scramble_row", function()
		it("shuffles positions of all pieces in row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_row" } },
				{ row = 4, col = 1, player = 2, powers = {} },
				{ row = 4, col = 10, player = 2, powers = {} },
				{ row = 5, col = 5, player = 2, powers = {} }, -- Different row - unaffected
			}

			-- Record original positions in row
			local originalCols = {}
			for _, p in ipairs(state.pieces) do
				if p.row == 4 then
					table.insert(originalCols, p.col)
				end
			end

			local piece = state.pieces[1]
			state = PowerEffects.activateScrambleRow(state, piece)

			-- Same pieces, positions shuffled within row
			local newCols = {}
			for _, p in ipairs(state.pieces) do
				if p.row == 4 then
					table.insert(newCols, p.col)
				end
			end

			-- Same columns used, just shuffled
			table.sort(originalCols)
			table.sort(newCols)
			assert.are.same(originalCols, newCols)
		end)

		it("does not affect pieces in other rows", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_row" } },
				{ row = 5, col = 7, player = 2, powers = {} },
			}
			local otherPiece = state.pieces[2]

			state = PowerEffects.activateScrambleRow(state, state.pieces[1])

			assert.are.equal(5, otherPiece.row)
			assert.are.equal(7, otherPiece.col)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateScrambleRow(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("scramble_column", function()
		it("shuffles positions of all pieces in column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_column" } },
				{ row = 1, col = 5, player = 2, powers = {} },
				{ row = 8, col = 5, player = 2, powers = {} },
				{ row = 4, col = 6, player = 2, powers = {} }, -- Different column - unaffected
			}

			-- Record original rows in column
			local originalRows = {}
			for _, p in ipairs(state.pieces) do
				if p.col == 5 then
					table.insert(originalRows, p.row)
				end
			end

			local piece = state.pieces[1]
			state = PowerEffects.activateScrambleColumn(state, piece)

			-- Same pieces, positions shuffled within column
			local newRows = {}
			for _, p in ipairs(state.pieces) do
				if p.col == 5 then
					table.insert(newRows, p.row)
				end
			end

			table.sort(originalRows)
			table.sort(newRows)
			assert.are.same(originalRows, newRows)
		end)

		it("does not affect pieces in other columns", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_column" } },
				{ row = 3, col = 7, player = 2, powers = {} },
			}
			local otherPiece = state.pieces[2]

			state = PowerEffects.activateScrambleColumn(state, state.pieces[1])

			assert.are.equal(3, otherPiece.row)
			assert.are.equal(7, otherPiece.col)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scramble_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateScrambleColumn(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("getValidMovesWithPowers with flags", function()
		it("includes diagonal moves when canMoveDiagonally is true", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.canMoveDiagonally = true

			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			local hasDiagonal = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 6 then
					hasDiagonal = true
				end
			end
			assert.is_true(hasDiagonal)
		end)

		it("excludes capture of isJumpProof pieces", function()
			local state = GameLogic.createInitialState()
			local attacker = GameLogic.getPieceAt(state, 2, 5)
			attacker.row = 6

			local defender = GameLogic.getPieceAt(state, 7, 5)
			defender.isJumpProof = true

			local moves = PowerEffects.getValidMovesWithPowers(state, attacker)
			local canCapture = false
			for _, move in ipairs(moves) do
				if move.row == 7 and move.col == 5 then
					canCapture = true
				end
			end
			assert.is_false(canCapture)
		end)
	end)
end)
