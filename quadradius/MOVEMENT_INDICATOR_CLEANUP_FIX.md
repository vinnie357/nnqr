# Movement Indicator Cleanup Fix

## Problem Identified
Movement indicators in the 3D system were not properly cleaning up after piece moves, causing them to remain visible on the board even after:
1. A piece was moved to a new position
2. Turn phase changed from PieceMovement to PowerSpawning  
3. A piece was deselected

## Root Cause Analysis
The issue was in the cleanup logic across multiple systems:

1. **`show_valid_moves_for_powers_3d`** - Was spawning indicators but not checking turn phase properly
2. **`cleanup_indicators_3d`** - Only cleaned up when no pieces were dragging, but ignored selection state
3. **Missing cleanup** - No system to clean up indicators when turn phase changes

## Files Modified

### 1. `/src/systems/enhanced_move_indicators_3d.rs`
- **Added GameState parameter** to `show_valid_moves_for_powers_3d` system
- **Added turn phase check** - Only spawn indicators during `TurnPhase::PieceMovement`
- **Added new system** `cleanup_orphaned_indicators_3d` to handle orphaned indicators
- **Fixed imports** - Added `GameState` and `TurnPhase` imports

### 2. `/src/systems/drag_drop_3d.rs`  
- **Enhanced `cleanup_indicators_3d`** to also check for selected pieces
- **Improved logic** - Now cleans up when no pieces are dragging AND no pieces are selected
- **Added logging** for better debugging

### 3. `/src/main.rs`
- **Added new cleanup system** `cleanup_orphaned_indicators_3d` to the update loop
- **Proper ordering** - Runs after the indicator spawning system

## Key Improvements

### 1. Turn Phase Awareness
```rust
// Only show indicators during piece movement phase
if game_state.turn_phase != TurnPhase::PieceMovement {
    return;
}
```

### 2. Comprehensive Cleanup Logic
```rust
// Clean up if no pieces are dragging AND no pieces are selected
let no_dragging = dragging.is_empty();
let no_selected = selected_pieces.is_empty() && selected_pieces_2d.is_empty();

if no_dragging && no_selected {
    // Clean up indicators
}
```

### 3. Orphaned Indicator Detection
```rust
// Clean up indicators when turn phase changes or no selection
let has_selected_pieces = !selected_2d_pieces.is_empty() || !selected_3d_pieces.is_empty();
let in_movement_phase = game_state.turn_phase == TurnPhase::PieceMovement;

if !has_selected_pieces || !in_movement_phase {
    // Clean up orphaned indicators
}
```

## System Flow After Fix

1. **Piece Selection** → Indicators spawn (only in PieceMovement phase)
2. **Piece Move** → Turn advances to PowerSpawning → Indicators clean up automatically  
3. **Piece Deselection** → Indicators clean up immediately
4. **Turn Phase Change** → All indicators clean up automatically

## Testing
- Created comprehensive test suite in `movement_indicator_cleanup_fix_test.rs`
- Tests cover all cleanup scenarios
- Build verification confirms no compilation errors

## Benefits
- ✅ No more lingering movement indicators after moves
- ✅ Clean board state between turns  
- ✅ Proper cleanup when changing turn phases
- ✅ Better performance (no indicator buildup)
- ✅ Improved user experience with cleaner visuals

## Verification
To verify the fix works:
1. Select a piece → indicators appear
2. Move the piece → indicators disappear immediately 
3. Turn changes to PowerSpawning → no indicators remain
4. Deselect a piece → indicators clean up instantly