# Task 2: Destructive Environmental Powers Context

You are working on Task 2 within Phase 3 of the Quadradius implementation. This task focuses on implementing destructive environmental powers that permanently modify board accessibility and create strategic hazards.

## Task Objective:
Implement destructive powers (Acid, Crater, Earthquake, Flood) that create permanent board modifications, impassable areas, and dynamic environmental effects while maintaining gameplay balance.

## Task Requirements:
- Implement Acid power that creates permanent impassable holes in single tiles
- Implement Crater power that creates large depressions affecting multiple tiles
- Implement Earthquake power with controlled random destruction patterns
- Implement Flood power that fills low-lying areas with impassable water
- Extend board state management to track impassable/destroyed areas
- Update movement validation to respect destroyed terrain
- Provide clear visual representation of destroyed/hazardous areas

## Deliverables:
- Board state extensions for tracking impassable tiles and environmental hazards
- Destructive power implementations with permanent board modifications
- Enhanced movement validation system that respects terrain destruction
- Random effect generation system with balanced bounds for Earthquake
- Environmental hazard system for ongoing effects (Flood)
- Visual effects system for destruction sequences and permanent changes
- Comprehensive test suite covering destruction scenarios and edge cases

## Context Integration:
- Phase Context: ../tasks.md
- Task 1 Dependencies: ../task1-terrain-height/ (terrain modification foundation)
- Project Standards: ../../shared/standards/claude.md
- Utilities: ../../shared/utilities/claude.md
- Coordination: ../../shared/coordination/claude.md

## Implementation Guidelines:
**Board State Management**: 
- Extend existing board representation to track destroyed/impassable tiles
- Implement persistent storage for terrain modifications across game turns
- Ensure board state changes are properly serialized for save/load functionality

**Destruction Balance**:
- Earthquake destruction must be random but within balanced gameplay bounds
- Prevent scenarios that isolate pieces with no possible moves
- Ensure destructive effects enhance rather than break strategic gameplay

**Performance Requirements**:
- Maintain 60+ FPS with complex destruction scenarios
- Optimize visual effects for multiple simultaneous destructions
- Efficient pathfinding updates when terrain becomes impassable

**Integration Standards**:
- Build upon Task 1's terrain height modification foundation
- Integrate seamlessly with existing movement and power systems
- Maintain ECS architecture patterns established in codebase

## Code Organization:
```
Task Implementation Structure:
├── src/components/board_state.rs - Board destruction tracking
├── src/systems/power_effects.rs - Destructive power handlers
├── src/systems/movement_validation.rs - Updated pathfinding
├── src/systems/environmental_hazards.rs - Ongoing effect management
├── src/systems/visual_destruction.rs - Destruction visual effects
└── tests/destructive_powers.rs - Comprehensive destruction testing
```

## Success Criteria:
- Acid power creates permanent single-tile holes that block all movement
- Crater power creates multi-tile depressions with realistic terrain modification
- Earthquake power generates balanced random destruction within reasonable bounds
- Flood power fills low areas creating strategic water barriers
- Board state correctly tracks all types of terrain destruction
- Movement validation prevents access to all destroyed/impassable areas
- Visual effects clearly communicate permanent terrain changes
- Performance maintains 60+ FPS with maximum destruction scenarios
- Balance testing confirms no unwinnable game states are created

## Testing Standards:
**Destruction Functionality Tests**:
1. **Single Destruction Tests** - Each power works individually
2. **Combination Tests** - Multiple destructive powers interact properly
3. **Edge Case Tests** - Destruction at board boundaries, near existing pieces
4. **Balance Tests** - No scenarios create completely isolated pieces
5. **Performance Tests** - Frame rate maintained with maximum destruction
6. **Persistence Tests** - Destroyed terrain persists across turns/saves

**Random Effect Validation**:
- Earthquake effects are random but bounded
- Random destruction patterns are balanced for gameplay
- Random seed testing for reproducible results

## Environmental Hazard System:
**Flood Implementation**:
- Identify low-lying areas based on terrain height
- Create expanding water hazards that follow terrain topology
- Implement ongoing hazard effects that persist across turns
- Visual representation of water hazards with proper depth perception

**Hazard Management**:
- Track multiple simultaneous environmental hazards
- Handle hazard interactions (e.g., Earthquake affecting Flooded areas)
- Performance optimization for ongoing hazard processing

## Integration Dependencies:
- **Task 1 Foundation**: Builds on terrain height modification system
- **Board System**: Requires board state extension for destruction tracking
- **Movement System**: Must update pathfinding and validation systems
- **Visual System**: Needs destruction effects and permanent change visualization
- **Power System**: Integrates with existing power activation framework

## Balance Considerations:
**Gameplay Impact**:
- Destructive powers should create strategic opportunities, not game-breaking scenarios
- Random effects (Earthquake) bounded to prevent excessive destruction
- Multiple destructive powers shouldn't compound to create unplayable boards

**Strategic Value**:
- Acid creates tactical chokepoints and area denial
- Crater provides elevation changes for strategic positioning
- Earthquake introduces unpredictability while maintaining game balance
- Flood creates dynamic barriers that follow terrain topology

## Next Steps:
After completing this task:
1. Update status in `status.md` with destruction system completion
2. Coordinate with Task 3 (Constructive Powers) for construction/destruction interactions
3. Validate that destructive foundation supports constructive power integration
4. Test edge cases where construction and destruction powers interact
5. Prepare comprehensive integration testing for all Phase 3 powers

This task creates the foundation for permanent board modification that will interact with constructive powers in Task 3.