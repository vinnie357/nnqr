use crate::components::*;
use crate::resources::game_state::TurnCounter;
use crate::resources::*;
use crate::systems::effect_processing::ActiveEffects;
use bevy::prelude::*;

/// System to handle combat interactions with effects
pub fn process_combat_with_effects(
    mut commands: Commands,
    game_state: Res<GameState>,
    mut pieces_query: Query<(Entity, &GamePiece, Option<&mut ActiveEffects>)>,
    capture_attempts: Query<(Entity, &CaptureAttempt)>,
) {
    // Store reflection data to process after main loop
    let mut reflection_data = Vec::new();
    for (attempt_entity, capture_attempt) in capture_attempts.iter() {
        let target_pos = capture_attempt.target_position;
        let attacker_player = capture_attempt.attacker_player;

        // Find the target piece
        if let Some((target_entity, target_piece, target_effects)) = pieces_query
            .iter_mut()
            .find(|(_, piece, _)| piece.board_position == target_pos)
        {
            let mut capture_blocked = false;

            // Check for shield protection
            if let Some(mut effects) = target_effects {
                if let Some(shield_effect) = effects.effects.iter_mut().find(|e| {
                    matches!(
                        e.effect_data,
                        EffectData::Protection(ProtectionType::Shield { .. })
                    )
                }) {
                    // Shield blocks the attack
                    capture_blocked = true;

                    // Reduce shield hits
                    if let EffectData::Protection(ProtectionType::Shield {
                        ref mut hits_remaining,
                    }) = shield_effect.effect_data
                    {
                        *hits_remaining = hits_remaining.saturating_sub(1);

                        if *hits_remaining == 0 {
                            // Remove shield effect
                            effects.effects.retain(|e| {
                                !matches!(
                                    e.effect_data,
                                    EffectData::Protection(ProtectionType::Shield { .. })
                                )
                            });
                            println!("🛡 Shield destroyed!");
                        } else {
                            println!(
                                "🛡 Shield absorbed attack! {} hits remaining",
                                hits_remaining
                            );
                        }
                    }

                    // Spawn shield break visual effect
                    let world_pos = board_to_world_position(target_pos);
                    crate::systems::visual_effects::spawn_capture_explosion(
                        &mut commands,
                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                        Color::rgb(0.7, 0.7, 0.9), // Shield blue
                    );
                }

                // Check for Jump Proof immunity
                if effects.has_effect("Jump Proof") {
                    capture_blocked = true;
                    println!("🚫 Attack blocked by Jump Proof immunity!");

                    // Spawn immunity visual effect
                    let world_pos = board_to_world_position(target_pos);
                    crate::systems::visual_effects::spawn_capture_explosion(
                        &mut commands,
                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                        Color::rgb(0.0, 1.0, 1.0), // Cyan immunity
                    );
                }

                // Check for reflection
                if let Some(reflect_effect) = effects.effects.iter().find(|e| {
                    matches!(
                        e.effect_data,
                        EffectData::Protection(ProtectionType::Reflection { .. })
                    )
                }) {
                    // Reflect the attack back to attacker
                    capture_blocked = true;

                    // Store reflection info for later processing
                    reflection_data.push((
                        target_piece.player,
                        attacker_player,
                        capture_attempt.damage_type.clone(),
                    ));

                    // Spawn reflection visual effect
                    let world_pos = board_to_world_position(target_pos);
                    crate::systems::visual_effects::spawn_capture_explosion(
                        &mut commands,
                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                        Color::rgb(0.8, 0.7, 0.9), // Purple reflection
                    );
                }
            }

            if !capture_blocked {
                // Normal capture occurs
                execute_capture(&mut commands, target_entity, &capture_attempt);
            }
        }

        // Remove the processed capture attempt
        commands.entity(attempt_entity).despawn();
    }

    // Process any reflections that were queued
    for (defender_player, attacker_player, damage_type) in reflection_data {
        // Find attacker pieces to reflect damage to
        for (_, piece, _) in pieces_query.iter() {
            if piece.player == attacker_player {
                println!("↩ Attack reflected back to attacker!");

                // Create reflection capture attempt
                commands.spawn(CaptureAttempt {
                    target_position: piece.board_position,
                    attacker_player: defender_player,
                    damage_type,
                    can_be_blocked: false, // Reflections can't be blocked
                });
                break; // Only reflect to one piece
            }
        }
    }
}

/// Component to represent a capture attempt
#[derive(Component)]
pub struct CaptureAttempt {
    pub target_position: (u8, u8),
    pub attacker_player: Player,
    pub damage_type: DamageType,
    pub can_be_blocked: bool,
}

/// Execute a successful capture
fn execute_capture(
    commands: &mut Commands,
    target_entity: Entity,
    capture_attempt: &CaptureAttempt,
) {
    // Remove the captured piece
    commands.entity(target_entity).despawn();

    // Spawn capture effect
    let world_pos = board_to_world_position(capture_attempt.target_position);
    crate::systems::visual_effects::spawn_capture_explosion(
        commands,
        Vec3::new(world_pos.x, world_pos.y, 0.0),
        Color::rgb(1.0, 0.4, 0.4), // Red capture explosion
    );

    println!("💥 Piece captured at {:?}", capture_attempt.target_position);
}

/// System to handle invisibility effects in targeting
pub fn apply_invisibility_targeting(
    game_state: Res<GameState>,
    pieces_query: Query<(&GamePiece, &ActiveEffects)>,
    mut targeting_query: Query<&mut TargetingIndicator>,
) {
    for mut targeting in targeting_query.iter_mut() {
        // Check if target piece is invisible to current player
        if let Some((target_piece, target_effects)) = pieces_query
            .iter()
            .find(|(piece, _)| piece.board_position == targeting.target_position)
        {
            // Enemy pieces with invisibility can't be targeted
            if target_piece.player != game_state.current_player
                && target_effects.has_effect("Invisible")
            {
                targeting.is_valid = false;
                targeting.blocked_reason = Some("Target is invisible".to_string());
            }
        }
    }
}

/// Component for targeting indicators
#[derive(Component)]
pub struct TargetingIndicator {
    pub target_position: (u8, u8),
    pub is_valid: bool,
    pub blocked_reason: Option<String>,
}

/// System to prevent movement for frozen pieces
pub fn apply_frozen_movement_restriction(
    pieces_query: Query<(&GamePiece, &ActiveEffects)>,
    mut movement_query: Query<&mut MovementAttempt>,
) {
    for mut movement in movement_query.iter_mut() {
        // Check if the piece trying to move is frozen
        if let Some((_, effects)) = pieces_query
            .iter()
            .find(|(piece, _)| piece.board_position == movement.from_position)
        {
            if effects.has_effect("Frozen") {
                movement.is_valid = false;
                movement.blocked_reason = Some("Piece is frozen and cannot move".to_string());
                println!("❄ Movement blocked: Piece is frozen");
            }
        }
    }
}

/// Component for movement attempts
#[derive(Component)]
pub struct MovementAttempt {
    pub from_position: (u8, u8),
    pub to_position: (u8, u8),
    pub is_valid: bool,
    pub blocked_reason: Option<String>,
}

/// System to handle poison death
pub fn process_poison_death(
    mut commands: Commands,
    game_state: Res<GameState>,
    turn_counter: Res<TurnCounter>,
    pieces_query: Query<(Entity, &GamePiece, &ActiveEffects)>,
) {
    for (entity, piece, effects) in pieces_query.iter() {
        // Check for poison effects that should trigger death
        for effect in &effects.effects {
            if let EffectData::Status(StatusEffect::Poisoned { death_timer }) = &effect.effect_data
            {
                if effect.remaining_turns(turn_counter.turn_number) <= 1 {
                    // Piece dies from poison
                    println!("☠ Piece at {:?} dies from poison!", piece.board_position);

                    // Spawn poison death effect
                    let world_pos = board_to_world_position(piece.board_position);
                    crate::systems::visual_effects::spawn_capture_explosion(
                        &mut commands,
                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                        Color::rgb(0.4, 0.8, 0.2), // Green poison explosion
                    );

                    // Remove the piece
                    commands.entity(entity).despawn();
                }
            }
        }
    }
}

/// System to handle invisibility rendering
pub fn apply_invisibility_rendering(
    game_state: Res<GameState>,
    mut pieces_query: Query<(&GamePiece, &ActiveEffects, &mut Visibility)>,
) {
    for (piece, effects, mut visibility) in pieces_query.iter_mut() {
        if effects.has_effect("Invisible") {
            // Hide piece from opponent, keep visible for owner
            if piece.player != game_state.current_player {
                *visibility = Visibility::Hidden;
            } else {
                // Owner can see their own invisible pieces (with transparency)
                *visibility = Visibility::Visible;
                // TODO: Add transparency effect for owner
            }
        } else {
            // Piece is visible to all
            *visibility = Visibility::Visible;
        }
    }
}

/// System to apply enhanced movement effects
pub fn apply_movement_enhancements(
    pieces_query: Query<(&GamePiece, &ActiveEffects)>,
    mut movement_query: Query<&mut MovementAttempt>,
) {
    for mut movement in movement_query.iter_mut() {
        if let Some((_, effects)) = pieces_query
            .iter()
            .find(|(piece, _)| piece.board_position == movement.from_position)
        {
            // Check for enhanced movement abilities
            for effect in &effects.effects {
                match &effect.effect_data {
                    EffectData::Movement(MovementRestriction::Enhanced(MovementType::Diagonal)) => {
                        // Allow diagonal movement
                        if is_diagonal_move(movement.from_position, movement.to_position) {
                            movement.is_valid = true;
                            movement.blocked_reason = None;
                        }
                    }
                    EffectData::Movement(MovementRestriction::Enhanced(MovementType::Teleport)) => {
                        // Allow teleportation to any empty square
                        movement.is_valid = true;
                        movement.blocked_reason = None;
                    }
                    EffectData::Movement(MovementRestriction::Enhanced(MovementType::Jump)) => {
                        // Allow jumping over pieces
                        if can_jump_to_position(movement.from_position, movement.to_position) {
                            movement.is_valid = true;
                            movement.blocked_reason = None;
                        }
                    }
                    EffectData::Movement(MovementRestriction::Enhanced(MovementType::Knight)) => {
                        // Allow knight-style movement
                        if is_knight_move(movement.from_position, movement.to_position) {
                            movement.is_valid = true;
                            movement.blocked_reason = None;
                        }
                    }
                    _ => {}
                }
            }
        }
    }
}

/// Helper function to check if a move is diagonal
fn is_diagonal_move(from: (u8, u8), to: (u8, u8)) -> bool {
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    dx == 1 && dy == 1
}

/// Helper function to check if a knight move is valid
fn is_knight_move(from: (u8, u8), to: (u8, u8)) -> bool {
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();
    (dx == 2 && dy == 1) || (dx == 1 && dy == 2)
}

/// Helper function to check if jump is possible
fn can_jump_to_position(_from: (u8, u8), _to: (u8, u8)) -> bool {
    // TODO: Implement proper jump validation
    true
}

/// Helper function for coordinate conversion
fn board_to_world_position(board_pos: (u8, u8)) -> Vec2 {
    use crate::components::board::{BOARD_HEIGHT, BOARD_WIDTH};
    use crate::components::TILE_SIZE;

    let enhanced_tile_size = TILE_SIZE * 1.2;
    let x = (board_pos.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let y = (board_pos.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;
    Vec2::new(x, y)
}

/// Helper function to create a capture attempt
pub fn create_capture_attempt(
    commands: &mut Commands,
    target_position: (u8, u8),
    attacker_player: Player,
    damage_type: DamageType,
) {
    commands.spawn(CaptureAttempt {
        target_position,
        attacker_player,
        damage_type,
        can_be_blocked: true,
    });
}

/// System to handle recruitment effects
pub fn apply_recruitment_effects(
    mut commands: Commands,
    mut pieces_query: Query<(Entity, &mut GamePiece, &ActiveEffects)>,
    game_state: Res<GameState>,
    turn_counter: Res<TurnCounter>,
) {
    for (entity, mut piece, effects) in pieces_query.iter_mut() {
        // Check for recruitment effects
        for effect in &effects.effects {
            if let EffectData::Status(StatusEffect::Recruiting { conversion_power }) =
                &effect.effect_data
            {
                if effect.remaining_turns(turn_counter.turn_number) <= 1 {
                    // Convert the piece to the effect source player
                    let old_player = piece.player;
                    piece.player = effect.source_player;

                    println!(
                        "🔄 Piece at {:?} converted from {:?} to {:?}",
                        piece.board_position, old_player, effect.source_player
                    );

                    // Update piece color
                    use crate::resources::QuadradiusTheme;
                    let new_color = match effect.source_player {
                        Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
                        Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
                    };

                    commands.entity(entity).insert(Sprite {
                        color: new_color,
                        custom_size: Some(Vec2::splat(TILE_SIZE * 1.2)),
                        ..default()
                    });

                    // Spawn conversion effect
                    let world_pos = board_to_world_position(piece.board_position);
                    crate::systems::visual_effects::spawn_capture_explosion(
                        &mut commands,
                        Vec3::new(world_pos.x, world_pos.y, 0.0),
                        Color::rgb(0.9, 0.5, 0.2), // Orange recruitment
                    );
                }
            }
        }
    }
}
