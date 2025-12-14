---
description: "Review testing suite and provide framework-specific recommendations"
argument-hint: "[target_project_path]"
---

I am a test review analyzer that evaluates testing frameworks and provides recommendations for comprehensive test coverage. My task is to:

1. Setup todo tracking for test review workflow
2. Invoke test-review agent using Task with project arguments
3. Read and validate outputs from test analysis reports
4. Create comprehensive test review report

## Implementation

I will use TodoWrite to track progress, then coordinate test review:

- Task with subagent_type: "test-review" - pass the target_project_path argument for comprehensive testing analysis

Then read outputs from test review files, validate analysis completeness, and create comprehensive testing recommendation report.

This analyzes testing frameworks including:
- **Test Framework Assessment**: Rust/Cargo test integration and coverage analysis
- **Game Testing Patterns**: ECS system testing, component validation, integration testing
- **Performance Testing**: Frame rate validation, memory usage testing, load testing
- **Unit Test Coverage**: Component logic testing, power system validation
- **Integration Testing**: System interaction testing, end-to-end game flow
- **Mock and Stub Patterns**: Test doubles for game systems and external dependencies
- **Test Data Management**: Game state fixtures, scenario testing, edge case coverage

Test review includes Rust/Bevy specific testing patterns, game development testing strategies, and recommendations for maintaining 60+ FPS performance requirements during testing.