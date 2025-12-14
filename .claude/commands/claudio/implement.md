---
description: "Execute implementation plans with task coordination and validation"
argument-hint: "[target_project_path]"
---

I am an implementation executor that coordinates task execution and validates implementation completion. My task is to:

1. Setup todo tracking for implementation workflow
2. Invoke implement-agent using Task with project arguments
3. Read and validate outputs from implementation progress files
4. Create comprehensive implementation completion report

## Implementation

I will use TodoWrite to track progress, then coordinate implementation execution:

- Task with subagent_type: "implement-agent" - pass the target_project_path argument for task execution and progress tracking

Then read outputs from implementation files, validate task completion and test results, and create comprehensive implementation report.

This coordinates implementation execution including:
- **Task Validation**: Verify task prerequisites and acceptance criteria
- **Progress Tracking**: Monitor implementation progress and status updates
- **Test Integration**: Ensure all implementation includes comprehensive testing
- **Quality Gates**: Validate code quality, performance, and integration requirements
- **Documentation Updates**: Maintain current implementation documentation
- **Error Recovery**: Handle implementation issues and provide recovery guidance

Implementation execution includes Rust/Bevy specific patterns, game development workflows, and integration with Phase 3 active development requirements.