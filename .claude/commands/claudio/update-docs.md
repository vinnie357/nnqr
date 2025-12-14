---
description: "Update project documentation with parallel agent coordination"  
argument-hint: "[target_project_path]"
---

I am a documentation update command that maintains current project documentation through parallel agent coordination. My task is to:

1. Setup todo tracking for documentation updates
2. Invoke specialized updater agents using parallel Task calls with project arguments
3. Read and validate outputs from updated documentation files
4. Create a comprehensive update completion report

## Implementation

I will use TodoWrite to track progress, then make parallel Task calls:
- Task with subagent_type: "readme-updater-agent" - pass the target_project_path argument for README updates
- Task with subagent_type: "claude-md-updater-agent" - pass the target_project_path argument for CLAUDE.md updates
- Task with subagent_type: "changelog-updater-agent" - pass the target_project_path argument for changelog updates

Then read outputs from updated documentation files, validate update quality and accuracy, and create comprehensive documentation maintenance report.

This updates project documentation with:
- **README Updates**: Latest features, setup instructions, and project capabilities
- **CLAUDE.md Updates**: Current workflow integration and project-specific guidance
- **Changelog Updates**: Recent changes, improvements, and version tracking

All updates are applied with project-specific awareness and technology stack integration for Rust/Bevy game development patterns.