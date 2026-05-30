## orbs_test.gd — Tests for orbs.gd (orb spawning and collection).
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/orbs_test.gd
extends SceneTree

const Orbs = preload("res://src/orbs.gd")
const Board = preload("res://src/board.gd")
const GameState = preload("res://src/game_state.gd")

func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _init() -> void:
	var fails := [0]

	# --- Constants ---
	_assert(Orbs.SPAWN_INTERVAL == 7, "SPAWN_INTERVAL==7", fails)
	_assert(Orbs.MIN_ORBS == 2, "MIN_ORBS==2", fails)
	_assert(Orbs.MAX_ORBS == 4, "MAX_ORBS==4", fails)

	# --- should_spawn_orbs ---
	_assert(not Orbs.should_spawn_orbs(0), "no spawn at turn 0", fails)
	_assert(not Orbs.should_spawn_orbs(1), "no spawn at turn 1", fails)
	_assert(not Orbs.should_spawn_orbs(6), "no spawn at turn 6", fails)
	_assert(Orbs.should_spawn_orbs(7), "spawn at turn 7", fails)
	_assert(not Orbs.should_spawn_orbs(8), "no spawn at turn 8", fails)
	_assert(Orbs.should_spawn_orbs(14), "spawn at turn 14", fails)
	_assert(Orbs.should_spawn_orbs(21), "spawn at turn 21", fails)

	# --- empty_tiles: no pieces or orbs, all tiles empty ---
	var s0 = Board.create_initial_state(1)
	s0.pieces.clear()
	var tiles = Orbs.empty_tiles(s0)
	_assert(tiles.size() == 80, "80 empty tiles when board is empty (8x10)", fails)

	# --- empty_tiles: occupied by pieces ---
	var s1 = Board.create_initial_state(1)  # 40 pieces
	var et1 = Orbs.empty_tiles(s1)
	_assert(et1.size() == 40, "40 empty tiles with 40 pieces, got %d" % et1.size(), fails)

	# --- empty_tiles: destroyed tiles excluded ---
	var s2 = Board.create_initial_state(1)
	s2.pieces.clear()
	s2.destroyed_tiles["4,5"] = true
	s2.destroyed_tiles["4,6"] = true
	var et2 = Orbs.empty_tiles(s2)
	_assert(et2.size() == 78, "78 empty tiles with 2 destroyed, got %d" % et2.size(), fails)

	# --- spawn_orbs: deterministic for same seed+turn ---
	var sa = Board.create_initial_state(42)
	sa.pieces.clear()
	sa.turn = 7
	var sb = Board.create_initial_state(42)
	sb.pieces.clear()
	sb.turn = 7
	var power_ids = ["a", "b", "c"]
	var sa2 = Orbs.spawn_orbs(sa, power_ids)
	var sb2 = Orbs.spawn_orbs(sb, power_ids)
	_assert(sa2.orbs.size() == sb2.orbs.size(), "spawn deterministic: same orb count", fails)
	# Verify each orb matches
	for i in range(sa2.orbs.size()):
		var oa = sa2.orbs[i]
		var ob = sb2.orbs[i]
		_assert(oa.row == ob.row and oa.col == ob.col and oa.power_id == ob.power_id,
			"spawn deterministic: orb %d matches" % i, fails)

	# --- spawn_orbs: count within [MIN_ORBS, MAX_ORBS] ---
	var sc = Board.create_initial_state(1)
	sc.pieces.clear()
	sc.turn = 7
	var sc2 = Orbs.spawn_orbs(sc, ["x", "y", "z"])
	_assert(sc2.orbs.size() >= Orbs.MIN_ORBS and sc2.orbs.size() <= Orbs.MAX_ORBS,
		"spawn count in [%d,%d], got %d" % [Orbs.MIN_ORBS, Orbs.MAX_ORBS, sc2.orbs.size()], fails)

	# --- spawn_orbs: orbs land on valid (non-destroyed, non-occupied) tiles ---
	var sd = Board.create_initial_state(1)
	sd.pieces.clear()
	sd.turn = 7
	sd.destroyed_tiles["4,5"] = true
	var sd2 = Orbs.spawn_orbs(sd, ["p1"])
	for orb in sd2.orbs:
		_assert(not (orb.row == 4 and orb.col == 5),
			"orb not on destroyed tile (4,5)", fails)

	# --- spawn_orbs: no orbs when no power_ids ---
	var se = Board.create_initial_state(1)
	se.pieces.clear()
	se.turn = 7
	var se2 = Orbs.spawn_orbs(se, [])
	_assert(se2.orbs.size() == 0, "no orbs spawned when power_ids empty", fails)

	# --- spawn_orbs: power_id assigned from provided list ---
	var sf = Board.create_initial_state(1)
	sf.pieces.clear()
	sf.turn = 7
	var valid_ids = ["fire", "ice", "wind"]
	var sf2 = Orbs.spawn_orbs(sf, valid_ids)
	for orb in sf2.orbs:
		_assert(orb.power_id in valid_ids,
			"orb power_id '%s' is from valid_ids" % orb.power_id, fails)

	# --- collect_orb: piece collects orb on its tile ---
	var sg = Board.create_initial_state(1)
	sg.pieces.clear()
	var piece_g = GameState.Piece.new("p1-5-5", 1, 5, 5)
	sg.pieces.append(piece_g)
	sg.orbs.append({"row": 5, "col": 5, "power_id": "fire"})
	var result = Orbs.collect_orb(sg, 5, 5)
	var new_sg = result.state
	var collected = result.collected
	_assert(collected == "fire", "collected power_id == 'fire'", fails)
	_assert(new_sg.orbs.size() == 0, "orb removed after collection", fails)
	# Piece now has the power
	var updated_piece: GameState.Piece = null
	for p in new_sg.pieces:
		if p.id == "p1-5-5":
			updated_piece = p
			break
	_assert(updated_piece != null, "piece still in state after collect", fails)
	_assert(updated_piece.powers.size() == 1, "piece has 1 power after collect", fails)
	_assert(updated_piece.powers[0] == "fire", "piece has 'fire' power", fails)

	# --- collect_orb: no orb at tile returns null collected ---
	var sh = Board.create_initial_state(1)
	sh.pieces.clear()
	var piece_h = GameState.Piece.new("p1-5-5", 1, 5, 5)
	sh.pieces.append(piece_h)
	var result_h = Orbs.collect_orb(sh, 5, 5)
	_assert(result_h.collected == null, "no orb -> collected is null", fails)
	_assert(result_h.state.orbs.size() == 0, "orbs unchanged when no orb", fails)

	# --- collect_orb: no piece at tile returns null collected ---
	var si = Board.create_initial_state(1)
	si.pieces.clear()
	si.orbs.append({"row": 5, "col": 5, "power_id": "ice"})
	var result_i = Orbs.collect_orb(si, 5, 5)
	_assert(result_i.collected == null, "no piece -> collected is null", fails)
	_assert(result_i.state.orbs.size() == 1, "orb stays when no piece to collect", fails)

	# --- spawn does not overwrite existing orbs ---
	var sj = Board.create_initial_state(1)
	sj.pieces.clear()
	sj.orbs.append({"row": 4, "col": 4, "power_id": "existing"})
	sj.turn = 7
	var sj2 = Orbs.spawn_orbs(sj, ["new"])
	_assert(sj2.orbs.size() >= 3, "existing orb kept + new orbs added, got %d" % sj2.orbs.size(), fails)

	if fails[0] == 0:
		print("OK orbs")
	else:
		printerr("FAIL orbs: %d" % fails[0])
	quit(fails[0])
