// TDD — failing tests for scorePowerActivation heuristics and chooseMove power integration.
// Written against the stub in evaluator.ts; all tests below must FAIL until implementation lands.
//
// Acceptance criteria (from nnqr-20):
//  AC1 — AI picks destroy_row/column when ≥2 enemies are in that line.
//  AC2 — AI activates jump_proof ONLY when the activating piece is threatened.
//  AC3 — Expert chooseMove completes within the turn-time budget.
//  AC4 — A piece with a single-use offensive power does NOT activate when no worthwhile target.

import { describe, expect, it } from "vitest";
import { BOARD_COLS, BOARD_ROWS } from "../board";
import { createHeightMap } from "../height";
import { makeRng } from "../rng";
import type { GameState, Piece } from "../types";
import { chooseMove } from "./ai";
import { scorePowerActivation } from "./evaluator";

// ---------------------------------------------------------------------------
// Minimal state builder (matches ai.test.ts pattern)
// ---------------------------------------------------------------------------
function makeState(
  p1Pieces: Array<{ row: number; col: number; extra?: Partial<Piece> }>,
  p2Pieces: Array<{ row: number; col: number; extra?: Partial<Piece> }>,
  overrides: Partial<GameState> = {},
): GameState {
  const pieces: Piece[] = [
    ...p1Pieces.map((p, i) => ({
      id: `p1-${i}`,
      player: 1 as const,
      row: p.row,
      col: p.col,
      powers: [] as string[],
      ...p.extra,
    })),
    ...p2Pieces.map((p, i) => ({
      id: `p2-${i}`,
      player: 2 as const,
      row: p.row,
      col: p.col,
      powers: [] as string[],
      ...p.extra,
    })),
  ];
  return {
    cols: BOARD_COLS,
    rows: BOARD_ROWS,
    pieces,
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
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// scorePowerActivation — destroy_row / destroy_column
// ---------------------------------------------------------------------------
describe("scorePowerActivation – destroy_row", () => {
  it("returns > 0 when ≥2 enemy pieces share the row and no allies are in the row", () => {
    // p1 piece at row 4, col 1, has destroy_row.
    // Two p2 pieces also in row 4 — threshold met.
    const p1Piece: Partial<Piece> = { powers: ["destroy_row"] };
    const state = makeState(
      [{ row: 4, col: 1, extra: p1Piece }],
      [{ row: 4, col: 5 }, { row: 4, col: 8 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "destroy_row");
    expect(score).toBeGreaterThan(0);
  });

  it("returns -Infinity when only 1 enemy is in the row (below threshold)", () => {
    const state = makeState(
      [{ row: 4, col: 1, extra: { powers: ["destroy_row"] } }],
      [{ row: 4, col: 5 }], // only 1 enemy
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "destroy_row");
    expect(score).toBe(-Infinity);
  });

  it("returns -Infinity when allies would also be destroyed", () => {
    // An ally at same row — do not waste the power.
    const state = makeState(
      [
        { row: 4, col: 1, extra: { powers: ["destroy_row"] } },
        { row: 4, col: 3 }, // ally in same row
      ],
      [{ row: 4, col: 5 }, { row: 4, col: 8 }],
    );
    const piece = state.pieces.find((p) => p.id === "p1-0")!;
    const score = scorePowerActivation(state, piece, "destroy_row");
    expect(score).toBe(-Infinity);
  });
});

describe("scorePowerActivation – destroy_column", () => {
  it("returns > 0 when ≥2 enemy pieces share the column and no allies in the column", () => {
    const state = makeState(
      [{ row: 1, col: 5, extra: { powers: ["destroy_column"] } }],
      [{ row: 3, col: 5 }, { row: 6, col: 5 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "destroy_column");
    expect(score).toBeGreaterThan(0);
  });

  it("returns -Infinity when no enemies are in the column", () => {
    const state = makeState(
      [{ row: 1, col: 5, extra: { powers: ["destroy_column"] } }],
      [{ row: 3, col: 7 }], // different column
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "destroy_column");
    expect(score).toBe(-Infinity);
  });
});

// ---------------------------------------------------------------------------
// scorePowerActivation — bomb / destroy_radial (area 3×3)
// ---------------------------------------------------------------------------
describe("scorePowerActivation – bomb", () => {
  it("returns > 0 when ≥2 enemies are in the 3×3 area and no allies", () => {
    // p1 at (4,5), two enemies adjacent
    const state = makeState(
      [{ row: 4, col: 5, extra: { powers: ["bomb"] } }],
      [{ row: 4, col: 6 }, { row: 3, col: 5 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "bomb");
    expect(score).toBeGreaterThan(0);
  });

  it("returns -Infinity when only 1 enemy is in the 3×3 area", () => {
    const state = makeState(
      [{ row: 4, col: 5, extra: { powers: ["bomb"] } }],
      [{ row: 4, col: 6 }], // single enemy
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "bomb");
    expect(score).toBe(-Infinity);
  });
});

// ---------------------------------------------------------------------------
// scorePowerActivation — jump_proof
// ---------------------------------------------------------------------------
describe("scorePowerActivation – jump_proof", () => {
  it("returns > 0 when the piece is in getThreatenedPieces (threatened)", () => {
    // p1 at (4,4), p2 at (3,4) — p2 can move to (4,4) and capture p1.
    const state = makeState(
      [{ row: 4, col: 4, extra: { powers: ["jump_proof"] } }],
      [{ row: 3, col: 4 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "jump_proof");
    expect(score).toBeGreaterThan(0);
  });

  it("returns -Infinity when the piece is NOT threatened", () => {
    // p2 is far away — no threat to p1.
    const state = makeState(
      [{ row: 1, col: 1, extra: { powers: ["jump_proof"] } }],
      [{ row: 8, col: 10 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "jump_proof");
    expect(score).toBe(-Infinity);
  });

  it("returns -Infinity when piece already has isJumpProof active", () => {
    // Already protected — no benefit activating again.
    const state = makeState(
      [{ row: 4, col: 4, extra: { powers: ["jump_proof"], isJumpProof: true } }],
      [{ row: 3, col: 4 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    const score = scorePowerActivation(state, piece, "jump_proof");
    expect(score).toBe(-Infinity);
  });
});

// ---------------------------------------------------------------------------
// scorePowerActivation — powers not in the piece's inventory
// ---------------------------------------------------------------------------
describe("scorePowerActivation – power not in inventory", () => {
  it("returns -Infinity when the piece doesn't have the power", () => {
    const state = makeState(
      [{ row: 4, col: 1, extra: { powers: [] } }],
      [{ row: 4, col: 5 }, { row: 4, col: 8 }],
    );
    const piece = state.pieces.find((p) => p.player === 1)!;
    // Piece has no destroy_row — should not activate.
    const score = scorePowerActivation(state, piece, "destroy_row");
    expect(score).toBe(-Infinity);
  });
});

// ---------------------------------------------------------------------------
// AC1 — chooseMove picks destroy_row when ≥2 enemies in same row (medium+)
// ---------------------------------------------------------------------------
describe("chooseMove – AC1: selects destroy_row activation", () => {
  // The AI's returned decision for a power activation must carry the powerId.
  // We check that chooseMove returns a power-activation decision (not a move)
  // when destroy_row is the clearly dominant action.
  it("medium AI returns a power activation for destroy_row when ≥2 enemies in row", () => {
    // p1 at row 4 col 1, with destroy_row. Two enemies in row 4.
    // No other moves score higher (enemies far away from p1 normal moves).
    const state = makeState(
      [{ row: 4, col: 1, extra: { powers: ["destroy_row"] } }],
      [{ row: 4, col: 8 }, { row: 4, col: 9 }],
      { currentPlayer: 1 },
    );
    const rng = makeRng(1);
    const decision = chooseMove(state, 1, "medium", rng);
    expect(decision).not.toBeNull();
    // Decision must carry powerId to indicate it's a power activation
    expect((decision as { powerId?: string }).powerId).toBe("destroy_row");
  });
});

// ---------------------------------------------------------------------------
// AC2 — chooseMove activates jump_proof only when threatened (medium+)
// ---------------------------------------------------------------------------
describe("chooseMove – AC2: jump_proof only when threatened", () => {
  it("medium AI activates jump_proof when piece is immediately threatened", () => {
    // p1 at (4,4) with jump_proof; p2 at (3,4) can capture next move.
    const state = makeState(
      [{ row: 4, col: 4, extra: { powers: ["jump_proof"] } }],
      [{ row: 3, col: 4 }],
      { currentPlayer: 1 },
    );
    const rng = makeRng(1);
    const decision = chooseMove(state, 1, "medium", rng);
    expect(decision).not.toBeNull();
    expect((decision as { powerId?: string }).powerId).toBe("jump_proof");
  });

  it("medium AI does NOT activate jump_proof when piece is not threatened", () => {
    // p1 at (1,1) with jump_proof; p2 is far away at (8,10), no threat.
    const state = makeState(
      [{ row: 1, col: 1, extra: { powers: ["jump_proof"] } }],
      [{ row: 8, col: 10 }],
      { currentPlayer: 1 },
    );
    const rng = makeRng(1);
    const decision = chooseMove(state, 1, "medium", rng);
    expect(decision).not.toBeNull();
    // Must be a regular move, not a jump_proof activation
    expect((decision as { powerId?: string }).powerId).toBeUndefined();
  });
});

// ---------------------------------------------------------------------------
// AC3 — expert chooseMove completes within a reasonable time budget
// ---------------------------------------------------------------------------
describe("chooseMove – AC3: expert completes within time budget", () => {
  it("expert difficulty returns within 5000 ms on a busy board with power candidates", () => {
    // 6 pieces per side; p1 pieces have various powers to stress the power candidate path.
    const state = makeState(
      [
        { row: 2, col: 2, extra: { powers: ["destroy_row"] } },
        { row: 2, col: 4, extra: { powers: ["bomb"] } },
        { row: 2, col: 6, extra: { powers: ["jump_proof"] } },
        { row: 2, col: 8, extra: { powers: [] } },
        { row: 3, col: 3, extra: { powers: [] } },
        { row: 3, col: 7, extra: { powers: [] } },
      ],
      [
        { row: 6, col: 2 },
        { row: 6, col: 4 },
        { row: 6, col: 6 },
        { row: 6, col: 8 },
        { row: 7, col: 3 },
        { row: 7, col: 7 },
      ],
      { currentPlayer: 1 },
    );
    const rng = makeRng(42);
    const start = Date.now();
    const decision = chooseMove(state, 1, "expert", rng);
    const elapsed = Date.now() - start;

    // Result must be a legal action or null; must not hang.
    expect(elapsed).toBeLessThan(5000);
    // If a decision was made it must be non-null (at least one move exists)
    expect(decision).not.toBeNull();
  });
});

// ---------------------------------------------------------------------------
// AC4 — single-use offensive power not activated when no worthwhile target
// ---------------------------------------------------------------------------
describe("chooseMove – AC4: no pointless single-use activation", () => {
  it("does NOT activate destroy_row when no enemies are in the row", () => {
    // p1 at (4,1) with destroy_row; enemies only in row 7 — no trigger condition.
    const state = makeState(
      [{ row: 4, col: 1, extra: { powers: ["destroy_row"] } }],
      [{ row: 7, col: 5 }, { row: 7, col: 8 }],
      { currentPlayer: 1 },
    );
    const rng = makeRng(1);
    const decision = chooseMove(state, 1, "medium", rng);
    expect(decision).not.toBeNull();
    // Must NOT be a destroy_row activation — no enemies in row 4
    expect((decision as { powerId?: string }).powerId).not.toBe("destroy_row");
  });

  it("does NOT activate bomb when only 1 enemy is in the 3×3 area", () => {
    // p1 at (4,5) with bomb; one enemy at (4,6) — wasteful single target.
    const state = makeState(
      [{ row: 4, col: 5, extra: { powers: ["bomb"] } }],
      [{ row: 4, col: 6 }],
      { currentPlayer: 1 },
    );
    const rng = makeRng(1);
    const decision = chooseMove(state, 1, "medium", rng);
    expect(decision).not.toBeNull();
    expect((decision as { powerId?: string }).powerId).not.toBe("bomb");
  });
});
