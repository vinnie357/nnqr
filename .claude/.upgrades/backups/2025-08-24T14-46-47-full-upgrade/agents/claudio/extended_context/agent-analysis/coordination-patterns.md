# Agent Coordination Patterns

## Task Tool Coordination Standards

### Validated Task Tool Pattern
**CRITICAL: All agent coordination must use this pattern**:
```markdown
Use Task tool with subagent_type: "agent-name" to [action] [context]
```

### Naming Convention Requirements
**Lowercase-Hyphen Format MANDATORY**:
- Agent files: `agent-name.md` (NOT `agent_name.md`)
- Task tool references: `"agent-name"` (NOT `"agent_name"`)
- Command references: `command-name.md` (NOT `command_name.md`)
- All generated components must follow lowercase-hyphen naming

### Parallel Execution Optimization

#### Single Message Batch Execution
**CRITICAL: Run multiple Task invocations in a SINGLE message** when dependencies allow:

```markdown
Run multiple Task invocations in a SINGLE message:
- Task with agent-one for parallel action one
- Task with agent-two for parallel action two  
- Task with agent-three for parallel action three
```

**Performance Benefits**:
- 3-4x faster execution than sequential Task invocations
- Optimal resource utilization during multi-agent coordination
- Reduced wait times and improved user experience
- Maintained quality and safety guarantees

#### Dependency Management
**Sequential Execution Required When**:
- Agent B requires output from Agent A as input
- Foundation analysis must complete before dependent analysis
- Backup must complete before localization can begin
- Validation requires completed installation for testing

**Parallel Execution Safe When**:
- Agents work on independent aspects of the same problem
- No data dependencies exist between agent tasks
- Agents process different categories of the same input
- Quality assurance agents analyze independent system aspects

## Agent Specialization Patterns

### Coordinator Agents
**Role**: Orchestrate complex workflows using multiple specialized agents
**Pattern**: Use parallel batch execution for optimal performance
**Example**: `claudio-coordinator-agent`, `upgrade-coordinator-agent`

**Coordination Template**:
```markdown
## Phase Execution Strategy

### Parallel Batch Execution
Run multiple Task invocations in a SINGLE message:
- Task with specialist-one for specific analysis domain
- Task with specialist-two for independent analysis domain
- Task with specialist-three for parallel processing domain
```

### Specialist Agents  
**Role**: Deep expertise in specific domains with focused responsibilities
**Pattern**: Clear input/output contracts with other agents
**Example**: `discovery-agent`, `prd-agent`, `security-review-coordinator`

**Specialization Template**:
```markdown
## Core Responsibilities
1. **Primary Function**: Specific domain expertise
2. **Input Requirements**: Clear specification of required inputs
3. **Output Deliverables**: Detailed output specifications
4. **Integration Points**: How outputs integrate with other agents
```

### Technical Agents
**Role**: Handle specific technical tasks like installation, validation, backup
**Pattern**: Atomic operations with clear success/failure states
**Example**: `upgrade-backup-manager`, `upgrade-installation-validator`

**Technical Template**:
```markdown
## Technical Operations
1. **Atomic Operations**: Single-responsibility technical tasks
2. **Error Handling**: Comprehensive error detection and recovery
3. **Validation**: Built-in validation and verification procedures
4. **Integration**: Clear integration points with workflow
```

## Extended Context Integration

### Context Organization Patterns
```
extended_context/
├── workflow/           # Core workflow contexts
├── development/        # Development-specific contexts
├── infrastructure/     # System and technical contexts
├── documentation/      # Documentation generation contexts
├── research/          # Research methodology contexts
├── command-analysis/  # Claude SDK command evaluation
└── agent-analysis/    # Agent architecture patterns
```

### Context Access Patterns
**Efficient Context Loading**:
- Load context files on-demand rather than preloading all
- Cache frequently accessed context for performance
- Organize context by logical topic and category
- Reference context files by clear, logical paths

### Context Maintenance
**Quality Assurance**:
- Regular review and updating of context files
- Validation of context file accuracy and relevance
- Performance monitoring of context loading and usage
- Integration testing of context-dependent functionality

## Error Handling and Recovery

### Coordination Error Patterns
**Common Issues**:
- Agent name mismatches (underscore vs hyphen)
- Missing or incorrect Task tool patterns
- Dependency violations in parallel execution
- Resource conflicts during concurrent execution

**Resolution Strategies**:
- Standardize on lowercase-hyphen naming across all components
- Validate Task tool patterns during agent development
- Clearly document dependency relationships
- Implement resource conflict detection and resolution

### Recovery Procedures
**Graceful Degradation**:
- Continue workflow execution when non-critical agents fail
- Provide clear error messages with resolution guidance
- Implement fallback strategies for common failure scenarios
- Maintain system integrity during partial failures

### Quality Validation
**Agent Validation Testing**:
- Verify agent names follow lowercase-hyphen convention
- Test Task tool coordination patterns for functionality
- Validate extended context access and integration
- Performance testing of parallel execution patterns

## Performance Optimization

### Resource Management
**Memory Efficiency**:
- Optimize extended context loading and caching
- Prevent memory leaks during long-running workflows
- Monitor resource usage during parallel execution
- Implement cleanup procedures for temporary resources

### Coordination Efficiency
**Execution Optimization**:
- Maximize parallel execution opportunities while respecting dependencies
- Minimize unnecessary coordination overhead
- Optimize Task tool invocation patterns for performance
- Monitor and report coordination performance metrics

### User Experience
**Response Time Optimization**:
- Provide real-time progress updates during long workflows
- Minimize perceived wait times through efficient coordination
- Clear error reporting with actionable resolution steps
- Responsive user interface throughout workflow execution

This framework ensures efficient, reliable agent coordination through validated patterns and performance optimization while maintaining safety and quality guarantees.