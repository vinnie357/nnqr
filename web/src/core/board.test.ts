import { describe, expect, it } from "vitest";
import {
  BOARD_COLS,
  BOARD_ROWS,
  createInitialState,
  checkWinner,
  getValidMoves,
  moveTo,
  pieceAt,
  selectPiece,
} from "./board";
import { createHeightMap } from "./height";
import type { GameState, Piece } from "./types";

describe("createInitialState", () => {
  it("builds a 10x8 board with 20 pieces per player", () => {
    const s = createInitialState();
    expect(s.cols).toBe(BOARD_COLS);
    expect(s.rows).toBe(BOARD_ROWS);
    expect(s.pieces.filter((p) => p.player === 1)).toHaveLength(20);
    expect(s.pieces.filter((p) => p.player === 2)).toHaveLength(20);
    expect(s.currentPlayer).toBe(1);
    expect(s.status).toBe("playing");
  });

  it("places player 1 on rows 1-2 and player 2 on rows 7-8", () => {
    const s = createInitialState();
    expect(s.pieces.filter((p) => p.player === 1).every((p) => p.row === 1 || p.row === 2)).toBe(true);
    expect(s.pieces.filter((p) => p.player === 2).every((p) => p.row === 7 || p.row === 8)).toBe(true);
  });
});

describe("getValidMoves", () => {
  it("locks the back row at the packed start (surrounded by edges + own pieces)", () => {
    const s = createInitialState();
    const back = pieceAt(s, 1, 1) as Piece;
    // (1,1): up/left are off-board; down (2,1) and right (1,2) are own pieces.
    expect(getValidMoves(s, back)).toEqual([]);
  });

  it("lets a front-row piece advance into the empty rank", () => {
    const s = createInitialState();
    const front = pieceAt(s, 2, 5) as Piece;
    // (2,5): up (1,5) and sides (2,4)/(2,6) are own pieces; only (3,5) is open.
    expect(getValidMoves(s, front)).toEqual([{ row: 3, col: 5, capture: false }]);
  });

  it("flags an enemy-occupied tile as a capture", () => {
    const s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [
        { id: "a", player: 1, row: 4, col: 4, powers: [] },
        { id: "b", player: 2, row: 4, col: 5, powers: [] },
      ],
      heightMap: createHeightMap(BOARD_ROWS, BOARD_COLS, 0),
      destroyedTiles: {},
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    const moves = getValidMoves(s, s.pieces[0] as Piece);
    expect(moves).toContainEqual({ row: 4, col: 5, capture: true });
  });

  it("excludes a +2 height tile a normal piece cannot climb", () => {
    const heightMap = createHeightMap(BOARD_ROWS, BOARD_COLS, 0);
    // piece is at height 0, target (4,5) is height 2 — climb of 2 is illegal
    heightMap[3]![4] = 2; // row 4, col 5 (0-indexed: row-1=3, col-1=4)
    const s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      heightMap,
      destroyedTiles: {},
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    const moves = getValidMoves(s, s.pieces[0] as Piece);
    expect(moves.find((m) => m.row === 4 && m.col === 5)).toBeUndefined();
  });

  it("allows dropping from a high tile to a low tile", () => {
    const heightMap = createHeightMap(BOARD_ROWS, BOARD_COLS, 0);
    // piece is at height 4, target (4,5) is height 0 — drop of 4 is legal
    heightMap[3]![3] = 4; // row 4, col 4 (0-indexed)
    const s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      heightMap,
      destroyedTiles: {},
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    const moves = getValidMoves(s, s.pieces[0] as Piece);
    expect(moves.find((m) => m.row === 4 && m.col === 5)).toEqual({ row: 4, col: 5, capture: false });
  });

  it("excludes a destroyed adjacent tile", () => {
    const s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      heightMap: createHeightMap(BOARD_ROWS, BOARD_COLS, 0),
      destroyedTiles: { "4,5": true },
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    const moves = getValidMoves(s, s.pieces[0] as Piece);
    expect(moves.find((m) => m.row === 4 && m.col === 5)).toBeUndefined();
  });

  it("grants diagonal moves when canMoveDiagonally is set", () => {
    const s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [], canMoveDiagonally: true }],
      heightMap: createHeightMap(BOARD_ROWS, BOARD_COLS, 0),
      destroyedTiles: {},
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    const moves = getValidMoves(s, s.pieces[0] as Piece);
    // Must include at least one diagonal move, e.g. (3,3)
    expect(moves.find((m) => m.row === 3 && m.col === 3)).toEqual({ row: 3, col: 3, capture: false });
    expect(moves.length).toBeGreaterThan(4);
  });

  it("cannot capture a jump-proof enemy", () => {
    const s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [
        { id: "a", player: 1, row: 4, col: 4, powers: [] },
        { id: "b", player: 2, row: 4, col: 5, powers: [], isJumpProof: true },
      ],
      heightMap: createHeightMap(BOARD_ROWS, BOARD_COLS, 0),
      destroyedTiles: {},
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    const moves = getValidMoves(s, s.pieces[0] as Piece);
    // The jump-proof enemy tile should not appear as a capture move
    expect(moves.find((m) => m.row === 4 && m.col === 5)).toBeUndefined();
  });
});

describe("selectPiece", () => {
  it("selects own piece and computes valid moves", () => {
    const s = selectPiece(createInitialState(), 2, 5);
    expect(s.selected).toEqual({ row: 2, col: 5 });
    expect(s.validMoves.length).toBeGreaterThan(0);
  });

  it("refuses to select the opponent's piece", () => {
    const s = selectPiece(createInitialState(), 8, 5);
    expect(s.selected).toBeNull();
    expect(s.validMoves).toEqual([]);
  });
});

describe("moveTo", () => {
  it("moves a piece, ends the turn, and increments the counter", () => {
    let s = createInitialState();
    s = selectPiece(s, 2, 5); // player 1 forward piece
    s = moveTo(s, 3, 5);
    expect(pieceAt(s, 3, 5)?.player).toBe(1);
    expect(pieceAt(s, 2, 5)).toBeNull();
    expect(s.currentPlayer).toBe(2);
    expect(s.turn).toBe(1);
    expect(s.selected).toBeNull();
  });

  it("captures an enemy on the target tile", () => {
    let s: GameState = {
      cols: BOARD_COLS,
      rows: BOARD_ROWS,
      pieces: [
        { id: "a", player: 1, row: 4, col: 4, powers: [] },
        { id: "b", player: 2, row: 4, col: 5, powers: [] },
      ],
      heightMap: createHeightMap(BOARD_ROWS, BOARD_COLS, 0),
      destroyedTiles: {},
      orbs: [],
      currentPlayer: 1,
      selected: null,
      validMoves: [],
      status: "playing",
      winner: null,
      turn: 0,
      seed: 1,
    };
    s = selectPiece(s, 4, 4);
    s = moveTo(s, 4, 5);
    expect(s.pieces).toHaveLength(1);
    expect(pieceAt(s, 4, 5)?.player).toBe(1);
    expect(s.status).toBe("won");
    expect(s.winner).toBe(1);
  });

  it("rejects an illegal move", () => {
    let s = selectPiece(createInitialState(), 2, 5);
    const before = s.pieces.length;
    s = moveTo(s, 6, 6); // not adjacent
    expect(s.pieces).toHaveLength(before);
    expect(s.currentPlayer).toBe(1); // turn not consumed
  });
});

describe("checkWinner", () => {
  it("returns null while both players have pieces", () => {
    expect(checkWinner(createInitialState())).toBeNull();
  });
});
