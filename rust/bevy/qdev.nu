#!/usr/bin/env nu

# Quadradius Development Utility
# Comprehensive nushell-based development tools for Rust/Bevy game development

# Main entry point with subcommand routing
def main [] {
    print $"(ansi cyan_bold)🎮 Quadradius Development Utility(ansi reset)"
    print ""
    print "Usage: qdev <command> [options]"
    print ""
    print $"(ansi yellow_bold)Available Commands:(ansi reset)"
    print "  check           - Run cargo check"
    print "  clippy [level]  - Run clippy (levels: strict, normal, permissive)"
    print "  fmt [--check]   - Format code or check formatting"
    print "  test [pattern]  - Run tests (optionally filter by pattern)"
    print "  build [mode]    - Build project (modes: debug, release)"
    print "  run [mode]      - Run the game (modes: dev, debug, release)"
    print "  clean           - Clean build artifacts"
    print "  fix-warnings    - Fix unused variable warnings"
    print "  fix-critical    - Fix critical warnings only"
    print "  quality         - Run full quality check workflow"
    print "  ci              - Run CI workflow (fmt-check, clippy, test)"
    print "  stats           - Show project statistics"
    print "  powers          - Test power system"
    print ""
    print $"(ansi light_gray)Examples:(ansi reset)"
    print "  qdev clippy strict    # Run strict clippy"
    print "  qdev test powers      # Run power-related tests"
    print "  qdev quality          # Full quality check"
    print ""
}

# Run cargo check
def "main check" [] {
    print $"(ansi cyan)🔍 Running cargo check...(ansi reset)\n"
    cargo check --all-targets
}

# Run clippy with configurable strictness
def "main clippy" [
    level: string = "normal"  # Strictness level: strict, normal, or permissive
] {
    print $"(ansi cyan)📋 Running clippy \(($level) mode\)...(ansi reset)\n"

    match $level {
        "strict" => {
            cargo clippy --all-targets -- -D warnings -D clippy::all
        }
        "normal" => {
            cargo clippy -- -D warnings
        }
        "permissive" => {
            cargo clippy --all-targets -- -W clippy::all
        }
        _ => {
            print $"(ansi red)❌ Unknown level: ($level). Use: strict, normal, or permissive(ansi reset)"
            return
        }
    }
}

# Format code or check formatting
def "main fmt" [
    --check  # Only check formatting without modifying files
] {
    if $check {
        print $"(ansi cyan)🎨 Checking code formatting...(ansi reset)\n"
        cargo fmt -- --check
    } else {
        print $"(ansi cyan)🎨 Formatting code...(ansi reset)\n"
        cargo fmt
        print $"(ansi green)✅ Code formatted successfully!(ansi reset)"
    }
}

# Run tests with optional pattern filtering
def "main test" [
    pattern?: string  # Optional test pattern to filter
    --verbose(-v)     # Show test output
    --coverage        # Run with coverage
    --nocapture       # Don't capture stdout/stderr
] {
    print $"(ansi cyan)🧪 Running tests...(ansi reset)\n"

    mut cmd = "cargo test"

    if $pattern != null {
        $cmd = $"($cmd) ($pattern)"
    }

    if $verbose or $nocapture {
        $cmd = $"($cmd) -- --nocapture"
    }

    if $coverage {
        print $"(ansi yellow)📊 Coverage mode not yet implemented(ansi reset)"
        return
    }

    nu -c $cmd
}

# Build the project
def "main build" [
    mode: string = "debug"  # Build mode: debug or release
] {
    print $"(ansi cyan)🔨 Building in \(($mode) mode\)...(ansi reset)\n"

    match $mode {
        "debug" => {
            cargo build
        }
        "release" => {
            cargo build --release
        }
        _ => {
            print $"(ansi red)❌ Unknown mode: ($mode). Use: debug or release(ansi reset)"
            return
        }
    }
}

# Run the game
def "main run" [
    mode: string = "dev"  # Run mode: dev, debug, or release
    --log-level(-l): string = "info"  # Log level: debug, info, warn, error
] {
    print $"(ansi cyan)🎮 Starting Quadradius in \(($mode) mode\)...(ansi reset)\n"

    match $mode {
        "dev" => {
            cargo run
        }
        "debug" => {
            with-env { RUST_LOG: $log_level } {
                cargo run
            }
        }
        "release" => {
            with-env { RUST_LOG: $log_level } {
                cargo run --release
            }
        }
        _ => {
            print $"(ansi red)❌ Unknown mode: ($mode). Use: dev, debug, or release(ansi reset)"
            return
        }
    }
}

# Clean build artifacts
def "main clean" [
    --deep  # Also clean cargo cache
] {
    print $"(ansi cyan)🧹 Cleaning build artifacts...(ansi reset)\n"

    cargo clean

    if $deep {
        print $"(ansi yellow)Deep cleaning (removing target/)...(ansi reset)"
        rm -rf target
    }

    print $"(ansi green)✅ Clean complete!(ansi reset)"
}

# Fix unused variable warnings
def "main fix-warnings" [] {
    print $"(ansi cyan)🔧 Running fix_unused_warnings.nu...(ansi reset)\n"
    nu fix_unused_warnings.nu
}

# Fix critical warnings only
def "main fix-critical" [] {
    print $"(ansi cyan)🔧 Running fix_critical_warnings.nu...(ansi reset)\n"
    nu fix_critical_warnings.nu
}

# Run comprehensive quality check workflow
def "main quality" [
    --fix  # Automatically fix issues where possible
] {
    print $"(ansi cyan_bold)🎯 Running Quality Check Workflow(ansi reset)\n"

    let steps = [
        {name: "Format Check", cmd: "cargo fmt -- --check"}
        {name: "Clippy", cmd: "cargo clippy -- -D warnings"}
        {name: "Tests", cmd: "cargo test"}
        {name: "Build (Release)", cmd: "cargo build --release"}
    ]

    mut failed = []
    mut passed = []

    for step in $steps {
        print $"(ansi yellow)▶ ($step.name)...(ansi reset)"

        let result = (do -i { nu -c $step.cmd } | complete)

        if $result.exit_code == 0 {
            print $"  (ansi green)✅ \(($step.name)\) passed(ansi reset)\n"
            $passed = ($passed | append $step.name)
        } else {
            print $"  (ansi red)❌ \(($step.name)\) failed(ansi reset)\n"
            $failed = ($failed | append $step.name)

            if not $fix {
                print $"(ansi yellow)Stopping at first failure. Use --fix to attempt automatic fixes.(ansi reset)\n"
                break
            }
        }
    }

    print $"(ansi cyan_bold)📊 Quality Check Summary:(ansi reset)"
    print $"  (ansi green)Passed: \(($passed | length)\)(ansi reset)"
    print $"  (ansi red)Failed: \(($failed | length)\)(ansi reset)"

    if ($failed | length) == 0 {
        print $"\n(ansi green_bold)🎉 All quality checks passed!(ansi reset)"
    } else {
        print $"\n(ansi red_bold)❌ Quality checks failed:(ansi reset)"
        for failure in $failed {
            print $"  - ($failure)"
        }
    }
}

# Run CI workflow
def "main ci" [] {
    print $"(ansi cyan_bold)🚀 Running CI Workflow(ansi reset)\n"

    # Format check
    print $"(ansi yellow)1/3 Format check...(ansi reset)"
    cargo fmt -- --check
    if $env.LAST_EXIT_CODE != 0 {
        print $"(ansi red)❌ Format check failed!(ansi reset)"
        return
    }
    print $"(ansi green)✅ Format check passed(ansi reset)\n"

    # Clippy
    print $"(ansi yellow)2/3 Clippy...(ansi reset)"
    cargo clippy -- -D warnings
    if $env.LAST_EXIT_CODE != 0 {
        print $"(ansi red)❌ Clippy failed!(ansi reset)"
        return
    }
    print $"(ansi green)✅ Clippy passed(ansi reset)\n"

    # Tests
    print $"(ansi yellow)3/3 Tests...(ansi reset)"
    cargo test
    if $env.LAST_EXIT_CODE != 0 {
        print $"(ansi red)❌ Tests failed!(ansi reset)"
        return
    }
    print $"(ansi green)✅ Tests passed(ansi reset)\n"

    print $"(ansi green_bold)🎉 CI workflow completed successfully!(ansi reset)"
}

# Show project statistics
def "main stats" [] {
    print $"(ansi cyan_bold)📊 Quadradius Project Statistics(ansi reset)\n"

    # Count Rust files
    let rust_files = (ls **/*.rs | length)
    print $"(ansi yellow)Rust Files:(ansi reset) \(($rust_files)\)"

    # Count lines of code
    let loc = (rg --files -t rust | lines | length)
    print $"(ansi yellow)Total Files:(ansi reset) \(($loc)\)"

    # Count tests
    let tests = (rg '#\[test\]' -c | lines | length)
    print $"(ansi yellow)Test Files:(ansi reset) \(($tests)\)"

    # Show crate info
    print $"\n(ansi cyan)Crate Structure:(ansi reset)"
    ls src/systems/*.rs | get name | each { |f| print $"  • ($f)" }

    # Show dependencies
    print $"\n(ansi cyan)Key Dependencies:(ansi reset)"
    open Cargo.toml | get dependencies | transpose | each { |dep|
        print $"  • ($dep.column0)"
    } | ignore
}

# Test power system
def "main powers" [] {
    print $"(ansi cyan)🎮 Running Power System Test(ansi reset)\n"
    nu test_powers.nu
}

# Interactive mode - select command from menu
def "main interactive" [] {
    print $"(ansi cyan_bold)🎮 Quadradius Development - Interactive Mode(ansi reset)\n"

    let commands = [
        "check"
        "clippy"
        "fmt"
        "test"
        "build"
        "run"
        "quality"
        "ci"
        "fix-warnings"
        "stats"
        "Exit"
    ]

    loop {
        print $"\n(ansi yellow)Select a command:(ansi reset)"
        for i in 0..(($commands | length) - 1) {
            print $"  ($i + 1). ($commands | get $i)"
        }

        let choice = (input "\nEnter number: ")
        let idx = ($choice | into int) - 1

        if $idx < 0 or $idx >= ($commands | length) {
            print $"(ansi red)Invalid choice(ansi reset)"
            continue
        }

        let cmd = ($commands | get $idx)

        if $cmd == "Exit" {
            print $"(ansi green)Goodbye!(ansi reset)"
            break
        }

        nu -c $"qdev ($cmd)"
    }
}
