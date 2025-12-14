# Board Color Palette Update - 2D Visibility Improvements

## Date: January 11, 2025

## Overview
Updated the color palette for the 2D board view to significantly improve visibility and contrast, following the original Quadradius principle of "whiter = higher elevation."

## Problem
The previous 2D board colors were too dark, making it difficult to:
- Distinguish between different tile heights
- See the board boundaries clearly
- Identify game pieces on darker tiles

## Solution

### Color Changes Implemented

#### 1. Base Tile Colors (3D - unchanged)
- Base (Height 0): RGB(0.65, 0.67, 0.70)
- Height 1: RGB(0.72, 0.75, 0.78)
- Height 2: RGB(0.80, 0.83, 0.86)
- Height 3: RGB(0.88, 0.91, 0.94)
- Height 4: RGB(0.95, 0.98, 1.0)
- Depressed: RGB(0.35, 0.32, 0.30)

#### 2. 2D-Specific Tile Colors (NEW)
- Base (Height 0): RGB(0.70, 0.72, 0.75) - 7% brighter than 3D
- Height 1: RGB(0.76, 0.79, 0.82) - Clear elevation step
- Height 2: RGB(0.82, 0.85, 0.88) - Noticeable difference
- Height 3: RGB(0.88, 0.91, 0.94) - Approaching white
- Height 4: RGB(0.94, 0.97, 1.0) - Nearly pure white
- Depressed: RGB(0.40, 0.37, 0.35) - Warmer tone, still visible

#### 3. Supporting Elements
- Grid Lines: RGB(0.30, 0.30, 0.35) - Changed from RGB(0.1, 0.1, 0.1)
- Board Background: RGB(0.15, 0.15, 0.18) - NEW dark backdrop for contrast

## Implementation Details

### Files Modified:
1. `src/resources/theme.rs`
   - Added new 2D-specific color constants
   - Created `tile_color_for_height_2d()` function
   - Added grid line and background colors

2. `src/systems/board.rs`
   - Updated to use `tile_color_for_height_2d()` for tile colors
   - Replaced hardcoded grid color with theme constant
   - Added dark background sprite behind entire board

### Design Principles:
- **Whiter = Higher**: Following original game's elevation visualization
- **High Contrast**: Dark background with light tiles for clear boundaries
- **Clear Steps**: Each height level is visually distinct
- **Warm/Cool Tones**: Subtle blue tint for elevation, warm tint for depressions

## Results
- Board tiles are now clearly visible in 2D mode
- Height differences are immediately apparent
- Grid lines provide structure without overwhelming the tiles
- Dark background creates clear board boundaries

## Testing
Verified that:
- All tile heights render with correct colors
- Grid lines are visible but not intrusive
- Background properly sits behind all tiles
- 3D mode colors remain unchanged