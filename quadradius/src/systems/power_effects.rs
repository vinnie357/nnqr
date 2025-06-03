use crate::{components::*, resources::*};
use crate::systems::TerrainHeight;
use bevy::prelude::*;

#[derive(Component)]
pub struct PowerTargetIndicator;

#[derive(Component)]
pub struct ActivePowerEffect {
    pub power_type: PowerType,
}

// Component to mark pieces that have Move Diagonal active
#[derive(Component)]
pub struct MoveDiagonalActive;

pub fn handle_power_selection(
    mut commands: Commands,
    game_state: Res<GameState>,
    indicators: Query<Entity, With<PowerTargetIndicator>>,
) {
    // Clear old indicators
    for entity in indicators.iter() {
        commands.entity(entity).despawn();
    }

    if let Some(power_index) = game_state.selected_power {
        let powers = game_state.get_current_player_powers();
        if let Some(&power_type) = powers.get(power_index) {
            match power_type {
                // Powers that apply to all pieces
                PowerType::MoveDiagonal | PowerType::Teleport | PowerType::Jump | 
                PowerType::MoveTwo | PowerType::Knight | PowerType::MoveTwice |
                PowerType::Slide => {
                    // No targeting needed - applies to current player's pieces
                    spawn_power_ready_indicator(&mut commands);
                }
                
                // Column targeting powers
                PowerType::RaiseColumn | PowerType::LowerColumn | PowerType::DestroyColumn => {
                    // Need to target a column
                    spawn_column_target_indicators(&mut commands);
                }
                
                // Piece targeting powers
                PowerType::Multiply | PowerType::Swap | PowerType::Push | PowerType::Pull |
                PowerType::Recruit | PowerType::Freeze | PowerType::Sniper | PowerType::Assassin => {
                    // Need to target a piece
                    spawn_piece_target_indicators(&mut commands, &game_state);
                }
                
                // Area targeting powers
                PowerType::SmartBomb | PowerType::RaiseArea | PowerType::LowerArea |
                PowerType::Rotate | PowerType::Shuffle | PowerType::Earthquake => {
                    // Need to target an area
                    spawn_area_target_indicators(&mut commands);
                }
                
                // Special targeting or no targeting
                _ => {
                    spawn_power_ready_indicator(&mut commands);
                }
            }
        }
    }
}

fn spawn_power_ready_indicator(commands: &mut Commands) {
    commands.spawn((
        PowerTargetIndicator,
        Text2dBundle {
            text: Text::from_section(
                "Power Ready! Click to activate",
                TextStyle {
                    font_size: 24.0,
                    color: Color::rgb(0.2, 1.0, 0.2),
                    ..default()
                },
            ),
            transform: Transform::from_xyz(0.0, 200.0, 10.0),
            ..default()
        },
    ));
}

fn spawn_column_target_indicators(commands: &mut Commands) {
    for x in 0..BOARD_SIZE {
        for y in 0..BOARD_SIZE {
            let world_pos = board_to_world_position((x, y));
            commands.spawn((
                PowerTargetIndicator,
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(1.0, 1.0, 0.0, 0.2), // Yellow transparent
                        custom_size: Some(Vec2::splat(TILE_SIZE * 0.95)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 3.0),
                    ..default()
                },
            ));
        }
    }
}

fn spawn_piece_target_indicators(commands: &mut Commands, game_state: &GameState) {
    // For now, show indicators on all tiles since we need piece positions
    // In a real implementation, we'd query for piece positions and only show indicators there
    for x in 0..BOARD_SIZE {
        for y in 0..BOARD_SIZE {
            let world_pos = board_to_world_position((x, y));
            commands.spawn((
                PowerTargetIndicator,
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(0.0, 1.0, 1.0, 0.3), // Cyan transparent
                        custom_size: Some(Vec2::splat(TILE_SIZE * 0.85)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 3.0),
                    ..default()
                },
            ));
        }
    }
}

fn spawn_area_target_indicators(commands: &mut Commands) {
    // Highlight 3x3 areas for area-effect powers
    for x in 1..BOARD_SIZE-1 {
        for y in 1..BOARD_SIZE-1 {
            let world_pos = board_to_world_position((x, y));
            commands.spawn((
                PowerTargetIndicator,
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(1.0, 0.5, 0.0, 0.25), // Orange transparent
                        custom_size: Some(Vec2::splat(TILE_SIZE * 3.0)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 3.0),
                    ..default()
                },
            ));
        }
    }
}

pub fn handle_power_activation(
    mut commands: Commands,
    mouse_input: Res<Input<MouseButton>>,
    windows: Query<&Window>,
    camera_q: Query<(&Camera, &GlobalTransform)>,
    mut game_state: ResMut<GameState>,
    mut tile_queries: ParamSet<(
        Query<&BoardTile>,
        Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    )>,
    pieces: Query<(Entity, &GamePiece)>,
    indicators: Query<Entity, With<PowerTargetIndicator>>,
) {
    // Only handle during power phase with selected power
    if game_state.turn_phase != TurnPhase::PowerActivation || game_state.selected_power.is_none() {
        return;
    }

    if !mouse_input.just_pressed(MouseButton::Left) {
        return;
    }

    let window = windows.single();
    let (camera, camera_transform) = camera_q.single();

    if let Some(cursor_pos) = window.cursor_position() {
        if let Some(world_pos) = camera.viewport_to_world_2d(camera_transform, cursor_pos) {
            let board_pos = world_to_board_position(world_pos);

            if let Some(power_index) = game_state.selected_power {
                let powers = game_state.get_current_player_powers().clone();
                if let Some(&power_type) = powers.get(power_index) {
                    let activated = match power_type {
                        // Phase 2 powers
                        PowerType::MoveDiagonal => {
                            activate_move_diagonal(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::RaiseColumn => {
                            // Use the new terrain height system
                            use crate::systems::terrain_height::raise_column;
                            raise_column(board_pos.0, &mut tile_queries.p1(), &mut commands);
                            true
                        }
                        PowerType::LowerColumn => {
                            // Use the new terrain height system
                            use crate::systems::terrain_height::lower_column;
                            lower_column(board_pos.0, &mut tile_queries.p1(), &mut commands);
                            true
                        }
                        PowerType::DestroyColumn => {
                            // Use the new terrain height system
                            use crate::systems::terrain_height::destroy_column;
                            destroy_column(board_pos.0, &mut tile_queries.p1(), &pieces, &mut commands);
                            true
                        }
                        PowerType::Multiply => {
                            activate_multiply(&mut commands, board_pos, &game_state, &pieces, &tile_queries.p0())
                        }
                        
                        // Movement powers (Phase 3)
                        PowerType::Teleport => {
                            use crate::systems::movement_powers::activate_teleport;
                            activate_teleport(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::Jump => {
                            use crate::systems::movement_powers::activate_jump;
                            activate_jump(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::MoveTwo => {
                            use crate::systems::movement_powers::activate_move_two;
                            activate_move_two(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::Knight => {
                            use crate::systems::movement_powers::activate_knight;
                            activate_knight(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::MoveTwice => {
                            // Special case - modifies turn structure
                            println!("Move Twice activated - implement turn modification");
                            true
                        }
                        PowerType::Slide => {
                            use crate::systems::movement_powers::activate_slide;
                            activate_slide(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::Freeze => {
                            // Freeze needs to target an opponent piece
                            println!("Freeze activated - select target piece");
                            false // Need targeting UI
                        }
                        PowerType::Assassin => {
                            // Assassin removes any piece instantly
                            if let Some(target_piece) = pieces.iter().find(|(_, p)| p.board_position == board_pos) {
                                commands.entity(target_piece.0).despawn();
                                
                                // Spawn explosion effect
                                let world_pos = board_to_world_position(board_pos);
                                crate::systems::visual_effects::spawn_capture_explosion(
                                    &mut commands,
                                    Vec3::new(world_pos.x, world_pos.y, 0.0),
                                    Color::rgb(0.8, 0.0, 0.0), // Red explosion for assassin
                                );
                                
                                println!("Assassin eliminated piece at {:?}", board_pos);
                                true
                            } else {
                                println!("No piece at target location");
                                false
                            }
                        }
                        PowerType::Sniper => {
                            // Sniper can eliminate any enemy piece
                            if let Some((entity, piece)) = pieces.iter().find(|(_, p)| p.board_position == board_pos) {
                                if piece.player != game_state.current_player {
                                    commands.entity(entity).despawn();
                                    
                                    let world_pos = board_to_world_position(board_pos);
                                    crate::systems::visual_effects::spawn_capture_explosion(
                                        &mut commands,
                                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                                        Color::rgb(1.0, 0.5, 0.0), // Orange explosion for sniper
                                    );
                                    
                                    println!("Sniper eliminated enemy piece at {:?}", board_pos);
                                    true
                                } else {
                                    println!("Cannot snipe your own pieces!");
                                    false
                                }
                            } else {
                                println!("No piece at target location");
                                false
                            }
                        }
                        PowerType::SmartBomb => {
                            // SmartBomb destroys all pieces in 3x3 area
                            let mut destroyed = 0;
                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let target_x = board_pos.0 as i8 + dx;
                                    let target_y = board_pos.1 as i8 + dy;
                                    
                                    if target_x >= 0 && target_x < BOARD_SIZE as i8 && 
                                       target_y >= 0 && target_y < BOARD_SIZE as i8 {
                                        let target = (target_x as u8, target_y as u8);
                                        
                                        if let Some((entity, _)) = pieces.iter().find(|(_, p)| p.board_position == target) {
                                            commands.entity(entity).despawn();
                                            destroyed += 1;
                                        }
                                    }
                                }
                            }
                            
                            if destroyed > 0 {
                                let world_pos = board_to_world_position(board_pos);
                                // Big explosion for smart bomb
                                for _ in 0..3 {
                                    crate::systems::visual_effects::spawn_capture_explosion(
                                        &mut commands,
                                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                                        Color::rgb(1.0, 0.3, 0.0),
                                    );
                                }
                                
                                println!("SmartBomb destroyed {} pieces!", destroyed);
                                true
                            } else {
                                println!("No pieces in blast radius");
                                false
                            }
                        }
                        
                        // Powers that need specific targets will show indicators
                        _ => {
                            println!("Power {} not yet implemented", power_type.name());
                            false
                        }
                    };

                    if activated {
                        // Spawn power activation visual effects
                        let world_pos = board_to_world_position(board_pos);
                        crate::systems::visual_effects::spawn_power_activation_particles(
                            &mut commands,
                            Vec3::new(world_pos.x, world_pos.y, 0.0),
                            power_type,
                        );
                        
                        // Spawn floating text
                        crate::systems::visual_effects::spawn_floating_text(
                            &mut commands,
                            Vec3::new(world_pos.x, world_pos.y, 0.0),
                            format!("{} Activated!", power_type.name()),
                            power_type.color(),
                        );

                        // Remove the used power from inventory
                        game_state.get_current_player_powers_mut().remove(power_index);
                        
                        // Clear selection and move to piece movement
                        game_state.selected_power = None;
                        game_state.turn_phase = TurnPhase::PieceMovement;

                        // Clear indicators
                        for entity in indicators.iter() {
                            commands.entity(entity).despawn();
                        }

                        println!("Power activated: {}", power_type.name());
                    }
                }
            }
        }
    }
}

fn activate_move_diagonal(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    // Add MoveDiagonal component to all current player's pieces
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            commands.entity(entity).insert(MoveDiagonalActive);
        }
    }
}

fn activate_raise_column(
    commands: &mut Commands,
    column: u8,
    tiles: &Query<&BoardTile>,
) {
    // Increase height of all tiles in the column
    for tile in tiles.iter() {
        if tile.coordinates.0 == column {
            // In a real implementation, we'd modify the tile's height
            // For now, we'll spawn a visual effect
            let world_pos = board_to_world_position(tile.coordinates);
            commands.spawn((
                ActivePowerEffect { power_type: PowerType::RaiseColumn },
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(0.0, 1.0, 0.0, 0.5),
                        custom_size: Some(Vec2::splat(TILE_SIZE)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 4.0),
                    ..default()
                },
            ));
        }
    }
}

fn activate_lower_column(
    commands: &mut Commands,
    column: u8,
    tiles: &Query<&BoardTile>,
) {
    // Decrease height of all tiles in the column
    for tile in tiles.iter() {
        if tile.coordinates.0 == column {
            let world_pos = board_to_world_position(tile.coordinates);
            commands.spawn((
                ActivePowerEffect { power_type: PowerType::LowerColumn },
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(1.0, 1.0, 0.0, 0.5),
                        custom_size: Some(Vec2::splat(TILE_SIZE)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 4.0),
                    ..default()
                },
            ));
        }
    }
}

fn activate_destroy_column(
    commands: &mut Commands,
    column: u8,
    tiles: &Query<&BoardTile>,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    // Remove all pieces in the column
    for (entity, piece) in pieces.iter() {
        if piece.board_position.0 == column {
            commands.entity(entity).despawn();
        }
    }

    // Visual effect for destroyed column
    for tile in tiles.iter() {
        if tile.coordinates.0 == column {
            let world_pos = board_to_world_position(tile.coordinates);
            commands.spawn((
                ActivePowerEffect { power_type: PowerType::DestroyColumn },
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(1.0, 0.0, 0.0, 0.5),
                        custom_size: Some(Vec2::splat(TILE_SIZE)),
                        ..default()
                    },
                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 4.0),
                    ..default()
                },
            ));
        }
    }
}

fn activate_multiply(
    commands: &mut Commands,
    target_pos: (u8, u8),
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
    _tiles: &Query<&BoardTile>,
) -> bool {
    println!("Multiply: Checking position {:?} for current player {:?}", target_pos, game_state.current_player);
    
    // Check if there's a piece at target position owned by current player
    for (_, piece) in pieces.iter() {
        if piece.board_position == target_pos && piece.player == game_state.current_player {
            println!("Multiply: Found valid piece to duplicate at {:?}", target_pos);
            // Find adjacent empty tile
            let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)];
            
            for (dx, dy) in directions.iter() {
                let new_x = target_pos.0 as i8 + dx;
                let new_y = target_pos.1 as i8 + dy;
                
                if new_x >= 0 && new_x < BOARD_SIZE as i8 && new_y >= 0 && new_y < BOARD_SIZE as i8 {
                    let new_pos = (new_x as u8, new_y as u8);
                    
                    // Check if position is empty
                    let occupied = pieces.iter().any(|(_, p)| p.board_position == new_pos);
                    
                    if !occupied {
                        // Spawn new piece
                        let world_pos = board_to_world_position(new_pos);
                        commands.spawn((
                            GamePiece {
                                player: game_state.current_player,
                                board_position: new_pos,
                            },
                            SpriteBundle {
                                sprite: Sprite {
                                    color: match game_state.current_player {
                                        Player::Player1 => Color::rgb(0.8, 0.2, 0.2),
                                        Player::Player2 => Color::rgb(0.2, 0.2, 0.8),
                                    },
                                    custom_size: Some(Vec2::splat(TILE_SIZE * 0.8)),
                                    ..default()
                                },
                                transform: Transform::from_xyz(world_pos.x, world_pos.y, 1.0),
                                ..default()
                            },
                        ));
                        println!("Multiply: Successfully created duplicate at {:?}", new_pos);
                        return true;
                    }
                }
            }
            println!("Multiply: No empty adjacent tiles found");
        }
    }
    println!("Multiply: No valid piece found at clicked position");
    false
}

// Update movement validation to handle diagonal moves
pub fn is_valid_move_with_diagonal(
    from: (u8, u8),
    to: (u8, u8),
    allow_diagonal: bool,
) -> bool {
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    
    if allow_diagonal {
        // Allow diagonal moves (distance 1 in both x and y)
        (dx == 1 && dy == 1) || (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    } else {
        // Normal movement - only horizontal or vertical
        (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
    }
}

// Clean up power effects after a delay
pub fn cleanup_power_effects(
    mut commands: Commands,
    time: Res<Time>,
    mut effects: Query<(Entity, &mut Sprite), With<ActivePowerEffect>>,
) {
    for (entity, mut sprite) in effects.iter_mut() {
        // Fade out effect
        let alpha = sprite.color.a() - time.delta_seconds() * 0.5;
        if alpha <= 0.0 {
            commands.entity(entity).despawn();
        } else {
            sprite.color.set_a(alpha);
        }
    }
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    let x = (board_pos.0 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    let y = (board_pos.1 as f32 - BOARD_SIZE as f32 / 2.0 + 0.5) * TILE_SIZE;
    Vec2::new(x, y)
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    let x = ((world_pos.x / TILE_SIZE) + BOARD_SIZE as f32 / 2.0).round() as i8;
    let y = ((world_pos.y / TILE_SIZE) + BOARD_SIZE as f32 / 2.0).round() as i8;
    
    let x = x.max(0).min(BOARD_SIZE as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_SIZE as i8 - 1) as u8;
    
    (x, y)
}