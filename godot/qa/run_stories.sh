#!/usr/bin/env bash
# qa/run_stories.sh — Run all qa_*.json scenarios through the see-harness and assert
# expected outcomes on the produced .qa/state.json.
#
# Assertions live HERE (not baked into scenario JSON) to prevent the hard-coded-
# end-state anti-pattern: scenarios drive real inputs from a fresh-ish state;
# this script checks the produced state.
#
# Usage: bash qa/run_stories.sh  (from godot/ directory)
# Exit: nonzero if any story fails.
#
# State.json is not human-readable from the PNGs — lead validates PNGs separately.
# All assertions are on state.json only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_DIR="$(dirname "$SCRIPT_DIR")"
GODOT_SH="$GODOT_DIR/scripts/godot.sh"
QA_DIR="$GODOT_DIR/.qa"
JQ="$(which jq 2>/dev/null || true)"
if [ -z "$JQ" ]; then
  # Fall back to mise-managed jq
  JQ="mise exec -- jq"
fi

pass_count=0
fail_count=0

pass() {
  local story="$1"
  echo "PASS $story"
  pass_count=$((pass_count + 1))
}

fail() {
  local story="$1"
  local reason="$2"
  echo "FAIL $story: $reason"
  fail_count=$((fail_count + 1))
}

run_scenario() {
  local story="$1"
  local scenario_path="$2"
  echo "--- Running $story ---"
  "$GODOT_SH" --path "$GODOT_DIR" -- --scenario "res://scenarios/$scenario_path" 2>&1 || true
  # Copy frame to named file for lead review
  if [ -f "$QA_DIR/frame.png" ]; then
    cp "$QA_DIR/frame.png" "$QA_DIR/${story}.png"
    echo "  frame saved: .qa/${story}.png"
  else
    echo "  WARNING: .qa/frame.png not produced"
  fi
}

# ---------------------------------------------------------------------------
# Story 1: qa_move_capture
# Starting: p1-mover at (4,4), p2-enemy at (5,4). NO capture yet.
# Inputs: click (4,4) select, click (5,4) capture.
# Assert: p2-enemy absent, p1-mover at row=5 col=4, turn==1, current_player==2.
# ---------------------------------------------------------------------------
STORY="qa_move_capture"
run_scenario "$STORY" "qa_move_capture.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  # p2-enemy must be gone
  P2_COUNT=$($JQ '[.pieces[] | select(.id == "p2-enemy")] | length' "$STATE")
  # p1-mover must be at row=5 col=4
  P1_ROW=$($JQ '[.pieces[] | select(.id == "p1-mover")] | .[0].row' "$STATE")
  P1_COL=$($JQ '[.pieces[] | select(.id == "p1-mover")] | .[0].col' "$STATE")
  # turn must be 1 (started at 0, one move made)
  TURN=$($JQ '.turn' "$STATE")
  # current_player must be 2 (flipped after p1 move)
  CUR_PLAYER=$($JQ '.current_player' "$STATE")

  ERRORS=""
  [ "$P2_COUNT" = "0" ] || ERRORS="$ERRORS; p2-enemy still in pieces (count=$P2_COUNT)"
  [ "$P1_ROW" = "5" ]   || ERRORS="$ERRORS; p1-mover row=$P1_ROW (expected 5)"
  [ "$P1_COL" = "4" ]   || ERRORS="$ERRORS; p1-mover col=$P1_COL (expected 4)"
  [ "$TURN" = "1" ]     || ERRORS="$ERRORS; turn=$TURN (expected 1)"
  [ "$CUR_PLAYER" = "2" ] || ERRORS="$ERRORS; current_player=$CUR_PLAYER (expected 2)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 2: qa_collect_menu
# Starting: p1-a at (4,5) powers=[], orb at (4,4) power_id='raise_tile'.
# Inputs: click (4,5) select, click (4,4) move+collect, ai_turn, click (4,4) reselect.
# Assert: p1-a at (4,4) with powers containing 'raise_tile', orbs==[], selected=={row:4,col:4}.
# ---------------------------------------------------------------------------
STORY="qa_collect_menu"
run_scenario "$STORY" "qa_collect_menu.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  # p1-a must be at row=4 col=4
  P1_ROW=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].row' "$STATE")
  P1_COL=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].col' "$STATE")
  # p1-a must have 'raise_tile' in powers
  HAS_POWER=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].powers | contains(["raise_tile"])' "$STATE")
  # orbs must be empty
  ORB_COUNT=$($JQ '.orbs | length' "$STATE")
  # selected must be {row:4, col:4}
  SEL_ROW=$($JQ 'if .selected != null then .selected.row else -1 end' "$STATE")
  SEL_COL=$($JQ 'if .selected != null then .selected.col else -1 end' "$STATE")

  ERRORS=""
  [ "$P1_ROW" = "4" ]       || ERRORS="$ERRORS; p1-a row=$P1_ROW (expected 4)"
  [ "$P1_COL" = "4" ]       || ERRORS="$ERRORS; p1-a col=$P1_COL (expected 4)"
  [ "$HAS_POWER" = "true" ] || ERRORS="$ERRORS; p1-a powers missing 'raise_tile'"
  [ "$ORB_COUNT" = "0" ]    || ERRORS="$ERRORS; orbs not empty (count=$ORB_COUNT)"
  [ "$SEL_ROW" = "4" ]      || ERRORS="$ERRORS; selected.row=$SEL_ROW (expected 4)"
  [ "$SEL_COL" = "4" ]      || ERRORS="$ERRORS; selected.col=$SEL_COL (expected 4)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 3: qa_activate_power
# Starting: p1-a at (4,5) powers=['jump_proof'], is_jump_proof=false.
# Inputs: click (4,5) select, activate 'jump_proof' (self power, no target).
# Assert: p1-a.is_jump_proof==true, p1-a.powers does NOT contain 'jump_proof' (consumed).
# ---------------------------------------------------------------------------
STORY="qa_activate_power"
run_scenario "$STORY" "qa_activate_power.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  # p1-a must have is_jump_proof == true
  IS_JP=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].is_jump_proof' "$STATE")
  # p1-a must NOT have 'jump_proof' in powers (consumed)
  HAS_JP_IN_POWERS=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].powers | contains(["jump_proof"])' "$STATE")

  ERRORS=""
  [ "$IS_JP" = "true" ]          || ERRORS="$ERRORS; is_jump_proof=$IS_JP (expected true)"
  [ "$HAS_JP_IN_POWERS" = "false" ] || ERRORS="$ERRORS; 'jump_proof' still in powers (not consumed)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 4: qa_vs_ai
# Starting: p1-a at (3,5); p2-a (6,4), p2-b (6,5), p2-c (6,6).
# Inputs: click (3,5) select, click (4,5) move p1, ai_turn medium.
# Assert: current_player==1 (cycled back after 2 turns), status=='playing',
#         not ALL p2 pieces still at their original row-6 positions (AI moved).
# ---------------------------------------------------------------------------
STORY="qa_vs_ai"
run_scenario "$STORY" "qa_vs_ai.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  CUR_PLAYER=$($JQ '.current_player' "$STATE")
  STATUS=$($JQ -r '.status' "$STATE")
  # Check that at least one p2 piece has moved away from row 6
  # (all three were at row 6 at start; AI must have moved one)
  P2_AT_ROW6=$($JQ '[.pieces[] | select(.player == 2 and .row == 6)] | length' "$STATE")
  P2_TOTAL=$($JQ '[.pieces[] | select(.player == 2)] | length' "$STATE")

  ERRORS=""
  [ "$CUR_PLAYER" = "1" ]   || ERRORS="$ERRORS; current_player=$CUR_PLAYER (expected 1)"
  [ "$STATUS" = "playing" ] || ERRORS="$ERRORS; status=$STATUS (expected playing)"
  # If ALL p2 pieces are still at row 6, the AI didn't move
  if [ "$P2_AT_ROW6" = "$P2_TOTAL" ] && [ "$P2_TOTAL" != "0" ]; then
    ERRORS="$ERRORS; all $P2_TOTAL p2 pieces still at row 6 — AI may not have moved"
  fi

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 5: qa_win
# Starting: p1-last at (4,4), p2-last at (5,4) — p2's only piece.
# Inputs: click (4,4) select, click (5,4) capture (removes p2's last piece).
# Assert: status=='won', winner==1, no player-2 pieces in pieces[].
# ---------------------------------------------------------------------------
STORY="qa_win"
run_scenario "$STORY" "qa_win.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  STATUS=$($JQ -r '.status' "$STATE")
  WINNER=$($JQ '.winner' "$STATE")
  P2_COUNT=$($JQ '[.pieces[] | select(.player == 2)] | length' "$STATE")

  ERRORS=""
  [ "$STATUS" = "won" ]   || ERRORS="$ERRORS; status=$STATUS (expected won)"
  [ "$WINNER" = "1" ]     || ERRORS="$ERRORS; winner=$WINNER (expected 1)"
  [ "$P2_COUNT" = "0" ]   || ERRORS="$ERRORS; $P2_COUNT player-2 pieces remain (expected 0)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 6: qa_move_again
# Starting: p1-a at (4,5) powers=['move_again'].
# Inputs: click (4,5) select, activate 'move_again' (immediate, no target),
#         click (4,4) move — should NOT flip current_player (extra_move consumed).
# Assert: current_player==1 (turn NOT flipped), p1-a at (4,4), status=='playing'.
# ---------------------------------------------------------------------------
STORY="qa_move_again"
run_scenario "$STORY" "qa_move_again.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  CUR_PLAYER=$($JQ '.current_player' "$STATE")
  STATUS=$($JQ -r '.status' "$STATE")
  P1_ROW=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].row' "$STATE")
  P1_COL=$($JQ '[.pieces[] | select(.id == "p1-a")] | .[0].col' "$STATE")

  ERRORS=""
  [ "$CUR_PLAYER" = "1" ]   || ERRORS="$ERRORS; current_player=$CUR_PLAYER (expected 1 — turn must NOT flip on extra_move)"
  [ "$STATUS" = "playing" ] || ERRORS="$ERRORS; status=$STATUS (expected playing)"
  [ "$P1_ROW" = "4" ]       || ERRORS="$ERRORS; p1-a row=$P1_ROW (expected 4)"
  [ "$P1_COL" = "4" ]       || ERRORS="$ERRORS; p1-a col=$P1_COL (expected 4)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 7: qa_ai_power
# Starting: p1-mover at (3,5); p1-a at (5,6) and p1-b at (5,8);
#           p2-ai at (5,2) with powers=['destroy_row'].
# Inputs: click (3,5) select, click (4,5) move p1, ai_turn expert.
# Expected: AI uses destroy_row — at least one of p1-a / p1-b is gone.
# Assert: p1 piece count in state.json < 2 (started with 3, mover + 2 in row 5;
#         destroy_row must have hit at least one of p1-a or p1-b).
# ---------------------------------------------------------------------------
STORY="qa_ai_power"
run_scenario "$STORY" "qa_ai_power.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  # Count remaining p1 pieces in row 5 (p1-a and p1-b started there)
  P1_ROW5=$($JQ '[.pieces[] | select(.player == 1 and .row == 5)] | length' "$STATE")

  ERRORS=""
  # destroy_row should have destroyed both p1-a and p1-b (they were the only pieces
  # in row 5 besides p2-ai itself). Expect 0 p1 pieces remaining in row 5.
  [ "$P1_ROW5" = "0" ] || ERRORS="$ERRORS; p1 pieces still in row 5 (count=$P1_ROW5, expected 0 — AI may not have used destroy_row)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 8: qa_spyware (nnqr-43 — visual only)
# State: p1-spy at (4,5) with spyware_row; p2-revealed at (4,7) flagged
#        powers_revealed=true, powers=['jump_proof','shield']; revealed orb
#        at (4,3) power_id='raise_tile'; unrevealed orb at (2,8).
# Visual assertions (lead validates PNG):
#   - p2-revealed piece has purple tint ring + power label beneath token.
#   - Orb at (4,3) shows 'raise_tile' label; orb at (2,8) shows no label.
# State assertion: p2-revealed piece has powers_revealed==true in state.json.
# ---------------------------------------------------------------------------
STORY="qa_spyware"
run_scenario "$STORY" "qa_spyware.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  HAS_REVEALED=$($JQ '[.pieces[] | select(.id == "p2-revealed")] | .[0].powers_revealed // false' "$STATE")

  ERRORS=""
  [ "$HAS_REVEALED" = "true" ] || ERRORS="$ERRORS; p2-revealed.powers_revealed=$HAS_REVEALED (expected true)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Story 9: qa_invisible (nnqr-43 — visual only)
# State: p1-invis at (3,4) is_invisible=true; p2-invis at (6,7) is_invisible=true;
#        p1-normal at (2,2) and p2-normal at (7,8) are not invisible.
# Visual assertions (lead validates PNG):
#   - p1-invis and p2-invis render as ghost outlines with '?' label.
#   - p1-normal and p2-normal render as solid tokens.
# State assertion: is_invisible flags preserved in state.json.
# ---------------------------------------------------------------------------
STORY="qa_invisible"
run_scenario "$STORY" "qa_invisible.json"
STATE="$QA_DIR/state.json"
if [ ! -f "$STATE" ]; then
  fail "$STORY" "state.json not produced"
else
  P1_INVIS=$($JQ '[.pieces[] | select(.id == "p1-invis")] | .[0].is_invisible' "$STATE")
  P2_INVIS=$($JQ '[.pieces[] | select(.id == "p2-invis")] | .[0].is_invisible' "$STATE")
  P1_NORM=$($JQ '[.pieces[] | select(.id == "p1-normal")] | .[0].is_invisible' "$STATE")
  P2_NORM=$($JQ '[.pieces[] | select(.id == "p2-normal")] | .[0].is_invisible' "$STATE")

  ERRORS=""
  [ "$P1_INVIS" = "true" ]  || ERRORS="$ERRORS; p1-invis.is_invisible=$P1_INVIS (expected true)"
  [ "$P2_INVIS" = "true" ]  || ERRORS="$ERRORS; p2-invis.is_invisible=$P2_INVIS (expected true)"
  [ "$P1_NORM" = "false" ]  || ERRORS="$ERRORS; p1-normal.is_invisible=$P1_NORM (expected false)"
  [ "$P2_NORM" = "false" ]  || ERRORS="$ERRORS; p2-normal.is_invisible=$P2_NORM (expected false)"

  if [ -z "$ERRORS" ]; then
    pass "$STORY"
  else
    fail "$STORY" "${ERRORS#; }"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=== QA Stories: $pass_count passed, $fail_count failed ==="
echo "PNGs written to .qa/<story>.png (lead validates visuals)"

[ "$fail_count" -eq 0 ] || exit 1
