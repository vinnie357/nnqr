#!/usr/bin/env nu
# Repeatable developer/playtest operations, exposed by root mise tasks.
const ASTRA_DIR = path self | path dirname

def main [] {
    print "NNQR Astra tools: status | reports | replay <report.zip> | logs"
}

# Show actual artifacts rather than inferring platform validation from unit tests.
def "main status" [] {
    [
        {artifact: "Native screenshot", path: ($ASTRA_DIR | path join ".qa/arena.png")}
        {artifact: "Power screenshot", path: ($ASTRA_DIR | path join ".qa/power.png")}
        {artifact: "Browser build", path: ($ASTRA_DIR | path join "build/web/index.html")}
        {artifact: "Mac export", path: ($ASTRA_DIR | path join "build/native/Astra.zip")}
        {artifact: "Rules test log", path: ($ASTRA_DIR | path join ".logs/tests.log")}
        {artifact: "Controller test log", path: ($ASTRA_DIR | path join ".logs/ui-tests.log")}
    ] | each {|row| $row | insert exists ($row.path | path exists) }
}

# List local reports, newest first. Exported-app reports live in Godot's user directory.
def "main reports" [] {
    let reports = ($ASTRA_DIR | path join ".userdata/reports")
    if not ($reports | path exists) { print "No local reports yet."; return }
    glob ($reports | path join "*.zip") | each {|file| ls $file } | flatten | sort-by modified --reverse
}

# Reconstruct a report's final state through the same authoritative rules used by the game.
def "main replay" [report: path] {
    let source = ($report | path expand)
    mkdir ($ASTRA_DIR | path join ".logs")
    ^bash ($ASTRA_DIR | path join "scripts/godot.sh") --headless --log-file ($ASTRA_DIR | path join ".logs/replay.log") --path $ASTRA_DIR --script res://tools/replay.gd -- $source
    if $env.LAST_EXIT_CODE != 0 { exit $env.LAST_EXIT_CODE }
}

# Last game log lines, useful immediately after an interrupted playtest.
def "main logs" [] {
    let logfile = ($ASTRA_DIR | path join ".logs/astra.log")
    if not ($logfile | path exists) { print "No launch log yet."; return }
    open --raw $logfile | lines | last 60 | str join "\n"
}
