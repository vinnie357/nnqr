// Entry point — creates the Phaser game, orchestrates the title → play flow,
// and exposes `window.NNQR` for the AI QA see-loop.
//
// Architecture:
//   TitleScene  — game-mode / difficulty selection
//   MainScene   — board rendering + input forwarding to GameController
//   GameController (src/game/controller.ts) — pure game-flow state machine
//   Renderer    (src/game/renderer.ts)       — stateless draw pass

import Phaser from "phaser";
import type { Difficulty } from "./core/ai/ai";
import { BOARD_COLS, BOARD_ROWS, createInitialState, selectPiece, moveTo } from "./core/board";
import { execute } from "./core/powers/executor";
import {
  GameController,
  type ControllerState,
  type GameMode,
} from "./game/controller";
import {
  CANVAS_W,
  CANVAS_H,
  MARGIN_LEFT,
  MARGIN_TOP,
  POWER_MENU_X,
  POWER_MENU_W,
  TILE,
  renderFrame,
  type RenderTargets,
} from "./game/renderer";

// ---------------------------------------------------------------------------
// Main (play) scene
// ---------------------------------------------------------------------------

class MainScene extends Phaser.Scene {
  private controller!: GameController;
  private gfx!: Phaser.GameObjects.Graphics;
  private texts!: RenderTargets["texts"];
  private ctrlState!: ControllerState;

  constructor() {
    super("main");
  }

  init(data: { mode: GameMode; difficulty: Difficulty }): void {
    // Build initial game state.
    const game = createInitialState(Date.now() & 0xffffffff);
    this.controller = new GameController(
      game,
      data.mode,
      data.difficulty,
      (next) => {
        this.ctrlState = next;
        this.render();
      },
    );
    this.ctrlState = this.controller.getState();
  }

  create(): void {
    this.gfx = this.add.graphics();

    const textStyle = {
      fontFamily: "'Courier New', monospace",
      fontSize: "13px",
      color: "#e6e8ee",
    };
    const smallStyle = {
      fontFamily: "system-ui, sans-serif",
      fontSize: "12px",
      color: "#44aaff",
    };

    // Status bar at top.
    const statusText = this.add.text(MARGIN_LEFT, 10, "", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "15px",
      color: "#e6e8ee",
    });

    // Power menu to the right of the board.
    const powerMenuText = this.add.text(POWER_MENU_X, MARGIN_TOP, "", {
      ...textStyle,
      wordWrap: { width: POWER_MENU_W },
    });

    // AI indicator (top-right).
    const aiText = this.add.text(CANVAS_W - 10, 10, "", {
      ...smallStyle,
    }).setOrigin(1, 0);

    // Win banner (centered).
    const winText = this.add.text(MARGIN_LEFT + (BOARD_COLS * TILE) / 2, MARGIN_TOP + (BOARD_ROWS * TILE) / 2, "", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "28px",
      color: "#ffd633",
      align: "center",
      backgroundColor: "#111318",
      padding: { x: 20, y: 14 },
    }).setOrigin(0.5);

    this.texts = {
      status: statusText,
      powerMenu: powerMenuText,
      aiIndicator: aiText,
      winBanner: winText,
    };

    // Board click handler.
    this.input.on("pointerdown", (p: Phaser.Input.Pointer) => {
      const col = Math.floor((p.x - MARGIN_LEFT) / TILE) + 1;
      const row = Math.floor((p.y - MARGIN_TOP) / TILE) + 1;
      if (row >= 1 && row <= BOARD_ROWS && col >= 1 && col <= BOARD_COLS) {
        this.controller.handleTileClick(row, col);
        return;
      }

      // Power menu click: check if within menu bounds.
      if (p.x >= POWER_MENU_X && p.x <= POWER_MENU_X + POWER_MENU_W) {
        this.handlePowerMenuClick(p.y);
      }
    });

    // Keyboard input.
    this.input.keyboard?.on("keydown", (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        this.controller.cancelPowerMode();
        return;
      }
      if (event.key === "r" || event.key === "R") {
        // New game — go back to title.
        this.controller.destroy();
        this.scene.start("title");
        return;
      }
      // Number keys 1-9 to activate powers.
      const n = parseInt(event.key, 10);
      if (!isNaN(n) && n >= 1 && n <= 9) {
        this.activatePowerByIndex(n - 1);
      }
    });

    this.exposeBridge();
    this.render();
  }

  private handlePowerMenuClick(y: number): void {
    const { game } = this.ctrlState;
    const sel = game.selected;
    if (!sel) return;
    const piece = game.pieces.find((p) => p.row === sel.row && p.col === sel.col);
    if (!piece || piece.powers.length === 0) return;

    // Unique powers list (matching rendering order).
    const seen = new Map<string, number>();
    const uniquePowers: string[] = [];
    for (const id of piece.powers) {
      if (!seen.has(id)) {
        uniquePowers.push(id);
      }
      seen.set(id, (seen.get(id) ?? 0) + 1);
    }

    // Power menu starts at MARGIN_TOP, each item is ~20px in text.
    // The text object is at MARGIN_TOP, with 2 header lines.
    const headerLines = 2;
    const lineH = 18; // approximate line height for 13px text
    const menuStart = MARGIN_TOP + headerLines * lineH;
    const idx = Math.floor((y - menuStart) / lineH);
    if (idx >= 0 && idx < uniquePowers.length) {
      this.controller.handlePowerActivation(uniquePowers[idx]!);
    }
  }

  private activatePowerByIndex(idx: number): void {
    const { game } = this.ctrlState;
    const sel = game.selected;
    if (!sel) return;
    const piece = game.pieces.find((p) => p.row === sel.row && p.col === sel.col);
    if (!piece) return;

    // Build unique power list.
    const seen = new Set<string>();
    const uniquePowers: string[] = [];
    for (const id of piece.powers) {
      if (!seen.has(id)) {
        uniquePowers.push(id);
        seen.add(id);
      }
    }

    const powerId = uniquePowers[idx];
    if (powerId) {
      this.controller.handlePowerActivation(powerId);
    }
  }

  private render(): void {
    renderFrame(this.ctrlState, {
      gfx: this.gfx,
      scene: this,
      texts: this.texts,
    });
  }

  private exposeBridge(): void {
    window.NNQR = {
      version: "0.2.0",
      getState: () => structuredClone(this.ctrlState.game),
      api: {
        select: (row: number, col: number) => {
          const next = selectPiece(this.ctrlState.game, row, col);
          this.controller["state"] = { ...this.ctrlState, game: next };
          this.ctrlState = this.controller.getState();
          this.render();
          return structuredClone(this.ctrlState.game);
        },
        move: (row: number, col: number) => {
          const next = moveTo(this.ctrlState.game, row, col);
          this.controller["state"] = { ...this.ctrlState, game: next };
          this.ctrlState = this.controller.getState();
          this.render();
          return structuredClone(this.ctrlState.game);
        },
        activatePower: (powerId: string, target?: { row: number; col: number }) => {
          const { game } = this.ctrlState;
          const sel = game.selected;
          if (!sel) return structuredClone(game);
          const piece = game.pieces.find((p) => p.row === sel.row && p.col === sel.col);
          if (!piece) return structuredClone(game);
          const next = execute(game, piece, powerId, target);
          this.controller["state"] = { ...this.ctrlState, game: next };
          this.ctrlState = this.controller.getState();
          this.render();
          return structuredClone(this.ctrlState.game);
        },
        newGame: (opts: { mode: GameMode; difficulty: Difficulty }) => {
          this.controller.destroy();
          this.scene.restart({ mode: opts.mode, difficulty: opts.difficulty });
          return structuredClone(this.ctrlState.game);
        },
        reset: () => {
          this.controller.destroy();
          this.scene.start("title");
          return structuredClone(this.ctrlState.game);
        },
      },
    };
  }

  shutdown(): void {
    this.controller.destroy();
  }
}

// ---------------------------------------------------------------------------
// Phaser game bootstrap
// ---------------------------------------------------------------------------

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: "app",
  width: CANVAS_W,
  height: CANVAS_H,
  backgroundColor: 0x1e2230,
  scene: [
    // The TitleScene is injected dynamically below.
    // We construct a config object for the title scene.
    {
      key: "title",
      create(this: Phaser.Scene) {
        // We need to forward the choice to the main scene. Use a nested class
        // since Phaser scene configs don't accept constructor args directly.
        const W = this.scale.width;
        const H = this.scale.height;
        const cx = W / 2;
        const scene = this;

        // Background.
        this.add.rectangle(cx, H / 2, W, H, 0x1e2230);

        // Title text.
        this.add.text(cx, 80, "NNQR", {
          fontFamily: "system-ui, sans-serif",
          fontSize: "52px",
          color: "#ffd633",
          fontStyle: "bold",
        }).setOrigin(0.5);

        this.add.text(cx, 140, "Not Not Quadradius", {
          fontFamily: "system-ui, sans-serif",
          fontSize: "18px",
          color: "#9999cc",
        }).setOrigin(0.5);

        this.add.text(cx, 165, "10×8 board · 82 powers", {
          fontFamily: "system-ui, sans-serif",
          fontSize: "13px",
          color: "#666688",
        }).setOrigin(0.5);

        type MenuItem = { label: string; mode: GameMode; difficulty: Difficulty };
        const items: MenuItem[] = [
          { label: "2 Player (Hotseat)", mode: "hotseat", difficulty: "easy" },
          { label: "vs AI — Easy",       mode: "vsai",    difficulty: "easy" },
          { label: "vs AI — Medium",     mode: "vsai",    difficulty: "medium" },
          { label: "vs AI — Hard",       mode: "vsai",    difficulty: "hard" },
          { label: "vs AI — Expert",     mode: "vsai",    difficulty: "expert" },
        ];

        let selected = 0;

        const buttons: Phaser.GameObjects.Rectangle[] = [];
        const labels: Phaser.GameObjects.Text[] = [];

        function refresh() {
          for (let i = 0; i < items.length; i++) {
            const isSelected = i === selected;
            buttons[i]?.setFillStyle(isSelected ? 0x4a5070 : 0x33384a);
            labels[i]?.setColor(isSelected ? "#ffd633" : "#e6e8ee");
          }
        }

        function launch(i: number) {
          const item = items[i];
          if (!item) return;
          scene.scene.start("main", { mode: item.mode, difficulty: item.difficulty });
        }

        for (let i = 0; i < items.length; i++) {
          const item = items[i]!;
          const by = 260 + i * 52;
          const btn = scene.add
            .rectangle(cx, by, 300, 42, i === 0 ? 0x4a5070 : 0x33384a)
            .setStrokeStyle(1, 0x6666aa)
            .setInteractive({ useHandCursor: true });
          buttons.push(btn);

          const lbl = scene.add
            .text(cx, by, item.label, {
              fontFamily: "system-ui, sans-serif",
              fontSize: "17px",
              color: i === 0 ? "#ffd633" : "#e6e8ee",
            })
            .setOrigin(0.5);
          labels.push(lbl);

          // Capture loop variable.
          const idx = i;
          btn.on("pointerover", () => { selected = idx; refresh(); });
          btn.on("pointerdown", () => launch(idx));
        }

        scene.add.text(cx, 540, "↑↓ to select · Enter/Space to confirm · R to restart during game", {
          fontFamily: "system-ui, sans-serif",
          fontSize: "12px",
          color: "#444466",
        }).setOrigin(0.5);

        scene.input.keyboard?.on("keydown", (event: KeyboardEvent) => {
          if (event.key === "ArrowUp" || event.key === "w") {
            selected = (selected - 1 + items.length) % items.length;
            refresh();
          } else if (event.key === "ArrowDown" || event.key === "s") {
            selected = (selected + 1) % items.length;
            refresh();
          } else if (event.key === "Enter" || event.key === " ") {
            launch(selected);
          }
        });

        // Expose bridge for newGame API before main scene starts.
        window.NNQR = {
          version: "0.2.0",
          getState: () => createInitialState(),
          api: {
            select: (_r: number, _c: number) => createInitialState(),
            move: (_r: number, _c: number) => createInitialState(),
            activatePower: (_id: string, _t?: { row: number; col: number }) => createInitialState(),
            newGame: (opts: { mode: GameMode; difficulty: Difficulty }) => {
              scene.scene.start("main", { mode: opts.mode, difficulty: opts.difficulty });
              return createInitialState();
            },
            reset: () => {
              scene.scene.start("title");
              return createInitialState();
            },
          },
        };
      },
    } as Phaser.Types.Scenes.CreateSceneFromObjectConfig,
    MainScene,
  ],
});

// Suppress the unused variable warning from the Phaser.Game constructor.
void game;

// ---------------------------------------------------------------------------
// Extend globals.d.ts surface (see globals.d.ts for the type declaration).
// The bridge is set by each scene; here we just ensure the type is consistent.
// ---------------------------------------------------------------------------

// Re-export nothing — types live in globals.d.ts.
export {};
