# CLAUDE.md - Quadradius Implementation Guide

## Project Context
You are implementing Quadradius, a turn-based strategy game described as "checkers on steroids", using Rust and the Bevy game engine. This is a faithful recreation of the 2007 Flash game featuring an 8x8 board, terrain heights, and approximately 70 different power-ups that dramatically alter gameplay.

**IMPORTANT**: This guide works alongside two companion documents:
1. **Project Requirements Document (PRD)** - Contains complete game mechanics, technical architecture, and project specifications
2. **Implementation Plan** - Contains strict phase-by-phase execution steps with acceptance criteria

**Your workflow should be**: Implementation Plan (what to do) → CLAUDE.md (how to do it) → PRD (detailed specifications)

## Implementation Philosophy

### MANDATORY: Follow the Implementation Plan
**NEVER deviate from the Implementation Plan phases without explicit instruction**
- Phase 1 MUST be 100% complete before any power-up work
- Each step's acceptance criteria must be fully met before proceeding
- The plan exists to prevent common game development failures

### Start Simple, Build Incrementally
- Begin with the absolute minimum: board rendering and basic piece movement
- Add one feature at a time and test thoroughly before moving on
- Resist the urge to implement multiple systems simultaneously
- Each commit should represent a working, testable increment

### Bevy Best Practices
- Embrace the Entity Component System (ECS) architecture
- Keep systems focused and single-responsibility
- Use Resources for global game state, Components for entity data
- Leverage Bevy's query system for efficient data access
- Prefer composition over inheritance for game entities

### Reference Document Usage
- **Implementation Plan**: Your step-by-step roadmap (FOLLOW THIS STRICTLY)
- **PRD**: Detailed specifications when you need technical details
- **CLAUDE.md** (this doc): Best practices and implementation guidance

## Development Phases & Milestones

**CRITICAL**: These phases align with the Implementation Plan. Refer to the Implementation Plan for specific acceptance criteria and detailed tasks.

### Phase 1: Foundation (Complete this FIRST)
**Goal**: Get a basic playable game without power-ups
**Status**: MANDATORY prerequisite for all other work

**Key Implementation Points from Plan**:
- Step 1.1: Project setup and basic 8x8 board rendering
- Step 1.2: Player pieces, selection system  
- Step 1.3: Movement system with terrain height rules
- Step 1.4: Turn management and win conditions

**Don't proceed to Phase 2 until**: Two humans can play a complete game locally with all basic rules working perfectly.

### Phase 2: Power-Up Foundation  
**Goal**: Add core power-up mechanics with first 5 powers
**Prerequisites**: Phase 1 must be 100% complete

**Key Implementation Points from Plan**:
- Step 2.1: Power orb spawning and collection system
- Step 2.2: Power activation UI and framework
- Step 2.3: Implement exactly 5 specific powers (Move Diagonal, Raise Column, Lower Column, Destroy Column, Multiply)

### Phase 3: Expanded Power System
**Goal**: Implement remaining ~65 powers in organized groups
**Prerequisites**: Phase 2 must be 100% complete

### Phase 4: Polish & Multiplayer
**Goal**: Production-ready game with networking
**Prerequisites**: Phase 3 must be 100% complete

## Critical Technical Decisions

### Board Representation
```rust
// Recommended approach:
#[derive(Component)]
struct BoardTile {
    coordinates: (u8, u8),
    height: i8,
    occupant: Option<Entity>, // Reference to piece entity
    power_orb: Option<PowerType>,
}

// Use Bevy entities for each tile - easier queries and updates
```

### Movement Validation
```rust
// Key rule: pieces can move down any levels, up only one level
fn is_valid_move(from: (u8, u8), to: (u8, u8), board: &Board) -> bool {
    let from_height = board.get_height(from);
    let to_height = board.get_height(to);
    
    // Can always move down, can only move up one level
    to_height <= from_height + 1
}
```

### Power-Up Architecture
```rust
// Design for extensibility from the start:
trait PowerEffect {
    fn can_activate(&self, context: &GameContext) -> bool;
    fn activate(&self, context: &mut GameContext) -> Result<(), GameError>;
    fn get_targets(&self, context: &GameContext) -> Vec<Target>;
}

// This trait approach makes adding new powers straightforward
```

## Common Pitfalls & Solutions

### Problem: Overengineering Early
**Symptom**: Spending time on abstract systems before basic gameplay works
**Solution**: Hardcode first, then refactor. Get it working before getting it perfect.

### Problem: Complex State Management
**Symptom**: Game state becomes confusing, bugs in turn management
**Solution**: Use clear state machines and Bevy's States:

```rust
#[derive(States, Debug, Clone, PartialEq, Eq, Hash)]
enum GameState {
    SetupBoard,
    PlayerTurn(PlayerId),
    PowerActivation,
    GameOver(PlayerId), // winner
}
```

### Problem: Power-Up Interaction Complexity
**Symptom**: Powers affecting each other in unpredictable ways
**Solution**: Process powers in strict order, use event system:

```rust
#[derive(Event)]
struct PowerActivated {
    power_type: PowerType,
    target: Target,
    player: PlayerId,
}
```

## Testing Strategy

### Test Each Phase Thoroughly
```rust
// Example tests you should write:
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_movement_validation() {
        // Test height restrictions
        // Test bounds checking
        // Test occupied tile handling
    }

    #[test]
    fn test_turn_alternation() {
        // Ensure turns switch correctly
        // Test invalid turn attempts
    }

    #[test]
    fn test_win_conditions() {
        // Test piece elimination victory
        // Test edge cases
    }
}
```

### Manual Testing Checklist
For each milestone, manually verify:
- [ ] Can complete a full game without crashes
- [ ] UI is responsive and intuitive
- [ ] Game rules are enforced correctly
- [ ] Visual feedback is clear
- [ ] Performance is acceptable (60 FPS)

## Code Organization

### Recommended Project Structure
```
src/
├── main.rs              # Bevy app setup
├── lib.rs               # Re-exports
├── systems/
│   ├── mod.rs
│   ├── board.rs         # Board rendering and management
│   ├── movement.rs      # Piece movement logic
│   ├── input.rs         # User input handling
│   ├── powers.rs        # Power-up system
│   └── ui.rs           # User interface
├── components/
│   ├── mod.rs
│   ├── board.rs         # Board-related components
│   ├── piece.rs         # Piece components
│   └── power.rs         # Power-up components
├── resources/
│   ├── mod.rs
│   ├── game_state.rs    # Global game state
│   └── config.rs        # Game configuration
└── events/
    ├── mod.rs
    ├── game_events.rs   # Game-specific events
    └── input_events.rs  # Input events
```

### Key Systems to Implement
```rust
// Core systems in order of implementation:
fn setup_board_system()        // Phase 1
fn handle_input_system()       // Phase 1  
fn move_pieces_system()        // Phase 1
fn check_win_condition_system() // Phase 1
fn spawn_power_orbs_system()   // Phase 2
fn activate_powers_system()    // Phase 2
fn ui_update_system()          // Throughout
```

## Debugging & Development Tips

### Use Bevy's Debug Tools
```rust
// Add these for development:
use bevy::diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin};

app.add_plugins((
    FrameTimeDiagnosticsPlugin::default(),
    LogDiagnosticsPlugin::default(),
));
```

### Visual Debugging
- Use different colors for tile heights
- Add debug overlays for valid moves
- Show game state in window title
- Use console logging for turn events

### Performance Monitoring
- Profile early and often
- Watch entity count (should be manageable for 8x8 board)
- Monitor frame time during power activation
- Test with all 70 powers eventually active

## Power-Up Implementation Strategy

### Start with Simple Powers (Phase 2)
1. **Move Diagonal**: Just modify movement validation temporarily
2. **Destroy Column**: Remove tiles from board, handle piece displacement
3. **Raise/Lower Column**: Modify tile heights, validate moves still work
4. **Multiply**: Spawn new piece entity at valid location
5. **Invisible**: Add visibility component, modify rendering

### Medium Complexity Powers (Phase 3)
- Powers that affect multiple pieces
- Powers that modify other powers
- Powers with duration effects

### Complex Powers (Phase 3)
- Powers that completely change game rules temporarily
- Powers with complex targeting systems
- Powers that interact with other powers

## Success Metrics

**FOLLOW IMPLEMENTATION PLAN SUCCESS CHECKPOINTS EXACTLY**

### Phase 1 Complete When (from Implementation Plan):
- [ ] Game runs without crashes
- [ ] Complete games can be played start to finish  
- [ ] All movement rules work correctly
- [ ] Win conditions are properly detected
- [ ] Code is well-organized and documented

### Phase 2 Complete When (from Implementation Plan):
- [ ] Power orbs spawn and can be collected
- [ ] 5 specific powers work as intended (Move Diagonal, Raise Column, Lower Column, Destroy Column, Multiply)
- [ ] No regressions in basic gameplay
- [ ] Power effects are visually clear
- [ ] Game remains balanced and fun

### Ready for Phase 3 When:
- All Phase 2 acceptance criteria met
- Manual testing passes completely
- Code is clean and maintainable

### Ready for Polish When:
- All major powers implemented
- Game feels balanced and fun
- Performance is solid
- Code is maintainable

## Final Notes

**DOCUMENT HIERARCHY**:
1. **Implementation Plan** = Your strict roadmap (NEVER deviate without instruction)
2. **CLAUDE.md** (this) = How to implement effectively  
3. **PRD** = Detailed technical specifications when needed

**PHASE DISCIPLINE**:
The Implementation Plan's phase structure exists because 90% of game projects fail by trying to build everything at once. The phases are designed to prevent:
- Overengineering before basic gameplay works
- Complex power-up bugs that are hard to debug
- Scope creep and feature bloat
- Performance issues from premature optimization

**WHEN IN DOUBT**:
- Check the Implementation Plan for what to do next
- Check the PRD for detailed specifications  
- Check CLAUDE.md for how to implement it well
- Ask for clarification if acceptance criteria are unclear

Remember: The original Quadradius was beloved because it was **fun to play**, not because it was technically perfect. Focus on gameplay feel over technical perfection, especially in early phases.

Get humans playing your game as early as possible and gather feedback. A working game with 5 powers is infinitely more valuable than a perfectly architected system with 0 powers.

**CRITICAL**: Follow the Implementation Plan phases religiously. The documents work together to ensure success - don't skip steps or phases!
