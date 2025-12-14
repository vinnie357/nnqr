# URGENT: Mouse Click Crash Fix

## Issue Analysis
Users reporting game crashes to desktop when clicking pieces. Investigation reveals several potential crash points in the mouse input handling systems.

## Root Cause Analysis

### 1. Graphics Driver Issue (Primary)
The game is crashing during graphics initialization with wgpu-related panics:
```
thread 'main' panicked at wgpu-0.17.2/src/backend/direct.rs:771:18:
Encountered a panic in system `bevy_render::view::window::prepare_windows`!
```

### 2. Mouse Input System Issues (Secondary)
Several potential crash points identified in mouse handling:

**A. Window Query Safety**
```rust
let window = windows.single(); // CRASH RISK: Could panic if no window or multiple windows
```

**B. Camera Query Safety** 
```rust
let (camera, camera_transform) = camera_q.single(); // CRASH RISK: Could panic if no camera
```

**C. Coordinate Conversion Failures**
```rust
screen_to_board(&windows, &camera_q, cursor_pos) // Could return None and cause downstream panics
```

## Immediate Fixes Required

### 1. Add Safe Window/Camera Queries
Replace dangerous `.single()` calls with safe alternatives:

```rust
// BEFORE (crash risk)
let window = windows.single();
let (camera, camera_transform) = camera_q.single();

// AFTER (safe)
let Ok(window) = windows.get_single() else {
    return; // Gracefully exit if no window
};
let Ok((camera, camera_transform)) = camera_q.get_single() else {
    return; // Gracefully exit if no camera
};
```

### 2. Add Bounds Checking
```rust
// Add validation before board position access
if board_pos.0 >= BOARD_WIDTH || board_pos.1 >= BOARD_HEIGHT {
    return; // Invalid board position
}
```

### 3. Add Graphics Driver Workaround
For environments with graphics issues, add fallback rendering:

```rust
// In main.rs, add fallback for graphics issues
.add_plugins(DefaultPlugins.set(WindowPlugin {
    primary_window: Some(Window {
        title: "Quadradius".into(),
        resolution: (800.0, 600.0).into(),
        present_mode: bevy::window::PresentMode::Immediate, // More compatible
        ..default()
    }),
    ..default()
}).set(RenderPlugin {
    // Add compatibility settings
    wgpu_settings: WgpuSettings {
        backends: Some(Backends::VULKAN | Backends::DX12 | Backends::DX11),
        ..default()
    },
    ..default()
}))
```

## Files to Fix

### High Priority (Crash-causing)
1. `src/systems/drag_drop_3d.rs` - Replace `.single()` calls
2. `src/systems/piece_visibility_fix.rs` - Safe window queries
3. `src/systems/drag_drop.rs` - Safe camera queries
4. `src/main.rs` - Add graphics compatibility settings

### Medium Priority (Defensive)
1. Add error logging to identify crash points
2. Add coordinate validation throughout
3. Add entity existence validation before operations

## Quick Emergency Fix

For immediate deployment, add this at the start of each mouse handler:

```rust
// Emergency crash prevention
let Ok(window) = windows.get_single() else {
    warn!("No window available for mouse input");
    return;
};
let Ok((camera, camera_transform)) = camera_q.get_single() else {
    warn!("No camera available for mouse input");
    return;
};
```

## Testing Plan

1. **Test mouse clicks on pieces** - Should not crash
2. **Test mouse clicks on empty areas** - Should not crash  
3. **Test rapid clicking** - Should handle gracefully
4. **Test on different graphics drivers** - Should initialize properly

## Long-term Solution

1. Implement comprehensive error handling throughout input systems
2. Add telemetry to identify crash patterns
3. Create fallback rendering modes for compatibility
4. Add automated crash detection and recovery

## Priority: CRITICAL
This fix should be implemented immediately as crashes prevent all gameplay.