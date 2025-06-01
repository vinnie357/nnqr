# Rust Testing Guide for Quadradius Project

## Overview
This document outlines the comprehensive testing strategy for the Quadradius game implementation in Rust using Bevy. Testing is critical for ensuring game logic correctness, preventing regressions, and maintaining code quality throughout development.

## Testing Philosophy for Game Development

### Core Principles
1. **Test Game Logic, Not Engine Code**: Focus on your game rules, not Bevy's internals
2. **Fast Feedback Loops**: Tests should run quickly to enable rapid iteration
3. **Deterministic Testing**: Game state should be predictable and reproducible
4. **Isolated Components**: Test individual systems and components in isolation
5. **Integration at Boundaries**: Test how systems interact, especially at game rule boundaries

### Testing Pyramid for Games
```
    ┌─────────────────┐
    │   E2E Tests     │  ← Full game scenarios (few, slow)
    │   (Scenarios)   │
    ├─────────────────┤
    │ Integration     │  ← System interactions (moderate)
    │ Tests           │
    ├─────────────────┤
    │ Unit Tests      │  ← Individual functions/components (many, fast)
    └─────────────────┘
```

---

## Rust Testing Fundamentals

### Basic Test Structure
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_function_name() {
        // Arrange
        let input = setup_test_data();
        
        // Act
        let result = function_under_test(input);
        
        // Assert
        assert_eq!(result, expected_value);
    }
}
```

### Key Testing Attributes
- `#[test]` - Marks a function as a test
- `#[ignore]` - Skip test during normal runs
- `#[should_panic]` - Test should panic to pass
- `#[should_panic(expected = "message")]` - Test should panic with specific message

### Assertion Macros
```rust
assert_eq!(left, right);           // Equality
assert_ne!(left, right);           // Inequality  
assert!(condition);                // Boolean true
assert!(condition, "message");     // With custom message
debug_assert_eq!(left, right);     // Only in debug builds
```

### Running Tests
```bash
cargo test                    # Run all tests
cargo test test_name         # Run specific test
cargo test module_name       # Run tests in module
cargo test -- --nocapture   # Show println! output
cargo test -- --ignored     # Run ignored tests
cargo test --release        # Run in release mode
```

---

## Bevy-Specific Testing Patterns

### Testing ECS Components
```rust
#[cfg(test)]
mod component_tests {
    use super::*;
    use bevy::prelude::*;

    #[test]
    fn test_game_piece_creation() {
        let piece = GamePiece {
            player: PlayerId(1),
            powers: vec![],
        };
        
        assert_eq!(piece.player.0, 1);
        assert!(piece.powers.is_empty());
    }
}
```

### Testing Systems with Mock Worlds
```rust
#[cfg(test)]
mod system_tests {
    use super::*;
    use bevy::prelude::*;

    #[test]
    fn test_movement_system() {
        // Create a test world
        let mut world = World::new();
        
        // Add required resources
        world.insert_resource(GameState::default());
        
        // Spawn test entities
        let entity = world.spawn((
            BoardPosition(0, 0),
            GamePiece { player: PlayerId(1), powers: vec![] }
        )).id();
        
        // Create and run system
        let mut system = IntoSystem::into_system(movement_system);
        system.initialize(&mut world);
        system.run((), &mut world);
        
        // Assert results
        let position = world.get::<BoardPosition>(entity).unwrap();
        assert_eq!(position.0, expected_x);
    }
}
```

### Testing Resources and Events
```rust
#[test]
fn test_game_state_transitions() {
    let mut world = World::new();
    world.insert_resource(GameState::PlayerTurn(PlayerId(1)));
    
    // Test state transition logic
    let current_state = world.get_resource::<GameState>().unwrap();
    match current_state {
        GameState::PlayerTurn(player) => assert_eq!(player.0, 1),
        _ => panic!("Expected PlayerTurn state"),
    }
}
```

---

## Quadradius-Specific Testing Strategy

### Phase 1: Foundation Testing
**Critical areas to test immediately:**

#### Board Logic Tests
```rust
#[cfg(test)]
mod board_tests {
    use super::*;

    #[test]
    fn test_board_initialization() {
        let board = Board::new(8, 8);
        assert_eq!(board.width, 8);
        assert_eq!(board.height, 8);
        assert_eq!(board.grid.len(), 8);
        assert_eq!(board.grid[0].len(), 8);
    }

    #[test]
    fn test_valid_coordinates() {
        let board = Board::new(8, 8);
        assert!(board.is_valid_position(0, 0));
        assert!(board.is_valid_position(7, 7));
        assert!(!board.is_valid_position(8, 8));
        assert!(!board.is_valid_position(255, 255)); // Test underflow
    }

    #[test]
    fn test_terrain_height_modification() {
        let mut board = Board::new(8, 8);
        board.set_height(3, 3, 2);
        assert_eq!(board.get_height(3, 3), 2);
    }
}
```

#### Movement Validation Tests
```rust
#[cfg(test)]
mod movement_tests {
    use super::*;

    #[test]
    fn test_basic_movement_rules() {
        let board = Board::new(8, 8);
        
        // Test horizontal movement
        assert!(is_valid_move((0, 0), (0, 1), &board));
        assert!(is_valid_move((0, 0), (1, 0), &board));
        
        // Test invalid diagonal movement (should fail in basic rules)
        assert!(!is_valid_move((0, 0), (1, 1), &board));
        
        // Test out of bounds
        assert!(!is_valid_move((7, 7), (8, 7), &board));
    }

    #[test]
    fn test_height_movement_restrictions() {
        let mut board = Board::new(8, 8);
        board.set_height(1, 0, 2); // Raise destination
        board.set_height(0, 0, 0); // Keep source low
        
        // Can move up one level
        board.set_height(1, 0, 1);
        assert!(is_valid_move((0, 0), (1, 0), &board));
        
        // Cannot move up two levels
        board.set_height(1, 0, 2);
        assert!(!is_valid_move((0, 0), (1, 0), &board));
        
        // Can always move down
        board.set_height(0, 0, 3);
        board.set_height(1, 0, 0);
        assert!(is_valid_move((0, 0), (1, 0), &board));
    }

    #[test]
    fn test_occupied_tile_blocking() {
        let mut board = Board::new(8, 8);
        board.place_piece(1, 0, GamePiece { player: PlayerId(2), powers: vec![] });
        
        // Cannot move to occupied tile of same player
        assert!(!can_move_to_tile((0, 0), (1, 0), &board, PlayerId(2)));
        
        // Can capture opponent piece
        assert!(can_move_to_tile((0, 0), (1, 0), &board, PlayerId(1)));
    }
}
```

#### Turn Management Tests
```rust
#[cfg(test)]
mod turn_tests {
    use super::*;

    #[test]
    fn test_turn_alternation() {
        let mut game_state = GameState::PlayerTurn(PlayerId(1));
        
        end_turn(&mut game_state);
        
        match game_state {
            GameState::PlayerTurn(player) => assert_eq!(player.0, 2),
            _ => panic!("Expected PlayerTurn state"),
        }
    }

    #[test]
    fn test_invalid_turn_actions() {
        let game_state = GameState::PlayerTurn(PlayerId(1));
        
        // Player 2 cannot move during Player 1's turn
        let result = attempt_move(&game_state, PlayerId(2), (0, 0), (0, 1));
        assert!(result.is_err());
    }
}
```

### Phase 2: Power-Up Testing
**Test power-up mechanics systematically:**

#### Power Collection Tests
```rust
#[cfg(test)]
mod power_tests {
    use super::*;

    #[test]
    fn test_power_orb_spawning() {
        let mut board = Board::new(8, 8);
        let mut rng = thread_rng();
        
        spawn_power_orb(&mut board, &mut rng);
        
        let orb_count = board.count_power_orbs();
        assert_eq!(orb_count, 1);
    }

    #[test]
    fn test_power_collection() {
        let mut piece = GamePiece { player: PlayerId(1), powers: vec![] };
        let power = PowerUp { power_type: PowerType::MoveDiagonal, uses_remaining: 1 };
        
        piece.collect_power(power);
        
        assert_eq!(piece.powers.len(), 1);
        assert_eq!(piece.powers[0].power_type, PowerType::MoveDiagonal);
    }

    #[test]
    fn test_power_activation() {
        let mut piece = GamePiece { 
            player: PlayerId(1), 
            powers: vec![PowerUp { power_type: PowerType::MoveDiagonal, uses_remaining: 1 }]
        };
        
        let result = piece.activate_power(PowerType::MoveDiagonal);
        
        assert!(result.is_ok());
        assert!(piece.powers.is_empty()); // Single-use power consumed
    }
}
```

#### Specific Power Effect Tests
```rust
#[test]
fn test_move_diagonal_power() {
    let mut board = Board::new(8, 8);
    let mut piece = create_test_piece_with_power(PowerType::MoveDiagonal);
    
    // Activate power
    piece.activate_power(PowerType::MoveDiagonal).unwrap();
    
    // Should now allow diagonal movement
    assert!(can_move_diagonal(&piece, (0, 0), (1, 1), &board));
}

#[test]
fn test_raise_column_power() {
    let mut board = Board::new(8, 8);
    let original_height = board.get_height(3, 3);
    
    activate_raise_column_power(&mut board, 3);
    
    // All tiles in column 3 should be raised by 1
    for row in 0..8 {
        assert_eq!(board.get_height(3, row), original_height + 1);
    }
}
```

### Phase 3: Integration Testing
**Test system interactions:**

```rust
#[cfg(test)]
mod integration_tests {
    use super::*;

    #[test]
    fn test_complete_turn_cycle() {
        let mut game = create_test_game();
        
        // Player 1 moves
        game.move_piece(PlayerId(1), (0, 0), (0, 1)).unwrap();
        assert_eq!(game.current_player(), PlayerId(2));
        
        // Player 2 moves
        game.move_piece(PlayerId(2), (7, 7), (7, 6)).unwrap();
        assert_eq!(game.current_player(), PlayerId(1));
    }

    #[test]
    fn test_power_and_move_combination() {
        let mut game = create_test_game();
        let piece_id = game.get_piece_at(0, 0).unwrap();
        
        // Give piece a power
        game.add_power_to_piece(piece_id, PowerType::MoveDiagonal);
        
        // Activate power and move in same turn
        game.activate_power(piece_id, PowerType::MoveDiagonal).unwrap();
        game.move_piece(PlayerId(1), (0, 0), (1, 1)).unwrap();
        
        // Verify piece moved diagonally
        assert!(game.get_piece_at(1, 1).is_some());
        assert!(game.get_piece_at(0, 0).is_none());
    }

    #[test]
    fn test_win_condition_detection() {
        let mut game = create_test_game();
        
        // Remove all pieces except one for each player
        game.remove_all_pieces_except_one();
        
        // Capture last opponent piece
        game.move_piece(PlayerId(1), (3, 3), (4, 4)).unwrap(); // Capture
        
        assert_eq!(game.get_winner(), Some(PlayerId(1)));
        assert_eq!(game.get_state(), GameState::GameOver(PlayerId(1)));
    }
}
```

---

## Test Organization Structure

### Recommended Directory Structure
```
src/
├── lib.rs
├── main.rs
├── components/
│   ├── mod.rs
│   ├── board.rs
│   ├── piece.rs           
│   └── power.rs
├── systems/
│   ├── mod.rs
│   ├── movement.rs
│   ├── powers.rs
│   └── ui.rs
└── tests/
    ├── integration/
    │   ├── mod.rs
    │   ├── game_flow.rs
    │   ├── power_combinations.rs
    │   └── edge_cases.rs
    ├── unit/
    │   ├── mod.rs
    │   ├── board_tests.rs
    │   ├── movement_tests.rs
    │   ├── power_tests.rs
    │   └── turn_tests.rs
    └── helpers/
        ├── mod.rs
        ├── test_builders.rs
        └── mock_data.rs
```

### Test Helper Functions
```rust
// tests/helpers/test_builders.rs
pub fn create_test_game() -> Game {
    Game::new_with_config(TestConfig::default())
}

pub fn create_test_board() -> Board {
    Board::new(8, 8)
}

pub fn create_test_piece_with_power(power: PowerType) -> GamePiece {
    GamePiece {
        player: PlayerId(1),
        powers: vec![PowerUp { power_type: power, uses_remaining: 1 }],
    }
}

pub fn setup_board_with_pieces() -> Board {
    let mut board = Board::new(8, 8);
    // Add standard starting positions
    for col in 0..8 {
        board.place_piece(0, col, create_player_piece(PlayerId(1)));
        board.place_piece(7, col, create_player_piece(PlayerId(2)));
    }
    board
}
```

---

## Testing Best Practices for Quadradius

### Do's
1. **Test Each Phase Thoroughly**: Complete Phase 1 tests before moving to Phase 2
2. **Use Descriptive Test Names**: `test_cannot_move_up_more_than_one_level`
3. **Test Edge Cases**: Boundary conditions, empty states, full inventories
4. **Mock External Dependencies**: Use test doubles for random number generation
5. **Keep Tests Independent**: Each test should set up its own state
6. **Test Error Conditions**: Verify proper error handling for invalid moves

### Don'ts
1. **Don't Test Bevy Internals**: Focus on your game logic, not engine code
2. **Don't Write Flaky Tests**: Avoid time-dependent or randomly failing tests
3. **Don't Skip Negative Tests**: Test that invalid operations properly fail
4. **Don't Test Implementation Details**: Test behavior, not internal structure
5. **Don't Write Overly Complex Tests**: Keep tests simple and focused

### Performance Testing
```rust
#[cfg(test)]
mod performance_tests {
    use super::*;
    use std::time::Instant;

    #[test]
    #[ignore] // Run separately with --ignored
    fn test_board_operations_performance() {
        let mut board = Board::new(8, 8);
        let start = Instant::now();
        
        // Perform 1000 operations
        for _ in 0..1000 {
            board.set_height(0, 0, 1);
            board.get_height(0, 0);
        }
        
        let duration = start.elapsed();
        assert!(duration.as_millis() < 100, "Board operations too slow: {:?}", duration);
    }
}
```

---

## Continuous Integration Testing

### GitHub Actions Configuration
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
        override: true
    - name: Run tests
      run: cargo test --verbose
    - name: Run clippy
      run: cargo clippy -- -D warnings
    - name: Check formatting
      run: cargo fmt -- --check
```

### Test Coverage
```bash
# Install cargo-tarpaulin
cargo install cargo-tarpaulin

# Generate coverage report
cargo tarpaulin --out Html --output-dir coverage/
```

---

## Testing Checklist by Phase

### Phase 1 Testing Checklist
- [ ] Board initialization and coordinate validation
- [ ] Basic piece movement (horizontal/vertical only)
- [ ] Terrain height movement restrictions
- [ ] Turn alternation between players  
- [ ] Piece capture mechanics
- [ ] Win condition detection
- [ ] Invalid move rejection
- [ ] Boundary condition handling

### Phase 2 Testing Checklist
- [ ] Power orb spawning system
- [ ] Power collection mechanics
- [ ] Power activation framework
- [ ] Each of the 5 initial powers individually
- [ ] Power effect combinations
- [ ] Power inventory management
- [ ] Turn phase transitions (power → move → end)

### Phase 3 Testing Checklist
- [ ] All remaining power implementations
- [ ] Complex power interactions
- [ ] Power balance verification
- [ ] Edge cases with multiple active powers
- [ ] Performance with many active effects

This comprehensive testing strategy ensures that each phase of development is thoroughly validated before proceeding to the next, maintaining high code quality and preventing regressions throughout the Quadradius development process.
