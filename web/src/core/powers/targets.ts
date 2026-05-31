// Power target resolution — pure helper for the view layer.
// Given a piece and a powerId, returns the set of valid target tiles/pieces
// that the player must click to complete the activation.
//
// Only "targeting-required" powers need entries here. Powers whose targeting is
// "self" / "self_row" / "self_column" / "area_3x3" / "global" activate
// immediately (no click needed) — the view layer detects them by checking
// `needsTarget(powerId)`.

import { inBounds, isDestroyed, pieceAt } from "../board";
import type { GameState, Piece } from "../types";

type Area = "row" | "column" | "radial";

export interface TargetTile {
  row: number;
  col: number;
}

const ADJACENT: ReadonlyArray<readonly [number, number]> = [
  [-1, 0],
  [1, 0],
  [0, -1],
  [0, 1],
];

const ADJACENT8: ReadonlyArray<readonly [number, number]> = [
  [-1, -1],
  [-1, 0],
  [-1, 1],
  [0, -1],
  [0, 1],
  [1, -1],
  [1, 0],
  [1, 1],
];

function adjTiles(piece: Piece): TargetTile[] {
  return ADJACENT.map(([dr, dc]) => ({ row: piece.row + dr, col: piece.col + dc })).filter(
    ({ row, col }) => inBounds(row, col),
  );
}

function adj8Tiles(piece: Piece): TargetTile[] {
  return ADJACENT8.map(([dr, dc]) => ({ row: piece.row + dr, col: piece.col + dc })).filter(
    ({ row, col }) => inBounds(row, col),
  );
}

/** Returns valid target tiles for a power that requires a target click. */
export function getTargetTiles(
  state: GameState,
  piece: Piece,
  powerId: string,
): TargetTile[] {
  switch (powerId) {
    case "raise_tile":
    case "lower_tile": {
      // Adjacent tiles that are not destroyed, and raise/lower won't go out of range.
      return adjTiles(piece).filter(({ row, col }) => !isDestroyed(state, row, col));
    }

    case "switcheroo": {
      // Any adjacent tile occupied by any piece (own or enemy).
      return adjTiles(piece).filter(({ row, col }) => pieceAt(state, row, col) !== null);
    }

    case "recruit": {
      // Adjacent enemy pieces.
      return adj8Tiles(piece).filter(({ row, col }) => {
        const p = pieceAt(state, row, col);
        return p !== null && p.player !== piece.player;
      });
    }

    case "multiply": {
      // Adjacent empty, non-destroyed tiles.
      return adjTiles(piece).filter(
        ({ row, col }) => !isDestroyed(state, row, col) && pieceAt(state, row, col) === null,
      );
    }

    case "refurb": {
      // Adjacent destroyed tiles.
      return adjTiles(piece).filter(({ row, col }) => isDestroyed(state, row, col));
    }

    case "centerpult": {
      // Any tile that is the center of a 2×2 square formation (all 4 corners occupied).
      // The target is one of the 4 tiles in a 2x2 block; we look for blocks where
      // all 4 are occupied. Return the top-left corner of each such block as the
      // click target (consistent with the Love2D version: target is any of the 4 tiles).
      // We expose all tiles in valid 2x2 blocks as targets.
      const targets: TargetTile[] = [];
      const seen = new Set<string>();
      for (let r = 1; r < state.rows; r++) {
        for (let c = 1; c < state.cols; c++) {
          const corners: Array<{ row: number; col: number }> = [
            { row: r, col: c },
            { row: r, col: c + 1 },
            { row: r + 1, col: c },
            { row: r + 1, col: c + 1 },
          ];
          const allOccupied = corners.every(({ row, col }) => pieceAt(state, row, col) !== null);
          if (allOccupied) {
            for (const t of corners) {
              const key = `${t.row},${t.col}`;
              if (!seen.has(key)) {
                seen.add(key);
                targets.push(t);
              }
            }
          }
        }
      }
      return targets;
    }

    case "hotspot": {
      // Either: set hotspot on own tile (handled immediately by executor), or
      // show existing friendly hotspots as targets.
      // The executor treats hotspot as "self" if no hotspot tile exists yet, else
      // as "special" to pick a hotspot. We return the friendly hotspot tiles.
      const extState = state as GameState & { hotspotTiles?: Record<string, number> };
      const hotspots = extState.hotspotTiles ?? {};
      return Object.entries(hotspots)
        .filter(([, player]) => player === piece.player)
        .map(([key]) => {
          const [r, c] = key.split(",").map(Number);
          return { row: r ?? 0, col: c ?? 0 };
        })
        .filter(({ row, col }) => inBounds(row, col));
    }

    default:
      return [];
  }
}

// ---------------------------------------------------------------------------
// Area preview tiles (for UI highlight and AI targeting of area powers)
// ---------------------------------------------------------------------------

/** Read the grow_quadradius level from a piece (0 if not set). */
function growLevel(piece: Piece): number {
  return (piece as Piece & { growQuadradiusLevel?: number }).growQuadradiusLevel ?? 0;
}

/**
 * Returns the tiles that an area power activated by `piece` would affect.
 * Excludes the activating piece's own tile (center).
 * Respects grow_quadradius expansion:
 *  - radial: Chebyshev distance 1+L
 *  - row:    band [r-L, r+L] full board width
 *  - column: band [c-L, c+L] full board height
 * All results are clamped to board bounds.
 *
 * Used by the view layer to preview area effects before activation and by the
 * AI to determine how many tiles a power would hit.
 */
export function getAreaPreviewTiles(
  state: GameState,
  piece: Piece,
  area: Area,
): TargetTile[] {
  const L = growLevel(piece);
  const dist = 1 + L;
  const tiles: TargetTile[] = [];
  if (area === "row") {
    const rMin = Math.max(1, piece.row - L);
    const rMax = Math.min(state.rows, piece.row + L);
    for (let r = rMin; r <= rMax; r++) {
      for (let c = 1; c <= state.cols; c++) {
        if (r === piece.row && c === piece.col) continue;
        tiles.push({ row: r, col: c });
      }
    }
  } else if (area === "column") {
    const cMin = Math.max(1, piece.col - L);
    const cMax = Math.min(state.cols, piece.col + L);
    for (let r = 1; r <= state.rows; r++) {
      for (let c = cMin; c <= cMax; c++) {
        if (r === piece.row && c === piece.col) continue;
        tiles.push({ row: r, col: c });
      }
    }
  } else {
    for (let dr = -dist; dr <= dist; dr++) {
      for (let dc = -dist; dc <= dist; dc++) {
        if (dr === 0 && dc === 0) continue;
        const r = piece.row + dr;
        const c = piece.col + dc;
        if (inBounds(r, c)) tiles.push({ row: r, col: c });
      }
    }
  }
  return tiles;
}

/**
 * Returns true when this power needs the player to click a target tile/piece
 * before execution. Powers without target selection execute immediately.
 */
export function needsTarget(powerId: string): boolean {
  return [
    "raise_tile",
    "lower_tile",
    "switcheroo",
    "recruit",
    "multiply",
    "refurb",
    "centerpult",
    "hotspot",
  ].includes(powerId);
}

/**
 * Count occurrences of each power id in a piece's inventory.
 * Returns a map from powerId to count.
 */
export function powerCounts(piece: Piece): Map<string, number> {
  const counts = new Map<string, number>();
  for (const id of piece.powers) {
    counts.set(id, (counts.get(id) ?? 0) + 1);
  }
  return counts;
}

/**
 * Returns the power id that has 10+ copies in the piece's inventory, or null.
 * A piece with 10+ of one power overheats and is destroyed.
 */
export function overheatPower(piece: Piece): string | null {
  const counts = powerCounts(piece);
  for (const [id, count] of counts) {
    if (count >= 10) return id;
  }
  return null;
}

/**
 * Compute the height-based shade offset for a tile (0..4 → darkest..brightest).
 */
export function heightShade(height: number): number {
  return height / 4;
}

/**
 * Interpolate between two hex color components.
 */
export function lerpColor(a: number, b: number, t: number): number {
  return Math.round(a + (b - a) * t);
}

/**
 * Pack RGB components into a Phaser-compatible 0xRRGGBB integer.
 */
export function rgb(r: number, g: number, b: number): number {
  return ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff);
}

/**
 * Returns the tile color based on checkerboard pattern and height.
 * Light tiles: base 0x33384a, brightened by height.
 * Dark tiles:  base 0x2a2f3e, brightened by height.
 */
export function tileColor(row: number, col: number, height: number): number {
  const isLight = (row + col) % 2 === 0;
  const base = isLight ? { r: 0x33, g: 0x38, b: 0x4a } : { r: 0x2a, g: 0x2f, b: 0x3e };
  const bright = { r: 0x5a, g: 0x60, b: 0x78 };
  const t = heightShade(height);
  return rgb(
    lerpColor(base.r, bright.r, t),
    lerpColor(base.g, bright.g, t),
    lerpColor(base.b, bright.b, t),
  );
}
