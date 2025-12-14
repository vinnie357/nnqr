# Task 1: Terrain Height Enhancement Context

You are working on Task 1 within Phase 3 of the Quadradius implementation. This task focuses on implementing terrain height modification powers and area terrain effects.

## Task Objective:
Implement individual tile height modification powers (LowerTile, RaiseTile) and area terrain effects (Flatten, Scramble) with proper integration to the existing terrain height system.

## Task Requirements:
- Implement LowerTile power that reduces target tile height by 1-3 levels
- Implement RaiseTile power that increases target tile height by 1-3 levels
- Implement Flatten power that creates uniform height across 3x3 area
- Implement Scramble power that randomizes heights within area bounds
- Maintain height limits (minimum 0, maximum 10)
- Integrate with existing power activation and targeting systems
- Provide clear visual feedback for all terrain modifications

## Deliverables:
- Extended PowerType enum with new terrain powers
- Power effect handlers in `src/systems/power_effects.rs`
- Tile height modification functions integrated with terrain system
- Area targeting enhancements for terrain preview
- Visual feedback system for terrain changes
- Comprehensive test suite for all new functionality

## Context Integration:
- Phase Context: ../tasks.md
- Project Standards: ../../shared/standards/claude.md
- Utilities: ../../shared/utilities/claude.md
- Coordination: ../../shared/coordination/claude.md

## Implementation Guidelines:
**Test-Driven Development**: Write tests first for each power before implementation
- Use the existing test framework in `tests/` directory
- Follow the test patterns shown in the task breakdown
- Ensure tests cover both normal cases and edge cases (height limits)

**Performance Requirements**: 
- Maintain 60+ FPS with all terrain modifications
- Use efficient batch operations for area effects
- Minimize visual effect overhead

**Integration Standards**:
- Follow existing ECS patterns in the codebase
- Integrate with existing power activation system
- Respect existing terrain height system architecture
- Maintain compatibility with movement validation

**Visual Standards**:
- Provide immediate visual feedback for height changes
- Use consistent visual effects with existing power system
- Ensure 3D isometric view properly represents height changes

## Code Organization:
```
Task Implementation Structure:
├── src/systems/power_effects.rs - Power effect handlers
├── src/components/powers.rs - PowerType enum extensions
├── src/systems/terrain_height.rs - Height modification functions
├── src/systems/visual_feedback.rs - Visual effect integration
└── tests/terrain_powers.rs - Comprehensive test suite
```

## Success Criteria:
- All tests pass with 100% success rate for new functionality
- LowerTile and RaiseTile powers work with single-tile targeting
- Flatten and Scramble powers work with area targeting (3x3)
- Height modifications respect minimum and maximum bounds
- Visual feedback is immediate and clear for all modifications
- Performance maintains 60+ FPS benchmark
- Integration testing validates no regressions in existing systems

## Testing Standards:
Required test coverage for each power:
1. **Normal functionality tests** - Power works as expected
2. **Boundary condition tests** - Respects height limits (0-10)
3. **Integration tests** - Works with targeting and activation systems
4. **Performance tests** - Maintains FPS requirements
5. **Edge case tests** - Handles error conditions gracefully

## Integration Dependencies:
- **Terrain System**: Build on existing `src/systems/terrain_height.rs`
- **Power System**: Extend existing power activation framework
- **Targeting System**: Enhance area targeting for terrain preview
- **Visual System**: Integrate with 3D rendering pipeline
- **Movement System**: Ensure terrain changes affect movement validation

## Next Steps:
After completing this task:
1. Update task status in `status.md` with completion details
2. Coordinate with Task 2 (Destructive Powers) for board state integration
3. Ensure terrain modification foundation supports destructive/constructive powers
4. Validate performance benchmarks before proceeding to next task

This task establishes the foundation for all subsequent terrain modification powers in Phase 3.