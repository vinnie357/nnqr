-- Busted tests for game logic
-- Run with: busted spec/

describe("Logic", function()
	local Logic

	setup(function()
		Logic = require("src.logic")
	end)

	describe("board dimensions", function()
		it("has 10 columns", function()
			assert.are.equal(10, Logic.BOARD_COLS)
		end)

		it("has 8 rows", function()
			assert.are.equal(8, Logic.BOARD_ROWS)
		end)
	end)

	describe("isValidPosition", function()
		it("accepts center positions", function()
			assert.is_true(Logic.isValidPosition(4, 5))
		end)

		it("accepts corner positions", function()
			assert.is_true(Logic.isValidPosition(1, 1))
			assert.is_true(Logic.isValidPosition(1, 10))
			assert.is_true(Logic.isValidPosition(8, 1))
			assert.is_true(Logic.isValidPosition(8, 10))
		end)

		it("rejects positions below row 1", function()
			assert.is_false(Logic.isValidPosition(0, 5))
		end)

		it("rejects positions above row 8", function()
			assert.is_false(Logic.isValidPosition(9, 5))
		end)

		it("rejects positions below col 1", function()
			assert.is_false(Logic.isValidPosition(5, 0))
		end)

		it("rejects positions above col 10", function()
			assert.is_false(Logic.isValidPosition(5, 11))
		end)
	end)

	describe("isValidMove", function()
		describe("orthogonal movement", function()
			it("allows moving up one square", function()
				assert.is_true(Logic.isValidMove(5, 5, 4, 5, 1, nil))
			end)

			it("allows moving down one square", function()
				assert.is_true(Logic.isValidMove(5, 5, 6, 5, 1, nil))
			end)

			it("allows moving left one square", function()
				assert.is_true(Logic.isValidMove(5, 5, 5, 4, 1, nil))
			end)

			it("allows moving right one square", function()
				assert.is_true(Logic.isValidMove(5, 5, 5, 6, 1, nil))
			end)
		end)

		describe("invalid moves", function()
			it("rejects diagonal movement", function()
				assert.is_false(Logic.isValidMove(5, 5, 6, 6, 1, nil))
			end)

			it("rejects moving two squares", function()
				assert.is_false(Logic.isValidMove(5, 5, 7, 5, 1, nil))
			end)

			it("rejects staying in place", function()
				assert.is_false(Logic.isValidMove(5, 5, 5, 5, 1, nil))
			end)
		end)

		describe("captures", function()
			it("allows capturing enemy piece", function()
				assert.is_true(Logic.isValidMove(5, 5, 5, 6, 1, 2))
			end)

			it("rejects capturing own piece", function()
				assert.is_false(Logic.isValidMove(5, 5, 5, 6, 1, 1))
			end)
		end)
	end)

	describe("coordinate conversion", function()
		it("converts board to screen at origin", function()
			local x, y = Logic.boardToScreen(1, 1, 0, 0)
			assert.are.equal(0, x)
			assert.are.equal(32, y)
		end)

		it("round-trips screen to board conversion", function()
			local offsetX, offsetY = 400, 100
			local origRow, origCol = 4, 5

			local x, y = Logic.boardToScreen(origRow, origCol, offsetX, offsetY)
			local row, col = Logic.screenToBoard(x, y, offsetX, offsetY)

			assert.are.equal(origRow, row)
			assert.are.equal(origCol, col)
		end)
	end)

	describe("createInitialPieces", function()
		it("creates 20 pieces for player 1", function()
			local pieces = Logic.createInitialPieces(1)
			assert.are.equal(20, #pieces)
		end)

		it("places player 1 pieces in rows 1 and 2", function()
			local pieces = Logic.createInitialPieces(1)
			for _, piece in ipairs(pieces) do
				assert.are.equal(1, piece.player)
				assert.is_true(piece.row == 1 or piece.row == 2)
			end
		end)

		it("creates 20 pieces for player 2", function()
			local pieces = Logic.createInitialPieces(2)
			assert.are.equal(20, #pieces)
		end)

		it("places player 2 pieces in rows 7 and 8", function()
			local pieces = Logic.createInitialPieces(2)
			for _, piece in ipairs(pieces) do
				assert.are.equal(2, piece.player)
				assert.is_true(piece.row == 7 or piece.row == 8)
			end
		end)
	end)

	describe("countPieces", function()
		it("counts pieces correctly", function()
			local pieces = {}
			for i = 1, 5 do
				table.insert(pieces, { player = 1 })
			end
			for i = 1, 3 do
				table.insert(pieces, { player = 2 })
			end

			local p1, p2 = Logic.countPieces(pieces)
			assert.are.equal(5, p1)
			assert.are.equal(3, p2)
		end)
	end)

	describe("checkWinner", function()
		it("returns 2 when player 1 has no pieces", function()
			local pieces = { { player = 2 } }
			assert.are.equal(2, Logic.checkWinner(pieces))
		end)

		it("returns 1 when player 2 has no pieces", function()
			local pieces = { { player = 1 } }
			assert.are.equal(1, Logic.checkWinner(pieces))
		end)

		it("returns nil when both have pieces", function()
			local pieces = { { player = 1 }, { player = 2 } }
			assert.is_nil(Logic.checkWinner(pieces))
		end)
	end)

	describe("nextPlayer", function()
		it("returns 2 when current is 1", function()
			assert.are.equal(2, Logic.nextPlayer(1))
		end)

		it("returns 1 when current is 2", function()
			assert.are.equal(1, Logic.nextPlayer(2))
		end)
	end)

	describe("getValidMoves", function()
		it("returns 4 moves from center", function()
			local function getPieceAt()
				return nil
			end
			local moves = Logic.getValidMoves(4, 5, 1, getPieceAt)
			assert.are.equal(4, #moves)
		end)

		it("returns 2 moves from corner", function()
			local function getPieceAt()
				return nil
			end
			local moves = Logic.getValidMoves(1, 1, 1, getPieceAt)
			assert.are.equal(2, #moves)
		end)

		it("excludes squares with own pieces", function()
			local function getPieceAt(row, col)
				if row == 4 and col == 5 then
					return { player = 1 }
				end
				return nil
			end
			local moves = Logic.getValidMoves(4, 4, 1, getPieceAt)
			assert.are.equal(3, #moves)
		end)
	end)
end)
