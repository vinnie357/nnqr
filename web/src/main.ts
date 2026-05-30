// Phaser renderer + input for the NNQR walking skeleton. All game rules live in
// src/core (framework-free); this file only draws state and translates clicks.
//
// It exposes `window.NNQR` so the AI QA loop can READ state
// (`browser_evaluate("window.NNQR.getState()")`) and DRIVE the game
// (`window.NNQR.api.select(r,c)` / `.move(r,c)`) deterministically, in addition
// to clicking the canvas.

import Phaser from "phaser";
import { BOARD_COLS, BOARD_ROWS, createInitialState, moveTo, selectPiece } from "./core/board";
import type { GameState } from "./core/types";

const TILE = 60;
const MARGIN = 40;
const BOARD_W = BOARD_COLS * TILE;
const BOARD_H = BOARD_ROWS * TILE;
const WIDTH = BOARD_W + MARGIN * 2;
const HEIGHT = BOARD_H + MARGIN * 2 + 40; // extra band for the status text

const COLORS = {
  bg: 0x1e2230,
  tileLight: 0x33384a,
  tileDark: 0x2a2f3e,
  p1: 0x4a8cf0,
  p2: 0xf05a5a,
  selected: 0xffd633,
  moveEmpty: 0x4ce06a,
  moveCapture: 0xf2802c,
};

class MainScene extends Phaser.Scene {
  private state: GameState = createInitialState();
  private gfx!: Phaser.GameObjects.Graphics;
  private pieceLayer!: Phaser.GameObjects.Container;
  private status!: Phaser.GameObjects.Text;

  constructor() {
    super("main");
  }

  create(): void {
    this.gfx = this.add.graphics();
    this.pieceLayer = this.add.container(0, 0);
    this.status = this.add.text(MARGIN, HEIGHT - 30, "", { fontFamily: "system-ui, sans-serif", fontSize: "18px", color: "#e6e8ee" });

    this.input.on("pointerdown", (p: Phaser.Input.Pointer) => {
      const col = Math.floor((p.x - MARGIN) / TILE) + 1;
      const row = Math.floor((p.y - MARGIN) / TILE) + 1;
      if (row < 1 || row > BOARD_ROWS || col < 1 || col > BOARD_COLS) return;
      this.handleTile(row, col);
    });

    this.exposeBridge();
    this.render();
  }

  /** A tile click either selects an own piece or executes a pending valid move. */
  private handleTile(row: number, col: number): void {
    const onValidMove = this.state.validMoves.some((m) => m.row === row && m.col === col);
    this.setState(onValidMove ? moveTo(this.state, row, col) : selectPiece(this.state, row, col));
  }

  private setState(next: GameState): void {
    this.state = next;
    this.render();
  }

  private tileXY(row: number, col: number): { x: number; y: number } {
    return { x: MARGIN + (col - 1) * TILE, y: MARGIN + (row - 1) * TILE };
  }

  private render(): void {
    const g = this.gfx;
    g.clear();
    this.pieceLayer.removeAll(true);

    // Board tiles (checkerboard).
    for (let row = 1; row <= BOARD_ROWS; row++) {
      for (let col = 1; col <= BOARD_COLS; col++) {
        const { x, y } = this.tileXY(row, col);
        g.fillStyle((row + col) % 2 === 0 ? COLORS.tileLight : COLORS.tileDark, 1);
        g.fillRect(x, y, TILE, TILE);
      }
    }

    // Selected tile outline.
    if (this.state.selected) {
      const { x, y } = this.tileXY(this.state.selected.row, this.state.selected.col);
      g.lineStyle(4, COLORS.selected, 1);
      g.strokeRect(x + 2, y + 2, TILE - 4, TILE - 4);
    }

    // Valid-move markers.
    for (const m of this.state.validMoves) {
      const { x, y } = this.tileXY(m.row, m.col);
      const cx = x + TILE / 2;
      const cy = y + TILE / 2;
      if (m.capture) {
        g.lineStyle(4, COLORS.moveCapture, 1);
        g.strokeCircle(cx, cy, TILE / 2 - 6);
      } else {
        g.fillStyle(COLORS.moveEmpty, 0.9);
        g.fillCircle(cx, cy, 8);
      }
    }

    // Pieces.
    for (const piece of this.state.pieces) {
      const { x, y } = this.tileXY(piece.row, piece.col);
      const dot = this.add.circle(x + TILE / 2, y + TILE / 2, TILE / 2 - 10, piece.player === 1 ? COLORS.p1 : COLORS.p2);
      dot.setStrokeStyle(2, 0x000000, 0.35);
      this.pieceLayer.add(dot);
    }

    this.status.setText(this.statusText());
  }

  private statusText(): string {
    if (this.state.status === "won") return `Player ${this.state.winner} wins!  (turn ${this.state.turn})`;
    const counts = `P1:${this.state.pieces.filter((p) => p.player === 1).length} P2:${this.state.pieces.filter((p) => p.player === 2).length}`;
    return `Turn ${this.state.turn} — Player ${this.state.currentPlayer} to move    ${counts}`;
  }

  /** Expose a stable bridge for the AI QA loop to read state and drive inputs. */
  private exposeBridge(): void {
    window.NNQR = {
      version: "0.1.0",
      getState: () => structuredClone(this.state),
      api: {
        select: (row: number, col: number) => {
          this.setState(selectPiece(this.state, row, col));
          return structuredClone(this.state);
        },
        move: (row: number, col: number) => {
          this.setState(moveTo(this.state, row, col));
          return structuredClone(this.state);
        },
        reset: () => {
          this.setState(createInitialState());
          return structuredClone(this.state);
        },
      },
    };
  }
}

new Phaser.Game({
  type: Phaser.AUTO,
  parent: "app",
  width: WIDTH,
  height: HEIGHT,
  backgroundColor: COLORS.bg,
  scene: [MainScene],
});
