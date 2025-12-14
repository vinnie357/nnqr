#!/usr/bin/env nu

# Phase 6: Fix all unused variable warnings
# Nushell version with structured approach and better error handling

def main [] {
    print $"(ansi cyan_bold)🔧 Phase 6: Fixing all unused variable warnings...(ansi reset)\n"

    fix_power_effects
    fix_power_interactions
    fix_power_orbs
    fix_power_orbs_3d
    fix_power_test_report
    fix_power_testing
    fix_settings
    fix_terrain_height
    fix_visual_effects

    print $"\n(ansi green_bold)✅ Fixed main systems unused variables!(ansi reset)"
    print $"(ansi yellow)🔧 Now fixing test files...(ansi reset)\n"

    fix_test_arrays
    fix_test_unused_variables

    print $"\n(ansi green_bold)✅ All unused variable warnings should now be fixed!(ansi reset)"
    print $"(ansi yellow)🧪 Running cargo check to verify...(ansi reset)\n"

    cargo check --all-targets
}

# Fix power_effects.rs unused variables
def fix_power_effects [] {
    print $"(ansi yellow)Fixing power_effects.rs...(ansi reset)"

    let file = "src/systems/power_effects.rs"
    let fixes = [
        ["for (piece_entity, piece) in pieces.iter() {" "for (_piece_entity, piece) in pieces.iter() {"]
        [".filter(|(student_entity, student_piece)| {" ".filter(|(_student_entity, student_piece)| {"]
        ["commands: &mut Commands," "_commands: &mut Commands,"]
        ["powers: &[PowerType]," "_powers: &[PowerType],"]
        ["pieces: &Query<(Entity, &GamePiece)>," "_pieces: &Query<(Entity, &GamePiece)>,"]
    ]

    apply_fixes $file $fixes
}

# Fix power_interactions.rs unused variables
def fix_power_interactions [] {
    print $"(ansi yellow)Fixing power_interactions.rs...(ansi reset)"

    let file = "src/systems/power_interactions.rs"
    let fixes = [
        ["if let Ok(target_piece) = pieces.get(target) {" "if let Ok(_target_piece) = pieces.get(target) {"]
        ["commands: &mut Commands," "_commands: &mut Commands,"]
        ["pieces: &Query<(Entity, &GamePiece)>," "_pieces: &Query<(Entity, &GamePiece)>,"]
        ["if let Ok((_, echo_piece)) = pieces.get(echo_entity) {" "if let Ok((_, _echo_piece)) = pieces.get(echo_entity) {"]
    ]

    apply_fixes $file $fixes
}

# Fix power_orbs.rs unused variables
def fix_power_orbs [] {
    print $"(ansi yellow)Fixing power_orbs.rs...(ansi reset)"

    let file = "src/systems/power_orbs.rs"
    let fixes = [
        ["for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {" "for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {"]
    ]

    apply_fixes $file $fixes
}

# Fix power_orbs_3d.rs unused variables
def fix_power_orbs_3d [] {
    print $"(ansi yellow)Fixing power_orbs_3d.rs...(ansi reset)"

    let file = "src/systems/power_orbs_3d.rs"
    let fixes = [
        ["for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {" "for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {"]
    ]

    apply_fixes $file $fixes
}

# Fix power_test_report.rs unused variables
def fix_power_test_report [] {
    print $"(ansi yellow)Fixing power_test_report.rs...(ansi reset)"

    let file = "src/systems/power_test_report.rs"
    let fixes = [
        ["commands: Commands," "_commands: Commands,"]
        ["pieces: Query<(Entity, &GamePiece)>," "_pieces: Query<(Entity, &GamePiece)>,"]
    ]

    apply_fixes $file $fixes
}

# Fix power_testing.rs unused variables
def fix_power_testing [] {
    print $"(ansi yellow)Fixing power_testing.rs...(ansi reset)"

    let file = "src/systems/power_testing.rs"
    let fixes = [
        ["if let Some((entity, _)) = pieces.iter().next() {" "if let Some((_entity, _)) = pieces.iter().next() {"]
    ]

    apply_fixes $file $fixes
}

# Fix settings.rs unused variables
def fix_settings [] {
    print $"(ansi yellow)Fixing settings.rs...(ansi reset)"

    let file = "src/systems/settings.rs"
    let fixes = [
        ["for (entity_2d, piece_2d) in pieces_2d.iter() {" "for (_entity_2d, piece_2d) in pieces_2d.iter() {"]
        ["for (entity_3d, piece_3d) in pieces_3d.iter() {" "for (_entity_3d, piece_3d) in pieces_3d.iter() {"]
        ["render_config: Res<RenderConfig>," "_render_config: Res<RenderConfig>,"]
        ["let rim_mesh = meshes.add(Mesh::from(shape::Torus {" "let _rim_mesh = meshes.add(Mesh::from(shape::Torus {"]
        ["let rim_material = materials.add(StandardMaterial {" "let _rim_material = materials.add(StandardMaterial {"]
    ]

    apply_fixes $file $fixes
}

# Fix terrain_height.rs unused variables
def fix_terrain_height [] {
    print $"(ansi yellow)Fixing terrain_height.rs...(ansi reset)"

    let file = "src/systems/terrain_height.rs"
    let fixes = [
        ["let height_factor = (terrain.height + 2) as f32 / 7.0; // Normalize to 0-1" "let _height_factor = (terrain.height + 2) as f32 / 7.0; // Normalize to 0-1"]
    ]

    apply_fixes $file $fixes
}

# Fix visual_effects.rs unused variables
def fix_visual_effects [] {
    print $"(ansi yellow)Fixing visual_effects.rs...(ansi reset)"

    let file = "src/systems/visual_effects.rs"
    let fixes = [
        ["commands: &mut Commands," "_commands: &mut Commands,"]
    ]

    apply_fixes $file $fixes
}

# Fix test arrays (convert vec! to array literals)
def fix_test_arrays [] {
    print $"(ansi yellow)Fixing test arrays...(ansi reset)"

    let test_files = glob src/tests/**/*.rs

    let array_fixes = [
        ["let p1_pieces = vec![" "let p1_pieces = ["]
        ["let p2_pieces = vec![" "let p2_pieces = ["]
        ["let test_positions = vec![" "let test_positions = ["]
        ["let piece_positions = vec![" "let piece_positions = ["]
        ["let piece_positions_friendly = vec![" "let piece_positions_friendly = ["]
    ]

    for file in $test_files {
        apply_fixes $file $array_fixes
    }

    print $"(ansi green)✅ Fixed test arrays!(ansi reset)"
}

# Fix unused variables in test files
def fix_test_unused_variables [] {
    print $"(ansi yellow)Fixing unused variables in tests...(ansi reset)"

    let test_files = glob src/tests/**/*.rs

    let test_fixes = [
        ["let world = &mut app.world;" "let _world = &mut app.world;"]
        ["let player1_piece = world" "let _player1_piece = world"]
        ["let player2_piece = world" "let _player2_piece = world"]
        ["let another_player1_piece = world" "let _another_player1_piece = world"]
        ["let p1_piece1 = world" "let _p1_piece1 = world"]
        ["let p1_piece2 = world" "let _p1_piece2 = world"]
        ["let p2_piece1 = world" "let _p2_piece1 = world"]
        ["let p2_piece2 = world" "let _p2_piece2 = world"]
        ["let p1_piece = world" "let _p1_piece = world"]
        ["let p2_piece = world" "let _p2_piece = world"]
    ]

    for file in $test_files {
        apply_fixes $file $test_fixes
    }
}

# Helper function to apply a list of fixes to a file
def apply_fixes [file: string, fixes: list] {
    if not ($file | path exists) {
        print $"  (ansi red)Warning: File not found: ($file)(ansi reset)"
        return
    }

    mut content = open $file
    mut changes = 0

    for fix in $fixes {
        let old = $fix.0
        let new = $fix.1
        let updated = $content | str replace --all $old $new

        if $content != $updated {
            $content = $updated
            $changes = $changes + 1
        }
    }

    if $changes > 0 {
        $content | save --force $file
        print $"  (ansi green)✓(ansi reset) Fixed ($changes) issues in: ($file)"
    } else {
        print $"  (ansi dim)- No changes needed: ($file)(ansi reset)"
    }
}
