// Core board rules for the NNQR walking skeleton: 10x8 board, 20 pieces per
// player (rows 1-2 and 7-8), orthogonal single-step movement, capture by
// landing on an enemy, win by elimination. Ported from the canonical spec
// (research/game.md) and the Lua reference (lua/love2d/src/logic.lua). Height,
// powers, and orbs are added in later milestones (Track B2).

import type { GameState, Move, Piece, Player } from "./types";

export const BOARD_COLS = 10;
export const BOARD_ROWS = 8;

const ORTHOGONAL: ReadonlyArray<readonly [number, number]> = [
  [-1, 0],
  [1, 0],
  [0, -1],
  [0, 1],
];

function makePieces(player: Player): Piece[] {
  const rows = player === 1 ? [1, 2] : [BOARD_ROWS - 1, BOARD_ROWS];
  const pieces: Piece[] = [];
  for (const row of rows) {
    for (let col = 1; col <= BOARD_COLS; col++) {
      pieces.push({ id: `p${player}-${row}-${col}`, player, row, col, powers: [] });
    }
  }
  return pieces;
}

export function createInitialState(): GameState {
  return {
    cols: BOARD_COLS,
    rows: BOARD_ROWS,
    pieces: [...makePieces(1), ...makePieces(2)],
    currentPlayer: 1,
    selected: null,
    validMoves: [],
    status: "playing",
    winner: null,
    turn: 0,
  };
}

export function inBounds(row: number, col: number): boolean {
  return row >= 1 && row <= BOARD_ROWS && col >= 1 && col <= BOARD_COLS;
}

export function pieceAt(state: GameState, row: number, col: number): Piece | null {
  return state.pieces.find((p) => p.row === row && p.col === col) ?? null;
}

/** Orthogonal single-step moves to empty tiles or enemy-occupied tiles (capture). */
export function getValidMoves(state: GameState, piece: Piece): Move[] {
  const moves: Move[] = [];
  for (const [dr, dc] of ORTHOGONAL) {
    const row = piece.row + dr;
    const col = piece.col + dc;
    if (!inBounds(row, col)) continue;
    const occupant = pieceAt(state, row, col);
    if (!occupant) {
      moves.push({ row, col, capture: false });
    } else if (occupant.player !== piece.player) {
      moves.push({ row, col, capture: true });
    }
  }
  return moves;
}

export function checkWinner(state: GameState): Player | null {
  const p1 = state.pieces.some((p) => p.player === 1);
  const p2 = state.pieces.some((p) => p.player === 2);
  if (!p1) return 2;
  if (!p2) return 1;
  return null;
}

/** Select a piece belonging to the current player; clears selection otherwise. */
export function selectPiece(state: GameState, row: number, col: number): GameState {
  if (state.status !== "playing") return state;
  const piece = pieceAt(state, row, col);
  if (!piece || piece.player !== state.currentPlayer) {
    return { ...state, selected: null, validMoves: [] };
  }
  return { ...state, selected: { row, col }, validMoves: getValidMoves(state, piece) };
}

/**
 * Move the selected piece to (row, col) if it is a valid move. Captures any
 * enemy on the target, ends the turn, and resolves a winner. Returns the state
 * unchanged when the move is illegal.
 */
export function moveTo(state: GameState, row: number, col: number): GameState {
  if (state.status !== "playing" || !state.selected) return state;
  const move = state.validMoves.find((m) => m.row === row && m.col === col);
  if (!move) return state;

  const mover = pieceAt(state, state.selected.row, state.selected.col);
  if (!mover) return state;

  const pieces = state.pieces
    .filter((p) => !(p.row === row && p.col === col && p.player !== mover.player))
    .map((p) => (p.id === mover.id ? { ...p, row, col } : p));

  const next: GameState = {
    ...state,
    pieces,
    selected: null,
    validMoves: [],
    currentPlayer: state.currentPlayer === 1 ? 2 : 1,
    turn: state.turn + 1,
  };

  const winner = checkWinner(next);
  if (winner) {
    next.status = "won";
    next.winner = winner;
  }
  return next;
}
