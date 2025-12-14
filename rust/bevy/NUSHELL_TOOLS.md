# Quadradius Nushell Development Tools

Comprehensive nushell-based development utilities for the Quadradius Rust/Bevy game project.

## 📚 Table of Contents

- [Quick Start](#quick-start)
- [Development Utility (qdev)](#development-utility-qdev)
- [Git Helper (qgit)](#git-helper-qgit)
- [Maintenance Scripts](#maintenance-scripts)
- [Mise Integration](#mise-integration)
- [Why Nushell?](#why-nushell)

---

## 🚀 Quick Start

```bash
# Using mise tasks (recommended)
mise run qdev           # Show qdev help
mise run qgit           # Show qgit help
mise run quality        # Run quality checks
mise run git-status     # Enhanced git status

# Direct execution
./qdev.nu check         # Run cargo check
./qgit.nu status        # Show git status
```

---

## 🛠️ Development Utility (qdev)

**File:** `qdev.nu`
**Purpose:** Comprehensive development workflow automation

### Available Commands

#### **Check & Lint**

```bash
qdev check                    # Run cargo check
qdev clippy [level]          # Run clippy with strictness levels
  - strict                   # -D warnings -D clippy::all
  - normal (default)         # -D warnings
  - permissive              # -W clippy::all
qdev fmt [--check]           # Format code or check formatting
```

#### **Testing**

```bash
qdev test                    # Run all tests
qdev test powers             # Run tests matching "powers"
qdev test --verbose          # Show test output
qdev test --nocapture        # Don't capture stdout/stderr
qdev powers                  # Run power system test suite
```

#### **Building & Running**

```bash
qdev build [mode]            # Build project
  - debug (default)          # Debug build
  - release                  # Optimized build
qdev run [mode]              # Run the game
  - dev (default)            # Development mode
  - debug                    # With debug logging
  - release                  # Optimized with info logging
qdev run --log-level debug   # Custom log level
```

#### **Maintenance**

```bash
qdev clean                   # Clean build artifacts
qdev clean --deep            # Also remove target/
qdev fix-warnings            # Fix unused variable warnings
qdev fix-critical            # Fix critical warnings only
```

#### **Workflows**

```bash
qdev quality                 # Full quality check workflow
  - Format check
  - Clippy
  - Tests
  - Release build
qdev quality --fix           # Attempt automatic fixes
qdev ci                      # CI workflow (fmt-check, clippy, test)
qdev stats                   # Show project statistics
qdev interactive             # Interactive menu mode
```

### Examples

```bash
# Typical development workflow
qdev fmt                     # Format code
qdev check                   # Quick check
qdev test powers             # Test power systems
qdev run debug               # Run with debug logs

# Pre-commit workflow
qdev quality                 # Full quality check
qdev ci                      # CI simulation

# Strict code review
qdev clippy strict           # Maximum linting
```

---

## 📦 Git Helper (qgit)

**File:** `qgit.nu`
**Purpose:** Streamlined git workflows with conventional commits

### Available Commands

#### **Status & Information**

```bash
qgit status                  # Enhanced git status
  - Shows current branch
  - Ahead/behind indicators
  - Stash count
qgit log [count]             # Pretty commit log (default: 10)
qgit diff [file]             # Show diff with syntax
qgit diff --staged           # Show staged changes
qgit info                    # Detailed branch information
```

#### **Committing**

```bash
qgit commit "message"        # Smart conventional commit
  --type feat (default)      # Commit type (feat, fix, docs, etc.)
  --scope powers             # Commit scope
  --breaking                 # Mark as breaking change

# Examples:
qgit commit "add terrain height" --type feat --scope board
# Creates: feat(board): add terrain height

qgit commit "fix crash" --type fix --scope rendering
# Creates: fix(rendering): fix crash
```

**Conventional Commit Types:**
- `feat` - New features
- `fix` - Bug fixes
- `docs` - Documentation changes
- `refactor` - Code refactoring
- `test` - Test additions/changes
- `chore` - Build/tooling changes
- `perf` - Performance improvements
- `style` - Code style changes

**Common Scopes:**
- `powers` - Power system changes
- `board` - Board/grid system
- `rendering` - 2D/3D rendering
- `ecs` - Entity Component System
- `tests` - Test infrastructure
- `build` - Build configuration

#### **Branching**

```bash
qgit branch feature-name     # Create and switch to new branch
qgit branch fix-bug --from main  # Create from specific branch
qgit cleanup                 # Clean up merged branches
qgit cleanup --dry-run       # Preview cleanup
```

#### **Synchronization**

```bash
qgit sync                    # Pull (rebase) and push
qgit sync --no-push          # Sync without pushing
```

#### **Stashing**

```bash
qgit stash "work in progress"  # Stash with message
qgit stash                     # Stash without message
qgit pop                       # Pop latest stash
qgit pop 1                     # Pop specific stash
```

#### **Undo Operations**

```bash
qgit undo                    # Undo last commit (keep changes)
qgit undo --hard             # Discard last commit completely
qgit amend                   # Amend last commit
qgit amend --no-edit         # Amend without editing message
```

#### **Quick Workflows**

```bash
qgit quick "implement power X" --type feat --scope powers
# Runs: add, commit, push in one command

qgit quick "fix clippy warnings" --type fix --no-push
# Commit without pushing
```

### Git Workflow Examples

```bash
# Feature development
qgit branch feature-teleport
# ... make changes ...
qgit quick "implement teleport power" --type feat --scope powers

# Bug fix
qgit branch fix-crash
# ... fix bug ...
qgit commit "resolve rendering crash" --type fix --scope rendering
qgit sync

# Emergency hotfix
qgit stash "current work"
qgit branch hotfix-memory-leak --from main
# ... fix leak ...
qgit quick "fix memory leak" --type fix --scope ecs
qgit pop
```

---

## 🔧 Maintenance Scripts

### fix_unused_warnings.nu

Comprehensive unused variable warning fixes across the entire codebase.

```bash
nu fix_unused_warnings.nu
mise run fix-warnings
```

**Features:**
- Fixes unused variables in all system files
- Handles test file array conversions
- Shows progress with colored output
- Validates changes with cargo check

### fix_critical_warnings.nu

Targeted fixes for critical warnings only.

```bash
nu fix_critical_warnings.nu
mise run fix-critical
```

**Features:**
- Focuses on high-priority issues
- Adds allow attributes where appropriate
- Comments out deprecated constants
- Runs verification build

### test_powers.nu

Interactive power system testing.

```bash
nu test_powers.nu
mise run test-powers-nu
```

**Features:**
- Colored instruction display
- Debug control documentation
- Launches game for manual testing

---

## 📋 Mise Integration

All nushell tools are integrated with mise for convenient access:

```bash
# Development tools
mise run qdev               # Show qdev help
mise run quality            # Quality check workflow
mise run stats              # Project statistics

# Git tools
mise run qgit               # Show qgit help
mise run git-status         # Enhanced status
mise run git-log            # Pretty log

# Maintenance
mise run fix-warnings       # Fix all warnings
mise run fix-critical       # Fix critical only
mise run test-powers-nu     # Power system test

# Standard Rust tasks (also available)
mise run check              # cargo check
mise run clippy             # cargo clippy
mise run test               # cargo test
mise run fmt                # cargo fmt
mise run build              # cargo build
mise run start              # cargo run
```

### Mise Task Aliases

Add to your shell:

```bash
# .bashrc / .zshrc
alias qd="mise run qdev"
alias qg="mise run qgit"
alias qq="mise run quality"
```

Then use:

```bash
qd check                    # Quick check
qg status                   # Git status
qq                          # Quality workflow
```

---

## 🌟 Why Nushell?

### Advantages Over Bash

1. **Structured Data**
   ```nu
   # Clean data structures
   let fixes = [
       {file: "foo.rs", old: "bar", new: "baz"}
   ]

   # vs bash string manipulation
   sed -i 's/bar/baz/g' foo.rs
   ```

2. **Better Error Handling**
   ```nu
   # File existence checks
   if not ($file | path exists) {
       print $"(ansi red)File not found(ansi reset)"
       return
   }
   ```

3. **Type Safety**
   - No quoting issues
   - No escaping problems
   - Clear parameter types

4. **Visual Feedback**
   ```nu
   print $"(ansi green)✅ Success(ansi reset)"
   print $"(ansi red)❌ Failed(ansi reset)"
   print $"(ansi yellow)⚠ Warning(ansi reset)"
   ```

5. **Maintainability**
   - Clear function definitions
   - Reusable helper functions
   - Self-documenting code

### Performance Benefits

- **Parallel execution** of independent tasks
- **Structured pipelines** instead of string pipes
- **Built-in caching** for repeated operations
- **Native cross-platform** support

---

## 📊 Project Statistics

View comprehensive project stats:

```bash
qdev stats
```

**Provides:**
- Rust file count
- Total file count
- Test count
- Crate structure
- Key dependencies

---

## 🎯 Common Workflows

### Daily Development

```bash
# Morning routine
qgit sync                   # Get latest changes
qdev check                  # Verify build
qdev test                   # Run tests

# During development
qdev fmt                    # Format as you go
qdev check                  # Quick validation

# Before commit
qdev quality                # Full quality check
qgit commit "your message" --type feat --scope area
```

### Pre-Release Checklist

```bash
qdev quality                # Quality workflow
qdev clippy strict          # Strict linting
qdev test --verbose         # All tests with output
qdev build release          # Release build
qgit log 20                 # Review recent commits
```

### Code Review Preparation

```bash
qdev fmt                    # Format all code
qdev fix-warnings           # Clean up warnings
qdev clippy strict          # Maximum linting
qdev ci                     # CI simulation
qgit diff                   # Review changes
```

---

## 🔍 Troubleshooting

### Script Not Executable

```bash
chmod +x qdev.nu qgit.nu
```

### Nushell Not Found

```bash
# Install via mise
mise install

# Or direct install
cargo install nu
```

### Permission Denied

```bash
# Run with nu explicitly
nu qdev.nu check
nu qgit.nu status
```

---

## 📝 Contributing

When adding new nushell scripts:

1. **Use consistent structure**
   - Main entry with help text
   - Subcommands with `def "main subcommand"`
   - Colored output with `ansi`

2. **Add to mise.toml**
   ```toml
   [tasks.your-task]
   description = "Your task description"
   dir = "quadradius"
   run = "nu your-script.nu"
   ```

3. **Document in this file**
   - Add command description
   - Provide examples
   - Explain use cases

4. **Test thoroughly**
   ```bash
   nu your-script.nu         # Test help
   nu your-script.nu cmd     # Test command
   ```

---

## 🎉 Summary

The Quadradius nushell toolkit provides:

- **Development acceleration** with qdev
- **Git workflow streamlining** with qgit
- **Automated maintenance** with fix scripts
- **Mise integration** for convenience
- **Type-safe scripting** with nushell
- **Cross-platform compatibility**
- **Visual feedback** for all operations

**Get started:**

```bash
mise run qdev               # Explore development tools
mise run qgit               # Explore git tools
mise run quality            # Run first quality check
```

Happy coding! 🎮✨
