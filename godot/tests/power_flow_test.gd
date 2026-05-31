## power_flow_test.gd — Tests that power flags (set via set_meta) are actually
## CONSUMED by game flow: board movement, orb collection, and terrain triggers.
##
## These tests assert OBSERVABLE game-flow changes (piece destroyed, powers lost,
## powers gained) — NOT merely that set_meta was called.
##
## Run: godot/scripts/godot.sh --headless --path . -s res://tests/power_flow_test.gd
extends SceneTree

const Board      = preload("res://src/board.gd")
const GameState  = preload("res://src/game_state.gd")
const Controller = preload("res://src/controller.gd")
const Orbs       = preload("res://src/orbs.gd")
const Effects    = preload("res://src/powers/effects.gd")
const Height     = preload("res://src/height.gd")


func _assert(cond: bool, msg: String, fails: Array) -> void:
	if not cond:
		printerr("  FAIL: " + msg)
		fails[0] += 1


func _empty_state(seed: int = 1, turn: int = 1) -> GameState:
	var s := GameState.new()
	s.current_player = 1
	s.turn = turn
	s.status = "playing"
	s.winner = 0
	s.seed = seed
	s.height_map = Height.create_height_map(8, 10, 0)
	s.destroyed_tiles = {}
	s.orbs = []
	s.selected = null
	s.valid_moves = []
	s.pieces = []
	return s


func _make_piece(id: String, player: int, row: int, col: int, powers: Array = []) -> GameState.Piece:
	var p := GameState.Piece.new(id, player, row, col)
	p.powers = powers.duplicate()
	return p


func _find_piece(state: GameState, id: String) -> GameState.Piece:
	for p: GameState.Piece in state.pieces:
		if p.id == id:
			return p
	return null


func _init() -> void:
	var fails := [0]

	# -----------------------------------------------------------------------
	# TRIPWIRE: a tripwired enemy piece is destroyed when it moves.
	#
	# Setup: p1 at (3,5), p2 at (5,5) with is_tripwired meta.
	# p2 moves to (5,4) — a valid empty move.
	# Expected: p2 is removed from state.pieces after the move.
	# -----------------------------------------------------------------------
	var s_tw := _empty_state()
	var p1_tw := _make_piece("p1-tw", 1, 3, 5)
	var p2_tw := _make_piece("p2-tw", 2, 5, 5)
	p2_tw.set_meta("is_tripwired", true)
	s_tw.pieces = [p1_tw, p2_tw]
	# Switch to player 2's turn so p2 can move.
	s_tw.current_player = 2
	var s_tw1: GameState = Controller.handle_tile_click(s_tw, 5, 5)   # select p2
	var s_tw2: GameState = Controller.handle_tile_click(s_tw1, 5, 4)  # move p2

	var tw_ids: Array = []
	for p: GameState.Piece in s_tw2.pieces:
		tw_ids.append(p.id)
	_assert(not tw_ids.has("p2-tw"),
		"tripwire: tripwired piece is removed after moving", fails)
	_assert(tw_ids.has("p1-tw"),
		"tripwire: non-tripwired piece survives", fails)

	# -----------------------------------------------------------------------
	# TRIPWIRE: a piece WITHOUT the flag is NOT destroyed after moving.
	# -----------------------------------------------------------------------
	var s_notw := _empty_state()
	var p1_notw := _make_piece("p1-notw", 1, 3, 5)
	var p2_notw := _make_piece("p2-notw", 2, 5, 5)
	s_notw.pieces = [p1_notw, p2_notw]
	s_notw.current_player = 2
	var s_notw1: GameState = Controller.handle_tile_click(s_notw, 5, 5)
	var s_notw2: GameState = Controller.handle_tile_click(s_notw1, 5, 4)
	var notw_ids: Array = []
	for p: GameState.Piece in s_notw2.pieces:
		notw_ids.append(p.id)
	_assert(notw_ids.has("p2-notw"),
		"tripwire baseline: untripwired piece survives move", fails)

	# -----------------------------------------------------------------------
	# INHIBIT: an inhibited piece cannot collect an orb it lands on.
	#
	# Setup: p1 at (3,5) with is_inhibited, orb at (3,4).
	# p1 moves onto orb tile.
	# Expected: p1.powers does NOT contain the orb's power_id.
	# -----------------------------------------------------------------------
	var s_inh := _empty_state()
	var p1_inh := _make_piece("p1-inh", 1, 3, 5)
	p1_inh.set_meta("is_inhibited", true)
	var p2_inh := _make_piece("p2-inh", 2, 7, 5)
	s_inh.pieces = [p1_inh, p2_inh]
	s_inh.orbs = [{"row": 3, "col": 4, "power_id": "raise_tile"}]
	var s_inh1: GameState = Controller.handle_tile_click(s_inh, 3, 5)   # select
	var s_inh2: GameState = Controller.handle_tile_click(s_inh1, 3, 4)  # move onto orb
	var inh_piece := _find_piece(s_inh2, "p1-inh")
	_assert(inh_piece != null, "inhibit: inhibited piece still exists after move", fails)
	_assert(not inh_piece.powers.has("raise_tile"),
		"inhibit: inhibited piece does NOT collect orb power", fails)
	# Orb should still be present (not consumed by an inhibited piece)
	_assert(s_inh2.orbs.size() > 0,
		"inhibit: orb remains uncollected when piece is inhibited", fails)

	# -----------------------------------------------------------------------
	# INHIBIT baseline: a NON-inhibited piece DOES collect the orb.
	# -----------------------------------------------------------------------
	var s_ninh := _empty_state()
	var p1_ninh := _make_piece("p1-ninh", 1, 3, 5)
	var p2_ninh := _make_piece("p2-ninh", 2, 7, 5)
	s_ninh.pieces = [p1_ninh, p2_ninh]
	s_ninh.orbs = [{"row": 3, "col": 4, "power_id": "raise_tile"}]
	var s_ninh1: GameState = Controller.handle_tile_click(s_ninh, 3, 5)
	var s_ninh2: GameState = Controller.handle_tile_click(s_ninh1, 3, 4)
	var ninh_piece := _find_piece(s_ninh2, "p1-ninh")
	_assert(ninh_piece != null, "inhibit baseline: normal piece survives", fails)
	_assert(ninh_piece.powers.has("raise_tile"),
		"inhibit baseline: normal piece DOES collect orb", fails)

	# -----------------------------------------------------------------------
	# PARASITE: when a parasitized piece collects an orb, the parasitizer also
	# receives a copy of that power.
	#
	# Setup: p1 at (3,5) [parasitizer], p2 at (5,5) [parasitized].
	#   p2.parasitized_by = p1.id
	#   orb at (5,4) with power "raise_tile"
	# p2 (player 2's turn) moves onto the orb.
	# Expected: both p2 AND p1 gain "raise_tile".
	# -----------------------------------------------------------------------
	var s_par := _empty_state()
	var p1_par := _make_piece("p1-par", 1, 3, 5)
	var p2_par := _make_piece("p2-par", 2, 5, 5)
	p2_par.set_meta("parasitized_by", "p1-par")
	s_par.pieces = [p1_par, p2_par]
	s_par.current_player = 2
	s_par.orbs = [{"row": 5, "col": 4, "power_id": "raise_tile"}]
	var s_par1: GameState = Controller.handle_tile_click(s_par, 5, 5)   # select p2
	var s_par2: GameState = Controller.handle_tile_click(s_par1, 5, 4)  # move onto orb
	var par_victim := _find_piece(s_par2, "p2-par")
	var par_leech := _find_piece(s_par2, "p1-par")
	_assert(par_victim != null, "parasite: victim (p2) survives", fails)
	_assert(par_leech != null, "parasite: parasitizer (p1) survives", fails)
	_assert(par_victim.powers.has("raise_tile"),
		"parasite: victim collects the orb power normally", fails)
	_assert(par_leech.powers.has("raise_tile"),
		"parasite: parasitizer ALSO receives copy of orb power", fails)

	# -----------------------------------------------------------------------
	# SCAVENGER: when a scavenger piece captures an enemy, it inherits the
	# enemy's powers.
	#
	# Setup: p1 at (3,5) with is_scavenger, p2 at (3,4) with powers ["bomb"].
	# p1 captures p2.
	# Expected: p1 gains "bomb" after the capture.
	# -----------------------------------------------------------------------
	var s_scav := _empty_state()
	var p1_scav := _make_piece("p1-scav", 1, 3, 5)
	p1_scav.set_meta("is_scavenger", true)
	var p2_scav := _make_piece("p2-scav", 2, 3, 4, ["bomb"])
	s_scav.pieces = [p1_scav, p2_scav]
	var s_scav1: GameState = Controller.handle_tile_click(s_scav, 3, 5)   # select p1
	var s_scav2: GameState = Controller.handle_tile_click(s_scav1, 3, 4)  # capture p2
	var scav_piece := _find_piece(s_scav2, "p1-scav")
	_assert(scav_piece != null, "scavenger: scavenger piece survives capture", fails)
	_assert(scav_piece.powers.has("bomb"),
		"scavenger: scavenger inherits captured enemy's powers", fails)

	# -----------------------------------------------------------------------
	# SCAVENGER baseline: a non-scavenger piece does NOT inherit enemy powers.
	# -----------------------------------------------------------------------
	var s_nscav := _empty_state()
	var p1_nscav := _make_piece("p1-nscav", 1, 3, 5)
	var p2_nscav := _make_piece("p2-nscav", 2, 3, 4, ["bomb"])
	s_nscav.pieces = [p1_nscav, p2_nscav]
	var s_nscav1: GameState = Controller.handle_tile_click(s_nscav, 3, 5)
	var s_nscav2: GameState = Controller.handle_tile_click(s_nscav1, 3, 4)
	var nscav_piece := _find_piece(s_nscav2, "p1-nscav")
	_assert(nscav_piece != null, "scavenger baseline: attacker survives", fails)
	_assert(not nscav_piece.powers.has("bomb"),
		"scavenger baseline: non-scavenger does NOT inherit enemy powers", fails)

	# -----------------------------------------------------------------------
	# BANKRUPT: a piece that moves onto a bankrupted tile loses all its powers
	# and has its positive piece-flags reset.
	#
	# Setup: p1 at (3,5) with powers ["bomb","raise_tile"] and is_jump_proof=true.
	#   bankrupt_tiles = {"3,4": true}
	# p1 moves to (3,4).
	# Expected: p1.powers is empty AND p1.is_jump_proof is false after the move.
	# -----------------------------------------------------------------------
	var s_bk := _empty_state()
	var p1_bk := _make_piece("p1-bk", 1, 3, 5, ["bomb", "raise_tile"])
	p1_bk.is_jump_proof = true
	var p2_bk := _make_piece("p2-bk", 2, 7, 5)
	s_bk.pieces = [p1_bk, p2_bk]
	s_bk.set_meta("bankrupt_tiles", {"3,4": true})
	var s_bk1: GameState = Controller.handle_tile_click(s_bk, 3, 5)   # select p1
	var s_bk2: GameState = Controller.handle_tile_click(s_bk1, 3, 4)  # move onto bankrupt tile
	var bk_piece := _find_piece(s_bk2, "p1-bk")
	_assert(bk_piece != null, "bankrupt: piece survives landing on bankrupt tile", fails)
	_assert(bk_piece.powers.size() == 0,
		"bankrupt: piece loses all powers on bankrupt tile", fails)
	_assert(not bk_piece.is_jump_proof,
		"bankrupt: is_jump_proof cleared on bankrupt tile", fails)

	# -----------------------------------------------------------------------
	# BANKRUPT baseline: moving onto a non-bankrupted tile does NOT clear powers.
	# -----------------------------------------------------------------------
	var s_nbk := _empty_state()
	var p1_nbk := _make_piece("p1-nbk", 1, 3, 5, ["bomb"])
	var p2_nbk := _make_piece("p2-nbk", 2, 7, 5)
	s_nbk.pieces = [p1_nbk, p2_nbk]
	# no bankrupt_tiles meta set
	var s_nbk1: GameState = Controller.handle_tile_click(s_nbk, 3, 5)
	var s_nbk2: GameState = Controller.handle_tile_click(s_nbk1, 3, 4)
	var nbk_piece := _find_piece(s_nbk2, "p1-nbk")
	_assert(nbk_piece != null, "bankrupt baseline: piece survives normal move", fails)
	_assert(nbk_piece.powers.has("bomb"),
		"bankrupt baseline: powers unchanged on normal tile", fails)

	# -----------------------------------------------------------------------
	# Results
	# -----------------------------------------------------------------------
	if fails[0] == 0:
		print("OK power_flow")
	else:
		printerr("FAIL power_flow: %d" % fails[0])
	quit(fails[0])
