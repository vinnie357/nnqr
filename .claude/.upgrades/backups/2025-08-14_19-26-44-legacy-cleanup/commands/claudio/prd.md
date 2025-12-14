# /claudio:prd Command

Generates comprehensive Product Requirements Document (PRD) for Quadradius game project based on discovery analysis and existing game specifications.

## Usage
```bash
/claudio:prd [feature_name] [context]
```

## Description
Creates detailed PRD documentation for the Quadradius project, incorporating game mechanics research, technical architecture requirements, and implementation specifications for a turn-based strategy game with 70+ power-ups.

## Project-Specific PRD Generation
This command creates PRDs tailored for Quadradius development:

### Game Mechanics Specifications
- **Board Layout**: 10×8 grid with terrain height system
- **Victory Conditions**: Piece elimination and strategic objectives
- **Movement System**: Orthogonal movement with height restrictions
- **Power System**: 71 unique power-ups with sophisticated effects

### Technical Requirements
- **Rust/Bevy Architecture**: ECS-based system design
- **3D Isometric Rendering**: Camera setup and coordinate transformations
- **Cross-Platform Deployment**: Linux development, Windows releases
- **Performance Targets**: 60+ FPS with complex visual effects

### Implementation Context
- **Research Integration**: Incorporates findings from `research/game.md`
- **Architecture Patterns**: Leverages `research/isometric_design_patterns_bevy.md`
- **Current Status**: Builds on existing implementation in `quadradius/src/`
- **Quality Standards**: Aligns with comprehensive testing framework

### Power System Requirements
- **Combat Powers**: Offensive abilities, defensive mechanics, area effects
- **Movement Powers**: Enhanced mobility, teleportation, terrain interaction
- **Board Manipulation**: Terrain modification, environmental changes
- **Meta Powers**: Power interactions, advanced mechanics

## Output Structure
Creates comprehensive PRD with:
- Executive summary and project overview
- Detailed game mechanics and rules
- Technical architecture specifications
- Feature requirements and acceptance criteria
- Implementation priorities and dependencies
- Quality requirements and testing standards

## Integration with Project Research
Leverages existing research documentation:
- Game mechanics analysis from original Flash game research
- Technical patterns for Bevy/Rust implementation
- UI/UX requirements for isometric game interface
- Performance optimization strategies

## Example Usage
```bash
/claudio:prd power-system "Complete implementation of 71 power-ups"
# Creates PRD for power system implementation

/claudio:prd board-manipulation "Terrain height modification powers"
# Creates PRD for board manipulation features
```

PRD generation forms the requirements foundation for implementation planning and task organization.