#!/usr/bin/env nu

# Quadradius Power System Test
# Nushell version

def main [] {
    print $"(ansi green_bold)Starting Quadradius Power System Test(ansi reset)"
    print "====================================="
    print ""
    print $"(ansi cyan_bold)Debug Controls:(ansi reset)"
    print "  P - Spawn a random power orb"
    print "  O - Display current player's powers"
    print "  I - Generate power test report"
    print "  Space - End turn"
    print ""
    print $"(ansi yellow_bold)Test Instructions:(ansi reset)"
    print "  1. Press P to spawn power orbs"
    print "  2. Move pieces to collect orbs"
    print "  3. Press O to verify collection"
    print "  4. Powers should activate during power phase"
    print ""
    print $"(ansi green)Starting game...(ansi reset)"
    print ""

    cargo run
}
