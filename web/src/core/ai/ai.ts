// AI dispatcher — `chooseMove` selects the best { piece, move } for a player.
// Ported from lua/love2d/src/shared/ai/ai.lua.
//
// Difficulty tiers
// ────────────────
//   easy   → uniform-random legal move (uses seeded rng, never Math.random)
//   medium → best move by heuristic evaluateBoard / scoreMove; power candidates
//             are evaluated and may replace the movement decision when they score
//             higher.
//   hard   → minimax depth 2 + power activation candidates folded in.
//   expert → minimax depth 4 + power activation candidates (same folding approach
//             as hard; branching factor stays bounded by MAX_POWER_CANDIDATES).

import type { GameState, Move, Piece, Player } from "../types";
import type { Rng } from "../rng";
import { getValidMoves } from "../board";
import { getBestMove, getAllMoves, scoreMove, scorePowerActivation } from "./evaluator";
import { findBestMove } from "./search";

export type Difficulty = "easy" | "medium" | "hard" | "expert";

/**
 * The result of `chooseMove`.
 *
 * When `powerId` is present the AI has decided to activate that power for
 * `piece`.  In this case `move` is absent and the caller should invoke
 * `executor.execute(state, piece, powerId, target)` rather than applying a
 * board move.
 *
 * When `powerId` is absent the AI has chosen a normal board move described
 * by `move`.
 */
export interface AiDecision {
  piece: Piece;
  move?: Move;
  /** Present only when the AI chose a power activation instead of a move. */
  powerId?: string;
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
// Power activation candidate gathering (medium / hard / expert only)
// ---------------------------------------------------------------------------

/**
 * Maximum power-activation candidates to fold into the action set.
 * Keeps the branching factor bounded even when pieces carry many powers.
 * Power candidates are evaluated at root depth only (not inside minimax) —
 * the search tree for moves remains unchanged.
 */
const MAX_POWER_CANDIDATES = 3;

interface PowerCandidate {
  piece: Piece;
  powerId: string;
  score: number;
}

/**
 * Gather the top-K power-activation candidates for `player`, scored via
 * `scorePowerActivation`.  Candidates with score === -Infinity are excluded.
 * Powers are de-duplicated per piece (duplicates in inventory don't produce
 * additional candidates — the highest-score unique powerId wins).
 */
function gatherPowerCandidates(state: GameState, player: Player): PowerCandidate[] {
  const candidates: PowerCandidate[] = [];

  for (const piece of state.pieces) {
    if (piece.player !== player) continue;
    const seen = new Set<string>();
    for (const powerId of piece.powers) {
      if (seen.has(powerId)) continue;
      seen.add(powerId);
      const score = scorePowerActivation(state, piece, powerId);
      if (score !== -Infinity) {
        candidates.push({ piece, powerId, score });
      }
    }
  }

  candidates.sort((a, b) => b.score - a.score);
  return candidates.slice(0, MAX_POWER_CANDIDATES);
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
    // Gather power-activation candidates and score the best movement option.
    const powerCandidates = gatherPowerCandidates(state, player);
    const aiMove = getBestMove(state, player);
    const bestMoveScore = aiMove ? scoreMove(state, aiMove) : -Infinity;

    // Prefer a power activation when it scores strictly above the best move.
    if (powerCandidates.length > 0 && powerCandidates[0]!.score > bestMoveScore) {
      const best = powerCandidates[0]!;
      return { piece: best.piece, powerId: best.powerId };
    }

    if (!aiMove) return null;
    const boardMove = toMove(state, aiMove.piece, aiMove.target);
    if (!boardMove) return null;
    return { piece: aiMove.piece, move: boardMove };
  }

  // hard = depth 2, expert = depth 4
  const depth = difficulty === "hard" ? 2 : 4;

  // Gather power candidates at root level; compare heuristically against the
  // minimax move rather than re-running search over all power actions (that
  // would multiply the branching factor).
  const powerCandidates = gatherPowerCandidates(state, player);
  const aiMove = findBestMove(state, depth, player);

  if (powerCandidates.length > 0) {
    const minimaxMoveScore = aiMove ? scoreMove(state, aiMove) : -Infinity;
    if (powerCandidates[0]!.score > minimaxMoveScore) {
      const best = powerCandidates[0]!;
      return { piece: best.piece, powerId: best.powerId };
    }
  }

  if (!aiMove) return null;
  const boardMove = toMove(state, aiMove.piece, aiMove.target);
  if (!boardMove) return null;
  return { piece: aiMove.piece, move: boardMove };
}
