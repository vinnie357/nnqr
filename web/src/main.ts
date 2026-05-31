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
import { BOARD_COLS, BOARD_ROWS, createInitialState } from "./core/board";
import {
  GameController,
  type ControllerState,
  type GameMode,
} from "./game/controller";
import {
  createPauseOverlay,
  handleEscape,
  resume,
  type PauseOverlayState,
} from "./game/pause-overlay";
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
  /** nnqr-43: Group for per-tile dynamic reveal labels (cleared each frame). */
  private revealLabels!: Phaser.GameObjects.Group;

  // ---- Pause overlay state ----
  private pauseState: PauseOverlayState = createPauseOverlay();
  /** Semi-transparent dim rectangle drawn over the board when paused. */
  private pauseGfx!: Phaser.GameObjects.Graphics;
  /** Container holding the pause menu text objects. */
  private pauseContainer!: Phaser.GameObjects.Container;
  private pauseResumeBtn!: Phaser.GameObjects.Rectangle;
  private pauseQuitBtn!: Phaser.GameObjects.Rectangle;

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
    // nnqr-43: group for ephemeral per-tile reveal labels (cleared each renderFrame).
    this.revealLabels = this.add.group();

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

    // Win banner (centered). Hidden until a player wins — see renderWinBanner.
    const winText = this.add.text(MARGIN_LEFT + (BOARD_COLS * TILE) / 2, MARGIN_TOP + (BOARD_ROWS * TILE) / 2, "", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "28px",
      color: "#ffd633",
      align: "center",
      backgroundColor: "#111318",
      padding: { x: 20, y: 14 },
    }).setOrigin(0.5).setVisible(false);

    this.texts = {
      status: statusText,
      powerMenu: powerMenuText,
      aiIndicator: aiText,
      winBanner: winText,
    };

    // ---- Discoverable hint (always visible in-game) ----
    this.add.text(CANVAS_W - 10, 32, "Esc: pause / menu", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "11px",
      color: "#555577",
    }).setOrigin(1, 0);

    // ---- Pause overlay ----
    this.pauseGfx = this.add.graphics();
    this.pauseContainer = this.add.container(0, 0);

    const cx = CANVAS_W / 2;
    const cy = CANVAS_H / 2;

    // Backdrop card.
    const card = this.add.rectangle(cx, cy, 320, 200, 0x111318, 0.97)
      .setStrokeStyle(2, 0x6666aa);

    const title = this.add.text(cx, cy - 70, "⏸  Paused", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "22px",
      color: "#ffd633",
      fontStyle: "bold",
    }).setOrigin(0.5);

    // Resume button.
    this.pauseResumeBtn = this.add.rectangle(cx, cy - 12, 220, 40, 0x33384a)
      .setStrokeStyle(1, 0x6666aa)
      .setInteractive({ useHandCursor: true });
    const resumeLabel = this.add.text(cx, cy - 12, "Resume  (Esc / Enter)", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "15px",
      color: "#e6e8ee",
    }).setOrigin(0.5);

    // Quit button.
    this.pauseQuitBtn = this.add.rectangle(cx, cy + 42, 220, 40, 0x33384a)
      .setStrokeStyle(1, 0x6666aa)
      .setInteractive({ useHandCursor: true });
    const quitLabel = this.add.text(cx, cy + 42, "Quit to Title  (Q)", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "15px",
      color: "#e6e8ee",
    }).setOrigin(0.5);

    const hint = this.add.text(cx, cy + 82, "R also returns to title at any time", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "11px",
      color: "#444466",
    }).setOrigin(0.5);

    this.pauseContainer.add([card, title, this.pauseResumeBtn, resumeLabel, this.pauseQuitBtn, quitLabel, hint]);
    this.pauseContainer.setVisible(false);

    // Button interactions.
    this.pauseResumeBtn.on("pointerover", () => { this.pauseResumeBtn.setFillStyle(0x4a5070); });
    this.pauseResumeBtn.on("pointerout", () => { this.pauseResumeBtn.setFillStyle(0x33384a); });
    this.pauseResumeBtn.on("pointerdown", () => { this.applyResume(); });

    this.pauseQuitBtn.on("pointerover", () => { this.pauseQuitBtn.setFillStyle(0x4a5070); });
    this.pauseQuitBtn.on("pointerout", () => { this.pauseQuitBtn.setFillStyle(0x33384a); });
    this.pauseQuitBtn.on("pointerdown", () => { this.applyQuitToTitle(); });

    // Board click handler.
    this.input.on("pointerdown", (p: Phaser.Input.Pointer) => {
      // Suspend board input while paused (pause overlay handles its own clicks).
      if (this.pauseState.paused) return;

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
        const result = handleEscape(this.pauseState, this.ctrlState.powerMode !== null);
        if (result.action === "cancelPower") {
          this.controller.cancelPowerMode();
        } else {
          this.pauseState = result.next;
          this.updatePauseOverlay();
        }
        return;
      }
      // While paused, only Q (quit) and Enter (resume) are active.
      if (this.pauseState.paused) {
        if (event.key === "Enter") {
          this.applyResume();
        } else if (event.key === "q" || event.key === "Q") {
          this.applyQuitToTitle();
        }
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

  /** Resume from the pause overlay — restores the same game state exactly. */
  private applyResume(): void {
    this.pauseState = resume(this.pauseState);
    this.updatePauseOverlay();
  }

  /** Quit to title from the pause overlay. */
  private applyQuitToTitle(): void {
    this.pauseState = resume(this.pauseState);
    this.controller.destroy();
    this.scene.start("title");
  }

  /** Sync the pause overlay Phaser objects with the current pauseState. */
  private updatePauseOverlay(): void {
    const visible = this.pauseState.paused;
    this.pauseContainer.setVisible(visible);
    if (visible) {
      // Draw a semi-transparent dim over the full canvas.
      this.pauseGfx.clear();
      this.pauseGfx.fillStyle(0x000000, 0.55);
      this.pauseGfx.fillRect(0, 0, CANVAS_W, CANVAS_H);
    } else {
      this.pauseGfx.clear();
    }
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
      revealLabels: this.revealLabels,
    });
  }

  private exposeBridge(): void {
    window.NNQR = {
      version: "0.2.0",
      getState: () => structuredClone(this.ctrlState.game),
      isPaused: () => this.pauseState.paused,
      api: {
        select: (row: number, col: number) => {
          // Route through the controller so validMoves and all side-effects run.
          this.controller.handleTileClick(row, col);
          return structuredClone(this.ctrlState.game);
        },
        move: (row: number, col: number) => {
          // Route through the controller — triggers orb collection, overheat,
          // orb spawn, and scheduleAiTurn when in vs-AI mode.
          this.controller.handleTileClick(row, col);
          return structuredClone(this.ctrlState.game);
        },
        activatePower: (powerId: string, target?: { row: number; col: number }) => {
          // Activate the power via the controller's handler.
          this.controller.handlePowerActivation(powerId);
          // If a target is provided, complete targeting with a second tile click.
          if (target !== undefined) {
            this.controller.handleTileClick(target.row, target.col);
          }
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
          isPaused: () => false,
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
