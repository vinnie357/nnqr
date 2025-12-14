# Bug Report: 3D Board Valid Movement Indicators Obscure View

## Bug ID
010_3dboard_valid_movement_indicators_obscure

## Priority
High

## Summary
When players select a piece to move on the 3D board, the green movement indicators cover both the selected piece and the board tiles, obscuring the player's view and making it impossible to clearly see available move locations.

## Description
The movement indicator system currently renders green highlights that overlay the entire area including:
- The selected piece itself
- The board tiles where movement is valid
- Potentially other pieces or board elements

This creates visual confusion and prevents players from clearly identifying valid move targets.

## Expected Behavior
Movement indicators should:
- Only highlight valid move destination tiles
- NOT cover or obscure the selected piece
- Provide clear visual distinction between the selected piece and valid move locations
- Allow players to easily see and select their intended move target

## Actual Behavior
Movement indicators currently:
- Cover the selected piece with green highlighting
- Obscure the board tiles making selection difficult
- Create visual clutter that hinders gameplay

## Steps to Reproduce
1. Start a game with 3D board view enabled
2. Click on any player piece to select it
3. Observe the green movement indicators that appear
4. Notice how the indicators cover the piece and board

## Impact
- Gameplay usability is significantly reduced
- Players cannot clearly see their move options
- Selection of move targets becomes difficult or impossible
- Overall game experience is degraded

## Suggested Fix
Modify the movement indicator rendering system to:
1. Exclude the selected piece from indicator overlays
2. Apply indicators only to valid destination tiles
3. Use appropriate Z-ordering to prevent obscuring important visual elements
4. Consider using outline/border highlighting instead of full tile coverage

## Related Files
- `quadradius/src/systems/board_3d.rs` - 3D board rendering
- `quadradius/src/systems/enhanced_visual_feedback.rs` - Visual feedback systems
- Movement indicator components and rendering systems

## Environment
- 3D board view mode
- All piece types affected
- Occurs consistently on piece selection