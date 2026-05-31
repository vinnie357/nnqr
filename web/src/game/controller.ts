// Game controller — manages game state transitions for both hotseat and vs-AI modes.
// Pure game-flow logic; no Phaser imports. Takes a setState callback that the
// scene calls to re-render whenever state changes.

import { chooseMove, type Difficulty } from "../core/ai/ai";
import { checkWinner, moveTo, selectPiece } from "../core/board";
import { POWER_IDS } from "../core/powers/definitions";
import { execute } from "../core/powers/executor";
import { getTargetTiles, needsTarget, overheatPower } from "../core/powers/targets";
import { makeRng } from "../core/rng";
import { collectOrb, shouldSpawnOrbs, spawnOrbs } from "../core/orbs";
import type { GameState, Piece, Player } from "../core/types";

export type GameMode = "hotseat" | "vsai";

export interface PowerMode {
  piece: Piece;
  powerId: string;
  targetTiles: ReadonlyArray<{ row: number; col: number }>;
}

export interface ControllerState {
  game: GameState;
  mode: GameMode;
  aiPlayer: Player;
  difficulty: Difficulty;
  /** Non-null while waiting for the player to click a target for a power. */
  powerMode: PowerMode | null;
  /** True while the AI is "thinking" (brief delay). */
  aiThinking: boolean;
}

type OnChange = (state: ControllerState) => void;

export class GameController {
  private state: ControllerState;
  private onChange: OnChange;
  private aiTimer: ReturnType<typeof setTimeout> | null = null;

  constructor(
    initialGame: GameState,
    mode: GameMode,
    difficulty: Difficulty,
    onChange: OnChange,
  ) {
    this.state = {
      game: initialGame,
      mode,
      aiPlayer: 2,
      difficulty,
      powerMode: null,
      aiThinking: false,
    };
    this.onChange = onChange;
  }

  getState(): ControllerState {
    return this.state;
  }

  private set(next: Partial<ControllerState>): void {
    this.state = { ...this.state, ...next };
    this.onChange(this.state);
  }

  private setGame(game: GameState): void {
    this.set({ game });
  }

  /** Called by input when a board tile is clicked. */
  handleTileClick(row: number, col: number): void {
    const { game, powerMode, aiThinking } = this.state;

    // Block input during AI thinking or game over.
    if (aiThinking || game.status === "won") return;

    // If in AI mode and it's the AI's turn, ignore human clicks on the board.
    if (this.state.mode === "vsai" && game.currentPlayer === this.state.aiPlayer) return;

    if (powerMode) {
      // In targeting mode: check if this tile is a valid target.
      const valid = powerMode.targetTiles.find((t) => t.row === row && t.col === col);
      if (valid) {
        this.executePower(powerMode.piece, powerMode.powerId, { row, col });
      } else {
        // Cancel power targeting.
        this.set({ powerMode: null });
      }
      return;
    }

    // Normal tile click: move or select.
    const onValidMove = game.validMoves.some((m) => m.row === row && m.col === col);
    if (onValidMove) {
      this.applyMove(row, col);
    } else {
      this.setGame(selectPiece(game, row, col));
    }
  }

  /** Called by input when a power is activated from the power menu. */
  handlePowerActivation(powerId: string): void {
    const { game, aiThinking, powerMode } = this.state;
    if (aiThinking || game.status === "won") return;
    if (this.state.mode === "vsai" && game.currentPlayer === this.state.aiPlayer) return;

    // Cancel existing power mode if clicking the same power.
    if (powerMode?.powerId === powerId) {
      this.set({ powerMode: null });
      return;
    }

    const sel = game.selected;
    if (!sel) return;
    const piece = game.pieces.find((p) => p.row === sel.row && p.col === sel.col);
    if (!piece || !piece.powers.includes(powerId)) return;

    if (needsTarget(powerId)) {
      const targetTiles = getTargetTiles(game, piece, powerId);
      if (targetTiles.length === 0) {
        // No valid targets — cannot activate.
        return;
      }
      this.set({ powerMode: { piece, powerId, targetTiles } });
    } else {
      this.executePower(piece, powerId, undefined);
    }
  }

  /** Cancel targeting mode (e.g. Escape). */
  cancelPowerMode(): void {
    this.set({ powerMode: null });
  }

  private executePower(piece: Piece, powerId: string, target: { row: number; col: number } | undefined): void {
    const { game } = this.state;

    // Re-resolve the piece from current state (it may have moved/changed).
    const livePiece = game.pieces.find((p) => p.id === piece.id);
    if (!livePiece) {
      this.set({ powerMode: null });
      return;
    }

    const nextGame = execute(game, livePiece, powerId, target);
    this.set({ powerMode: null, game: nextGame });
  }

  private applyMove(row: number, col: number): void {
    const { game } = this.state;
    if (!game.selected) return;

    // Apply the move.
    let next = moveTo(game, row, col);

    // Collect orb at destination.
    const movingPieceId = game.pieces.find(
      (p) => p.row === game.selected!.row && p.col === game.selected!.col,
    )?.id;

    if (movingPieceId) {
      const { state: afterOrb, collected } = collectOrb(next, row, col);
      if (collected) {
        next = afterOrb;
        // Check overheat: ≥10 of same power destroys the piece.
        const movedPiece = next.pieces.find((p) => p.id === movingPieceId);
        if (movedPiece) {
          const overheatId = overheatPower(movedPiece);
          if (overheatId) {
            next = {
              ...next,
              pieces: next.pieces.filter((p) => p.id !== movingPieceId),
            };
          }
        }
      }
    }

    // After turn boundary, maybe spawn orbs.
    if (shouldSpawnOrbs(next.turn)) {
      next = spawnOrbs(next, POWER_IDS, makeRng(next.seed + next.turn));
    }

    this.setGame(next);

    // Trigger AI turn if applicable.
    if (
      this.state.mode === "vsai" &&
      next.status === "playing" &&
      next.currentPlayer === this.state.aiPlayer
    ) {
      this.scheduleAiTurn();
    }
  }

  private scheduleAiTurn(): void {
    this.set({ aiThinking: true });
    this.aiTimer = setTimeout(() => {
      this.aiTimer = null;
      this.runAiTurn();
    }, 450);
  }

  /**
   * Run the AI turn synchronously (no scheduling delay). Exposed for the scene
   * and for tests that need to drive a full AI turn deterministically.
   */
  runAiTurnNow(): void {
    this.runAiTurn();
  }

  private runAiTurn(): void {
    const { game, aiPlayer, difficulty } = this.state;
    if (game.status !== "playing" || game.currentPlayer !== aiPlayer) {
      this.set({ aiThinking: false });
      return;
    }

    const rng = makeRng(game.seed + game.turn);
    const decision = chooseMove(game, aiPlayer, difficulty, rng);

    if (!decision) {
      this.set({ aiThinking: false });
      return;
    }

    // Power activation: the AI chose to activate a power rather than move.
    // Apply it through the real executor so the effect reaches the board.
    if (decision.powerId !== undefined) {
      this.applyAiPower(decision.piece, decision.powerId);
      return;
    }

    // Normal move path — decision.move is guaranteed present when powerId is absent.
    const move = decision.move!;

    // Reselect the piece (updates validMoves in state).
    let next = selectPiece(game, decision.piece.row, decision.piece.col);
    this.state = { ...this.state, game: next };

    // Apply the move.
    next = moveTo(next, move.row, move.col);

    // Collect orb.
    const movedPiece = next.pieces.find((p) => p.id === decision.piece.id);
    if (movedPiece) {
      const { state: afterOrb, collected } = collectOrb(next, move.row, move.col);
      if (collected) {
        next = afterOrb;
        const updatedPiece = next.pieces.find((p) => p.id === decision.piece.id);
        if (updatedPiece) {
          const overheatId = overheatPower(updatedPiece);
          if (overheatId) {
            next = {
              ...next,
              pieces: next.pieces.filter((p) => p.id !== decision.piece.id),
            };
          }
        }
      }
    }

    // Spawn orbs on turn boundary.
    if (shouldSpawnOrbs(next.turn)) {
      next = spawnOrbs(next, POWER_IDS, makeRng(next.seed + next.turn));
    }

    this.set({ game: next, aiThinking: false });
  }

  /**
   * Apply an AI-chosen power activation through the real executor, then advance
   * the turn the same way the normal move path does: flip to the human player,
   * re-check the winner, spawn orbs on the turn boundary, and clear aiThinking.
   *
   * Mirrors the structure of the normal move branch and `executePower`.
   */
  private applyAiPower(piece: Piece, powerId: string): void {
    const { game } = this.state;

    // Re-resolve the live piece by id (it must still be on the board).
    const livePiece = game.pieces.find((p) => p.id === piece.id);
    if (!livePiece) {
      this.set({ aiThinking: false });
      return;
    }

    // Resolve a target if this power requires one. The AI's offensive line/area
    // powers (destroy_row, destroy_column, bomb, radial, …) are self-targeted
    // and take no target; targeted powers (recruit, switcheroo, …) need a tile.
    let target: { row: number; col: number } | undefined;
    if (needsTarget(powerId)) {
      const tiles = getTargetTiles(game, livePiece, powerId);
      if (tiles.length === 0) {
        // No valid target — abort the activation and end the turn safely.
        this.set({ aiThinking: false });
        return;
      }
      // Pick the highest-value target: prefer a tile occupied by an enemy piece,
      // else the first valid tile. (Targeted AI powers are rare today; this keeps
      // the choice deterministic and reasonable.)
      const best =
        tiles.find((t) =>
          game.pieces.some(
            (p) => p.row === t.row && p.col === t.col && p.player !== livePiece.player,
          ),
        ) ?? tiles[0]!;
      target = { row: best.row, col: best.col };
    }

    // Execute the power (pure — returns new state with the effect + power consumed).
    let next = execute(game, livePiece, powerId, target);

    // Advance the turn: flip to the opponent and bump the turn counter.
    next = {
      ...next,
      selected: null,
      validMoves: [],
      currentPlayer: next.currentPlayer === 1 ? 2 : 1,
      turn: next.turn + 1,
    };

    // Re-check the winner after the power may have removed pieces.
    const winner = checkWinner(next);
    if (winner) {
      next = { ...next, status: "won", winner };
    }

    // Spawn orbs on the turn boundary, mirroring the move path.
    if (next.status === "playing" && shouldSpawnOrbs(next.turn)) {
      next = spawnOrbs(next, POWER_IDS, makeRng(next.seed + next.turn));
    }

    this.set({ game: next, aiThinking: false });
  }

  destroy(): void {
    if (this.aiTimer !== null) {
      clearTimeout(this.aiTimer);
      this.aiTimer = null;
    }
  }
}
