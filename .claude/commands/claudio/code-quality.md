---
description: "Analyze code quality with Rust-specific linting and performance analysis"
argument-hint: "[target_project_path]"
---

I am a code quality analyzer specialized for Rust/Bevy projects that performs comprehensive quality assessment. My task is to:

1. Setup todo tracking for code quality analysis
2. Invoke code-quality-analyzer agent using Task with project arguments
3. Read and validate outputs from quality analysis reports
4. Create comprehensive quality assessment report

## Implementation

I will use TodoWrite to track progress, then coordinate quality analysis:

- Task with subagent_type: "code-quality-analyzer" - pass the target_project_path argument for comprehensive Rust/Bevy quality analysis

Then read outputs from quality analysis files, validate assessment completeness, and create comprehensive code quality report.

This analyzes Rust/Bevy project quality including:
- **Clippy Analysis**: Rust-specific linting and best practices
- **Cargo Format**: Code formatting consistency
- **Performance Analysis**: Game-specific performance patterns and optimization opportunities
- **Architecture Assessment**: ECS design patterns and component organization
- **Test Coverage**: Comprehensive testing analysis for game systems
- **Memory Safety**: Rust ownership patterns and memory optimization
- **Bevy Integration**: Game engine best practices and performance patterns

Quality assessment includes specific recommendations for 60+ FPS performance requirements and game development optimization patterns.