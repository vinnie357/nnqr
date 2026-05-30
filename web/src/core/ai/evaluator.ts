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
// POWER-ACTIVATION SEAM (stub — implement when powers module lands)
// ---------------------------------------------------------------------------

/**
 * Score the expected gain of activating `powerId` for `piece` in `state`.
 *
 * Positive return value means activation is beneficial for the piece's owner.
 * Return -Infinity to mark a power as not applicable in the current position.
 *
 * This stub always returns -Infinity (no power use), which keeps the AI
 * playing pure movement until the powers module author drops in the real
 * implementation.  The ai.ts chooseMove function consults this function
 * whenever it builds the candidate action set for medium/hard/expert.
 */
export function scorePowerActivation(
  _state: GameState,
  _piece: Piece,
  _powerId: string,
): number {
  return -Infinity;
}
