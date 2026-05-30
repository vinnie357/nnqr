// Tests for src/core/powers/targets.ts — pure target-resolution helpers.

import { describe, it, expect } from "vitest";
import { createInitialState } from "../board";
import {
  getTargetTiles,
  needsTarget,
  overheatPower,
  powerCounts,
  tileColor,
  heightShade,
} from "./targets";
import type { GameState, Piece } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function freshState(): GameState {
  return createInitialState(1);
}

function makePiece(overrides: Partial<Piece> & { id: string; player: 1 | 2; row: number; col: number }): Piece {
  return {
    powers: [],
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// needsTarget
// ---------------------------------------------------------------------------

describe("needsTarget", () => {
  it("returns true for powers that require a target click", () => {
    const targeted = [
      "raise_tile",
      "lower_tile",
      "switcheroo",
      "recruit",
      "multiply",
      "refurb",
      "centerpult",
      "hotspot",
    ];
    for (const id of targeted) {
      expect(needsTarget(id), `${id} should need target`).toBe(true);
    }
  });

  it("returns false for self/row/column/global powers", () => {
    const immediate = [
      "destroy_row",
      "destroy_column",
      "bomb",
      "relocate",
      "jump_proof",
      "move_diagonal",
      "climb_tile",
      "double_powers",
      "orbic_rehash",
    ];
    for (const id of immediate) {
      expect(needsTarget(id), `${id} should not need target`).toBe(false);
    }
  });
});

// ---------------------------------------------------------------------------
// powerCounts
// ---------------------------------------------------------------------------

describe("powerCounts", () => {
  it("returns empty map for a piece with no powers", () => {
    const piece = makePiece({ id: "p1", player: 1, row: 1, col: 1 });
    expect(powerCounts(piece).size).toBe(0);
  });

  it("counts single powers correctly", () => {
    const piece = makePiece({ id: "p1", player: 1, row: 1, col: 1, powers: ["bomb"] });
    expect(powerCounts(piece).get("bomb")).toBe(1);
  });

  it("counts duplicate powers correctly", () => {
    const piece = makePiece({
      id: "p1",
      player: 1,
      row: 1,
      col: 1,
      powers: ["bomb", "destroy_row", "bomb", "bomb"],
    });
    const counts = powerCounts(piece);
    expect(counts.get("bomb")).toBe(3);
    expect(counts.get("destroy_row")).toBe(1);
  });
});

// ---------------------------------------------------------------------------
// overheatPower
// ---------------------------------------------------------------------------

describe("overheatPower", () => {
  it("returns null when no power is at ≥10 copies", () => {
    const piece = makePiece({
      id: "p1",
      player: 1,
      row: 1,
      col: 1,
      powers: Array(9).fill("bomb"),
    });
    expect(overheatPower(piece)).toBeNull();
  });

  it("returns the power id when a piece has ≥10 of one power", () => {
    const piece = makePiece({
      id: "p1",
      player: 1,
      row: 1,
      col: 1,
      powers: Array(10).fill("bomb"),
    });
    expect(overheatPower(piece)).toBe("bomb");
  });

  it("returns null for empty power list", () => {
    const piece = makePiece({ id: "p1", player: 1, row: 1, col: 1 });
    expect(overheatPower(piece)).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// getTargetTiles — raise_tile / lower_tile
// ---------------------------------------------------------------------------

describe("getTargetTiles — raise_tile", () => {
  it("returns adjacent, non-destroyed tiles", () => {
    const state = freshState();
    // Piece at center of board.
    const piece = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const tiles = getTargetTiles(state, piece, "raise_tile");
    expect(tiles.length).toBe(4); // up, down, left, right
    expect(tiles).toContainEqual({ row: 3, col: 5 });
    expect(tiles).toContainEqual({ row: 5, col: 5 });
    expect(tiles).toContainEqual({ row: 4, col: 4 });
    expect(tiles).toContainEqual({ row: 4, col: 6 });
  });

  it("clips to board boundaries at corner", () => {
    const state = freshState();
    const piece = makePiece({ id: "p1", player: 1, row: 1, col: 1 });
    const tiles = getTargetTiles(state, piece, "raise_tile");
    // Only right and down are in bounds.
    expect(tiles.length).toBe(2);
    expect(tiles).toContainEqual({ row: 1, col: 2 });
    expect(tiles).toContainEqual({ row: 2, col: 1 });
  });

  it("excludes destroyed tiles", () => {
    const state: GameState = {
      ...freshState(),
      destroyedTiles: { "4,6": true },
    };
    const piece = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const tiles = getTargetTiles(state, piece, "raise_tile");
    expect(tiles.some((t) => t.row === 4 && t.col === 6)).toBe(false);
    expect(tiles.length).toBe(3);
  });
});

// ---------------------------------------------------------------------------
// getTargetTiles — recruit
// ---------------------------------------------------------------------------

describe("getTargetTiles — recruit", () => {
  it("returns adjacent enemy pieces only", () => {
    const base = freshState();
    // Place a P1 piece surrounded by a mix of pieces.
    const p1 = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const enemy = makePiece({ id: "e1", player: 2, row: 4, col: 6 });
    const ally = makePiece({ id: "a1", player: 1, row: 4, col: 4 });
    const state: GameState = { ...base, pieces: [p1, enemy, ally] };
    const tiles = getTargetTiles(state, p1, "recruit");
    expect(tiles).toContainEqual({ row: 4, col: 6 });
    expect(tiles).not.toContainEqual({ row: 4, col: 4 });
    expect(tiles.length).toBe(1);
  });

  it("returns empty when no adjacent enemies", () => {
    const base = freshState();
    const p1 = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const state: GameState = { ...base, pieces: [p1] };
    expect(getTargetTiles(state, p1, "recruit").length).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// getTargetTiles — multiply
// ---------------------------------------------------------------------------

describe("getTargetTiles — multiply", () => {
  it("returns adjacent empty non-destroyed tiles", () => {
    const base = freshState();
    const p1 = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const blocker = makePiece({ id: "b1", player: 2, row: 4, col: 6 });
    const state: GameState = {
      ...base,
      pieces: [p1, blocker],
      destroyedTiles: { "3,5": true },
    };
    const tiles = getTargetTiles(state, p1, "multiply");
    // row4,col6 occupied, row3,col5 destroyed, so only row5,col5 and row4,col4 remain.
    expect(tiles).toContainEqual({ row: 5, col: 5 });
    expect(tiles).toContainEqual({ row: 4, col: 4 });
    expect(tiles).not.toContainEqual({ row: 4, col: 6 });
    expect(tiles).not.toContainEqual({ row: 3, col: 5 });
  });
});

// ---------------------------------------------------------------------------
// getTargetTiles — refurb
// ---------------------------------------------------------------------------

describe("getTargetTiles — refurb", () => {
  it("returns only adjacent destroyed tiles", () => {
    const base = freshState();
    const p1 = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const state: GameState = { ...base, pieces: [p1], destroyedTiles: { "4,6": true, "5,5": true } };
    const tiles = getTargetTiles(state, p1, "refurb");
    expect(tiles).toContainEqual({ row: 4, col: 6 });
    expect(tiles).toContainEqual({ row: 5, col: 5 });
    // row3,col5 is not destroyed.
    expect(tiles).not.toContainEqual({ row: 3, col: 5 });
  });

  it("returns empty when no adjacent destroyed tiles", () => {
    const state = freshState();
    const piece = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    expect(getTargetTiles(state, piece, "refurb").length).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// getTargetTiles — switcheroo
// ---------------------------------------------------------------------------

describe("getTargetTiles — switcheroo", () => {
  it("returns adjacent tiles occupied by any piece", () => {
    const base = freshState();
    const p1 = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    const enemy = makePiece({ id: "e1", player: 2, row: 4, col: 6 });
    const ally = makePiece({ id: "a1", player: 1, row: 3, col: 5 });
    const state: GameState = { ...base, pieces: [p1, enemy, ally] };
    const tiles = getTargetTiles(state, p1, "switcheroo");
    expect(tiles).toContainEqual({ row: 4, col: 6 });
    expect(tiles).toContainEqual({ row: 3, col: 5 });
    expect(tiles.length).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// getTargetTiles — unknown power
// ---------------------------------------------------------------------------

describe("getTargetTiles — unknown power", () => {
  it("returns empty array for an unrecognized power id", () => {
    const state = freshState();
    const piece = makePiece({ id: "p1", player: 1, row: 4, col: 5 });
    expect(getTargetTiles(state, piece, "destroy_row").length).toBe(0);
  });
});

// ---------------------------------------------------------------------------
// heightShade
// ---------------------------------------------------------------------------

describe("heightShade", () => {
  it("returns 0 for height 0", () => {
    expect(heightShade(0)).toBe(0);
  });

  it("returns 1 for height 4", () => {
    expect(heightShade(4)).toBe(1);
  });

  it("returns 0.5 for height 2", () => {
    expect(heightShade(2)).toBe(0.5);
  });
});

// ---------------------------------------------------------------------------
// tileColor
// ---------------------------------------------------------------------------

describe("tileColor", () => {
  it("returns a number in valid 24-bit range", () => {
    for (const h of [0, 1, 2, 3, 4]) {
      const c = tileColor(1, 1, h);
      expect(c).toBeGreaterThanOrEqual(0);
      expect(c).toBeLessThan(0x1000000);
    }
  });

  it("light and dark tiles produce different colors at height 0", () => {
    // (1,1) is light (sum=2, even), (1,2) is dark (sum=3, odd).
    expect(tileColor(1, 1, 0)).not.toBe(tileColor(1, 2, 0));
  });

  it("higher terrain produces brighter tiles", () => {
    // Extract the red channel to compare brightness.
    const low = tileColor(1, 1, 0) >> 16;
    const high = tileColor(1, 1, 4) >> 16;
    expect(high).toBeGreaterThan(low);
  });
});
