# MoveDiagonal Power Test Script

## Test Objective
Verify that MoveDiagonal power allows diagonal movement for pieces when activated.

## Test Setup
1. Start game with debug controls enabled
2. Add MoveDiagonal power using debug key '1'
3. Force power activation phase using 'Space'
4. Test diagonal movement functionality

## Expected Behavior
- Normal pieces can only move orthogonally (up, down, left, right)
- With MoveDiagonal active, pieces should move diagonally
- Movement should respect terrain height rules
- Movement should respect collision detection

## Test Steps

### Step 1: Verify Normal Movement (Baseline)
1. Start game
2. Move a piece normally (should only allow orthogonal movement)
3. Confirm diagonal movement is NOT allowed

### Step 2: Add MoveDiagonal Power
1. Press '1' key to add MoveDiagonal power
2. Check console for: "DEBUG: Added MoveDiagonal to current player"
3. Verify power appears in player inventory

### Step 3: Activate Power Phase
1. Press 'Space' to force PowerActivation phase
2. Check console for: "DEBUG: Forced PowerActivation phase"
3. UI should show power activation interface

### Step 4: Test Diagonal Movement
1. Click MoveDiagonal power button in UI
2. Click on a piece to select
3. Try to move piece diagonally
4. Verify diagonal movement is now allowed

### Step 5: Verify Rules Still Apply
1. Test diagonal movement respects terrain height
2. Test collision detection with diagonal moves
3. Test board boundary handling

## Test Results Log
- [ ] Baseline orthogonal movement confirmed
- [ ] MoveDiagonal power added successfully
- [ ] Power activation phase triggered
- [ ] Diagonal movement enabled
- [ ] Terrain height rules respected
- [ ] Collision detection working
- [ ] Board boundaries respected

## Issues Found
(Document any bugs or unexpected behavior here)

## Status
⏳ **TODO** - Ready to execute test