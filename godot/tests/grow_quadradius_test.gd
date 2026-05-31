## grow_quadradius_test.gd — Tests for grow_quadradius range extension.
##
## Verifies that _area_pieces, _area_tile_coords, related inline loops,
## and targets.get_target_tiles all expand by 1+L where L is the activating
## piece's grow_quadradius_level (0..3).
##
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/grow_quadradius_test.gd
extends SceneTree

const GameState = preload("res://src/game_state.gd")
const Effects = preload("res://src/powers/effects.gd")
const Targets = preload("res://src/powers/targets.gd")
const Height = preload("res://src/height.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _make_piece(id: String, player: int, row: int, col: int, powers: Array = []) -> GameState.Piece:
	var p := GameState.Piece.new(id, player, row, col)
	p.powers = powers.duplicate()
	return p


func _make_piece_with_level(id: String, player: int, row: int, col: int, level: int, powers: Array = []) -> GameState.Piece:
	var p := _make_piece(id, player, row, col, powers)
	if level > 0:
		p.set_meta("grow_quadradius_level", level)
	return p


func _empty_state() -> GameState:
	var s := GameState.new()
	s.pieces = []
	s.height_map = Height.create_height_map(8, 10, 0)
	s.destroyed_tiles = {}
	s.orbs = []
	s.seed = 42
	s.turn = 1
	return s


func _find_piece(state: GameState, id: String) -> GameState.Piece:
	for p in state.pieces:
		if p.id == id:
			return p
	return null


func _init() -> void:
	var fails := [0]

	# -------------------------------------------------------------------------
	# SECTION 1: _area_tile_coords radial — Chebyshev distance 1+L
	# -------------------------------------------------------------------------

	# L=0 baseline: exactly 8 surrounding tiles (3x3 minus center), caster at (4,5)
	var s0 := _empty_state()
	var p_l0 := _make_piece_with_level("c0", 1, 4, 5, 0, ["destroy_radial"])
	s0.pieces = [p_l0]
	var s0_after = Effects.new().activate_destroy_radial(s0, p_l0)
	# Caster at (4,5): surrounding pieces at (3,4),(3,5),(3,6),(4,4),(4,6),(5,4),(5,5),(5,6) = 8 tiles
	# Place enemies at each of those 8 tiles and verify all are removed
	var s0_full := _empty_state()
	var caster0 := _make_piece_with_level("caster0", 1, 4, 5, 0, ["destroy_radial"])
	var surround_coords := [
		[3,4],[3,5],[3,6],[4,4],[4,6],[5,4],[5,5],[5,6]
	]
	s0_full.pieces = [caster0]
	for i in range(surround_coords.size()):
		var rc = surround_coords[i]
		s0_full.pieces.append(_make_piece("e%d" % i, 2, rc[0], rc[1]))
	# Add a far enemy that should survive
	s0_full.pieces.append(_make_piece("far0", 2, 1, 1))
	var s0_full_after = Effects.new().activate_destroy_radial(s0_full, caster0)
	var s0_ids := []
	for p in s0_full_after.pieces:
		s0_ids.append(p.id)
	_assert(s0_ids.has("caster0"), "L0 radial: caster survives", fails)
	for i in range(surround_coords.size()):
		_assert(not s0_ids.has("e%d" % i), "L0 radial: surrounding[%d] removed" % i, fails)
	_assert(s0_ids.has("far0"), "L0 radial: far enemy survives", fails)

	# L=1 radial: 5x5 minus center = 24 tiles. Enemy at distance 2 row/col offset should be hit.
	var s1 := _empty_state()
	var p_l1 := _make_piece_with_level("caster1", 1, 4, 5, 1, ["destroy_radial"])
	var e_d2 := _make_piece("e_d2", 2, 4, 7)  # 2 cols away — inside L=1 range (dist 2)
	var e_far1 := _make_piece("far1", 2, 1, 1)  # far — outside
	s1.pieces = [p_l1, e_d2, e_far1]
	var s1_after = Effects.new().activate_destroy_radial(s1, p_l1)
	var s1_ids := []
	for p in s1_after.pieces:
		s1_ids.append(p.id)
	_assert(s1_ids.has("caster1"), "L1 radial: caster survives", fails)
	_assert(not s1_ids.has("e_d2"), "L1 radial: enemy 2 cols away removed", fails)
	_assert(s1_ids.has("far1"), "L1 radial: far enemy survives", fails)

	# L=1: count tiles in 5x5 minus center = 24 at interior position (4,5)
	var s1_tile_state := _empty_state()
	var p_l1_tile := _make_piece_with_level("ct1", 1, 4, 5, 1)
	s1_tile_state.pieces = [p_l1_tile]
	# Place enemies filling all possible tiles so we can count how many were hit
	var s1_count_state := _empty_state()
	var caster1_count := _make_piece_with_level("caster1c", 1, 4, 5, 1, ["destroy_radial"])
	s1_count_state.pieces = [caster1_count]
	for r in range(1, 9):
		for c in range(1, 11):
			if r == 4 and c == 5:
				continue  # skip caster position
			s1_count_state.pieces.append(_make_piece("ec_%d_%d" % [r, c], 2, r, c))
	var s1_count_after = Effects.new().activate_destroy_radial(s1_count_state, caster1_count)
	# Count surviving non-caster pieces (those outside 5x5 area)
	var s1_survivors := 0
	for p in s1_count_after.pieces:
		if p.id != "caster1c":
			s1_survivors += 1
	# Board is 10x8=80 tiles, minus caster tile = 79, minus 24 hit = 55 survive
	_assert(s1_survivors == 55, "L1 radial: 24 tiles hit (55 survivors), got %d" % s1_survivors, fails)

	# L=2: count tiles in 7x7 minus center = 48
	var s2_count_state := _empty_state()
	var caster2_count := _make_piece_with_level("caster2c", 1, 4, 5, 2, ["destroy_radial"])
	s2_count_state.pieces = [caster2_count]
	for r in range(1, 9):
		for c in range(1, 11):
			if r == 4 and c == 5:
				continue
			s2_count_state.pieces.append(_make_piece("ec2_%d_%d" % [r, c], 2, r, c))
	var s2_count_after = Effects.new().activate_destroy_radial(s2_count_state, caster2_count)
	var s2_survivors := 0
	for p in s2_count_after.pieces:
		if p.id != "caster2c":
			s2_survivors += 1
	# 7x7 minus center = 48, but clamped at board edges.
	# Caster at (4,5): rows 2-6 (5 rows), cols 3-7 (5 cols) fully inside (board 1..8, 1..10)
	# Actual 7x7 extent: rows 1-7 (7 rows), cols 2-8 (7 cols) = 49 tiles minus center = 48
	# All 48 within board (row 1..7 <= 8, col 2..8 <= 10), so survivors = 79 - 48 = 31
	_assert(s2_survivors == 31, "L2 radial: 48 tiles hit (31 survivors), got %d" % s2_survivors, fails)

	# -------------------------------------------------------------------------
	# SECTION 2: _area_tile_coords radial — board-edge clamping near a corner
	# -------------------------------------------------------------------------
	# Piece at corner (1,1) with L=2: 7x7 extends to rows -1..3, cols -1..3
	# Clamped to rows 1..3, cols 1..3 = 9 tiles minus center = 8
	var s_corner := _empty_state()
	var p_corner := _make_piece_with_level("pcorner", 1, 1, 1, 2, ["destroy_radial"])
	s_corner.pieces = [p_corner]
	for r in range(1, 9):
		for c in range(1, 11):
			if r == 1 and c == 1:
				continue
			s_corner.pieces.append(_make_piece("ec_corner_%d_%d" % [r, c], 2, r, c))
	var s_corner_after = Effects.new().activate_destroy_radial(s_corner, p_corner)
	var corner_survivors := 0
	for p in s_corner_after.pieces:
		if p.id != "pcorner":
			corner_survivors += 1
	# Caster at (1,1), L=2 → dist=3. Rows 1..min(8,4)=1..4, cols 1..min(10,4)=1..4
	# = 4x4=16 tiles minus center = 15 tiles hit; 79-15=64 survive.
	# Confirms clamping: no out-of-bounds tiles (row<1 or col<1 never appended).
	_assert(corner_survivors == 64, "L2 corner clamping: 15 tiles hit (64 survivors), got %d" % corner_survivors, fails)

	# Clamped tiles are in bounds: row must be in [1,8], col in [1,10]
	var s_corner_check := _empty_state()
	var p_corner_check := _make_piece_with_level("pcc", 1, 1, 1, 1)
	s_corner_check.pieces = [p_corner_check]
	# Make sure no out-of-bounds tile coord is returned by activating on a state
	# where only in-bounds pieces exist and checking that activation doesn't error
	var p_far := _make_piece("farcc", 2, 8, 10)
	s_corner_check.pieces.append(p_far)
	var p_near := _make_piece("nearcc", 2, 2, 2)
	s_corner_check.pieces.append(p_near)
	s_corner_check.pieces[0].powers = ["destroy_radial"]
	var s_corner_check_after = Effects.new().activate_destroy_radial(s_corner_check, s_corner_check.pieces[0])
	var cc_ids := []
	for p in s_corner_check_after.pieces:
		cc_ids.append(p.id)
	_assert(not cc_ids.has("nearcc"), "L1 corner (1,1): piece at (2,2) removed", fails)
	_assert(cc_ids.has("farcc"), "L1 corner (1,1): piece at (8,10) survives", fails)

	# -------------------------------------------------------------------------
	# SECTION 3: row area — band of 2L+1 rows
	# -------------------------------------------------------------------------
	# L=0: only row r affected (current behavior)
	var s_row0 := _empty_state()
	var p_row0 := _make_piece_with_level("crow0", 1, 3, 5, 0, ["destroy_row"])
	var e_row0_same := _make_piece("erow0_same", 2, 3, 2)
	var e_row0_adj := _make_piece("erow0_adj", 2, 4, 2)  # adjacent row — should survive at L=0
	s_row0.pieces = [p_row0, e_row0_same, e_row0_adj]
	var s_row0_after = Effects.new().activate_destroy_row(s_row0, p_row0)
	var row0_ids := []
	for p in s_row0_after.pieces:
		row0_ids.append(p.id)
	_assert(not row0_ids.has("erow0_same"), "L0 row: same-row enemy removed", fails)
	_assert(row0_ids.has("erow0_adj"), "L0 row: adjacent-row enemy survives", fails)
	_assert(row0_ids.has("crow0"), "L0 row: caster survives", fails)

	# L=1: rows r-1, r, r+1 all cleared (3 rows)
	var s_row1 := _empty_state()
	var p_row1 := _make_piece_with_level("crow1", 1, 4, 5, 1, ["destroy_row"])
	var e_r3 := _make_piece("e_r3", 2, 3, 2)   # row-1
	var e_r4 := _make_piece("e_r4", 2, 4, 2)   # same row
	var e_r5 := _make_piece("e_r5", 2, 5, 2)   # row+1
	var e_r6 := _make_piece("e_r6", 2, 6, 2)   # row+2, should survive
	s_row1.pieces = [p_row1, e_r3, e_r4, e_r5, e_r6]
	var s_row1_after = Effects.new().activate_destroy_row(s_row1, p_row1)
	var row1_ids := []
	for p in s_row1_after.pieces:
		row1_ids.append(p.id)
	_assert(row1_ids.has("crow1"), "L1 row: caster survives", fails)
	_assert(not row1_ids.has("e_r3"), "L1 row: row-1 enemy removed", fails)
	_assert(not row1_ids.has("e_r4"), "L1 row: same-row enemy removed", fails)
	_assert(not row1_ids.has("e_r5"), "L1 row: row+1 enemy removed", fails)
	_assert(row1_ids.has("e_r6"), "L1 row: row+2 enemy survives", fails)

	# L=2: rows r-2..r+2 (5 rows)
	var s_row2 := _empty_state()
	var p_row2 := _make_piece_with_level("crow2", 1, 4, 5, 2, ["destroy_row"])
	var e_r2 := _make_piece("e_r2", 2, 2, 2)   # row-2
	var e_r4b := _make_piece("e_r4b", 2, 4, 2)  # same row
	var e_r6b := _make_piece("e_r6b", 2, 6, 2)  # row+2
	var e_r7 := _make_piece("e_r7", 2, 7, 2)    # row+3, should survive
	s_row2.pieces = [p_row2, e_r2, e_r4b, e_r6b, e_r7]
	var s_row2_after = Effects.new().activate_destroy_row(s_row2, p_row2)
	var row2_ids := []
	for p in s_row2_after.pieces:
		row2_ids.append(p.id)
	_assert(not row2_ids.has("e_r2"), "L2 row: row-2 enemy removed", fails)
	_assert(not row2_ids.has("e_r4b"), "L2 row: same-row enemy removed", fails)
	_assert(not row2_ids.has("e_r6b"), "L2 row: row+2 enemy removed", fails)
	_assert(row2_ids.has("e_r7"), "L2 row: row+3 enemy survives", fails)

	# -------------------------------------------------------------------------
	# SECTION 4: column area — band of 2L+1 columns
	# -------------------------------------------------------------------------
	# L=0: only col c affected
	var s_col0 := _empty_state()
	var p_col0 := _make_piece_with_level("ccol0", 1, 3, 5, 0, ["destroy_column"])
	var e_col0_same := _make_piece("ecol0_same", 2, 7, 5)
	var e_col0_adj := _make_piece("ecol0_adj", 2, 7, 6)  # adjacent col — survives
	s_col0.pieces = [p_col0, e_col0_same, e_col0_adj]
	var s_col0_after = Effects.new().activate_destroy_column(s_col0, p_col0)
	var col0_ids := []
	for p in s_col0_after.pieces:
		col0_ids.append(p.id)
	_assert(not col0_ids.has("ecol0_same"), "L0 column: same-col enemy removed", fails)
	_assert(col0_ids.has("ecol0_adj"), "L0 column: adjacent-col enemy survives", fails)

	# L=1: cols c-1..c+1 (3 cols)
	var s_col1 := _empty_state()
	var p_col1 := _make_piece_with_level("ccol1", 1, 3, 5, 1, ["destroy_column"])
	var e_c4 := _make_piece("e_c4", 2, 7, 4)   # col-1
	var e_c5 := _make_piece("e_c5", 2, 7, 5)   # same col
	var e_c6 := _make_piece("e_c6", 2, 7, 6)   # col+1
	var e_c7 := _make_piece("e_c7", 2, 7, 7)   # col+2 — survives
	s_col1.pieces = [p_col1, e_c4, e_c5, e_c6, e_c7]
	var s_col1_after = Effects.new().activate_destroy_column(s_col1, p_col1)
	var col1_ids := []
	for p in s_col1_after.pieces:
		col1_ids.append(p.id)
	_assert(col1_ids.has("ccol1"), "L1 column: caster survives", fails)
	_assert(not col1_ids.has("e_c4"), "L1 column: col-1 enemy removed", fails)
	_assert(not col1_ids.has("e_c5"), "L1 column: same-col enemy removed", fails)
	_assert(not col1_ids.has("e_c6"), "L1 column: col+1 enemy removed", fails)
	_assert(col1_ids.has("e_c7"), "L1 column: col+2 enemy survives", fails)

	# -------------------------------------------------------------------------
	# SECTION 5: Integration — destroy_radial with grow_level=1 hits distance-2 enemy
	# -------------------------------------------------------------------------
	var s_int := _empty_state()
	var p_int := _make_piece_with_level("cint", 1, 4, 5, 1, ["destroy_radial"])
	var e_near_int := _make_piece("near_int", 2, 4, 7)  # 2 cols away — within L=1 reach
	var e_far_int := _make_piece("far_int", 2, 4, 8)    # 3 cols away — outside L=1 reach
	s_int.pieces = [p_int, e_near_int, e_far_int]
	var s_int_after = Effects.new().activate_destroy_radial(s_int, p_int)
	var int_ids := []
	for p in s_int_after.pieces:
		int_ids.append(p.id)
	_assert(int_ids.has("cint"), "integration: caster survives", fails)
	_assert(not int_ids.has("near_int"), "integration: enemy 2 away destroyed at L=1", fails)
	_assert(int_ids.has("far_int"), "integration: enemy 3 away survives at L=1", fails)

	# -------------------------------------------------------------------------
	# SECTION 6: kamikaze_radial inline loop uses grow level
	# -------------------------------------------------------------------------
	var s_kami := _empty_state()
	var p_kami := _make_piece_with_level("ckami", 1, 4, 5, 1, ["kamikaze_radial"])
	var e_kami_close := _make_piece("kami_close", 2, 4, 7)  # 2 cols away
	var e_kami_far := _make_piece("kami_far", 2, 4, 8)      # 3 cols away — survives
	s_kami.pieces = [p_kami, e_kami_close, e_kami_far]
	var s_kami_after = Effects.new().activate_kamikaze_radial(s_kami, p_kami)
	var kami_ids := []
	for p in s_kami_after.pieces:
		kami_ids.append(p.id)
	_assert(not kami_ids.has("ckami"), "L1 kamikaze_radial: caster destroyed", fails)
	_assert(not kami_ids.has("kami_close"), "L1 kamikaze_radial: close enemy destroyed", fails)
	_assert(kami_ids.has("kami_far"), "L1 kamikaze_radial: far enemy survives", fails)

	# -------------------------------------------------------------------------
	# SECTION 7: targets.get_target_tiles for area powers returns expanded set
	# -------------------------------------------------------------------------
	# For a non-targeted area power like destroy_radial: currently returns []
	# After fix: should return the area tiles so UI/AI can highlight them
	var s_tgt := _empty_state()
	var p_tgt_l0 := _make_piece_with_level("ptgt0", 1, 4, 5, 0, ["destroy_radial"])
	s_tgt.pieces = [p_tgt_l0]
	var tiles_l0 = Targets.get_area_tiles(s_tgt, p_tgt_l0, "radial")
	_assert(tiles_l0.size() == 8, "targets L0 radial: 8 tiles, got %d" % tiles_l0.size(), fails)

	var p_tgt_l1 := _make_piece_with_level("ptgt1", 1, 4, 5, 1, ["destroy_radial"])
	s_tgt.pieces = [p_tgt_l1]
	var tiles_l1 = Targets.get_area_tiles(s_tgt, p_tgt_l1, "radial")
	_assert(tiles_l1.size() == 24, "targets L1 radial: 24 tiles, got %d" % tiles_l1.size(), fails)

	var p_tgt_l2 := _make_piece_with_level("ptgt2", 1, 4, 5, 2, ["destroy_radial"])
	s_tgt.pieces = [p_tgt_l2]
	var tiles_l2 = Targets.get_area_tiles(s_tgt, p_tgt_l2, "radial")
	_assert(tiles_l2.size() == 48, "targets L2 radial: 48 tiles, got %d" % tiles_l2.size(), fails)

	# Row: L=1 affects 3 rows; L=0 affects only row r
	var s_tgt_row := _empty_state()
	s_tgt_row.pieces = [_make_piece_with_level("ptgt_row0", 1, 4, 5, 0)]
	var row_tiles_l0 = Targets.get_area_tiles(s_tgt_row, s_tgt_row.pieces[0], "row")
	# Row r=4, 10 cols, minus own col (5) = 9 tiles
	_assert(row_tiles_l0.size() == 9, "targets L0 row: 9 tiles, got %d" % row_tiles_l0.size(), fails)

	var s_tgt_row1 := _empty_state()
	s_tgt_row1.pieces = [_make_piece_with_level("ptgt_row1", 1, 4, 5, 1)]
	var row_tiles_l1 = Targets.get_area_tiles(s_tgt_row1, s_tgt_row1.pieces[0], "row")
	# Rows 3,4,5 x 10 cols = 30 tiles minus own tile (4,5) = 29
	_assert(row_tiles_l1.size() == 29, "targets L1 row: 29 tiles, got %d" % row_tiles_l1.size(), fails)

	if fails[0] == 0:
		print("OK grow_quadradius")
	else:
		printerr("FAIL grow_quadradius: %d" % fails[0])
	quit(fails[0])
