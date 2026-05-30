import { describe, expect, it } from "vitest";
import { BOARD_COLS, BOARD_ROWS } from "./board";
import { createHeightMap } from "./height";
import {
  MAX_ORBS,
  MIN_ORBS,
  SPAWN_INTERVAL,
  collectOrb,
  emptyTiles,
  shouldSpawnOrbs,
  spawnOrbs,
} from "./orbs";
import type { GameState } from "./types";

function makeState(overrides: Partial<GameState> = {}): GameState {
  return {
    cols: BOARD_COLS,
    rows: BOARD_ROWS,
    pieces: [],
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
// shouldSpawnOrbs
// ---------------------------------------------------------------------------
describe("shouldSpawnOrbs", () => {
  it("returns false at turn 0", () => {
    expect(shouldSpawnOrbs(0)).toBe(false);
  });

  it("returns false for turns between intervals (e.g. turn 1)", () => {
    expect(shouldSpawnOrbs(1)).toBe(false);
  });

  it("returns false for turn 8 (one past the first interval)", () => {
    expect(shouldSpawnOrbs(8)).toBe(false);
  });

  it(`returns true at turn ${SPAWN_INTERVAL}`, () => {
    expect(shouldSpawnOrbs(SPAWN_INTERVAL)).toBe(true);
  });

  it(`returns true at turn ${SPAWN_INTERVAL * 2}`, () => {
    expect(shouldSpawnOrbs(SPAWN_INTERVAL * 2)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// emptyTiles
// ---------------------------------------------------------------------------
describe("emptyTiles", () => {
  it("excludes tiles occupied by pieces", () => {
    const s = makeState({
      pieces: [{ id: "a", player: 1, row: 3, col: 3, powers: [] }],
    });
    const tiles = emptyTiles(s);
    expect(tiles.find((t) => t.row === 3 && t.col === 3)).toBeUndefined();
  });

  it("excludes tiles occupied by orbs", () => {
    const s = makeState({
      orbs: [{ row: 5, col: 5, powerId: "bomb" }],
    });
    const tiles = emptyTiles(s);
    expect(tiles.find((t) => t.row === 5 && t.col === 5)).toBeUndefined();
  });

  it("excludes destroyed tiles", () => {
    const s = makeState({
      destroyedTiles: { "4,4": true },
    });
    const tiles = emptyTiles(s);
    expect(tiles.find((t) => t.row === 4 && t.col === 4)).toBeUndefined();
  });

  it("includes tiles that are not occupied, not orb-bearing, and not destroyed", () => {
    const s = makeState();
    const tiles = emptyTiles(s);
    // An empty board has BOARD_ROWS * BOARD_COLS = 80 tiles
    expect(tiles).toHaveLength(BOARD_ROWS * BOARD_COLS);
    expect(tiles.find((t) => t.row === 4 && t.col === 4)).toBeDefined();
  });

  it("excludes pieces, orbs, and destroyed tiles simultaneously", () => {
    const s = makeState({
      pieces: [{ id: "a", player: 1, row: 1, col: 1, powers: [] }],
      orbs: [{ row: 2, col: 2, powerId: "bomb" }],
      destroyedTiles: { "3,3": true },
    });
    const tiles = emptyTiles(s);
    expect(tiles.find((t) => t.row === 1 && t.col === 1)).toBeUndefined();
    expect(tiles.find((t) => t.row === 2 && t.col === 2)).toBeUndefined();
    expect(tiles.find((t) => t.row === 3 && t.col === 3)).toBeUndefined();
    // Everything else still present
    expect(tiles).toHaveLength(BOARD_ROWS * BOARD_COLS - 3);
  });
});

// ---------------------------------------------------------------------------
// spawnOrbs
// ---------------------------------------------------------------------------
describe("spawnOrbs", () => {
  const POWER_IDS = ["bomb", "relocate"] as const;

  it("is deterministic for a fixed seed and turn", () => {
    const s = makeState({ seed: 42, turn: 7 });
    const result1 = spawnOrbs(s, POWER_IDS);
    const result2 = spawnOrbs(s, POWER_IDS);
    expect(result1.orbs).toEqual(result2.orbs);
  });

  it(`spawns between ${MIN_ORBS} and ${MAX_ORBS} orbs`, () => {
    const s = makeState({ seed: 42, turn: 7 });
    const result = spawnOrbs(s, POWER_IDS);
    expect(result.orbs.length).toBeGreaterThanOrEqual(MIN_ORBS);
    expect(result.orbs.length).toBeLessThanOrEqual(MAX_ORBS);
  });

  it("places orbs only on empty tiles (none on pieces or existing orbs)", () => {
    const s = makeState({
      seed: 1,
      turn: 7,
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
    });
    const result = spawnOrbs(s, POWER_IDS);
    for (const orb of result.orbs) {
      expect(orb.row === 4 && orb.col === 4).toBe(false);
    }
  });

  it("appends new orbs to any existing orbs", () => {
    const existing = { row: 1, col: 1, powerId: "bomb" };
    const s = makeState({ seed: 1, turn: 7, orbs: [existing] });
    const result = spawnOrbs(s, POWER_IDS);
    expect(result.orbs[0]).toEqual(existing);
    expect(result.orbs.length).toBeGreaterThan(1);
  });

  it("returns state unchanged when powerIds is empty", () => {
    const s = makeState({ seed: 1, turn: 7 });
    const result = spawnOrbs(s, []);
    expect(result.orbs).toHaveLength(0);
  });

  it("each spawned orb carries a powerId from the provided list", () => {
    const s = makeState({ seed: 5, turn: 7 });
    const result = spawnOrbs(s, POWER_IDS);
    for (const orb of result.orbs) {
      expect(POWER_IDS).toContain(orb.powerId);
    }
  });

  it("does not place two orbs on the same tile", () => {
    const s = makeState({ seed: 99, turn: 7 });
    const result = spawnOrbs(s, POWER_IDS);
    const keys = result.orbs.map((o) => `${o.row},${o.col}`);
    const unique = new Set(keys);
    expect(unique.size).toBe(keys.length);
  });
});

// ---------------------------------------------------------------------------
// collectOrb
// ---------------------------------------------------------------------------
describe("collectOrb", () => {
  it("adds the orb's powerId to the landing piece's powers", () => {
    const s = makeState({
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      orbs: [{ row: 4, col: 4, powerId: "bomb" }],
    });
    const { state, collected } = collectOrb(s, 4, 4);
    expect(collected).toBe("bomb");
    const piece = state.pieces.find((p) => p.id === "a");
    expect(piece?.powers).toContain("bomb");
  });

  it("removes the orb from the board after collection", () => {
    const s = makeState({
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      orbs: [{ row: 4, col: 4, powerId: "bomb" }],
    });
    const { state } = collectOrb(s, 4, 4);
    expect(state.orbs.find((o) => o.row === 4 && o.col === 4)).toBeUndefined();
  });

  it("only removes the orb at the specified tile, not others", () => {
    const s = makeState({
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      orbs: [
        { row: 4, col: 4, powerId: "bomb" },
        { row: 5, col: 5, powerId: "relocate" },
      ],
    });
    const { state } = collectOrb(s, 4, 4);
    expect(state.orbs).toHaveLength(1);
    expect(state.orbs[0]).toEqual({ row: 5, col: 5, powerId: "relocate" });
  });

  it("is a no-op when no orb is present at the tile", () => {
    const s = makeState({
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
    });
    const { state, collected } = collectOrb(s, 4, 4);
    expect(collected).toBeNull();
    expect(state.pieces[0]?.powers).toHaveLength(0);
    expect(state.orbs).toHaveLength(0);
  });

  it("is a no-op when no piece is present at the tile (orb remains)", () => {
    const s = makeState({
      orbs: [{ row: 4, col: 4, powerId: "bomb" }],
    });
    const { state, collected } = collectOrb(s, 4, 4);
    expect(collected).toBeNull();
    expect(state.orbs).toHaveLength(1);
  });

  it("accumulates multiple power ids on repeated collection", () => {
    const s1 = makeState({
      pieces: [{ id: "a", player: 1, row: 4, col: 4, powers: [] }],
      orbs: [{ row: 4, col: 4, powerId: "bomb" }],
    });
    const { state: s2 } = collectOrb(s1, 4, 4);
    // Move the piece conceptually to another orb
    const s3: GameState = {
      ...s2,
      pieces: [{ id: "a", player: 1, row: 5, col: 5, powers: s2.pieces[0]!.powers }],
      orbs: [{ row: 5, col: 5, powerId: "relocate" }],
    };
    const { state: s4, collected } = collectOrb(s3, 5, 5);
    expect(collected).toBe("relocate");
    expect(s4.pieces[0]?.powers).toEqual(["bomb", "relocate"]);
  });
});
