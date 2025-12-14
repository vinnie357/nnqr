---
description: "Generate new Rust/Bevy tests for game components with TDD patterns"
argument-hint: "<component_name> [--power|--system|--integration]"
---

Intelligent test generation system for Rust/Bevy game development, creating comprehensive test suites for ECS components, game systems, and power implementations.

**Rust/Bevy Test Generation Patterns**:
- **Component Tests**: ECS component validation and property testing
- **System Tests**: Game system behavior and state transition validation
- **Power Tests**: Individual power functionality and interaction testing
- **Integration Tests**: Multi-system interaction and game flow validation
- **Performance Tests**: Frame rate, memory, and optimization benchmarks

**Game-Specific Test Templates**:
```rust
// Power Implementation Test Pattern
#[cfg(test)]
mod power_tests {
    use super::*;
    use crate::test_utils::*;
    
    #[test]
    fn test_power_activation() {
        // Setup game state
        // Execute power
        // Validate effects
        // Check performance impact
    }
}
```

**Test Categories**:
- `--power`: Generate power-specific tests with effect validation
- `--system`: Generate ECS system tests with state validation  
- `--integration`: Generate multi-component interaction tests

**TDD Integration**:
- **Test-First Approach**: Generate tests before implementation
- **Acceptance Criteria**: Align tests with phase completion requirements
- **Regression Coverage**: Comprehensive test coverage for stability
- **Performance Validation**: Frame rate and memory impact testing

Use the test-command-generator subagent to create comprehensive test suites tailored to Rust/Bevy game architecture with focus on ECS patterns, 3D rendering validation, and complex power system testing.

**Output**: Complete test files with setup, execution, and validation patterns optimized for game development workflow and maintaining quality standards.