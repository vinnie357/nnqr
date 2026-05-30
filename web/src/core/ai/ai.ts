// AI dispatcher — `chooseMove` selects the best { piece, move } for a player.
// Ported from lua/love2d/src/shared/ai/ai.lua.
//
// Difficulty tiers
// ────────────────
//   easy   → uniform-random legal move (uses seeded rng, never Math.random)
//   medium → best move by heuristic evaluateBoard / scoreMove
//   hard   → minimax depth 2 with alpha-beta pruning
//   expert → minimax depth 4 with alpha-beta pruning
//             (breadth-capped at MAX_BRANCHING_FACTOR=10 per search.ts)
//
// POWER-ACTIVATION SEAM
// ─────────────────────
// Power activations are NOT included in the action set yet — the powers module
// is being built in parallel.  When it lands, extend the candidate set here
// with power-activation actions and score them via `scorePowerActivation`
// from evaluator.ts.  The seam is marked with the comment "// POWER SEAM"
// below and in evaluator.ts.

import type { GameState, Move, Piece, Player } from "../types";
import type { Rng } from "../rng";
import { getValidMoves } from "../board";
import { getBestMove, getAllMoves, scorePowerActivation } from "./evaluator";
import { findBestMove } from "./search";

export type Difficulty = "easy" | "medium" | "hard" | "expert";

/** The result of `chooseMove`. */
export interface AiDecision {
  piece: Piece;
  move: Move;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/**
 * Convert an AiMove ({ piece, target }) back to the `Move` shape used by the
 * board contract ({ row, col, capture }).
 */
function toMove(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number },
): Move | null {
  const legal = getValidMoves(state, piece);
  return legal.find((m) => m.row === target.row && m.col === target.col) ?? null;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Choose an action for `player` at the given `difficulty`.
 *
 * @param state      Current (immutable) game state
 * @param player     The AI player (1 or 2)
 * @param difficulty "easy" | "medium" | "hard" | "expert"
 * @param rng        Seeded RNG — used for random tie-breaks and easy selection.
 *                   Pass `makeRng(seed)` from rng.ts; never use Math.random.
 * @returns AiDecision or null when the player has no legal moves
 */
export function chooseMove(
  state: GameState,
  player: Player,
  difficulty: Difficulty,
  rng: Rng,
): AiDecision | null {
  // POWER SEAM: before building the move candidate set, gather power-activation
  // candidates for each of the player's pieces and score them via
  // `scorePowerActivation(state, piece, powerId)`.  If any activation scores
  // above the best movement score, return it as the decision instead.
  // Example skeleton (not active until powers module lands):
  //
  //   for (const piece of state.pieces.filter(p => p.player === player)) {
  //     for (const powerId of piece.powers) {
  //       const activationScore = scorePowerActivation(state, piece, powerId);
  //       if (activationScore > threshold) { ... return powerDecision; }
  //     }
  //   }
  //
  // The `scorePowerActivation` import is kept live so TypeScript confirms the
  // seam compiles correctly even before the body is filled in.
  void scorePowerActivation; // acknowledge import until powers module lands

  if (difficulty === "easy") {
    const moves = getAllMoves(state, player);
    if (moves.length === 0) return null;

    const chosen = rng.pick(moves);
    if (!chosen) return null;

    const boardMove = toMove(state, chosen.piece, chosen.target);
    if (!boardMove) return null;
    return { piece: chosen.piece, move: boardMove };
  }

  if (difficulty === "medium") {
    const aiMove = getBestMove(state, player);
    if (!aiMove) return null;

    const boardMove = toMove(state, aiMove.piece, aiMove.target);
    if (!boardMove) return null;
    return { piece: aiMove.piece, move: boardMove };
  }

  // hard = depth 2, expert = depth 4
  const depth = difficulty === "hard" ? 2 : 4;
  const aiMove = findBestMove(state, depth, player);
  if (!aiMove) return null;

  const boardMove = toMove(state, aiMove.piece, aiMove.target);
  if (!boardMove) return null;
  return { piece: aiMove.piece, move: boardMove };
}
