-- Busted tests for game logic integration with height system
-- Run with: busted spec/
-- TDD: Write tests first (RED), then implement (GREEN)

describe("GameLogic", function()
	local GameLogic

	setup(function()
		GameLogic = require("src.shared.game_logic")
	end)

	describe("board initialization", function()
		it("creates a board with correct dimensions", function()
			local state = GameLogic.createInitialState()
			assert.are.equal(10, state.cols)
			assert.are.equal(8, state.rows)
		end)

		it("initializes height map", function()
			local state = GameLogic.createInitialState()
			assert.is_table(state.heightMap)
			assert.are.equal(8, #state.heightMap)
			assert.are.equal(10, #state.heightMap[1])
		end)

		it("starts heights at 0", function()
			local state = GameLogic.createInitialState()
			assert.are.equal(0, state.heightMap[1][1])
			assert.are.equal(0, state.heightMap[4][5])
		end)

		it("creates 40 pieces total", function()
			local state = GameLogic.createInitialState()
			assert.are.equal(40, #state.pieces)
		end)

		it("creates 20 pieces per player", function()
			local state = GameLogic.createInitialState()
			local p1, p2 = 0, 0
			for _, piece in ipairs(state.pieces) do
				if piece.player == 1 then
					p1 = p1 + 1
				else
					p2 = p2 + 1
				end
			end
			assert.are.equal(20, p1)
			assert.are.equal(20, p2)
		end)

		it("starts with player 1", function()
			local state = GameLogic.createInitialState()
			assert.are.equal(1, state.currentPlayer)
		end)

		it("starts in playing state", function()
			local state = GameLogic.createInitialState()
			assert.are.equal("playing", state.gameState)
		end)
	end)

	describe("getPieceAt", function()
		it("finds piece at position", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 1)
			assert.is_table(piece)
			assert.are.equal(1, piece.player)
		end)

		it("returns nil for empty position", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 4, 5)
			assert.is_nil(piece)
		end)
	end)

	describe("getValidMoves with height", function()
		it("returns valid moves for piece on flat terrain", function()
			local state = GameLogic.createInitialState()
			-- Piece at row 2 should have moves to row 1 and row 3
			local piece = GameLogic.getPieceAt(state, 2, 5)
			local moves = GameLogic.getValidMoves(state, piece)
			-- Should have at least 1 move (down to row 3)
			assert.is_true(#moves >= 1)
		end)

		it("excludes moves to tiles too high to climb", function()
			local state = GameLogic.createInitialState()
			-- Set a tile to height 2
			state.heightMap[3][5] = 2
			-- Piece at row 2, col 5 (height 0) shouldn't be able to move to row 3, col 5 (height 2)
			local piece = GameLogic.getPieceAt(state, 2, 5)
			local moves = GameLogic.getValidMoves(state, piece)
			-- Check that row 3, col 5 is NOT in valid moves
			local foundBadMove = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 5 then
					foundBadMove = true
				end
			end
			assert.is_false(foundBadMove)
		end)

		it("allows moves to tiles 1 level higher", function()
			local state = GameLogic.createInitialState()
			-- Set a tile to height 1
			state.heightMap[3][5] = 1
			-- Piece at row 2, col 5 (height 0) CAN move to row 3, col 5 (height 1)
			local piece = GameLogic.getPieceAt(state, 2, 5)
			local moves = GameLogic.getValidMoves(state, piece)
			local foundMove = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 5 then
					foundMove = true
				end
			end
			assert.is_true(foundMove)
		end)

		it("allows dropping any number of levels", function()
			local state = GameLogic.createInitialState()
			-- Set piece's tile to height 4
			state.heightMap[2][5] = 4
			-- Destination at height 0
			state.heightMap[3][5] = 0
			local piece = GameLogic.getPieceAt(state, 2, 5)
			local moves = GameLogic.getValidMoves(state, piece)
			local foundMove = false
			for _, move in ipairs(moves) do
				if move.row == 3 and move.col == 5 then
					foundMove = true
				end
			end
			assert.is_true(foundMove)
		end)
	end)

	describe("movePiece", function()
		it("moves piece to new position", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			state = GameLogic.movePiece(state, piece, 3, 5)
			assert.are.equal(3, piece.row)
			assert.are.equal(5, piece.col)
		end)

		it("captures enemy piece", function()
			local state = GameLogic.createInitialState()
			-- Move a P1 piece next to P2
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 6 -- Move close to P2
			-- Now capture
			local initialCount = #state.pieces
			state = GameLogic.movePiece(state, piece, 7, 5)
			assert.are.equal(initialCount - 1, #state.pieces)
		end)

		it("returns updated state", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			local newState = GameLogic.movePiece(state, piece, 3, 5)
			assert.is_table(newState)
		end)
	end)

	describe("endTurn", function()
		it("switches to player 2 after player 1", function()
			local state = GameLogic.createInitialState()
			state = GameLogic.endTurn(state)
			assert.are.equal(2, state.currentPlayer)
		end)

		it("switches to player 1 after player 2", function()
			local state = GameLogic.createInitialState()
			state.currentPlayer = 2
			state = GameLogic.endTurn(state)
			assert.are.equal(1, state.currentPlayer)
		end)

		it("detects player 1 win when player 2 has no pieces", function()
			local state = GameLogic.createInitialState()
			-- Remove all player 2 pieces
			local newPieces = {}
			for _, p in ipairs(state.pieces) do
				if p.player == 1 then
					table.insert(newPieces, p)
				end
			end
			state.pieces = newPieces
			state = GameLogic.endTurn(state)
			assert.are.equal("gameover", state.gameState)
			assert.are.equal(1, state.winner)
		end)

		it("detects player 2 win when player 1 has no pieces", function()
			local state = GameLogic.createInitialState()
			-- Remove all player 1 pieces
			local newPieces = {}
			for _, p in ipairs(state.pieces) do
				if p.player == 2 then
					table.insert(newPieces, p)
				end
			end
			state.pieces = newPieces
			state = GameLogic.endTurn(state)
			assert.are.equal("gameover", state.gameState)
			assert.are.equal(2, state.winner)
		end)
	end)

	describe("setHeight", function()
		it("sets height at position", function()
			local state = GameLogic.createInitialState()
			state = GameLogic.setHeight(state, 4, 5, 3)
			assert.are.equal(3, state.heightMap[4][5])
		end)

		it("clamps height to valid range", function()
			local state = GameLogic.createInitialState()
			state = GameLogic.setHeight(state, 4, 5, 10)
			assert.are.equal(4, state.heightMap[4][5])
		end)
	end)

	describe("getHeight", function()
		it("gets height at position", function()
			local state = GameLogic.createInitialState()
			state.heightMap[4][5] = 2
			assert.are.equal(2, GameLogic.getHeight(state, 4, 5))
		end)

		it("returns 0 for out of bounds", function()
			local state = GameLogic.createInitialState()
			assert.are.equal(0, GameLogic.getHeight(state, 0, 0))
			assert.are.equal(0, GameLogic.getHeight(state, 100, 100))
		end)
	end)

	describe("isValidMove", function()
		it("validates move considering height", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			-- Valid: same height orthogonal
			assert.is_true(GameLogic.isValidMove(state, piece, 3, 5))
		end)

		it("rejects move to tile too high", function()
			local state = GameLogic.createInitialState()
			state.heightMap[3][5] = 3
			local piece = GameLogic.getPieceAt(state, 2, 5)
			assert.is_false(GameLogic.isValidMove(state, piece, 3, 5))
		end)

		it("rejects capturing own piece", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 1, 5)
			-- Row 2 has own piece
			assert.is_false(GameLogic.isValidMove(state, piece, 2, 5))
		end)

		it("allows capturing enemy piece at climbable height", function()
			local state = GameLogic.createInitialState()
			-- Move P1 piece near P2
			local piece = GameLogic.getPieceAt(state, 2, 5)
			piece.row = 6
			-- Enemy at row 7 (height 0)
			assert.is_true(GameLogic.isValidMove(state, piece, 7, 5))
		end)
	end)

	describe("selectPiece", function()
		it("selects piece and calculates valid moves", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			state = GameLogic.selectPiece(state, piece)
			assert.are.equal(piece, state.selectedPiece)
			assert.is_table(state.validMoves)
			assert.is_true(#state.validMoves >= 1)
		end)

		it("deselects when selecting nil", function()
			local state = GameLogic.createInitialState()
			local piece = GameLogic.getPieceAt(state, 2, 5)
			state = GameLogic.selectPiece(state, piece)
			state = GameLogic.selectPiece(state, nil)
			assert.is_nil(state.selectedPiece)
			assert.are.equal(0, #state.validMoves)
		end)

		it("only allows selecting current player pieces", function()
			local state = GameLogic.createInitialState()
			-- Try to select P2 piece when it's P1's turn
			local piece = GameLogic.getPieceAt(state, 7, 5)
			state = GameLogic.selectPiece(state, piece)
			assert.is_nil(state.selectedPiece)
		end)
	end)

	-- Step 5: Power-aware move calculation tests
	describe("power-aware moves", function()
		describe("diagonal movement flag", function()
			it("includes diagonal moves when piece has canMoveDiagonally flag", function()
				local state = GameLogic.createInitialState()
				local piece = GameLogic.getPieceAt(state, 2, 5)
				piece.canMoveDiagonally = true

				state = GameLogic.selectPiece(state, piece)

				-- Should have diagonal move to row 3, col 6
				local hasDiagonal = false
				for _, move in ipairs(state.validMoves) do
					if move.row == 3 and move.col == 6 then
						hasDiagonal = true
						break
					end
				end
				assert.is_true(hasDiagonal)
			end)

			it("excludes diagonal moves when piece does not have flag", function()
				local state = GameLogic.createInitialState()
				local piece = GameLogic.getPieceAt(state, 2, 5)
				-- No canMoveDiagonally flag

				state = GameLogic.selectPiece(state, piece)

				-- Should NOT have diagonal move to row 3, col 6
				local hasDiagonal = false
				for _, move in ipairs(state.validMoves) do
					if move.row == 3 and move.col == 6 then
						hasDiagonal = true
						break
					end
				end
				assert.is_false(hasDiagonal)
			end)
		end)

		describe("jump proof flag", function()
			it("excludes capture of piece with isJumpProof flag", function()
				local state = GameLogic.createInitialState()
				-- Move P1 piece adjacent to P2
				local attacker = GameLogic.getPieceAt(state, 2, 5)
				attacker.row = 6

				-- Give P2 piece jump_proof flag
				local defender = GameLogic.getPieceAt(state, 7, 5)
				defender.isJumpProof = true

				state = GameLogic.selectPiece(state, attacker)

				-- Should NOT be able to capture the jump proof piece
				local canCapture = false
				for _, move in ipairs(state.validMoves) do
					if move.row == 7 and move.col == 5 then
						canCapture = true
						break
					end
				end
				assert.is_false(canCapture)
			end)

			it("allows capture of piece without isJumpProof flag", function()
				local state = GameLogic.createInitialState()
				-- Move P1 piece adjacent to P2
				local attacker = GameLogic.getPieceAt(state, 2, 5)
				attacker.row = 6

				local defender = GameLogic.getPieceAt(state, 7, 5)
				-- No isJumpProof flag

				state = GameLogic.selectPiece(state, attacker)

				-- Should be able to capture
				local canCapture = false
				for _, move in ipairs(state.validMoves) do
					if move.row == 7 and move.col == 5 then
						canCapture = true
						break
					end
				end
				assert.is_true(canCapture)
			end)
		end)

		describe("invisible flag", function()
			it("reveals invisible piece when it captures", function()
				local state = GameLogic.createInitialState()
				-- Move P1 piece adjacent to P2
				local attacker = GameLogic.getPieceAt(state, 2, 5)
				attacker.row = 6
				attacker.isInvisible = true

				state = GameLogic.movePiece(state, attacker, 7, 5)

				assert.is_false(attacker.isInvisible)
			end)

			it("keeps invisible piece hidden when moving to empty tile", function()
				local state = GameLogic.createInitialState()
				local piece = GameLogic.getPieceAt(state, 2, 5)
				piece.isInvisible = true

				state = GameLogic.movePiece(state, piece, 3, 5)

				assert.is_true(piece.isInvisible)
			end)
		end)
	end)

	describe("overheat mechanic", function()
		local Powers

		setup(function()
			Powers = require("src.shared.powers")
		end)

		it("piece with 9 of same power does not overheat", function()
			local piece = { powers = {} }
			for _ = 1, 9 do
				table.insert(piece.powers, "bomb")
			end
			assert.is_nil(Powers.checkOverheat(piece))
		end)

		it("piece with 10 of same power overheats", function()
			local piece = { powers = {} }
			for _ = 1, 10 do
				table.insert(piece.powers, "bomb")
			end
			assert.are.equal("bomb", Powers.checkOverheat(piece))
		end)

		it("adding power can trigger overheat", function()
			local piece = { powers = {} }
			for _ = 1, 9 do
				Powers.addPower(piece, "bomb")
			end
			assert.is_nil(Powers.checkOverheat(piece))

			Powers.addPower(piece, "bomb")
			assert.are.equal("bomb", Powers.checkOverheat(piece))
		end)

		it("different powers don't contribute to same overheat", function()
			local piece = { powers = {} }
			for _ = 1, 5 do
				Powers.addPower(piece, "bomb")
				Powers.addPower(piece, "move_diagonal")
			end
			-- 5 bombs + 5 move_diagonal = no overheat
			assert.is_nil(Powers.checkOverheat(piece))
		end)

		it("OVERHEAT_THRESHOLD constant is 10", function()
			assert.are.equal(10, Powers.OVERHEAT_THRESHOLD)
		end)
	end)

	describe("destroyed tiles", function()
		describe("state management", function()
			it("createInitialState includes empty destroyedTiles", function()
				local state = GameLogic.createInitialState()
				assert.is_table(state.destroyedTiles)
				assert.are.equal(0, #state.destroyedTiles)
			end)

			it("destroyTile marks tile as destroyed", function()
				local state = GameLogic.createInitialState()
				state = GameLogic.destroyTile(state, 4, 5)
				assert.is_true(GameLogic.isTileDestroyed(state, 4, 5))
			end)

			it("isTileDestroyed returns false for intact tile", function()
				local state = GameLogic.createInitialState()
				assert.is_false(GameLogic.isTileDestroyed(state, 4, 5))
			end)

			it("isTileDestroyed returns true for destroyed tile", function()
				local state = GameLogic.createInitialState()
				state = GameLogic.destroyTile(state, 4, 5)
				assert.is_true(GameLogic.isTileDestroyed(state, 4, 5))
			end)

			it("cannot destroy out-of-bounds tiles", function()
				local state = GameLogic.createInitialState()
				state = GameLogic.destroyTile(state, 0, 0)
				assert.is_false(GameLogic.isTileDestroyed(state, 0, 0))
				state = GameLogic.destroyTile(state, 100, 100)
				assert.is_false(GameLogic.isTileDestroyed(state, 100, 100))
			end)

			it("destroying already-destroyed tile is no-op", function()
				local state = GameLogic.createInitialState()
				state = GameLogic.destroyTile(state, 4, 5)
				state = GameLogic.destroyTile(state, 4, 5) -- Should not error
				assert.is_true(GameLogic.isTileDestroyed(state, 4, 5))
			end)
		end)

		describe("movement validation", function()
			it("cannot move onto destroyed tile", function()
				local state = GameLogic.createInitialState()
				-- Destroy tile at row 3, col 5
				state = GameLogic.destroyTile(state, 3, 5)
				-- Piece at row 2, col 5 should not be able to move to row 3, col 5
				local piece = GameLogic.getPieceAt(state, 2, 5)
				local moves = GameLogic.getValidMoves(state, piece)
				local canMoveToDestroyed = false
				for _, move in ipairs(moves) do
					if move.row == 3 and move.col == 5 then
						canMoveToDestroyed = true
						break
					end
				end
				assert.is_false(canMoveToDestroyed)
			end)

			it("destroyed tiles excluded from valid moves", function()
				local state = GameLogic.createInitialState()
				local piece = GameLogic.getPieceAt(state, 2, 5)
				-- Get moves before destroying
				local movesBefore = GameLogic.getValidMoves(state, piece)
				local countBefore = #movesBefore

				-- Destroy a tile that would be a valid move
				state = GameLogic.destroyTile(state, 3, 5)
				local movesAfter = GameLogic.getValidMoves(state, piece)
				local countAfter = #movesAfter

				-- Should have one fewer valid move
				assert.is_true(countAfter < countBefore)
			end)

			it("isTileDestroyed returns false for out-of-bounds", function()
				local state = GameLogic.createInitialState()
				assert.is_false(GameLogic.isTileDestroyed(state, -1, -1))
				assert.is_false(GameLogic.isTileDestroyed(state, 99, 99))
			end)
		end)
	end)
end)
