use crate::components::*;
use bevy::prelude::*;

/// Enhanced visual feedback component
#[derive(Component)]
pub struct VisualFeedback {
    pub feedback_type: FeedbackType,
    pub intensity: f32,
    pub duration: f32,
    pub elapsed: f32,
}

#[derive(Clone, Copy)]
pub enum FeedbackType {
    Selection,
    ValidMove,
    InvalidMove,
    Hover,
    PowerActivation,
}

/// Component for pulsing animations
#[derive(Component)]
pub struct PulseAnimation {
    pub min_scale: f32,
    pub max_scale: f32,
    pub speed: f32,
    pub current_time: f32,
}

/// Component for glow effects
#[derive(Component)]
pub struct GlowEffect {
    pub base_emissive: Color,
    pub glow_intensity: f32,
    pub pulse_speed: f32,
    pub current_time: f32,
}

/// Add visual feedback for piece selection
pub fn add_selection_feedback(
    mut commands: Commands,
    selected_pieces: Query<Entity, (With<crate::components::GamePiece>, Without<VisualFeedback>)>,
) {
    for entity in selected_pieces.iter() {
        commands.entity(entity).insert((
            VisualFeedback {
                feedback_type: FeedbackType::Selection,
                intensity: 1.0,
                duration: f32::INFINITY, // Persist until deselected
                elapsed: 0.0,
            },
            PulseAnimation {
                min_scale: 1.0,
                max_scale: 1.1,
                speed: 3.0,
                current_time: 0.0,
            },
            GlowEffect {
                base_emissive: Color::rgb(1.0, 1.0, 0.0),
                glow_intensity: 0.5,
                pulse_speed: 4.0,
                current_time: 0.0,
            },
        ));
    }
}

/// Add visual feedback for valid move tiles
pub fn add_move_feedback(
    mut commands: Commands,
    _meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    valid_moves: Query<(Entity, &BoardTile), Without<VisualFeedback>>,
) {
    for (entity, _tile) in valid_moves.iter() {
        // Create a glowing overlay for valid move tiles
        let _overlay_material = materials.add(StandardMaterial {
            base_color: Color::rgba(0.0, 1.0, 0.0, 0.3), // Transparent green
            emissive: Color::rgb(0.0, 0.8, 0.0),
            alpha_mode: AlphaMode::Blend,
            metallic: 0.0,
            perceptual_roughness: 1.0,
            ..default()
        });

        commands.entity(entity).insert(VisualFeedback {
            feedback_type: FeedbackType::ValidMove,
            intensity: 0.8,
            duration: f32::INFINITY,
            elapsed: 0.0,
        });
    }
}

/// Update pulse animations for enhanced visual feedback
pub fn update_pulse_animations(
    mut query: Query<(&mut Transform, &mut PulseAnimation)>,
    time: Res<Time>,
) {
    for (mut transform, mut pulse) in query.iter_mut() {
        pulse.current_time += time.delta_seconds();
        let pulse_factor = (pulse.current_time * pulse.speed).sin() * 0.5 + 0.5;
        let scale = pulse.min_scale + (pulse.max_scale - pulse.min_scale) * pulse_factor;
        transform.scale = Vec3::splat(scale);
    }
}

/// Update glow effects for enhanced visual feedback
pub fn update_glow_effects(
    mut query: Query<&mut GlowEffect>,
_materials: ResMut<Assets<StandardMaterial>>,
_material_query: Query<&Handle<StandardMaterial>>,
    time: Res<Time>,
) {
    for mut glow in query.iter_mut() {
        glow.current_time += time.delta_seconds();
        let pulse_factor = (glow.current_time * glow.pulse_speed).sin() * 0.5 + 0.5;
        let glow_intensity = glow.glow_intensity * pulse_factor;

        // Update material emissive property
        // Note: This would need entity-material mapping for full implementation
        let _emissive_color = glow.base_emissive * glow_intensity;
        // materials.get_mut(material_handle).map(|mat| mat.emissive = emissive_color);
    }
}

/// Add hover effects for interactive tiles
pub fn add_hover_effects(
    mut commands: Commands,
    hovered_tiles: Query<Entity, (With<crate::components::BoardTile>, Without<VisualFeedback>)>,
) {
    for entity in hovered_tiles.iter() {
        commands.entity(entity).insert(VisualFeedback {
            feedback_type: FeedbackType::Hover,
            intensity: 0.6,
            duration: f32::INFINITY,
            elapsed: 0.0,
        });
    }
}

/// Clean up visual feedback when no longer needed
pub fn cleanup_visual_feedback(
    mut commands: Commands,
    mut feedback_query: Query<(Entity, &mut VisualFeedback)>,
    time: Res<Time>,
) {
    for (entity, mut feedback) in feedback_query.iter_mut() {
        feedback.elapsed += time.delta_seconds();

        if feedback.duration != f32::INFINITY && feedback.elapsed >= feedback.duration {
            commands.entity(entity).remove::<VisualFeedback>();
            commands.entity(entity).remove::<PulseAnimation>();
            commands.entity(entity).remove::<GlowEffect>();
        }
    }
}

/// Add particle effects for power activations
pub fn add_power_activation_effects(
    mut commands: Commands,
    power_activations: Query<(Entity, &PowerType), With<crate::components::PowerInventory>>,
) {
    for (entity, power_type) in power_activations.iter() {
        let effect_color = match power_type {
            PowerType::MoveDiagonal => Color::rgb(1.0, 0.8, 0.0), // Gold
            PowerType::Jump => Color::rgb(0.0, 0.8, 1.0),         // Cyan
            PowerType::MoveTwo => Color::rgb(0.0, 1.0, 0.0),      // Green
            _ => Color::rgb(1.0, 1.0, 1.0),                       // White default
        };

        commands.entity(entity).insert((
            VisualFeedback {
                feedback_type: FeedbackType::PowerActivation,
                intensity: 1.5,
                duration: 2.0, // 2 second effect
                elapsed: 0.0,
            },
            GlowEffect {
                base_emissive: effect_color,
                glow_intensity: 1.0,
                pulse_speed: 8.0, // Fast pulse for power activation
                current_time: 0.0,
            },
        ));
    }
}
