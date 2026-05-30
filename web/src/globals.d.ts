import type { Difficulty } from "./core/ai/ai";
import type { GameState } from "./core/types";
import type { GameMode } from "./game/controller";

// The QA bridge exposed on window for the AI see-loop (read state + drive inputs).
declare global {
  interface Window {
    NNQR?: {
      version: string;
      /** Returns a deep clone of the current game state. */
      getState: () => GameState;
      /** Returns true when the pause overlay is open (QA / see-loop use). */
      isPaused: () => boolean;
      api: {
        /**
         * Select the piece at (row, col) for the current player, or clear
         * selection if there is no own piece there.
         * Returns the new game state.
         */
        select: (row: number, col: number) => GameState;

        /**
         * Move the currently selected piece to (row, col) if it is a valid
         * move destination. Returns the new game state.
         */
        move: (row: number, col: number) => GameState;

        /**
         * Activate a power on the currently selected piece.
         * `target` is required for powers that need a target tile (raise_tile,
         * lower_tile, recruit, switcheroo, multiply, refurb, centerpult,
         * hotspot). Omit or pass undefined for immediate-effect powers.
         * Returns the new game state.
         */
        activatePower: (
          powerId: string,
          target?: { row: number; col: number },
        ) => GameState;

        /**
         * Start a new game with the given mode and difficulty.
         * mode: "hotseat" | "vsai"
         * difficulty: "easy" | "medium" | "hard" | "expert"
         * Returns the new initial game state.
         */
        newGame: (opts: { mode: GameMode; difficulty: Difficulty }) => GameState;

        /**
         * Return to the title screen.
         * Returns the current game state before resetting.
         */
        reset: () => GameState;
      };
    };
  }
}

export {};
