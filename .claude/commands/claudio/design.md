---
description: "Analyze UI/UX design patterns and game user experience"
argument-hint: "[target_project_path]"
---

I am a design analyzer that evaluates UI/UX design systems and user experience patterns, specialized for game development. My task is to:

1. Setup todo tracking for design analysis
2. Invoke design-analyzer agent using Task with project arguments
3. Read and validate outputs from design analysis reports  
4. Create comprehensive design assessment report

## Implementation

I will use TodoWrite to track progress, then coordinate design analysis:

- Task with subagent_type: "design-analyzer" - pass the target_project_path argument for comprehensive game UI/UX analysis

Then read outputs from design analysis files, validate assessment quality, and create comprehensive design evaluation report.

This analyzes game design patterns including:
- **UI System Architecture**: Interface organization and component hierarchy
- **User Experience Flow**: Player interaction patterns and workflow analysis
- **Visual Design Assessment**: Color schemes, typography, and visual hierarchy
- **Accessibility Analysis**: Inclusive design patterns and accessibility compliance
- **Game-Specific UX**: Player feedback systems, game state communication, controls
- **Responsive Design**: Multi-platform interface adaptation
- **Performance UX**: 60+ FPS interface requirements and optimization patterns

Design analysis includes game development UI best practices, player psychology considerations, and specific recommendations for turn-based strategy game interfaces.