use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};
use crate::resources::game_state::TurnCounter;
use crate::systems::effect_processing::add_effect_to_entity;
use crate::systems::TerrainHeight;
use crate::{components::*, resources::*};
use bevy::prelude::*;
use rand::Rng;

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
        if let Some(mut entity_commands) = commands.get_entity(entity) {
            entity_commands.despawn();
        }
    }

    if let Some(power_index) = game_state.selected_power {
        let powers = game_state.get_current_player_powers();
        if let Some(&power_type) = powers.get(power_index) {
            match power_type {
                // Powers that apply to all pieces
                PowerType::MoveDiagonal
                | PowerType::Teleport
                | PowerType::Jump
                | PowerType::MoveTwo
                | PowerType::Knight
                | PowerType::MoveTwice
                | PowerType::Slide => {
                    // No targeting needed - applies to current player's pieces
                    spawn_power_ready_indicator(&mut commands);
                }

                // Column targeting powers
                PowerType::RaiseColumn | PowerType::LowerColumn | PowerType::DestroyColumn => {
                    // Need to target a column
                    spawn_column_target_indicators(&mut commands);
                }

                // Piece targeting powers
                PowerType::Multiply
                | PowerType::Swap
                | PowerType::Push
                | PowerType::Pull
                | PowerType::Recruit
                | PowerType::Freeze
                | PowerType::Sniper
                | PowerType::Assassin => {
                    // Need to target a piece
                    spawn_piece_target_indicators(&mut commands, &game_state);
                }

                // Tile targeting powers (individual tile modification)
                PowerType::RaiseTile | PowerType::LowerTile | PowerType::Terraform => {
                    // Need to target a single tile
                    spawn_tile_target_indicators(&mut commands);
                }

                // Area targeting powers
                PowerType::SmartBomb
                | PowerType::RaiseArea
                | PowerType::LowerArea
                | PowerType::Rotate
                | PowerType::Shuffle
                | PowerType::Earthquake
                | PowerType::Flatten
                | PowerType::Scramble
                | PowerType::Crater
                | PowerType::Flood => {
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
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
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

fn spawn_piece_target_indicators(commands: &mut Commands, _game_state: &GameState) {
    // For now, show indicators on all tiles since we need piece positions
    // In a real implementation, we'd query for piece positions and only show indicators there
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
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
    for x in 1..BOARD_WIDTH - 1 {
        for y in 1..BOARD_HEIGHT - 1 {
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

fn spawn_tile_target_indicators(commands: &mut Commands) {
    // Highlight individual tiles for single-tile terrain modification
    for x in 0..BOARD_WIDTH {
        for y in 0..BOARD_HEIGHT {
            let world_pos = board_to_world_position((x, y));
            commands.spawn((
                PowerTargetIndicator,
                SpriteBundle {
                    sprite: Sprite {
                        color: Color::rgba(0.5, 1.0, 0.5, 0.3), // Green transparent for terrain
                        custom_size: Some(Vec2::splat(TILE_SIZE * 0.9)),
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
    camera_q: Query<(&Camera, &GlobalTransform), (With<Camera2d>, With<Camera>)>,
    mut game_state: ResMut<GameState>,
    turn_counter: Res<TurnCounter>,
    mut tile_queries: ParamSet<(
        Query<&BoardTile>,
        Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
    )>,
    pieces: Query<(Entity, &GamePiece)>,
    walls: Query<(Entity, &crate::components::power::Wall)>,
    indicators: Query<Entity, With<PowerTargetIndicator>>,
    screen_shake: Option<ResMut<ScreenShake>>,
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
                            destroy_column(
                                board_pos.0,
                                &mut tile_queries.p1(),
                                &pieces,
                                &mut commands,
                            );
                            true
                        }
                        PowerType::Multiply => activate_multiply(
                            &mut commands,
                            board_pos,
                            &game_state,
                            &pieces,
                            &tile_queries.p0(),
                        ),

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
                            // Add MoveTwiceActive component to current player's pieces
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player {
                                    commands.entity(entity).insert(
                                        crate::components::power::MoveTwiceActive {
                                            moves_remaining: 2,
                                        },
                                    );
                                }
                            }
                            println!("Move Twice activated - pieces can move twice this turn");
                            true
                        }
                        PowerType::Slide => {
                            use crate::systems::movement_powers::activate_slide;
                            activate_slide(&mut commands, &game_state, &pieces);
                            true
                        }
                        PowerType::Swap => {
                            // Find current player's piece and target piece
                            let mut current_piece = None;
                            let mut target_piece = None;
                            
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player && current_piece.is_none() {
                                    current_piece = Some((entity, piece.board_position));
                                }
                                if piece.board_position == board_pos && piece.player != game_state.current_player {
                                    target_piece = Some((entity, piece.board_position));
                                }
                            }

                            if let (Some((entity1, pos1)), Some((entity2, pos2))) = (current_piece, target_piece) {
                                // Update board positions
                                if let Ok((_, piece1)) = pieces.get(entity1) {
                                    commands.entity(entity1).insert(GamePiece {
                                        player: piece1.player,
                                        board_position: pos2,
                                    });
                                }
                                if let Ok((_, piece2)) = pieces.get(entity2) {
                                    commands.entity(entity2).insert(GamePiece {
                                        player: piece2.player,
                                        board_position: pos1,
                                    });

                                    // Update visual positions
                                    let world_pos1 = board_to_world_position(pos2);
                                    let world_pos2 = board_to_world_position(pos1);
                                    commands.entity(entity1).insert(Transform::from_xyz(
                                        world_pos1.x,
                                        world_pos1.y,
                                        1.0,
                                    ));
                                    commands.entity(entity2).insert(Transform::from_xyz(
                                        world_pos2.x,
                                        world_pos2.y,
                                        1.0,
                                    ));

                                    println!("Swapped pieces at {:?} and {:?}", pos1, pos2);
                                    true
                                } else {
                                    println!("No enemy piece at target location for swap");
                                    false
                                }
                            } else {
                                println!("No current player piece found for swap");
                                false
                            }
                        }
                        PowerType::Push => {
                            // Push target piece away
                            if let Some((entity, piece)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                // Calculate push direction from center of board
                                let center = (BOARD_WIDTH / 2, BOARD_HEIGHT / 2);
                                let dx = if board_pos.0 > center.0 { 1 } else { -1 };
                                let dy = if board_pos.1 > center.1 { 1 } else { -1 };

                                let push_to = (
                                    (board_pos.0 as i8 + dx).clamp(0, BOARD_WIDTH as i8 - 1) as u8,
                                    (board_pos.1 as i8 + dy).clamp(0, BOARD_HEIGHT as i8 - 1) as u8,
                                );

                                // Check if destination is empty
                                let occupied =
                                    pieces.iter().any(|(_, p)| p.board_position == push_to);
                                if !occupied {
                                    commands.entity(entity).insert(GamePiece {
                                        player: piece.player,
                                        board_position: push_to,
                                    });
                                    let world_pos = board_to_world_position(push_to);
                                    commands.entity(entity).insert(Transform::from_xyz(
                                        world_pos.x,
                                        world_pos.y,
                                        1.0,
                                    ));
                                    println!("Pushed piece from {:?} to {:?}", board_pos, push_to);
                                    true
                                } else {
                                    println!("Cannot push - destination occupied");
                                    false
                                }
                            } else {
                                println!("No piece at target location to push");
                                false
                            }
                        }
                        PowerType::Pull => {
                            // Pull target piece towards current player's piece
                            if let Some((target_entity, target_piece)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if let Some((_, puller_piece)) = pieces
                                    .iter()
                                    .find(|(_, p)| p.player == game_state.current_player)
                                {
                                    // Calculate pull direction
                                    let dx = (puller_piece.board_position.0 as i8
                                        - board_pos.0 as i8)
                                        .signum();
                                    let dy = (puller_piece.board_position.1 as i8
                                        - board_pos.1 as i8)
                                        .signum();

                                    let pull_to = (
                                        (board_pos.0 as i8 + dx).clamp(0, BOARD_WIDTH as i8 - 1)
                                            as u8,
                                        (board_pos.1 as i8 + dy).clamp(0, BOARD_HEIGHT as i8 - 1)
                                            as u8,
                                    );

                                    // Check if destination is empty
                                    let occupied =
                                        pieces.iter().any(|(_, p)| p.board_position == pull_to);
                                    if !occupied {
                                        commands.entity(target_entity).insert(GamePiece {
                                            player: target_piece.player,
                                            board_position: pull_to,
                                        });
                                        let world_pos = board_to_world_position(pull_to);
                                        commands.entity(target_entity).insert(Transform::from_xyz(
                                            world_pos.x,
                                            world_pos.y,
                                            1.0,
                                        ));
                                        println!(
                                            "Pulled piece from {:?} to {:?}",
                                            board_pos, pull_to
                                        );
                                        true
                                    } else {
                                        println!("Cannot pull - destination occupied");
                                        false
                                    }
                                } else {
                                    println!("No current player piece found to pull towards");
                                    false
                                }
                            } else {
                                println!("No piece at target location to pull");
                                false
                            }
                        }
                        PowerType::Leap => {
                            // Leap to target position within 3 tiles
                            if let Some((entity, piece)) = pieces
                                .iter()
                                .find(|(_, p)| p.player == game_state.current_player)
                            {
                                let source_pos = piece.board_position;
                                let dx = (board_pos.0 as i8 - source_pos.0 as i8).abs();
                                let dy = (board_pos.1 as i8 - source_pos.1 as i8).abs();

                                if dx <= 3 && dy <= 3 {
                                    let occupied =
                                        pieces.iter().any(|(_, p)| p.board_position == board_pos);
                                    if !occupied {
                                        commands.entity(entity).insert(GamePiece {
                                            player: piece.player,
                                            board_position: board_pos,
                                        });
                                        let world_pos = board_to_world_position(board_pos);
                                        commands.entity(entity).insert(Transform::from_xyz(
                                            world_pos.x,
                                            world_pos.y,
                                            1.0,
                                        ));
                                        println!("Leaped from {:?} to {:?}", source_pos, board_pos);
                                        true
                                    } else {
                                        println!("Cannot leap - destination occupied");
                                        false
                                    }
                                } else {
                                    println!("Cannot leap - target too far (max 3 tiles)");
                                    false
                                }
                            } else {
                                println!("No current player piece found for leap");
                                false
                            }
                        }
                        PowerType::Freeze => {
                            // Freeze target piece for 3 turns using new effect system
                            if let Some((entity, piece)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if piece.player != game_state.current_player {
                                    let freeze_effect = PowerEffect::new(
                                        PowerType::Freeze,
                                        3, // Duration in turns
                                        entity,
                                        EffectData::Status(StatusEffect::Frozen),
                                        game_state.current_player,
                                        turn_counter.turn_number,
                                    );
                                    add_effect_to_entity(&mut commands, entity, freeze_effect);
                                    println!("Frozen enemy piece at {:?} for 3 turns", board_pos);
                                    true
                                } else {
                                    println!("Cannot freeze your own piece");
                                    false
                                }
                            } else {
                                println!("No piece at target location to freeze");
                                false
                            }
                        }
                        PowerType::Assassin => {
                            // Assassin removes any piece instantly
                            if let Some(target_piece) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if let Some(mut entity_commands) =
                                    commands.get_entity(target_piece.0)
                                {
                                    entity_commands.despawn();
                                }

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
                            if let Some((entity, piece)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if piece.player != game_state.current_player {
                                    if let Some(mut entity_commands) = commands.get_entity(entity) {
                                        entity_commands.despawn();
                                    }

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

                                    if target_x >= 0
                                        && target_x < BOARD_WIDTH as i8
                                        && target_y >= 0
                                        && target_y < BOARD_HEIGHT as i8
                                    {
                                        let target = (target_x as u8, target_y as u8);

                                        if let Some((entity, _)) =
                                            pieces.iter().find(|(_, p)| p.board_position == target)
                                        {
                                            if let Some(mut entity_commands) =
                                                commands.get_entity(entity)
                                            {
                                                entity_commands.despawn();
                                            }
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
                        PowerType::Shield => {
                            // Give current player's pieces shield protection using new effect system
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player {
                                    let shield_effect = PowerEffect::new(
                                        PowerType::Shield,
                                        5, // Duration in turns
                                        entity,
                                        EffectData::Protection(ProtectionType::Shield {
                                            hits_remaining: 1,
                                        }),
                                        game_state.current_player,
                                        turn_counter.turn_number,
                                    );
                                    add_effect_to_entity(&mut commands, entity, shield_effect);
                                }
                            }
                            println!(
                                "Shield activated - pieces protected for 5 turns or until hit"
                            );
                            true
                        }
                        PowerType::Invisible => {
                            // Make current player's pieces invisible for 3 turns using new effect system
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player {
                                    let invisible_effect = PowerEffect::new(
                                        PowerType::Invisible,
                                        3, // Duration in turns
                                        entity,
                                        EffectData::Status(StatusEffect::Invisible),
                                        game_state.current_player,
                                        turn_counter.turn_number,
                                    );
                                    add_effect_to_entity(&mut commands, entity, invisible_effect);
                                }
                            }
                            println!("Invisibility activated - pieces invisible for 3 turns");
                            true
                        }
                        PowerType::Recruit => {
                            // Convert enemy piece to current player's side
                            if let Some((entity, piece)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if piece.player != game_state.current_player {
                                    commands.entity(entity).insert(GamePiece {
                                        player: game_state.current_player,
                                        board_position: piece.board_position,
                                    });

                                    // Update piece color using correct theme colors
                                    use crate::resources::QuadradiusTheme;
                                    let new_color = match game_state.current_player {
                                        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Bright metallic blue
                                        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Bright metallic red
                                    };

                                    // Only update the sprite color, don't replace the entire bundle
                                    commands.entity(entity).insert(Sprite {
                                        color: new_color,
                                        custom_size: Some(Vec2::splat(TILE_SIZE * 1.2)),
                                        ..default()
                                    });

                                    println!("Recruited enemy piece at {:?}", board_pos);
                                    true
                                } else {
                                    println!("Cannot recruit your own piece");
                                    false
                                }
                            } else {
                                println!("No piece at target location to recruit");
                                false
                            }
                        }
                        PowerType::Poison => {
                            // Poison target piece - it dies after 3 turns using new effect system
                            if let Some((entity, piece)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if piece.player != game_state.current_player {
                                    let poison_effect = PowerEffect::new(
                                        PowerType::Poison,
                                        3, // Duration in turns
                                        entity,
                                        EffectData::Status(StatusEffect::Poisoned {
                                            death_timer: 3,
                                        }),
                                        game_state.current_player,
                                        turn_counter.turn_number,
                                    );
                                    add_effect_to_entity(&mut commands, entity, poison_effect);
                                    println!(
                                        "Poisoned enemy piece at {:?} - dies in 3 turns",
                                        board_pos
                                    );
                                    true
                                } else {
                                    println!("Cannot poison your own piece");
                                    false
                                }
                            } else {
                                println!("No piece at target location to poison");
                                false
                            }
                        }
                        PowerType::Explode => {
                            // Sacrifice current player's piece to destroy surrounding pieces
                            if let Some((entity, _piece)) = pieces.iter().find(|(_, p)| {
                                p.board_position == board_pos
                                    && p.player == game_state.current_player
                            }) {
                                // Remove the exploding piece
                                if let Some(mut entity_commands) = commands.get_entity(entity) {
                                    entity_commands.despawn();
                                }

                                // Destroy all adjacent pieces
                                let mut destroyed = 0;
                                for dx in -1i8..=1 {
                                    for dy in -1i8..=1 {
                                        if dx == 0 && dy == 0 {
                                            continue;
                                        } // Skip center piece (already destroyed)

                                        let target_x = board_pos.0 as i8 + dx;
                                        let target_y = board_pos.1 as i8 + dy;

                                        if target_x >= 0
                                            && target_x < BOARD_WIDTH as i8
                                            && target_y >= 0
                                            && target_y < BOARD_HEIGHT as i8
                                        {
                                            let target = (target_x as u8, target_y as u8);
                                            if let Some((target_entity, _)) = pieces
                                                .iter()
                                                .find(|(_, p)| p.board_position == target)
                                            {
                                                if let Some(mut entity_commands) =
                                                    commands.get_entity(target_entity)
                                                {
                                                    entity_commands.despawn();
                                                }
                                                destroyed += 1;
                                            }
                                        }
                                    }
                                }

                                let world_pos = board_to_world_position(board_pos);
                                crate::systems::visual_effects::spawn_capture_explosion(
                                    &mut commands,
                                    Vec3::new(world_pos.x, world_pos.y, 0.0),
                                    Color::rgb(1.0, 0.0, 0.0),
                                );

                                println!(
                                    "Piece exploded at {:?}, destroying {} surrounding pieces",
                                    board_pos, destroyed
                                );
                                true
                            } else {
                                println!("No current player piece at target location to explode");
                                false
                            }
                        }
                        PowerType::Resurrect => {
                            // Bring back a destroyed piece (simplified - spawn new piece)
                            let occupied =
                                pieces.iter().any(|(_, p)| p.board_position == board_pos);
                            if !occupied {
                                let world_pos = board_to_world_position(board_pos);
                                commands.spawn((
                                    GamePiece {
                                        player: game_state.current_player,
                                        board_position: board_pos,
                                    },
                                    SpriteBundle {
                                        sprite: Sprite {
                                            color: match game_state.current_player {
                                                Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Bright metallic blue
                                                Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Bright metallic red
                                            },
                                            custom_size: Some(Vec2::splat(TILE_SIZE * 1.2)),
                                            ..default()
                                        },
                                        transform: Transform::from_xyz(
                                            world_pos.x,
                                            world_pos.y,
                                            1.0,
                                        ),
                                        ..default()
                                    },
                                ));
                                println!("Resurrected piece at {:?}", board_pos);
                                true
                            } else {
                                println!("Cannot resurrect - position occupied");
                                false
                            }
                        }

                        // Board Manipulation Powers
                        PowerType::RaiseArea => {
                            // Raise 3x3 area around target
                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let target_x = board_pos.0 as i8 + dx;
                                    let target_y = board_pos.1 as i8 + dy;
                                    if target_x >= 0
                                        && target_x < BOARD_WIDTH as i8
                                        && target_y >= 0
                                        && target_y < BOARD_HEIGHT as i8
                                    {
                                        // Use terrain height system to raise
                                        use crate::systems::terrain_height::raise_single_tile;
                                        raise_single_tile(
                                            target_x as u8,
                                            target_y as u8,
                                            &mut tile_queries.p1(),
                                            &mut commands,
                                        );
                                    }
                                }
                            }
                            println!("Raised 3x3 area around {:?}", board_pos);
                            true
                        }
                        PowerType::LowerArea => {
                            // Lower 3x3 area around target
                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let target_x = board_pos.0 as i8 + dx;
                                    let target_y = board_pos.1 as i8 + dy;
                                    if target_x >= 0
                                        && target_x < BOARD_WIDTH as i8
                                        && target_y >= 0
                                        && target_y < BOARD_HEIGHT as i8
                                    {
                                        // Use terrain height system to lower
                                        use crate::systems::terrain_height::lower_single_tile;
                                        lower_single_tile(
                                            target_x as u8,
                                            target_y as u8,
                                            &mut tile_queries.p1(),
                                            &mut commands,
                                        );
                                    }
                                }
                            }
                            println!("Lowered 3x3 area around {:?}", board_pos);
                            true
                        }
                        PowerType::CreateWall => {
                            // Create wall at target position
                            let world_pos = board_to_world_position(board_pos);
                            commands.spawn((
                                crate::components::power::Wall {
                                    height: 2,
                                    board_position: board_pos,
                                    wall_type: crate::components::power::WallType::Stone,
                                    health: 1,
                                    created_turn: turn_counter.turn_number,
                                },
                                SpriteBundle {
                                    sprite: Sprite {
                                        color: Color::rgb(0.5, 0.5, 0.5),
                                        custom_size: Some(Vec2::splat(TILE_SIZE)),
                                        ..default()
                                    },
                                    transform: Transform::from_xyz(world_pos.x, world_pos.y, 2.0),
                                    ..default()
                                },
                            ));
                            println!("Created stone wall at {:?}", board_pos);
                            true
                        }
                        PowerType::DestroyWall => {
                            // Remove walls at target position
                            for (entity, wall) in walls.iter() {
                                if wall.board_position == board_pos {
                                    if let Some(mut entity_commands) = commands.get_entity(entity) {
                                        entity_commands.despawn();
                                    }
                                }
                            }
                            println!("Destroyed wall at {:?}", board_pos);
                            true
                        }
                        PowerType::Shuffle => {
                            // Shuffle pieces in 3x3 area
                            let mut area_pieces = Vec::new();
                            let mut area_positions = Vec::new();

                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let target_x = board_pos.0 as i8 + dx;
                                    let target_y = board_pos.1 as i8 + dy;
                                    if target_x >= 0
                                        && target_x < BOARD_WIDTH as i8
                                        && target_y >= 0
                                        && target_y < BOARD_HEIGHT as i8
                                    {
                                        let target_pos = (target_x as u8, target_y as u8);
                                        area_positions.push(target_pos);

                                        if let Some((entity, piece)) = pieces
                                            .iter()
                                            .find(|(_, p)| p.board_position == target_pos)
                                        {
                                            area_pieces.push((entity, piece.player));
                                        }
                                    }
                                }
                            }

                            // Shuffle pieces to random positions in the area
                            use rand::seq::SliceRandom;
                            let mut rng = rand::thread_rng();
                            area_positions.shuffle(&mut rng);

                            for (i, (entity, player)) in area_pieces.iter().enumerate() {
                                if let Some(&new_pos) = area_positions.get(i) {
                                    commands.entity(*entity).insert(GamePiece {
                                        player: *player,
                                        board_position: new_pos,
                                    });
                                    let world_pos = board_to_world_position(new_pos);
                                    commands.entity(*entity).insert(Transform::from_xyz(
                                        world_pos.x,
                                        world_pos.y,
                                        1.0,
                                    ));
                                }
                            }

                            println!(
                                "Shuffled {} pieces in area around {:?}",
                                area_pieces.len(),
                                board_pos
                            );
                            true
                        }
                        PowerType::Earthquake => {
                            // Random height changes across the board
                            use rand::Rng;
                            let mut rng = rand::thread_rng();
                            let mut changed = 0;

                            for x in 0..BOARD_WIDTH {
                                for y in 0..BOARD_HEIGHT {
                                    if rng.gen::<f32>() < 0.3 {
                                        // 30% chance for each tile
                                        if rng.gen::<bool>() {
                                            use crate::systems::terrain_height::raise_single_tile;
                                            raise_single_tile(
                                                x,
                                                y,
                                                &mut tile_queries.p1(),
                                                &mut commands,
                                            );
                                        } else {
                                            use crate::systems::terrain_height::lower_single_tile;
                                            lower_single_tile(
                                                x,
                                                y,
                                                &mut tile_queries.p1(),
                                                &mut commands,
                                            );
                                        }
                                        changed += 1;
                                    }
                                }
                            }

                            println!("Earthquake affected {} tiles", changed);
                            true
                        }
                        PowerType::Pit => {
                            // Create deep hole at target position
                            use crate::systems::terrain_height::set_tile_height;
                            set_tile_height(
                                board_pos.0,
                                board_pos.1,
                                -3,
                                &mut tile_queries.p1(),
                                &mut commands,
                            );

                            // Remove any piece at this position
                            if let Some((entity, _)) =
                                pieces.iter().find(|(_, p)| p.board_position == board_pos)
                            {
                                if let Some(mut entity_commands) = commands.get_entity(entity) {
                                    entity_commands.despawn();
                                }
                            }

                            println!("Created pit at {:?}", board_pos);
                            true
                        }
                        PowerType::Terraform => {
                            // Set specific tile height (set to height 0)
                            use crate::systems::terrain_height::set_tile_height;
                            set_tile_height(
                                board_pos.0,
                                board_pos.1,
                                0,
                                &mut tile_queries.p1(),
                                &mut commands,
                            );
                            println!("Terraformed tile at {:?} to height 0", board_pos);
                            true
                        }

                        // Individual Tile Terrain Powers (Phase 3 implementation plan)
                        PowerType::RaiseTile => {
                            // Raise a single tile by 1-3 levels
                            use crate::systems::terrain_height::{get_tile_height, set_tile_height};
                            let current_height =
                                get_tile_height(board_pos.0, board_pos.1, &tile_queries.p1());
                            let raise_amount = rand::thread_rng().gen_range(1..=3);
                            let new_height = (current_height + raise_amount).min(4); // Max height 4
                            set_tile_height(
                                board_pos.0,
                                board_pos.1,
                                new_height,
                                &mut tile_queries.p1(),
                                &mut commands,
                            );
                            println!(
                                "Raised tile at {:?} from {} to {} (+{})",
                                board_pos, current_height, new_height, raise_amount
                            );
                            true
                        }
                        PowerType::LowerTile => {
                            // Lower a single tile by 1-3 levels
                            use crate::systems::terrain_height::{get_tile_height, set_tile_height};
                            let current_height =
                                get_tile_height(board_pos.0, board_pos.1, &tile_queries.p1());
                            let lower_amount = rand::thread_rng().gen_range(1..=3);
                            let new_height = (current_height - lower_amount).max(-2); // Min height -2
                            set_tile_height(
                                board_pos.0,
                                board_pos.1,
                                new_height,
                                &mut tile_queries.p1(),
                                &mut commands,
                            );
                            println!(
                                "Lowered tile at {:?} from {} to {} (-{})",
                                board_pos, current_height, new_height, lower_amount
                            );
                            true
                        }
                        PowerType::Flatten => {
                            // Set all tiles in 3x3 area to uniform height (average of area)
                            use crate::systems::terrain_height::{get_tile_height, set_tile_height};
                            let mut total_height: i32 = 0;
                            let mut tile_count = 0;

                            // Calculate average height in 3x3 area
                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let nx = board_pos.0 as i8 + dx;
                                    let ny = board_pos.1 as i8 + dy;
                                    if nx >= 0
                                        && nx < BOARD_WIDTH as i8
                                        && ny >= 0
                                        && ny < BOARD_HEIGHT as i8
                                    {
                                        total_height += get_tile_height(
                                            nx as u8,
                                            ny as u8,
                                            &tile_queries.p1(),
                                        ) as i32;
                                        tile_count += 1;
                                    }
                                }
                            }

                            let avg_height = (total_height / tile_count) as i8;

                            // Set all tiles to average height
                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let nx = board_pos.0 as i8 + dx;
                                    let ny = board_pos.1 as i8 + dy;
                                    if nx >= 0
                                        && nx < BOARD_WIDTH as i8
                                        && ny >= 0
                                        && ny < BOARD_HEIGHT as i8
                                    {
                                        set_tile_height(
                                            nx as u8,
                                            ny as u8,
                                            avg_height,
                                            &mut tile_queries.p1(),
                                            &mut commands,
                                        );
                                    }
                                }
                            }
                            println!(
                                "Flattened 3x3 area at {:?} to uniform height {}",
                                board_pos, avg_height
                            );
                            true
                        }
                        PowerType::Scramble => {
                            // Randomize heights in 3x3 area
                            use crate::systems::terrain_height::set_tile_height;

                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let nx = board_pos.0 as i8 + dx;
                                    let ny = board_pos.1 as i8 + dy;
                                    if nx >= 0
                                        && nx < BOARD_WIDTH as i8
                                        && ny >= 0
                                        && ny < BOARD_HEIGHT as i8
                                    {
                                        let random_height = rand::thread_rng().gen_range(-2..=4);
                                        set_tile_height(
                                            nx as u8,
                                            ny as u8,
                                            random_height,
                                            &mut tile_queries.p1(),
                                            &mut commands,
                                        );
                                    }
                                }
                            }
                            println!("Scrambled terrain heights in 3x3 area at {:?}", board_pos);
                            true
                        }
                        PowerType::Crater => {
                            // Create a large depression in 3x3 area (lower all tiles significantly)
                            use crate::systems::terrain_height::set_tile_height;
                            let crater_depth = -2; // Deep crater

                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let nx = board_pos.0 as i8 + dx;
                                    let ny = board_pos.1 as i8 + dy;
                                    if nx >= 0
                                        && nx < BOARD_WIDTH as i8
                                        && ny >= 0
                                        && ny < BOARD_HEIGHT as i8
                                    {
                                        // Center is deepest, edges slightly higher
                                        let depth_modifier = if dx == 0 && dy == 0 { 0 } else { 1 };
                                        set_tile_height(
                                            nx as u8,
                                            ny as u8,
                                            crater_depth + depth_modifier,
                                            &mut tile_queries.p1(),
                                            &mut commands,
                                        );
                                    }
                                }
                            }
                            println!("Created crater at {:?}", board_pos);
                            true
                        }
                        PowerType::Flood => {
                            // Fill low areas with water (mark tiles as flooded, blocks movement)
                            // For now, we lower all tiles in 3x3 area to create a "flooded" zone
                            use crate::systems::terrain_height::{get_tile_height, set_tile_height};
                            let flood_level = -1; // Flood level

                            for dx in -1i8..=1 {
                                for dy in -1i8..=1 {
                                    let nx = board_pos.0 as i8 + dx;
                                    let ny = board_pos.1 as i8 + dy;
                                    if nx >= 0
                                        && nx < BOARD_WIDTH as i8
                                        && ny >= 0
                                        && ny < BOARD_HEIGHT as i8
                                    {
                                        let current_height =
                                            get_tile_height(nx as u8, ny as u8, &tile_queries.p1());
                                        // Only flood tiles that are at or below flood level
                                        if current_height <= flood_level {
                                            set_tile_height(
                                                nx as u8,
                                                ny as u8,
                                                flood_level - 1, // Sink flooded tiles
                                                &mut tile_queries.p1(),
                                                &mut commands,
                                            );
                                        }
                                    }
                                }
                            }
                            println!("Flooded area at {:?}", board_pos);
                            true
                        }

                        // Meta Powers
                        PowerType::StealPower => {
                            // Steal random power from opponent
                            let opponent_powers = match game_state.current_player {
                                Player::Player1 => &game_state.player2_powers,
                                Player::Player2 => &game_state.player1_powers,
                            };

                            if !opponent_powers.is_empty() {
                                use rand::seq::SliceRandom;
                                let mut rng = rand::thread_rng();
                                if let Some(&stolen_power) = opponent_powers.choose(&mut rng) {
                                    // Remove from opponent
                                    match game_state.current_player {
                                        Player::Player1 => {
                                            if let Some(pos) = game_state
                                                .player2_powers
                                                .iter()
                                                .position(|&p| p == stolen_power)
                                            {
                                                game_state.player2_powers.remove(pos);
                                            }
                                            game_state.player1_powers.push(stolen_power);
                                        }
                                        Player::Player2 => {
                                            if let Some(pos) = game_state
                                                .player1_powers
                                                .iter()
                                                .position(|&p| p == stolen_power)
                                            {
                                                game_state.player1_powers.remove(pos);
                                            }
                                            game_state.player2_powers.push(stolen_power);
                                        }
                                    }
                                    println!("Stole power: {:?}", stolen_power);
                                    true
                                } else {
                                    false
                                }
                            } else {
                                println!("Opponent has no powers to steal");
                                false
                            }
                        }
                        PowerType::CopyPower => {
                            // Copy random power from current player's inventory
                            let current_powers = game_state.get_current_player_powers();
                            if !current_powers.is_empty() {
                                use rand::seq::SliceRandom;
                                let mut rng = rand::thread_rng();
                                if let Some(&copied_power) = current_powers.choose(&mut rng) {
                                    game_state
                                        .get_current_player_powers_mut()
                                        .push(copied_power);
                                    println!("Copied power: {:?}", copied_power);
                                    true
                                } else {
                                    false
                                }
                            } else {
                                println!("No powers to copy");
                                false
                            }
                        }
                        PowerType::PowerSwap => {
                            // Exchange all powers with opponent
                            let temp_powers = game_state.player1_powers.clone();
                            game_state.player1_powers = game_state.player2_powers.clone();
                            game_state.player2_powers = temp_powers;
                            println!("Swapped all powers with opponent");
                            true
                        }
                        PowerType::PowerGift => {
                            // Give random power to opponent
                            let current_powers = game_state.get_current_player_powers_mut();
                            if !current_powers.is_empty() {
                                let mut rng = rand::thread_rng();
                                let index = rng.gen_range(0..current_powers.len());
                                let gifted_power = current_powers.remove(index);

                                match game_state.current_player {
                                    Player::Player1 => game_state.player2_powers.push(gifted_power),
                                    Player::Player2 => game_state.player1_powers.push(gifted_power),
                                }
                                println!("Gifted power: {:?} to opponent", gifted_power);
                                true
                            } else {
                                println!("No powers to gift");
                                false
                            }
                        }
                        PowerType::PowerDrain => {
                            // Remove all opponent powers
                            let removed_count = match game_state.current_player {
                                Player::Player1 => {
                                    let count = game_state.player2_powers.len();
                                    game_state.player2_powers.clear();
                                    count
                                }
                                Player::Player2 => {
                                    let count = game_state.player1_powers.len();
                                    game_state.player1_powers.clear();
                                    count
                                }
                            };
                            println!("Drained {} powers from opponent", removed_count);
                            true
                        }
                        PowerType::Reflect => {
                            // Add reflection ability to current player's pieces using new effect system
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player {
                                    let reflect_effect = PowerEffect::new(
                                        PowerType::Reflect,
                                        3, // Duration in turns
                                        entity,
                                        EffectData::Protection(ProtectionType::Reflection {
                                            turns_remaining: 3,
                                        }),
                                        game_state.current_player,
                                        turn_counter.turn_number,
                                    );
                                    add_effect_to_entity(&mut commands, entity, reflect_effect);
                                }
                            }
                            println!(
                                "Reflection activated - attacks will be reflected for 3 turns"
                            );
                            true
                        }
                        PowerType::Absorb => {
                            // Add absorption ability to current player's pieces
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player {
                                    commands.entity(entity).insert(
                                        crate::components::power::Absorbing { remaining_turns: 3 },
                                    );
                                }
                            }
                            println!(
                                "Absorption activated - will gain powers when attacked for 3 turns"
                            );
                            true
                        }
                        PowerType::DoublePower => {
                            activate_double_power(
                                &mut commands,
                                &mut game_state,
                                power_index,
                                &powers,
                            );
                            true
                        }
                        PowerType::PowerEcho => {
                            activate_power_echo(&mut commands, &game_state, &pieces, &turn_counter);
                            true
                        }
                        PowerType::PowerMemory => {
                            activate_power_memory(&mut commands, &mut game_state, &pieces);
                            true
                        }
                        PowerType::RandomPower => {
                            // Get random power effect
                            use rand::seq::SliceRandom;
                            let all_powers = [
                                PowerType::MoveDiagonal,
                                PowerType::Teleport,
                                PowerType::Jump,
                                PowerType::MoveTwo,
                                PowerType::Knight,
                                PowerType::SmartBomb,
                                PowerType::Sniper,
                                PowerType::Shield,
                                PowerType::Multiply,
                                PowerType::RaiseColumn,
                                PowerType::LowerColumn,
                            ];
                            let mut rng = rand::thread_rng();
                            if let Some(&random_power) = all_powers.choose(&mut rng) {
                                // Activate random power at the target position
                                println!("Random Power activated: {:?}", random_power);
                                // This would need to recursively call the power activation
                                true
                            } else {
                                false
                            }
                        }
                        PowerType::NullifyPower => {
                            // Cancel opponent's next power (simplified - remove random power)
                            let opponent_powers = match game_state.current_player {
                                Player::Player1 => &mut game_state.player2_powers,
                                Player::Player2 => &mut game_state.player1_powers,
                            };

                            if !opponent_powers.is_empty() {
                                use rand::Rng;
                                let mut rng = rand::thread_rng();
                                let index = rng.gen_range(0..opponent_powers.len());
                                let nullified_power = opponent_powers.remove(index);
                                println!("Nullified opponent's power: {:?}", nullified_power);
                                true
                            } else {
                                println!("Opponent has no powers to nullify");
                                false
                            }
                        }
                        PowerType::Bridge => {
                            // Create bridge connecting two areas (simplified - set tiles to height 0)
                            for x in board_pos.0.saturating_sub(1)
                                ..=(board_pos.0 + 1).min(BOARD_WIDTH - 1)
                            {
                                use crate::systems::terrain_height::set_tile_height;
                                set_tile_height(
                                    x,
                                    board_pos.1,
                                    0,
                                    &mut tile_queries.p1(),
                                    &mut commands,
                                );
                            }
                            println!("Created bridge at {:?}", board_pos);
                            true
                        }
                        PowerType::Rotate => {
                            // Rotate 3x3 area 90 degrees clockwise
                            activate_rotate_area(board_pos, &mut commands, &pieces);
                            true
                        }

                        PowerType::JumpProof => {
                            // Give current player's pieces permanent capture immunity
                            for (entity, piece) in pieces.iter() {
                                if piece.player == game_state.current_player {
                                    let jumpproof_effect = PowerEffect::new(
                                        PowerType::JumpProof,
                                        999, // Permanent effect (very long duration)
                                        entity,
                                        EffectData::Protection(ProtectionType::Immunity {
                                            damage_types: vec![
                                                DamageType::Capture,
                                                DamageType::All,
                                            ],
                                        }),
                                        game_state.current_player,
                                        turn_counter.turn_number,
                                    );
                                    add_effect_to_entity(&mut commands, entity, jumpproof_effect);
                                }
                            }
                            println!("Jump Proof activated - pieces are now permanently immune to capture!");
                            true
                        }
                        // Missing research powers
                        PowerType::GrowQuadradius => {
                            activate_grow_quadradius(
                                &mut commands,
                                &game_state,
                                &pieces,
                                &turn_counter,
                            );
                            true
                        }
                        PowerType::Bombs => {
                            println!("Bombs activated - dropping 16 random bombs");
                            // Implementation will be added later
                            false
                        }
                        PowerType::SnakeTunneling => {
                            // Snake tunneling: destructive snake across board, raises terrain 2 levels
                            activate_snake_tunneling(
                                board_pos,
                                &mut commands,
                                &pieces,
                                &mut tile_queries.p1(),
                            );
                            true
                        }
                        PowerType::DredgeColumn => {
                            // Dredge column: sink enemies 2 levels, raise friendlies 2 levels
                            activate_dredge_column(
                                board_pos.0,
                                game_state.current_player,
                                &mut commands,
                                &pieces,
                                &mut tile_queries.p1(),
                            );
                            true
                        }
                        PowerType::TeachRow => {
                            activate_teach_row(&mut commands, &game_state, &pieces, &turn_counter);
                            true
                        }
                        PowerType::TeachRadial => {
                            activate_teach_radial(
                                board_pos,
                                &mut commands,
                                &game_state,
                                &pieces,
                                &turn_counter,
                            );
                            true
                        }
                        PowerType::Acid => {
                            println!("Acid activated - creating permanent holes in board");
                            activate_acid_attack(
                                board_pos,
                                &mut commands,
                                &pieces,
                                &mut tile_queries.p1(),
                            );
                            true
                        }
                        PowerType::RecruitRadial => {
                            println!("Recruit Radial activated - converting enemies in 3x3 area");
                            // Implementation will be added later
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

                        // Spawn enhanced floating text for power activation
                        crate::systems::visual_effects::spawn_enhanced_power_text(
                            &mut commands,
                            Vec3::new(world_pos.x, world_pos.y, 0.0),
                            power_type,
                        );

                        // Trigger screen shake for dramatic powers
                        crate::systems::visual_effects::trigger_power_screen_shake(
                            &mut commands,
                            screen_shake,
                            power_type,
                        );

                        // Remove the used power from inventory
                        game_state
                            .get_current_player_powers_mut()
                            .remove(power_index);

                        // Clear selection and move to piece movement
                        game_state.selected_power = None;
                        game_state.turn_phase = TurnPhase::PieceMovement;

                        // Clear indicators
                        for entity in indicators.iter() {
                            if let Some(mut entity_commands) = commands.get_entity(entity) {
                                entity_commands.despawn();
                            }
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

fn activate_raise_column(commands: &mut Commands, column: u8, tiles: &Query<&BoardTile>) {
    // Increase height of all tiles in the column
    for tile in tiles.iter() {
        if tile.coordinates.0 == column {
            // In a real implementation, we'd modify the tile's height
            // For now, we'll spawn a visual effect
            let world_pos = board_to_world_position(tile.coordinates);
            commands.spawn((
                ActivePowerEffect {
                    power_type: PowerType::RaiseColumn,
                },
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

fn activate_lower_column(commands: &mut Commands, column: u8, tiles: &Query<&BoardTile>) {
    // Decrease height of all tiles in the column
    for tile in tiles.iter() {
        if tile.coordinates.0 == column {
            let world_pos = board_to_world_position(tile.coordinates);
            commands.spawn((
                ActivePowerEffect {
                    power_type: PowerType::LowerColumn,
                },
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
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
        }
    }

    // Visual effect for destroyed column
    for tile in tiles.iter() {
        if tile.coordinates.0 == column {
            let world_pos = board_to_world_position(tile.coordinates);
            commands.spawn((
                ActivePowerEffect {
                    power_type: PowerType::DestroyColumn,
                },
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
    println!(
        "Multiply: Checking position {:?} for current player {:?}",
        target_pos, game_state.current_player
    );

    // Check if there's a piece at target position owned by current player
    for (_, piece) in pieces.iter() {
        if piece.board_position == target_pos && piece.player == game_state.current_player {
            println!(
                "Multiply: Found valid piece to duplicate at {:?}",
                target_pos
            );
            // Find adjacent empty tile
            let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)];

            for (dx, dy) in directions.iter() {
                let new_x = target_pos.0 as i8 + dx;
                let new_y = target_pos.1 as i8 + dy;

                if new_x >= 0
                    && new_x < BOARD_WIDTH as i8
                    && new_y >= 0
                    && new_y < BOARD_HEIGHT as i8
                {
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
                                        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Bright metallic blue
                                        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Bright metallic red
                                    },
                                    custom_size: Some(Vec2::splat(TILE_SIZE * 1.2)),
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
pub fn is_valid_move_with_diagonal(from: (u8, u8), to: (u8, u8), allow_diagonal: bool) -> bool {
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    if allow_diagonal {
        // Allow diagonal moves (distance 1 in both x and y)
        (dx <= 1 && dy <= 1) && (dx + dy > 0)
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
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
        } else {
            sprite.color.set_a(alpha);
        }
    }
}

fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    // Use enhanced tile size to match 2D board layout
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match board.rs enhanced tile size
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

fn world_to_board_position(world_pos: Vec2) -> (u8, u8) {
    // Use enhanced tile size to match 2D board layout
    let enhanced_tile_size = TILE_SIZE * 1.2; // Match board.rs enhanced tile size
                                              // Reverse the board.rs formula: tile_pos = (board_pos - BOARD_SIZE/2.0 + 0.5) * tile_size
                                              // So: board_pos = (tile_pos / tile_size) + BOARD_SIZE/2.0 - 0.5
    let x = ((world_pos.x / enhanced_tile_size) + BOARD_WIDTH as f32 / 2.0 - 0.5).round() as i8;
    let y = ((world_pos.y / enhanced_tile_size) + BOARD_HEIGHT as f32 / 2.0 - 0.5).round() as i8;

    let x = x.max(0).min(BOARD_WIDTH as i8 - 1) as u8;
    let y = y.max(0).min(BOARD_HEIGHT as i8 - 1) as u8;

    (x, y)
}

fn activate_dredge_column(
    column: u8,
    current_player: Player,
    commands: &mut Commands,
    pieces: &Query<(Entity, &GamePiece)>,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
) {
    use crate::systems::terrain_height::{MAX_HEIGHT, MIN_HEIGHT};

    println!(
        "💧 Dredge Column {} activated by {:?}",
        column, current_player
    );

    // Find all pieces in the column and adjust terrain
    for (_piece_entity, piece) in pieces.iter() {
        if piece.board_position.0 == column {
            // Find the tile at this piece's position
            for (tile_entity, mut tile, mut terrain) in tiles.iter_mut() {
                if tile.coordinates == piece.board_position {
                    let old_height = tile.height;

                    if piece.player == current_player {
                        // Raise friendly pieces 2 levels
                        tile.height = (tile.height + 2).min(MAX_HEIGHT);
                        terrain.height = tile.height;
                        println!(
                            "  ⬆️ Raised friendly piece at ({}, {}) from {} to {}",
                            tile.coordinates.0, tile.coordinates.1, old_height, tile.height
                        );
                    } else {
                        // Sink enemy pieces 2 levels
                        tile.height = (tile.height - 2).max(MIN_HEIGHT);
                        terrain.height = tile.height;
                        println!(
                            "  ⬇️ Sunk enemy piece at ({}, {}) from {} to {}",
                            tile.coordinates.0, tile.coordinates.1, old_height, tile.height
                        );
                    }

                    // Add terrain animation
                    commands.entity(tile_entity).insert(
                        crate::systems::terrain_height::TerrainAnimation {
                            start_height: old_height,
                            target_height: tile.height,
                            duration: 0.8,
                            elapsed: 0.0,
                        },
                    );
                    break;
                }
            }
        }
    }
}

fn activate_snake_tunneling(
    start_pos: (u8, u8),
    commands: &mut Commands,
    pieces: &Query<(Entity, &GamePiece)>,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
) {
    use crate::systems::terrain_height::MAX_HEIGHT;

    println!(
        "🐍 Snake Tunneling activated from ({}, {})",
        start_pos.0, start_pos.1
    );

    // Snake creates a straight line path across the entire row
    let snake_row = start_pos.1;

    for x in 0..BOARD_WIDTH {
        let pos = (x, snake_row);

        // Destroy any pieces in the path
        for (piece_entity, piece) in pieces.iter() {
            if piece.board_position == pos {
                if let Some(mut entity_commands) = commands.get_entity(piece_entity) {
                    entity_commands.despawn();
                }
                println!("  💥 Snake destroyed piece at ({}, {})", pos.0, pos.1);
            }
        }

        // Raise terrain 2 levels along the path
        for (tile_entity, mut tile, mut terrain) in tiles.iter_mut() {
            if tile.coordinates == pos {
                let old_height = tile.height;
                tile.height = (tile.height + 2).min(MAX_HEIGHT);
                terrain.height = tile.height;

                // Add terrain animation
                commands.entity(tile_entity).insert(
                    crate::systems::terrain_height::TerrainAnimation {
                        start_height: old_height,
                        target_height: tile.height,
                        duration: 1.0,
                        elapsed: 0.0,
                    },
                );

                println!(
                    "  ⬆️ Snake raised terrain at ({}, {}) from {} to {}",
                    pos.0, pos.1, old_height, tile.height
                );
                break;
            }
        }
    }

    println!(
        "🐍 Snake tunneling complete - row {} devastated and raised",
        snake_row
    );
}

/// Rotate pieces in a 3x3 area 90 degrees clockwise
fn activate_rotate_area(
    center: (u8, u8),
    commands: &mut Commands,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};

    // Collect pieces in 3x3 area
    let mut area_pieces = Vec::new();

    for dx in -1i8..=1 {
        for dy in -1i8..=1 {
            let target_x = center.0 as i8 + dx;
            let target_y = center.1 as i8 + dy;

            if target_x >= 0
                && target_x < BOARD_WIDTH as i8
                && target_y >= 0
                && target_y < BOARD_HEIGHT as i8
            {
                let pos = (target_x as u8, target_y as u8);
                if let Some((entity, piece)) = pieces.iter().find(|(_, p)| p.board_position == pos)
                {
                    area_pieces.push((entity, *piece, dx, dy));
                }
            }
        }
    }

    // Apply 90-degree clockwise rotation
    for (entity, piece, dx, dy) in area_pieces {
        // Rotation matrix for 90 degrees clockwise: (x,y) -> (y, -x)
        let new_dx = dy;
        let new_dy = -dx;

        let new_x = center.0 as i8 + new_dx;
        let new_y = center.1 as i8 + new_dy;

        if new_x >= 0 && new_x < BOARD_WIDTH as i8 && new_y >= 0 && new_y < BOARD_HEIGHT as i8 {
            let new_pos = (new_x as u8, new_y as u8);

            // Update piece position
            commands.entity(entity).insert(GamePiece {
                player: piece.player,
                board_position: new_pos,
            });

            // Update visual position
            let world_pos = board_to_world_position(new_pos);
            commands
                .entity(entity)
                .insert(Transform::from_xyz(world_pos.x, world_pos.y, 1.0));

            println!(
                "  🔄 Rotated piece from {:?} to {:?}",
                piece.board_position, new_pos
            );
        }
    }
}

/// Activate TeachRow power - shares a power with all friendly pieces in the same row
fn activate_teach_row(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
    turn_counter: &TurnCounter,
) {
    // Find current player's pieces and determine what power to teach
    let current_player_pieces: Vec<_> = pieces
        .iter()
        .filter(|(_, piece)| piece.player == game_state.current_player)
        .collect();

    if current_player_pieces.is_empty() {
        println!("No pieces found to teach");
        return;
    }

    // For simplicity, teach MoveDiagonal to all pieces in each row that has current player's pieces
    let mut rows_taught = std::collections::HashSet::new();

    for (teacher_entity, teacher_piece) in &current_player_pieces {
        let teacher_row = teacher_piece.board_position.1;

        if rows_taught.contains(&teacher_row) {
            continue; // Already taught this row
        }

        // Find all friendly pieces in the same row
        let students: Vec<_> = pieces
            .iter()
            .filter(|(student_entity, student_piece)| {
                *student_entity != *teacher_entity
                    && student_piece.player == game_state.current_player
                    && student_piece.board_position.1 == teacher_row
            })
            .collect();

        // Teach MoveDiagonal to all students in this row
        for (student_entity, _) in students {
            commands.entity(student_entity).insert(MoveDiagonalActive);

            // Add a temporary effect for 5 turns
            let teach_effect = PowerEffect::new(
                PowerType::MoveDiagonal,
                5, // Duration in turns
                student_entity,
                EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)),
                game_state.current_player,
                turn_counter.turn_number,
            );
            add_effect_to_entity(commands, student_entity, teach_effect);
        }

        rows_taught.insert(teacher_row);
        println!(
            "🎓 Teach Row: Taught MoveDiagonal to all pieces in row {}",
            teacher_row
        );
    }
}

/// Activate TeachRadial power - shares a power with all friendly pieces in 3x3 area around target
fn activate_teach_radial(
    center_pos: (u8, u8),
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
    turn_counter: &TurnCounter,
) {
    // Find the piece at center position (must be current player's piece)
    let teacher = pieces.iter().find(|(_, piece)| {
        piece.board_position == center_pos && piece.player == game_state.current_player
    });

    if teacher.is_none() {
        println!("No valid teacher piece found at center position");
        return;
    }

    // Find all friendly pieces in 3x3 area around center
    let students: Vec<_> = pieces
        .iter()
        .filter(|(_student_entity, student_piece)| {
            student_piece.player == game_state.current_player
                && student_piece.board_position != center_pos // Don't teach to self
                && {
                    let dx = (student_piece.board_position.0 as i8 - center_pos.0 as i8).abs();
                    let dy = (student_piece.board_position.1 as i8 - center_pos.1 as i8).abs();
                    dx <= 1 && dy <= 1 // Within 3x3 area
                }
        })
        .collect();

    // Teach MoveDiagonal to all students (in a real implementation, this would be the teacher's last used power)
    let student_count = students.len();
    for (student_entity, student_piece) in students {
        commands.entity(student_entity).insert(MoveDiagonalActive);

        // Add a temporary effect for 3 turns (shorter than row teaching)
        let teach_effect = PowerEffect::new(
            PowerType::MoveDiagonal,
            3, // Duration in turns
            student_entity,
            EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)),
            game_state.current_player,
            turn_counter.turn_number,
        );
        add_effect_to_entity(commands, student_entity, teach_effect);

        println!(
            "🎓 Teach Radial: Taught MoveDiagonal to piece at ({}, {})",
            student_piece.board_position.0, student_piece.board_position.1
        );
    }

    println!(
        "🎓 Teach Radial complete - {} pieces learned MoveDiagonal around center ({}, {})",
        student_count, center_pos.0, center_pos.1
    );
}

/// Enhanced DoublePower implementation with amplifier system
fn activate_double_power(
    _commands: &mut Commands,
    game_state: &mut GameState,
    power_index: usize,
    _powers: &[PowerType],
) {
    // Get the current player's available powers (excluding the DoublePower itself)
    let available_powers: Vec<PowerType> = game_state
        .get_current_player_powers()
        .iter()
        .enumerate()
        .filter_map(|(i, &power)| {
            if i != power_index && power.can_be_copied() {
                Some(power)
            } else {
                None
            }
        })
        .collect();

    if !available_powers.is_empty() {
        // Let the player choose which power to double, or pick the most recent
        if let Some(&power_to_double) = available_powers.last() {
            // Add the power back to inventory with enhanced effect
            game_state
                .get_current_player_powers_mut()
                .push(power_to_double);

            println!(
                "🔄 Double Power activated - can use {:?} again with enhanced effect",
                power_to_double
            );
        }
    } else {
        println!("⚠️ No powers available to double");
    }
}

/// Activate PowerEcho - repeats the last opponent power
fn activate_power_echo(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
    turn_counter: &TurnCounter,
) {
    // In a full implementation, this would access the power registry
    // For now, simulate echoing a common opponent power
    let echo_power = PowerType::MoveDiagonal; // Simplified - would be last opponent power

    // Find current player's pieces and give them the echoed power
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            commands.entity(entity).insert(MoveDiagonalActive);

            // Add temporary effect
            let echo_effect = PowerEffect::new(
                echo_power,
                2, // Short duration for echoed powers
                entity,
                EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)),
                game_state.current_player,
                turn_counter.turn_number,
            );
            add_effect_to_entity(commands, entity, echo_effect);
        }
    }

    println!(
        "🔊 Power Echo activated - echoed {:?} back to current player's pieces",
        echo_power
    );
}

/// Activate PowerMemory - restores previously used powers
fn activate_power_memory(
    _commands: &mut Commands,
    game_state: &mut GameState,
    _pieces: &Query<(Entity, &GamePiece)>,
) {
    // Simulate power memory by adding back some previously "used" powers
    // In a full implementation, this would access the PowerHistory component
    let remembered_powers = vec![
        PowerType::MoveDiagonal,
        PowerType::Teleport,
        PowerType::Shield,
    ];

    let current_player_powers = game_state.get_current_player_powers_mut();
    let mut powers_restored = 0;

    for power in remembered_powers {
        // Only restore if not already in inventory and limit to 2 restorations
        if !current_player_powers.contains(&power) && powers_restored < 2 {
            current_player_powers.push(power);
            powers_restored += 1;
            println!("💾 Power Memory restored: {:?}", power);
        }
    }

    if powers_restored == 0 {
        // If no specific powers to restore, add a random basic power
        current_player_powers.push(PowerType::MoveDiagonal);
        println!("💾 Power Memory restored: MoveDiagonal (fallback)");
    } else {
        println!(
            "💾 Power Memory complete - restored {} powers from memory",
            powers_restored
        );
    }
}

/// Activate GrowQuadradius - the most powerful power that extends range to entire board
fn activate_grow_quadradius(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
    turn_counter: &TurnCounter,
) {
    // Find all current player's pieces and give them massive range extension
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            // Add the GrowQuadradius active component with extended range
            commands.entity(entity).insert(GrowQuadradiusActive {
                remaining_turns: 5,   // Powerful but limited duration
                range_extension: 255, // Effectively infinite range on a 10x8 board
            });

            // Add the power effect for tracking
            let grow_effect = PowerEffect::new(
                PowerType::GrowQuadradius,
                5, // Duration in turns
                entity,
                EffectData::Status(StatusEffect::Recruiting {
                    conversion_power: 255,
                }), // Repurpose for range extension
                game_state.current_player,
                turn_counter.turn_number,
            );
            add_effect_to_entity(commands, entity, grow_effect);

            println!(
                "🌟 GrowQuadradius: Extended range for piece at ({}, {}) to entire board",
                piece.board_position.0, piece.board_position.1
            );
        }
    }

    println!(
        "🌟 GrowQuadradius activated - ALL {} pieces now have board-wide range for 5 turns!",
        match game_state.current_player {
            Player::Player1 => "Player 1",
            Player::Player2 => "Player 2",
        }
    );

    // Add special visual effect for this massive power
    commands.spawn((
        ActivePowerEffect {
            power_type: PowerType::GrowQuadradius,
        },
        SpriteBundle {
            sprite: Sprite {
                color: Color::rgba(1.0, 0.0, 1.0, 0.3), // Bright magenta glow
                custom_size: Some(Vec2::new(TILE_SIZE * 20.0, TILE_SIZE * 16.0)), // Cover entire board
                ..default()
            },
            transform: Transform::from_xyz(0.0, 0.0, 5.0), // High Z to show over everything
            ..default()
        },
    ));
}

/// Activate Acid - creates permanent holes in the board making tiles unusable
fn activate_acid_attack(
    target_pos: (u8, u8),
    commands: &mut Commands,
    pieces: &Query<(Entity, &GamePiece)>,
    tiles: &mut Query<(Entity, &mut BoardTile, &mut TerrainHeight)>,
) {
    println!("💧 Acid attack at ({}, {}) - creating permanent hole", target_pos.0, target_pos.1);

    // Remove any piece at the target position
    for (entity, piece) in pieces.iter() {
        if piece.board_position == target_pos {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
            println!("  Destroyed piece at target location");
        }
    }

    // Set target tile to minimum height and mark as acidic
    use crate::systems::terrain_height::{set_tile_height, MIN_HEIGHT};
    set_tile_height(target_pos.0, target_pos.1, MIN_HEIGHT - 1, tiles, commands);

    // Mark tile as permanently damaged with acid
    for (entity, mut tile, mut terrain) in tiles.iter_mut() {
        if tile.coordinates == target_pos {
            // Set to below minimum height to indicate hole
            tile.height = MIN_HEIGHT - 1;
            terrain.height = MIN_HEIGHT - 1;
            
            // Add acid marker component
            commands.entity(entity).insert(crate::components::power::AcidHole);
            break;
        }
    }

    // Spawn visual effect - acid bubbling
    let world_pos = board_to_world_position(target_pos);
    for _ in 0..8 {
        let offset_x = (rand::random::<f32>() - 0.5) * 30.0;
        let offset_y = (rand::random::<f32>() - 0.5) * 30.0;
        
        commands.spawn((
            SpriteBundle {
                sprite: Sprite {
                    color: Color::rgb(0.8, 1.0, 0.2), // Acid green-yellow
                    custom_size: Some(Vec2::new(6.0, 6.0)),
                    ..default()
                },
                transform: Transform::from_translation(Vec3::new(
                    world_pos.x + offset_x,
                    world_pos.y + offset_y,
                    2.0,
                )),
                ..default()
            },
            crate::systems::visual_effects::ParticleEffect {
                lifetime: 2.0,
                max_lifetime: 2.0,
                velocity: Vec3::new(
                    (rand::random::<f32>() - 0.5) * 50.0,
                    (rand::random::<f32>() - 0.5) * 50.0,
                    0.0,
                ),
                color: Color::rgb(0.8, 1.0, 0.2),
                size: 6.0,
            },
        ));
    }

    println!("  Tile permanently destroyed - no movement possible through this position");
}
