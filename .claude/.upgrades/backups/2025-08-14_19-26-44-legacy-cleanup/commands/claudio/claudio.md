# /claudio:claudio Command

Complete Quadradius project analysis and workflow setup command that creates comprehensive project documentation and task organization.

## Usage
```bash
/claudio:claudio [target_directory]
```

## Description
Executes a complete project analysis workflow for the Quadradius game project, creating comprehensive documentation including discovery analysis, requirements documentation, implementation planning, and task organization. This command is optimized for Rust/Bevy game development projects.

## Project Context
This command is specialized for the Quadradius project - a sophisticated turn-based strategy game built with Rust and Bevy engine that recreates the 2007 Flash game "Quadradius" with 70+ power-ups, 3D isometric rendering, and advanced game mechanics.

## Workflow Steps
1. **Discovery Analysis**: Analyze project structure, technology stack (Rust/Bevy), and current implementation status
2. **Requirements Generation**: Create comprehensive PRD based on game mechanics and technical requirements
3. **Implementation Planning**: Generate phase-based development plan aligned with existing project structure
4. **Task Organization**: Break down implementation into executable tasks with clear acceptance criteria
5. **Documentation Creation**: Generate comprehensive project documentation and guides
6. **Quality Validation**: Ensure all generated documents meet project standards

## Output Structure
Creates `.claudio/` directory with:
- **`docs/`**: Discovery analysis, PRD, implementation plan, executive summary
- **`phase1/, phase2/, etc.`**: Task breakdown organized by development phases
- **`status.md`**: Progress tracking and workflow status

## Integration with Existing Project
This command recognizes and integrates with existing project structure:
- Existing research documentation in `research/`
- Phase-based development structure in `features/`
- Implementation status tracking in `instructions/`
- Test-driven development approach with comprehensive test suite

## Target Artifacts
- Comprehensive project discovery and technology analysis
- Product Requirements Document with game mechanics specifications
- Phase-based implementation plan with 8 development phases
- Executable task lists with acceptance criteria and context
- Quality assessment and validation workflow

## Prerequisites
- Target directory must contain a recognizable project structure
- Project should have source code or documentation to analyze
- Claudio system must be properly installed

## Example
```bash
/claudio:claudio ./quadradius-game
# Creates complete .claudio/ structure for Quadradius game project
```

This command transforms the existing Quadradius codebase into an organized, trackable development process with clear next steps and comprehensive documentation.