## board_test.gd — Tests for board.gd (core game rules).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/board_test.gd
extends SceneTree

const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")

func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _init() -> void:
	var fails := [0]

	# --- Constants ---
	_assert(Board.BOARD_COLS == 10, "BOARD_COLS==10", fails)
	_assert(Board.BOARD_ROWS == 8, "BOARD_ROWS==8", fails)

	# --- in_bounds ---
	_assert(Board.in_bounds(1, 1), "in_bounds(1,1)", fails)
	_assert(Board.in_bounds(8, 10), "in_bounds(8,10)", fails)
	_assert(Board.in_bounds(4, 5), "in_bounds(4,5)", fails)
	_assert(not Board.in_bounds(0, 1), "not in_bounds(0,1)", fails)
	_assert(not Board.in_bounds(9, 1), "not in_bounds(9,1)", fails)
	_assert(not Board.in_bounds(1, 0), "not in_bounds(1,0)", fails)
	_assert(not Board.in_bounds(1, 11), "not in_bounds(1,11)", fails)

	# --- create_initial_state ---
	var state = Board.create_initial_state(1)
	_assert(state.pieces.size() == 40, "initial state has 40 pieces", fails)
	_assert(state.current_player == 1, "initial current_player==1", fails)
	_assert(state.turn == 0, "initial turn==0", fails)
	_assert(state.status == "playing", "initial status==playing", fails)
	_assert(state.winner == 0, "initial winner==0", fails)
	_assert(state.seed == 1, "initial seed==1", fails)

	# Count pieces per player
	var p1_count := 0
	var p2_count := 0
	for p in state.pieces:
		if p.player == 1: p1_count += 1
		else: p2_count += 1
	_assert(p1_count == 20, "20 pieces for player 1", fails)
	_assert(p2_count == 20, "20 pieces for player 2", fails)

	# Player 1 on rows 1-2, player 2 on rows 7-8
	for p in state.pieces:
		if p.player == 1:
			_assert(p.row == 1 or p.row == 2, "p1 row in {1,2}: got %d" % p.row, fails)
		else:
			_assert(p.row == 7 or p.row == 8, "p2 row in {7,8}: got %d" % p.row, fails)

	# --- piece_at ---
	var found = Board.piece_at(state, 1, 1)
	_assert(found != null, "piece_at(1,1) found", fails)
	_assert(found.player == 1, "piece_at(1,1) is player 1", fails)
	var empty = Board.piece_at(state, 4, 5)
	_assert(empty == null, "piece_at(4,5) is null (empty)", fails)

	# --- is_destroyed (initially none) ---
	_assert(not Board.is_destroyed(state, 1, 1), "tile (1,1) not destroyed initially", fails)

	# --- can_capture: normal piece is capturable ---
	var attacker = state.pieces[0]  # player 1 piece
	var target = null
	for p in state.pieces:
		if p.player == 2:
			target = p
			break
	_assert(Board.can_capture(state, attacker, target), "normal piece is capturable", fails)

	# --- can_capture: jump-proof piece is NOT capturable ---
	var jp_target = GameState.Piece.new("jp", 2, 5, 5)
	jp_target.is_jump_proof = true
	_assert(not Board.can_capture(state, attacker, jp_target), "jump-proof piece not capturable", fails)

	# --- get_valid_moves: orthogonal only by default ---
	# Player 1 piece at row 2, col 5 (surrounded: row1 has friend, row3 is empty, col4/6 are friends)
	# Easier: create a fresh state, isolate a piece in middle
	var s2 = Board.create_initial_state(1)
	# Find a piece at row 2, col 5 (player 1)
	var p2c5: GameState.Piece = null
	for p in s2.pieces:
		if p.row == 2 and p.col == 5:
			p2c5 = p
			break
	_assert(p2c5 != null, "found piece at row 2 col 5", fails)
	var moves = Board.get_valid_moves(s2, p2c5)
	# From row2,col5: up=row1 (friend), down=row3 (empty), left=row2col4 (friend), right=row2col6 (friend)
	# Only one valid move: row3,col5
	_assert(moves.size() == 1, "piece at (2,5) has 1 valid move (down only), got %d" % moves.size(), fails)
	_assert(moves[0].row == 3 and moves[0].col == 5, "valid move is (3,5)", fails)
	_assert(not moves[0].capture, "move to (3,5) is not a capture", fails)

	# --- get_valid_moves: capture enemy ---
	# Put p1 at row3,col5; p2 at row4,col5 (enemy directly below)
	var s3 = Board.create_initial_state(1)
	# Remove all pieces and place two controlled ones
	s3.pieces.clear()
	var mover = GameState.Piece.new("p1-3-5", 1, 3, 5)
	var enemy = GameState.Piece.new("p2-4-5", 2, 4, 5)
	s3.pieces.append(mover)
	s3.pieces.append(enemy)
	var cap_moves = Board.get_valid_moves(s3, mover)
	var has_capture := false
	for m in cap_moves:
		if m.row == 4 and m.col == 5 and m.capture:
			has_capture = true
	_assert(has_capture, "can capture enemy at (4,5)", fails)

	# --- get_valid_moves: jump-proof enemy is not a valid capture target ---
	var s4 = Board.create_initial_state(1)
	s4.pieces.clear()
	var mover4 = GameState.Piece.new("p1-3-5", 1, 3, 5)
	var jp_enemy = GameState.Piece.new("p2-4-5", 2, 4, 5)
	jp_enemy.is_jump_proof = true
	s4.pieces.append(mover4)
	s4.pieces.append(jp_enemy)
	var jp_moves = Board.get_valid_moves(s4, mover4)
	var no_jp_capture := true
	for m in jp_moves:
		if m.row == 4 and m.col == 5 and m.capture:
			no_jp_capture = false
	_assert(no_jp_capture, "jump-proof enemy not in valid moves", fails)

	# --- get_valid_moves: diagonal power ---
	var s5 = Board.create_initial_state(1)
	s5.pieces.clear()
	var diag_piece = GameState.Piece.new("p1-4-5", 1, 4, 5)
	diag_piece.can_move_diagonally = true
	s5.pieces.append(diag_piece)
	var diag_moves = Board.get_valid_moves(s5, diag_piece)
	# 8 directions from (4,5) all empty -> 8 moves
	_assert(diag_moves.size() == 8, "diagonal piece has 8 moves from center, got %d" % diag_moves.size(), fails)

	# --- get_valid_moves: height climb limit ---
	var s6 = Board.create_initial_state(1)
	s6.pieces.clear()
	var climb_piece = GameState.Piece.new("p1-4-5", 1, 4, 5)
	s6.pieces.append(climb_piece)
	# Set current tile height=1, right tile height=3 (too steep to climb)
	s6.height_map[3][4] = 1  # row=4,col=5 -> index [3][4]
	s6.height_map[3][5] = 3  # row=4,col=6 -> index [3][5]
	var climb_moves = Board.get_valid_moves(s6, climb_piece)
	var can_go_right := false
	for m in climb_moves:
		if m.row == 4 and m.col == 6:
			can_go_right = true
	_assert(not can_go_right, "cannot climb from h=1 to h=3 (climb>1)", fails)

	# --- get_valid_moves: can_climb_any ignores height ---
	var s7 = Board.create_initial_state(1)
	s7.pieces.clear()
	var any_climb = GameState.Piece.new("p1-4-5", 1, 4, 5)
	any_climb.can_climb_any = true
	s7.pieces.append(any_climb)
	s7.height_map[3][4] = 0   # row=4,col=5 h=0
	s7.height_map[3][5] = 4   # row=4,col=6 h=4 (normally too steep)
	var any_climb_moves = Board.get_valid_moves(s7, any_climb)
	var can_climb_steep := false
	for m in any_climb_moves:
		if m.row == 4 and m.col == 6:
			can_climb_steep = true
	_assert(can_climb_steep, "can_climb_any lets piece jump h=0 to h=4", fails)

	# --- get_valid_moves: wrap flag ---
	var s8 = Board.create_initial_state(1)
	s8.pieces.clear()
	var wrap_piece = GameState.Piece.new("p1-1-1", 1, 1, 1)
	wrap_piece.can_wrap = true
	s8.pieces.append(wrap_piece)
	var wrap_moves = Board.get_valid_moves(s8, wrap_piece)
	# From (1,1) with wrap: up->row8,col1  left->row1,col10  right->row1,col2  down->row2,col1
	var has_wrap_up := false
	var has_wrap_left := false
	for m in wrap_moves:
		if m.row == 8 and m.col == 1: has_wrap_up = true
		if m.row == 1 and m.col == 10: has_wrap_left = true
	_assert(has_wrap_up, "wrap: can move from (1,1) up to (8,1)", fails)
	_assert(has_wrap_left, "wrap: can move from (1,1) left to (1,10)", fails)

	# --- destroyed tile blocks movement ---
	var s9 = Board.create_initial_state(1)
	s9.pieces.clear()
	var dp = GameState.Piece.new("p1-4-5", 1, 4, 5)
	s9.pieces.append(dp)
	s9.destroyed_tiles["5,5"] = true  # block (5,5) = row5,col5 below
	var dest_moves = Board.get_valid_moves(s9, dp)
	var can_go_destroyed := false
	for m in dest_moves:
		if m.row == 5 and m.col == 5:
			can_go_destroyed = true
	_assert(not can_go_destroyed, "cannot move to destroyed tile (5,5)", fails)

	# --- check_winner: no winner initially ---
	var sw = Board.create_initial_state(1)
	_assert(Board.check_winner(sw) == 0, "no winner in initial state", fails)

	# --- check_winner: player 2 wins when player 1 has no pieces ---
	var sw2 = Board.create_initial_state(1)
	sw2.pieces.clear()
	var lone_p2 = GameState.Piece.new("p2-5-5", 2, 5, 5)
	sw2.pieces.append(lone_p2)
	_assert(Board.check_winner(sw2) == 2, "player 2 wins when p1 eliminated", fails)

	# --- check_winner: player 1 wins when player 2 has no pieces ---
	var sw3 = Board.create_initial_state(1)
	sw3.pieces.clear()
	var lone_p1 = GameState.Piece.new("p1-5-5", 1, 5, 5)
	sw3.pieces.append(lone_p1)
	_assert(Board.check_winner(sw3) == 1, "player 1 wins when p2 eliminated", fails)

	# --- select_piece: selects own piece (use row 2 col 5 which has 1 valid move: row 3) ---
	var ss = Board.create_initial_state(1)
	var after_select = Board.select_piece(ss, 2, 5)
	_assert(after_select.selected != null, "select_piece sets selected", fails)
	_assert(after_select.selected.row == 2 and after_select.selected.col == 5,
		"selected at (2,5)", fails)
	_assert(after_select.valid_moves.size() > 0, "valid_moves populated after select", fails)

	# --- select_piece: clicking enemy clears selection ---
	var ss2 = Board.create_initial_state(1)
	var after_enemy = Board.select_piece(ss2, 7, 1)
	_assert(after_enemy.selected == null, "selecting enemy clears selection", fails)
	_assert(after_enemy.valid_moves.size() == 0, "valid_moves empty after enemy click", fails)

	# --- select_piece: no-op when not playing ---
	var ss3 = Board.create_initial_state(1)
	ss3.status = "won"
	var after_won = Board.select_piece(ss3, 1, 1)
	_assert(after_won.selected == null, "select_piece no-op when won", fails)

	# --- move_to: moves piece and flips player ---
	var sm = Board.create_initial_state(1)
	sm.pieces.clear()
	var mover_sm = GameState.Piece.new("p1-3-5", 1, 3, 5)
	sm.pieces.append(mover_sm)
	# Select it first
	sm = Board.select_piece(sm, 3, 5)
	sm = Board.move_to(sm, 4, 5)
	_assert(sm.current_player == 2, "move flips to player 2", fails)
	_assert(sm.turn == 1, "move increments turn to 1", fails)
	_assert(sm.selected == null, "selection cleared after move", fails)
	# Piece moved
	var moved = Board.piece_at(sm, 4, 5)
	_assert(moved != null, "piece now at (4,5)", fails)
	_assert(moved.id == "p1-3-5", "same piece id after move", fails)

	# --- move_to: capture removes enemy ---
	var sc = Board.create_initial_state(1)
	sc.pieces.clear()
	var attacker_c = GameState.Piece.new("p1-3-5", 1, 3, 5)
	var victim = GameState.Piece.new("p2-4-5", 2, 4, 5)
	sc.pieces.append(attacker_c)
	sc.pieces.append(victim)
	sc = Board.select_piece(sc, 3, 5)
	sc = Board.move_to(sc, 4, 5)
	_assert(sc.pieces.size() == 1, "capture removes enemy (1 piece left)", fails)
	_assert(sc.pieces[0].player == 1, "remaining piece is player 1", fails)

	# --- move_to: sets winner when last enemy captured ---
	var sw_end = Board.create_initial_state(1)
	sw_end.pieces.clear()
	sw_end.pieces.append(GameState.Piece.new("p1-3-5", 1, 3, 5))
	sw_end.pieces.append(GameState.Piece.new("p2-4-5", 2, 4, 5))
	sw_end = Board.select_piece(sw_end, 3, 5)
	sw_end = Board.move_to(sw_end, 4, 5)
	_assert(sw_end.status == "won", "status becomes won after elimination", fails)
	_assert(sw_end.winner == 1, "winner is player 1", fails)

	# --- move_to: illegal move returns state unchanged ---
	var si = Board.create_initial_state(1)
	si.pieces.clear()
	si.pieces.append(GameState.Piece.new("p1-3-5", 1, 3, 5))
	si = Board.select_piece(si, 3, 5)
	var before_turn = si.turn
	si = Board.move_to(si, 1, 1)  # not a valid move
	_assert(si.turn == before_turn, "illegal move does not increment turn", fails)

	if fails[0] == 0:
		print("OK board")
	else:
		printerr("FAIL board: %d" % fails[0])
	quit(fails[0])
