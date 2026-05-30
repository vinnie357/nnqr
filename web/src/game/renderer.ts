// Renderer — draws the board, pieces, orbs, UI, and overlays onto Phaser
// Graphics and Text objects. Stateless: called every frame with the current
// ControllerState + scene references.

import type Phaser from "phaser";
import { isDestroyed as isTileDestroyed } from "../core/board";
import { getHeight } from "../core/height";
import { definitions } from "../core/powers/definitions";
import { powerCounts, tileColor } from "../core/powers/targets";
import type { GameState, Piece } from "../core/types";
import type { ControllerState } from "./controller";

// ---------------------------------------------------------------------------
// Layout constants
// ---------------------------------------------------------------------------

export const TILE = 56;
export const MARGIN_LEFT = 40;
export const MARGIN_TOP = 60;
export const POWER_MENU_X = MARGIN_LEFT + 10 * TILE + 20;
export const POWER_MENU_W = 210;
export const STATUS_BAND = 50;
export const BOARD_W = 10 * TILE;
export const BOARD_H = 8 * TILE;
export const CANVAS_W = POWER_MENU_X + POWER_MENU_W + 10;
export const CANVAS_H = MARGIN_TOP + BOARD_H + STATUS_BAND;

// ---------------------------------------------------------------------------
// Color palette
// ---------------------------------------------------------------------------

const C = {
  bg: 0x1e2230,
  p1: 0x4a8cf0,
  p2: 0xf05a5a,
  p1Dark: 0x2e5899,
  p2Dark: 0x992929,
  selectedOutline: 0xffd633,
  moveEmpty: 0x4ce06a,
  moveCapture: 0xf2802c,
  powerTarget: 0xcc66ff,
  orb: 0xffe44d,
  destroyedTile: 0x111318,
  menuBg: 0x181b26,
  menuBorder: 0x3a3f55,
  menuHeader: 0xffd633,
  menuText: 0xe6e8ee,
  menuActive: 0x9944cc,
  aiIndicator: 0x44aaff,
  winBanner: 0xffd633,
  winBg: 0x111318,
  overheatWarning: 0xff4422,
  heightBar0: 0x2a2f3e,
  heightBar4: 0x5a6080,
};

// ---------------------------------------------------------------------------
// Coordinate helpers
// ---------------------------------------------------------------------------

export function tileXY(row: number, col: number): { x: number; y: number } {
  return {
    x: MARGIN_LEFT + (col - 1) * TILE,
    y: MARGIN_TOP + (row - 1) * TILE,
  };
}

// ---------------------------------------------------------------------------
// Render helpers
// ---------------------------------------------------------------------------

function pieceColor(player: 1 | 2): number {
  return player === 1 ? C.p1 : C.p2;
}

function drawHeightBar(g: Phaser.GameObjects.Graphics, x: number, y: number, height: number): void {
  if (height === 0) return;
  const barH = 4;
  const barW = TILE - 8;
  const barY = y + TILE - barH - 2;
  const barX = x + 4;
  // Background
  g.fillStyle(C.heightBar0, 0.6);
  g.fillRect(barX, barY, barW, barH);
  // Fill
  const fillW = Math.round((height / 4) * barW);
  g.fillStyle(C.heightBar4, 0.9);
  g.fillRect(barX, barY, fillW, barH);
}

function drawPiece(
  g: Phaser.GameObjects.Graphics,
  piece: Piece,
  selected: boolean,
): void {
  const { x, y } = tileXY(piece.row, piece.col);
  const cx = x + TILE / 2;
  const cy = y + TILE / 2;
  const r = TILE / 2 - 8;

  const color = pieceColor(piece.player);
  g.fillStyle(color, 1);
  g.fillCircle(cx, cy, r);

  // Stroke
  const strokeColor = piece.player === 1 ? C.p1Dark : C.p2Dark;
  g.lineStyle(2, strokeColor, 0.9);
  g.strokeCircle(cx, cy, r);

  // Selection highlight ring.
  if (selected) {
    g.lineStyle(3, C.selectedOutline, 1);
    g.strokeCircle(cx, cy, r + 3);
  }

  // Power badge: small dot in top-right if piece has powers.
  if (piece.powers.length > 0) {
    // Count powers for overheat warning.
    let maxCount = 0;
    for (const [, cnt] of powerCounts(piece)) {
      if (cnt > maxCount) maxCount = cnt;
    }
    const badgeColor = maxCount >= 7 ? C.overheatWarning : C.orb;
    g.fillStyle(badgeColor, 1);
    g.fillCircle(cx + r - 3, cy - r + 3, 5);

    // Show count if > 1.
    // (Text is added separately in the scene layer.)
  }
}

// ---------------------------------------------------------------------------
// Main render function
// ---------------------------------------------------------------------------

export interface RenderTargets {
  gfx: Phaser.GameObjects.Graphics;
  scene: Phaser.Scene;
  texts: {
    status: Phaser.GameObjects.Text;
    powerMenu: Phaser.GameObjects.Text;
    aiIndicator: Phaser.GameObjects.Text;
    winBanner: Phaser.GameObjects.Text;
  };
}

export function renderFrame(
  ctrl: ControllerState,
  targets: RenderTargets,
): void {
  const { game, powerMode, aiThinking, mode, difficulty } = ctrl;
  const { gfx, texts } = targets;
  gfx.clear();

  renderBoard(gfx, game);
  renderOrbs(gfx, game);
  renderMoveMarkers(gfx, game);
  renderPowerTargets(gfx, powerMode);
  renderPieces(gfx, game);

  renderStatusText(texts.status, game, aiThinking, mode, difficulty);
  renderPowerMenu(texts.powerMenu, game, powerMode, ctrl);
  renderAiIndicator(texts.aiIndicator, mode, difficulty, game, aiThinking);
  renderWinBanner(texts.winBanner, game);
}

// ---------------------------------------------------------------------------
// Board tiles
// ---------------------------------------------------------------------------

function renderBoard(g: Phaser.GameObjects.Graphics, game: GameState): void {
  for (let row = 1; row <= game.rows; row++) {
    for (let col = 1; col <= game.cols; col++) {
      const { x, y } = tileXY(row, col);
      const destroyed = isTileDestroyed(game, row, col);

      if (destroyed) {
        g.fillStyle(C.destroyedTile, 1);
        g.fillRect(x, y, TILE, TILE);
        // Hatch pattern to make destroyed tiles distinct.
        g.lineStyle(1, 0x333344, 0.6);
        for (let i = 0; i < TILE; i += 8) {
          g.lineBetween(x + i, y, x, y + i);
          g.lineBetween(x + TILE, y + i, x + i, y + TILE);
        }
      } else {
        const height = getHeight(game.heightMap, row, col);
        const color = tileColor(row, col, height);
        g.fillStyle(color, 1);
        g.fillRect(x, y, TILE, TILE);

        // Height indicator bar at bottom of tile.
        drawHeightBar(g, x, y, height);

        // Grid line.
        g.lineStyle(1, 0x1e2230, 0.4);
        g.strokeRect(x, y, TILE, TILE);
      }
    }
  }

  // Selected tile outline.
  if (game.selected) {
    const { x, y } = tileXY(game.selected.row, game.selected.col);
    g.lineStyle(4, C.selectedOutline, 1);
    g.strokeRect(x + 2, y + 2, TILE - 4, TILE - 4);
  }
}

// ---------------------------------------------------------------------------
// Orbs
// ---------------------------------------------------------------------------

function renderOrbs(g: Phaser.GameObjects.Graphics, game: GameState): void {
  for (const orb of game.orbs) {
    const { x, y } = tileXY(orb.row, orb.col);
    const cx = x + TILE / 2;
    const cy = y + TILE / 2;

    // Glow ring.
    g.fillStyle(C.orb, 0.25);
    g.fillCircle(cx, cy, 14);

    // Gold circle.
    g.fillStyle(C.orb, 1);
    g.fillCircle(cx, cy, 8);

    // White shine dot.
    g.fillStyle(0xffffff, 0.8);
    g.fillCircle(cx - 2, cy - 2, 2);
  }
}

// ---------------------------------------------------------------------------
// Move markers
// ---------------------------------------------------------------------------

function renderMoveMarkers(g: Phaser.GameObjects.Graphics, game: GameState): void {
  for (const m of game.validMoves) {
    const { x, y } = tileXY(m.row, m.col);
    const cx = x + TILE / 2;
    const cy = y + TILE / 2;
    if (m.capture) {
      g.lineStyle(4, C.moveCapture, 0.9);
      g.strokeCircle(cx, cy, TILE / 2 - 6);
      // Inner X for capture.
      g.lineStyle(2, C.moveCapture, 0.7);
      g.lineBetween(cx - 8, cy - 8, cx + 8, cy + 8);
      g.lineBetween(cx + 8, cy - 8, cx - 8, cy + 8);
    } else {
      g.fillStyle(C.moveEmpty, 0.85);
      g.fillCircle(cx, cy, 9);
      g.lineStyle(2, C.moveEmpty, 0.4);
      g.strokeCircle(cx, cy, 9);
    }
  }
}

// ---------------------------------------------------------------------------
// Power target tiles
// ---------------------------------------------------------------------------

function renderPowerTargets(
  g: Phaser.GameObjects.Graphics,
  powerMode: ControllerState["powerMode"],
): void {
  if (!powerMode) return;
  for (const t of powerMode.targetTiles) {
    const { x, y } = tileXY(t.row, t.col);
    g.fillStyle(C.powerTarget, 0.35);
    g.fillRect(x + 2, y + 2, TILE - 4, TILE - 4);
    g.lineStyle(2, C.powerTarget, 0.9);
    g.strokeRect(x + 2, y + 2, TILE - 4, TILE - 4);
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

function renderPieces(g: Phaser.GameObjects.Graphics, game: GameState): void {
  const selectedId = game.selected
    ? game.pieces.find(
        (p) => p.row === game.selected!.row && p.col === game.selected!.col,
      )?.id
    : undefined;

  for (const piece of game.pieces) {
    drawPiece(g, piece, piece.id === selectedId);
  }
}

// ---------------------------------------------------------------------------
// Status text
// ---------------------------------------------------------------------------

function renderStatusText(
  text: Phaser.GameObjects.Text,
  game: GameState,
  aiThinking: boolean,
  mode: string,
  difficulty: string,
): void {
  if (game.status === "won") {
    text.setText("");
    return;
  }

  const p1count = game.pieces.filter((p) => p.player === 1).length;
  const p2count = game.pieces.filter((p) => p.player === 2).length;
  const counts = `P1:${p1count}  P2:${p2count}`;

  let who = `Player ${game.currentPlayer}`;
  if (mode === "vsai") {
    who = game.currentPlayer === 1 ? "You (P1)" : `AI (${difficulty})`;
  }

  const thinking = aiThinking ? "  [AI thinking...]" : "";
  text.setText(`Turn ${game.turn} — ${who} to move    ${counts}${thinking}`);
}

// ---------------------------------------------------------------------------
// Power menu
// ---------------------------------------------------------------------------

function renderPowerMenu(
  text: Phaser.GameObjects.Text,
  game: GameState,
  powerMode: ControllerState["powerMode"],
  ctrl: ControllerState,
): void {
  const sel = game.selected;
  if (!sel) {
    text.setText("");
    return;
  }
  const piece = game.pieces.find((p) => p.row === sel.row && p.col === sel.col);
  if (!piece || piece.powers.length === 0) {
    text.setText(
      "Powers\n──────\n(none)",
    );
    return;
  }

  // Build power menu text.
  const lines: string[] = ["Powers (click to use)", "──────────────────────"];

  // Group by unique power id with count.
  const seen = new Map<string, number>();
  for (const id of piece.powers) {
    seen.set(id, (seen.get(id) ?? 0) + 1);
  }

  let i = 1;
  for (const [id, count] of seen) {
    const def = definitions[id];
    const name = def?.name ?? id;
    const countStr = count > 1 ? ` ×${count}` : "";
    const active = powerMode?.powerId === id ? " ◀" : "";
    const overheat = count >= 7 ? " ⚠" : "";
    lines.push(`${i}. ${name}${countStr}${overheat}${active}`);
    i++;
  }

  if (powerMode) {
    lines.push("");
    lines.push("Click a purple tile");
    lines.push("or press Esc to cancel");
  }

  // Unused parameter warning guard.
  void ctrl;

  text.setText(lines.join("\n"));
}

// ---------------------------------------------------------------------------
// AI difficulty indicator
// ---------------------------------------------------------------------------

function renderAiIndicator(
  text: Phaser.GameObjects.Text,
  mode: string,
  difficulty: string,
  game: GameState,
  aiThinking: boolean,
): void {
  if (mode !== "vsai" || game.status === "won") {
    text.setText("");
    return;
  }
  const label = aiThinking ? `AI (${difficulty}) thinking...` : `vs AI — ${difficulty}`;
  text.setText(label);
}

// ---------------------------------------------------------------------------
// Win banner
// ---------------------------------------------------------------------------

function renderWinBanner(
  text: Phaser.GameObjects.Text,
  game: GameState,
): void {
  if (game.status !== "won" || game.winner === null) {
    text.setVisible(false);
    return;
  }
  text.setText(`Player ${game.winner} wins!  (turn ${game.turn})\n\nPress R to play again`);
  text.setVisible(true);
}
