# Quadradius Power Testing Guide

## Debug Controls
- **Number Keys 1-5**: Add Phase 2 powers to current player
- **Q, W, E, R, T**: Add movement powers  
- **A, S, D**: Add combat powers
- **Space**: Force power activation phase

## Phase 2 Powers (Core 5)

### 1. Move Diagonal (Press 1)
- **Expected**: Pieces can move diagonally (one square)
- **Test**: Add power, activate it, try to drag piece diagonally
- **Status**: WORKING ✓

### 2. Raise Column (Press 2)  
- **Expected**: Click on any column to raise all tiles by 1 height
- **Test**: Add power, activate it, click on a column
- **Status**: Visual effect only - needs terrain height implementation

### 3. Lower Column (Press 3)
- **Expected**: Click on any column to lower all tiles by 1 height  
- **Test**: Add power, activate it, click on a column
- **Status**: Visual effect only - needs terrain height implementation

### 4. Destroy Column (Press 4)
- **Expected**: Click on column to destroy it and all pieces on it
- **Test**: Add power, activate it, click on a column with pieces
- **Status**: WORKING ✓ (pieces are removed)

### 5. Multiply (Press 5)
- **Expected**: Click on your piece to create a copy on adjacent tile
- **Test**: Add power, activate it, click on one of your pieces
- **Status**: WORKING ✓

## Movement Powers (Phase 3)

### 6. Teleport (Press Q)
- **Expected**: Pieces can move to ANY empty square
- **Test**: Add power, activate it, try to move piece anywhere
- **Status**: Activates but movement validation needs update

### 7. Jump (Press W)  
- **Expected**: Pieces can jump over other pieces in straight lines
- **Test**: Add power, activate it, try to jump over a piece
- **Status**: Activates but movement validation needs update

### 8. Move Two (Press E)
- **Expected**: Pieces can move exactly 2 squares in one direction
- **Test**: Add power, activate it, try to move 2 squares
- **Status**: Activates but movement validation needs update

### 9. Knight (Press R)
- **Expected**: Pieces move in L-shape like chess knight
- **Test**: Add power, activate it, try L-shaped move
- **Status**: Activates but movement validation needs update

### 10. Slide (Press T)
- **Expected**: Pieces slide until they hit obstacle
- **Test**: Add power, activate it, move piece
- **Status**: Activates but movement logic needs implementation

## Combat Powers

### 11. Smart Bomb (Press A)
- **Expected**: Destroys pieces in 3x3 area
- **Test**: Add power, activate it, click on board area
- **Status**: Not implemented - needs area targeting

### 12. Freeze (Press S)  
- **Expected**: Target enemy piece cannot move next turn
- **Test**: Add power, activate it, click enemy piece
- **Status**: Shows message but needs targeting UI

### 13. Shield (Press D)
- **Expected**: Protects pieces from being captured
- **Test**: Add power, activate it
- **Status**: Not implemented

## Testing Process

1. Run the game: `cargo run`
2. Press number/letter key to add power to current player
3. Press Space to force power activation phase if needed
4. Click the power button in the UI
5. Follow the power's targeting requirements
6. Observe if the power works as expected

## Known Issues

1. Movement powers activate but don't modify piece movement rules yet
2. Area-effect powers need targeting UI implementation  
3. Terrain modification powers need height system implementation
4. Some powers need multi-turn state tracking (Freeze, Shield, etc.)