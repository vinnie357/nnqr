-- Lovetest tests for game logic
-- Run with: love . --test

local Logic = require("src.logic")

-- Board dimensions tests
function test_board_dimensions()
	assert_equal(10, Logic.BOARD_COLS)
	assert_equal(8, Logic.BOARD_ROWS)
end

-- Position validation tests
function test_valid_position_center()
	assert_true(Logic.isValidPosition(4, 5))
end

function test_valid_position_corners()
	assert_true(Logic.isValidPosition(1, 1))
	assert_true(Logic.isValidPosition(1, 10))
	assert_true(Logic.isValidPosition(8, 1))
	assert_true(Logic.isValidPosition(8, 10))
end

function test_invalid_position_out_of_bounds()
	assert_false(Logic.isValidPosition(0, 5))
	assert_false(Logic.isValidPosition(9, 5))
	assert_false(Logic.isValidPosition(5, 0))
	assert_false(Logic.isValidPosition(5, 11))
end

-- Movement validation tests
function test_valid_move_up()
	assert_true(Logic.isValidMove(5, 5, 4, 5, 1, nil))
end

function test_valid_move_down()
	assert_true(Logic.isValidMove(5, 5, 6, 5, 1, nil))
end

function test_valid_move_left()
	assert_true(Logic.isValidMove(5, 5, 5, 4, 1, nil))
end

function test_valid_move_right()
	assert_true(Logic.isValidMove(5, 5, 5, 6, 1, nil))
end

function test_invalid_move_diagonal()
	assert_false(Logic.isValidMove(5, 5, 6, 6, 1, nil))
end

function test_invalid_move_two_squares()
	assert_false(Logic.isValidMove(5, 5, 7, 5, 1, nil))
end

function test_invalid_move_same_position()
	assert_false(Logic.isValidMove(5, 5, 5, 5, 1, nil))
end

function test_valid_capture_enemy()
	assert_true(Logic.isValidMove(5, 5, 5, 6, 1, 2))
end

function test_invalid_capture_own_piece()
	assert_false(Logic.isValidMove(5, 5, 5, 6, 1, 1))
end

-- Coordinate conversion tests
function test_board_to_screen_origin()
	local x, y = Logic.boardToScreen(1, 1, 0, 0)
	assert_equal(0, x)
	assert_equal(32, y)
end

function test_screen_to_board_roundtrip()
	local offsetX, offsetY = 400, 100
	local origRow, origCol = 4, 5

	local x, y = Logic.boardToScreen(origRow, origCol, offsetX, offsetY)
	local row, col = Logic.screenToBoard(x, y, offsetX, offsetY)

	assert_equal(origRow, row)
	assert_equal(origCol, col)
end

-- Piece creation tests
function test_create_player1_pieces()
	local pieces = Logic.createInitialPieces(1)
	assert_equal(20, #pieces)

	for _, piece in ipairs(pieces) do
		assert_equal(1, piece.player)
		assert_true(piece.row == 1 or piece.row == 2)
	end
end

function test_create_player2_pieces()
	local pieces = Logic.createInitialPieces(2)
	assert_equal(20, #pieces)

	for _, piece in ipairs(pieces) do
		assert_equal(2, piece.player)
		assert_true(piece.row == 7 or piece.row == 8)
	end
end

-- Piece counting tests
function test_count_pieces()
	local pieces = {}
	for i = 1, 5 do
		table.insert(pieces, { player = 1 })
	end
	for i = 1, 3 do
		table.insert(pieces, { player = 2 })
	end

	local p1, p2 = Logic.countPieces(pieces)
	assert_equal(5, p1)
	assert_equal(3, p2)
end

-- Win condition tests
function test_player2_wins_when_no_player1_pieces()
	local pieces = { { player = 2 } }
	assert_equal(2, Logic.checkWinner(pieces))
end

function test_player1_wins_when_no_player2_pieces()
	local pieces = { { player = 1 } }
	assert_equal(1, Logic.checkWinner(pieces))
end

function test_no_winner_when_both_have_pieces()
	local pieces = { { player = 1 }, { player = 2 } }
	assert_nil(Logic.checkWinner(pieces))
end

-- Turn management tests
function test_next_player_from_1()
	assert_equal(2, Logic.nextPlayer(1))
end

function test_next_player_from_2()
	assert_equal(1, Logic.nextPlayer(2))
end

-- Valid moves generation
function test_get_valid_moves_center()
	local function getPieceAt(row, col)
		return nil
	end

	local moves = Logic.getValidMoves(4, 5, 1, getPieceAt)
	assert_equal(4, #moves)
end

function test_get_valid_moves_corner()
	local function getPieceAt(row, col)
		return nil
	end

	local moves = Logic.getValidMoves(1, 1, 1, getPieceAt)
	assert_equal(2, #moves)
end

function test_get_valid_moves_blocked_by_own_piece()
	local function getPieceAt(row, col)
		if row == 4 and col == 5 then
			return { player = 1 }
		end
		return nil
	end

	local moves = Logic.getValidMoves(4, 4, 1, getPieceAt)
	-- Should have 3 moves (up, down, left) but not right (own piece)
	assert_equal(3, #moves)
end
