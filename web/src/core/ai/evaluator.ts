// AI Evaluator — heuristic board scoring.
// Ported from lua/love2d/src/shared/ai/evaluator.lua.
//
// POWER-ACTIVATION SEAM
// ─────────────────────
// The evaluator currently scores only piece *moves* (position, capture, orb).
// When the powers module is ready, power activation candidates should be added
// to the action set at the call site in ai.ts (see the comment "POWER SEAM"
// there). Here, the relevant hook surface is `scorePowerActivation`:
//
//   scorePowerActivation(state: GameState, piece: Piece, powerId: string): number
//
// Implement it to return the expected gain of activating `powerId` for `piece`
// in `state` (positive = beneficial). The signature is intentionally left as a
// stub so the powers module author can drop in the implementation without
// touching search.ts or ai.ts.

import { getHeight } from "../height";
import type { GameState, Orb, Piece, Player } from "../types";
import { getValidMoves } from "../board";

// ---------------------------------------------------------------------------
// Scoring weights (direct port of Lua WEIGHTS table)
// ---------------------------------------------------------------------------

export const WEIGHTS = {
  CENTER_BONUS: 10,
  HEIGHT_BONUS: 5,
  POWER_BONUS: 8,
  JUMP_PROOF_BONUS: 15,
  DIAGONAL_BONUS: 10,
  ORB_BASE_VALUE: 15,
  CAPTURE_BONUS: 50,
  CAPTURE_VALUE_MULT: 2,
  THREAT_PENALTY: 30,
  POSITION_WEIGHT: 1,
  RISKY_ORB_PENALTY: 20,
  PIECE_VALUE: 100,
  WIN_BONUS: 10000,
} as const;

// Power value scores for orb collection priority
export const POWER_VALUES: Record<string, number> = {
  bomb: 25,
  destroy_row: 20,
  destroy_column: 20,
  recruit: 22,
  jump_proof: 18,
  move_diagonal: 15,
  move_again: 12,
  relocate: 10,
  raise_tile: 8,
  lower_tile: 8,
  multiply: 18,
  invisible: 12,
  refurb: 6,
};

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/** Board center coordinates (1-based, fractional for even dimensions). */
const CENTER_ROW = (8 + 1) / 2; // 4.5
const CENTER_COL = (10 + 1) / 2; // 5.5
const MAX_DIST = Math.sqrt(CENTER_ROW ** 2 + CENTER_COL ** 2);

/**
 * Score a board tile by its centrality and height.
 * Returns 0 for destroyed tiles.
 */
export function scorePosition(state: GameState, row: number, col: number): number {
  if (state.destroyedTiles[`${row},${col}`]) return 0;

  const distFromCenter = Math.sqrt((row - CENTER_ROW) ** 2 + (col - CENTER_COL) ** 2);
  const centerFactor = 1 - distFromCenter / MAX_DIST;
  const heightVal = getHeight(state.heightMap, row, col);

  return centerFactor * WEIGHTS.CENTER_BONUS + heightVal * WEIGHTS.HEIGHT_BONUS;
}

/**
 * Score a piece's position including power-inventory and flag bonuses.
 */
export function scorePiecePosition(state: GameState, piece: Piece): number {
  let score = scorePosition(state, piece.row, piece.col);
  score += piece.powers.length * WEIGHTS.POWER_BONUS;
  if (piece.isJumpProof) score += WEIGHTS.JUMP_PROOF_BONUS;
  if (piece.canMoveDiagonally) score += WEIGHTS.DIAGONAL_BONUS;
  return score;
}

// ---------------------------------------------------------------------------
// Threat / capture helpers
// ---------------------------------------------------------------------------

/**
 * Returns player's pieces that an opponent can capture on the very next move.
 */
export function getThreatenedPieces(state: GameState, player: Player): Piece[] {
  const opponent: Player = player === 1 ? 2 : 1;
  const threatened: Piece[] = [];

  for (const enemy of state.pieces) {
    if (enemy.player !== opponent) continue;
    for (const move of getValidMoves(state, enemy)) {
      if (!move.capture) continue;
      for (const ours of state.pieces) {
        if (ours.player === player && ours.row === move.row && ours.col === move.col) {
          if (!threatened.includes(ours)) threatened.push(ours);
        }
      }
    }
  }
  return threatened;
}

/** { piece, target, targetPiece } tuples where player can capture an enemy. */
export interface CaptureOpportunity {
  piece: Piece;
  target: { row: number; col: number };
  targetPiece: Piece;
}

export function getCaptureOpportunities(state: GameState, player: Player): CaptureOpportunity[] {
  const opps: CaptureOpportunity[] = [];
  for (const piece of state.pieces) {
    if (piece.player !== player) continue;
    for (const move of getValidMoves(state, piece)) {
      if (!move.capture) continue;
      const enemy = state.pieces.find((p) => p.row === move.row && p.col === move.col && p.player !== player);
      if (enemy) opps.push({ piece, target: { row: move.row, col: move.col }, targetPiece: enemy });
    }
  }
  return opps;
}

// ---------------------------------------------------------------------------
// Orb helpers
// ---------------------------------------------------------------------------

export function scoreOrbValue(orb: Orb): number {
  return POWER_VALUES[orb.powerId] ?? WEIGHTS.ORB_BASE_VALUE;
}

/**
 * True if an enemy can reach `target` on their next move (risky orb collection).
 */
export function isOrbCollectionRisky(state: GameState, player: Player, target: { row: number; col: number }): boolean {
  const opponent: Player = player === 1 ? 2 : 1;
  for (const enemy of state.pieces) {
    if (enemy.player !== opponent) continue;
    for (const move of getValidMoves(state, enemy)) {
      if (move.row === target.row && move.col === target.col) return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Move helpers
// ---------------------------------------------------------------------------

export interface AiMove {
  piece: Piece;
  target: { row: number; col: number };
}

/** All legal moves for `player` as { piece, target } pairs. */
export function getAllMoves(state: GameState, player: Player): AiMove[] {
  const moves: AiMove[] = [];
  for (const piece of state.pieces) {
    if (piece.player !== player) continue;
    for (const m of getValidMoves(state, piece)) {
      moves.push({ piece, target: { row: m.row, col: m.col } });
    }
  }
  return moves;
}

// ---------------------------------------------------------------------------
// Move scoring (heuristic, used by medium AI and minimax leaf fallback)
// ---------------------------------------------------------------------------

/**
 * Score a single move for `player` using heuristics.
 * Higher = better for `player`.
 */
export function scoreMove(state: GameState, move: AiMove): number {
  const { piece, target } = move;
  const player = piece.player;
  let score = 0;

  // 1. Position improvement
  const curPosScore = scorePosition(state, piece.row, piece.col);
  const newPosScore = scorePosition(state, target.row, target.col);
  score += (newPosScore - curPosScore) * WEIGHTS.POSITION_WEIGHT;
  score += newPosScore * 0.5; // base attractiveness of destination

  // 2. Capture bonus
  const targetPiece = state.pieces.find((p) => p.row === target.row && p.col === target.col && p.player !== player);
  if (targetPiece) {
    score += WEIGHTS.CAPTURE_BONUS;
    score += scorePiecePosition(state, targetPiece) * WEIGHTS.CAPTURE_VALUE_MULT;
  }

  // 3. Orb collection bonus
  const orbAtTarget = state.orbs.find((o) => o.row === target.row && o.col === target.col);
  if (orbAtTarget) {
    score += scoreOrbValue(orbAtTarget);
    if (isOrbCollectionRisky(state, player, target)) {
      score -= WEIGHTS.RISKY_ORB_PENALTY;
    }
  }

  // 4. Threat penalty (moving into a square the opponent can immediately capture)
  if (!targetPiece) {
    if (isOrbCollectionRisky(state, player, target)) {
      score -= WEIGHTS.THREAT_PENALTY;
    }
  }

  return score;
}

/**
 * Return the best move for `player` by heuristic evaluation alone.
 * Tie-breaks are deterministic (first-best in iteration order).
 */
export function getBestMove(state: GameState, player: Player): AiMove | null {
  const moves = getAllMoves(state, player);
  if (moves.length === 0) return null;

  let best: AiMove | null = null;
  let bestScore = -Infinity;

  for (const move of moves) {
    const s = scoreMove(state, move);
    if (s > bestScore) {
      bestScore = s;
      best = move;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// Full board evaluation (used by minimax)
// ---------------------------------------------------------------------------

/**
 * Evaluate the board from `player`'s perspective.
 * Positive = good for player, negative = bad.
 */
export function evaluateBoard(state: GameState, player: Player): number {
  if (state.pieces.length === 0) return 0;

  let myScore = 0;
  let oppScore = 0;
  let myCount = 0;
  let oppCount = 0;

  for (const piece of state.pieces) {
    const val = WEIGHTS.PIECE_VALUE + scorePiecePosition(state, piece);
    if (piece.player === player) {
      myScore += val;
      myCount++;
    } else {
      oppScore += val;
      oppCount++;
    }
  }

  if (oppCount === 0 && myCount > 0) return WEIGHTS.WIN_BONUS + myScore;
  if (myCount === 0 && oppCount > 0) return -(WEIGHTS.WIN_BONUS + oppScore);

  return myScore - oppScore;
}

// ---------------------------------------------------------------------------
// POWER-ACTIVATION SEAM (implementation)
// ---------------------------------------------------------------------------

/**
 * Score the expected gain of activating `powerId` for `piece` in `state`.
 *
 * Positive return value means activation is beneficial for the piece's owner.
 * Return -Infinity to mark a power as not applicable in the current position.
 *
 * Heuristics ported from lua/love2d/src/shared/ai/evaluator.lua:
 *   - destroy_row / kamikaze_row / acidic_row / recruit_row / scramble_row:
 *       score = enemyHits * CAPTURE_BONUS — but only when ≥2 enemies in row
 *       AND no allies in row (avoid self-harm).
 *   - destroy_column / kamikaze_column / acidic_column / recruit_column / scramble_column:
 *       same logic along column axis.
 *   - destroy_radial / bomb / kamikaze_radial / smart_bombs / acidic_radial:
 *       score = enemyHits * CAPTURE_BONUS — only when ≥2 enemies in 3×3 area
 *       AND no allies in area.
 *   - jump_proof: score = JUMP_PROOF_BONUS when piece is threatened AND not
 *       already jump-proof; -Infinity otherwise.
 *   - Unknown or non-combat powers: -Infinity (not handled; AI ignores them).
 *
 * If the piece does not have the power in its inventory the function returns
 * -Infinity so the candidate is never selected.
 */
export function scorePowerActivation(
  state: GameState,
  piece: Piece,
  powerId: string,
): number {
  // Piece must actually own the power.
  if (!piece.powers.includes(powerId)) return -Infinity;

  const player = piece.player;

  // --- Row-targeting offensive powers ---
  if (
    powerId === "destroy_row" ||
    powerId === "kamikaze_row" ||
    powerId === "acidic_row" ||
    powerId === "recruit_row" ||
    powerId === "scramble_row" ||
    powerId === "pilfer_row" ||
    powerId === "trench_row" ||
    powerId === "wall_row" ||
    powerId === "invert_row" ||
    powerId === "dredge_row" ||
    powerId === "tripwire_row" ||
    powerId === "bankrupt_row" ||
    powerId === "inhibit_row" ||
    powerId === "parasite_row" ||
    powerId === "teach_row" ||
    powerId === "learn_row" ||
    powerId === "purify_row" ||
    powerId === "refurb_row" ||
    powerId === "spyware_row" ||
    powerId === "orb_spy_row"
  ) {
    let enemiesInRow = 0;
    let alliesInRow = 0;
    for (const p of state.pieces) {
      if (p === piece) continue;
      if (p.row !== piece.row) continue;
      if (p.player === player) alliesInRow++;
      else enemiesInRow++;
    }
    // Threshold: ≥2 enemies, zero allies (avoid friendly fire).
    if (enemiesInRow >= 2 && alliesInRow === 0) {
      return enemiesInRow * WEIGHTS.CAPTURE_BONUS;
    }
    return -Infinity;
  }

  // --- Column-targeting offensive powers ---
  if (
    powerId === "destroy_column" ||
    powerId === "kamikaze_column" ||
    powerId === "acidic_column" ||
    powerId === "recruit_column" ||
    powerId === "scramble_column" ||
    powerId === "pilfer_column" ||
    powerId === "trench_column" ||
    powerId === "wall_column" ||
    powerId === "invert_column" ||
    powerId === "dredge_column" ||
    powerId === "tripwire_column" ||
    powerId === "bankrupt_column" ||
    powerId === "inhibit_column" ||
    powerId === "parasite_column" ||
    powerId === "teach_column" ||
    powerId === "learn_column" ||
    powerId === "purify_column" ||
    powerId === "refurb_column" ||
    powerId === "spyware_column" ||
    powerId === "orb_spy_column"
  ) {
    let enemiesInCol = 0;
    let alliesInCol = 0;
    for (const p of state.pieces) {
      if (p === piece) continue;
      if (p.col !== piece.col) continue;
      if (p.player === player) alliesInCol++;
      else enemiesInCol++;
    }
    if (enemiesInCol >= 2 && alliesInCol === 0) {
      return enemiesInCol * WEIGHTS.CAPTURE_BONUS;
    }
    return -Infinity;
  }

  // --- Area (3×3) offensive powers ---
  if (
    powerId === "destroy_radial" ||
    powerId === "bomb" ||
    powerId === "kamikaze_radial" ||
    powerId === "smart_bombs" ||
    powerId === "acidic_radial" ||
    powerId === "pilfer_radial" ||
    powerId === "scramble_radial" ||
    powerId === "teach_radial" ||
    powerId === "learn_radial" ||
    powerId === "dredge_radial" ||
    powerId === "tripwire_radial" ||
    powerId === "bankrupt_radial" ||
    powerId === "inhibit_radial" ||
    powerId === "parasite_radial" ||
    powerId === "refurb_radial" ||
    powerId === "purify_radial" ||
    powerId === "spyware_radial" ||
    powerId === "orb_spy_radial"
  ) {
    let enemiesInArea = 0;
    let alliesInArea = 0;
    for (const p of state.pieces) {
      if (p === piece) continue;
      const dr = Math.abs(p.row - piece.row);
      const dc = Math.abs(p.col - piece.col);
      if (dr > 1 || dc > 1) continue;
      if (p.player === player) alliesInArea++;
      else enemiesInArea++;
    }
    if (enemiesInArea >= 2 && alliesInArea === 0) {
      return enemiesInArea * WEIGHTS.CAPTURE_BONUS;
    }
    return -Infinity;
  }

  // --- Defensive: jump_proof ---
  if (powerId === "jump_proof") {
    // Already active — no benefit.
    if (piece.isJumpProof) return -Infinity;
    // Only activate when this piece is under immediate threat.
    const threatened = getThreatenedPieces(state, player);
    if (threatened.some((t) => t.id === piece.id)) {
      // Score reflects survival value: piece base value + position + jump-proof bonus.
      // This must beat a normal capture move score (CAPTURE_BONUS ≈ 50) so the AI
      // prefers saving a threatened piece over most alternative actions.
      return WEIGHTS.PIECE_VALUE + scorePiecePosition(state, piece) + WEIGHTS.JUMP_PROOF_BONUS;
    }
    return -Infinity;
  }

  // All other powers (movement, terrain, meta, utility, etc.) are not yet
  // evaluated for autonomous AI activation.
  return -Infinity;
}
