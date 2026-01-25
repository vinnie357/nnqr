# AI Agent Work Loop

This document describes how an AI agent should interact with the Beads issue tracker to complete work autonomously.

## What an Agent Needs

### 1. Project Context
- `CLAUDE.md` - Project overview, commands, patterns
- `AGENTS.md` - Work loop, session protocols
- `bd prime` - Dynamic workflow context (run at session start)

### 2. Task Discovery
- `bd ready --json` - Machine-readable ready tasks
- `bd show <id>` - Full task details with description
- Task description contains implementation requirements

### 3. Quality Gates
Know which commands to run for each implementation:
- **Lua**: `mise run love-test-busted`, `mise run love-fmt`
- **Rust**: `mise run rust-test`, `mise run rust-clippy`

### 4. Session Lifecycle
- **Start**: `bd ready` → `bd show` → `bd update --status in_progress`
- **Work**: Read task, implement, test
- **End**: `bd close` → `bd sync` → `git commit` → `git push`

## Work Loop Pseudocode

```
AGENT_LOOP:
  1. Initialize
     - Read CLAUDE.md for project context
     - Run `bd prime` for workflow context
     - Run `bd ready --json` to get available tasks

  2. Select Task
     - Parse JSON to find highest priority ready task
     - If no tasks: EXIT or wait
     - Run `bd show <id>` to get full description

  3. Claim Task
     - Run `bd update <id> --status in_progress`

  4. Execute Task
     - Parse task description for requirements
     - Implement code changes
     - Write tests if specified
     - Run quality gates for the implementation type

  5. Validate
     - All tests pass?
     - Code formatted?
     - No linting errors?
     - If validation fails: fix and retry

  6. Complete
     - Run `bd close <id>`
     - Run `bd ready` to see newly unblocked tasks
     - Commit changes with task reference

  7. Session End (or continue loop)
     - `bd sync`
     - `git push`
     - Verify push succeeded

  GOTO 2 (or EXIT if session complete)
```

## Agent Prompt Template

For spawning a work loop agent:

```
You are an AI agent working on the NNQR project.

## Session Start
1. Read project context from CLAUDE.md
2. Run `bd prime` for workflow context
3. Run `bd ready` to find available work

## Your Task
Pick the first ready task and complete it:
1. `bd show <id>` - Read full requirements
2. `bd update <id> --status in_progress` - Claim it
3. Implement the task following project patterns
4. Run quality gates: `mise run love-test-busted`
5. `bd close <id>` when complete

## Session End
- `bd sync` to sync beads state
- Commit with conventional message
- `git push` - MANDATORY before saying "done"

## Current Ready Tasks
[Insert output of `bd ready` here]
```

## Multi-Agent Considerations

When multiple agents work in parallel:

| Concern | Solution |
|---------|----------|
| **Race conditions** | Use `--status in_progress` to claim tasks |
| **State drift** | Run `bd sync` frequently |
| **Clean history** | Each task = one commit |
| **Dependency awareness** | Closing tasks unblocks others - coordinate |

## Key Beads Concepts

1. **Hash-based IDs**: Task IDs like `nnqr-h0s` are collision-resistant (use 4+ chars)
2. **Git-native storage**: Tasks in `.beads/` directory, versioned with code
3. **Dependency-aware**: `bd ready` only shows tasks with no blockers
4. **JSON output**: Use `--json` for programmatic access

## Work Loop Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  1. FIND WORK                                               │
│     bd ready                     # Find unblocked tasks     │
│     bd show <id>                 # Read task details        │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────┐
│  2. CLAIM TASK                                              │
│     bd update <id> --status in_progress                     │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────┐
│  3. DO THE WORK                                             │
│     - Implement code                                        │
│     - Write tests (TDD preferred)                           │
│     - Run quality checks                                    │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────┐
│  4. COMPLETE & CLOSE                                        │
│     bd close <id>                # Mark task done           │
│     bd ready                     # See newly unblocked      │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────┐
│  5. SYNC & COMMIT                                           │
│     bd sync                      # Sync beads state         │
│     git add . && git commit      # Commit changes           │
│     git push                     # Push to remote           │
└──────────────────────────────────────┬──────────────────────┘
                                       │
                                       └─────► Loop back to 1
```
