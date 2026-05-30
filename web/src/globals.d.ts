import type { GameState } from "./core/types";

// The QA bridge exposed on window for the AI see-loop (read state + drive inputs).
declare global {
  interface Window {
    NNQR?: {
      version: string;
      getState: () => GameState;
      api: {
        select: (row: number, col: number) => GameState;
        move: (row: number, col: number) => GameState;
        reset: () => GameState;
      };
    };
  }
}

export {};
