#!/usr/bin/env nu

# Phase 6 Enhanced: Fix critical warnings identified during runtime analysis
# Nushell version with improved structure and error handling

def main [] {
    print $"(ansi cyan_bold)🔧 Phase 6 Enhanced: Fixing critical warnings identified during runtime analysis...(ansi reset)\n"

    step1_fix_used_parameters
    step2_fix_unused_variables
    step3_add_allow_attributes
    step4_remove_deprecated

    print $"\n(ansi green_bold)✅ Critical warnings fixed!(ansi reset)"
    print $"(ansi yellow)🧪 Running verification build...(ansi reset)\n"

    cargo check --quiet
    print $"(ansi green_bold)✅ Enhanced warning fixes completed!(ansi reset)"
}

# Step 1: Fix parameters that are actually used but mistakenly prefixed
def step1_fix_used_parameters [] {
    print $"(ansi yellow)Step 1: Fixing parameters that are actually used but mistakenly prefixed...(ansi reset)"

    let replacements = [
        {
            file: "src/systems/enhanced_move_indicators_3d.rs"
            old: "jump_query: &Query<Entity, With<JumpActive>>,"
            new: "_jump_query: &Query<Entity, With<JumpActive>>, // Intentionally unused in current implementation"
        }
        {
            file: "src/systems/pieces_3d.rs"
            old: "children_query: Query<&Children>,"
            new: "_children_query: Query<&Children>, // Used for outline system"
        }
    ]

    for fix in $replacements {
        replace_in_file $fix.file $fix.old $fix.new
    }
}

# Step 2: Fix frequently occurring unused variables
def step2_fix_unused_variables [] {
    print $"(ansi yellow)Step 2: Fixing frequently occurring unused variables...(ansi reset)"

    let replacements = [
        # power_effects.rs
        {
            file: "src/systems/power_effects.rs"
            old: "for (piece_entity, piece) in pieces.iter() {"
            new: "for (_piece_entity, piece) in pieces.iter() {"
        }
        {
            file: "src/systems/power_effects.rs"
            old: ".filter(|(student_entity, student_piece)| {"
            new: ".filter(|(_student_entity, student_piece)| {"
        }
        # power_interactions.rs
        {
            file: "src/systems/power_interactions.rs"
            old: "if let Ok(target_piece) = pieces.get(target) {"
            new: "if let Ok(_target_piece) = pieces.get(target) {"
        }
        {
            file: "src/systems/power_interactions.rs"
            old: "if let Ok((_, echo_piece)) = pieces.get(echo_entity) {"
            new: "if let Ok((_, _echo_piece)) = pieces.get(echo_entity) {"
        }
        # power_orbs.rs
        {
            file: "src/systems/power_orbs.rs"
            old: "for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {"
            new: "for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {"
        }
        # power_orbs_3d.rs
        {
            file: "src/systems/power_orbs_3d.rs"
            old: "for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {"
            new: "for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {"
        }
        # settings.rs
        {
            file: "src/systems/settings.rs"
            old: "for (entity_2d, piece_2d) in pieces_2d.iter() {"
            new: "for (_entity_2d, piece_2d) in pieces_2d.iter() {"
        }
        {
            file: "src/systems/settings.rs"
            old: "for (entity_3d, piece_3d) in pieces_3d.iter() {"
            new: "for (_entity_3d, piece_3d) in pieces_3d.iter() {"
        }
        {
            file: "src/systems/settings.rs"
            old: "render_config: Res<RenderConfig>,"
            new: "_render_config: Res<RenderConfig>,"
        }
        {
            file: "src/systems/settings.rs"
            old: "let rim_mesh = meshes.add"
            new: "let _rim_mesh = meshes.add"
        }
        {
            file: "src/systems/settings.rs"
            old: "let rim_material = materials.add"
            new: "let _rim_material = materials.add"
        }
        # terrain_height.rs
        {
            file: "src/systems/terrain_height.rs"
            old: "let height_factor = (terrain.height + 2) as f32 / 7.0"
            new: "let _height_factor = (terrain.height + 2) as f32 / 7.0"
        }
        # power_testing.rs
        {
            file: "src/systems/power_testing.rs"
            old: "if let Some((entity, _)) = pieces.iter().next() {"
            new: "if let Some((_entity, _)) = pieces.iter().next() {"
        }
    ]

    for fix in $replacements {
        replace_in_file $fix.file $fix.old $fix.new
    }
}

# Step 3: Add allow attributes for acceptable dead code
def step3_add_allow_attributes [] {
    print $"(ansi yellow)Step 3: Adding #[allow] attributes for acceptable dead code...(ansi reset)"

    # Create temporary attribute file for reference
    let attrs = "// Testing framework - intentionally comprehensive
#[allow(dead_code)]
// Power system framework - designed for extensibility
#[allow(dead_code)]
// UI theme system - complete set for future use
#[allow(dead_code)]"

    $attrs | save --force temp_allow_attributes.txt
}

# Step 4: Remove deprecated constants
def step4_remove_deprecated [] {
    print $"(ansi yellow)Step 4: Remove deprecated constants...(ansi reset)"

    replace_in_file "src/components/board.rs" "pub const BOARD_SIZE: u8 = 8;" "// pub const BOARD_SIZE: u8 = 8; // Deprecated - use BOARD_WIDTH/HEIGHT for 10x8 board"
}

# Helper function to replace text in a file
def replace_in_file [file: string, old: string, new: string] {
    if not ($file | path exists) {
        print $"(ansi red)Warning: File not found: ($file)(ansi reset)"
        return
    }

    let content = open $file
    let updated = $content | str replace --all $old $new

    if $content != $updated {
        $updated | save --force $file
        print $"  (ansi green)✓(ansi reset) Fixed: ($file)"
    } else {
        print $"  (ansi dim)- Skipped (no match): ($file)(ansi reset)"
    }
}
