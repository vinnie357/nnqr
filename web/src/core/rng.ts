// Seeded RNG (mulberry32). Workrush lesson: build deterministic randomness in
// from the start so QA scenarios are reproducible — scattered Date.now()/
// Math.random() made workrush's game un-replayable. Orb spawning and AI
// tie-breaks (Track B2) draw from here, never from Math.random().

export interface Rng {
  /** Next float in [0, 1). */
  next(): number;
  /** Integer in [min, max] inclusive. */
  int(min: number, max: number): number;
  /** Pick a uniformly random element (returns undefined for an empty array). */
  pick<T>(items: readonly T[]): T | undefined;
}

export function makeRng(seed: number): Rng {
  let s = seed >>> 0;
  const next = (): number => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    int: (min, max) => min + Math.floor(next() * (max - min + 1)),
    pick: (items) => (items.length === 0 ? undefined : items[Math.floor(next() * items.length)]),
  };
}
