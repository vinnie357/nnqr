// Power system tests — definition count, dispatch completeness, and representative effect behavior.

import { describe, expect, it } from "vitest";
import { createHeightMap, getHeight, MAX_HEIGHT } from "../height";
import type { GameState, Piece, Player } from "../types";
import { definitions, POWER_IDS } from "./definitions";
import {
  activateBomb,
  activateDestroyRadial,
  activateDestroyRow,
  activateJumpProof,
  activateRelocate,
} from "./effects";
import { execute, isRegistered, registeredIds } from "./executor";

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

function makePiece(
  id: string,
  player: Player,
  row: number,
  col: number,
  powers: string[] = [],
): Piece {
  return { id, player, row, col, powers };
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

// ---------------------------------------------------------------------------
// 1. Definition count: must be exactly 82
// ---------------------------------------------------------------------------

describe("definitions", () => {
  it("contains exactly 82 powers", () => {
    expect(Object.keys(definitions).length).toBe(82);
  });

  it("POWER_IDS has exactly 82 entries matching definition keys", () => {
    expect(POWER_IDS.length).toBe(82);
    for (const id of POWER_IDS) {
      expect(definitions[id]).toBeDefined();
    }
  });

  it("every definition has required fields", () => {
    for (const [id, def] of Object.entries(definitions)) {
      expect(def.id).toBe(id);
      expect(typeof def.name).toBe("string");
      expect(typeof def.category).toBe("string");
      expect(["permanent", "single_use"]).toContain(def.duration);
      expect(typeof def.description).toBe("string");
      expect(typeof def.targeting).toBe("string");
      expect(typeof def.blocking).toBe("boolean");
    }
  });
});

// ---------------------------------------------------------------------------
// 2. Dispatch completeness: every definition resolves to a handler
// ---------------------------------------------------------------------------

describe("executor dispatch completeness", () => {
  it("isRegistered returns true for every defined power id", () => {
    const missing: string[] = [];
    for (const id of Object.keys(definitions)) {
      if (!isRegistered(id)) missing.push(id);
    }
    expect(missing).toEqual([]);
  });

  it("registeredIds includes all definition ids (no orphans)", () => {
    const registered = new Set(registeredIds());
    for (const id of Object.keys(definitions)) {
      expect(registered.has(id)).toBe(true);
    }
  });

  it("module loads without throwing (load-time assert passed)", () => {
    // If executor.ts had thrown at load time, this test file would not reach here.
    expect(typeof execute).toBe("function");
  });
});

// ---------------------------------------------------------------------------
// 3. Representative effect: destroy_row
// ---------------------------------------------------------------------------

describe("destroy_row effect", () => {
  it("removes all other pieces in the activating piece's row", () => {
    const piece = makePiece("p1", 1, 3, 5, ["destroy_row"]);
    const enemy1 = makePiece("e1", 2, 3, 2);
    const enemy2 = makePiece("e2", 2, 3, 8);
    const ally = makePiece("a1", 1, 3, 9);
    const bystander = makePiece("b1", 2, 5, 5); // different row — should survive
    const state = baseState({ pieces: [piece, enemy1, enemy2, ally, bystander] });

    const next = activateDestroyRow(state, piece);

    const ids = next.pieces.map((p) => p.id);
    // Activating piece survives (the power is consumed, not the piece)
    expect(ids).toContain("p1");
    // Same-row pieces removed
    expect(ids).not.toContain("e1");
    expect(ids).not.toContain("e2");
    expect(ids).not.toContain("a1");
    // Different-row piece survives
    expect(ids).toContain("b1");
  });

  it("consumes destroy_row from the activating piece's inventory", () => {
    const piece = makePiece("p1", 1, 3, 5, ["destroy_row", "bomb"]);
    const state = baseState({ pieces: [piece] });
    const next = activateDestroyRow(state, piece);
    const updatedPiece = next.pieces.find((p) => p.id === "p1")!;
    expect(updatedPiece.powers).not.toContain("destroy_row");
    expect(updatedPiece.powers).toContain("bomb");
  });

  it("forwards through execute()", () => {
    const piece = makePiece("p1", 1, 3, 5, ["destroy_row"]);
    const enemy = makePiece("e1", 2, 3, 2);
    const state = baseState({ pieces: [piece, enemy] });
    const next = execute(state, piece, "destroy_row");
    expect(next.pieces.map((p) => p.id)).not.toContain("e1");
  });
});

// ---------------------------------------------------------------------------
// 4. Representative effect: bomb / destroy_radial
// ---------------------------------------------------------------------------

describe("bomb effect", () => {
  it("removes pieces in 3x3 area (excluding self) and lowers terrain", () => {
    const piece = makePiece("p1", 1, 4, 5, ["bomb"]);
    const adjacent = makePiece("e1", 2, 4, 6);
    const distant = makePiece("e2", 2, 1, 1); // outside 3x3
    const state = baseState({
      pieces: [piece, adjacent, distant],
      heightMap: createHeightMap(8, 10, 2),
    });

    const next = activateBomb(state, piece);

    // Adjacent enemy removed
    expect(next.pieces.map((p) => p.id)).not.toContain("e1");
    // Distant enemy survives
    expect(next.pieces.map((p) => p.id)).toContain("e2");
    // Terrain lowered at center tile
    expect(getHeight(next.heightMap, 4, 5)).toBe(1);
    // Terrain lowered at adjacent tile
    expect(getHeight(next.heightMap, 4, 6)).toBe(1);
  });
});

describe("destroy_radial effect", () => {
  it("removes all pieces in 3x3 area (excluding self) without affecting terrain", () => {
    const piece = makePiece("p1", 1, 4, 5, ["destroy_radial"]);
    const adjacent = makePiece("e1", 2, 4, 6);
    const distant = makePiece("e2", 2, 1, 1);
    const state = baseState({
      pieces: [piece, adjacent, distant],
      heightMap: createHeightMap(8, 10, 2),
    });

    const next = activateDestroyRadial(state, piece);

    expect(next.pieces.map((p) => p.id)).not.toContain("e1");
    expect(next.pieces.map((p) => p.id)).toContain("e2");
    // Terrain unchanged
    expect(getHeight(next.heightMap, 4, 6)).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// 5. Representative effect: raise_tile bumps height
// ---------------------------------------------------------------------------

describe("raise_tile effect via execute()", () => {
  it("increases the target tile height by 1", () => {
    const piece = makePiece("p1", 1, 3, 3, ["raise_tile"]);
    const state = baseState({
      pieces: [piece],
      heightMap: createHeightMap(8, 10, 1),
    });
    const next = execute(state, piece, "raise_tile", { row: 3, col: 4 });
    expect(getHeight(next.heightMap, 3, 4)).toBe(2);
    // Other tiles unchanged
    expect(getHeight(next.heightMap, 3, 3)).toBe(1);
  });

  it("clamps at MAX_HEIGHT", () => {
    const piece = makePiece("p1", 1, 3, 3, ["raise_tile"]);
    const state = baseState({
      pieces: [piece],
      heightMap: createHeightMap(8, 10, MAX_HEIGHT),
    });
    const next = execute(state, piece, "raise_tile", { row: 3, col: 4 });
    expect(getHeight(next.heightMap, 3, 4)).toBe(MAX_HEIGHT);
  });
});

// ---------------------------------------------------------------------------
// 6. Representative effect: jump_proof sets the flag + consumes power
// ---------------------------------------------------------------------------

describe("jump_proof effect", () => {
  it("sets isJumpProof flag on the piece", () => {
    const piece = makePiece("p1", 1, 3, 3, ["jump_proof"]);
    const state = baseState({ pieces: [piece] });
    const next = activateJumpProof(state, piece);
    const updated = next.pieces.find((p) => p.id === "p1")!;
    expect(updated.isJumpProof).toBe(true);
  });

  it("consumes the jump_proof power", () => {
    const piece = makePiece("p1", 1, 3, 3, ["jump_proof", "bomb"]);
    const state = baseState({ pieces: [piece] });
    const next = activateJumpProof(state, piece);
    const updated = next.pieces.find((p) => p.id === "p1")!;
    expect(updated.powers).not.toContain("jump_proof");
    expect(updated.powers).toContain("bomb");
  });
});

// ---------------------------------------------------------------------------
// 7. Representative effect: multiply creates a piece
// ---------------------------------------------------------------------------

describe("multiply effect via execute()", () => {
  it("creates a new piece at the target position", () => {
    const piece = makePiece("p1", 1, 3, 3, ["multiply"]);
    const state = baseState({ pieces: [piece] });
    const next = execute(state, piece, "multiply", { row: 3, col: 4 });
    const pieces = next.pieces;
    expect(pieces.length).toBe(2);
    const newPiece = pieces.find((p) => p.id !== "p1")!;
    expect(newPiece.row).toBe(3);
    expect(newPiece.col).toBe(4);
    expect(newPiece.player).toBe(1 as Player);
  });

  it("consumes the multiply power from the caster", () => {
    const piece = makePiece("p1", 1, 3, 3, ["multiply"]);
    const state = baseState({ pieces: [piece] });
    const next = execute(state, piece, "multiply", { row: 3, col: 4 });
    const caster = next.pieces.find((p) => p.id === "p1")!;
    expect(caster.powers).not.toContain("multiply");
  });
});

// ---------------------------------------------------------------------------
// 8. Representative effect: relocate is deterministic under a fixed seed
// ---------------------------------------------------------------------------

describe("relocate effect", () => {
  it("moves the piece to a different tile (non-empty board has empty tiles)", () => {
    const piece = makePiece("p1", 1, 4, 5, ["relocate"]);
    const state = baseState({ pieces: [piece], seed: 99, turn: 3 });
    const next = activateRelocate(state, piece);
    const moved = next.pieces.find((p) => p.id === "p1")!;
    // Piece moves away from (4,5)
    expect(moved.row !== 4 || moved.col !== 5).toBe(true);
  });

  it("is deterministic for a given seed+turn", () => {
    const piece1 = makePiece("p1", 1, 4, 5, ["relocate"]);
    const piece2 = makePiece("p1", 1, 4, 5, ["relocate"]);
    const s1 = baseState({ pieces: [piece1], seed: 7, turn: 5 });
    const s2 = baseState({ pieces: [piece2], seed: 7, turn: 5 });
    const n1 = activateRelocate(s1, piece1).pieces.find((p) => p.id === "p1")!;
    const n2 = activateRelocate(s2, piece2).pieces.find((p) => p.id === "p1")!;
    expect(n1.row).toBe(n2.row);
    expect(n1.col).toBe(n2.col);
  });

  it("produces different outcomes for different seeds", () => {
    const runWith = (seed: number) => {
      const piece = makePiece("p1", 1, 4, 5, ["relocate"]);
      const state = baseState({ pieces: [piece], seed, turn: 1 });
      return activateRelocate(state, piece).pieces.find((p) => p.id === "p1")!;
    };
    const a = runWith(1);
    const b = runWith(12345);
    // Different seeds should produce different positions (with overwhelming probability)
    expect(a.row !== b.row || a.col !== b.col).toBe(true);
  });

  it("consumes the relocate power", () => {
    const piece = makePiece("p1", 1, 4, 5, ["relocate"]);
    const state = baseState({ pieces: [piece] });
    const next = activateRelocate(state, piece);
    const moved = next.pieces.find((p) => p.id === "p1")!;
    expect(moved.powers).not.toContain("relocate");
  });
});

// ---------------------------------------------------------------------------
// 9. Immutability: effects return new state without mutating input
// ---------------------------------------------------------------------------

describe("immutability", () => {
  it("destroy_row does not mutate the original state", () => {
    const piece = makePiece("p1", 1, 3, 5, ["destroy_row"]);
    const enemy = makePiece("e1", 2, 3, 2);
    const state = baseState({ pieces: [piece, enemy] });
    const originalPieceCount = state.pieces.length;
    activateDestroyRow(state, piece);
    expect(state.pieces.length).toBe(originalPieceCount);
  });

  it("raise_tile does not mutate the original heightMap", () => {
    const piece = makePiece("p1", 1, 3, 3, ["raise_tile"]);
    const state = baseState({ pieces: [piece], heightMap: createHeightMap(8, 10, 1) });
    const originalHeight = getHeight(state.heightMap, 3, 4);
    execute(state, piece, "raise_tile", { row: 3, col: 4 });
    expect(getHeight(state.heightMap, 3, 4)).toBe(originalHeight);
  });
});

// ---------------------------------------------------------------------------
// 10. execute() returns state unchanged for unknown power id
// ---------------------------------------------------------------------------

describe("execute with unknown power", () => {
  it("returns the same state reference for an unknown power id", () => {
    const piece = makePiece("p1", 1, 3, 3, []);
    const state = baseState({ pieces: [piece] });
    const next = execute(state, piece, "nonexistent_power_xyz");
    expect(next).toBe(state);
  });
});
