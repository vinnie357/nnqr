# /claudio:discovery Command

Analyzes Quadradius project structure, technology stack, and current capabilities to create comprehensive project discovery documentation.

## Usage
```bash
/claudio:discovery [target_directory]
```

## Description
Performs deep analysis of the Quadradius project, examining the Rust/Bevy codebase, understanding the current implementation status, and documenting project capabilities, architecture patterns, and development context.

## Project-Specific Analysis
This command is optimized for the Quadradius project and analyzes:

### Technology Stack
- **Rust**: Systems programming language with Cargo build system
- **Bevy Engine**: Modern ECS game engine with 3D rendering capabilities
- **Game Architecture**: Turn-based strategy game with isometric 3D view
- **Cross-Platform**: Linux development with Windows deployment pipeline

### Game Architecture Analysis
- **ECS Components**: Board, pieces, powers, UI elements
- **Game Systems**: Movement, combat, power effects, turn management
- **Resource Management**: Game state, visual effects, themes
- **Testing Framework**: Comprehensive test suite with 118 source files

### Current Implementation Status
- **Production Ready**: 38+ powers implemented, Windows v0.2.0 deployed
- **Phase Completion**: Phases 1-2 complete, working toward phase 3
- **Power System**: 50%+ of 71 total powers functional
- **Advanced Features**: 3D rendering, terrain heights, turn-based mechanics

### Development Patterns
- **Test-Driven Development**: Comprehensive test coverage
- **Phase-Based Development**: 8-phase structured approach
- **Documentation-First**: Extensive research and planning documentation
- **Quality Focus**: Automated testing, performance monitoring, cross-platform builds

## Output
Creates detailed discovery documentation including:
- Technology stack analysis and dependencies
- Architecture patterns and system design
- Current implementation status and capabilities
- Development workflow and tooling analysis
- Project structure and organization assessment
- Quality metrics and testing coverage

## Integration Points
Analyzes integration with existing project elements:
- Research documentation in `research/` directory
- Implementation tracking in `instructions/` directory
- Phase-based structure in `features/` directory
- Test coverage across `src/tests/` directory

## Example
```bash
/claudio:discovery ./my-game-project
# Analyzes game project and creates discovery documentation
```

The discovery analysis forms the foundation for all subsequent workflow generation and project planning activities.