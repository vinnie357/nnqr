# CLAUDE.md - Quadradius Implementation Guide

## Project Context
You are implementing Quadradius, a turn-based strategy game described as "checkers on steroids", using Rust and the Bevy game engine. This is a faithful recreation of the 2007 Flash game featuring an 8x8 board, terrain heights, and approximately 70 different power-ups that dramatically alter gameplay.

**IMPORTANT**: This guide works alongside two companion documents:
1. **Project Requirements Document (PRD)** - Contains complete game mechanics, technical architecture, and project specifications
2. **Implementation Plan** - Contains strict phase-by-phase execution steps with acceptance criteria

**Your workflow should be**: Implementation Plan (what to do) → CLAUDE.md (how to do it) → PRD (detailed specifications) → Rust Testing Guide (comprehensive testing strategy)

## Implementation Philosophy

### MANDATORY: Follow the Implementation Plan
**NEVER deviate from the Implementation Plan phases without explicit instruction**
- Phase 1 MUST be 100% complete before any power-up work
- Each step's acceptance criteria must be fully met before proceeding
- The plan exists to prevent common game development failures

### Start Simple, Build Incrementally
- Begin with the absolute minimum: board rendering and basic piece movement
- Add one feature at a time and test thoroughly before moving on
- Resist the urge to implement multiple systems simultaneously
- Each commit should represent a working, testable increment

### Bevy Best Practices
- Embrace the Entity Component System (ECS) architecture
- Keep systems focused and single-responsibility
- Use Resources for global game state, Components for entity data
- Leverage Bevy's query system for efficient data access
- Prefer composition over inheritance for game entities

### Reference Document Usage
- **Implementation Plan**: Your step-by-step roadmap (FOLLOW THIS STRICTLY)
- **PRD**: Detailed specifications when you need technical details
- **Rust Testing Guide**: Comprehensive testing strategy and examples for each phase
- **CLAUDE.md** (this doc): Best practices and implementation guidance

## Memories
- When planning it is okay to use ultrathink

(Rest of the file remains unchanged)