# Quadradius Phase 1

## Status
Phase 1 is complete! Basic game mechanics are fully implemented.

## How to Play
1. Run the game: `cargo run`
2. **Left Click** - Select a piece (only current player's pieces can be selected)
3. **Right Click** - Move selected piece to an adjacent square
4. Movement rules:
   - Can only move horizontally or vertically (not diagonally)
   - Can move down any number of terrain levels
   - Can only move up ONE terrain level maximum
5. Capture enemy pieces by moving onto their square
6. Win by eliminating all opponent pieces

## Controls
- Left Mouse: Select piece
- Right Mouse: Move piece

## Features Implemented (Phase 1)
- ✓ 8x8 board with varied terrain heights (visual: green=low, yellow=medium)
- ✓ Player pieces (red vs blue) in checkerboard starting positions
- ✓ Piece selection with visual feedback (yellow highlight)
- ✓ Movement system with height restrictions
- ✓ Turn-based gameplay
- ✓ Piece capture mechanics
- ✓ Win condition detection

## Next Steps
Phase 2 will add the power-up system with the first 5 powers.