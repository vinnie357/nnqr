---
description: "Run Rust/Bevy game tests with comprehensive coverage and performance validation"
argument-hint: "[test_pattern] [--watch|--coverage|--performance]"
---

Comprehensive test runner optimized for Rust/Bevy game development with focus on ECS systems, 3D rendering, and game mechanics validation.

**Rust/Bevy Test Categories**:
- **Unit Tests**: Component and system logic validation
- **Integration Tests**: ECS system interaction testing  
- **Game Logic Tests**: Power system, board mechanics, and game state validation
- **Rendering Tests**: 3D isometric view, depth sorting, and visual validation
- **Performance Tests**: Frame rate, memory usage, and optimization validation

**Test Execution Patterns**:
```bash
cargo test                           # Run all tests
cargo test power_tests               # Specific test module
cargo test --test integration       # Integration tests only
cargo test --release               # Optimized performance testing
```

**Development Workflow Integration**:
- **TDD Focus**: Test-first development approach for new powers and mechanics
- **Phase Validation**: Test requirements for phase completion criteria
- **Regression Prevention**: Comprehensive test coverage prevents power interaction bugs
- **Performance Monitoring**: Frame rate and memory validation during development

**Options**:
- `--watch`: Continuous testing during development
- `--coverage`: Generate test coverage reports with tarpaulin
- `--performance`: Run performance benchmarks and frame rate validation

Execute comprehensive Rust/Bevy test suite with game-specific validation patterns, focusing on ECS architecture, 3D rendering systems, and complex power interaction testing.

**Critical**: Maintains 60+ FPS performance requirements during testing and validates all power implementations against original game specifications.