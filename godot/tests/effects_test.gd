## effects_test.gd — Spot-check representative effects from powers/effects.gd.
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/effects_test.gd
extends SceneTree

const GameState = preload("res://src/game_state.gd")
const Effects = preload("res://src/powers/effects.gd")
const Height = preload("res://src/height.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _make_piece(id: String, player: int, row: int, col: int, powers: Array = []) -> GameState.Piece:
	var p := GameState.Piece.new(id, player, row, col)
	p.powers = powers.duplicate()
	return p


func _empty_state(seed: int = 42, turn: int = 1) -> GameState:
	var s := GameState.new()
	s.pieces = []
	s.height_map = Height.create_height_map(8, 10, 0)
	s.destroyed_tiles = {}
	s.orbs = []
	s.seed = seed
	s.turn = turn
	return s


func _find_piece(state: GameState, id: String) -> GameState.Piece:
	for p in state.pieces:
		if p.id == id:
			return p
	return null


func _init() -> void:
	var fails := [0]

	# -------------------------------------------------------------------------
	# DESTROY SHAPE: destroy_row removes row pieces, caster survives, consumes
	# -------------------------------------------------------------------------
	var s_dr := _empty_state()
	var p_dr := _make_piece("caster", 1, 3, 5, ["destroy_row"])
	var e1 := _make_piece("e1", 2, 3, 2)
	var e2 := _make_piece("e2", 2, 3, 8)
	var bystander := _make_piece("by", 2, 5, 5)
	s_dr.pieces = [p_dr, e1, e2, bystander]
	var s_dr_after = Effects.new().activate_destroy_row(s_dr, p_dr)
	var dr_ids := []
	for p in s_dr_after.pieces:
		dr_ids.append(p.id)
	_assert(dr_ids.has("caster"), "destroy_row: caster survives", fails)
	_assert(not dr_ids.has("e1"), "destroy_row: e1 removed", fails)
	_assert(not dr_ids.has("e2"), "destroy_row: e2 removed", fails)
	_assert(dr_ids.has("by"), "destroy_row: bystander on diff row survives", fails)
	var caster_after = _find_piece(s_dr_after, "caster")
	_assert(not caster_after.powers.has("destroy_row"), "destroy_row: power consumed", fails)

	# Immutability: original state not mutated
	_assert(s_dr.pieces.size() == 4, "destroy_row: input state not mutated", fails)

	# -------------------------------------------------------------------------
	# DESTROY SHAPE: destroy_column
	# -------------------------------------------------------------------------
	var s_dc := _empty_state()
	var p_dc := _make_piece("cdc", 1, 3, 5, ["destroy_column"])
	var ec1 := _make_piece("ec1", 2, 1, 5)
	var ec2 := _make_piece("ec2", 2, 7, 5)
	var byc := _make_piece("byc", 2, 3, 2)
	s_dc.pieces = [p_dc, ec1, ec2, byc]
	var s_dc_after = Effects.new().activate_destroy_column(s_dc, p_dc)
	var dc_ids := []
	for p in s_dc_after.pieces:
		dc_ids.append(p.id)
	_assert(dc_ids.has("cdc"), "destroy_column: caster survives", fails)
	_assert(not dc_ids.has("ec1"), "destroy_column: ec1 removed", fails)
	_assert(not dc_ids.has("ec2"), "destroy_column: ec2 removed", fails)
	_assert(dc_ids.has("byc"), "destroy_column: bystander survives", fails)

	# -------------------------------------------------------------------------
	# DESTROY SHAPE: destroy_radial — 3x3 area, no terrain change
	# -------------------------------------------------------------------------
	var s_drad := _empty_state()
	s_drad.height_map = Height.create_height_map(8, 10, 2)
	var p_drad := _make_piece("crad", 1, 4, 5, ["destroy_radial"])
	var adj := _make_piece("adj", 2, 4, 6)
	var far := _make_piece("far", 2, 1, 1)
	s_drad.pieces = [p_drad, adj, far]
	var s_drad_after = Effects.new().activate_destroy_radial(s_drad, p_drad)
	var rad_ids := []
	for p in s_drad_after.pieces:
		rad_ids.append(p.id)
	_assert(rad_ids.has("crad"), "destroy_radial: caster survives", fails)
	_assert(not rad_ids.has("adj"), "destroy_radial: adjacent removed", fails)
	_assert(rad_ids.has("far"), "destroy_radial: distant survives", fails)
	# terrain unchanged
	_assert(Height.get_height(s_drad_after.height_map, 4, 6) == 2, "destroy_radial: terrain unchanged", fails)

	# -------------------------------------------------------------------------
	# BOMB: destroy 3x3 + lower terrain
	# -------------------------------------------------------------------------
	var s_bomb := _empty_state()
	s_bomb.height_map = Height.create_height_map(8, 10, 2)
	var p_bomb := _make_piece("cbomb", 1, 4, 5, ["bomb"])
	var adj_bomb := _make_piece("ab", 2, 4, 6)
	var far_bomb := _make_piece("fb", 2, 1, 1)
	s_bomb.pieces = [p_bomb, adj_bomb, far_bomb]
	var s_bomb_after = Effects.new().activate_bomb(s_bomb, p_bomb)
	var bomb_ids := []
	for p in s_bomb_after.pieces:
		bomb_ids.append(p.id)
	_assert(not bomb_ids.has("ab"), "bomb: adjacent enemy removed", fails)
	_assert(bomb_ids.has("fb"), "bomb: distant enemy survives", fails)
	_assert(Height.get_height(s_bomb_after.height_map, 4, 5) == 1, "bomb: center terrain lowered to 1", fails)
	_assert(Height.get_height(s_bomb_after.height_map, 4, 6) == 1, "bomb: adj terrain lowered to 1", fails)
	_assert(Height.get_height(s_bomb_after.height_map, 1, 1) == 2, "bomb: far terrain unchanged", fails)

	# -------------------------------------------------------------------------
	# RAISE TILE / LOWER TILE: targeted terrain adjustment
	# -------------------------------------------------------------------------
	var s_rt := _empty_state()
	var p_rt := _make_piece("prt", 1, 3, 3, ["raise_tile"])
	s_rt.pieces = [p_rt]
	var target_rc := {"row": 3, "col": 4}
	var s_rt_after = Effects.new().activate_raise_tile(s_rt, p_rt, target_rc)
	_assert(Height.get_height(s_rt_after.height_map, 3, 4) == 1, "raise_tile: height +1 = 1", fails)
	_assert(Height.get_height(s_rt_after.height_map, 3, 3) == 0, "raise_tile: other tile unchanged", fails)
	# power consumed
	var prt_after = _find_piece(s_rt_after, "prt")
	_assert(not prt_after.powers.has("raise_tile"), "raise_tile: power consumed", fails)

	# Clamp at MAX (4)
	var s_rt2 := _empty_state()
	s_rt2.height_map = Height.create_height_map(8, 10, 4)
	var p_rt2 := _make_piece("prt2", 1, 3, 3, ["raise_tile"])
	s_rt2.pieces = [p_rt2]
	var s_rt2_after = Effects.new().activate_raise_tile(s_rt2, p_rt2, {"row": 3, "col": 4})
	_assert(Height.get_height(s_rt2_after.height_map, 3, 4) == 4, "raise_tile: clamped at MAX(4)", fails)

	var s_lt := _empty_state()
	s_lt.height_map = Height.create_height_map(8, 10, 2)
	var p_lt := _make_piece("plt", 1, 3, 3, ["lower_tile"])
	s_lt.pieces = [p_lt]
	var s_lt_after = Effects.new().activate_lower_tile(s_lt, p_lt, {"row": 3, "col": 4})
	_assert(Height.get_height(s_lt_after.height_map, 3, 4) == 1, "lower_tile: height -1 = 1", fails)

	# -------------------------------------------------------------------------
	# RECRUIT (single target): convert adjacent enemy
	# -------------------------------------------------------------------------
	var s_rec := _empty_state()
	var p_rec := _make_piece("prec", 1, 4, 5, ["recruit"])
	var enemy_rec := _make_piece("erec", 2, 4, 6)
	var ally_rec := _make_piece("arec", 1, 4, 4)
	s_rec.pieces = [p_rec, enemy_rec, ally_rec]
	var s_rec_after = Effects.new().activate_recruit(s_rec, p_rec, enemy_rec)
	var erec_after = _find_piece(s_rec_after, "erec")
	_assert(erec_after != null, "recruit: target still exists", fails)
	_assert(erec_after.player == 1, "recruit: enemy converted to player 1", fails)
	var prec_after = _find_piece(s_rec_after, "prec")
	_assert(not prec_after.powers.has("recruit"), "recruit: power consumed", fails)

	# -------------------------------------------------------------------------
	# MOVEMENT FLAG: move_diagonal sets flag + consumes power
	# -------------------------------------------------------------------------
	var s_md := _empty_state()
	var p_md := _make_piece("pmd", 1, 3, 3, ["move_diagonal"])
	s_md.pieces = [p_md]
	var s_md_after = Effects.new().activate_move_diagonal(s_md, p_md)
	var pmd_after = _find_piece(s_md_after, "pmd")
	_assert(pmd_after.can_move_diagonally, "move_diagonal: flag set", fails)
	_assert(not pmd_after.powers.has("move_diagonal"), "move_diagonal: power consumed", fails)

	# -------------------------------------------------------------------------
	# MOVEMENT FLAG: jump_proof sets flag + consumes power
	# -------------------------------------------------------------------------
	var s_jp := _empty_state()
	var p_jp := _make_piece("pjp", 1, 3, 3, ["jump_proof", "bomb"])
	s_jp.pieces = [p_jp]
	var s_jp_after = Effects.new().activate_jump_proof(s_jp, p_jp)
	var pjp_after = _find_piece(s_jp_after, "pjp")
	_assert(pjp_after.is_jump_proof, "jump_proof: flag set", fails)
	_assert(not pjp_after.powers.has("jump_proof"), "jump_proof: power consumed", fails)
	_assert(pjp_after.powers.has("bomb"), "jump_proof: other powers preserved", fails)

	# -------------------------------------------------------------------------
	# SWITCHEROO: swap positions of two pieces
	# -------------------------------------------------------------------------
	var s_sw := _empty_state()
	var p_sw := _make_piece("psw", 1, 3, 3, ["switcheroo"])
	var tgt_sw := _make_piece("tsw", 2, 3, 4)
	s_sw.pieces = [p_sw, tgt_sw]
	var s_sw_after = Effects.new().activate_switcheroo(s_sw, p_sw, tgt_sw)
	var psw_after = _find_piece(s_sw_after, "psw")
	var tsw_after = _find_piece(s_sw_after, "tsw")
	_assert(psw_after.row == 3 and psw_after.col == 4, "switcheroo: caster moved to (3,4)", fails)
	_assert(tsw_after.row == 3 and tsw_after.col == 3, "switcheroo: target moved to (3,3)", fails)

	# -------------------------------------------------------------------------
	# MULTIPLY: create a copy at target position
	# -------------------------------------------------------------------------
	var s_mul := _empty_state()
	var p_mul := _make_piece("pmul", 1, 3, 3, ["multiply"])
	s_mul.pieces = [p_mul]
	var s_mul_after = Effects.new().activate_multiply(s_mul, p_mul, {"row": 3, "col": 4})
	_assert(s_mul_after.pieces.size() == 2, "multiply: 2 pieces after, got %d" % s_mul_after.pieces.size(), fails)
	var new_piece_found := false
	for p in s_mul_after.pieces:
		if p.id != "pmul" and p.row == 3 and p.col == 4 and p.player == 1:
			new_piece_found = true
	_assert(new_piece_found, "multiply: new piece at (3,4) for player 1", fails)
	var pmul_after = _find_piece(s_mul_after, "pmul")
	_assert(not pmul_after.powers.has("multiply"), "multiply: power consumed", fails)

	# -------------------------------------------------------------------------
	# REFURB (single target): repair a destroyed tile
	# -------------------------------------------------------------------------
	var s_rfb := _empty_state()
	var p_rfb := _make_piece("prfb", 1, 4, 5, ["refurb"])
	s_rfb.pieces = [p_rfb]
	s_rfb.destroyed_tiles["4,6"] = true
	var s_rfb_after = Effects.new().activate_refurb(s_rfb, p_rfb, {"row": 4, "col": 6})
	_assert(not s_rfb_after.destroyed_tiles.has("4,6"), "refurb: tile (4,6) restored", fails)
	_assert(Height.get_height(s_rfb_after.height_map, 4, 6) == 0, "refurb: tile height reset to 0", fails)
	var prfb_after = _find_piece(s_rfb_after, "prfb")
	_assert(not prfb_after.powers.has("refurb"), "refurb: power consumed", fails)

	# -------------------------------------------------------------------------
	# ACIDIC ROW: destroy pieces and mark tiles as destroyed
	# -------------------------------------------------------------------------
	var s_acid := _empty_state()
	var p_acid := _make_piece("pacid", 1, 3, 5, ["acidic_row"])
	var e_acid := _make_piece("eacid", 2, 3, 2)
	var by_acid := _make_piece("byacid", 2, 5, 5)
	s_acid.pieces = [p_acid, e_acid, by_acid]
	var s_acid_after = Effects.new().activate_acidic_row(s_acid, p_acid)
	var acid_ids := []
	for p in s_acid_after.pieces:
		acid_ids.append(p.id)
	_assert(not acid_ids.has("eacid"), "acidic_row: enemy removed", fails)
	_assert(acid_ids.has("byacid"), "acidic_row: bystander survives", fails)
	_assert(s_acid_after.destroyed_tiles.has("3,2"), "acidic_row: enemy tile destroyed", fails)
	_assert(not s_acid_after.destroyed_tiles.has("3,5"), "acidic_row: own tile not destroyed", fails)

	# -------------------------------------------------------------------------
	# KAMIKAZE RADIAL: destroys self and area pieces
	# -------------------------------------------------------------------------
	var s_kami := _empty_state()
	var p_kami := _make_piece("pkami", 1, 4, 5, ["kamikaze_radial"])
	var adj_kami := _make_piece("adj_k", 2, 4, 6)
	var far_kami := _make_piece("far_k", 2, 1, 1)
	s_kami.pieces = [p_kami, adj_kami, far_kami]
	var s_kami_after = Effects.new().activate_kamikaze_radial(s_kami, p_kami)
	var kami_ids := []
	for p in s_kami_after.pieces:
		kami_ids.append(p.id)
	_assert(not kami_ids.has("pkami"), "kamikaze_radial: caster removed", fails)
	_assert(not kami_ids.has("adj_k"), "kamikaze_radial: adjacent removed", fails)
	_assert(kami_ids.has("far_k"), "kamikaze_radial: distant survives", fails)

	# -------------------------------------------------------------------------
	# SCRAMBLE ROW: shuffles column positions in row
	# -------------------------------------------------------------------------
	var s_scr := _empty_state()
	var p_scr := _make_piece("pscr", 1, 3, 5, ["scramble_row"])
	var e_scr1 := _make_piece("es1", 2, 3, 2)
	var e_scr2 := _make_piece("es2", 2, 3, 8)
	s_scr.pieces = [p_scr, e_scr1, e_scr2]
	var s_scr_after = Effects.new().activate_scramble_row(s_scr, p_scr)
	# All pieces still present (just rearranged)
	var scr_ids := []
	for p in s_scr_after.pieces:
		scr_ids.append(p.id)
	_assert(scr_ids.has("pscr"), "scramble_row: caster present", fails)
	_assert(scr_ids.has("es1"), "scramble_row: es1 present", fails)
	_assert(scr_ids.has("es2"), "scramble_row: es2 present", fails)
	# All still in row 3
	for p in s_scr_after.pieces:
		if scr_ids.has(p.id):
			_assert(p.row == 3, "scramble_row: piece still in row 3, got %d" % p.row, fails)

	# -------------------------------------------------------------------------
	# RECRUIT ROW: convert all enemies in row
	# -------------------------------------------------------------------------
	var s_rrow := _empty_state()
	var p_rrow := _make_piece("prrow", 1, 3, 5, ["recruit_row"])
	var er1 := _make_piece("er1", 2, 3, 2)
	var er2 := _make_piece("er2", 2, 3, 8)
	var byrow := _make_piece("byrow", 2, 5, 5)
	s_rrow.pieces = [p_rrow, er1, er2, byrow]
	var s_rrow_after = Effects.new().activate_recruit_row(s_rrow, p_rrow)
	var er1_after = _find_piece(s_rrow_after, "er1")
	var er2_after = _find_piece(s_rrow_after, "er2")
	var byrow_after = _find_piece(s_rrow_after, "byrow")
	_assert(er1_after != null and er1_after.player == 1, "recruit_row: er1 converted", fails)
	_assert(er2_after != null and er2_after.player == 1, "recruit_row: er2 converted", fails)
	_assert(byrow_after != null and byrow_after.player == 2, "recruit_row: byrow unchanged", fails)

	# -------------------------------------------------------------------------
	# TEACH RADIAL: copy caster powers to adjacent allies
	# -------------------------------------------------------------------------
	var s_teach := _empty_state()
	var p_teach := _make_piece("pteach", 1, 4, 5, ["teach_radial", "bomb"])
	var ally_t := _make_piece("at", 1, 4, 6)
	var enemy_t := _make_piece("et", 2, 4, 4)
	s_teach.pieces = [p_teach, ally_t, enemy_t]
	var s_teach_after = Effects.new().activate_teach_radial(s_teach, p_teach)
	var at_after = _find_piece(s_teach_after, "at")
	var et_after = _find_piece(s_teach_after, "et")
	# ally should receive "bomb" (teach_radial was consumed before copying)
	_assert(at_after.powers.has("bomb"), "teach_radial: ally receives bomb", fails)
	_assert(not et_after.powers.has("bomb"), "teach_radial: enemy does not receive powers", fails)

	# -------------------------------------------------------------------------
	# PILFER RADIAL: steal powers from adjacent enemies
	# -------------------------------------------------------------------------
	var s_pilfer := _empty_state()
	var p_pilfer := _make_piece("ppil", 1, 4, 5, ["pilfer_radial"])
	var e_pilfer := _make_piece("epil", 2, 4, 6, ["bomb"])
	s_pilfer.pieces = [p_pilfer, e_pilfer]
	var s_pilfer_after = Effects.new().activate_pilfer_radial(s_pilfer, p_pilfer)
	var ppil_after = _find_piece(s_pilfer_after, "ppil")
	var epil_after = _find_piece(s_pilfer_after, "epil")
	_assert(ppil_after.powers.has("bomb"), "pilfer_radial: caster gained bomb", fails)
	_assert(not epil_after.powers.has("bomb"), "pilfer_radial: enemy lost bomb", fails)

	# -------------------------------------------------------------------------
	# SPYWARE RADIAL: reveals enemy powers (sets flag)
	# -------------------------------------------------------------------------
	var s_spy := _empty_state()
	var p_spy := _make_piece("pspy", 1, 4, 5, ["spyware_radial"])
	var e_spy := _make_piece("espy", 2, 4, 6)
	s_spy.pieces = [p_spy, e_spy]
	var s_spy_after = Effects.new().activate_spyware_radial(s_spy, p_spy)
	var espy_after = _find_piece(s_spy_after, "espy")
	_assert(espy_after.get_meta("powers_revealed", false) == true, "spyware_radial: enemy powers_revealed set", fails)

	# -------------------------------------------------------------------------
	# DOUBLE POWERS: doubles remaining power list
	# -------------------------------------------------------------------------
	var s_dbl := _empty_state()
	var p_dbl := _make_piece("pdbl", 1, 3, 3, ["double_powers", "bomb", "recruit"])
	s_dbl.pieces = [p_dbl]
	var s_dbl_after = Effects.new().activate_double_powers(s_dbl, p_dbl)
	var pdbl_after = _find_piece(s_dbl_after, "pdbl")
	# double_powers consumed, bomb+recruit each x2 = 4 powers
	_assert(pdbl_after.powers.size() == 4, "double_powers: 4 powers after (bomb+recruit x2), got %d" % pdbl_after.powers.size(), fails)
	_assert(not pdbl_after.powers.has("double_powers"), "double_powers: itself consumed", fails)

	# -------------------------------------------------------------------------
	# BANKRUPT RADIAL: marks tiles in area as bankrupt traps
	# -------------------------------------------------------------------------
	var s_bank := _empty_state()
	var p_bank := _make_piece("pbank", 1, 4, 5, ["bankrupt_radial"])
	s_bank.pieces = [p_bank]
	var s_bank_after = Effects.new().activate_bankrupt_radial(s_bank, p_bank)
	# Adjacent tile should be flagged in bankrupt_tiles
	_assert(s_bank_after.get_meta("bankrupt_tiles", {}).has("4,6") or
		s_bank_after.get_meta("bankrupt_tiles", {}).has("4,4"),
		"bankrupt_radial: at least one bankrupt tile set", fails)

	# -------------------------------------------------------------------------
	# TRIPWIRE RADIAL: marks enemy pieces with is_tripwired
	# -------------------------------------------------------------------------
	var s_trip := _empty_state()
	var p_trip := _make_piece("ptrip", 1, 4, 5, ["tripwire_radial"])
	var e_trip := _make_piece("etrip", 2, 4, 6)
	s_trip.pieces = [p_trip, e_trip]
	var s_trip_after = Effects.new().activate_tripwire_radial(s_trip, p_trip)
	var etrip_after = _find_piece(s_trip_after, "etrip")
	_assert(etrip_after.get_meta("is_tripwired", false) == true, "tripwire_radial: enemy is_tripwired set", fails)

	# -------------------------------------------------------------------------
	# INHIBIT RADIAL: marks enemy pieces with is_inhibited
	# -------------------------------------------------------------------------
	var s_inh := _empty_state()
	var p_inh := _make_piece("pinh", 1, 4, 5, ["inhibit_radial"])
	var e_inh := _make_piece("einh", 2, 4, 6)
	s_inh.pieces = [p_inh, e_inh]
	var s_inh_after = Effects.new().activate_inhibit_radial(s_inh, p_inh)
	var einh_after = _find_piece(s_inh_after, "einh")
	_assert(einh_after.get_meta("is_inhibited", false) == true, "inhibit_radial: enemy is_inhibited set", fails)

	# -------------------------------------------------------------------------
	# PARASITE RADIAL: marks enemy pieces with parasitized_by
	# -------------------------------------------------------------------------
	var s_para := _empty_state()
	var p_para := _make_piece("ppara", 1, 4, 5, ["parasite_radial"])
	var e_para := _make_piece("epara", 2, 4, 6)
	s_para.pieces = [p_para, e_para]
	var s_para_after = Effects.new().activate_parasite_radial(s_para, p_para)
	var epara_after = _find_piece(s_para_after, "epara")
	_assert(epara_after.get_meta("parasitized_by", "") == "ppara", "parasite_radial: enemy parasitized_by caster id", fails)

	# -------------------------------------------------------------------------
	# FLAT TO SPHERE: enables wrap flag
	# -------------------------------------------------------------------------
	var s_fts := _empty_state()
	var p_fts := _make_piece("pfts", 1, 3, 3, ["flat_to_sphere"])
	s_fts.pieces = [p_fts]
	var s_fts_after = Effects.new().activate_flat_to_sphere(s_fts, p_fts)
	var pfts_after = _find_piece(s_fts_after, "pfts")
	_assert(pfts_after.can_wrap, "flat_to_sphere: can_wrap set", fails)

	# -------------------------------------------------------------------------
	# CLIMB TILE: enables can_climb_any flag
	# -------------------------------------------------------------------------
	var s_ct := _empty_state()
	var p_ct := _make_piece("pct", 1, 3, 3, ["climb_tile"])
	s_ct.pieces = [p_ct]
	var s_ct_after = Effects.new().activate_climb_tile(s_ct, p_ct)
	var pct_after = _find_piece(s_ct_after, "pct")
	_assert(pct_after.can_climb_any, "climb_tile: can_climb_any set", fails)

	# -------------------------------------------------------------------------
	# INVISIBLE: sets is_invisible flag
	# -------------------------------------------------------------------------
	var s_inv := _empty_state()
	var p_inv := _make_piece("pinv", 1, 3, 3, ["invisible"])
	s_inv.pieces = [p_inv]
	var s_inv_after = Effects.new().activate_invisible(s_inv, p_inv)
	var pinv_after = _find_piece(s_inv_after, "pinv")
	_assert(pinv_after.is_invisible, "invisible: is_invisible set", fails)

	# -------------------------------------------------------------------------
	# SCAVENGER: sets is_scavenger flag
	# -------------------------------------------------------------------------
	var s_scav := _empty_state()
	var p_scav := _make_piece("pscav", 1, 3, 3, ["scavenger"])
	s_scav.pieces = [p_scav]
	var s_scav_after = Effects.new().activate_scavenger(s_scav, p_scav)
	var pscav_after = _find_piece(s_scav_after, "pscav")
	_assert(pscav_after.get_meta("is_scavenger", false) == true, "scavenger: is_scavenger set", fails)

	# -------------------------------------------------------------------------
	# INVERT RADIAL: flips heights in area (4 -> 0)
	# -------------------------------------------------------------------------
	var s_inv2 := _empty_state()
	s_inv2.height_map = Height.create_height_map(8, 10, 4)
	var p_inv2 := _make_piece("pinv2", 1, 4, 5, ["invert_radial"])
	s_inv2.pieces = [p_inv2]
	var s_inv2_after = Effects.new().activate_invert_radial(s_inv2, p_inv2)
	_assert(Height.get_height(s_inv2_after.height_map, 4, 5) == 0, "invert_radial: h4->h0 at caster tile", fails)
	_assert(Height.get_height(s_inv2_after.height_map, 4, 6) == 0, "invert_radial: h4->h0 at adj tile", fails)

	# -------------------------------------------------------------------------
	# PLATEAU: set 3x3 area to max height
	# -------------------------------------------------------------------------
	var s_plat := _empty_state()
	var p_plat := _make_piece("pplat", 1, 4, 5, ["plateau"])
	s_plat.pieces = [p_plat]
	var s_plat_after = Effects.new().activate_plateau(s_plat, p_plat)
	_assert(Height.get_height(s_plat_after.height_map, 4, 5) == 4, "plateau: center at MAX", fails)
	_assert(Height.get_height(s_plat_after.height_map, 4, 6) == 4, "plateau: adj at MAX", fails)
	_assert(Height.get_height(s_plat_after.height_map, 1, 1) == 0, "plateau: far tile unchanged", fails)

	# -------------------------------------------------------------------------
	# RELOCATE: piece teleports to a random empty tile
	# -------------------------------------------------------------------------
	var s_reloc := _empty_state()
	var p_reloc := _make_piece("preloc", 1, 4, 5, ["relocate"])
	s_reloc.pieces = [p_reloc]
	var s_reloc_after = Effects.new().activate_relocate(s_reloc, p_reloc)
	var preloc_after = _find_piece(s_reloc_after, "preloc")
	_assert(preloc_after.row != 4 or preloc_after.col != 5, "relocate: piece moved from (4,5)", fails)
	_assert(not preloc_after.powers.has("relocate"), "relocate: power consumed", fails)

	# Deterministic under same seed+turn
	var s_reloc2 := _empty_state()
	s_reloc2.seed = 99
	s_reloc2.turn = 3
	var p_reloc2 := _make_piece("pr2", 1, 4, 5, ["relocate"])
	s_reloc2.pieces = [p_reloc2]
	var r1 = Effects.new().activate_relocate(s_reloc2, p_reloc2)
	var r2 = Effects.new().activate_relocate(s_reloc2, p_reloc2)
	var pr1 = _find_piece(r1, "pr2")
	var pr2 = _find_piece(r2, "pr2")
	_assert(pr1.row == pr2.row and pr1.col == pr2.col, "relocate: deterministic under same seed+turn", fails)

	# -------------------------------------------------------------------------
	# GROW QUADRADIUS: increments growQuadradiusLevel, capped at 3
	# -------------------------------------------------------------------------
	var s_gq := _empty_state()
	var p_gq := _make_piece("pgq", 1, 3, 3, ["grow_quadradius"])
	s_gq.pieces = [p_gq]
	var s_gq1 = Effects.new().activate_grow_quadradius(s_gq, p_gq)
	var pgq1 = _find_piece(s_gq1, "pgq")
	_assert(pgq1.get_meta("grow_quadradius_level", 0) == 1, "grow_quadradius: level 1 after first use", fails)

	# -------------------------------------------------------------------------
	# BENEFICIARY: activation-time squad transfer — correct semantics (nnqr-42)
	# All OTHER same-player pieces sacrifice their powers to the activating piece.
	# Donors are emptied; opponents are untouched; beneficiary power is consumed.
	# -------------------------------------------------------------------------
	var s_ben := _empty_state()
	var p_ben := _make_piece("p_ben", 1, 1, 1, ["beneficiary"])
	var ben_don1 := _make_piece("ben_don1", 1, 2, 1, ["destroy_row", "bomb"])
	var ben_don2 := _make_piece("ben_don2", 1, 3, 1, ["relocate"])
	var ben_don3 := _make_piece("ben_don3", 1, 4, 1, [])
	var ben_opp := _make_piece("ben_opp", 2, 5, 1, ["jump_proof"])
	s_ben.pieces = [p_ben, ben_don1, ben_don2, ben_don3, ben_opp]
	var s_ben_after = Effects.new().activate_beneficiary(s_ben, p_ben)
	var ben_act_after = _find_piece(s_ben_after, "p_ben")
	_assert(ben_act_after != null, "beneficiary: activator still on board", fails)
	_assert(not ben_act_after.powers.has("beneficiary"), "beneficiary: power consumed from activator", fails)
	_assert(ben_act_after.powers.has("destroy_row"), "beneficiary: activator gains destroy_row", fails)
	_assert(ben_act_after.powers.has("bomb"), "beneficiary: activator gains bomb", fails)
	_assert(ben_act_after.powers.has("relocate"), "beneficiary: activator gains relocate", fails)
	# Donors are emptied
	var ben_d1a = _find_piece(s_ben_after, "ben_don1")
	var ben_d2a = _find_piece(s_ben_after, "ben_don2")
	var ben_d3a = _find_piece(s_ben_after, "ben_don3")
	_assert(ben_d1a.powers.size() == 0, "beneficiary: don1 emptied", fails)
	_assert(ben_d2a.powers.size() == 0, "beneficiary: don2 emptied", fails)
	_assert(ben_d3a.powers.size() == 0, "beneficiary: don3 emptied (was already empty)", fails)
	# Opponent untouched
	var ben_oppa = _find_piece(s_ben_after, "ben_opp")
	_assert(ben_oppa.powers.has("jump_proof"), "beneficiary: opponent powers untouched", fails)
	# Activator retains its own non-beneficiary powers
	var s_ben2 := _empty_state()
	var p_ben2 := _make_piece("p_ben2", 1, 1, 1, ["beneficiary", "bomb"])
	var ben2_don := _make_piece("ben2_don", 1, 2, 1, ["relocate"])
	s_ben2.pieces = [p_ben2, ben2_don]
	var s_ben2_after = Effects.new().activate_beneficiary(s_ben2, p_ben2)
	var ben2_act_after = _find_piece(s_ben2_after, "p_ben2")
	_assert(ben2_act_after.powers.has("bomb"), "beneficiary: activator retains own bomb", fails)
	_assert(ben2_act_after.powers.has("relocate"), "beneficiary: activator gains donor relocate", fails)
	_assert(not ben2_act_after.powers.has("beneficiary"), "beneficiary: beneficiary power consumed", fails)
	# Original state not mutated
	_assert(s_ben.pieces.size() == 5, "beneficiary: input state not mutated", fails)

	# -------------------------------------------------------------------------
	# ORB SPY ROW: marks same-row orbs as revealed
	# -------------------------------------------------------------------------
	var s_orbspy := _empty_state()
	var p_orbspy := _make_piece("porb", 1, 3, 5, ["orb_spy_row"])
	s_orbspy.pieces = [p_orbspy]
	s_orbspy.orbs = [
		{"row": 3, "col": 2, "power_id": "bomb"},
		{"row": 5, "col": 2, "power_id": "recruit"},
	]
	var s_orbspy_after = Effects.new().activate_orb_spy_row(s_orbspy, p_orbspy)
	_assert(s_orbspy_after.orbs[0].get("revealed", false), "orb_spy_row: orb in row 3 revealed", fails)
	_assert(not s_orbspy_after.orbs[1].get("revealed", false), "orb_spy_row: orb in row 5 not revealed", fails)

	# -------------------------------------------------------------------------
	# PURIFY RADIAL: remove debuffs from allies
	# -------------------------------------------------------------------------
	var s_pur := _empty_state()
	var p_pur := _make_piece("ppur", 1, 4, 5, ["purify_radial"])
	var ally_pur := _make_piece("apur", 1, 4, 6)
	ally_pur.set_meta("is_tripwired", true)
	s_pur.pieces = [p_pur, ally_pur]
	var s_pur_after = Effects.new().activate_purify_radial(s_pur, p_pur)
	var apur_after = _find_piece(s_pur_after, "apur")
	_assert(not apur_after.get_meta("is_tripwired", false) == true, "purify_radial: ally debuff cleared", fails)

	# -------------------------------------------------------------------------
	# DREDGE RADIAL: raise ally tiles, lower enemy tiles
	# -------------------------------------------------------------------------
	var s_dredge := _empty_state()
	s_dredge.height_map = Height.create_height_map(8, 10, 2)
	var p_dredge := _make_piece("pdredge", 1, 4, 5, ["dredge_radial"])
	var ally_dredge := _make_piece("adredge", 1, 4, 6)
	var enemy_dredge := _make_piece("edredge", 2, 4, 4)
	s_dredge.pieces = [p_dredge, ally_dredge, enemy_dredge]
	var s_dredge_after = Effects.new().activate_dredge_radial(s_dredge, p_dredge)
	_assert(Height.get_height(s_dredge_after.height_map, 4, 6) == 3, "dredge_radial: ally tile raised to 3", fails)
	_assert(Height.get_height(s_dredge_after.height_map, 4, 4) == 1, "dredge_radial: enemy tile lowered to 1", fails)

	# -------------------------------------------------------------------------
	# WALL ROW: raise entire row by 2
	# -------------------------------------------------------------------------
	var s_wall := _empty_state()
	s_wall.height_map = Height.create_height_map(8, 10, 1)
	var p_wall := _make_piece("pwall", 1, 3, 5, ["wall_row"])
	s_wall.pieces = [p_wall]
	var s_wall_after = Effects.new().activate_wall_row(s_wall, p_wall)
	_assert(Height.get_height(s_wall_after.height_map, 3, 1) == 3, "wall_row: row tile raised to 3", fails)
	_assert(Height.get_height(s_wall_after.height_map, 5, 1) == 1, "wall_row: other row unchanged", fails)

	# -------------------------------------------------------------------------
	# TRENCH ROW: lower entire row by 2
	# -------------------------------------------------------------------------
	var s_trench := _empty_state()
	s_trench.height_map = Height.create_height_map(8, 10, 3)
	var p_trench := _make_piece("ptrench", 1, 3, 5, ["trench_row"])
	s_trench.pieces = [p_trench]
	var s_trench_after = Effects.new().activate_trench_row(s_trench, p_trench)
	_assert(Height.get_height(s_trench_after.height_map, 3, 1) == 1, "trench_row: row tile lowered to 1", fails)
	_assert(Height.get_height(s_trench_after.height_map, 5, 1) == 3, "trench_row: other row unchanged", fails)

	# -------------------------------------------------------------------------
	# MOAT: center max, surrounding ring lowered by 1
	# -------------------------------------------------------------------------
	var s_moat := _empty_state()
	s_moat.height_map = Height.create_height_map(8, 10, 2)
	var p_moat := _make_piece("pmoat", 1, 4, 5, ["moat"])
	s_moat.pieces = [p_moat]
	var s_moat_after = Effects.new().activate_moat(s_moat, p_moat)
	_assert(Height.get_height(s_moat_after.height_map, 4, 5) == 4, "moat: center raised to MAX", fails)
	_assert(Height.get_height(s_moat_after.height_map, 4, 6) == 1, "moat: ring lowered to 1", fails)

	# -------------------------------------------------------------------------
	# CANCEL MULTIPLY: destroys multiplied pieces
	# -------------------------------------------------------------------------
	var s_cm := _empty_state()
	var p_cm := _make_piece("pcm", 1, 3, 3, ["cancel_multiply"])
	var mul_p := _make_piece("mul1", 1, 5, 5)
	s_cm.pieces = [p_cm, mul_p]
	s_cm.set_meta("multiplied_pieces", ["mul1"])
	var s_cm_after = Effects.new().activate_cancel_multiply(s_cm, p_cm)
	var cm_ids := []
	for p in s_cm_after.pieces:
		cm_ids.append(p.id)
	_assert(not cm_ids.has("mul1"), "cancel_multiply: multiplied piece removed", fails)
	_assert(cm_ids.has("pcm"), "cancel_multiply: caster survives", fails)

	# -------------------------------------------------------------------------
	# LEARN RADIAL: absorb powers from adjacent allies
	# -------------------------------------------------------------------------
	var s_learn := _empty_state()
	var p_learn := _make_piece("plearn", 1, 4, 5, ["learn_radial"])
	var ally_learn := _make_piece("alearn", 1, 4, 6, ["bomb", "recruit"])
	s_learn.pieces = [p_learn, ally_learn]
	var s_learn_after = Effects.new().activate_learn_radial(s_learn, p_learn)
	var plearn_after = _find_piece(s_learn_after, "plearn")
	var alearn_after = _find_piece(s_learn_after, "alearn")
	_assert(plearn_after.powers.has("bomb"), "learn_radial: caster gained bomb", fails)
	_assert(plearn_after.powers.has("recruit"), "learn_radial: caster gained recruit", fails)
	_assert(alearn_after.powers.size() == 0, "learn_radial: ally drained", fails)

	# -------------------------------------------------------------------------
	# HOTSPOT: sets hotspot tile at caster position
	# -------------------------------------------------------------------------
	var s_hot := _empty_state()
	var p_hot := _make_piece("phot", 1, 3, 3, ["hotspot"])
	s_hot.pieces = [p_hot]
	var s_hot_after = Effects.new().activate_hotspot(s_hot, p_hot)
	var hotspots = s_hot_after.get_meta("hotspot_tiles", {})
	_assert(hotspots.has("3,3"), "hotspot: tile '3,3' set in hotspot_tiles", fails)
	_assert(hotspots.get("3,3", 0) == 1, "hotspot: player 1 owns hotspot", fails)

	# -------------------------------------------------------------------------
	# ORBIC REHASH: respawns orbs at new locations
	# -------------------------------------------------------------------------
	var s_orb := _empty_state()
	var p_orb := _make_piece("porb2", 1, 4, 5, ["orbic_rehash"])
	s_orb.pieces = [p_orb]
	s_orb.orbs = [
		{"row": 3, "col": 3, "power_id": "bomb"},
		{"row": 5, "col": 7, "power_id": "recruit"},
	]
	var s_orb_after = Effects.new().activate_orbic_rehash(s_orb, p_orb)
	_assert(s_orb_after.orbs.size() == 2, "orbic_rehash: same orb count, got %d" % s_orb_after.orbs.size(), fails)
	# Power ids preserved (just relocated)
	var orb_power_ids := []
	for o in s_orb_after.orbs:
		orb_power_ids.append(o.power_id)
	_assert(orb_power_ids.has("bomb"), "orbic_rehash: bomb orb preserved", fails)
	_assert(orb_power_ids.has("recruit"), "orbic_rehash: recruit orb preserved", fails)

	# -------------------------------------------------------------------------
	# MOVE AGAIN: sets extraMove flag
	# -------------------------------------------------------------------------
	var s_ma := _empty_state()
	var p_ma := _make_piece("pma", 1, 3, 3, ["move_again"])
	s_ma.pieces = [p_ma]
	var s_ma_after = Effects.new().activate_move_again(s_ma, p_ma)
	_assert(s_ma_after.get_meta("extra_move", false) == true, "move_again: extra_move flag set", fails)

	# -------------------------------------------------------------------------
	# SMART BOMBS: destroy only enemies in 3x3
	# -------------------------------------------------------------------------
	var s_smart := _empty_state()
	var p_smart := _make_piece("psmart", 1, 4, 5, ["smart_bombs"])
	var ally_smart := _make_piece("asmart", 1, 4, 6)
	var enemy_smart := _make_piece("esmart", 2, 4, 4)
	var far_smart := _make_piece("fsmart", 2, 1, 1)
	s_smart.pieces = [p_smart, ally_smart, enemy_smart, far_smart]
	var s_smart_after = Effects.new().activate_smart_bombs(s_smart, p_smart)
	var smart_ids := []
	for p in s_smart_after.pieces:
		smart_ids.append(p.id)
	_assert(smart_ids.has("psmart"), "smart_bombs: caster survives", fails)
	_assert(smart_ids.has("asmart"), "smart_bombs: ally survives", fails)
	_assert(not smart_ids.has("esmart"), "smart_bombs: enemy destroyed", fails)
	_assert(smart_ids.has("fsmart"), "smart_bombs: distant enemy survives", fails)

	# -------------------------------------------------------------------------
	# CENTERPULT: jump to target, displace occupant
	# -------------------------------------------------------------------------
	var s_cp := _empty_state()
	var p_cp := _make_piece("pcp", 1, 5, 5, ["centerpult"])
	var displaced := _make_piece("disp", 2, 2, 3)
	s_cp.pieces = [p_cp, displaced]
	var s_cp_after = Effects.new().activate_centerpult(s_cp, p_cp, {"row": 2, "col": 3})
	var pcp_after = _find_piece(s_cp_after, "pcp")
	_assert(pcp_after.row == 2 and pcp_after.col == 3, "centerpult: caster teleported to (2,3)", fails)
	var cp_ids := []
	for p in s_cp_after.pieces:
		cp_ids.append(p.id)
	_assert(not cp_ids.has("disp"), "centerpult: displaced piece removed", fails)

	# -------------------------------------------------------------------------
	# KAMIKAZE ROW/COLUMN: destroy all in row/column including self
	# -------------------------------------------------------------------------
	var s_krow := _empty_state()
	var p_krow := _make_piece("pkrow", 1, 3, 5, ["kamikaze_row"])
	var e_krow := _make_piece("ekrow", 2, 3, 2)
	var by_krow := _make_piece("bykrow", 2, 5, 5)
	s_krow.pieces = [p_krow, e_krow, by_krow]
	var s_krow_after = Effects.new().activate_kamikaze_row(s_krow, p_krow)
	var krow_ids := []
	for p in s_krow_after.pieces:
		krow_ids.append(p.id)
	_assert(not krow_ids.has("pkrow"), "kamikaze_row: self removed", fails)
	_assert(not krow_ids.has("ekrow"), "kamikaze_row: row enemy removed", fails)
	_assert(krow_ids.has("bykrow"), "kamikaze_row: diff-row piece survives", fails)

	# -------------------------------------------------------------------------
	# ACIDIC COLUMN: destroys pieces + tiles in column
	# -------------------------------------------------------------------------
	var s_acol := _empty_state()
	var p_acol := _make_piece("pacol", 1, 3, 5, ["acidic_column"])
	var e_acol := _make_piece("eacol", 2, 6, 5)
	s_acol.pieces = [p_acol, e_acol]
	var s_acol_after = Effects.new().activate_acidic_column(s_acol, p_acol)
	var acol_ids := []
	for p in s_acol_after.pieces:
		acol_ids.append(p.id)
	_assert(not acol_ids.has("eacol"), "acidic_column: enemy removed", fails)
	_assert(s_acol_after.destroyed_tiles.has("6,5"), "acidic_column: tile (6,5) destroyed", fails)

	# -------------------------------------------------------------------------
	# REFURB RADIAL: repair destroyed tiles in 3x3
	# -------------------------------------------------------------------------
	var s_rfb_r := _empty_state()
	var p_rfb_r := _make_piece("prfbr", 1, 4, 5, ["refurb_radial"])
	s_rfb_r.pieces = [p_rfb_r]
	s_rfb_r.destroyed_tiles["4,6"] = true
	s_rfb_r.destroyed_tiles["1,1"] = true
	var s_rfb_r_after = Effects.new().activate_refurb_radial(s_rfb_r, p_rfb_r)
	_assert(not s_rfb_r_after.destroyed_tiles.has("4,6"), "refurb_radial: adj tile restored", fails)
	_assert(s_rfb_r_after.destroyed_tiles.has("1,1"), "refurb_radial: far tile unchanged", fails)

	if fails[0] == 0:
		print("OK effects")
	else:
		printerr("FAIL effects: %d" % fails[0])
	quit(fails[0])
