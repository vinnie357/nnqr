# Quadradius Development - Quick Reference

## ⚡ Most Common Commands

```bash
# Development Cycle
mise run qdev check          # Quick validation
mise run qdev test           # Run tests
mise run qdev fmt            # Format code
mise run qdev run            # Start game

# Quality Assurance
mise run quality             # Full quality workflow
mise run qdev ci             # CI simulation

# Git Workflow
mise run qgit status         # Enhanced status
mise run qgit quick "msg"    # Add, commit, push
mise run qgit log            # Pretty log

# Fixes
mise run fix-warnings        # Fix unused variables
mise run fix-critical        # Fix critical issues
```

## 🎯 Quick Workflows

### Standard Development

```bash
# Start of day
mise run qgit sync

# During development
mise run qdev check          # After each change
mise run qdev test powers    # After power changes

# Before commit
mise run quality
mise run qgit quick "implement feature X" --type feat
```

### Bug Fix

```bash
mise run qgit branch fix-bug-name
# ... fix bug ...
mise run qdev test
mise run qgit quick "fix bug description" --type fix
```

### Code Cleanup

```bash
mise run qdev fmt
mise run fix-warnings
mise run qdev clippy strict
mise run qdev ci
```

## 📋 qdev Commands

| Command | Description | Example |
|---------|-------------|---------|
| `check` | cargo check | `qdev check` |
| `clippy` | Run linter | `qdev clippy strict` |
| `fmt` | Format code | `qdev fmt` |
| `test` | Run tests | `qdev test powers` |
| `build` | Build project | `qdev build release` |
| `run` | Run game | `qdev run debug` |
| `clean` | Clean artifacts | `qdev clean --deep` |
| `quality` | QA workflow | `qdev quality` |
| `ci` | CI workflow | `qdev ci` |
| `stats` | Project stats | `qdev stats` |

## 📦 qgit Commands

| Command | Description | Example |
|---------|-------------|---------|
| `status` | Enhanced status | `qgit status` |
| `commit` | Smart commit | `qgit commit "msg" --type feat` |
| `quick` | Fast workflow | `qgit quick "msg"` |
| `sync` | Pull & push | `qgit sync` |
| `branch` | New branch | `qgit branch feature-name` |
| `log` | Pretty log | `qgit log 20` |
| `diff` | Show changes | `qgit diff` |
| `stash` | Stash work | `qgit stash "wip"` |
| `undo` | Undo commit | `qgit undo` |
| `cleanup` | Clean branches | `qgit cleanup` |

## 🎨 Conventional Commit Types

```bash
feat      # New feature
fix       # Bug fix
docs      # Documentation
refactor  # Code refactoring
test      # Tests
chore     # Build/tooling
perf      # Performance
style     # Code style
```

**Common Scopes:**
`powers`, `board`, `rendering`, `ecs`, `tests`, `build`

## 🔥 Power User Aliases

Add to your shell config:

```bash
# .bashrc / .zshrc
alias qd="mise run qdev"
alias qg="mise run qgit"
alias qq="mise run quality"
alias qc="mise run qdev check"
alias qt="mise run qdev test"
alias qf="mise run qdev fmt"
alias qr="mise run qdev run"
alias qs="mise run qgit status"
alias ql="mise run qgit log"
```

Then use:

```bash
qc                  # Quick check
qt powers           # Test powers
qf                  # Format
qr                  # Run game
qs                  # Git status
ql                  # Git log
qq                  # Full quality check
```

## 🎮 Game Testing

```bash
# Power system testing
mise run test-powers-nu

# Debug controls in game:
P - Spawn power orb
O - Display powers
I - Generate report
Space - End turn
```

## 🔍 Debugging

```bash
# With logs
mise run qdev run debug --log-level debug

# Just info
mise run qdev run release --log-level info

# Test specific feature
mise run qdev test terrain --verbose
```

## 📊 Project Health

```bash
# Quick health check
mise run qdev check
mise run qdev test

# Full analysis
mise run qdev stats
mise run quality

# Strict review
mise run qdev clippy strict
mise run qdev ci
```

## 🛠️ Maintenance

```bash
# Fix warnings
mise run fix-warnings       # All warnings
mise run fix-critical       # Critical only

# Clean build
mise run qdev clean
mise run qdev clean --deep

# Update deps (manual)
cargo update
mise run qdev test
```

## 🚨 Emergency Fixes

```bash
# Broke the build?
mise run qgit undo          # Undo last commit
mise run qdev check         # Verify

# Need to stash fast?
mise run qgit stash "emergency"
# ... fix emergency ...
mise run qgit pop

# Merge conflict?
mise run qgit status        # See conflicts
# ... resolve ...
mise run qgit quick "resolve conflicts" --type fix
```

## 📈 Before Push Checklist

```bash
✓ mise run qdev fmt
✓ mise run qdev check
✓ mise run qdev test
✓ mise run qdev clippy
✓ mise run qgit diff          # Review changes
✓ mise run qgit quick "message" --type TYPE --scope SCOPE
```

## 💡 Tips

1. **Use quality workflow** before PR
2. **Conventional commits** for clear history
3. **Test after changes** - `qdev test`
4. **Format often** - `qdev fmt`
5. **Review with** - `qdev clippy strict`
6. **Sync daily** - `qgit sync`
7. **Stash when switching** - `qgit stash`
8. **Clean branches** - `qgit cleanup`

---

**Need help?**

```bash
mise run qdev               # See all qdev commands
mise run qgit               # See all qgit commands
mise tasks                  # See all available tasks
```

**Full documentation:** See `NUSHELL_TOOLS.md`
