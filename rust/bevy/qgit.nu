#!/usr/bin/env nu

# Quadradius Git Helper
# Streamlined git workflows for Quadradius development

# Main entry point
def main [] {
    print $"(ansi cyan_bold)📦 Quadradius Git Helper(ansi reset)"
    print ""
    print "Usage: qgit <command> [options]"
    print ""
    print $"(ansi yellow_bold)Available Commands:(ansi reset)"
    print "  status          - Show git status with enhancements"
    print "  commit [msg]    - Smart commit with conventional commits"
    print "  sync            - Pull, rebase, and push"
    print "  branch [name]   - Create and switch to new branch"
    print "  cleanup         - Clean up merged branches"
    print "  undo            - Undo last commit (keep changes)"
    print "  amend           - Amend last commit"
    print "  stash [msg]     - Stash changes with message"
    print "  pop             - Pop stashed changes"
    print "  log [count]     - Show pretty commit log"
    print "  diff [file]     - Show diff with syntax"
    print "  quick [msg]     - Quick commit workflow (add, commit, push)"
    print ""
}

# Show enhanced git status
def "main status" [] {
    print $"(ansi cyan_bold)📊 Git Status(ansi reset)\n"

    # Current branch
    let branch = (git branch --show-current)
    print $"(ansi yellow)Current Branch:(ansi reset) ($branch)"

    # Ahead/behind
    let status = (git status -sb | lines | first)
    print $"(ansi dim)($status)(ansi reset)\n"

    # Show status
    git status --short

    # Show stashes if any
    let stashes = (git stash list | lines | length)
    if $stashes > 0 {
        print $"\n(ansi yellow)💾 Stashed Changes:(ansi reset) ($stashes)"
    }
}

# Smart commit with conventional commits
def "main commit" [
    message?: string  # Commit message
    --type(-t): string = "feat"  # Commit type: feat, fix, docs, refactor, test, chore
    --scope(-s): string  # Commit scope (e.g., powers, board, rendering)
    --breaking(-b)  # Mark as breaking change
] {
    # If no message, prompt for it
    let msg = if $message == null {
        input "Commit message: "
    } else {
        $message
    }

    # Build conventional commit message
    mut commit_msg = $type

    if $scope != null {
        $commit_msg = $"($commit_msg)(($scope))"
    }

    if $breaking {
        $commit_msg = $"($commit_msg)!"
    }

    $commit_msg = $"($commit_msg): ($msg)"

    # Add footer
    $commit_msg = $"($commit_msg)\n\n🤖 Generated with Quadradius Dev Tools\n\nCo-Authored-By: Claude <noreply@anthropic.com>"

    print $"(ansi cyan)📝 Creating commit:(ansi reset)"
    print $"(ansi dim)($commit_msg)(ansi reset)\n"

    # Stage all changes
    git add .

    # Create commit
    git commit -m $commit_msg

    print $"\n(ansi green)✅ Commit created successfully!(ansi reset)"
}

# Pull, rebase, and push
def "main sync" [
    --no-push  # Don't push after syncing
] {
    print $"(ansi cyan)🔄 Syncing with remote...(ansi reset)\n"

    # Fetch latest
    print $"(ansi yellow)Fetching from remote...(ansi reset)"
    git fetch origin

    # Get current branch
    let branch = (git branch --show-current)

    # Pull with rebase
    print $"(ansi yellow)Pulling with rebase...(ansi reset)"
    git pull --rebase origin $branch

    if not $no_push {
        print $"(ansi yellow)Pushing to remote...(ansi reset)"
        git push origin $branch
    }

    print $"\n(ansi green)✅ Sync complete!(ansi reset)"
}

# Create and switch to new branch
def "main branch" [
    name: string  # Branch name
    --from(-f): string  # Create from branch (default: current)
] {
    print $"(ansi cyan)🌿 Creating branch: ($name)(ansi reset)\n"

    if $from != null {
        git checkout -b $name $from
    } else {
        git checkout -b $name
    }

    print $"(ansi green)✅ Switched to new branch: ($name)(ansi reset)"
}

# Clean up merged branches
def "main cleanup" [
    --dry-run  # Show what would be deleted
] {
    print $"(ansi cyan)🧹 Cleaning up merged branches...(ansi reset)\n"

    # Get merged branches (excluding main/master)
    let merged = (git branch --merged | lines | where $it !~ "main|master|\\*" | str trim)

    if ($merged | length) == 0 {
        print $"(ansi green)✨ No merged branches to clean up(ansi reset)"
        return
    }

    print $"(ansi yellow)Found ($merged | length) merged branches:(ansi reset)"
    for branch in $merged {
        print $"  • ($branch)"
    }

    if $dry_run {
        print $"\n(ansi dim)(Dry run - no branches deleted)(ansi reset)"
        return
    }

    let confirm = (input "\nDelete these branches? (y/N): ")

    if $confirm == "y" or $confirm == "Y" {
        for branch in $merged {
            git branch -d $branch
            print $"(ansi green)  ✓ Deleted ($branch)(ansi reset)"
        }
        print $"\n(ansi green)✅ Cleanup complete!(ansi reset)"
    } else {
        print $"(ansi yellow)Cancelled(ansi reset)"
    }
}

# Undo last commit (keep changes)
def "main undo" [
    --hard  # Discard changes completely
] {
    if $hard {
        let confirm = (input "⚠️  This will discard all changes. Are you sure? (y/N): ")
        if $confirm != "y" and $confirm != "Y" {
            print $"(ansi yellow)Cancelled(ansi reset)"
            return
        }
        git reset --hard HEAD~1
        print $"(ansi red)💥 Last commit discarded completely(ansi reset)"
    } else {
        git reset --soft HEAD~1
        print $"(ansi green)✅ Last commit undone (changes kept)(ansi reset)"
    }
}

# Amend last commit
def "main amend" [
    --no-edit  # Don't edit commit message
] {
    git add .

    if $no_edit {
        git commit --amend --no-edit
    } else {
        git commit --amend
    }

    print $"(ansi green)✅ Commit amended(ansi reset)"
}

# Stash changes with message
def "main stash" [
    message?: string  # Stash message
] {
    let msg = if $message == null {
        input "Stash message (optional): "
    } else {
        $message
    }

    if $msg == "" {
        git stash
    } else {
        git stash push -m $msg
    }

    print $"(ansi green)✅ Changes stashed(ansi reset)"
}

# Pop stashed changes
def "main pop" [
    index?: int  # Stash index (default: latest)
] {
    if $index == null {
        git stash pop
    } else {
        git stash pop $"stash@{($index)}"
    }

    print $"(ansi green)✅ Stash applied(ansi reset)"
}

# Show pretty commit log
def "main log" [
    count: int = 10  # Number of commits to show
] {
    print $"(ansi cyan_bold)📜 Recent Commits(ansi reset)\n"

    git log --oneline --graph --decorate --color=always -n $count
}

# Show diff with syntax
def "main diff" [
    file?: string  # Specific file to diff
    --staged  # Show staged changes
] {
    if $staged {
        if $file == null {
            git diff --staged --color=always
        } else {
            git diff --staged --color=always $file
        }
    } else {
        if $file == null {
            git diff --color=always
        } else {
            git diff --color=always $file
        }
    }
}

# Quick commit workflow (add, commit, push)
def "main quick" [
    message: string  # Commit message
    --type(-t): string = "feat"  # Commit type
    --scope(-s): string  # Commit scope
    --no-push  # Don't push after commit
] {
    print $"(ansi cyan_bold)⚡ Quick Commit Workflow(ansi reset)\n"

    # Build commit message
    mut commit_msg = $type

    if $scope != null {
        $commit_msg = $"($commit_msg)(($scope))"
    }

    $commit_msg = $"($commit_msg): ($message)"
    $commit_msg = $"($commit_msg)\n\n🤖 Generated with Quadradius Dev Tools\n\nCo-Authored-By: Claude <noreply@anthropic.com>"

    # Show what will be committed
    print $"(ansi yellow)Files to commit:(ansi reset)"
    git status --short

    print $"\n(ansi yellow)Commit message:(ansi reset)"
    print $"(ansi dim)($commit_msg)(ansi reset)\n"

    # Add all
    print $"(ansi cyan)Adding files...(ansi reset)"
    git add .

    # Commit
    print $"(ansi cyan)Creating commit...(ansi reset)"
    git commit -m $commit_msg

    if not $no_push {
        # Push
        print $"(ansi cyan)Pushing to remote...(ansi reset)"
        let branch = (git branch --show-current)
        git push origin $branch
    }

    print $"\n(ansi green_bold)✅ Quick commit complete!(ansi reset)"
}

# Show current branch info
def "main info" [] {
    print $"(ansi cyan_bold)📊 Branch Information(ansi reset)\n"

    let branch = (git branch --show-current)
    print $"(ansi yellow)Current Branch:(ansi reset) ($branch)"

    # Commit count
    let commits = (git rev-list --count HEAD)
    print $"(ansi yellow)Total Commits:(ansi reset) ($commits)"

    # Contributors
    let contributors = (git shortlog -sn --all | lines | length)
    print $"(ansi yellow)Contributors:(ansi reset) ($contributors)"

    # Last commit
    print $"\n(ansi yellow)Last Commit:(ansi reset)"
    git log -1 --pretty=format:"%h - %s (%cr) <%an>" --color=always
    print ""
}
