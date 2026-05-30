// PauseOverlay — a pure-logic state machine for the pause/menu overlay.
//
// Design: framework-agnostic. The Phaser scene owns the actual Phaser objects;
// this module tracks whether the overlay is open and exposes the three
// transition functions (toggle, resume, quit). Tests exercise this module
// without Phaser.

export interface PauseOverlayState {
  /** True when the pause overlay is visible and board input is suspended. */
  readonly paused: boolean;
}

/** Returns the initial (unpaused) state. */
export function createPauseOverlay(): PauseOverlayState {
  return { paused: false };
}

/** Toggle paused/resumed. */
export function togglePause(s: PauseOverlayState): PauseOverlayState {
  return { paused: !s.paused };
}

/** Explicitly resume (close overlay). */
export function resume(_s: PauseOverlayState): PauseOverlayState {
  return { paused: false };
}

/** Explicitly pause (open overlay). */
export function pause(_s: PauseOverlayState): PauseOverlayState {
  return { paused: true };
}

/**
 * Handle an Escape keypress in the context of the game.
 *
 * Logic (per acceptance criteria):
 *   1. If a power-targeting mode is active → cancel targeting only; leave
 *      pause state unchanged and return `{ action: "cancelPower" }`.
 *   2. Otherwise → toggle the pause overlay and return
 *      `{ action: "togglePause", next: PauseOverlayState }`.
 *
 * This keeps the Escape disambiguation free of Phaser/scene dependencies so it
 * can be unit-tested directly.
 */
export type EscapeResult =
  | { action: "cancelPower" }
  | { action: "togglePause"; next: PauseOverlayState };

export function handleEscape(
  s: PauseOverlayState,
  powerModeActive: boolean,
): EscapeResult {
  if (powerModeActive) {
    return { action: "cancelPower" };
  }
  const next = togglePause(s);
  return { action: "togglePause", next };
}
