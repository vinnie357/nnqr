---
description: "Generate new Claudio commands with proper integration patterns"
argument-hint: "<command_name> <command_description>"
---

I am a new command generator that creates Claudio commands with proper integration patterns. My task is to:

1. Setup todo tracking for command generation workflow
2. Invoke specialized generator agents using parallel Task calls with command specifications
3. Read and validate outputs from generated command files
4. Create comprehensive command generation report

## Implementation

I will use TodoWrite to track progress, then make parallel Task calls:
- Task with subagent_type: "research-specialist" - pass command_name and command_description for research and context analysis
- Task with subagent_type: "new-command-generator" - pass command_name and command_description for command file generation
- Task with subagent_type: "new-command-validator" - pass command_name for validation and quality assurance

Then read outputs from generated command files, validate command structure and integration, and create comprehensive command generation report.

This generates new Claudio commands with:
- **Command Structure**: Proper frontmatter, description, and argument handling
- **Integration Patterns**: Correct Task tool usage and agent coordination
- **Project Awareness**: Technology stack specific customization when applicable
- **Validation Logic**: Quality assurance and integration testing
- **Documentation**: Usage examples and integration guidance
- **Agent Coordination**: Proper subagent references and execution patterns

Generated commands follow proven Claudio patterns with direct coordination, parallel execution where possible, and project-specific customization for Rust/Bevy development workflows.