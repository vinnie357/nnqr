# Power Pickup and Usage Test Plan

## Overview
This test plan verifies that both Player 1 and Player 2 can successfully:
1. Pick up power orbs by moving pieces over them
2. View their collected powers
3. Activate and use powers during their turn
4. Experience the correct power effects

## Test Environment Setup

### Prerequisites
1. Build and run the game: `cargo run`
2. Enable debug mode for easier testing
3. Have two players ready to test (or test solo by alternating turns)

### Debug Controls Available
- **P** - Spawn a random power orb at a random location
- **O** - Display current player's power inventory
- **I** - Generate automated power test report

## Test Scenarios

### Test 1: Power Orb Pickup
**Objective**: Verify both players can collect power orbs

#### Player 1 Test Steps:
1. Start a new game
2. Press **P** to spawn a power orb (note its location)
3. Move a Player 1 piece to the power orb location
4. Verify the power orb disappears when the piece lands on it
5. Press **O** to display power inventory
6. **Expected Result**: The collected power should appear in Player 1's inventory

#### Player 2 Test Steps:
1. End Player 1's turn
2. Press **P** to spawn a new power orb
3. Move a Player 2 piece to the power orb location
4. Verify the power orb disappears
5. Press **O** to display power inventory
6. **Expected Result**: The collected power should appear in Player 2's inventory

### Test 2: Power Activation UI
**Objective**: Verify the power activation interface works for both players

#### For Each Player:
1. Collect at least one power orb (use Test 1 steps)
2. During your turn, the Power Activation UI should appear if you have powers
3. **Expected UI Elements**:
   - Title: "Power Activation"
   - List of collected powers with numbers
   - Instructions to press number keys to activate
   - "Skip (Space)" option
4. **Expected Behavior**:
   - UI only appears for the current player
   - UI shows only that player's powers
   - UI disappears after power use or skip

### Test 3: Individual Power Usage Tests

Test each of the 12 implemented powers for both players:

#### 3.1 MoveDiagonal Power
**Player 1:**
1. Collect MoveDiagonal power
2. Activate it during power phase (press corresponding number)
3. Select a piece and attempt diagonal movement
4. **Expected**: Piece can move diagonally

**Player 2:**
1. Repeat above steps as Player 2
2. **Expected**: Same diagonal movement capability

#### 3.2 RaiseColumn Power
**Both Players Test:**
1. Collect RaiseColumn power
2. Activate power and select a column (0-7)
3. **Expected**: All tiles in column increase height by 1 (max 3)
4. Verify pieces on raised tiles remain in place

#### 3.3 LowerColumn Power
**Both Players Test:**
1. Collect LowerColumn power
2. Activate power and select a column
3. **Expected**: All tiles in column decrease height by 1 (min -3)
4. Verify pieces on lowered tiles remain in place

#### 3.4 DestroyColumn Power
**Both Players Test:**
1. Collect DestroyColumn power
2. Place some pieces in a column for testing
3. Activate power and select that column
4. **Expected**: 
   - All tiles in column destroyed
   - All pieces in column removed
   - Column becomes impassable

#### 3.5 Multiply Power
**Both Players Test:**
1. Collect Multiply power
2. Activate power and select one of your pieces
3. Select an adjacent empty tile
4. **Expected**: New piece created at selected location

#### 3.6 Teleport Power
**Both Players Test:**
1. Collect Teleport power
2. Activate power and select a piece
3. Select any empty tile on board
4. **Expected**: Piece instantly moves to selected tile

#### 3.7 Jump Power
**Both Players Test:**
1. Collect Jump power
2. Place obstacle pieces for testing
3. Activate power and attempt to jump over pieces
4. **Expected**: Can jump over pieces/obstacles

#### 3.8 MoveTwo Power
**Both Players Test:**
1. Collect MoveTwo power
2. Activate power and select a piece
3. Select destination 2 tiles away
4. **Expected**: Piece moves 2 tiles in one direction

#### 3.9 Knight Power
**Both Players Test:**
1. Collect Knight power
2. Activate power and select a piece
3. Attempt L-shaped movement
4. **Expected**: Piece moves in chess knight pattern

#### 3.10 Slide Power
**Both Players Test:**
1. Collect Slide power
2. Activate power and select a piece
3. Select a direction
4. **Expected**: Piece slides until hitting obstacle/edge

#### 3.11 SmartBomb Power
**Both Players Test:**
1. Collect SmartBomb power
2. Place enemy pieces in a cluster
3. Activate power and select center of cluster
4. **Expected**: 3x3 area of destruction

#### 3.12 Sniper Power
**Both Players Test:**
1. Collect Sniper power
2. Activate power and select a distant enemy piece
3. **Expected**: Selected piece destroyed

### Test 4: Edge Cases and Error Handling

#### 4.1 Multiple Powers
1. Collect multiple different powers as one player
2. Verify all powers appear in inventory
3. Test using powers in sequence
4. **Expected**: Each power works independently

#### 4.2 Power Persistence
1. Collect powers but don't use them
2. End turn and wait for opponent's turn
3. On next turn, verify powers still available
4. **Expected**: Unused powers persist between turns

#### 4.3 Invalid Targets
1. Collect any targeted power (e.g., Multiply)
2. Try to target invalid locations:
   - Enemy pieces (for friendly powers)
   - Occupied tiles (for placement powers)
   - Out of range targets
3. **Expected**: Invalid selections rejected with feedback

### Test 5: Automated Test Verification
1. Wait 5 seconds after game start for automated tests
2. Check console for test results
3. Press **I** to generate detailed test report
4. **Expected**: All 12 powers show "PASSED" status

## Troubleshooting Guide

### Issue: Power orbs not spawning
- Verify using debug build
- Check console for spawn messages
- Try manual spawn with **P** key

### Issue: Can't collect powers
- Ensure piece lands exactly on power orb tile
- Check if piece movement is valid
- Verify power orb visual is present

### Issue: Power activation UI not appearing
- Confirm powers in inventory with **O**
- Check game state is "PowerActivation"
- Verify it's your turn

### Issue: Power effects not working
- Check console for error messages
- Verify correct power selected
- Ensure valid target selected
- Try automated test to isolate issue

## Test Recording Template

```
Date: _________
Tester: _________
Build Version: _________

Power Pickup Tests:
[ ] Player 1 can collect power orbs
[ ] Player 2 can collect power orbs
[ ] Power inventory displays correctly for both players

Power Usage Tests (mark P1/P2 for each):
[ ] MoveDiagonal    - P1:___ P2:___
[ ] RaiseColumn     - P1:___ P2:___
[ ] LowerColumn     - P1:___ P2:___
[ ] DestroyColumn   - P1:___ P2:___
[ ] Multiply        - P1:___ P2:___
[ ] Teleport        - P1:___ P2:___
[ ] Jump            - P1:___ P2:___
[ ] MoveTwo         - P1:___ P2:___
[ ] Knight          - P1:___ P2:___
[ ] Slide           - P1:___ P2:___
[ ] SmartBomb       - P1:___ P2:___
[ ] Sniper          - P1:___ P2:___

Edge Cases:
[ ] Multiple powers work correctly
[ ] Powers persist between turns
[ ] Invalid targets handled properly
[ ] Automated tests pass

Notes/Issues Found:
_________________________________
_________________________________
_________________________________
```

## Success Criteria
- All 12 implemented powers work for both players
- Power collection is consistent and reliable
- Power activation UI is intuitive and responsive
- No crashes or game-breaking bugs
- Clear visual/audio feedback for all power effects