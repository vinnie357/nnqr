use crate::components::*;
use crate::resources::ScreenShake;
use bevy::prelude::*;
use rand::Rng;

// Enhanced visual components
#[derive(Component)]
pub struct ParticleEffect {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub velocity: Vec3,
    pub color: Color,
    pub size: f32,
}

#[derive(Component)]
pub struct AnimatedScale {
    pub start_scale: f32,
    pub target_scale: f32,
    pub duration: f32,
    pub elapsed: f32,
}

#[derive(Component)]
pub struct FloatingText {
    pub lifetime: f32,
    pub velocity: Vec3,
}

#[derive(Component)]
pub struct PulseEffect {
    pub min_scale: f32,
    pub max_scale: f32,
    pub speed: f32,
}

// Enhanced power orb visual effects
pub fn setup_enhanced_visuals() {
    // This would add particle system setup
    println!("Enhanced visual effects initialized");
}

// Spawn particle effects for power activation
pub fn spawn_power_activation_particles(
    commands: &mut Commands,
    position: Vec3,
    power_type: PowerType,
) {
    let color = power_type.color();
    let mut rng = rand::thread_rng();

    // Spawn multiple particles
    for _ in 0..15 {
        let velocity = Vec3::new(
            rng.gen_range(-100.0..100.0),
            rng.gen_range(50.0..150.0),
            0.0,
        );

        commands.spawn((
            ParticleEffect {
                lifetime: 2.0,
                max_lifetime: 2.0,
                velocity,
                color,
                size: rng.gen_range(3.0..8.0),
            },
            SpriteBundle {
                sprite: Sprite {
                    color,
                    custom_size: Some(Vec2::splat(4.0)),
                    ..default()
                },
                transform: Transform::from_translation(position),
                ..default()
            },
        ));
    }
}

// Spawn explosion effect for piece capture
pub fn spawn_capture_explosion(commands: &mut Commands, position: Vec3, player_color: Color) {
    let mut rng = rand::thread_rng();

    // Main explosion burst
    for _ in 0..20 {
        let angle = rng.gen_range(0.0..std::f32::consts::TAU);
        let speed = rng.gen_range(50.0..150.0);
        let velocity = Vec3::new(angle.cos() * speed, angle.sin() * speed, 0.0);

        commands.spawn((
            ParticleEffect {
                lifetime: 1.5,
                max_lifetime: 1.5,
                velocity,
                color: player_color,
                size: rng.gen_range(2.0..6.0),
            },
            SpriteBundle {
                sprite: Sprite {
                    color: player_color,
                    custom_size: Some(Vec2::splat(3.0)),
                    ..default()
                },
                transform: Transform::from_translation(position),
                ..default()
            },
        ));
    }
}

// Add floating damage text
pub fn spawn_floating_text(commands: &mut Commands, position: Vec3, text: String, color: Color) {
    commands.spawn((
        FloatingText {
            lifetime: 2.0,
            velocity: Vec3::new(0.0, 50.0, 0.0),
        },
        Text2dBundle {
            text: Text::from_section(
                text,
                TextStyle {
                    font_size: 20.0,
                    color,
                    ..default()
                },
            ),
            transform: Transform::from_translation(position + Vec3::new(0.0, 20.0, 5.0)),
            ..default()
        },
    ));
}

// Enhanced floating text for power activations with different styles based on power impact
pub fn spawn_enhanced_power_text(commands: &mut Commands, position: Vec3, power_type: PowerType) {
    let (font_size, lifetime, velocity, offset) = match power_type {
        // High impact powers - larger, longer lasting, more dramatic
        PowerType::SmartBomb | PowerType::Explode | PowerType::Earthquake => (
            32.0,
            3.0,
            Vec3::new(0.0, 80.0, 0.0),
            Vec3::new(0.0, 40.0, 10.0),
        ),
        PowerType::DestroyColumn | PowerType::Assassin => (
            28.0,
            2.5,
            Vec3::new(0.0, 70.0, 0.0),
            Vec3::new(0.0, 35.0, 8.0),
        ),
        // Medium impact powers - standard display
        PowerType::RaiseArea | PowerType::LowerArea | PowerType::Sniper => (
            24.0,
            2.0,
            Vec3::new(0.0, 60.0, 0.0),
            Vec3::new(0.0, 30.0, 6.0),
        ),
        // Low impact powers - smaller, quicker
        PowerType::MoveDiagonal | PowerType::Teleport | PowerType::Jump => (
            18.0,
            1.5,
            Vec3::new(0.0, 40.0, 0.0),
            Vec3::new(0.0, 25.0, 4.0),
        ),
        // Default for all other powers
        _ => (
            20.0,
            2.0,
            Vec3::new(0.0, 50.0, 0.0),
            Vec3::new(0.0, 20.0, 5.0),
        ),
    };

    let text = format!("⚡ {} ⚡", power_type.name());
    let color = power_type.color();

    commands.spawn((
        FloatingText { lifetime, velocity },
        Text2dBundle {
            text: Text::from_section(
                text,
                TextStyle {
                    font_size,
                    color,
                    ..default()
                },
            ),
            transform: Transform::from_translation(position + offset),
            ..default()
        },
        // Add a special component to identify power activation text
        PowerActivationText { power_type },
    ));
}

#[derive(Component)]
pub struct PowerActivationText {
    pub power_type: PowerType,
}

// Animate particles
pub fn update_particle_effects(
    mut commands: Commands,
    time: Res<Time>,
    mut particles: Query<(Entity, &mut ParticleEffect, &mut Transform, &mut Sprite)>,
) {
    for (entity, mut particle, mut transform, mut sprite) in particles.iter_mut() {
        particle.lifetime -= time.delta_seconds();

        if particle.lifetime <= 0.0 {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
            continue;
        }

        // Update position
        transform.translation += particle.velocity * time.delta_seconds();

        // Fade out over time
        let alpha = particle.lifetime / particle.max_lifetime;
        sprite.color.set_a(alpha);

        // Shrink over time
        let scale = alpha * particle.size / 4.0;
        transform.scale = Vec3::splat(scale);

        // Apply gravity
        particle.velocity.y -= 200.0 * time.delta_seconds();
    }
}

// Animate floating text
pub fn update_floating_text(
    mut commands: Commands,
    time: Res<Time>,
    mut texts: Query<(Entity, &mut FloatingText, &mut Transform, &mut Text)>,
) {
    for (entity, mut floating, mut transform, mut text) in texts.iter_mut() {
        floating.lifetime -= time.delta_seconds();

        if floating.lifetime <= 0.0 {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
            continue;
        }

        // Update position
        transform.translation += floating.velocity * time.delta_seconds();

        // Fade out
        let alpha = floating.lifetime / 2.0;
        if let Some(section) = text.sections.first_mut() {
            section.style.color.set_a(alpha);
        }
    }
}

// Enhanced animation for power activation text with special effects
pub fn update_power_activation_text(
    mut commands: Commands,
    time: Res<Time>,
    mut texts: Query<(
        Entity,
        &mut FloatingText,
        &mut Transform,
        &mut Text,
        &PowerActivationText,
    )>,
) {
    for (entity, mut floating, mut transform, mut text, power_text) in texts.iter_mut() {
        floating.lifetime -= time.delta_seconds();

        if floating.lifetime <= 0.0 {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
            }
            continue;
        }

        // Update position with slight deceleration
        let velocity_factor = floating.lifetime / 3.0; // Assume max lifetime is 3.0
        transform.translation += floating.velocity * time.delta_seconds() * velocity_factor;

        // Enhanced effects based on power type
        let elapsed_time = time.elapsed_seconds();

        match power_text.power_type {
            // High impact powers get pulsing scale effect
            PowerType::SmartBomb | PowerType::Explode | PowerType::Earthquake => {
                let pulse = 1.0 + 0.2 * (elapsed_time * 8.0).sin();
                transform.scale = Vec3::splat(pulse);
            }
            // Medium impact powers get gentle sway
            PowerType::DestroyColumn | PowerType::Assassin => {
                let sway = 5.0 * (elapsed_time * 4.0).sin();
                transform.translation.x += sway * time.delta_seconds();
            }
            _ => {
                // Standard powers get gentle scale fade
                let scale_factor = floating.lifetime / 2.0;
                transform.scale = Vec3::splat(scale_factor.max(0.5));
            }
        }

        // Enhanced fade out with power color intensity
        let alpha = (floating.lifetime / 3.0).max(0.0);
        if let Some(section) = text.sections.first_mut() {
            section.style.color.set_a(alpha);
        }
    }
}

// Animate scaled objects
pub fn update_animated_scale(
    mut commands: Commands,
    time: Res<Time>,
    mut scaled: Query<(Entity, &mut AnimatedScale, &mut Transform)>,
) {
    for (entity, mut anim, mut transform) in scaled.iter_mut() {
        anim.elapsed += time.delta_seconds();

        if anim.elapsed >= anim.duration {
            transform.scale = Vec3::splat(anim.target_scale);
            commands.entity(entity).remove::<AnimatedScale>();
            continue;
        }

        // Smooth interpolation
        let t = anim.elapsed / anim.duration;
        let smooth_t = t * t * (3.0 - 2.0 * t); // Smoothstep
        let scale = anim.start_scale + (anim.target_scale - anim.start_scale) * smooth_t;
        transform.scale = Vec3::splat(scale);
    }
}

// Update pulsing effects
pub fn update_pulse_effects(time: Res<Time>, mut pulsing: Query<(&PulseEffect, &mut Transform)>) {
    for (pulse, mut transform) in pulsing.iter_mut() {
        let time_factor = time.elapsed_seconds() * pulse.speed;
        let scale =
            pulse.min_scale + (pulse.max_scale - pulse.min_scale) * (0.5 + 0.5 * time_factor.sin());
        transform.scale = Vec3::splat(scale);
    }
}

// Enhanced power orb effects
pub fn enhance_power_orbs(
    mut commands: Commands,
    orbs: Query<Entity, (With<PowerOrb>, Without<PulseEffect>)>,
) {
    for entity in orbs.iter() {
        commands.entity(entity).insert(PulseEffect {
            min_scale: 0.9,
            max_scale: 1.1,
            speed: 2.0,
        });
    }
}

// Screen shake functionality - resource definition moved to resources/visual_effects.rs

pub fn trigger_screen_shake(screen_shake: &mut ResMut<ScreenShake>, intensity: f32, duration: f32) {
    screen_shake.intensity = intensity;
    screen_shake.duration = duration;
    screen_shake.remaining = duration;
}

// Enhanced screen shake system for dramatic power effects
pub fn trigger_power_screen_shake(
    commands: &mut Commands,
    screen_shake: Option<ResMut<ScreenShake>>,
    power_type: PowerType,
) {
    if let Some(mut shake) = screen_shake {
        let (intensity, duration) = match power_type {
            // High impact destructive powers
            PowerType::SmartBomb | PowerType::Explode => (15.0, 0.8),
            PowerType::DestroyColumn => (12.0, 0.6),
            PowerType::Earthquake => (20.0, 1.0),

            // Medium impact powers
            PowerType::Assassin | PowerType::Sniper => (8.0, 0.4),
            PowerType::Push | PowerType::Pull => (5.0, 0.3),
            PowerType::Teleport | PowerType::Swap => (6.0, 0.2),

            // Area manipulation powers
            PowerType::RaiseColumn | PowerType::LowerColumn => (7.0, 0.5),
            PowerType::RaiseArea | PowerType::LowerArea => (10.0, 0.6),
            PowerType::Shuffle | PowerType::Rotate => (8.0, 0.4),

            // Terrain manipulation
            PowerType::Pit | PowerType::Terraform => (6.0, 0.4),
            PowerType::Bridge => (4.0, 0.3),

            // No shake for passive powers
            _ => return,
        };

        trigger_screen_shake(&mut shake, intensity, duration);
        println!(
            "Triggered screen shake for {:?}: intensity={}, duration={}",
            power_type, intensity, duration
        );
    }
}

pub fn update_screen_shake(
    time: Res<Time>,
    mut screen_shake: ResMut<ScreenShake>,
    mut camera: Query<&mut Transform, With<Camera>>,
) {
    if screen_shake.remaining <= 0.0 {
        return;
    }

    screen_shake.remaining -= time.delta_seconds();

    if screen_shake.remaining <= 0.0 {
        // Reset camera position smoothly
        for mut transform in camera.iter_mut() {
            // Gradually return to original position to avoid jarring snap
            transform.translation.x *= 0.1;
            transform.translation.y *= 0.1;
            if transform.translation.x.abs() < 0.1 && transform.translation.y.abs() < 0.1 {
                transform.translation.x = 0.0;
                transform.translation.y = 0.0;
            }
        }
        screen_shake.intensity = 0.0;
        return;
    }

    // Apply enhanced shake with easing
    let mut rng = rand::thread_rng();
    let shake_factor = screen_shake.remaining / screen_shake.duration;
    let eased_factor = shake_factor * shake_factor; // Quadratic easing for smoother decay

    let offset_x = rng.gen_range(-1.0..1.0) * screen_shake.intensity * eased_factor;
    let offset_y = rng.gen_range(-1.0..1.0) * screen_shake.intensity * eased_factor;

    for mut transform in camera.iter_mut() {
        transform.translation.x = offset_x;
        transform.translation.y = offset_y;
    }
}

// Enhanced piece movement animation
pub fn animate_piece_movement(
    commands: &mut Commands,
    entity: Entity,
    start_pos: Vec3,
    end_pos: Vec3,
) {
    // Add smooth movement animation instead of instant teleport
    commands.entity(entity).insert(AnimatedScale {
        start_scale: 1.0,
        target_scale: 1.2,
        duration: 0.1,
        elapsed: 0.0,
    });

    // This would need a proper movement tween component in a full implementation
    println!(
        "Animating piece movement from {:?} to {:?}",
        start_pos, end_pos
    );
}
