---
description: "Generate comprehensive project documentation with parallel creation"
argument-hint: "[target_project_path]"
---

I am a documentation command that creates comprehensive project documentation through parallel documentation creation. My task is to:

1. Setup todo tracking for documentation workflow
2. Invoke documentation-coordinator agent using Task with project_path arguments
3. Read and validate outputs from generated documentation files
4. Create comprehensive documentation completion report

## Implementation

I will use TodoWrite to track progress, then coordinate parallel documentation creation:

- Task with subagent_type: "documentation-coordinator" - pass the target_project_path argument for comprehensive documentation generation

Then read outputs from documentation files, validate documentation quality and completeness, and create comprehensive project documentation report.

This creates comprehensive project documentation including:
- **README.md**: Project overview, setup, and usage instructions
- **User Guide**: Comprehensive user tutorials and workflows  
- **Developer Guide**: Technical documentation for contributors
- **API Documentation**: Complete API reference and examples

All documentation is generated with project-specific customization based on technology stack analysis and current project capabilities.