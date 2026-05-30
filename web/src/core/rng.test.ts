import { describe, expect, it } from "vitest";
import { makeRng } from "./rng";

describe("makeRng", () => {
  it("is deterministic for a given seed", () => {
    const a = makeRng(42);
    const b = makeRng(42);
    const seqA = [a.next(), a.next(), a.next()];
    const seqB = [b.next(), b.next(), b.next()];
    expect(seqA).toEqual(seqB);
  });

  it("differs across seeds", () => {
    expect(makeRng(1).next()).not.toEqual(makeRng(2).next());
  });

  it("int() stays within the inclusive range", () => {
    const r = makeRng(7);
    for (let i = 0; i < 200; i++) {
      const v = r.int(1, 6);
      expect(v).toBeGreaterThanOrEqual(1);
      expect(v).toBeLessThanOrEqual(6);
    }
  });

  it("pick() returns undefined for an empty array", () => {
    expect(makeRng(1).pick([])).toBeUndefined();
  });
});
