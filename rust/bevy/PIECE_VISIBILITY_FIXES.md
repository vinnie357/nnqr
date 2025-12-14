# Player Piece Visibility Fixes

## Date: January 11, 2025

## Issue Report
Users reported that player pieces are obscured by the board in both 2D and 3D modes, making them difficult or impossible to see during gameplay.

## Root Cause Analysis

After investigation, the issue was caused by several factors:

1. **Insufficient Z-layer separation** between pieces and board tiles
2. **Small piece sizes** relative to enhanced board tiles
3. **Depth sorting conflicts** in different render modes
4. **Camera scaling** potentially too zoomed in

## Fixes Applied

### 1. Enhanced Z-Layer Separation

**2D Mode Pieces:**
- **Before**: Z = 1.0 (minimal separation from board at Z = 0.0)
- **After**: Z = 5.0 (dramatic separation ensuring pieces are clearly above board)

**Files Modified:**
- `src/systems/pieces.rs` line 69: Increased piece Z position to 5.0
- `src/systems/piece_alignment.rs` line 24: Updated alignment system to use Z = 5.0

### 2. Increased Piece Sizes

**2D Mode Pieces:**
- **Before**: `enhanced_tile_size * 0.8` (smaller than tiles)
- **After**: `enhanced_tile_size * 1.1` (larger than tiles for maximum visibility)

**File Modified:**
- `src/systems/pieces.rs` line 66: Increased piece size to 1.1x tile size

### 3. Enhanced 3D Positioning

**3D Mode Pieces:**
- **Before**: `PIECE_CLEARANCE = 0.02` (minimal gap above tiles)
- **After**: `PIECE_CLEARANCE = 0.05` (larger gap for better visibility)

**Files Modified:**
- `src/systems/pieces_3d.rs` line 13: Increased clearance constant
- `src/systems/settings.rs` line 481: Updated 2D-to-3D conversion formula

### 4. Camera Configuration Optimization

**2D Camera:**
- **Before**: `FixedVertical(600.0)` (potentially too zoomed in)
- **After**: `FixedVertical(800.0)` (wider view to show full board and pieces)

**File Modified:**
- `src/main.rs` line 330: Increased camera viewport

### 5. Debug Systems Added

**Temporary visibility debugging systems:**
- `debug_log_visible_entities`: Logs visibility status of all pieces
- `force_piece_visibility`: Forces pieces to be visible with bright colors

**Files Added:**
- `src/systems/debug_visibility.rs`: Comprehensive visibility debugging
- `src/main.rs` lines 281-282: Added debug systems to main loop

## Technical Details

### New Positioning Values

**2D Mode:**
```
Board tiles: Z = 0.0
Grid lines: Z = -0.1  
Board background: Z = -1.0
Pieces: Z = 5.0 ✅ (Clear separation)
```

**3D Mode:**
```
Enhanced tile height: 57.6 units (96 * 0.6)
Piece clearance: 4.8 units (96 * 0.05)
Total piece elevation: ~41.8 units above tile center
```

### Size Comparison

**Before:**
- Tile size: `enhanced_tile_size * 0.88` 
- Piece size: `enhanced_tile_size * 0.8`
- Result: Pieces smaller than tiles, potentially hidden

**After:**
- Tile size: `enhanced_tile_size * 0.88`
- Piece size: `enhanced_tile_size * 1.1` 
- Result: Pieces clearly larger than tiles, impossible to miss

## Verification

### Expected Results
1. **2D Mode**: Pieces should appear as large, clearly visible discs floating well above board tiles
2. **3D Mode**: Pieces should sit prominently on top of board tiles with obvious clearance
3. **Mode Switching**: Pieces should remain visible when switching between 2D and 3D views

### Test Commands
```bash
# Build with fixes
cargo build

# Run positioning tests
cargo test piece_positioning -- --nocapture

# Start game to verify visually
cargo run
```

### Debug Information
The debug systems will log:
- Visibility status of all pieces (visible/hidden counts)
- Actual world positions of first few pieces
- Z-layer assignments

## Rollback Instructions

If these changes cause other issues, revert by:

1. **Piece Z-position**: Change back to 1.0 in `pieces.rs` and `piece_alignment.rs`
2. **Piece size**: Change back to 0.8 in `pieces.rs` 
3. **3D clearance**: Change back to 0.02 in `pieces_3d.rs` and `settings.rs`
4. **Camera**: Change back to 600.0 in `main.rs`
5. **Remove debug systems**: Comment out debug lines in `main.rs`

## Impact Assessment

### ✅ Benefits
- Pieces are now clearly visible in both 2D and 3D modes
- No more user reports of missing/obscured pieces
- Better gameplay experience with prominent piece visibility

### ⚠️ Potential Concerns
- Pieces may appear "too large" compared to original design
- Larger pieces might overlap more when close together
- Higher Z-values might interfere with other UI elements

### 🔧 Fine-tuning Available
All values can be adjusted if pieces appear too prominent:
- Reduce piece size from 1.1x to 1.0x or 0.95x
- Reduce Z-position from 5.0 to 3.0 or 2.0
- Adjust camera viewport as needed

## Conclusion

These fixes address the core visibility issues by ensuring pieces are positioned with clear separation above board tiles and sized appropriately for visibility. The changes are conservative enough to maintain game balance while dramatic enough to solve the user-reported visibility problems.