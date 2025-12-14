---
description: "Analyze and improve Claude Code implementations with focus on commands and sub-agents"
argument-hint: "<command_name> [--cross-system]"
---

Analyzes Claude Code command implementations to identify improvement opportunities, architectural patterns, and integration enhancements. Focuses on command structure, sub-agent coordination, and cross-system optimization.

**Sequential Analysis Approach**: 
- **Phase 1**: Command structure analysis and architecture assessment
- **Phase 2**: Individual sub-agent analysis and optimization recommendations  
- **Phase 3**: Integration pattern evaluation and improvement suggestions

**Analysis Scope**:
- Command implementation patterns and effectiveness
- Sub-agent coordination and Task tool usage patterns
- Extended context integration and optimization opportunities
- Cross-system comparison when `--cross-system` flag is used

Use the claude-sdk-architect subagent to analyze the specified command implementation with comprehensive architectural assessment, focusing on one command at a time to prevent system overload and ensure detailed analysis.

**Critical**: Sequential processing prevents resource conflicts and ensures focused analysis of each component. The `--cross-system` flag enables comparison across multiple Claude Code implementations for pattern identification.

**Output**: Detailed analysis with specific improvement recommendations, architectural insights, and integration enhancement opportunities.