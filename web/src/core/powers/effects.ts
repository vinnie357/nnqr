// Power effects — ported from lua/love2d/src/shared/power_effects.lua.
//
// Design rules (mirror the Lua refactor in bd7d810):
//   • All functions are PURE — return a new GameState, never mutate inputs.
//   • Area helpers (areaPieces / areaTileCoords) collapse the 57 row/col/radial
//     variants behind a single "area" parameter, exactly as Lua does.
//   • makeRng(state.seed + state.turn) is the sole randomness source.
//   • Piece flags (isJumpProof, canMoveDiagonally, canClimbAny, canWrap,
//     isInvisible) are set directly on the Piece; the contract in types.ts is
//     the single source of truth for those fields.
//
// Extended-state fields used here (not in the frozen contract but carried in
// the GameState spread so the contract type is satisfied via index access):
//   bankruptTiles, hotspotTiles, multipliedPieces — all optional Record/arrays.

import { clampHeight, getHeight, MAX_HEIGHT } from "../height";
import { makeRng } from "../rng";
import type { GameState, Piece } from "../types";
import { tileKey } from "../types";
import { inBounds } from "../board";

// ---------------------------------------------------------------------------
// Internal types for extended state fields not in the frozen contract
// ---------------------------------------------------------------------------

// We carry extra fields in the GameState via an intersection type privately.
// The public API still accepts/returns GameState (the frozen contract) but we
// cast internally to access the mutable extension fields.

type ExtState = GameState & {
  extraMove?: boolean;
  bankruptTiles?: Record<string, true>;
  hotspotTiles?: Record<string, number>; // key → player (1|2)
  multipliedPieces?: string[]; // piece ids
};

// ---------------------------------------------------------------------------
// Area selectors (shared core — mirror Lua areaPieceTargets / areaTiles)
// ---------------------------------------------------------------------------

type Area = "row" | "column" | "radial";

/** Read the grow_quadradius level from a piece (0 if not set). */
function growLevel(piece: Piece): number {
  return (piece as Piece & { growQuadradiusLevel?: number }).growQuadradiusLevel ?? 0;
}

/** Pieces in the given area, excluding the activating piece itself.
 *
 *  grow_quadradius expansion (level L = growQuadradiusLevel ?? 0):
 *  - radial: Chebyshev distance 1+L (L=0 → dist 1 = 3×3 ring, L=1 → dist 2 = 5×5 ring, …)
 *  - row:    band [r-L, r+L] (2L+1 rows), full board width
 *  - column: band [c-L, c+L], full board height
 */
function areaPieces(state: GameState, piece: Piece, area: Area): Piece[] {
  const L = growLevel(piece);
  const dist = 1 + L;
  return state.pieces.filter((p) => {
    if (p.id === piece.id) return false;
    if (area === "row") return Math.abs(p.row - piece.row) <= L;
    if (area === "column") return Math.abs(p.col - piece.col) <= L;
    // radial: Chebyshev distance ≤ dist (Chebyshev = max(|Δr|, |Δc|))
    return Math.abs(p.row - piece.row) <= dist && Math.abs(p.col - piece.col) <= dist;
  });
}

/** Tile coordinates in the given area, excluding the activating piece's own tile.
 *
 *  grow_quadradius expansion follows the same rules as areaPieces above.
 *  All coordinates are clamped to [1..rows] × [1..cols].
 */
function areaTileCoords(
  state: GameState,
  piece: Piece,
  area: Area,
): Array<{ row: number; col: number }> {
  const L = growLevel(piece);
  const dist = 1 + L;
  const tiles: Array<{ row: number; col: number }> = [];
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

// ---------------------------------------------------------------------------
// Piece mutation helpers (immutable — return new pieces array)
// ---------------------------------------------------------------------------

/** Return a new pieces array with the piece replaced by `next`. */
function replacePiece(pieces: Piece[], next: Piece): Piece[] {
  return pieces.map((p) => (p.id === next.id ? next : p));
}

/** Return a new pieces array with the piece whose id matches removed. */
function removePieceById(pieces: Piece[], id: string): Piece[] {
  return pieces.filter((p) => p.id !== id);
}

/** Remove one copy of `powerId` from a piece's powers array. */
function consumePower(piece: Piece, powerId: string): Piece {
  const idx = piece.powers.indexOf(powerId);
  if (idx === -1) return piece;
  const powers = [...piece.powers.slice(0, idx), ...piece.powers.slice(idx + 1)];
  return { ...piece, powers };
}

/** Return a new state where `piece` has had `powerId` consumed. */
function withConsumedPower(state: GameState, piece: Piece, powerId: string): GameState {
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

// ---------------------------------------------------------------------------
// Empty-tile helper
// ---------------------------------------------------------------------------

function emptyTiles(state: GameState): Array<{ row: number; col: number }> {
  const occupied = new Set<string>(state.pieces.map((p) => tileKey(p.row, p.col)));
  const tiles: Array<{ row: number; col: number }> = [];
  for (let r = 1; r <= state.rows; r++) {
    for (let c = 1; c <= state.cols; c++) {
      const key = tileKey(r, c);
      const isDestroyed = (state.destroyedTiles as Record<string, unknown>)[key] === true;
      if (!occupied.has(key) && !isDestroyed) tiles.push({ row: r, col: c });
    }
  }
  return tiles;
}

// ---------------------------------------------------------------------------
// Core family implementations (data-driven, one per family)
// ---------------------------------------------------------------------------

/** Core: destroy pieces in area. Does NOT affect terrain. */
function destroyArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const targets = areaPieces(state, piece, area);
  const targetIds = new Set(targets.map((t) => t.id));
  const pieces = state.pieces.filter((p) => !targetIds.has(p.id));
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

/** Core: destroy pieces AND mark tiles as destroyed. Own tile excluded. */
function acidicArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const targets = areaPieces(state, piece, area);
  const targetIds = new Set(targets.map((t) => t.id));
  const pieces = state.pieces.filter((p) => !targetIds.has(p.id));
  const tiles = areaTileCoords(state, piece, area);
  const destroyedTiles = { ...state.destroyedTiles } as Record<string, true>;
  for (const t of tiles) destroyedTiles[tileKey(t.row, t.col)] = true;
  const updated = consumePower(piece, powerId);
  return {
    ...state,
    pieces: replacePiece(pieces, updated),
    destroyedTiles,
  };
}

/** Core: recruit (convert) enemy pieces in area. */
function recruitArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const targets = areaPieces(state, piece, area).filter((p) => p.player !== piece.player);
  const pieces = state.pieces.map((p) =>
    targets.some((t) => t.id === p.id) ? { ...p, player: piece.player } : p,
  );
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

/** Core: scramble (shuffle) positions of pieces in row area (shuffle columns). */
function scrambleRow(state: GameState, piece: Piece, powerId: string): GameState {
  const rng = makeRng(state.seed + state.turn);
  const inRow = state.pieces.filter((p) => p.row === piece.row);
  const cols = inRow.map((p) => p.col);
  // Fisher-Yates
  for (let i = cols.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    const tmp = cols[i]!;
    cols[i] = cols[j]!;
    cols[j] = tmp;
  }
  const shuffled = new Map(inRow.map((p, i) => [p.id, cols[i]!]));
  const pieces = state.pieces.map((p) => {
    const newCol = shuffled.get(p.id);
    return newCol !== undefined ? { ...p, col: newCol } : p;
  });
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

/** Core: scramble (shuffle) positions of pieces in column area (shuffle rows). */
function scrambleColumn(state: GameState, piece: Piece, powerId: string): GameState {
  const rng = makeRng(state.seed + state.turn);
  const inCol = state.pieces.filter((p) => p.col === piece.col);
  const rows = inCol.map((p) => p.row);
  for (let i = rows.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    const tmp = rows[i]!;
    rows[i] = rows[j]!;
    rows[j] = tmp;
  }
  const shuffled = new Map(inCol.map((p, i) => [p.id, rows[i]!]));
  const pieces = state.pieces.map((p) => {
    const newRow = shuffled.get(p.id);
    return newRow !== undefined ? { ...p, row: newRow } : p;
  });
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

/** Core: scramble radial (shuffle {row,col} pairs in grow-aware radial area). */
function scrambleRadial(state: GameState, piece: Piece, powerId: string): GameState {
  const rng = makeRng(state.seed + state.turn);
  const dist = 1 + growLevel(piece);
  const inArea = state.pieces.filter(
    (p) => Math.abs(p.row - piece.row) <= dist && Math.abs(p.col - piece.col) <= dist,
  );
  const positions = inArea.map((p) => ({ row: p.row, col: p.col }));
  for (let i = positions.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    const tmp = positions[i]!;
    positions[i] = positions[j]!;
    positions[j] = tmp;
  }
  const shuffled = new Map(inArea.map((p, i) => [p.id, positions[i]!]));
  const pieces = state.pieces.map((p) => {
    const pos = shuffled.get(p.id);
    return pos !== undefined ? { ...p, row: pos.row, col: pos.col } : p;
  });
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

/** Core: raise/lower tiles in area by delta. */
function adjustHeightArea(
  state: GameState,
  piece: Piece,
  area: Area,
  delta: number,
  powerId: string,
  includeOwn = false,
): GameState {
  const tiles = includeOwn
    ? [...areaTileCoords(state, piece, area), { row: piece.row, col: piece.col }]
    : areaTileCoords(state, piece, area);
  let heightMap = state.heightMap.map((r) => [...r]);
  for (const t of tiles) {
    const cur = getHeight(heightMap, t.row, t.col);
    heightMap[t.row - 1]![t.col - 1] = clampHeight(cur + delta);
  }
  const updated = consumePower(piece, powerId);
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

/** Core: invert heights in area. */
function invertArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const tiles = [...areaTileCoords(state, piece, area), { row: piece.row, col: piece.col }];
  let heightMap = state.heightMap.map((r) => [...r]);
  for (const t of tiles) {
    const cur = getHeight(heightMap, t.row, t.col);
    heightMap[t.row - 1]![t.col - 1] = clampHeight(MAX_HEIGHT - cur);
  }
  const updated = consumePower(piece, powerId);
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

/** Core: dredge — raise tiles under allies, lower tiles under enemies in area. */
function dredgeArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const tiles = [...areaTileCoords(state, piece, area), { row: piece.row, col: piece.col }];
  let heightMap = state.heightMap.map((r) => [...r]);
  for (const t of tiles) {
    const occupant = state.pieces.find((p) => p.row === t.row && p.col === t.col);
    if (!occupant) continue;
    const cur = getHeight(heightMap, t.row, t.col);
    const delta = occupant.player === piece.player ? 1 : -1;
    heightMap[t.row - 1]![t.col - 1] = clampHeight(cur + delta);
  }
  const updated = consumePower(piece, powerId);
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

/** Core: teach — copy caster's powers to allied pieces in area. */
function teachArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  // Consume the teach power from caster first (so it's not copied)
  const casterUpdated = consumePower(piece, powerId);
  const allies = areaPieces(state, piece, area).filter((p) => p.player === piece.player);
  const pieces = replacePiece(state.pieces, casterUpdated).map((p) => {
    if (!allies.some((a) => a.id === p.id)) return p;
    return { ...p, powers: [...p.powers, ...casterUpdated.powers] };
  });
  return { ...state, pieces };
}

/** Core: learn — absorb powers from allied pieces in area. */
function learnArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  // Consume the learn power first
  const casterUpdated = consumePower(piece, powerId);
  const allies = areaPieces(state, piece, area).filter((p) => p.player === piece.player);
  const drainedIds = new Set(allies.map((a) => a.id));
  let gained: string[] = [];
  const pieces = replacePiece(state.pieces, casterUpdated).map((p) => {
    if (!drainedIds.has(p.id)) return p;
    gained = [...gained, ...p.powers];
    return { ...p, powers: [] };
  });
  const casterFinal = pieces.find((p) => p.id === piece.id)!;
  return {
    ...state,
    pieces: replacePiece(pieces, { ...casterFinal, powers: [...casterFinal.powers, ...gained] }),
  };
}

/** Core: pilfer — steal one random power from each enemy in area. */
function pilferArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const rng = makeRng(state.seed + state.turn);
  const enemies = areaPieces(state, piece, area).filter((p) => p.player !== piece.player);
  // Consume the pilfer power first
  const casterUpdated = consumePower(piece, powerId);
  let pieces = replacePiece(state.pieces, casterUpdated);
  let stolenPowers: string[] = [];
  for (const enemy of enemies) {
    const current = pieces.find((p) => p.id === enemy.id);
    if (!current || current.powers.length === 0) continue;
    const idx = rng.int(0, current.powers.length - 1);
    const stolen = current.powers[idx]!;
    stolenPowers = [...stolenPowers, stolen];
    const newEnemyPowers = [...current.powers.slice(0, idx), ...current.powers.slice(idx + 1)];
    pieces = replacePiece(pieces, { ...current, powers: newEnemyPowers });
  }
  const casterFinal = pieces.find((p) => p.id === piece.id)!;
  return {
    ...state,
    pieces: replacePiece(pieces, { ...casterFinal, powers: [...casterFinal.powers, ...stolenPowers] }),
  };
}

/** Core: flag-mark enemy pieces in area with a debuff flag. */
function flagEnemiesArea(
  state: GameState,
  piece: Piece,
  area: Area,
  powerId: string,
  flagKey: string,
  flagValue: unknown,
): GameState {
  const enemies = areaPieces(state, piece, area).filter((p) => p.player !== piece.player);
  const enemyIds = new Set(enemies.map((e) => e.id));
  const pieces = state.pieces.map((p) => {
    if (!enemyIds.has(p.id)) return p;
    return { ...p, [flagKey]: flagValue };
  });
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

/** Core: spyware — reveal powers of enemy pieces in area. */
function spywareArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  return flagEnemiesArea(state, piece, area, powerId, "powersRevealed", true);
}

/** Core: refurb — repair destroyed tiles in area. */
function refurbArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  if (Object.keys(state.destroyedTiles).length === 0) {
    return withConsumedPower(state, piece, powerId);
  }
  const tiles = [
    ...areaTileCoords(state, piece, area),
    { row: piece.row, col: piece.col }, // Lua refurb includes own tile
  ];
  const destroyedTiles = { ...state.destroyedTiles } as Record<string, true>;
  let heightMap = state.heightMap.map((r) => [...r]);
  for (const t of tiles) {
    const key = tileKey(t.row, t.col);
    if (destroyedTiles[key]) {
      delete destroyedTiles[key];
      heightMap[t.row - 1]![t.col - 1] = 0;
    }
  }
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(state.pieces, updated), destroyedTiles, heightMap };
}

/** Core: bankrupt — mark tiles in area as bankrupt traps. */
function bankruptArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const ext = state as ExtState;
  const bankruptTiles: Record<string, true> = { ...(ext.bankruptTiles ?? {}) };
  const tiles = areaTileCoords(state, piece, area);
  for (const t of tiles) bankruptTiles[tileKey(t.row, t.col)] = true;
  const updated = consumePower(piece, powerId);
  return {
    ...state,
    bankruptTiles,
    pieces: replacePiece(state.pieces, updated),
  } as GameState;
}

/** Core: tripwire — mark enemy pieces in area as tripwired. */
function tripwireArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  return flagEnemiesArea(state, piece, area, powerId, "isTripwired", true);
}

/** Core: inhibit — mark enemy pieces in area as inhibited. */
function inhibitArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  return flagEnemiesArea(state, piece, area, powerId, "isInhibited", true);
}

/** Core: parasite — mark enemy pieces in area as parasitized by piece.id. */
function parasiteArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  return flagEnemiesArea(state, piece, area, powerId, "parasitizedBy", piece.id);
}

/** Core: purify — remove debuffs from allies, buffs from enemies in area. */
function purifyArea(state: GameState, piece: Piece, area: Area, powerId: string): GameState {
  const candidates = areaPieces(state, piece, area);
  const pieces = state.pieces.map((p) => {
    if (!candidates.some((c) => c.id === p.id)) return p;
    if (p.player === piece.player) {
      // Remove debuffs from ally
      const { powersRevealed: _r, isTripwired: _t, isInhibited: _i, parasitizedBy: _p, ...rest } =
        p as Piece & Record<string, unknown>;
      return rest as Piece;
    } else {
      // Remove buffs from enemy
      const {
        growQuadradiusLevel: _g,
        canClimbAny: _ca,
        canMoveDiagonally: _cm,
        isJumpProof: _jp,
        canWrap: _cw,
        isInvisible: _inv,
        isScavenger: _sc,
        isBeneficiary: _b,
        ...rest
      } = p as Piece & Record<string, unknown>;
      return rest as Piece;
    }
  });
  const updated = consumePower(piece, powerId);
  return { ...state, pieces: replacePiece(pieces, updated) };
}

// ---------------------------------------------------------------------------
// Individual effect functions (exported for executor)
// ---------------------------------------------------------------------------

// --- Movement ---

export function activateMoveDiagonal(state: GameState, piece: Piece): GameState {
  const updated: Piece = { ...consumePower(piece, "move_diagonal"), canMoveDiagonally: true };
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

export function activateMoveAgain(state: GameState, piece: Piece): GameState {
  const updated = consumePower(piece, "move_again");
  return { ...state, extraMove: true, pieces: replacePiece(state.pieces, updated) } as GameState;
}

export function activateRelocate(state: GameState, piece: Piece): GameState {
  const rng = makeRng(state.seed + state.turn);
  const open = emptyTiles(state);
  if (open.length === 0) return withConsumedPower(state, piece, "relocate");
  const target = rng.pick(open)!;
  const updated = consumePower(piece, "relocate");
  return {
    ...state,
    pieces: replacePiece(state.pieces, { ...updated, row: target.row, col: target.col }),
  };
}

export function activateSwitcheroo(state: GameState, piece: Piece, target: Piece): GameState {
  const updated = consumePower(piece, "switcheroo");
  const pieces = state.pieces.map((p) => {
    if (p.id === piece.id) return { ...updated, row: target.row, col: target.col };
    if (p.id === target.id) return { ...p, row: piece.row, col: piece.col };
    return p;
  });
  return { ...state, pieces };
}

export function activateFlatToSphere(state: GameState, piece: Piece): GameState {
  const updated: Piece = { ...consumePower(piece, "flat_to_sphere"), canWrap: true };
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

export function activateClimbTile(state: GameState, piece: Piece): GameState {
  const updated: Piece = { ...consumePower(piece, "climb_tile"), canClimbAny: true };
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

export function activateHotspot(state: GameState, piece: Piece): GameState {
  const ext = state as ExtState;
  const hotspotTiles: Record<string, number> = { ...(ext.hotspotTiles ?? {}) };
  hotspotTiles[tileKey(piece.row, piece.col)] = piece.player;
  const updated = consumePower(piece, "hotspot");
  return {
    ...state,
    hotspotTiles,
    pieces: replacePiece(state.pieces, updated),
  } as GameState;
}

export function activateHotspotTeleport(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number },
): GameState {
  const updated = consumePower(piece, "hotspot");
  return {
    ...state,
    pieces: replacePiece(state.pieces, { ...updated, row: target.row, col: target.col }),
  };
}

export function activateCenterpult(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number } | null,
): GameState {
  // No target: no-op (keep the power)
  if (!target) return state;
  // Displace the piece already at target (if any, excluding self)
  const displaced = state.pieces.find(
    (p) => p.id !== piece.id && p.row === target.row && p.col === target.col,
  );
  let pieces = displaced ? removePieceById(state.pieces, displaced.id) : state.pieces;
  const updated = consumePower(piece, "centerpult");
  pieces = replacePiece(pieces, { ...updated, row: target.row, col: target.col });
  return { ...state, pieces };
}

// --- Offensive ---

export function activateDestroyRow(state: GameState, piece: Piece): GameState {
  return destroyArea(state, piece, "row", "destroy_row");
}

export function activateDestroyColumn(state: GameState, piece: Piece): GameState {
  return destroyArea(state, piece, "column", "destroy_column");
}

export function activateDestroyRadial(state: GameState, piece: Piece): GameState {
  return destroyArea(state, piece, "radial", "destroy_radial");
}

export function activateBomb(state: GameState, piece: Piece): GameState {
  // Bomb: destroy pieces in radial area (excluding self) + lower terrain by 1 in same area.
  // Tiles reaching height ≤ 0 become destroyed.
  // grow_quadradius expands the radial distance (dist = 1 + L).
  const dist = 1 + growLevel(piece);
  const targets = areaPieces(state, piece, "radial");
  const targetIds = new Set(targets.map((t) => t.id));
  const pieces = state.pieces.filter((p) => !targetIds.has(p.id));
  let heightMap = state.heightMap.map((r) => [...r]);
  const destroyedTiles = { ...state.destroyedTiles } as Record<string, true>;
  for (let dr = -dist; dr <= dist; dr++) {
    for (let dc = -dist; dc <= dist; dc++) {
      const r = piece.row + dr;
      const c = piece.col + dc;
      if (!inBounds(r, c)) continue;
      const cur = getHeight(heightMap, r, c);
      const next = cur - 1;
      heightMap[r - 1]![c - 1] = clampHeight(next);
      if (next <= 0) destroyedTiles[tileKey(r, c)] = true;
    }
  }
  const updated = consumePower(piece, "bomb");
  return {
    ...state,
    pieces: replacePiece(pieces, updated),
    heightMap,
    destroyedTiles,
  };
}

export function activateKamikazeRadial(state: GameState, piece: Piece): GameState {
  // Kamikaze includes self — don't use destroyArea which excludes self.
  // grow_quadradius expands the radial distance (dist = 1 + L).
  const dist = 1 + growLevel(piece);
  const inArea = state.pieces.filter(
    (p) => Math.abs(p.row - piece.row) <= dist && Math.abs(p.col - piece.col) <= dist,
  );
  const targetIds = new Set(inArea.map((t) => t.id));
  return { ...state, pieces: state.pieces.filter((p) => !targetIds.has(p.id)) };
}

export function activateKamikazeRow(state: GameState, piece: Piece): GameState {
  // grow_quadradius expands the row band to [r-L, r+L].
  const L = growLevel(piece);
  return {
    ...state,
    pieces: state.pieces.filter((p) => Math.abs(p.row - piece.row) > L),
  };
}

export function activateKamikazeColumn(state: GameState, piece: Piece): GameState {
  // grow_quadradius expands the column band to [c-L, c+L].
  const L = growLevel(piece);
  return {
    ...state,
    pieces: state.pieces.filter((p) => Math.abs(p.col - piece.col) > L),
  };
}

export function activateSmartBombs(state: GameState, piece: Piece): GameState {
  const enemies = areaPieces(state, piece, "radial").filter((p) => p.player !== piece.player);
  const enemyIds = new Set(enemies.map((e) => e.id));
  const pieces = state.pieces.filter((p) => !enemyIds.has(p.id));
  const updated = consumePower(piece, "smart_bombs");
  return { ...state, pieces: replacePiece(pieces, updated) };
}

export function activateAcidicRadial(state: GameState, piece: Piece): GameState {
  return acidicArea(state, piece, "radial", "acidic_radial");
}

export function activateAcidicRow(state: GameState, piece: Piece): GameState {
  return acidicArea(state, piece, "row", "acidic_row");
}

export function activateAcidicColumn(state: GameState, piece: Piece): GameState {
  return acidicArea(state, piece, "column", "acidic_column");
}

export function activatePilferRadial(state: GameState, piece: Piece): GameState {
  return pilferArea(state, piece, "radial", "pilfer_radial");
}

export function activatePilferRow(state: GameState, piece: Piece): GameState {
  return pilferArea(state, piece, "row", "pilfer_row");
}

export function activatePilferColumn(state: GameState, piece: Piece): GameState {
  return pilferArea(state, piece, "column", "pilfer_column");
}

// --- Defensive ---

export function activateJumpProof(state: GameState, piece: Piece): GameState {
  const updated: Piece = { ...consumePower(piece, "jump_proof"), isJumpProof: true };
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

// --- Terrain ---

export function activateRaiseTile(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number },
): GameState {
  let heightMap = state.heightMap.map((r) => [...r]);
  heightMap[target.row - 1]![target.col - 1] = clampHeight(
    getHeight(heightMap, target.row, target.col) + 1,
  );
  const updated = consumePower(piece, "raise_tile");
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

export function activateLowerTile(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number },
): GameState {
  let heightMap = state.heightMap.map((r) => [...r]);
  heightMap[target.row - 1]![target.col - 1] = clampHeight(
    getHeight(heightMap, target.row, target.col) - 1,
  );
  const updated = consumePower(piece, "lower_tile");
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

export function activatePlateau(state: GameState, piece: Piece): GameState {
  let heightMap = state.heightMap.map((r) => [...r]);
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      const r = piece.row + dr;
      const c = piece.col + dc;
      if (inBounds(r, c)) heightMap[r - 1]![c - 1] = MAX_HEIGHT;
    }
  }
  const updated = consumePower(piece, "plateau");
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

export function activateMoat(state: GameState, piece: Piece): GameState {
  let heightMap = state.heightMap.map((r) => [...r]);
  // Raise center to max
  heightMap[piece.row - 1]![piece.col - 1] = MAX_HEIGHT;
  // Lower surrounding ring by 1
  for (let dr = -1; dr <= 1; dr++) {
    for (let dc = -1; dc <= 1; dc++) {
      if (dr === 0 && dc === 0) continue;
      const r = piece.row + dr;
      const c = piece.col + dc;
      if (inBounds(r, c)) {
        heightMap[r - 1]![c - 1] = clampHeight(getHeight(heightMap, r, c) - 1);
      }
    }
  }
  const updated = consumePower(piece, "moat");
  return { ...state, heightMap, pieces: replacePiece(state.pieces, updated) };
}

export function activateTrenchRow(state: GameState, piece: Piece): GameState {
  return adjustHeightArea(state, piece, "row", -2, "trench_row", true);
}

export function activateTrenchColumn(state: GameState, piece: Piece): GameState {
  return adjustHeightArea(state, piece, "column", -2, "trench_column", true);
}

export function activateWallRow(state: GameState, piece: Piece): GameState {
  return adjustHeightArea(state, piece, "row", 2, "wall_row", true);
}

export function activateWallColumn(state: GameState, piece: Piece): GameState {
  return adjustHeightArea(state, piece, "column", 2, "wall_column", true);
}

export function activateInvertRadial(state: GameState, piece: Piece): GameState {
  return invertArea(state, piece, "radial", "invert_radial");
}

export function activateInvertRow(state: GameState, piece: Piece): GameState {
  return invertArea(state, piece, "row", "invert_row");
}

export function activateInvertColumn(state: GameState, piece: Piece): GameState {
  return invertArea(state, piece, "column", "invert_column");
}

export function activateDredgeRadial(state: GameState, piece: Piece): GameState {
  return dredgeArea(state, piece, "radial", "dredge_radial");
}

export function activateDredgeRow(state: GameState, piece: Piece): GameState {
  return dredgeArea(state, piece, "row", "dredge_row");
}

export function activateDredgeColumn(state: GameState, piece: Piece): GameState {
  return dredgeArea(state, piece, "column", "dredge_column");
}

// --- Strategic ---

export function activateRecruit(state: GameState, piece: Piece, target: Piece): GameState {
  const pieces = state.pieces.map((p) =>
    p.id === target.id ? { ...p, player: piece.player } : p,
  );
  const updated = consumePower(piece, "recruit");
  return { ...state, pieces: replacePiece(pieces, updated) };
}

export function activateMultiply(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number },
): GameState {
  const ext = state as ExtState;
  const newId = `${piece.id}-mul-${state.turn}`;
  const newPiece: Piece = {
    id: newId,
    player: piece.player,
    row: target.row,
    col: target.col,
    powers: [],
    // isMultiplied tracked via extended field
  };
  const multipliedPieces = [...(ext.multipliedPieces ?? []), newId];
  const updated = consumePower(piece, "multiply");
  return {
    ...state,
    pieces: [...replacePiece(state.pieces, updated), newPiece],
    multipliedPieces,
  } as GameState;
}

export function activateRecruitRow(state: GameState, piece: Piece): GameState {
  return recruitArea(state, piece, "row", "recruit_row");
}

export function activateRecruitColumn(state: GameState, piece: Piece): GameState {
  return recruitArea(state, piece, "column", "recruit_column");
}

export function activateTeachRadial(state: GameState, piece: Piece): GameState {
  return teachArea(state, piece, "radial", "teach_radial");
}

export function activateTeachRow(state: GameState, piece: Piece): GameState {
  return teachArea(state, piece, "row", "teach_row");
}

export function activateTeachColumn(state: GameState, piece: Piece): GameState {
  return teachArea(state, piece, "column", "teach_column");
}

export function activateLearnRadial(state: GameState, piece: Piece): GameState {
  return learnArea(state, piece, "radial", "learn_radial");
}

export function activateLearnRow(state: GameState, piece: Piece): GameState {
  return learnArea(state, piece, "row", "learn_row");
}

export function activateLearnColumn(state: GameState, piece: Piece): GameState {
  return learnArea(state, piece, "column", "learn_column");
}

export function activateScavenger(state: GameState, piece: Piece): GameState {
  const updated = { ...consumePower(piece, "scavenger"), isScavenger: true } as Piece;
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

// --- Utility ---

export function activateInvisible(state: GameState, piece: Piece): GameState {
  const updated: Piece = { ...consumePower(piece, "invisible"), isInvisible: true };
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

// --- Restoration ---

export function activateRefurb(
  state: GameState,
  piece: Piece,
  target: { row: number; col: number } | null,
): GameState {
  if (!target) return withConsumedPower(state, piece, "refurb");
  const key = tileKey(target.row, target.col);
  if (!state.destroyedTiles[key]) return withConsumedPower(state, piece, "refurb");
  const destroyedTiles = { ...state.destroyedTiles } as Record<string, true>;
  delete destroyedTiles[key];
  let heightMap = state.heightMap.map((r) => [...r]);
  heightMap[target.row - 1]![target.col - 1] = 0;
  const updated = consumePower(piece, "refurb");
  return { ...state, destroyedTiles, heightMap, pieces: replacePiece(state.pieces, updated) };
}

export function activateRefurbRadial(state: GameState, piece: Piece): GameState {
  return refurbArea(state, piece, "radial", "refurb_radial");
}

export function activateRefurbRow(state: GameState, piece: Piece): GameState {
  return refurbArea(state, piece, "row", "refurb_row");
}

export function activateRefurbColumn(state: GameState, piece: Piece): GameState {
  return refurbArea(state, piece, "column", "refurb_column");
}

export function activatePurifyRadial(state: GameState, piece: Piece): GameState {
  return purifyArea(state, piece, "radial", "purify_radial");
}

export function activatePurifyRow(state: GameState, piece: Piece): GameState {
  return purifyArea(state, piece, "row", "purify_row");
}

export function activatePurifyColumn(state: GameState, piece: Piece): GameState {
  return purifyArea(state, piece, "column", "purify_column");
}

// --- Chaos ---

export function activateScrambleRadial(state: GameState, piece: Piece): GameState {
  return scrambleRadial(state, piece, "scramble_radial");
}

export function activateScrambleRow(state: GameState, piece: Piece): GameState {
  return scrambleRow(state, piece, "scramble_row");
}

export function activateScrambleColumn(state: GameState, piece: Piece): GameState {
  return scrambleColumn(state, piece, "scramble_column");
}

// --- Meta ---

export function activateDoublePowers(state: GameState, piece: Piece): GameState {
  // Consume double_powers first, then duplicate the remaining powers
  const consumed = consumePower(piece, "double_powers");
  const doubled = [...consumed.powers, ...consumed.powers];
  return { ...state, pieces: replacePiece(state.pieces, { ...consumed, powers: doubled }) };
}

export function activateOrbicRehash(state: GameState, piece: Piece): GameState {
  const rng = makeRng(state.seed + state.turn);
  if (state.orbs.length === 0) return withConsumedPower(state, piece, "orbic_rehash");
  const powerIds = state.orbs.map((o) => o.powerId);
  const open = emptyTiles(state);
  // Shuffle open tiles
  const shuffled = [...open];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    const tmp = shuffled[i]!;
    shuffled[i] = shuffled[j]!;
    shuffled[j] = tmp;
  }
  const newOrbs = powerIds
    .slice(0, shuffled.length)
    .map((powerId, i) => ({ row: shuffled[i]!.row, col: shuffled[i]!.col, powerId }));
  const updated = consumePower(piece, "orbic_rehash");
  return { ...state, orbs: newOrbs, pieces: replacePiece(state.pieces, updated) };
}

export function activateCancelMultiply(state: GameState, piece: Piece): GameState {
  const ext = state as ExtState;
  const multiplied = new Set(ext.multipliedPieces ?? []);
  const pieces = state.pieces.filter((p) => !multiplied.has(p.id));
  const updated = consumePower(piece, "cancel_multiply");
  return {
    ...state,
    pieces: replacePiece(pieces, updated),
    multipliedPieces: [],
  } as GameState;
}

export function activateGrowQuadradius(state: GameState, piece: Piece): GameState {
  const current = (piece as Piece & { growQuadradiusLevel?: number }).growQuadradiusLevel ?? 0;
  const newLevel = Math.min(3, current + 1);
  const updated = {
    ...consumePower(piece, "grow_quadradius"),
    growQuadradiusLevel: newLevel,
  } as Piece;
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

export function activateBeneficiary(state: GameState, piece: Piece): GameState {
  const updated = { ...consumePower(piece, "beneficiary"), isBeneficiary: true } as Piece;
  return { ...state, pieces: replacePiece(state.pieces, updated) };
}

// --- Intelligence ---

export function activateSpywareRadial(state: GameState, piece: Piece): GameState {
  return spywareArea(state, piece, "radial", "spyware_radial");
}

export function activateSpywareRow(state: GameState, piece: Piece): GameState {
  return spywareArea(state, piece, "row", "spyware_row");
}

export function activateSpywareColumn(state: GameState, piece: Piece): GameState {
  return spywareArea(state, piece, "column", "spyware_column");
}

export function activateOrbSpyRadial(state: GameState, piece: Piece): GameState {
  // Mark orbs in radial area as revealed (flag on orb via extended state).
  // grow_quadradius expands the radial distance (dist = 1 + L).
  const dist = 1 + growLevel(piece);
  const orbs = state.orbs.map((o) => {
    if (Math.abs(o.row - piece.row) <= dist && Math.abs(o.col - piece.col) <= dist) {
      return { ...o, revealed: true };
    }
    return o;
  });
  const updated = consumePower(piece, "orb_spy_radial");
  return { ...state, orbs, pieces: replacePiece(state.pieces, updated) };
}

export function activateOrbSpyRow(state: GameState, piece: Piece): GameState {
  const orbs = state.orbs.map((o) =>
    o.row === piece.row ? { ...o, revealed: true } : o,
  );
  const updated = consumePower(piece, "orb_spy_row");
  return { ...state, orbs, pieces: replacePiece(state.pieces, updated) };
}

export function activateOrbSpyColumn(state: GameState, piece: Piece): GameState {
  const orbs = state.orbs.map((o) =>
    o.col === piece.col ? { ...o, revealed: true } : o,
  );
  const updated = consumePower(piece, "orb_spy_column");
  return { ...state, orbs, pieces: replacePiece(state.pieces, updated) };
}

// --- Trap ---

export function activateBankruptRadial(state: GameState, piece: Piece): GameState {
  return bankruptArea(state, piece, "radial", "bankrupt_radial");
}

export function activateBankruptRow(state: GameState, piece: Piece): GameState {
  return bankruptArea(state, piece, "row", "bankrupt_row");
}

export function activateBankruptColumn(state: GameState, piece: Piece): GameState {
  return bankruptArea(state, piece, "column", "bankrupt_column");
}

export function activateTripwireRadial(state: GameState, piece: Piece): GameState {
  return tripwireArea(state, piece, "radial", "tripwire_radial");
}

export function activateTripwireRow(state: GameState, piece: Piece): GameState {
  return tripwireArea(state, piece, "row", "tripwire_row");
}

export function activateTripwireColumn(state: GameState, piece: Piece): GameState {
  return tripwireArea(state, piece, "column", "tripwire_column");
}

// --- Control ---

export function activateInhibitRadial(state: GameState, piece: Piece): GameState {
  return inhibitArea(state, piece, "radial", "inhibit_radial");
}

export function activateInhibitRow(state: GameState, piece: Piece): GameState {
  return inhibitArea(state, piece, "row", "inhibit_row");
}

export function activateInhibitColumn(state: GameState, piece: Piece): GameState {
  return inhibitArea(state, piece, "column", "inhibit_column");
}

export function activateParasiteRadial(state: GameState, piece: Piece): GameState {
  return parasiteArea(state, piece, "radial", "parasite_radial");
}

export function activateParasiteRow(state: GameState, piece: Piece): GameState {
  return parasiteArea(state, piece, "row", "parasite_row");
}

export function activateParasiteColumn(state: GameState, piece: Piece): GameState {
  return parasiteArea(state, piece, "column", "parasite_column");
}
