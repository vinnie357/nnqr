// Pure game types — no framework dependencies. The single source of truth for
// the board state the renderer draws and the AI QA loop reads via window.NNQR.

export type Player = 1 | 2;

export interface Piece {
  id: string;
  player: Player;
  row: number;
  col: number;
  powers: string[];
}

export interface Move {
  row: number;
  col: number;
  capture: boolean;
}

export type GameStatus = "playing" | "won";

export interface GameState {
  cols: number;
  rows: number;
  pieces: Piece[];
  currentPlayer: Player;
  selected: { row: number; col: number } | null;
  validMoves: Move[];
  status: GameStatus;
  winner: Player | null;
  turn: number;
}
