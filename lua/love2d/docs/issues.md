# Issues

## Resolved

### Menu Continue Option
**Status:** RESOLVED (commit 1353afc)

**Problem:** When playing a game and hitting ESC key, the menu should have a continue option. Previously the user could only start a new game, go to settings, or exit the game.

**Solution:** Added "paused" screen with Continue, New Game, Settings, Quit options. ESC during gameplay now opens pause menu. New Game shows confirmation dialog to prevent accidental progress loss.

---

## Resolved

### PowerExecutor Integration
**Status:** RESOLVED (commits d8e6ad4, 6d3063a)

**Problem:** `Game.executepower()` in game.lua directly calls ~14 individual `PowerEffects.activate*` methods with a large if/else chain. Only a subset of the 83 powers were wired up for in-game use.

**Solution:**
- Refactored `Game.executepower()` to use `PowerExecutor.execute()` for all 83 powers
- Keep special animation cases for targeted powers (raise_tile, lower_tile, recruit, multiply, relocate)
- Use `GameAnimations.createPowerAnimation()` for generic power animations
- Simplified `GameAnimations.applyPowerEffect()` to use PowerExecutor

---

## Backlog

### Manual Testing Required
**Status:** PENDING

All 83 powers are now wired up through PowerExecutor. Manual testing is needed to verify each power category works correctly in-game.

**Test Checklist:**

#### Self-Targeting Powers (12)
- [ ] `move_diagonal` - Piece can move diagonally
- [ ] `move_again` - Piece gets extra move
- [ ] `jump_proof` - Piece immune to being jumped
- [ ] `invisible` - Piece becomes semi-transparent
- [ ] `climb_tile` - Piece ignores height restrictions
- [ ] `double_powers` - Powers work twice
- [ ] `grow_quadradius` - Piece influence radius increases
- [ ] `beneficiary` - Receives powers from defeated allies
- [ ] `scavenger` - Receives powers from defeated enemies
- [ ] `flat_to_sphere` - Movement pattern changes
- [ ] `smart_bombs` - Creates smart bomb effect
- [ ] `hotspot` - Creates teleport destination

#### Targeted Powers (6)
- [ ] `raise_tile` - Shows adjacent tiles, raises selected tile
- [ ] `lower_tile` - Shows adjacent tiles, lowers selected tile
- [ ] `recruit` - Shows adjacent enemies, converts selected enemy
- [ ] `multiply` - Shows adjacent empty tiles, clones piece
- [ ] `refurb` - Shows adjacent destroyed tiles, restores selected
- [ ] `switcheroo` - Shows adjacent pieces, swaps positions

#### Row Powers (20)
- [ ] `destroy_row` - Destroys all pieces in row
- [ ] Other row powers (kamikaze_row, recruit_row, etc.)

#### Column Powers (20)
- [ ] `destroy_column` - Destroys all pieces in column
- [ ] Other column powers

#### Radial Powers (21)
- [ ] `bomb` - Destroys pieces in 3x3 area
- [ ] Other radial powers

#### Global Powers (2)
- [ ] `orbic_rehash` - All orbs move to new positions
- [ ] `cancel_multiply` - Destroys all multiplied pieces

#### Special Powers (2)
- [ ] `hotspot_teleport` - Teleports to hotspot
- [ ] `centerpult` - Launches to center

**How to test:**
1. Run `mise run start` in `lua/love2d/`
2. Start a new game
3. Collect power orbs by moving pieces onto them
4. Click a piece to see its powers menu
5. Click a power to activate it
6. Verify the power effect works correctly

---

### Power Visual Feedback
**Status:** RESOLVED (commits c440b4c, f1e3b77)

Visual status indicators added for:
- climb_tile, flat_to_sphere, beneficiary, scavenger, tripwire, inhibited, multiplied

Enhanced animations:
- Terrain modification (raise/lower): ground cracks, dust clouds, directional arrows
- Recruit conversion: color transitions, conversion flash, two-color spiraling particles

### Sound Effects  
**Status:** MAPPINGS COMPLETE (sound files needed)

All 83 powers now have category-based sound mappings in `sound_manager.lua`:
- Destruction: explosion.ogg
- Teleportation: teleport.ogg
- Defensive: shield.ogg
- Recruitment: recruit.ogg
- Movement: power_up.ogg
- Terrain: terrain.ogg
- Power manipulation: magic.ogg
- Debuffs: debuff.ogg, acid.ogg
- Information: scan.ogg
- Traps: trap.ogg
- Chaos: scramble.ogg
- Healing: heal.ogg

**TODO:** Create actual .ogg sound files in `assets/sounds/`
