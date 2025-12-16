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

	-- Phase 9B: Terrain Powers

	-- 9B.1 Area Effects
	describe("plateau", function()
		it("raises 3x3 area to max height (4)", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "plateau" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activatePlateau(state, piece)

			-- All tiles in 3x3 should be at max height
			for dr = -1, 1 do
				for dc = -1, 1 do
					local row = 4 + dr
					local col = 5 + dc
					assert.are.equal(4, state.heightMap[row][col], "Tile at " .. row .. "," .. col .. " should be 4")
				end
			end
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "plateau" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activatePlateau(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("moat", function()
		it("raises center tile to max height", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "moat" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateMoat(state, piece)

			assert.are.equal(4, state.heightMap[4][5])
		end)

		it("lowers surrounding ring by 1", function()
			local state = GameLogic.createInitialState()
			-- Set all heights to 2 first
			for row = 3, 5 do
				for col = 4, 6 do
					state.heightMap[row][col] = 2
				end
			end
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "moat" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateMoat(state, piece)

			-- Surrounding tiles should be lowered to 1
			assert.are.equal(1, state.heightMap[3][4])
			assert.are.equal(1, state.heightMap[3][5])
			assert.are.equal(1, state.heightMap[3][6])
			assert.are.equal(1, state.heightMap[4][4])
			assert.are.equal(1, state.heightMap[4][6])
			assert.are.equal(1, state.heightMap[5][4])
			assert.are.equal(1, state.heightMap[5][5])
			assert.are.equal(1, state.heightMap[5][6])
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "moat" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateMoat(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("climb_tile", function()
		it("sets canClimbAny flag on piece", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "climb_tile" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateClimbTile(state, piece)
			assert.is_true(piece.canClimbAny)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "climb_tile" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateClimbTile(state, piece)
			assert.are.equal(0, #piece.powers)
		end)

		it("allows movement to any height when flag is set", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = {}, canClimbAny = true },
			}
			local piece = state.pieces[1]
			state.heightMap[4][5] = 0
			state.heightMap[4][6] = 4 -- Normally can't climb 4 levels

			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			local canReachHigh = false
			for _, move in ipairs(moves) do
				if move.row == 4 and move.col == 6 then
					canReachHigh = true
				end
			end
			assert.is_true(canReachHigh)
		end)
	end)

	-- 9B.2 Line Effects
	describe("trench_row", function()
		it("lowers entire row by 2", function()
			local state = GameLogic.createInitialState()
			-- Set row heights
			for col = 1, 10 do
				state.heightMap[4][col] = 3
			end
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "trench_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTrenchRow(state, piece)

			for col = 1, 10 do
				assert.are.equal(1, state.heightMap[4][col])
			end
		end)

		it("clamps at min height 0", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][5] = 1 -- Will go below 0
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "trench_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTrenchRow(state, piece)

			assert.are.equal(0, state.heightMap[4][5])
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "trench_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTrenchRow(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("trench_column", function()
		it("lowers entire column by 2", function()
			local state = GameLogic.createInitialState()
			for row = 1, 8 do
				state.heightMap[row][5] = 4
			end
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "trench_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTrenchColumn(state, piece)

			for row = 1, 8 do
				assert.are.equal(2, state.heightMap[row][5])
			end
		end)
	end)

	describe("wall_row", function()
		it("raises entire row by 2", function()
			local state = GameLogic.createInitialState()
			for col = 1, 10 do
				state.heightMap[4][col] = 1
			end
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "wall_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateWallRow(state, piece)

			for col = 1, 10 do
				assert.are.equal(3, state.heightMap[4][col])
			end
		end)

		it("clamps at max height 4", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][5] = 3 -- Will exceed 4
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "wall_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateWallRow(state, piece)

			assert.are.equal(4, state.heightMap[4][5])
		end)
	end)

	describe("wall_column", function()
		it("raises entire column by 2", function()
			local state = GameLogic.createInitialState()
			for row = 1, 8 do
				state.heightMap[row][5] = 1
			end
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "wall_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateWallColumn(state, piece)

			for row = 1, 8 do
				assert.are.equal(3, state.heightMap[row][5])
			end
		end)
	end)

	-- 9B.3 Invert Powers
	describe("invert_radial", function()
		it("flips heights in 3x3 (4 becomes 0, 0 becomes 4)", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][5] = 4
			state.heightMap[3][5] = 0
			state.heightMap[5][5] = 2
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "invert_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateInvertRadial(state, piece)

			assert.are.equal(0, state.heightMap[4][5]) -- 4 -> 0
			assert.are.equal(4, state.heightMap[3][5]) -- 0 -> 4
			assert.are.equal(2, state.heightMap[5][5]) -- 2 -> 2 (midpoint)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "invert_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateInvertRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("invert_row", function()
		it("flips heights in entire row", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][1] = 0
			state.heightMap[4][5] = 4
			state.heightMap[4][10] = 1
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "invert_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateInvertRow(state, piece)

			assert.are.equal(4, state.heightMap[4][1]) -- 0 -> 4
			assert.are.equal(0, state.heightMap[4][5]) -- 4 -> 0
			assert.are.equal(3, state.heightMap[4][10]) -- 1 -> 3
		end)
	end)

	describe("invert_column", function()
		it("flips heights in entire column", function()
			local state = GameLogic.createInitialState()
			state.heightMap[1][5] = 0
			state.heightMap[4][5] = 4
			state.heightMap[8][5] = 1
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "invert_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateInvertColumn(state, piece)

			assert.are.equal(4, state.heightMap[1][5]) -- 0 -> 4
			assert.are.equal(0, state.heightMap[4][5]) -- 4 -> 0
			assert.are.equal(3, state.heightMap[8][5]) -- 1 -> 3
		end)
	end)

	-- 9B.4 Dredge Powers
	describe("dredge_radial", function()
		it("raises tiles under friendly pieces in 3x3", function()
			local state = GameLogic.createInitialState()
			state.heightMap[3][5] = 1
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "dredge_radial" } },
				{ row = 3, col = 5, player = 1, powers = {} }, -- Ally
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDredgeRadial(state, piece)

			assert.are.equal(2, state.heightMap[3][5]) -- Raised
		end)

		it("lowers tiles under enemy pieces in 3x3", function()
			local state = GameLogic.createInitialState()
			state.heightMap[5][5] = 3
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "dredge_radial" } },
				{ row = 5, col = 5, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDredgeRadial(state, piece)

			assert.are.equal(2, state.heightMap[5][5]) -- Lowered
		end)

		it("raises activator's tile", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][5] = 1
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "dredge_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDredgeRadial(state, piece)

			assert.are.equal(2, state.heightMap[4][5]) -- Raised (self is friendly)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "dredge_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDredgeRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("dredge_row", function()
		it("raises friendly and lowers enemy tiles in row", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][1] = 1
			state.heightMap[4][10] = 3
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "dredge_row" } },
				{ row = 4, col = 1, player = 1, powers = {} }, -- Ally
				{ row = 4, col = 10, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDredgeRow(state, piece)

			assert.are.equal(2, state.heightMap[4][1]) -- Ally raised
			assert.are.equal(2, state.heightMap[4][10]) -- Enemy lowered
		end)
	end)

	describe("dredge_column", function()
		it("raises friendly and lowers enemy tiles in column", function()
			local state = GameLogic.createInitialState()
			state.heightMap[1][5] = 1
			state.heightMap[8][5] = 3
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "dredge_column" } },
				{ row = 1, col = 5, player = 1, powers = {} }, -- Ally
				{ row = 8, col = 5, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDredgeColumn(state, piece)

			assert.are.equal(2, state.heightMap[1][5]) -- Ally raised
			assert.are.equal(2, state.heightMap[8][5]) -- Enemy lowered
		end)
	end)

	-- Phase 9C: Power Transfer Powers

	-- 9C.1 Teach (Share to allies)
	describe("teach_radial", function()
		it("copies all powers to adjacent allies", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "teach_radial", "bomb", "jump_proof" } },
				{ row = 3, col = 5, player = 1, powers = {} }, -- Ally adjacent
				{ row = 5, col = 5, player = 2, powers = {} }, -- Enemy (excluded)
			}
			local piece = state.pieces[1]
			local ally = state.pieces[2]

			state = PowerEffects.activateTeachRadial(state, piece)

			-- Ally should have bomb and jump_proof (not teach_radial which was consumed)
			assert.are.equal(2, #ally.powers)
			local hasBomb = false
			local hasJumpProof = false
			for _, p in ipairs(ally.powers) do
				if p == "bomb" then
					hasBomb = true
				end
				if p == "jump_proof" then
					hasJumpProof = true
				end
			end
			assert.is_true(hasBomb)
			assert.is_true(hasJumpProof)
		end)

		it("does not copy to enemies", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "teach_radial", "bomb" } },
				{ row = 3, col = 5, player = 2, powers = {} }, -- Enemy
			}
			local piece = state.pieces[1]
			local enemy = state.pieces[2]

			state = PowerEffects.activateTeachRadial(state, piece)

			assert.are.equal(0, #enemy.powers)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "teach_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTeachRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("teach_row", function()
		it("copies all powers to allies in row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "teach_row", "bomb" } },
				{ row = 4, col = 1, player = 1, powers = {} }, -- Ally in row
				{ row = 4, col = 10, player = 1, powers = {} }, -- Ally in row
				{ row = 5, col = 5, player = 1, powers = {} }, -- Ally different row (excluded)
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTeachRow(state, piece)

			assert.are.equal(1, #state.pieces[2].powers) -- bomb
			assert.are.equal(1, #state.pieces[3].powers) -- bomb
			assert.are.equal(0, #state.pieces[4].powers) -- not in row
		end)
	end)

	describe("teach_column", function()
		it("copies all powers to allies in column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "teach_column", "bomb" } },
				{ row = 1, col = 5, player = 1, powers = {} }, -- Ally in column
				{ row = 8, col = 5, player = 1, powers = {} }, -- Ally in column
				{ row = 4, col = 6, player = 1, powers = {} }, -- Ally different column (excluded)
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateTeachColumn(state, piece)

			assert.are.equal(1, #state.pieces[2].powers) -- bomb
			assert.are.equal(1, #state.pieces[3].powers) -- bomb
			assert.are.equal(0, #state.pieces[4].powers) -- not in column
		end)
	end)

	-- 9C.2 Learn (Absorb from allies)
	describe("learn_radial", function()
		it("takes all powers from adjacent allies", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "learn_radial" } },
				{ row = 3, col = 5, player = 1, powers = { "bomb", "jump_proof" } }, -- Ally with powers
				{ row = 5, col = 5, player = 2, powers = { "recruit" } }, -- Enemy (excluded)
			}
			local piece = state.pieces[1]
			local ally = state.pieces[2]

			state = PowerEffects.activateLearnRadial(state, piece)

			-- Piece should have absorbed ally's powers
			assert.are.equal(2, #piece.powers)
			-- Ally should have no powers left
			assert.are.equal(0, #ally.powers)
		end)

		it("does not take from enemies", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "learn_radial" } },
				{ row = 3, col = 5, player = 2, powers = { "bomb" } }, -- Enemy
			}
			local piece = state.pieces[1]
			local enemy = state.pieces[2]

			state = PowerEffects.activateLearnRadial(state, piece)

			assert.are.equal(0, #piece.powers) -- learn_radial consumed, nothing learned
			assert.are.equal(1, #enemy.powers) -- Enemy keeps powers
		end)
	end)

	describe("learn_row", function()
		it("takes all powers from allies in row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "learn_row" } },
				{ row = 4, col = 1, player = 1, powers = { "bomb" } },
				{ row = 4, col = 10, player = 1, powers = { "recruit" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateLearnRow(state, piece)

			assert.are.equal(2, #piece.powers) -- bomb + recruit
			assert.are.equal(0, #state.pieces[2].powers)
			assert.are.equal(0, #state.pieces[3].powers)
		end)
	end)

	describe("learn_column", function()
		it("takes all powers from allies in column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "learn_column" } },
				{ row = 1, col = 5, player = 1, powers = { "bomb" } },
				{ row = 8, col = 5, player = 1, powers = { "recruit" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateLearnColumn(state, piece)

			assert.are.equal(2, #piece.powers) -- bomb + recruit
			assert.are.equal(0, #state.pieces[2].powers)
			assert.are.equal(0, #state.pieces[3].powers)
		end)
	end)

	-- 9C.3 Pilfer (Steal from enemies)
	describe("pilfer_radial", function()
		it("steals one random power from each adjacent enemy", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "pilfer_radial" } },
				{ row = 3, col = 5, player = 2, powers = { "bomb", "recruit" } }, -- Enemy with powers
				{ row = 5, col = 5, player = 1, powers = { "jump_proof" } }, -- Ally (excluded)
			}
			local piece = state.pieces[1]
			local enemy = state.pieces[2]

			state = PowerEffects.activatePilferRadial(state, piece)

			-- Piece should have stolen 1 power
			assert.are.equal(1, #piece.powers)
			-- Enemy should have 1 power left
			assert.are.equal(1, #enemy.powers)
		end)

		it("does not steal from allies", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "pilfer_radial" } },
				{ row = 3, col = 5, player = 1, powers = { "bomb" } }, -- Ally
			}
			local piece = state.pieces[1]
			local ally = state.pieces[2]

			state = PowerEffects.activatePilferRadial(state, piece)

			assert.are.equal(0, #piece.powers) -- Nothing stolen
			assert.are.equal(1, #ally.powers) -- Ally keeps power
		end)

		it("handles enemies with no powers", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "pilfer_radial" } },
				{ row = 3, col = 5, player = 2, powers = {} }, -- Enemy with no powers
			}
			local piece = state.pieces[1]

			state = PowerEffects.activatePilferRadial(state, piece)

			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("pilfer_row", function()
		it("steals one power from each enemy in row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "pilfer_row" } },
				{ row = 4, col = 1, player = 2, powers = { "bomb" } },
				{ row = 4, col = 10, player = 2, powers = { "recruit" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activatePilferRow(state, piece)

			assert.are.equal(2, #piece.powers) -- Stole from both
			assert.are.equal(0, #state.pieces[2].powers)
			assert.are.equal(0, #state.pieces[3].powers)
		end)
	end)

	describe("pilfer_column", function()
		it("steals one power from each enemy in column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "pilfer_column" } },
				{ row = 1, col = 5, player = 2, powers = { "bomb" } },
				{ row = 8, col = 5, player = 2, powers = { "recruit" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activatePilferColumn(state, piece)

			assert.are.equal(2, #piece.powers) -- Stole from both
			assert.are.equal(0, #state.pieces[2].powers)
			assert.are.equal(0, #state.pieces[3].powers)
		end)
	end)

	-- Phase 9D: Meta Powers

	describe("double_powers (2x)", function()
		it("doubles all powers on the piece", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "double_powers", "bomb", "recruit" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDoublePowers(state, piece)

			-- Should have: bomb, bomb, recruit, recruit (2x consumed)
			assert.are.equal(4, #piece.powers)
			local bombCount = 0
			local recruitCount = 0
			for _, p in ipairs(piece.powers) do
				if p == "bomb" then
					bombCount = bombCount + 1
				end
				if p == "recruit" then
					recruitCount = recruitCount + 1
				end
			end
			assert.are.equal(2, bombCount)
			assert.are.equal(2, recruitCount)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "double_powers" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDoublePowers(state, piece)
			assert.are.equal(0, #piece.powers)
		end)

		it("works with empty inventory (just consumes)", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "double_powers" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateDoublePowers(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("orbic_rehash", function()
		it("respawns all orbs at new random locations", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orbic_rehash" } },
			}
			local piece = state.pieces[1]
			local orbs = {
				{ row = 3, col = 3, powerId = "bomb" },
				{ row = 5, col = 7, powerId = "recruit" },
			}

			-- Record original positions
			local originalPositions = {}
			for _, orb in ipairs(orbs) do
				originalPositions[orb.row .. "," .. orb.col] = true
			end

			state, orbs = PowerEffects.activateOrbicRehash(state, piece, orbs)

			-- Same number of orbs
			assert.are.equal(2, #orbs)
			-- Powers preserved
			local powers = {}
			for _, orb in ipairs(orbs) do
				powers[orb.powerId] = true
			end
			assert.is_true(powers["bomb"])
			assert.is_true(powers["recruit"])
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orbic_rehash" } },
			}
			local piece = state.pieces[1]
			local orbs = {}

			state, orbs = PowerEffects.activateOrbicRehash(state, piece, orbs)
			assert.are.equal(0, #piece.powers)
		end)

		it("handles empty orbs array", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orbic_rehash" } },
			}
			local piece = state.pieces[1]
			local orbs = {}

			state, orbs = PowerEffects.activateOrbicRehash(state, piece, orbs)
			assert.are.equal(0, #orbs)
		end)
	end)

	describe("cancel_multiply", function()
		it("destroys the most recently multiplied piece", function()
			local state = GameLogic.createInitialState()
			-- Track multiplied pieces with a list
			state.multipliedPieces = {}
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "cancel_multiply" } },
				{ row = 3, col = 3, player = 2, powers = {} }, -- Normal piece
				{ row = 6, col = 6, player = 2, powers = {}, isMultiplied = true }, -- Multiplied piece
			}
			-- Track the multiplied piece
			table.insert(state.multipliedPieces, state.pieces[3])

			local piece = state.pieces[1]
			local initialCount = #state.pieces

			state = PowerEffects.activateCancelMultiply(state, piece)

			-- One piece destroyed
			assert.are.equal(initialCount - 1, #state.pieces)
			-- The multiplied piece should be gone
			local found = false
			for _, p in ipairs(state.pieces) do
				if p.isMultiplied then
					found = true
				end
			end
			assert.is_false(found)
		end)

		it("does nothing if no multiplied pieces exist", function()
			local state = GameLogic.createInitialState()
			state.multipliedPieces = {}
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "cancel_multiply" } },
				{ row = 3, col = 3, player = 2, powers = {} },
			}
			local piece = state.pieces[1]
			local initialCount = #state.pieces

			state = PowerEffects.activateCancelMultiply(state, piece)

			assert.are.equal(initialCount, #state.pieces)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.multipliedPieces = {}
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "cancel_multiply" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateCancelMultiply(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("grow_quadradius", function()
		it("increases piece growQuadradiusLevel", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "grow_quadradius" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateGrowQuadradius(state, piece)

			assert.are.equal(1, piece.growQuadradiusLevel)
		end)

		it("stacks up to level 3", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{
					row = 4,
					col = 5,
					player = 1,
					powers = { "grow_quadradius", "grow_quadradius", "grow_quadradius", "grow_quadradius" },
					growQuadradiusLevel = 0,
				},
			}
			local piece = state.pieces[1]

			-- Activate 4 times
			state = PowerEffects.activateGrowQuadradius(state, piece)
			assert.are.equal(1, piece.growQuadradiusLevel)
			state = PowerEffects.activateGrowQuadradius(state, piece)
			assert.are.equal(2, piece.growQuadradiusLevel)
			state = PowerEffects.activateGrowQuadradius(state, piece)
			assert.are.equal(3, piece.growQuadradiusLevel)
			state = PowerEffects.activateGrowQuadradius(state, piece)
			-- Should cap at 3
			assert.are.equal(3, piece.growQuadradiusLevel)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "grow_quadradius" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateGrowQuadradius(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("beneficiary", function()
		it("transfers all ally powers to this piece when they die", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "beneficiary" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateBeneficiary(state, piece)

			-- Sets the beneficiary flag
			assert.is_true(piece.isBeneficiary)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "beneficiary" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateBeneficiary(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	-- Phase 9E: Movement & Control Powers

	-- 9E.1 Special Movement
	describe("switcheroo", function()
		it("returns adjacent pieces as valid targets", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "switcheroo" } },
				{ row = 3, col = 5, player = 2, powers = {} }, -- Adjacent enemy
				{ row = 4, col = 6, player = 1, powers = {} }, -- Adjacent ally
				{ row = 1, col = 1, player = 2, powers = {} }, -- Not adjacent
			}
			local piece = state.pieces[1]

			local targets = PowerEffects.getSwitcherooTargets(state, piece)
			assert.are.equal(2, #targets) -- Both adjacent pieces
		end)

		it("swaps positions with target piece", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "switcheroo" } },
				{ row = 3, col = 5, player = 2, powers = {} },
			}
			local piece = state.pieces[1]
			local target = state.pieces[2]

			state = PowerEffects.activateSwitcheroo(state, piece, target)

			assert.are.equal(3, piece.row)
			assert.are.equal(5, piece.col)
			assert.are.equal(4, target.row)
			assert.are.equal(5, target.col)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "switcheroo" } },
				{ row = 3, col = 5, player = 2, powers = {} },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateSwitcheroo(state, piece, state.pieces[2])
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("scavenger", function()
		it("sets isScavenger flag on piece", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scavenger" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateScavenger(state, piece)

			assert.is_true(piece.isScavenger)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "scavenger" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateScavenger(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("flat_to_sphere", function()
		it("sets canWrap flag on piece", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "flat_to_sphere" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateFlatToSphere(state, piece)

			assert.is_true(piece.canWrap)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "flat_to_sphere" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateFlatToSphere(state, piece)
			assert.are.equal(0, #piece.powers)
		end)

		it("enables wraparound movement when flag is set", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 10, player = 1, powers = {}, canWrap = true }, -- Right edge
			}
			local piece = state.pieces[1]

			local moves = PowerEffects.getValidMovesWithPowers(state, piece)
			-- Should be able to wrap to column 1
			local canWrap = false
			for _, move in ipairs(moves) do
				if move.col == 1 then
					canWrap = true
				end
			end
			assert.is_true(canWrap)
		end)
	end)

	-- 9E.5 Intelligence Powers
	describe("spyware_radial", function()
		it("reveals powers of adjacent enemy pieces", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "spyware_radial" } },
				{ row = 3, col = 5, player = 2, powers = { "bomb", "recruit" } },
			}
			local piece = state.pieces[1]
			local enemy = state.pieces[2]

			state = PowerEffects.activateSpywareRadial(state, piece)

			assert.is_true(enemy.powersRevealed)
		end)

		it("does not reveal ally powers", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "spyware_radial" } },
				{ row = 3, col = 5, player = 1, powers = { "bomb" } }, -- Ally
			}
			local piece = state.pieces[1]
			local ally = state.pieces[2]

			state = PowerEffects.activateSpywareRadial(state, piece)

			assert.is_nil(ally.powersRevealed)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "spyware_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateSpywareRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("spyware_row", function()
		it("reveals powers of enemy pieces in row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "spyware_row" } },
				{ row = 4, col = 1, player = 2, powers = { "bomb" } },
				{ row = 4, col = 10, player = 2, powers = { "recruit" } },
				{ row = 5, col = 5, player = 2, powers = { "jump_proof" } }, -- Different row
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateSpywareRow(state, piece)

			assert.is_true(state.pieces[2].powersRevealed)
			assert.is_true(state.pieces[3].powersRevealed)
			assert.is_nil(state.pieces[4].powersRevealed)
		end)
	end)

	describe("spyware_column", function()
		it("reveals powers of enemy pieces in column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "spyware_column" } },
				{ row = 1, col = 5, player = 2, powers = { "bomb" } },
				{ row = 8, col = 5, player = 2, powers = { "recruit" } },
				{ row = 4, col = 6, player = 2, powers = { "jump_proof" } }, -- Different column
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateSpywareColumn(state, piece)

			assert.is_true(state.pieces[2].powersRevealed)
			assert.is_true(state.pieces[3].powersRevealed)
			assert.is_nil(state.pieces[4].powersRevealed)
		end)
	end)

	describe("orb_spy_radial", function()
		it("reveals contents of adjacent orbs", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orb_spy_radial" } },
			}
			local piece = state.pieces[1]
			local orbs = {
				{ row = 3, col = 5, powerId = "bomb", revealed = false },
				{ row = 1, col = 1, powerId = "recruit", revealed = false }, -- Not adjacent
			}

			state, orbs = PowerEffects.activateOrbSpyRadial(state, piece, orbs)

			assert.is_true(orbs[1].revealed)
			assert.is_false(orbs[2].revealed)
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orb_spy_radial" } },
			}
			local piece = state.pieces[1]

			state, _ = PowerEffects.activateOrbSpyRadial(state, piece, {})
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("orb_spy_row", function()
		it("reveals contents of orbs in row", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orb_spy_row" } },
			}
			local piece = state.pieces[1]
			local orbs = {
				{ row = 4, col = 1, powerId = "bomb", revealed = false },
				{ row = 4, col = 10, powerId = "recruit", revealed = false },
				{ row = 5, col = 5, powerId = "jump_proof", revealed = false }, -- Different row
			}

			state, orbs = PowerEffects.activateOrbSpyRow(state, piece, orbs)

			assert.is_true(orbs[1].revealed)
			assert.is_true(orbs[2].revealed)
			assert.is_false(orbs[3].revealed)
		end)
	end)

	describe("orb_spy_column", function()
		it("reveals contents of orbs in column", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "orb_spy_column" } },
			}
			local piece = state.pieces[1]
			local orbs = {
				{ row = 1, col = 5, powerId = "bomb", revealed = false },
				{ row = 8, col = 5, powerId = "recruit", revealed = false },
				{ row = 4, col = 6, powerId = "jump_proof", revealed = false }, -- Different column
			}

			state, orbs = PowerEffects.activateOrbSpyColumn(state, piece, orbs)

			assert.is_true(orbs[1].revealed)
			assert.is_true(orbs[2].revealed)
			assert.is_false(orbs[3].revealed)
		end)
	end)

	-- 9E.6 Restoration Powers
	describe("refurb_radial", function()
		it("repairs all destroyed tiles in 3x3 area", function()
			local state = GameLogic.createInitialState()
			state.destroyedTiles = {
				["3,5"] = true,
				["4,4"] = true,
				["1,1"] = true, -- Not adjacent
			}
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "refurb_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRefurbRadial(state, piece)

			assert.is_nil(state.destroyedTiles["3,5"])
			assert.is_nil(state.destroyedTiles["4,4"])
			assert.is_true(state.destroyedTiles["1,1"]) -- Still destroyed
		end)

		it("removes power after use", function()
			local state = GameLogic.createInitialState()
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "refurb_radial" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRefurbRadial(state, piece)
			assert.are.equal(0, #piece.powers)
		end)
	end)

	describe("refurb_row", function()
		it("repairs all destroyed tiles in row", function()
			local state = GameLogic.createInitialState()
			state.destroyedTiles = {
				["4,1"] = true,
				["4,10"] = true,
				["5,5"] = true, -- Different row
			}
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "refurb_row" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRefurbRow(state, piece)

			assert.is_nil(state.destroyedTiles["4,1"])
			assert.is_nil(state.destroyedTiles["4,10"])
			assert.is_true(state.destroyedTiles["5,5"]) -- Still destroyed
		end)
	end)

	describe("refurb_column", function()
		it("repairs all destroyed tiles in column", function()
			local state = GameLogic.createInitialState()
			state.destroyedTiles = {
				["1,5"] = true,
				["8,5"] = true,
				["4,6"] = true, -- Different column
			}
			state.pieces = {
				{ row = 4, col = 5, player = 1, powers = { "refurb_column" } },
			}
			local piece = state.pieces[1]

			state = PowerEffects.activateRefurbColumn(state, piece)

			assert.is_nil(state.destroyedTiles["1,5"])
			assert.is_nil(state.destroyedTiles["8,5"])
			assert.is_true(state.destroyedTiles["4,6"]) -- Still destroyed
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
