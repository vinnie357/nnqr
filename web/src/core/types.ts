// Pure game types — no framework dependencies. The single source of truth for
// the board state the renderer draws and the AI QA loop reads via window.NNQR.
// This is the contract the powers/ and ai/ modules build against.

export type Player = 1 | 2;

export interface Piece {
  id: string;
  player: Player;
  row: number;
  col: number;
  /** Power orbs collected, by power id (an inventory; may hold duplicates). */
  powers: string[];
  // Flags set by activating permanent powers (read by movement/capture rules).
  isJumpProof?: boolean;
  canMoveDiagonally?: boolean;
  canClimbAny?: boolean;
  canWrap?: boolean;
  isInvisible?: boolean;
  // Flags set by debuff / control powers — consumed by board.ts and orbs.ts.
  /** Set by scavenger power: this piece inherits powers from enemies it captures. */
  isScavenger?: boolean;
  /** Set by beneficiary power: allied pieces' powers transfer here on death. */
  isBeneficiary?: boolean;
  /** Set by tripwire power: this piece is removed from the board when it moves. */
  isTripwired?: boolean;
  /** Set by inhibit power: this piece cannot collect orb powers. */
  isInhibited?: boolean;
  /** Set by parasite power: orb powers collected by this piece go to the named piece id instead. */
  parasitizedBy?: string;
}

export interface Move {
  row: number;
  col: number;
  capture: boolean;
}

/** A power orb sitting on the board, collected when a piece lands on it. */
export interface Orb {
  row: number;
  col: number;
  powerId: string;
}

export type GameStatus = "playing" | "won";

export interface GameState {
  cols: number;
  rows: number;
  pieces: Piece[];
  /** Terrain height per tile, heightMap[row-1][col-1], range 0..4. */
  heightMap: number[][];
  /** Destroyed (impassable) tiles keyed "row,col". */
  destroyedTiles: Record<string, true>;
  orbs: Orb[];
  currentPlayer: Player;
  selected: { row: number; col: number } | null;
  validMoves: Move[];
  status: GameStatus;
  winner: Player | null;
  turn: number;
  /** Seed for deterministic RNG (orb spawning, AI tie-breaks). */
  seed: number;
}

export const tileKey = (row: number, col: number): string => `${row},${col}`;
