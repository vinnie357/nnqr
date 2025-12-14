#!/bin/bash

echo "🔧 Phase 6: Fixing all unused variable warnings..."

# Fix power_effects.rs unused variables
echo "Fixing power_effects.rs..."
sed -i 's/for (piece_entity, piece) in pieces.iter() {/for (_piece_entity, piece) in pieces.iter() {/g' src/systems/power_effects.rs
sed -i 's/\.filter(|(student_entity, student_piece)| {/.filter(|(_student_entity, student_piece)| {/g' src/systems/power_effects.rs
sed -i 's/commands: &mut Commands,/_commands: &mut Commands,/g' src/systems/power_effects.rs
sed -i 's/powers: &\[PowerType\],/_powers: &[PowerType],/g' src/systems/power_effects.rs
sed -i 's/pieces: &Query<(Entity, &GamePiece)>,/_pieces: &Query<(Entity, &GamePiece)>,/g' src/systems/power_effects.rs

# Fix power_interactions.rs unused variables
echo "Fixing power_interactions.rs..."
sed -i 's/if let Ok(target_piece) = pieces.get(target) {/if let Ok(_target_piece) = pieces.get(target) {/g' src/systems/power_interactions.rs
sed -i 's/commands: &mut Commands,/_commands: &mut Commands,/g' src/systems/power_interactions.rs
sed -i 's/pieces: &Query<(Entity, &GamePiece)>,/_pieces: &Query<(Entity, &GamePiece)>,/g' src/systems/power_interactions.rs
sed -i 's/if let Ok((_, echo_piece)) = pieces.get(echo_entity) {/if let Ok((_, _echo_piece)) = pieces.get(echo_entity) {/g' src/systems/power_interactions.rs

# Fix power_orbs.rs unused variables
echo "Fixing power_orbs.rs..."
sed -i 's/for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {/for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {/g' src/systems/power_orbs.rs

# Fix power_orbs_3d.rs unused variables
echo "Fixing power_orbs_3d.rs..."
sed -i 's/for (piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {/for (_piece_entity, piece, mut piece_inventory) in pieces.iter_mut() {/g' src/systems/power_orbs_3d.rs

# Fix power_test_report.rs unused variables
echo "Fixing power_test_report.rs..."
sed -i 's/commands: Commands,/_commands: Commands,/g' src/systems/power_test_report.rs
sed -i 's/pieces: Query<(Entity, &GamePiece)>,/_pieces: Query<(Entity, &GamePiece)>,/g' src/systems/power_test_report.rs

# Fix power_testing.rs unused variables
echo "Fixing power_testing.rs..."
sed -i 's/if let Some((entity, _)) = pieces.iter().next() {/if let Some((_entity, _)) = pieces.iter().next() {/g' src/systems/power_testing.rs

# Fix settings.rs unused variables
echo "Fixing settings.rs..."
sed -i 's/for (entity_2d, piece_2d) in pieces_2d.iter() {/for (_entity_2d, piece_2d) in pieces_2d.iter() {/g' src/systems/settings.rs
sed -i 's/for (entity_3d, piece_3d) in pieces_3d.iter() {/for (_entity_3d, piece_3d) in pieces_3d.iter() {/g' src/systems/settings.rs
sed -i 's/render_config: Res<RenderConfig>,/_render_config: Res<RenderConfig>,/g' src/systems/settings.rs
sed -i 's/let rim_mesh = meshes.add(Mesh::from(shape::Torus {/let _rim_mesh = meshes.add(Mesh::from(shape::Torus {/g' src/systems/settings.rs
sed -i 's/let rim_material = materials.add(StandardMaterial {/let _rim_material = materials.add(StandardMaterial {/g' src/systems/settings.rs

# Fix terrain_height.rs unused variables
echo "Fixing terrain_height.rs..."
sed -i 's/let height_factor = (terrain.height + 2) as f32 \/ 7.0; \/\/ Normalize to 0-1/let _height_factor = (terrain.height + 2) as f32 \/ 7.0; \/\/ Normalize to 0-1/g' src/systems/terrain_height.rs

# Fix visual_effects.rs unused variables
echo "Fixing visual_effects.rs..."
sed -i 's/commands: &mut Commands,/_commands: &mut Commands,/g' src/systems/visual_effects.rs

echo "✅ Fixed main systems unused variables!"
echo "🔧 Now fixing test files..."

# Fix tests with useless vec! usage
find src/tests -name "*.rs" -exec sed -i 's/let p1_pieces = vec!\[/let p1_pieces = [/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p2_pieces = vec!\[/let p2_pieces = [/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let test_positions = vec!\[/let test_positions = [/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let piece_positions = vec!\[/let piece_positions = [/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let piece_positions_friendly = vec!\[/let piece_positions_friendly = [/g' {} \;

# Close the arrays properly
find src/tests -name "*.rs" -exec sed -i 's/\];$/];/g' {} \;

echo "✅ Fixed test arrays!"
echo "🔧 Fixing unused variables in tests..."

# Fix unused variables in test files
find src/tests -name "*.rs" -exec sed -i 's/let world = &mut app.world;/let _world = \&mut app.world;/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let player1_piece = world/let _player1_piece = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let player2_piece = world/let _player2_piece = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let another_player1_piece = world/let _another_player1_piece = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p1_piece1 = world/let _p1_piece1 = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p1_piece2 = world/let _p1_piece2 = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p2_piece1 = world/let _p2_piece1 = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p2_piece2 = world/let _p2_piece2 = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p1_piece = world/let _p1_piece = world/g' {} \;
find src/tests -name "*.rs" -exec sed -i 's/let p2_piece = world/let _p2_piece = world/g' {} \;

echo "✅ All unused variable warnings should now be fixed!"
echo "🧪 Running cargo check to verify..."

cargo check --all-targets