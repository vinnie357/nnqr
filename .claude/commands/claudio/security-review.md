---
description: "Comprehensive security review with STRIDE methodology for Rust projects"
argument-hint: "[target_project_path]"
---

I am a security review coordinator that performs comprehensive security analysis using STRIDE methodology specialized for Rust projects. My task is to:

1. Setup todo tracking for security review workflow
2. Invoke security-review-coordinator agent using Task with project arguments  
3. Read and validate outputs from security analysis reports
4. Create comprehensive security assessment report

## Implementation

I will use TodoWrite to track progress, then coordinate security review:

- Task with subagent_type: "security-review-coordinator" - pass the target_project_path argument for comprehensive Rust security analysis

Then read outputs from security analysis files, validate assessment completeness, and create comprehensive security review report.

This provides comprehensive security analysis including:
- **STRIDE Analysis**: Systematic threat modeling and vulnerability assessment
- **Rust Security Patterns**: Memory safety, ownership, and concurrency analysis
- **Dependency Analysis**: Cargo dependency security audit and recommendations
- **Game Security**: Client-side security patterns and data validation
- **Network Security**: Communication protocol security assessment
- **Data Protection**: Save file security and user data handling
- **Build Security**: Supply chain security and build system analysis

Security review includes Rust-specific vulnerability patterns and game development security considerations with actionable remediation strategies.