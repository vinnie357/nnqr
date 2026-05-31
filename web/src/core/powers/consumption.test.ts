// consumption.test.ts — behavioral tests for power effects that CONSUME game-flow state.
// Each test asserts the observable game-flow change, not merely that a flag was set.
// Written RED-first per TDD; made green by wiring consumers in board.ts / orbs.ts / controller.ts.

import { describe, expect, it } from "vitest";
import { createHeightMap } from "../height";
import { moveTo } from "../board";
import { collectOrb } from "../orbs";
import type { GameState, Piece, Player } from "../types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makePiece(
  id: string,
  player: Player,
  row: number,
  col: number,
  powers: string[] = [],
  flags: Partial<Piece> = {},
): Piece {
  return { id, player, row, col, powers, ...flags };
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
    turn: 0,
    seed: 42,
    ...overrides,
  };
}

// ---------------------------------------------------------------------------
// 1. move_again — extraMove consumed by game flow: same player gets another turn
//
// After activating move_again the extraMove flag is set on GameState.
// The game-flow consumer (moveTo / controller applyMove) must NOT flip the
// currentPlayer when extraMove is true, and must clear the flag after granting
// the extra move.
// ---------------------------------------------------------------------------

describe("move_again: extraMove consumed by moveTo", () => {
  it("does not flip currentPlayer when extraMove is true", () => {
    const piece = makePiece("p1", 1, 4, 5, []);
    // Manually inject extraMove (as the power effect does)
    const state: GameState = {
      ...baseState({
        pieces: [piece],
        currentPlayer: 1,
        selected: { row: 4, col: 5 },
        validMoves: [{ row: 4, col: 6, capture: false }],
      }),
      extraMove: true,
    } as GameState;

    const next = moveTo(state, 4, 6);

    // currentPlayer must STILL be 1 (the extra move was granted)
    expect(next.currentPlayer).toBe(1);
  });

  it("clears extraMove after granting the extra turn", () => {
    const piece = makePiece("p1", 1, 4, 5, []);
    const state: GameState = {
      ...baseState({
        pieces: [piece],
        currentPlayer: 1,
        selected: { row: 4, col: 5 },
        validMoves: [{ row: 4, col: 6, capture: false }],
      }),
      extraMove: true,
    } as GameState;

    const next = moveTo(state, 4, 6) as GameState & { extraMove?: boolean };
    expect(next.extraMove).toBeFalsy();
  });

  it("flips currentPlayer normally when extraMove is absent", () => {
    const piece = makePiece("p1", 1, 4, 5, []);
    const state = baseState({
      pieces: [piece],
      currentPlayer: 1,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: false }],
    });
    const next = moveTo(state, 4, 6);
    expect(next.currentPlayer).toBe(2);
  });
});

// ---------------------------------------------------------------------------
// 2. bankrupt — bankruptTiles consumed by collectOrb: landing piece loses powers
//
// When a piece lands on a bankrupt tile, it should lose all its powers.
// The consumer lives in the collectOrb / post-move path.
// ---------------------------------------------------------------------------

describe("bankrupt: bankruptTiles consumed by collectOrb / moveTo", () => {
  it("piece landing on a bankrupt tile loses all its powers", () => {
    const piece = makePiece("p1", 1, 4, 5, ["bomb", "relocate"]);
    const state: GameState = {
      ...baseState({
        pieces: [piece],
        currentPlayer: 1,
        selected: { row: 4, col: 5 },
        validMoves: [{ row: 4, col: 6, capture: false }],
      }),
      bankruptTiles: { "4,6": true },
    } as GameState;

    const next = moveTo(state, 4, 6);
    const movedPiece = next.pieces.find((p) => p.id === "p1")!;
    expect(movedPiece.powers).toHaveLength(0);
  });

  it("piece landing on a non-bankrupt tile keeps its powers", () => {
    const piece = makePiece("p1", 1, 4, 5, ["bomb"]);
    const state = baseState({
      pieces: [piece],
      currentPlayer: 1,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: false }],
    });
    const next = moveTo(state, 4, 6);
    const movedPiece = next.pieces.find((p) => p.id === "p1")!;
    expect(movedPiece.powers).toContain("bomb");
  });
});

// ---------------------------------------------------------------------------
// 3. tripwire — isTripwired consumed by moveTo: tripwired piece is removed when
// it moves
// ---------------------------------------------------------------------------

describe("tripwire: isTripwired consumed by moveTo", () => {
  it("a tripwired piece is removed from the board when it moves", () => {
    // Enemy piece flagged as tripwired.
    const victim = makePiece("e1", 2, 5, 5, [], { isTripwired: true } as Partial<Piece>);
    const state: GameState = {
      ...baseState({
        pieces: [victim],
        currentPlayer: 2,
        selected: { row: 5, col: 5 },
        validMoves: [{ row: 5, col: 6, capture: false }],
      }),
    };

    const next = moveTo(state, 5, 6);
    expect(next.pieces.find((p) => p.id === "e1")).toBeUndefined();
  });

  it("a non-tripwired piece is NOT removed when it moves", () => {
    const piece = makePiece("p1", 1, 4, 5, []);
    const state = baseState({
      pieces: [piece],
      currentPlayer: 1,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: false }],
    });
    const next = moveTo(state, 4, 6);
    expect(next.pieces.find((p) => p.id === "p1")).toBeDefined();
  });
});

// ---------------------------------------------------------------------------
// 4. inhibit — isInhibited consumed by collectOrb: inhibited piece cannot
// collect orb powers
// ---------------------------------------------------------------------------

describe("inhibit: isInhibited consumed by collectOrb", () => {
  it("an inhibited piece does not receive the power from an orb it lands on", () => {
    const piece = makePiece("p1", 1, 4, 5, [], { isInhibited: true } as Partial<Piece>);
    const state: GameState = {
      ...baseState({
        pieces: [piece],
        orbs: [{ row: 4, col: 5, powerId: "bomb" }],
      }),
    };

    const { state: next, collected } = collectOrb(state, 4, 5);
    const movedPiece = next.pieces.find((p) => p.id === "p1")!;
    // Orb is collected (removed from board) but the power is NOT added to the piece
    expect(movedPiece.powers).not.toContain("bomb");
    // The orb should be removed from the board to prevent re-collection
    expect(next.orbs.find((o) => o.row === 4 && o.col === 4)).toBeUndefined();
    // collectOrb should report the orb was found but not granted
    expect(collected).toBeNull(); // inhibited = not received
  });

  it("a non-inhibited piece receives the power normally", () => {
    const piece = makePiece("p1", 1, 4, 5, []);
    const state = baseState({
      pieces: [piece],
      orbs: [{ row: 4, col: 5, powerId: "bomb" }],
    });
    const { state: next, collected } = collectOrb(state, 4, 5);
    const movedPiece = next.pieces.find((p) => p.id === "p1")!;
    expect(movedPiece.powers).toContain("bomb");
    expect(collected).toBe("bomb");
  });
});

// ---------------------------------------------------------------------------
// 5. parasite — parasitizedBy consumed by collectOrb: collected power goes to
// the parasite owner instead of the piece that landed on the orb
// ---------------------------------------------------------------------------

describe("parasite: parasitizedBy consumed by collectOrb", () => {
  it("a parasitized piece's collected power goes to the parasite owner", () => {
    const parasite = makePiece("e1", 2, 1, 1, []); // The parasite owner
    const victim = makePiece("p1", 1, 4, 5, [], { parasitizedBy: "e1" } as Partial<Piece>);
    const state: GameState = {
      ...baseState({
        pieces: [parasite, victim],
        orbs: [{ row: 4, col: 5, powerId: "bomb" }],
      }),
    };

    const { state: next, collected } = collectOrb(state, 4, 5);
    const victimAfter = next.pieces.find((p) => p.id === "p1")!;
    const parasiteAfter = next.pieces.find((p) => p.id === "e1")!;
    // Victim does NOT get the power
    expect(victimAfter.powers).not.toContain("bomb");
    // Parasite owner DOES get the power
    expect(parasiteAfter.powers).toContain("bomb");
    // The orb is consumed
    expect(next.orbs.find((o) => o.row === 4 && o.col === 5)).toBeUndefined();
    // collected should reflect the orb was found
    expect(collected).toBe("bomb");
  });

  it("a non-parasitized piece collects normally", () => {
    const piece = makePiece("p1", 1, 4, 5, []);
    const state = baseState({
      pieces: [piece],
      orbs: [{ row: 4, col: 5, powerId: "relocate" }],
    });
    const { state: next } = collectOrb(state, 4, 5);
    expect(next.pieces.find((p) => p.id === "p1")!.powers).toContain("relocate");
  });
});

// ---------------------------------------------------------------------------
// 6. scavenger — isScavenger consumed by moveTo: capturing piece inherits the
// captured enemy's powers
// ---------------------------------------------------------------------------

describe("scavenger: isScavenger consumed by moveTo (capture)", () => {
  it("a scavenger piece inherits the captured enemy's powers", () => {
    const scavenger = makePiece("p1", 1, 4, 5, ["relocate"], { isScavenger: true } as Partial<Piece>);
    const victim = makePiece("e1", 2, 4, 6, ["bomb", "destroy_row"]);
    const state = baseState({
      pieces: [scavenger, victim],
      currentPlayer: 1,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: true }],
    });
    const next = moveTo(state, 4, 6);
    const scavengerAfter = next.pieces.find((p) => p.id === "p1")!;
    // Scavenger keeps its own powers and gains the victim's
    expect(scavengerAfter.powers).toContain("relocate");
    expect(scavengerAfter.powers).toContain("bomb");
    expect(scavengerAfter.powers).toContain("destroy_row");
    // Victim is removed
    expect(next.pieces.find((p) => p.id === "e1")).toBeUndefined();
  });

  it("a non-scavenger capturing piece does NOT inherit enemy powers", () => {
    const attacker = makePiece("p1", 1, 4, 5, ["relocate"]);
    const victim = makePiece("e1", 2, 4, 6, ["bomb"]);
    const state = baseState({
      pieces: [attacker, victim],
      currentPlayer: 1,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: true }],
    });
    const next = moveTo(state, 4, 6);
    const attackerAfter = next.pieces.find((p) => p.id === "p1")!;
    expect(attackerAfter.powers).not.toContain("bomb");
  });
});

// ---------------------------------------------------------------------------
// 7. beneficiary — isBeneficiary consumed by moveTo (capture of an allied
// piece): beneficiary inherits allies' powers when they are captured/destroyed.
//
// When an allied piece is captured by an enemy AND the current player has a
// beneficiary, the beneficiary inherits the slain ally's powers.
// ---------------------------------------------------------------------------

describe("beneficiary: isBeneficiary consumed by moveTo (ally captured by enemy)", () => {
  it("beneficiary inherits powers of an allied piece captured by the enemy", () => {
    const beneficiary = makePiece("p1-b", 1, 1, 1, [], { isBeneficiary: true } as Partial<Piece>);
    const ally = makePiece("p1-a", 1, 4, 6, ["bomb", "relocate"]);
    const enemy = makePiece("e1", 2, 4, 5, []);
    const state = baseState({
      pieces: [beneficiary, ally, enemy],
      currentPlayer: 2,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: true }],
    });
    const next = moveTo(state, 4, 6);
    const benAfter = next.pieces.find((p) => p.id === "p1-b")!;
    // The ally was player 1; beneficiary is player 1 — should inherit ally's powers
    expect(benAfter.powers).toContain("bomb");
    expect(benAfter.powers).toContain("relocate");
    // Ally is gone
    expect(next.pieces.find((p) => p.id === "p1-a")).toBeUndefined();
  });

  it("beneficiary does NOT inherit powers when a non-allied piece is captured", () => {
    const beneficiary = makePiece("p1-b", 1, 1, 1, [], { isBeneficiary: true } as Partial<Piece>);
    const enemy = makePiece("e1", 2, 4, 6, ["bomb"]);
    const attacker = makePiece("p1", 1, 4, 5, []);
    const state = baseState({
      pieces: [beneficiary, attacker, enemy],
      currentPlayer: 1,
      selected: { row: 4, col: 5 },
      validMoves: [{ row: 4, col: 6, capture: true }],
    });
    // Player 1 captures an enemy: beneficiary should NOT get the enemy's powers
    const next = moveTo(state, 4, 6);
    const benAfter = next.pieces.find((p) => p.id === "p1-b")!;
    expect(benAfter.powers).not.toContain("bomb");
  });
});
