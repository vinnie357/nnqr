// Power executor — ported from lua/love2d/src/shared/power_executor.lua
//
// Dispatch is GENERATED from the definitions by naming convention at module
// load time: id "destroy_row" → effects.activateDestroyRow. A load-time assert
// confirms every definition resolves to a handler, so a new power can never be
// added to definitions.ts without also wiring its effect.
//
// Powers whose generic signature (state, piece, target?) is not sufficient get
// an OVERRIDE that resolves the piece/tile before forwarding to effects.

import type { GameState, Piece } from "../types";
import { definitions } from "./definitions";
import * as effects from "./effects";

type Handler = (state: GameState, piece: Piece, target?: unknown) => GameState;

// ---------------------------------------------------------------------------
// Naming convention: "orb_spy_row" → "activateOrbSpyRow"
// ---------------------------------------------------------------------------
function effectFnName(id: string): string {
  return (
    "activate" +
    id
      .split("_")
      .map((s) => s.charAt(0).toUpperCase() + s.slice(1))
      .join("")
  );
}

// ---------------------------------------------------------------------------
// Overrides — powers that need target-piece resolution or special forwarding
// ---------------------------------------------------------------------------

function targetPieceHandler(
  fn: (state: GameState, piece: Piece, target: Piece) => GameState,
): Handler {
  return (state, piece, target) => {
    if (!target || typeof target !== "object") return state;
    const t = target as { row?: number; col?: number };
    if (t.row === undefined || t.col === undefined) return state;
    const targetPiece = state.pieces.find((p) => p.row === t.row && p.col === t.col);
    if (!targetPiece) return state;
    return fn(state, piece, targetPiece);
  };
}

const OVERRIDES: Record<string, Handler> = {
  recruit: targetPieceHandler(effects.activateRecruit),
  switcheroo: targetPieceHandler(effects.activateSwitcheroo),
};

// Secondary actions (follow-up dispatches, not standalone power definitions)
const SECONDARY_ACTIONS: Record<string, Handler> = {
  hotspot_teleport: (state, piece, target) =>
    effects.activateHotspotTeleport(
      state,
      piece,
      (target as { row: number; col: number }) ?? { row: piece.row, col: piece.col },
    ),
  multiply: (state, piece, target) =>
    effects.activateMultiply(
      state,
      piece,
      (target as { row: number; col: number }) ?? { row: piece.row, col: piece.col },
    ),
  raise_tile: (state, piece, target) =>
    effects.activateRaiseTile(
      state,
      piece,
      (target as { row: number; col: number }) ?? { row: piece.row, col: piece.col },
    ),
  lower_tile: (state, piece, target) =>
    effects.activateLowerTile(
      state,
      piece,
      (target as { row: number; col: number }) ?? { row: piece.row, col: piece.col },
    ),
  refurb: (state, piece, target) =>
    effects.activateRefurb(state, piece, (target as { row: number; col: number }) ?? null),
  centerpult: (state, piece, target) =>
    effects.activateCenterpult(
      state,
      piece,
      (target as { row: number; col: number } | null) ?? null,
    ),
};

// ---------------------------------------------------------------------------
// Build the dispatch table
// ---------------------------------------------------------------------------
const DISPATCH: Record<string, Handler> = {};

for (const id of Object.keys(definitions)) {
  if (OVERRIDES[id]) {
    DISPATCH[id] = OVERRIDES[id]!;
    continue;
  }
  if (SECONDARY_ACTIONS[id]) {
    // Some powers (multiply, raise_tile, lower_tile, refurb, centerpult) need
    // target forwarding — handled via SECONDARY_ACTIONS above.
    DISPATCH[id] = SECONDARY_ACTIONS[id]!;
    continue;
  }
  const fnName = effectFnName(id);
  const fn = (effects as Record<string, unknown>)[fnName];
  if (typeof fn !== "function") {
    throw new Error(
      `PowerExecutor: power '${id}' has no effect function effects.${fnName}`,
    );
  }
  DISPATCH[id] = fn as Handler;
}

// Register secondary actions not in definitions (e.g. hotspot_teleport)
for (const [id, handler] of Object.entries(SECONDARY_ACTIONS)) {
  if (!(id in DISPATCH)) DISPATCH[id] = handler;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Execute a power's game logic. Returns unchanged state for unknown powers.
 */
export function execute(
  state: GameState,
  piece: Piece,
  powerId: string,
  target?: unknown,
): GameState {
  const handler = DISPATCH[powerId];
  if (!handler) return state;
  return handler(state, piece, target);
}

/** Whether a power id resolves to a registered handler. */
export function isRegistered(powerId: string): boolean {
  return powerId in DISPATCH;
}

/** All registered dispatch ids (defined powers + secondary actions). */
export function registeredIds(): string[] {
  return Object.keys(DISPATCH);
}
