// Terrain height rules. Ported from lua/love2d/src/shared/height.lua:
// heights 0..4; a piece may drop any number of levels but climb at most 1.

export const MIN_HEIGHT = 0;
export const MAX_HEIGHT = 4;
export const MAX_CLIMB = 1;

export function createHeightMap(rows: number, cols: number, fill = 0): number[][] {
  return Array.from({ length: rows }, () => Array.from({ length: cols }, () => fill));
}

export function getHeight(map: number[][], row: number, col: number): number {
  return map[row - 1]?.[col - 1] ?? 0;
}

export function clampHeight(height: number): number {
  return Math.max(MIN_HEIGHT, Math.min(MAX_HEIGHT, height));
}

/** True if a piece at `from` height may move to a tile at `to` height. */
export function canClimb(from: number, to: number): boolean {
  return to - from <= MAX_CLIMB;
}
