# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

For AI agent-specific documentation (pseudocode, prompt templates, multi-agent coordination), see `docs/beads/agent-loop.md`.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Work Loop (Starting a Session)

### 1. Find Work
```bash
bd ready              # Tasks with no blockers
bd show <id>          # Full task details
```

### 2. Claim Task
```bash
bd update <id> --status in_progress
```

### 3. Do Work
- Read task description for requirements
- Implement following project patterns
- Write tests (TDD preferred)
- Run quality checks (see below)

### 4. Complete Task
```bash
bd close <id>         # Unblocks dependent tasks
bd ready              # See newly available work
```

## Quality Gates

Run before completing work:

```bash
# Lua/Love2D
mise run love-test-busted   # Tests
mise run love-fmt           # Format check

# Rust/Bevy
mise run rust-test          # Tests
mise run rust-clippy        # Lint
```

## Filtering Tasks

```bash
bd list                       # All open tasks
bd list -l lua                # Filter by label
bd list -l lua -l phase10     # Multiple labels (AND)
bd list --status in_progress  # Active work
```

## Dependencies

Closing a task may unblock others:

```bash
bd show <id>                    # Shows BLOCKS section
bd dep blockers <id>            # What blocks this task
bd dep add <task> <depends-on>  # Add dependency
```

## Labels Convention

| Label | Meaning |
|-------|---------|
| `lua` / `rust` | Implementation |
| `phase10` | Roadmap phase |
| `10a` / `10b` / `10c` | Sub-phase |
| `bug` / `feature` / `task` | Type |

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

