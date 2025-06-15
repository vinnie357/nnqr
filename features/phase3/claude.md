# Phase 3: Board Manipulation & Terrain Powers - Context for Claude

## Phase Overview
**Status**: ⏳ NOT STARTED (Blocked by Phases 1 & 2)  
**Prerequisites**: Phase 1 terrain integration must be complete  
**Focus**: Powers that modify board topology, terrain heights, and create obstacles

## Research Documents & Context

### Primary Research References
1. **Terrain System**: `/research/game.md`
   - Lines 17-23: "Terrain Height System" mechanics
   - Line 19: "Pieces can move down any number of levels"
   - Line 20: "Pieces can only move up one level at a time"
   - Line 21: "Height differences create strategic positioning"

2. **Terrain Powers**: `/research/game.md`
   - Lines 56-61: Terrain manipulation examples
   - Line 57: "Dredge Column: Sinks enemy pieces 2 levels while raising friendly pieces"
   - Line 58: "Lower/Raise Tile: Modifies individual tile heights"
   - Line 59: "Scramble Column: Major terrain alterations"

3. **Board Specifications**: `/research/game.md`
   - Lines 11-12: "10×8 grid (10 columns by 8 rows)"
   - Line 91: "Height variations shown through color gradients"
   - Line 105: "Permanent terrain modifications visible"

4. **Technical Patterns**: `/research/isometric_design_patterns_bevy.md`
   - Lines 532-635: Area selection and multi-tile targeting
   - Lines 739-879: Performance with terrain modifications
   - Lines 416-530: Height-based movement validation

## Key Architecture Requirements

### Terrain System Components
```rust
#[derive(Component)]
pub struct TerrainHeight {
    pub height: i8,  // -5 to +5 typical range
    pub base_height: i8,  // Original height
    pub is_destroyed: bool,
    pub is_blocked: bool,
}

#[derive(Component)]
pub struct Wall {
    pub wall_type: WallType,
    pub health: u32,
    pub owner: Option<PlayerColor>,
}

#[derive(Event)]
pub struct TerrainModificationEvent {
    pub position: BoardPosition,
    pub modification: TerrainChange,
    pub affected_area: AffectedArea,
}
```

### Area Selection System
- 3x3 area selection for area powers
- Column selection (full vertical)
- Row selection (full horizontal)
- Custom patterns (cross, diagonal, etc.)

### Height Modification Rules
1. **Maximum Heights**: Usually -5 to +5
2. **Movement Rules**: Up 1 level, down unlimited
3. **Destroyed Tiles**: Impassable voids
4. **Visual Representation**: Color gradients

## Board Manipulation Categories

### Column/Row Powers
1. **RaiseColumn** - All tiles up 1 level
2. **LowerColumn** - All tiles down 1 level
3. **DestroyColumn** - Remove from play
4. **DredgeColumn** - Differential height change
5. **RotateColumn** - Rearrange pieces vertically

### Area Terrain Powers
1. **RaiseArea** - 3x3 up 1 level
2. **LowerArea** - 3x3 down 1 level
3. **Terraform** - Set specific heights
4. **Earthquake** - Random height changes
5. **Flatten** - Reset area to base level

### Obstacle Creation
1. **CreateWall** - Block movement
2. **IceWall** - Temporary barrier
3. **EnergyBarrier** - Selective blocking
4. **Pit** - Create void/hole
5. **Bridge** - Cross obstacles

### Board Transformation
1. **Rotate** - 3x3 section rotation
2. **Shuffle** - Randomize positions
3. **Mirror** - Flip section
4. **Compress** - Pull pieces together
5. **Expand** - Push pieces apart

## Phase 3 Dependencies

### From Phase 1 (Must be Complete)
1. **Terrain Height Integration** - Height system connected to powers
2. **Area Targeting System** - Multi-tile selection UI
3. **Movement Validation** - Height-based movement rules
4. **Visual Height Representation** - Clear height indicators

### From Phase 2 (Optional but Helpful)
1. **Effect System** - For temporary walls/bridges
2. **Duration Tracking** - For timed obstacles

### Systems to Create/Extend
1. **Area Selection UI** - Visual preview of affected tiles
2. **Terrain Modification System** - Apply height changes
3. **Obstacle System** - Walls and barriers
4. **Board State Validation** - Ensure playable board

## Implementation Patterns

### Column Modification Pattern
```rust
pub fn raise_column(
    column: u32,
    mut terrain_query: Query<&mut TerrainHeight>,
    board_positions: Query<&BoardPosition>,
) {
    for (entity, pos) in board_positions.iter() {
        if pos.x == column {
            if let Ok(mut terrain) = terrain_query.get_mut(entity) {
                terrain.height = (terrain.height + 1).min(MAX_HEIGHT);
                // Trigger visual update
            }
        }
    }
}
```

### Area Selection Pattern
```rust
pub fn get_3x3_area(center: BoardPosition) -> Vec<BoardPosition> {
    let mut positions = Vec::new();
    for dx in -1..=1 {
        for dy in -1..=1 {
            let x = (center.x as i32 + dx).clamp(0, BOARD_WIDTH - 1);
            let y = (center.y as i32 + dy).clamp(0, BOARD_HEIGHT - 1);
            positions.push(BoardPosition { x: x as u32, y: y as u32 });
        }
    }
    positions
}
```

### Wall Creation Pattern
```rust
pub fn create_wall(
    position: BoardPosition,
    wall_type: WallType,
    mut commands: Commands,
) {
    commands.spawn((
        Wall {
            wall_type,
            health: wall_type.max_health(),
            owner: None,
        },
        position,
        // Visual components
    ));
}
```

## Visual Requirements

### Height Visualization
- Color gradients: Darker = lower, Lighter = higher
- Height level indicators on tiles
- Smooth transitions between levels
- Shadow effects for depth

### Area Preview
- Highlight affected tiles before activation
- Show height change preview
- Indicate invalid targets
- Animation for modifications

### Obstacle Rendering
- Distinct wall visuals by type
- Semi-transparent for energy barriers
- Broken/damaged states
- Height-appropriate scaling

## Testing Considerations

### Edge Cases
1. Maximum/minimum height limits
2. Board boundary area selections
3. Pieces on modified terrain
4. Destroyed tile interactions
5. Wall placement validation

### Balance Testing
1. Height advantage quantification
2. Wall strategy effectiveness
3. Area power impact
4. Counter-play availability

### Performance Testing
1. Many terrain modifications
2. Complex height calculations
3. Pathfinding with obstacles
4. Visual update efficiency

## Phase 3 Success Criteria

1. **Terrain Powers Work**: All height modifications apply correctly
2. **Visual Clarity**: Height changes are immediately apparent
3. **Strategic Depth**: Board manipulation creates new strategies
4. **Performance**: Smooth gameplay with modified terrain
5. **Edge Cases**: All boundary conditions handled gracefully

## Common Pitfalls

1. **Height Overflow**: Not clamping to valid range
2. **Orphaned Pieces**: Pieces on destroyed tiles
3. **Pathfinding Issues**: Not updating after terrain changes
4. **Visual Confusion**: Too many height levels
5. **Performance Degradation**: Inefficient terrain queries

## Development Order

1. **Terrain Modification System** (Task 3.1)
2. **Area Selection UI** (Task 3.2)
3. **Column/Row Powers** (Task 3.3)
4. **Area Terrain Powers** (Task 3.4)
5. **Wall/Obstacle System** (Task 3.5)
6. **Board Transformation** (Task 3.6)

## Resources

- Terrain system: `systems/terrain_height.rs`
- Board components: `components/board.rs`
- Area selection: Reference SmartBomb implementation
- Visual examples: Current height rendering

Phase 3 transforms the static board into a dynamic battlefield.