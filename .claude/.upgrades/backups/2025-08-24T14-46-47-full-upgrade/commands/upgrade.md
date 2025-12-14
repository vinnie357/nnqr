---
description: "Parallel upgrade system using specialized subagents for improved performance"
argument-hint: "<target_project_path> [--check|--force]"
---

Advanced parallel upgrade system that orchestrates 6 specialized subagents for efficient Claudio installation updates. Uses batch parallel execution to minimize upgrade time while maintaining safety guarantees.

**Parallel Architecture**:
- **Phase 0**: Sequential foundation (discovery analysis, legacy cleanup)
- **Phase 1**: Parallel validation (installation analysis + backup creation)  
- **Phase 2**: Parallel processing (template analysis + component localization)
- **Phase 3**: Parallel completion (installation validation + final coordination)

**Specialized Subagents**:
- `upgrade-discovery-analyzer`: Installation analysis and compatibility assessment
- `upgrade-legacy-cleaner`: Deprecated pattern cleanup with user content protection
- `upgrade-template-analyzer`: Localization planning and conflict detection
- `upgrade-backup-manager`: Backup creation and rollback script generation
- `upgrade-component-localizer`: Project-specific template application and test command coordination
- `upgrade-installation-validator`: Integrity verification and completion reporting

**Options**:
- `--check`: Preview upgrade changes without applying modifications
- `--force`: Force complete re-installation with full project re-discovery

Use the upgrade-coordinator-agent subagent to orchestrate the complete parallel upgrade workflow with safety guarantees and performance optimization.

**Performance**: 3-4x faster than sequential processing through batch parallel execution while maintaining complete safety and rollback capabilities.

**Safety**: Each phase includes validation checkpoints with automatic rollback capabilities for any critical failures during the upgrade process.