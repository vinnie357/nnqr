# Bug Report: Power Pickup Issues

## Issue Description
Players are reporting they cannot pick up powers and cannot use powers they do pick up.

## Initial Investigation

### Finding 1: Debug Systems Disabled
- Debug systems were commented out in main.rs, preventing access to debug controls (P, O, I keys)
- Fixed by uncommenting debug systems

### Finding 2: Power Orb Spawning System Mismatch
- The main.rs file calls `spawn_balanced_power_orbs` from power_balance.rs
- This system has different spawning logic than the simpler `spawn_power_orbs` in power_orbs.rs
- The balanced system checks for existing orbs and limits spawning to 3 orbs maximum
- Uses a different coordinate calculation that might be causing position mismatches

### Finding 3: Coordinate System Issues
The balanced power orb spawning uses:
```rust
transform: Transform::from_translation(Vec3::new(
    spawn_pos.coordinates.0 as f32 * 75.0 - 262.5,
    spawn_pos.coordinates.1 as f32 * 75.0 - 262.5,
    1.0,
))
```

While the simple power orb system uses:
```rust
fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}
```

This suggests a coordinate mismatch between where orbs are visually displayed vs their logical board position.

## Fixes Applied
1. **Enabled debug systems** - Uncommented debug systems in main.rs to enable P, O, I keys
2. **Switched to simple spawn system** - Changed from spawn_balanced_power_orbs to spawn_power_orbs
3. **Added missing resource** - Added LastTurnTracker resource initialization

## Testing Plan
1. Build and run the game
2. Wait 5 seconds for automated tests to start
3. Use debug keys to manually test:
   - P: Spawn power orbs
   - O: Check power inventory
   - I: Generate test report
4. Test power collection by moving pieces over orbs
5. Verify power activation UI appears during power phase

## Known Issues Still to Investigate
1. Coordinate system mismatch between systems (75.0 vs 64.0 tile size)
2. Power activation UI may not be appearing correctly
3. Power effects may not be triggering properly