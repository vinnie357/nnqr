// Behavioral test for the AI power-activation integration in GameController.
//
// nnqr-20 follow-up: chooseMove can return a power activation, but the controller
// must actually APPLY it via the executor — not just clear aiThinking and skip.
// This test drives a full AI turn (not just chooseMove) and asserts the enemy
// piece count DROPS after the AI activates destroy_row — i.e. the power's effect
// reached the board.

import { describe, expect, it } from "vitest";
import { BOARD_COLS, BOARD_ROWS } from "../core/board";
import { createHeightMap } from "../core/height";
import type { GameState, Piece } from "../core/types";
import { GameController } from "./controller";

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
    currentPlayer: 2,
    selected: null,
    validMoves: [],
    status: "playing",
    winner: null,
    turn: 0,
    seed: 1,
    ...overrides,
  };
}

describe("GameController – AI power activation is applied", () => {
  it("AI activates destroy_row and the enemy piece count actually drops", () => {
    // AI is player 2. Its piece at (4,1) owns destroy_row. Two player-1 enemies
    // sit in row 4 (cols 8 and 9) — the destroy_row trigger condition (≥2 enemies,
    // no allies in row). No AI allies share row 4.
    const initial = makeState(
      [
        { row: 4, col: 8 },
        { row: 4, col: 9 },
        { row: 1, col: 1 }, // a p1 piece off-row so p1 isn't eliminated (game not over)
      ],
      [{ row: 4, col: 1, extra: { powers: ["destroy_row"] } }],
      { currentPlayer: 2 },
    );

    const enemiesBefore = initial.pieces.filter((p) => p.player === 1).length;
    expect(enemiesBefore).toBe(3);

    let latest: GameState = initial;
    const controller = new GameController(initial, "vsai", "medium", (s) => {
      latest = s.game;
    });

    // Drive the AI turn directly (synchronous; bypasses the setTimeout delay).
    controller.runAiTurnNow();

    const enemiesAfter = latest.pieces.filter((p) => p.player === 1).length;

    // The two enemies in row 4 must be gone — power was applied, not just chosen.
    expect(enemiesAfter).toBeLessThan(enemiesBefore);
    expect(enemiesAfter).toBe(1); // only the off-row (1,1) piece survives

    // The destroy_row power must be consumed from the AI piece's inventory.
    const aiPiece = latest.pieces.find((p) => p.player === 2);
    expect(aiPiece).toBeDefined();
    expect(aiPiece!.powers).not.toContain("destroy_row");

    // Turn must have advanced back to the human player.
    expect(latest.currentPlayer).toBe(1);
  });

  it("AI normal move path still works (no power) — a piece moves", () => {
    // AI piece at (4,4) with no powers; one human enemy at (7,7) far away.
    const initial = makeState(
      [{ row: 7, col: 7 }],
      [{ row: 4, col: 4 }],
      { currentPlayer: 2 },
    );

    let latest: GameState = initial;
    const controller = new GameController(initial, "vsai", "medium", (s) => {
      latest = s.game;
    });

    controller.runAiTurnNow();

    // AI piece should have moved from (4,4); turn passes to human.
    const aiPiece = latest.pieces.find((p) => p.player === 2)!;
    const moved = aiPiece.row !== 4 || aiPiece.col !== 4;
    expect(moved).toBe(true);
    expect(latest.currentPlayer).toBe(1);
  });
});
