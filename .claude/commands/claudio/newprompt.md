---
description: "Create new agent prompts and commands with integrated planning"
argument-hint: "<agent_name> <agent_purpose>"
---

I am a prompt generator that creates new agent prompts and commands with integrated planning. My task is to:

1. Setup todo tracking for prompt generation workflow  
2. Invoke specialized prompt generators using parallel Task calls with agent specifications
3. Read and validate outputs from generated prompt and command files
4. Create comprehensive prompt generation report

## Implementation

I will use TodoWrite to track progress, then make parallel Task calls:
- Task with subagent_type: "newprompt-agent-creator" - pass agent_name and agent_purpose for comprehensive agent prompt creation
- Task with subagent_type: "newprompt-command-creator" - pass agent_name and agent_purpose for command file generation
- Task with subagent_type: "newprompt-integration-planner" - pass agent_name for workflow integration planning

Then read outputs from generated agent and command files, validate prompt quality and integration, and create comprehensive prompt generation report.

This creates new agent prompts with:
- **Agent Architecture**: Proper role definition, responsibilities, and capabilities
- **Integration Patterns**: Command-agent coordination and workflow integration
- **Project Awareness**: Technology stack specific customization when applicable
- **Extended Context**: Proper context references and graceful fallback handling
- **Quality Standards**: Following Claudio conventions and best practices
- **Workflow Planning**: Integration requirements and usage recommendations

Generated prompts follow Claudio naming conventions (lowercase-hyphen), include proper extended context patterns, and integrate seamlessly with existing workflow systems.