// Core board rules: 10x8 board, 20 pieces per player (rows 1-2 and 7-8),
// orthogonal single-step movement (diagonal/wrap via power flags), terrain-height
// climb limits, capture by landing on an enemy (unless jump-proof), win by
// elimination. Ported from research/game.md and lua/love2d (logic.lua,
// power_effects.lua getValidMovesWithPowers). Powers, orbs (collection), and AI
// build on this contract in their own modules.

import { canClimb, createHeightMap, getHeight } from "./height";
import type { GameState, Move, Piece, Player } from "./types";
import { tileKey } from "./types";

export const BOARD_COLS = 10;
export const BOARD_ROWS = 8;

const ORTHOGONAL: ReadonlyArray<readonly [number, number]> = [
  [-1, 0],
  [1, 0],
  [0, -1],
  [0, 1],
];
const DIAGONAL: ReadonlyArray<readonly [number, number]> = [
  [-1, -1],
  [-1, 1],
  [1, -1],
  [1, 1],
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

export function createInitialState(seed = 1): GameState {
  return {
    cols: BOARD_COLS,
    rows: BOARD_ROWS,
    pieces: [...makePieces(1), ...makePieces(2)],
    heightMap: createHeightMap(BOARD_ROWS, BOARD_COLS, 0),
    destroyedTiles: {},
    orbs: [],
    currentPlayer: 1,
    selected: null,
    validMoves: [],
    status: "playing",
    winner: null,
    turn: 0,
    seed,
  };
}

export function inBounds(row: number, col: number): boolean {
  return row >= 1 && row <= BOARD_ROWS && col >= 1 && col <= BOARD_COLS;
}

export function pieceAt(state: GameState, row: number, col: number): Piece | null {
  return state.pieces.find((p) => p.row === row && p.col === col) ?? null;
}

export function isDestroyed(state: GameState, row: number, col: number): boolean {
  return state.destroyedTiles[tileKey(row, col)] === true;
}

/** A jump-proof piece cannot be captured by normal movement. */
export function canCapture(_state: GameState, _attacker: Piece, target: Piece): boolean {
  return !target.isJumpProof;
}

function wrap(row: number, col: number): { row: number; col: number } {
  let r = row;
  let c = col;
  if (r < 1) r = BOARD_ROWS;
  else if (r > BOARD_ROWS) r = 1;
  if (c < 1) c = BOARD_COLS;
  else if (c > BOARD_COLS) c = 1;
  return { row: r, col: c };
}

/**
 * Valid single-step moves, honoring the piece's power flags: diagonal movement,
 * edge wrap, unrestricted climbing, and jump-proof capture immunity.
 */
export function getValidMoves(state: GameState, piece: Piece): Move[] {
  const moves: Move[] = [];
  const fromHeight = getHeight(state.heightMap, piece.row, piece.col);
  const dirs = piece.canMoveDiagonally ? [...ORTHOGONAL, ...DIAGONAL] : ORTHOGONAL;

  for (const [dr, dc] of dirs) {
    let row = piece.row + dr;
    let col = piece.col + dc;
    if (piece.canWrap) ({ row, col } = wrap(row, col));
    if (!inBounds(row, col)) continue;
    if (isDestroyed(state, row, col)) continue;

    const toHeight = getHeight(state.heightMap, row, col);
    if (!piece.canClimbAny && !canClimb(fromHeight, toHeight)) continue;

    const occupant = pieceAt(state, row, col);
    if (!occupant) {
      moves.push({ row, col, capture: false });
    } else if (occupant.player !== piece.player && canCapture(state, piece, occupant)) {
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
 * Move the selected piece to (row, col) if legal: captures an enemy on the
 * target, ends the turn, and resolves a winner. Orb collection is layered on by
 * the orbs module at the call site. Returns state unchanged when illegal.
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
