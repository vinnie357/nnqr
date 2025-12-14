use crate::components::*;
use crate::resources::QuadradiusTheme;
use bevy::prelude::*;

// Animate pieces that had invalid moves with a shake effect
pub fn animate_invalid_moves(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &InvalidMoveAnimation, &mut Transform)>,
) {
    for (entity, animation, mut transform) in query.iter_mut() {
        let elapsed = time.elapsed_seconds() - animation.start_time;

        if elapsed > animation.duration {
            // Animation complete, remove component
            commands.entity(entity).remove::<InvalidMoveAnimation>();
            transform.translation = animation.original_pos;
        } else {
            // Apply shake effect
            let progress = elapsed / animation.duration;
            let shake_intensity = (1.0 - progress) * 5.0; // Decrease intensity over time
            let shake_speed = 30.0;

            // Create shake offset
            let offset_x = (elapsed * shake_speed).sin() * shake_intensity;
            let offset_y = (elapsed * shake_speed * 1.3).cos() * shake_intensity * 0.5;

            transform.translation = animation.original_pos + Vec3::new(offset_x, offset_y, 0.0);
        }
    }
}

// Flash pieces red when move is invalid
pub fn flash_invalid_moves(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &InvalidMoveFlash, &mut Sprite, &GamePiece)>,
) {
    for (entity, flash, mut sprite, piece) in query.iter_mut() {
        let elapsed = time.elapsed_seconds() - flash.start_time;

        if elapsed > flash.duration {
            // Flash complete, restore original color using proper theme colors
            commands.entity(entity).remove::<InvalidMoveFlash>();
            sprite.color = match piece.player {
                Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Bright metallic blue
                Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Bright metallic red
            };
        } else {
            // Apply red flash effect
            let progress = elapsed / flash.duration;
            let flash_intensity = (1.0 - progress).powf(2.0); // Quick fade out

            // Interpolate between piece color and red using proper theme colors
            let base_color = match piece.player {
                Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY, // Bright metallic blue
                Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY, // Bright metallic red
            };

            // Mix with bright red for flash effect
            let flash_color = Color::rgb(1.0, 0.3, 0.3);

            // Manual color interpolation
            let base_r = base_color.r();
            let base_g = base_color.g();
            let base_b = base_color.b();

            let flash_r = flash_color.r();
            let flash_g = flash_color.g();
            let flash_b = flash_color.b();

            sprite.color = Color::rgb(
                base_r + (flash_r - base_r) * flash_intensity,
                base_g + (flash_g - base_g) * flash_intensity,
                base_b + (flash_b - base_b) * flash_intensity,
            );
        }
    }
}

// Show temporary text feedback for invalid moves
#[derive(Component)]
pub struct InvalidMoveText {
    pub lifetime: f32,
}

pub fn spawn_invalid_move_text(
    mut commands: Commands,
    query: Query<(&Transform, &InvalidMoveAnimation), Added<InvalidMoveAnimation>>,
) {
    for (transform, _) in query.iter() {
        // Spawn text above the piece
        commands.spawn((
            Text2dBundle {
                text: Text::from_section(
                    "Invalid Move!",
                    TextStyle {
                        font_size: 20.0,
                        color: Color::rgb(1.0, 0.3, 0.3),
                        ..default()
                    },
                ),
                transform: Transform::from_xyz(
                    transform.translation.x,
                    transform.translation.y + 40.0,
                    5.0,
                ),
                ..default()
            },
            InvalidMoveText { lifetime: 1.0 },
        ));
    }
}

pub fn update_invalid_move_text(
    mut commands: Commands,
    time: Res<Time>,
    mut query: Query<(Entity, &mut InvalidMoveText, &mut Transform, &mut Text)>,
) {
    for (entity, mut text_component, mut transform, mut text) in query.iter_mut() {
        text_component.lifetime -= time.delta_seconds();

        if text_component.lifetime <= 0.0 {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
        } else {
            // Float upward and fade out
            transform.translation.y += 30.0 * time.delta_seconds();

            let alpha = text_component.lifetime;
            if let Some(section) = text.sections.first_mut() {
                section.style.color = Color::rgba(1.0, 0.3, 0.3, alpha);
            }
        }
    }
}
