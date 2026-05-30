# Agent Instructions

This project uses **bees** for issue tracking (SQLite-backed, local-first, no git hooks). Run `bees init` once per clone if `.bees/` is missing.

For AI agent-specific documentation (pseudocode, prompt templates, multi-agent coordination), see `docs/beads/agent-loop.md`.

## Quick Reference

```bash
bees ready              # Find available work
bees show <id>          # View issue details
bees update <id> --status in_progress  # Claim work
bees close <id> -r "..."  # Complete work (with reason)
bees sync               # Export DB to .bees/issues.jsonl (commit it)
```

## Work Loop (Starting a Session)

### 1. Find Work
```bash
bees ready              # Issues with no blockers
bees show <id>          # Full issue details
```

### 2. Claim Issue
```bash
bees update <id> --status in_progress
```

### 3. Do Work
- Read issue description for requirements
- Implement following project patterns
- Write tests (TDD preferred)
- Run quality checks (see below)

### 4. Complete Issue
```bash
bees close <id> -r "Done in PR #N"   # Unblocks dependent issues
bees ready                            # See newly available work
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

## Filtering Issues

```bash
bees list                       # All open issues
bees list --labels "lua"        # Filter by label
bees list --status closed       # Closed issues
bees list --json                # Machine-readable
```

## Dependencies

Closing an issue may unblock others:

```bash
bees show <id>                  # Shows dependencies
bees dep list <id>              # List this issue's dependencies
bees dep add <id> <blocker-id>  # <id> depends on <blocker-id>
bees dep add <id> <other> -t related   # Non-blocking link
```

## Labels Convention

| Label | Meaning |
|-------|---------|
| `lua` / `rust` | Implementation |
| `phase10` / `phase11` | Roadmap phase |
| `10a` / `10b` / `10c` | Sub-phase |
| `bug` / `feature` / `task` | Type |
| `complexity:trivial` / `complexity:complex` | Pipeline-decision label |

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Export + PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bees sync          # Export DB to .bees/issues.jsonl
   git add .bees/issues.jsonl && git commit -m "chore(bees): sync"
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
- bees stores state in SQLite (`.bees/bees.db`, gitignored); the shared source of truth is `.bees/issues.jsonl` via `bees sync`. Unlike beads, there is no bidirectional `pull` — share via git + JSONL.
