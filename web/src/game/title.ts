// Title scene — game mode selection screen shown before the main game.
// Player chooses: "2 Player (Hotseat)" or "vs AI" with difficulty selection.

import Phaser from "phaser";
import type { Difficulty } from "../core/ai/ai";
import type { GameMode } from "./controller";

export interface TitleChoice {
  mode: GameMode;
  difficulty: Difficulty;
}

type OnChoice = (choice: TitleChoice) => void;

const C = {
  bg: 0x1e2230,
  title: 0xffd633,
  subtitle: 0x9999cc,
  menuText: 0xe6e8ee,
  menuHover: 0xffd633,
  menuBg: 0x2a2f44,
  menuBorder: 0x4a4f66,
  button: 0x33384a,
  buttonHover: 0x4a5070,
  buttonBorder: 0x6666aa,
};

interface MenuItem {
  label: string;
  y: number;
  action: () => void;
}

export class TitleScene extends Phaser.Scene {
  private onChoice: OnChoice;
  private items: MenuItem[] = [];
  private selected = 0;

  constructor(onChoice: OnChoice) {
    super("title");
    this.onChoice = onChoice;
  }

  create(): void {
    const W = this.scale.width;
    const H = this.scale.height;
    const cx = W / 2;

    // Background.
    this.add.rectangle(cx, H / 2, W, H, C.bg);

    // Title.
    this.add.text(cx, 80, "NNQR", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "52px",
      color: "#ffd633",
      fontStyle: "bold",
    }).setOrigin(0.5);

    this.add.text(cx, 138, "Not Not Quadradius", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "18px",
      color: "#9999cc",
    }).setOrigin(0.5);

    this.add.text(cx, 165, "10×8 board · 82 powers", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "13px",
      color: "#666688",
    }).setOrigin(0.5);

    this.buildMainMenu();
  }

  private clearMenu(): void {
    // We rebuild from scratch each time — destroy existing menu objects.
    // In Phaser, the cleanest way is to destroy/recreate the whole scene's
    // relevant objects. We tag menu items with setName("menu") and destroy them.
    this.children.list
      .filter((c) => c.name === "menu")
      .forEach((c) => c.destroy());
    this.items = [];
    this.selected = 0;
  }

  private buildMainMenu(): void {
    this.clearMenu();

    const W = this.scale.width;
    const cx = W / 2;

    const addItem = (label: string, y: number, action: () => void): void => {
      this.items.push({ label, y, action });
    };

    addItem("2 Player (Hotseat)", 260, () => {
      this.onChoice({ mode: "hotseat", difficulty: "easy" });
    });
    addItem("vs AI — Easy", 310, () => {
      this.onChoice({ mode: "vsai", difficulty: "easy" });
    });
    addItem("vs AI — Medium", 360, () => {
      this.onChoice({ mode: "vsai", difficulty: "medium" });
    });
    addItem("vs AI — Hard", 410, () => {
      this.onChoice({ mode: "vsai", difficulty: "hard" });
    });
    addItem("vs AI — Expert", 460, () => {
      this.onChoice({ mode: "vsai", difficulty: "expert" });
    });

    for (let i = 0; i < this.items.length; i++) {
      const item = this.items[i]!;
      const isSelected = i === this.selected;
      const textColor = isSelected ? "#ffd633" : "#e6e8ee";
      const bg = this.add.rectangle(cx, item.y, 300, 38, isSelected ? C.buttonHover : C.button, 1)
        .setName("menu")
        .setStrokeStyle(1, C.buttonBorder)
        .setInteractive({ useHandCursor: true })
        .on("pointerover", () => {
          this.selected = i;
          this.buildMainMenu();
        })
        .on("pointerdown", () => {
          item.action();
        });
      void bg;

      this.add.text(cx, item.y, item.label, {
        fontFamily: "system-ui, sans-serif",
        fontSize: "17px",
        color: textColor,
      }).setOrigin(0.5).setName("menu");
    }

    // Controls hint.
    this.add.text(cx, 530, "↑↓ to select, Enter to confirm, R to restart during game", {
      fontFamily: "system-ui, sans-serif",
      fontSize: "12px",
      color: "#555577",
    }).setOrigin(0.5).setName("menu");

    // Keyboard: up/down/enter.
    this.input.keyboard?.removeAllListeners();
    this.input.keyboard?.on("keydown", (event: KeyboardEvent) => {
      if (event.key === "ArrowUp" || event.key === "w") {
        this.selected = (this.selected - 1 + this.items.length) % this.items.length;
        this.buildMainMenu();
      } else if (event.key === "ArrowDown" || event.key === "s") {
        this.selected = (this.selected + 1) % this.items.length;
        this.buildMainMenu();
      } else if (event.key === "Enter" || event.key === " ") {
        this.items[this.selected]?.action();
      }
    });
  }
}
