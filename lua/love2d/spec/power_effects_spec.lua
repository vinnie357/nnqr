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
