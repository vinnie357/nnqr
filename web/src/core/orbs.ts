// Power orbs: spawn every SPAWN_INTERVAL turns on empty tiles (2-4 at a time),
// collected when a piece lands on one. Ported from lua/love2d/src/shared/powers.lua
// (shouldSpawnOrbs / spawnOrbs / collectOrb). Randomness flows through the seeded
// RNG (workrush lesson: deterministic, replayable). The set of power ids is
// injected so this module stays independent of the powers catalog.

import { isDestroyed, pieceAt } from "./board";
import { makeRng, type Rng } from "./rng";
import type { GameState, Orb } from "./types";
import { tileKey } from "./types";

export const SPAWN_INTERVAL = 7;
export const MIN_ORBS = 2;
export const MAX_ORBS = 4;

export function shouldSpawnOrbs(turn: number): boolean {
  return turn > 0 && turn % SPAWN_INTERVAL === 0;
}

export function emptyTiles(state: GameState): Array<{ row: number; col: number }> {
  const occupied = new Set<string>();
  for (const p of state.pieces) occupied.add(tileKey(p.row, p.col));
  for (const o of state.orbs) occupied.add(tileKey(o.row, o.col));
  const tiles: Array<{ row: number; col: number }> = [];
  for (let row = 1; row <= state.rows; row++) {
    for (let col = 1; col <= state.cols; col++) {
      if (!occupied.has(tileKey(row, col)) && !isDestroyed(state, row, col)) {
        tiles.push({ row, col });
      }
    }
  }
  return tiles;
}

/**
 * Spawn 2-4 orbs on random empty tiles, each carrying a random power id. Returns
 * a new state with the orbs appended. Deterministic for a given seed+turn.
 */
export function spawnOrbs(state: GameState, powerIds: readonly string[], rng: Rng = makeRng(state.seed + state.turn)): GameState {
  if (powerIds.length === 0) return state;
  const open = emptyTiles(state);
  const count = Math.min(rng.int(MIN_ORBS, MAX_ORBS), open.length);
  const chosen = new Set<number>();
  const newOrbs: Orb[] = [];
  while (chosen.size < count) {
    const idx = rng.int(0, open.length - 1);
    if (chosen.has(idx)) continue;
    chosen.add(idx);
    const tile = open[idx]!;
    newOrbs.push({ row: tile.row, col: tile.col, powerId: powerIds[rng.int(0, powerIds.length - 1)]! });
  }
  return { ...state, orbs: [...state.orbs, ...newOrbs] };
}

/**
 * The piece at (row, col) collects any orb there: the power id is added to its
 * inventory and the orb removed. Returns the new state and the collected id.
 *
 * Extended-state consumers wired here:
 *   isInhibited  — inhibited piece cannot collect the power (orb is still removed).
 *   parasitizedBy — the collected power is redirected to the parasite owner piece.
 */
export function collectOrb(state: GameState, row: number, col: number): { state: GameState; collected: string | null } {
  const orb = state.orbs.find((o) => o.row === row && o.col === col);
  if (!orb) return { state, collected: null };
  const piece = pieceAt(state, row, col);
  if (!piece) return { state, collected: null };

  // Always remove the orb from the board.
  const orbs = state.orbs.filter((o) => o !== orb);

  // Inhibited: orb is consumed (removed) but the power is NOT granted to the piece.
  if (piece.isInhibited) {
    return { state: { ...state, orbs }, collected: null };
  }

  // Parasitized: the power goes to the parasite owner instead of this piece.
  if (piece.parasitizedBy) {
    const parasiteId = piece.parasitizedBy;
    const pieces = state.pieces.map((p) =>
      p.id === parasiteId ? { ...p, powers: [...p.powers, orb.powerId] } : p,
    );
    return { state: { ...state, pieces, orbs }, collected: orb.powerId };
  }

  // Normal collection.
  const pieces = state.pieces.map((p) => (p.id === piece.id ? { ...p, powers: [...p.powers, orb.powerId] } : p));
  return { state: { ...state, pieces, orbs }, collected: orb.powerId };
}
