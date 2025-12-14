# Quadradius Development Standards and Conventions

## Project Overview
This document defines the development standards and conventions for the Quadradius game recreation project. These standards ensure consistency, maintainability, and quality across all development work.

## Code Quality Standards

### Rust Language Standards
**Idiomatic Rust Practices**:
- Use `cargo clippy` and address all warnings before commits
- Follow Rust naming conventions (snake_case for functions/variables, PascalCase for types)
- Use `Result<T, E>` for error handling, avoid `unwrap()` in production code
- Prefer explicit error handling over panicking
- Use `#[derive]` macros appropriately for common traits
- Follow borrowing rules and minimize unnecessary clones

**Code Organization**:
```
Standard Module Structure:
├── src/components/ - ECS component definitions
├── src/systems/ - ECS system implementations
├── src/resources/ - Global resources and state
├── src/events/ - Event definitions and handling
└── tests/ - Comprehensive test suite
```

### Bevy ECS Patterns
**Component Design**:
- Components should be simple data containers
- Use marker components for tags and states
- Avoid complex logic in component definitions
- Implement `Debug`, `Clone`, and other derive macros as appropriate

**System Implementation**:
- Systems should have single, clear responsibilities
- Use query filters effectively to target specific entities
- Minimize system dependencies and coupling
- Use system sets for proper execution ordering

**Resource Management**:
- Resources should represent global state only
- Use events for communication between systems
- Avoid mutable resource conflicts between systems

## Testing Standards

### Test-Driven Development (TDD)
**Testing Methodology**:
1. **Write Tests First**: Always write tests before implementing functionality
2. **Red-Green-Refactor**: Ensure tests fail, make them pass, then refactor
3. **Comprehensive Coverage**: Test normal cases, edge cases, and error conditions
4. **Integration Testing**: Test system interactions and end-to-end scenarios

**Test Organization**:
```rust
// Unit Tests - in same file as implementation
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_specific_functionality() {
        // Arrange
        // Act  
        // Assert
    }
}

// Integration Tests - in tests/ directory
#[test]
fn integration_test_name() {
    // Test system interactions
}
```

**Required Test Categories**:
- **Unit Tests**: Individual function/component behavior
- **Integration Tests**: System interaction testing
- **Performance Tests**: Frame rate and memory validation
- **Edge Case Tests**: Boundary conditions and error scenarios

### Performance Requirements
**Frame Rate Standards**:
- **Target**: 60+ FPS consistently maintained
- **Measurement**: Use built-in Bevy diagnostics for monitoring
- **Validation**: Performance tests must validate frame rate under load
- **Optimization**: Profile code when performance targets aren't met

**Memory Management**:
- **Target**: <200MB memory usage during normal gameplay
- **Leak Prevention**: Use Rust's ownership system to prevent memory leaks
- **Resource Cleanup**: Properly dispose of resources when no longer needed
- **Allocation Patterns**: Minimize allocations in hot code paths

## Power System Architecture

### Power Implementation Patterns
**Power Type Definition**:
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PowerType {
    // Terrain modification powers
    LowerTile,
    RaiseTile,
    Flatten,
    // ... other power types
}
```

**Power Effect System**:
```rust
pub fn handle_power_activation(
    mut commands: Commands,
    mut power_events: EventReader<PowerActivationEvent>,
    // ... other parameters
) {
    for event in power_events.iter() {
        match event.power_type {
            PowerType::LowerTile => handle_lower_tile(/* parameters */),
            // ... other power handlers
        }
    }
}
```

**Testing Pattern for Powers**:
```rust
#[test]
fn test_power_name() {
    let mut world = World::new();
    setup_test_world(&mut world);
    
    // Arrange - Set up test scenario
    let piece = spawn_test_piece(&mut world, position);
    add_power_to_piece(&mut world, piece, PowerType::TestPower);
    
    // Act - Activate power
    activate_power(&mut world, piece, PowerType::TestPower, target);
    
    // Assert - Verify expected outcome
    assert_expected_result(&world);
}
```

## Visual Standards

### 3D Rendering Requirements
**Isometric View Standards**:
- Maintain consistent perspective angle throughout game
- Ensure depth sorting works correctly for all visual elements
- Use appropriate lighting to show terrain height and construction
- Visual effects should enhance clarity, not obscure gameplay

**Visual Feedback Requirements**:
- **Immediate**: User actions receive immediate visual response
- **Clear**: Visual changes clearly communicate game state modifications
- **Consistent**: Similar actions have consistent visual representations
- **Accessible**: Visual elements are distinguishable for color-blind users

### UI/UX Standards
**Interface Design**:
- Maintain clean, uncluttered interface design
- Provide clear visual hierarchy for game information
- Use consistent color schemes and visual elements
- Ensure all interactive elements provide clear feedback

## Documentation Standards

### Code Documentation
**Inline Documentation**:
```rust
/// Brief description of function purpose
/// 
/// # Arguments
/// * `parameter` - Description of parameter
/// 
/// # Returns
/// Description of return value
/// 
/// # Examples
/// ```
/// let result = function_name(parameter);
/// ```
pub fn function_name(parameter: Type) -> ReturnType {
    // Implementation
}
```

**Module Documentation**:
- Each module should have clear purpose description
- Document public APIs comprehensively
- Include usage examples where appropriate
- Document any non-obvious implementation decisions

### Architecture Documentation
**System Interactions**:
- Document how systems interact with each other
- Explain event flow and data dependencies
- Describe resource sharing and access patterns
- Document performance considerations

## Version Control Standards

### Commit Message Format
```
type(scope): brief description

Longer description if needed explaining what and why,
not how.

Fixes #issue-number
```

**Commit Types**:
- `feat`: New feature implementation
- `fix`: Bug fix
- `refactor`: Code refactoring without functionality change
- `test`: Adding or modifying tests
- `docs`: Documentation changes
- `perf`: Performance improvements

### Branch Management
**Branch Naming**:
- `feature/power-name` - New power implementations
- `fix/issue-description` - Bug fixes
- `refactor/system-name` - Code refactoring
- `test/test-category` - Test improvements

## Quality Gates

### Pre-Commit Requirements
1. **All tests pass**: `cargo test` must pass 100%
2. **No clippy warnings**: `cargo clippy` must report no issues
3. **Code formatted**: `cargo fmt` must be applied
4. **Performance validated**: Frame rate tests must pass

### Pre-Merge Requirements
1. **Code review completed**: Peer review of all changes
2. **Integration tests pass**: Full test suite validation
3. **Documentation updated**: All relevant documentation current
4. **No regressions**: Existing functionality unaffected

## Error Handling Patterns

### Result Type Usage
```rust
// Prefer Result<T, E> over Option<T> when operation can fail
pub fn validate_move(position: BoardPosition) -> Result<(), MoveError> {
    if !is_valid_position(position) {
        return Err(MoveError::InvalidPosition(position));
    }
    Ok(())
}
```

### Error Type Definition
```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PowerError {
    InvalidTarget(BoardPosition),
    InsufficientRange,
    PowerNotAvailable,
}
```

These standards ensure consistent, high-quality development across all Quadradius implementation phases.