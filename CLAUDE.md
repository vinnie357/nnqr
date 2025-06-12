# CLAUDE.md - Quadradius Implementation Guide

## Project Context
You are implementing Quadradius, a turn-based strategy game described as "checkers on steroids", using Rust and the Bevy game engine. This is a faithful recreation of the 2007 Flash game featuring a **10x8 board** (10 columns, 8 rows), terrain heights, and approximately 70 different power-ups that dramatically alter gameplay.

**IMPORTANT**: This guide works alongside comprehensive research and planning documents:

### Core Documents
1. **Project Requirements Document (PRD)** - Contains complete game mechanics, technical architecture, and project specifications
2. **Implementation Plan** - Contains strict phase-by-phase execution steps with acceptance criteria
3. **Detailed Task List** - Phase-by-phase implementation guide with research references

### Research Documents  
4. **@research/game.md** - Comprehensive analysis of original Flash game mechanics and specifications
5. **@research/isometric_design_patterns_bevy.md** - Technical patterns for isometric rendering in Bevy
6. **@implementation_status.md** - Current project status and gap analysis

**Your workflow should be**: Detailed Task List (current phase) → Research Documents (specifications) → CLAUDE.md (best practices) → PRD (technical details)

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

## Research Gap Analysis

### ✅ COMPREHENSIVE COVERAGE ACHIEVED
Based on analysis of all task phases and current project status, the existing research documents provide complete coverage for all implementation phases:

**Phase 1 (Documentation)**: Fully covered by research documents and current project analysis
**Phase 2 (Combat Powers)**: Complete power specifications and implementation examples available  
**Phase 3 (Board Manipulation)**: Terrain system and isometric rendering patterns documented
**Phase 4 (Meta Powers)**: Power interaction concepts and balance considerations covered
**Phase 5 (Enhancement)**: Performance optimization and visual effect patterns documented

### 📋 RESEARCH COMPLETENESS VALIDATION

#### Board and Core Mechanics ✅
- **@research/game.md** provides complete board specifications (10x8), terrain rules, movement restrictions
- **@nnqr_prd.md** has updated technical architecture reflecting research findings
- No gaps identified in core game mechanics documentation

#### Isometric Rendering ✅  
- **@research/isometric_design_patterns_bevy.md** provides comprehensive technical implementation guide
- Camera setup, coordinate transformations, depth sorting all documented
- Mouse interaction patterns for isometric view covered
- No gaps identified in rendering implementation

#### Power System ✅
- **@research/game.md** catalogs all major power categories with specific examples
- **@quadradius/POWER_IMPLEMENTATION_STATUS.md** documents current implementation state
- Power balance considerations and known overpowered combinations documented
- No gaps identified in power system specifications

#### Performance and Polish ✅
- Original game performance issues documented as lessons learned
- Optimization strategies for complex effects covered
- Visual feedback requirements specified
- No gaps identified in enhancement requirements

### 🎯 RECOMMENDATION: PROCEED WITH IMPLEMENTATION
**All necessary research is complete.** The current documentation set provides sufficient detail for all planned implementation phases. Focus should be on executing the detailed task list rather than additional research.

## Memories
- When planning it is okay to use ultrathink  
- Remember the code quality steps, and the windows build process for the exe
- Test driven development start with tests to prove the feature, then use the implementation to make the tests pass
- **Board is 10x8, not 8x8** - Critical correction from research
- Current project is far more advanced than basic implementation guide suggests
- Focus on power completion rather than rebuilding basic functionality
- Always write tests first, Test Driven Development is the focus.
- complex topics are stored in the research/ folder