use crate::components::*;
use crate::resources::*;
use bevy::prelude::*;

/// Component to mark area targeting indicators
#[derive(Component)]
pub struct AreaTargetingIndicator {
    pub center: (u8, u8),
    pub size: u8, // 3 for 3x3, 5 for 5x5, etc.
    pub power_type: PowerType,
}

/// Resource to track area targeting state
#[derive(Resource, Default)]
pub struct AreaTargetingState {
    pub active: bool,
    pub power_type: Option<PowerType>,
    pub target_size: u8,
    pub preview_center: Option<(u8, u8)>,
}

/// System to handle area targeting for powers
pub fn handle_area_targeting(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform), (With<crate::systems::settings::Camera2D>, With<Camera>)>,
    mut area_state: ResMut<AreaTargetingState>,
    game_state: Res<GameState>,
    existing_indicators: Query<Entity, With<AreaTargetingIndicator>>,
) {
    // Only process if area targeting is active
    if !area_state.active {
        return;
    }

    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();

    // Clear old indicators
    for indicator in existing_indicators.iter() {
        commands.entity(indicator).despawn();
    }

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let board_pos = world_to_board_position(world_pos);
            area_state.preview_center = Some(board_pos);

            // Show area preview
            spawn_area_preview(&mut commands, board_pos, area_state.target_size, area_state.power_type.unwrap());

            // Handle click to confirm targeting
            if mouse_input.just_pressed(MouseButton::Left) {
                if let Some(power_type) = area_state.power_type {
                    execute_area_power(&mut commands, board_pos, area_state.target_size, power_type, &game_state);
                }
                
                // Disable area targeting
                area_state.active = false;
                area_state.power_type = None;
                area_state.preview_center = None;
            }
        }
    }

    // Cancel targeting with right click
    if mouse_input.just_pressed(MouseButton::Right) {
        area_state.active = false;
        area_state.power_type = None;
        area_state.preview_center = None;
    }
}

/// Start area targeting for a specific power
pub fn start_area_targeting(
    area_state: &mut ResMut<AreaTargetingState>,
    power_type: PowerType,
) {
    area_state.active = true;
    area_state.power_type = Some(power_type);
    area_state.target_size = get_power_area_size(power_type);
    area_state.preview_center = None;
    
    println!("🎯 Area targeting started for {:?} ({}x{} area)", 
            power_type, area_state.target_size, area_state.target_size);
}

/// Get the area size for different powers
fn get_power_area_size(power_type: PowerType) -> u8 {
    match power_type {
        PowerType::SmartBomb 
        | PowerType::RaiseArea 
        | PowerType::LowerArea 
        | PowerType::Rotate 
        | PowerType::Shuffle 
        | PowerType::TeachRadial 
        | PowerType::RecruitRadial => 3,
        PowerType::Earthquake => 5, // Larger area for earthquake
        _ => 3, // Default to 3x3
    }
}

/// Spawn visual preview of the targeting area
fn spawn_area_preview(
    commands: &mut Commands,
    center: (u8, u8),
    size: u8,
    power_type: PowerType,
) {
    let half_size = size / 2;
    let color = get_area_preview_color(power_type);

    for dx in -(half_size as i8)..=(half_size as i8) {
        for dy in -(half_size as i8)..=(half_size as i8) {
            let target_x = center.0 as i8 + dx;
            let target_y = center.1 as i8 + dy;

            if target_x >= 0 && target_x < BOARD_WIDTH as i8 
                && target_y >= 0 && target_y < BOARD_HEIGHT as i8 {
                
                let world_pos = board_to_world_position((target_x as u8, target_y as u8));
                
                commands.spawn((
                    AreaTargetingIndicator {
                        center,
                        size,
                        power_type,
                    },
                    SpriteBundle {
                        sprite: Sprite {
                            color: Color::rgba(color.r(), color.g(), color.b(), 0.4),
                            custom_size: Some(Vec2::splat(TILE_SIZE * 0.9)),
                            ..default()
                        },
                        transform: Transform::from_xyz(world_pos.x, world_pos.y, 5.0),
                        ..default()
                    },
                ));
            }
        }
    }

    // Spawn center indicator
    let world_pos = board_to_world_position(center);
    commands.spawn((
        AreaTargetingIndicator {
            center,
            size,
            power_type,
        },
        SpriteBundle {
            sprite: Sprite {
                color,
                custom_size: Some(Vec2::splat(TILE_SIZE * 0.5)),
                ..default()
            },
            transform: Transform::from_xyz(world_pos.x, world_pos.y, 6.0),
            ..default()
        },
    ));
}

/// Get color for area preview based on power type
fn get_area_preview_color(power_type: PowerType) -> Color {
    match power_type {
        PowerType::SmartBomb => Color::rgb(1.0, 0.2, 0.2), // Red for destruction
        PowerType::RaiseArea => Color::rgb(0.4, 0.8, 0.4), // Green for raising
        PowerType::LowerArea => Color::rgb(0.8, 0.6, 0.3), // Brown for lowering
        PowerType::Rotate => Color::rgb(0.6, 0.8, 0.6), // Light green for rotation
        PowerType::Shuffle => Color::rgb(0.7, 0.5, 0.7), // Purple for shuffle
        PowerType::Earthquake => Color::rgb(0.6, 0.4, 0.2), // Brown for earthquake
        PowerType::TeachRadial => Color::rgb(0.0, 0.8, 1.0), // Cyan for teaching
        PowerType::RecruitRadial => Color::rgb(1.0, 0.8, 0.4), // Gold for recruitment
        _ => Color::rgb(0.8, 0.8, 0.8), // Default gray
    }
}

/// Execute an area-effect power
fn execute_area_power(
    commands: &mut Commands,
    center: (u8, u8),
    size: u8,
    power_type: PowerType,
    game_state: &GameState,
) {
    let half_size = size / 2;
    let mut affected_positions = Vec::new();

    // Collect all positions in the area
    for dx in -(half_size as i8)..=(half_size as i8) {
        for dy in -(half_size as i8)..=(half_size as i8) {
            let target_x = center.0 as i8 + dx;
            let target_y = center.1 as i8 + dy;

            if target_x >= 0 && target_x < BOARD_WIDTH as i8 
                && target_y >= 0 && target_y < BOARD_HEIGHT as i8 {
                affected_positions.push((target_x as u8, target_y as u8));
            }
        }
    }

    // Execute the power effect
    match power_type {
        PowerType::SmartBomb => {
            execute_smart_bomb_area(commands, &affected_positions);
        }
        PowerType::RaiseArea => {
            execute_raise_area(commands, &affected_positions);
        }
        PowerType::LowerArea => {
            execute_lower_area(commands, &affected_positions);
        }
        PowerType::Shuffle => {
            execute_shuffle_area(commands, &affected_positions);
        }
        PowerType::TeachRadial => {
            execute_teach_radial(commands, &affected_positions, game_state);
        }
        PowerType::RecruitRadial => {
            execute_recruit_radial(commands, &affected_positions, game_state);
        }
        _ => {
            println!("Area effect for {:?} not yet implemented", power_type);
        }
    }

    // Spawn area effect visual
    let world_pos = board_to_world_position(center);
    crate::systems::visual_effects::spawn_power_activation_particles(
        commands,
        Vec3::new(world_pos.x, world_pos.y, 0.0),
        power_type,
    );

    println!("💥 {} activated on {}x{} area at {:?}", 
            power_type.name(), size, size, center);
}

/// Execute SmartBomb area effect
fn execute_smart_bomb_area(
    commands: &mut Commands,
    affected_positions: &[(u8, u8)],
) {
    for &pos in affected_positions {
        // Find pieces at this position and destroy them
        // This would need to query pieces and despawn them
        // For now, just spawn explosion effects
        let world_pos = board_to_world_position(pos);
        crate::systems::visual_effects::spawn_capture_explosion(
            commands,
            Vec3::new(world_pos.x, world_pos.y, 0.0),
            Color::rgb(1.0, 0.3, 0.0), // Orange explosion
        );
    }
    println!("💥 SmartBomb destroyed pieces in {} positions", affected_positions.len());
}

/// Execute RaiseArea effect
fn execute_raise_area(
    commands: &mut Commands,
    affected_positions: &[(u8, u8)],
) {
    for &pos in affected_positions {
        // This would use the terrain height system to raise tiles
        // For now, just spawn visual effects
        let world_pos = board_to_world_position(pos);
        commands.spawn((
            SpriteBundle {
                sprite: Sprite {
                    color: Color::rgba(0.4, 0.8, 0.4, 0.7),
                    custom_size: Some(Vec2::splat(TILE_SIZE * 0.8)),
                    ..default()
                },
                transform: Transform::from_xyz(world_pos.x, world_pos.y, 4.0),
                ..default()
            },
            // Add a timer to fade out this effect
        ));
    }
    println!("⬆️ Raised {} tiles", affected_positions.len());
}

/// Execute LowerArea effect
fn execute_lower_area(
    commands: &mut Commands,
    affected_positions: &[(u8, u8)],
) {
    for &pos in affected_positions {
        let world_pos = board_to_world_position(pos);
        commands.spawn((
            SpriteBundle {
                sprite: Sprite {
                    color: Color::rgba(0.8, 0.6, 0.3, 0.7),
                    custom_size: Some(Vec2::splat(TILE_SIZE * 0.8)),
                    ..default()
                },
                transform: Transform::from_xyz(world_pos.x, world_pos.y, 4.0),
                ..default()
            },
        ));
    }
    println!("⬇️ Lowered {} tiles", affected_positions.len());
}

/// Execute Shuffle area effect
fn execute_shuffle_area(
    commands: &mut Commands,
    affected_positions: &[(u8, u8)],
) {
    // This would shuffle pieces within the area
    // For now, just spawn visual effects
    for &pos in affected_positions {
        let world_pos = board_to_world_position(pos);
        crate::systems::visual_effects::spawn_power_activation_particles(
            commands,
            Vec3::new(world_pos.x, world_pos.y, 0.0),
            PowerType::Shuffle,
        );
    }
    println!("🔀 Shuffled pieces in {} positions", affected_positions.len());
}

/// Execute TeachRadial effect
fn execute_teach_radial(
    commands: &mut Commands,
    affected_positions: &[(u8, u8)],
    game_state: &GameState,
) {
    // This would share powers with friendly pieces in the area
    for &pos in affected_positions {
        let world_pos = board_to_world_position(pos);
        commands.spawn((
            SpriteBundle {
                sprite: Sprite {
                    color: Color::rgba(0.0, 0.8, 1.0, 0.7),
                    custom_size: Some(Vec2::splat(TILE_SIZE * 0.6)),
                    ..default()
                },
                transform: Transform::from_xyz(world_pos.x, world_pos.y, 4.0),
                ..default()
            },
        ));
    }
    println!("📚 Taught powers to friendly pieces in {} positions", affected_positions.len());
}

/// Execute RecruitRadial effect
fn execute_recruit_radial(
    commands: &mut Commands,
    affected_positions: &[(u8, u8)],
    game_state: &GameState,
) {
    // This would convert enemy pieces in the area
    for &pos in affected_positions {
        let world_pos = board_to_world_position(pos);
        crate::systems::visual_effects::spawn_capture_explosion(
            commands,
            Vec3::new(world_pos.x, world_pos.y, 0.0),
            Color::rgb(1.0, 0.8, 0.4), // Gold recruitment effect
        );
    }
    println!("🔄 Recruited enemy pieces in {} positions", affected_positions.len());
}

/// Helper function for coordinate conversion
fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    use crate::components::board::{BOARD_WIDTH, BOARD_HEIGHT};
    use crate::components::TILE_SIZE;
    
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

/// Helper function for coordinate conversion
fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    use crate::components::board::{BOARD_WIDTH, BOARD_HEIGHT};
    use crate::components::TILE_SIZE;
    
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = ((world_pos.x / enhanced_tile_size) + BOARD_WIDTH as f32 / 2.0 - 0.5).round() as i8;
    let y = ((world_pos.y / enhanced_tile_size) + BOARD_HEIGHT as f32 / 2.0 - 0.5).round() as i8;

    let x = x.max(0).min(BOARD_WIDTH as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_HEIGHT as i8 - 1) as u8;

    (x, y)
}

/// Import constants
use crate::components::board::{BOARD_WIDTH, BOARD_HEIGHT};
use crate::components::TILE_SIZE;