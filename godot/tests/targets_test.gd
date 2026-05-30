## targets_test.gd — Tests for powers/targets.gd (target resolution).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/targets_test.gd
extends SceneTree

const GameState = preload("res://src/game_state.gd")
const Targets = preload("res://src/powers/targets.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _make_piece(id: String, player: int, row: int, col: int, powers: Array = []) -> GameState.Piece:
	var p := GameState.Piece.new(id, player, row, col)
	p.powers = powers.duplicate()
	return p


func _empty_state() -> GameState:
	var s := GameState.new()
	s.pieces = []
	s.height_map = []
	for _r in range(8):
		var row_arr: Array = []
		row_arr.resize(10)
		row_arr.fill(0)
		s.height_map.append(row_arr)
	s.destroyed_tiles = {}
	s.orbs = []
	s.seed = 42
	s.turn = 1
	return s


func _init() -> void:
	var fails := [0]

	# -------------------------------------------------------------------------
	# needs_target — targeted set
	# -------------------------------------------------------------------------
	var targeted := ["raise_tile", "lower_tile", "switcheroo", "recruit",
		"multiply", "refurb", "centerpult", "hotspot"]
	for id in targeted:
		_assert(Targets.needs_target(id), "needs_target(%s)==true" % id, fails)

	# powers that fire immediately should NOT need a target
	var immediate := ["destroy_row", "destroy_column", "bomb", "relocate",
		"jump_proof", "move_diagonal", "climb_tile", "double_powers",
		"orbic_rehash", "destroy_radial", "kamikaze_radial"]
	for id in immediate:
		_assert(not Targets.needs_target(id), "needs_target(%s)==false" % id, fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — raise_tile / lower_tile
	# -------------------------------------------------------------------------
	var s1 := _empty_state()
	var p1 := _make_piece("p1", 1, 4, 5)
	s1.pieces = [p1]
	var rt_tiles = Targets.get_target_tiles(s1, p1, "raise_tile")
	_assert(rt_tiles.size() == 4, "raise_tile: 4 adj tiles from center, got %d" % rt_tiles.size(), fails)
	var _has_up := false
	var _has_dn := false
	var _has_lt := false
	var _has_rt := false
	for t in rt_tiles:
		if t.row == 3 and t.col == 5:
			_has_up = true
		if t.row == 5 and t.col == 5:
			_has_dn = true
		if t.row == 4 and t.col == 4:
			_has_lt = true
		if t.row == 4 and t.col == 6:
			_has_rt = true
	_assert(_has_up, "raise_tile: up neighbour (3,5)", fails)
	_assert(_has_dn, "raise_tile: down neighbour (5,5)", fails)
	_assert(_has_lt, "raise_tile: left neighbour (4,4)", fails)
	_assert(_has_rt, "raise_tile: right neighbour (4,6)", fails)

	# Corner clip — piece at (1,1): only down and right in bounds
	var s_corner := _empty_state()
	var p_corner := _make_piece("pc", 1, 1, 1)
	s_corner.pieces = [p_corner]
	var corner_tiles = Targets.get_target_tiles(s_corner, p_corner, "raise_tile")
	_assert(corner_tiles.size() == 2, "raise_tile corner: 2 tiles, got %d" % corner_tiles.size(), fails)

	# Destroyed tile excluded
	var s_dst := _empty_state()
	var p_dst := _make_piece("pd", 1, 4, 5)
	s_dst.pieces = [p_dst]
	s_dst.destroyed_tiles["4,6"] = true
	var dst_tiles = Targets.get_target_tiles(s_dst, p_dst, "raise_tile")
	_assert(dst_tiles.size() == 3, "raise_tile: destroyed tile excluded, got %d" % dst_tiles.size(), fails)
	var _has_destroyed := false
	for t in dst_tiles:
		if t.row == 4 and t.col == 6:
			_has_destroyed = true
	_assert(not _has_destroyed, "raise_tile: destroyed (4,6) not in targets", fails)

	# lower_tile same logic as raise_tile
	var lt_tiles = Targets.get_target_tiles(s1, p1, "lower_tile")
	_assert(lt_tiles.size() == 4, "lower_tile: 4 adj tiles from center, got %d" % lt_tiles.size(), fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — switcheroo (adjacent tile occupied by any piece)
	# -------------------------------------------------------------------------
	var s_sw := _empty_state()
	var p_sw := _make_piece("sw", 1, 4, 5)
	var enemy_sw := _make_piece("e1", 2, 4, 6)
	var ally_sw := _make_piece("a1", 1, 3, 5)
	s_sw.pieces = [p_sw, enemy_sw, ally_sw]
	var sw_tiles = Targets.get_target_tiles(s_sw, p_sw, "switcheroo")
	_assert(sw_tiles.size() == 2, "switcheroo: 2 occupied adj tiles, got %d" % sw_tiles.size(), fails)
	var _sw_has_enemy := false
	var _sw_has_ally := false
	for t in sw_tiles:
		if t.row == 4 and t.col == 6:
			_sw_has_enemy = true
		if t.row == 3 and t.col == 5:
			_sw_has_ally = true
	_assert(_sw_has_enemy, "switcheroo: includes enemy", fails)
	_assert(_sw_has_ally, "switcheroo: includes ally", fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — recruit (8-dir adjacent enemy pieces only)
	# -------------------------------------------------------------------------
	var s_rec := _empty_state()
	var p_rec := _make_piece("rec", 1, 4, 5)
	var enemy_rec := _make_piece("er", 2, 4, 6)
	var ally_rec := _make_piece("ar", 1, 4, 4)
	var diag_enemy := _make_piece("de", 2, 3, 4)
	s_rec.pieces = [p_rec, enemy_rec, ally_rec, diag_enemy]
	var rec_tiles = Targets.get_target_tiles(s_rec, p_rec, "recruit")
	_assert(rec_tiles.size() == 2, "recruit: 2 enemy tiles, got %d" % rec_tiles.size(), fails)
	var _rec_has_enemy := false
	var _rec_has_ally := false
	var _rec_has_diag := false
	for t in rec_tiles:
		if t.row == 4 and t.col == 6:
			_rec_has_enemy = true
		if t.row == 4 and t.col == 4:
			_rec_has_ally = true
		if t.row == 3 and t.col == 4:
			_rec_has_diag = true
	_assert(_rec_has_enemy, "recruit: enemy at (4,6) included", fails)
	_assert(not _rec_has_ally, "recruit: ally at (4,4) excluded", fails)
	_assert(_rec_has_diag, "recruit: diagonal enemy at (3,4) included", fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — multiply (adjacent empty non-destroyed tiles)
	# -------------------------------------------------------------------------
	var s_mul := _empty_state()
	var p_mul := _make_piece("mul", 1, 4, 5)
	var blocker := _make_piece("blk", 2, 4, 6)
	s_mul.pieces = [p_mul, blocker]
	s_mul.destroyed_tiles["3,5"] = true
	var mul_tiles = Targets.get_target_tiles(s_mul, p_mul, "multiply")
	_assert(mul_tiles.size() == 2, "multiply: 2 valid targets, got %d" % mul_tiles.size(), fails)
	var _mul_has_blocked := false
	var _mul_has_dst := false
	for t in mul_tiles:
		if t.row == 4 and t.col == 6:
			_mul_has_blocked = true
		if t.row == 3 and t.col == 5:
			_mul_has_dst = true
	_assert(not _mul_has_blocked, "multiply: occupied tile excluded", fails)
	_assert(not _mul_has_dst, "multiply: destroyed tile excluded", fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — refurb (adjacent destroyed tiles only)
	# -------------------------------------------------------------------------
	var s_rfb := _empty_state()
	var p_rfb := _make_piece("rfb", 1, 4, 5)
	s_rfb.pieces = [p_rfb]
	s_rfb.destroyed_tiles["4,6"] = true
	s_rfb.destroyed_tiles["5,5"] = true
	var rfb_tiles = Targets.get_target_tiles(s_rfb, p_rfb, "refurb")
	_assert(rfb_tiles.size() == 2, "refurb: 2 destroyed adj tiles, got %d" % rfb_tiles.size(), fails)
	var _rfb_has_intact := false
	for t in rfb_tiles:
		if t.row == 3 and t.col == 5:
			_rfb_has_intact = true
	_assert(not _rfb_has_intact, "refurb: intact tile (3,5) not in targets", fails)

	var s_rfb2 := _empty_state()
	var p_rfb2 := _make_piece("rf2", 1, 4, 5)
	s_rfb2.pieces = [p_rfb2]
	var rfb2_tiles = Targets.get_target_tiles(s_rfb2, p_rfb2, "refurb")
	_assert(rfb2_tiles.size() == 0, "refurb: 0 targets when nothing destroyed", fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — centerpult (tiles in valid 2x2 blocks)
	# -------------------------------------------------------------------------
	var s_cp := _empty_state()
	var p_cp := _make_piece("cp", 1, 5, 5)
	var cp1 := _make_piece("c1", 2, 2, 2)
	var cp2 := _make_piece("c2", 2, 2, 3)
	var cp3 := _make_piece("c3", 2, 3, 2)
	var cp4 := _make_piece("c4", 2, 3, 3)
	s_cp.pieces = [p_cp, cp1, cp2, cp3, cp4]
	var cp_tiles = Targets.get_target_tiles(s_cp, p_cp, "centerpult")
	_assert(cp_tiles.size() == 4, "centerpult: 4 tiles in 2x2 block, got %d" % cp_tiles.size(), fails)

	# -------------------------------------------------------------------------
	# power_counts
	# -------------------------------------------------------------------------
	var p_pc := _make_piece("pc2", 1, 1, 1, ["bomb", "destroy_row", "bomb", "bomb"])
	var counts := Targets.power_counts(p_pc)
	_assert(counts.get("bomb", 0) == 3, "power_counts: bomb x3, got %d" % counts.get("bomb", 0), fails)
	_assert(counts.get("destroy_row", 0) == 1, "power_counts: destroy_row x1", fails)

	var p_empty_pc := _make_piece("emp", 1, 1, 1)
	_assert(Targets.power_counts(p_empty_pc).size() == 0, "power_counts: empty for no powers", fails)

	# -------------------------------------------------------------------------
	# overheat_power — 9 copies: no overheat; 10 copies: overheats
	# -------------------------------------------------------------------------
	var p_9 := _make_piece("p9", 1, 1, 1)
	p_9.powers = []
	for _i in range(9):
		p_9.powers.append("bomb")
	_assert(Targets.overheat_power(p_9) == "", "overheat: 9 bombs = no overheat", fails)

	var p_10 := _make_piece("p10", 1, 1, 1)
	p_10.powers = []
	for _i in range(10):
		p_10.powers.append("bomb")
	_assert(Targets.overheat_power(p_10) == "bomb", "overheat: 10 bombs = overheat bomb", fails)

	var p_none := _make_piece("pn", 1, 1, 1)
	_assert(Targets.overheat_power(p_none) == "", "overheat: empty powers = no overheat", fails)

	# -------------------------------------------------------------------------
	# get_target_tiles — unknown power returns empty
	# -------------------------------------------------------------------------
	var s_unk := _empty_state()
	var p_unk := _make_piece("pu", 1, 4, 5)
	s_unk.pieces = [p_unk]
	_assert(Targets.get_target_tiles(s_unk, p_unk, "destroy_row").size() == 0,
		"destroy_row returns empty (immediate power)", fails)
	_assert(Targets.get_target_tiles(s_unk, p_unk, "nonexistent_xyz").size() == 0,
		"unknown power returns empty", fails)

	if fails[0] == 0:
		print("OK targets")
	else:
		printerr("FAIL targets: %d" % fails[0])
	quit(fails[0])
