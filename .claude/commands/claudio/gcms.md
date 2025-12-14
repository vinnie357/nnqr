---
description: "Generate intelligent Git commit messages from staged changes"
argument-hint: "[target_project_path]"
---

I am a Git commit message generator that creates intelligent, conventional commits from staged changes. My task is to:

1. Setup todo tracking for commit message generation
2. Invoke git-commit-message agent using Task with project arguments
3. Read and validate generated commit message quality
4. Create comprehensive commit message generation report

## Implementation

I will use TodoWrite to track progress, then coordinate commit message generation:

- Task with subagent_type: "git-commit-message" - pass the target_project_path argument for intelligent commit message generation

Then read outputs from commit message analysis, validate message quality and conventional format compliance, and create comprehensive commit documentation.

This generates intelligent commit messages including:
- **Conventional Commits**: Standard format with type, scope, and description
- **Change Analysis**: Staged file analysis and impact assessment
- **Context Understanding**: Project-aware commit message generation
- **Rust/Bevy Awareness**: Game development specific commit patterns
- **Scope Detection**: Automatic scope identification (game, powers, ui, tests)
- **Breaking Changes**: Detection and documentation of breaking changes
- **Issue References**: Integration with issue tracking and project management

Commit messages follow conventional commit standards with game development specific scopes and Rust/Bevy project awareness.