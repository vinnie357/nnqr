// AI Search — minimax with alpha-beta pruning + capture-first move ordering.
// Ported from lua/love2d/src/shared/ai/search.lua.
//
// BREADTH CAP
// ───────────
// At each node we consider at most MAX_BRANCHING_FACTOR moves (captures first,
// then non-captures sorted by descending heuristic score). This keeps the
// expert search (depth 4) tractable even on a full 10×8 board where each
// player can have 20 pieces with up to 4 moves each (~80 raw moves).
//
// With cap=10 and depth=4 the worst-case node budget is 10^4 = 10 000 nodes,
// which typically completes in under 50 ms in a modern JS runtime.
// Without the cap, 80^4 ≈ 40 M nodes would be unacceptable for a game UI.

import type { GameState, Piece, Player } from "../types";
import { evaluateBoard, getAllMoves, scoreMove, type AiMove } from "./evaluator";

/** Maximum moves considered per node (captures always included first). */
export const MAX_BRANCHING_FACTOR = 10;

// ---------------------------------------------------------------------------
// State deep-copy
// ---------------------------------------------------------------------------

function copyState(state: GameState): GameState {
  return {
    cols: state.cols,
    rows: state.rows,
    currentPlayer: state.currentPlayer,
    turn: state.turn,
    status: state.status,
    winner: state.winner,
    selected: null,
    validMoves: [],
    orbs: state.orbs.map((o) => ({ ...o })),
    heightMap: state.heightMap.map((row) => [...row]),
    destroyedTiles: { ...state.destroyedTiles },
    seed: state.seed,
    pieces: state.pieces.map((p) => ({
      ...p,
      powers: [...p.powers],
    })),
  };
}

// ---------------------------------------------------------------------------
// Apply a move to a copied state (mutates copy in place — never the original)
// ---------------------------------------------------------------------------

function applyMove(state: GameState, movingPiece: Piece, target: { row: number; col: number }): void {
  // Remove captured piece (if any)
  const captureIdx = state.pieces.findIndex(
    (p) => p.row === target.row && p.col === target.col && p.player !== movingPiece.player,
  );
  if (captureIdx !== -1) state.pieces.splice(captureIdx, 1);

  // Move the piece
  const idx = state.pieces.findIndex((p) => p.id === movingPiece.id);
  if (idx !== -1) {
    const piece = state.pieces[idx];
    if (piece) {
      piece.row = target.row;
      piece.col = target.col;
    }
  }

  state.currentPlayer = state.currentPlayer === 1 ? 2 : 1;
  state.turn++;
}

// ---------------------------------------------------------------------------
// Move ordering: captures first, then non-captures by descending heuristic
// ---------------------------------------------------------------------------

export function orderMoves(state: GameState, moves: AiMove[]): AiMove[] {
  const captures: AiMove[] = [];
  const others: AiMove[] = [];

  for (const move of moves) {
    const isCapture = state.pieces.some(
      (p) => p.row === move.target.row && p.col === move.target.col && p.player !== move.piece.player,
    );
    if (isCapture) captures.push(move);
    else others.push(move);
  }

  // Sort non-captures by descending heuristic score for better pruning
  others.sort((a, b) => scoreMove(state, b) - scoreMove(state, a));

  return [...captures, ...others].slice(0, MAX_BRANCHING_FACTOR);
}

// ---------------------------------------------------------------------------
// Minimax with alpha-beta pruning (negamax formulation)
// ---------------------------------------------------------------------------

/**
 * Negamax (minimax reformulation): score is always from the perspective of
 * the player whose turn it is at this node.  The caller negates when bubbling.
 *
 * @param state  Current game state (will be deep-copied before mutation)
 * @param depth  Remaining plies to search
 * @param player The player whose move is being considered at this node
 * @param alpha  Lower bound on the maximising player's score
 * @param beta   Upper bound (cutoff threshold)
 * @returns [bestMove, score] — bestMove is null at leaf nodes
 */
function negamax(
  state: GameState,
  depth: number,
  player: Player,
  alpha: number,
  beta: number,
): [AiMove | null, number] {
  if (depth === 0) {
    return [null, evaluateBoard(state, player)];
  }

  const rawMoves = getAllMoves(state, player);
  if (rawMoves.length === 0) {
    return [null, evaluateBoard(state, player)];
  }

  const moves = orderMoves(state, rawMoves);
  const opponent: Player = player === 1 ? 2 : 1;

  let bestMove: AiMove | null = null;
  let bestScore = -Infinity;

  for (const move of moves) {
    const copy = copyState(state);
    // Find the corresponding piece in the copy by id
    const pieceCopy = copy.pieces.find((p) => p.id === move.piece.id);
    if (!pieceCopy) continue;

    applyMove(copy, pieceCopy, move.target);

    const [, childScore] = negamax(copy, depth - 1, opponent, -beta, -alpha);
    const score = -childScore;

    if (score > bestScore) {
      bestScore = score;
      bestMove = move;
    }

    alpha = Math.max(alpha, score);
    if (alpha >= beta) break; // Beta cutoff
  }

  return [bestMove, bestScore];
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Find the best move for `player` via minimax to `depth` plies.
 * Returns null when no legal moves exist.
 *
 * Expert (depth 4) is capped at MAX_BRANCHING_FACTOR=10 moves per node,
 * giving a worst-case budget of 10^4 = 10 000 nodes.
 */
export function findBestMove(state: GameState, depth: number, player: Player): AiMove | null {
  const [move] = negamax(state, depth, player, -Infinity, Infinity);
  return move;
}
