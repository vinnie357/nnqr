# Issue: 2D Board View Implementation Requirements

**Issue Type**: Feature Implementation  
**Priority**: High  
**Category**: Rendering System & Camera Management  
**Created**: 2025-01-15  
**Epic**: Dual View System Support  

## Problem Statement

The Quadradius game requires support for both 3D isometric and 2D top-down board views. The second screenshot reveals a flat 2D grid representation that differs significantly from the isometric 3D view, requiring a dual rendering system implementation.

## Screenshot Analysis - 2D Top-Down Board View

### Visual Characteristics
- **Grid Layout**: Clear 10x8 tile structure with black border separators
- **Tile Appearance**: Gray/light colored flat squares without height variation
- **Perspective**: Pure orthographic 2D view from directly above
- **Piece Representation**: Magenta/pink square pieces instead of circular 3D pieces
- **Spatial Clarity**: Enhanced grid visibility with distinct tile boundaries

### Game State Representation
- **Piece Distribution**: Same strategic positioning as 3D view
- **Player Pieces**: Clearly distributed around board perimeter
- **Turn Information**: Consistent with 3D view ("Player 1's Turn - Move Phase")
- **Piece Counts**: Maintained accuracy (P1: 20, P2: 20)

### UI Consistency Analysis
- **Panel Layout**: Identical to 3D view (left power panel, right chat, top status)
- **Control Scheme**: Same bottom status bar with identical controls
- **Chat System**: Functioning chat panel on right side
- **Power Display**: Consistent power panel structure on left

## Technical Implementation Requirements

### 1. Dual Camera System
```rust
#[derive(Component)]
enum CameraMode {
    Isometric3D {
        angle: f32,
        height: f32,
    },
    Orthographic2D {
        zoom: f32,
    },
}

#[derive(Resource)]
struct ViewModeSettings {
    current_mode: CameraMode,
    transition_speed: f32,
}
```

### 2. Adaptive Rendering Pipeline
```rust
#[derive(Component)]
enum PieceVisualMode {
    Circular3D {
        radius: f32,
        height_offset: f32,
    },
    Square2D {
        size: f32,
    },
}

#[derive(Component)]
struct ViewModeAdapter {
    mode_3d: PieceVisualMode,
    mode_2d: PieceVisualMode,
}
```

### 3. Board State Management
```rust
#[derive(Resource)]
struct BoardState {
    tiles: [[TileData; 8]; 10],
    pieces: HashMap<Entity, PieceData>,
    current_view: ViewMode,
}

// Unified board state that works for both views
#[derive(Component)]
struct TileData {
    coordinates: (u8, u8),
    height: i8,           // Preserved for 3D view
    occupant: Option<Entity>,
    power_orb: Option<PowerType>,
}
```

## Critical Implementation Challenges

### 1. Height Information Loss
**Problem**: 2D view doesn't show terrain height differences
**Impact**: Players lose strategic height advantage information
**Solution Options**:
- Add subtle color gradients to indicate height in 2D
- Include height indicators (numbers/symbols) on tiles
- Provide tooltip information on hover

### 2. Input Handling Complexity
**Problem**: Mouse picking needs to work in both camera modes
**Technical Requirements**:
```rust
fn handle_tile_selection(
    camera_query: Query<(&Camera, &CameraMode)>,
    cursor_ray: Ray,
    board_tiles: Query<&Transform, With<BoardTile>>,
) {
    match camera_mode {
        CameraMode::Isometric3D => {
            // 3D ray casting with height consideration
        },
        CameraMode::Orthographic2D => {
            // 2D coordinate conversion
        },
    }
}
```

### 3. Performance Optimization
**Problem**: Maintaining dual rendering pipelines
**Concerns**:
- Memory usage for multiple visual representations
- GPU load for switching between render modes
- Frame rate consistency during view transitions

### 4. Visual Continuity
**Problem**: Ensuring smooth user experience during view switches
**Requirements**:
- Maintain board position during camera transitions
- Preserve piece selection state across view changes
- Consistent UI interaction regardless of view mode

## Bevy Implementation Strategy

### Core Systems Required

#### 1. Camera Controller System
```rust
fn camera_view_switcher_system(
    keyboard: Res<ButtonInput<KeyCode>>,
    mut camera_query: Query<(&mut Transform, &mut CameraMode)>,
    mut view_settings: ResMut<ViewModeSettings>,
) {
    // Handle view switching with Q/E keys or UI button
    // Implement smooth camera transitions
}
```

#### 2. Adaptive Piece Rendering
```rust
fn update_piece_visuals_system(
    view_mode: Res<ViewModeSettings>,
    mut piece_query: Query<(&mut Sprite, &PieceData, &ViewModeAdapter)>,
) {
    // Switch between circular and square representations
    // Update colors and sizes based on view mode
}
```

#### 3. Board Rendering Pipeline
```rust
fn render_board_system(
    view_mode: Res<ViewModeSettings>,
    tile_query: Query<(&TileData, &mut Transform, &mut Sprite)>,
) {
    // Render height-based 3D tiles or flat 2D grid
    // Adjust lighting and shadows based on view mode
}
```

### Integration with Existing Systems

#### bevy_ecs_tilemap Integration
- Use tilemap for efficient 2D grid rendering
- Maintain 3D height information as metadata
- Switch between tilemap and 3D mesh rendering

#### UI System Compatibility
- Ensure UI panels work with both camera projections
- Maintain consistent interaction zones
- Handle different screen coordinate systems

## Acceptance Criteria

### Functional Requirements
- [ ] Support seamless switching between 3D isometric and 2D orthographic views
- [ ] Maintain identical game state across both view modes
- [ ] Preserve all UI functionality in both views
- [ ] Handle input (mouse clicks, piece selection) correctly in both modes
- [ ] Display terrain height information appropriately in 2D view

### Performance Requirements
- [ ] Maintain 60fps in both view modes
- [ ] View transitions complete within 500ms
- [ ] Memory usage increase < 25% for dual view support
- [ ] No frame drops during view switching

### Visual Requirements
- [ ] Piece representations are clear and distinct in both views
- [ ] Grid visibility is optimal in 2D mode
- [ ] Height information is conveyed effectively in 2D (via color/indicators)
- [ ] UI elements scale appropriately for both camera types

### User Experience Requirements
- [ ] Intuitive view switching mechanism (Q/E keys or UI button)
- [ ] Consistent piece selection behavior across views
- [ ] Smooth camera transitions without disorientation
- [ ] Help text/tutorial explaining dual view benefits

## Technical Dependencies

### Core Bevy Features
- **Camera System**: Multiple camera entities with different projections
- **Transform System**: 3D positioning that translates to 2D coordinates
- **Sprite System**: Adaptive sprite rendering for different view modes
- **Input System**: Ray casting for both 3D and 2D picking

### Third-Party Crates
- **bevy_ecs_tilemap**: Efficient 2D grid rendering
- **bevy_hanabi**: Particle effects that work in both view modes
- **Custom Camera Controller**: Smooth transitions between view modes

## Implementation Phases

### Phase 1: Core Dual Camera System
1. Implement basic camera mode switching
2. Create orthographic 2D camera setup
3. Add view mode resource management
4. Test basic camera transitions

### Phase 2: Adaptive Rendering
1. Implement piece visual mode switching
2. Create 2D board tile rendering system
3. Add height information display for 2D view
4. Optimize rendering pipeline for both modes

### Phase 3: Input System Integration
1. Implement mouse picking for both view modes
2. Ensure piece selection works in both views
3. Add view-appropriate hover effects
4. Test interaction consistency

### Phase 4: Polish & Optimization
1. Smooth camera transition animations
2. Performance optimization for dual rendering
3. UI improvements for view switching
4. User experience refinements

## Related Issues

- [UI Layout and Visual Design Analysis](./quadradius-ui-analysis-issue.md)
- [Bevy Examples Implementation Guide](./bevy-examples-guide.md)
- [Quadradius Game Recreation Guide](./quadradius-recreation-guide.md)

## Risk Assessment

**High Risk**: Complex camera system implementation
**Medium Risk**: Performance impact of dual rendering pipeline
**Low Risk**: UI compatibility across view modes

**Mitigation Strategy**: Implement core camera switching first, then gradually add adaptive features while monitoring performance impact.
