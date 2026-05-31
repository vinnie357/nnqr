// Tests for grow_quadradius range extension (nnqr-41).
//
// Spec (research/quadradius/game_details/powers.md §Grow Quadradius):
//   For a power activated by a piece with level L = growQuadradiusLevel ?? 0:
//   - radial: Chebyshev distance 1+L, center excluded (L0→8, L1→24, L2→48, clamped at board)
//   - row: band [r-L, r+L] (2L+1 rows), full board width, center excluded
//   - column: band [c-L, c+L], full board height, center excluded
//   L=0 MUST reproduce today's exact behavior.

import { describe, expect, it } from "vitest";
import { createHeightMap } from "../height";
import type { GameState, Piece, Player } from "../types";
import {
  activateDestroyRadial,
  activateDestroyRow,
  activateDestroyColumn,
  activateAcidicRadial,
  activateAcidicRow,
  activateAcidicColumn,
} from "./effects";

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

function makePiece(
  id: string,
  player: Player,
  row: number,
  col: number,
  powers: string[] = [],
  extraFields: Record<string, unknown> = {},
): Piece {
  return { id, player, row, col, powers, ...extraFields } as Piece;
}

function baseState(overrides: Partial<GameState> = {}): GameState {
  return {
    cols: 10,
    rows: 8,
    pieces: [],
    heightMap: createHeightMap(8, 10, 0),
    destroyedTiles: {},
    orbs: [],
    currentPlayer: 1,
    selected: null,
    validMoves: [],
    status: "playing",
    winner: null,
    turn: 1,
    seed: 42,
    ...overrides,
  };
}

/** Make a piece with growQuadradiusLevel set. */
function grownPiece(
  id: string,
  player: Player,
  row: number,
  col: number,
  level: number,
  powers: string[] = [],
): Piece {
  return makePiece(id, player, row, col, powers, { growQuadradiusLevel: level });
}

// ---------------------------------------------------------------------------
// 1. L=0 radial: exactly 8 surrounding tiles, center excluded (regression gate)
// ---------------------------------------------------------------------------

describe("areaPieces radial — L=0 (regression)", () => {
  it("destroy_radial at L=0 hits exactly the 8 surrounding pieces", () => {
    // Piece at center (4,5). Place 8 enemies around it + 1 distant.
    const piece = makePiece("p1", 1, 4, 5, ["destroy_radial"]);
    const ring: Piece[] = [
      makePiece("e00", 2, 3, 4),
      makePiece("e01", 2, 3, 5),
      makePiece("e02", 2, 3, 6),
      makePiece("e10", 2, 4, 4),
      makePiece("e12", 2, 4, 6),
      makePiece("e20", 2, 5, 4),
      makePiece("e21", 2, 5, 5),
      makePiece("e22", 2, 5, 6),
    ];
    const distant = makePiece("far", 2, 1, 1);
    const state = baseState({ pieces: [piece, ...ring, distant] });

    const next = activateDestroyRadial(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    // Activating piece survives
    expect(ids.has("p1")).toBe(true);
    // All 8 ring enemies destroyed
    for (const e of ring) {
      expect(ids.has(e.id), `${e.id} should be destroyed`).toBe(false);
    }
    // Distant piece survives
    expect(ids.has("far")).toBe(true);
  });

  it("destroy_radial L=0 does NOT reach Chebyshev distance 2", () => {
    const piece = makePiece("p1", 1, 4, 5, ["destroy_radial"]);
    const dist2 = makePiece("d2", 2, 4, 7); // col+2 away
    const state = baseState({ pieces: [piece, dist2] });

    const next = activateDestroyRadial(state, piece);
    expect(next.pieces.some((p) => p.id === "d2")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 2. L=1 radial: 5×5 minus center = 24 tiles
// ---------------------------------------------------------------------------

describe("areaPieces radial — L=1", () => {
  it("destroy_radial at L=1 hits pieces at Chebyshev distance ≤2 (excluding self)", () => {
    // Piece at (4,5). An enemy at Chebyshev dist=2 (row=4, col=7 → dr=0, dc=2)
    // should be hit by L=1 but NOT by L=0.
    const piece = grownPiece("p1", 1, 4, 5, 1, ["destroy_radial"]);
    const dist1 = makePiece("near", 2, 4, 6); // Chebyshev 1
    const dist2 = makePiece("far2", 2, 4, 7); // Chebyshev 2
    const dist3 = makePiece("far3", 2, 4, 8); // Chebyshev 3 — out of range
    const state = baseState({ pieces: [piece, dist1, dist2, dist3] });

    const next = activateDestroyRadial(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("near")).toBe(false);
    expect(ids.has("far2")).toBe(false);
    expect(ids.has("far3")).toBe(true);
    expect(ids.has("p1")).toBe(true);
  });

  it("destroy_radial at L=1 hits all 24 tiles of 5×5 minus center (interior piece)", () => {
    // Piece at (5,5) to avoid edge effects. Place 24 enemies filling 5×5 minus center.
    const piece = grownPiece("p1", 1, 5, 5, 1, ["destroy_radial"]);
    const ring: Piece[] = [];
    let enemyIdx = 0;
    for (let dr = -2; dr <= 2; dr++) {
      for (let dc = -2; dc <= 2; dc++) {
        if (dr === 0 && dc === 0) continue;
        ring.push(makePiece(`e${enemyIdx++}`, 2, 5 + dr, 5 + dc));
      }
    }
    expect(ring.length).toBe(24);

    const state = baseState({ pieces: [piece, ...ring] });
    const next = activateDestroyRadial(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    for (const e of ring) {
      expect(ids.has(e.id), `${e.id} should be destroyed`).toBe(false);
    }
    expect(ids.has("p1")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 3. L=2 radial: 7×7 minus center = 48 tiles
// ---------------------------------------------------------------------------

describe("areaPieces radial — L=2", () => {
  it("destroy_radial at L=2 reaches Chebyshev distance 3", () => {
    const piece = grownPiece("p1", 1, 5, 5, 2, ["destroy_radial"]);
    const dist3 = makePiece("d3", 2, 5, 8); // dc=3
    const dist4 = makePiece("d4", 2, 5, 9); // dc=4 — out of range
    const state = baseState({ pieces: [piece, dist3, dist4] });

    const next = activateDestroyRadial(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("d3")).toBe(false);
    expect(ids.has("d4")).toBe(true);
    expect(ids.has("p1")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 4. L=1 row: band of 3 rows
// ---------------------------------------------------------------------------

describe("areaPieces row — L=1", () => {
  it("destroy_row at L=1 hits pieces in rows r-1, r, and r+1", () => {
    // Piece at (4,5). With L=1, rows 3,4,5 are affected.
    const piece = grownPiece("p1", 1, 4, 5, 1, ["destroy_row"]);
    const inRow3 = makePiece("r3", 2, 3, 2); // row 3 — in band
    const inRow4 = makePiece("r4", 2, 4, 2); // row 4 — activating row
    const inRow5 = makePiece("r5", 2, 5, 9); // row 5 — in band
    const inRow6 = makePiece("r6", 2, 6, 1); // row 6 — outside band
    const state = baseState({ pieces: [piece, inRow3, inRow4, inRow5, inRow6] });

    const next = activateDestroyRow(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("r3")).toBe(false);
    expect(ids.has("r4")).toBe(false);
    expect(ids.has("r5")).toBe(false);
    expect(ids.has("r6")).toBe(true);
    expect(ids.has("p1")).toBe(true);
  });

  it("destroy_row at L=0 hits only the activating row (regression)", () => {
    const piece = makePiece("p1", 1, 4, 5, ["destroy_row"]);
    const inRow3 = makePiece("r3", 2, 3, 2);
    const inRow4 = makePiece("r4", 2, 4, 2);
    const inRow5 = makePiece("r5", 2, 5, 9);
    const state = baseState({ pieces: [piece, inRow3, inRow4, inRow5] });

    const next = activateDestroyRow(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("r3")).toBe(true);
    expect(ids.has("r4")).toBe(false); // destroyed — same row
    expect(ids.has("r5")).toBe(true);
    expect(ids.has("p1")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 5. L=1 column: band of 3 columns
// ---------------------------------------------------------------------------

describe("areaPieces column — L=1", () => {
  it("destroy_column at L=1 hits pieces in columns c-1, c, and c+1", () => {
    const piece = grownPiece("p1", 1, 4, 5, 1, ["destroy_column"]);
    const inCol4 = makePiece("c4", 2, 2, 4);
    const inCol5 = makePiece("c5", 2, 7, 5);
    const inCol6 = makePiece("c6", 2, 1, 6);
    const outCol = makePiece("out", 2, 3, 7); // col 7 — outside band
    const state = baseState({ pieces: [piece, inCol4, inCol5, inCol6, outCol] });

    const next = activateDestroyColumn(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("c4")).toBe(false);
    expect(ids.has("c5")).toBe(false);
    expect(ids.has("c6")).toBe(false);
    expect(ids.has("out")).toBe(true);
    expect(ids.has("p1")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 6. Board-edge clamping
// ---------------------------------------------------------------------------

describe("board-edge clamping for grown radial", () => {
  it("L=1 radial near top-left corner does not go out of bounds", () => {
    // Piece at (1,1). Chebyshev ≤2 extends to rows -1..3 and cols -1..3,
    // but must be clamped to board (1..8, 1..10).
    const piece = grownPiece("p1", 1, 1, 1, 1, ["destroy_radial"]);
    // An enemy at (1,3) is Chebyshev dist 2 from (1,1) — within L=1 range
    const inRange = makePiece("ir", 2, 1, 3);
    // An enemy at (3,3) is Chebyshev dist max(2,2)=2 — within L=1 range
    const inRange2 = makePiece("ir2", 2, 3, 3);
    // An enemy at (1,4) is Chebyshev dist 3 — outside L=1 range
    const outRange = makePiece("out", 2, 1, 4);
    const state = baseState({ pieces: [piece, inRange, inRange2, outRange] });

    const next = activateDestroyRadial(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("ir")).toBe(false);
    expect(ids.has("ir2")).toBe(false);
    expect(ids.has("out")).toBe(true);
    expect(ids.has("p1")).toBe(true);
  });

  it("L=1 row near row 1 clamps: band is [1,1,2] not [-0,1,2]", () => {
    // Piece at (1,5) with L=1. Band should be rows 1,2 (not row 0).
    const piece = grownPiece("p1", 1, 1, 5, 1, ["destroy_row"]);
    const inRow2 = makePiece("r2", 2, 2, 3);
    const inRow1 = makePiece("r1", 2, 1, 3); // same row as piece
    const outRow3 = makePiece("r3", 2, 3, 3); // row 3 is outside the clamped band
    const state = baseState({ pieces: [piece, inRow2, inRow1, outRow3] });

    const next = activateDestroyRow(state, piece);
    const ids = new Set(next.pieces.map((p) => p.id));

    expect(ids.has("r1")).toBe(false); // in band
    expect(ids.has("r2")).toBe(false); // in band
    expect(ids.has("r3")).toBe(true);  // clamped out
    expect(ids.has("p1")).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 7. Integration: destroy_radial with L=1 reaches enemy at Chebyshev dist 2
//    that L=0 does NOT reach
// ---------------------------------------------------------------------------

describe("integration: grow_quadradius range extension", () => {
  it("destroy_radial L=1 destroys an enemy 2 tiles away that L=0 would miss", () => {
    const L0piece = makePiece("l0", 1, 4, 5, ["destroy_radial"]);
    const L1piece = grownPiece("l1", 1, 4, 5, 1, ["destroy_radial"]);
    const enemy2away = makePiece("e2", 2, 4, 7); // Chebyshev dist 2

    const stateL0 = baseState({ pieces: [L0piece, enemy2away] });
    const stateL1 = baseState({ pieces: [L1piece, enemy2away] });

    const nextL0 = activateDestroyRadial(stateL0, L0piece);
    const nextL1 = activateDestroyRadial(stateL1, L1piece);

    // L=0: enemy survives (out of range)
    expect(nextL0.pieces.some((p) => p.id === "e2")).toBe(true);
    // L=1: enemy destroyed
    expect(nextL1.pieces.some((p) => p.id === "e2")).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// 8. areaTileCoords for acidic_radial — tiles reported correctly for L=1
// ---------------------------------------------------------------------------

describe("areaTileCoords radial — L=1 (acidic_radial marks destroyed tiles)", () => {
  it("acidic_radial L=1 marks exactly the 5×5 area tiles as destroyed (clamped at board)", () => {
    // Piece at (5,5): 5×5 area is rows 3..7, cols 3..7, all in bounds = 25-1=24 tiles
    const piece = grownPiece("p1", 1, 5, 5, 1, ["acidic_radial"]);
    const state = baseState({ pieces: [piece] });

    const next = activateAcidicRadial(state, piece);

    let expected = 0;
    for (let dr = -2; dr <= 2; dr++) {
      for (let dc = -2; dc <= 2; dc++) {
        if (dr === 0 && dc === 0) continue;
        const r = 5 + dr;
        const c = 5 + dc;
        if (r >= 1 && r <= 8 && c >= 1 && c <= 10) {
          const key = `${r},${c}`;
          expect(
            next.destroyedTiles[key],
            `tile (${r},${c}) should be destroyed`,
          ).toBe(true);
          expected++;
        }
      }
    }
    // All 24 tiles in the unclamped 5×5 are within the 8×10 board here
    expect(expected).toBe(24);
  });
});

// ---------------------------------------------------------------------------
// 9. Row tile coords for acidic_row — L=1 marks tiles in 3 rows
// ---------------------------------------------------------------------------

describe("areaTileCoords row — L=1 (acidic_row)", () => {
  it("acidic_row L=1 marks tiles in 3 rows, full board width", () => {
    const piece = grownPiece("p1", 1, 4, 5, 1, ["acidic_row"]);
    const state = baseState({ pieces: [piece] });

    const next = activateAcidicRow(state, piece);

    // Rows 3, 4, 5 — all columns except (4,5) own tile
    let count = 0;
    for (let r = 3; r <= 5; r++) {
      for (let c = 1; c <= 10; c++) {
        if (r === 4 && c === 5) continue; // center tile excluded
        const key = `${r},${c}`;
        expect(
          next.destroyedTiles[key],
          `tile (${r},${c}) should be destroyed`,
        ).toBe(true);
        count++;
      }
    }
    expect(count).toBe(3 * 10 - 1); // 29 tiles
  });
});

// ---------------------------------------------------------------------------
// 10. Column tile coords for acidic_column — L=1 marks tiles in 3 columns
// ---------------------------------------------------------------------------

describe("areaTileCoords column — L=1 (acidic_column)", () => {
  it("acidic_column L=1 marks tiles in 3 columns, full board height", () => {
    const piece = grownPiece("p1", 1, 4, 5, 1, ["acidic_column"]);
    const state = baseState({ pieces: [piece] });

    const next = activateAcidicColumn(state, piece);

    // Columns 4, 5, 6 — all rows except (4,5) own tile
    let count = 0;
    for (let c = 4; c <= 6; c++) {
      for (let r = 1; r <= 8; r++) {
        if (r === 4 && c === 5) continue;
        const key = `${r},${c}`;
        expect(
          next.destroyedTiles[key],
          `tile (${r},${c}) should be destroyed`,
        ).toBe(true);
        count++;
      }
    }
    expect(count).toBe(3 * 8 - 1); // 23 tiles
  });
});
