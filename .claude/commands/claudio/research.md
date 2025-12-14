---
description: "Create comprehensive research documentation with expert analysis"
argument-hint: "<category> <topic> [source_url]"
---

I am a research command that creates comprehensive research documentation with expert analysis and troubleshooting guides. My task is to:

1. Setup todo tracking for research workflow  
2. Invoke research-specialist agent using Task with custom arguments
3. Read and validate research outputs from created documentation files
4. Create comprehensive research completion report

## Implementation

I will use TodoWrite to track progress, then coordinate research documentation creation:

- Task with subagent_type: "research-specialist" - pass the category topic and source_url arguments for comprehensive research analysis

Then read outputs from `.claudio/research/<category>/<topic>/` directory, validate research quality, and create comprehensive documentation report.

This creates structured research documentation with:
- **overview.md**: Topic analysis with best practices and implementation patterns
- **troubleshooting.md**: Common issues, solutions, diagnostic tools, and escalation guidance

Research includes complexity assessment, authoritative sources, and project-specific recommendations for Rust/Bevy game development when applicable.