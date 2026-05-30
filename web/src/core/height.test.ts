import { describe, expect, it } from "vitest";
import {
  MAX_HEIGHT,
  MIN_HEIGHT,
  canClimb,
  clampHeight,
  createHeightMap,
  getHeight,
} from "./height";

describe("createHeightMap", () => {
  it("creates a map with the correct number of rows and columns", () => {
    const map = createHeightMap(8, 10, 0);
    expect(map.length).toBe(8);
    expect(map[0]!.length).toBe(10);
  });

  it("fills all cells with the specified value", () => {
    const map = createHeightMap(4, 6, 3);
    for (const row of map) {
      for (const cell of row) {
        expect(cell).toBe(3);
      }
    }
  });

  it("defaults to fill=0 when not specified", () => {
    const map = createHeightMap(2, 2);
    expect(map[0]![0]).toBe(0);
    expect(map[1]![1]).toBe(0);
  });

  it("creates independent rows (mutating one does not affect another)", () => {
    const map = createHeightMap(3, 3, 0);
    map[0]![0] = 4;
    expect(map[1]![0]).toBe(0);
  });
});

describe("getHeight", () => {
  it("returns the height at a valid 1-indexed (row, col)", () => {
    const map = createHeightMap(8, 10, 0);
    map[2]![4] = 3; // row 3, col 5
    expect(getHeight(map, 3, 5)).toBe(3);
  });

  it("returns 0 for an out-of-bounds row (too low)", () => {
    const map = createHeightMap(8, 10, 2);
    expect(getHeight(map, 0, 5)).toBe(0);
  });

  it("returns 0 for an out-of-bounds row (too high)", () => {
    const map = createHeightMap(8, 10, 2);
    expect(getHeight(map, 9, 5)).toBe(0);
  });

  it("returns 0 for an out-of-bounds col (too low)", () => {
    const map = createHeightMap(8, 10, 2);
    expect(getHeight(map, 4, 0)).toBe(0);
  });

  it("returns 0 for an out-of-bounds col (too high)", () => {
    const map = createHeightMap(8, 10, 2);
    expect(getHeight(map, 4, 11)).toBe(0);
  });

  it("returns height for top-left corner (1,1)", () => {
    const map = createHeightMap(8, 10, 0);
    map[0]![0] = 2;
    expect(getHeight(map, 1, 1)).toBe(2);
  });

  it("returns height for bottom-right corner (8,10)", () => {
    const map = createHeightMap(8, 10, 0);
    map[7]![9] = 4;
    expect(getHeight(map, 8, 10)).toBe(4);
  });
});

describe("canClimb", () => {
  it("allows staying at the same height", () => {
    expect(canClimb(2, 2)).toBe(true);
  });

  it("allows climbing exactly 1 level", () => {
    expect(canClimb(1, 2)).toBe(true);
  });

  it("disallows climbing 2 levels", () => {
    expect(canClimb(0, 2)).toBe(false);
  });

  it("disallows climbing 3 levels", () => {
    expect(canClimb(0, 3)).toBe(false);
  });

  it("allows dropping any number of levels", () => {
    expect(canClimb(4, 0)).toBe(true);
    expect(canClimb(3, 0)).toBe(true);
    expect(canClimb(2, 1)).toBe(true);
  });
});

describe("clampHeight", () => {
  it("clamps below MIN_HEIGHT to MIN_HEIGHT", () => {
    expect(clampHeight(MIN_HEIGHT - 1)).toBe(MIN_HEIGHT);
  });

  it("clamps above MAX_HEIGHT to MAX_HEIGHT", () => {
    expect(clampHeight(MAX_HEIGHT + 1)).toBe(MAX_HEIGHT);
  });

  it("returns the value unchanged when within bounds", () => {
    expect(clampHeight(0)).toBe(0);
    expect(clampHeight(2)).toBe(2);
    expect(clampHeight(4)).toBe(4);
  });
});
