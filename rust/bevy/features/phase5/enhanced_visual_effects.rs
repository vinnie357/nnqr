use bevy::prelude::*;
use bevy::math::Vec3Swizzles;
use std::collections::HashMap;

/// Phase 5 Enhanced Visual Effects System
/// Professional-grade power animations and visual feedback

#[derive(Resource)]
pub struct VisualEffectsManager {
    pub effect_templates: HashMap<String, EffectTemplate>,
    pub quality_level: VisualQuality,
    pub particle_budget: usize,
    pub active_effects: Vec<ActiveEffect>,
    pub animation_presets: HashMap<String, AnimationPreset>,
}

#[derive(Clone, PartialEq)]
pub enum VisualQuality {
    Ultra,   // Maximum visual fidelity
    High,    // Standard quality
    Medium,  // Balanced performance
    Low,     // Performance priority
    Potato,  // Minimum effects
}

#[derive(Clone)]
pub struct EffectTemplate {
    pub name: String,
    pub duration: f32,
    pub particle_count: usize,
    pub color_scheme: ColorScheme,
    pub animation_type: AnimationType,
    pub sound_effect: Option<String>,
    pub screen_shake: f32,
    pub glow_intensity: f32,
}

#[derive(Clone)]
pub struct ColorScheme {
    pub primary: Color,
    pub secondary: Color,
    pub accent: Color,
    pub trail: Color,
}

#[derive(Clone)]
pub enum AnimationType {
    Burst { radius: f32, speed: f32 },
    Beam { width: f32, length: f32 },
    Spiral { rotations: f32, radius: f32 },
    Pulse { frequency: f32, amplitude: f32 },
    Lightning { branches: usize, chaos: f32 },
    Teleport { fade_duration: f32 },
    Shield { thickness: f32, segments: usize },
    Heal { rise_speed: f32, sparkles: usize },
}

#[derive(Clone)]
pub struct AnimationPreset {
    pub name: String,
    pub keyframes: Vec<Keyframe>,
    pub easing: EasingType,
    pub loop_type: LoopType,
}

#[derive(Clone)]
pub struct Keyframe {
    pub time: f32,
    pub position: Vec3,
    pub scale: Vec3,
    pub rotation: f32,
    pub color: Color,
    pub alpha: f32,
}

#[derive(Clone)]
pub enum EasingType {
    Linear,
    EaseIn,
    EaseOut,
    EaseInOut,
    Bounce,
    Elastic,
}

#[derive(Clone)]
pub enum LoopType {
    None,
    Repeat,
    PingPong,
    Reverse,
}

#[derive(Component)]
pub struct ActiveEffect {
    pub template: EffectTemplate,
    pub start_time: f32,
    pub position: Vec3,
    pub target: Option<Vec3>,
    pub intensity: f32,
    pub particles: Vec<Entity>,
}

#[derive(Component)]
pub struct EnhancedParticle {
    pub velocity: Vec3,
    pub acceleration: Vec3,
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub size: f32,
    pub color: Color,
    pub fade_curve: FadeCurve,
    pub physics: ParticlePhysics,
}

#[derive(Clone)]
pub enum FadeCurve {
    Linear,
    FadeIn,
    FadeOut,
    FadeInOut,
    Pulse,
}

#[derive(Component, Clone)]
pub struct ParticlePhysics {
    pub gravity: f32,
    pub drag: f32,
    pub bounce: f32,
    pub collision: bool,
}

#[derive(Component)]
pub struct ScreenShake {
    pub intensity: f32,
    pub duration: f32,
    pub frequency: f32,
    pub decay: f32,
}

#[derive(Component)]
pub struct GlowEffect {
    pub intensity: f32,
    pub radius: f32,
    pub color: Color,
    pub pulse_speed: f32,
}

impl Default for VisualEffectsManager {
    fn default() -> Self {
        Self {
            effect_templates: create_default_effects(),
            quality_level: VisualQuality::High,
            particle_budget: 500,
            active_effects: Vec::new(),
            animation_presets: create_animation_presets(),
        }
    }
}

fn create_default_effects() -> HashMap<String, EffectTemplate> {
    let mut effects = HashMap::new();
    
    // Combat Power Effects
    effects.insert("Bomb".to_string(), EffectTemplate {
        name: "Bomb".to_string(),
        duration: 1.5,
        particle_count: 50,
        color_scheme: ColorScheme {
            primary: Color::srgb(1.0, 0.3, 0.1),
            secondary: Color::srgb(1.0, 0.8, 0.2),
            accent: Color::srgb(0.8, 0.1, 0.0),
            trail: Color::srgb(0.5, 0.3, 0.1),
        },
        animation_type: AnimationType::Burst { radius: 3.0, speed: 8.0 },
        sound_effect: Some("explosion.ogg".to_string()),
        screen_shake: 0.8,
        glow_intensity: 2.0,
    });
    
    effects.insert("Lightning".to_string(), EffectTemplate {
        name: "Lightning".to_string(),
        duration: 0.8,
        particle_count: 25,
        color_scheme: ColorScheme {
            primary: Color::srgb(0.8, 0.9, 1.0),
            secondary: Color::srgb(0.4, 0.6, 1.0),
            accent: Color::srgb(1.0, 1.0, 1.0),
            trail: Color::srgb(0.6, 0.8, 1.0),
        },
        animation_type: AnimationType::Lightning { branches: 3, chaos: 0.5 },
        sound_effect: Some("lightning.ogg".to_string()),
        screen_shake: 0.4,
        glow_intensity: 1.5,
    });
    
    effects.insert("Teleport".to_string(), EffectTemplate {
        name: "Teleport".to_string(),
        duration: 1.0,
        particle_count: 30,
        color_scheme: ColorScheme {
            primary: Color::srgb(0.6, 0.2, 0.8),
            secondary: Color::srgb(0.8, 0.4, 1.0),
            accent: Color::srgb(1.0, 0.6, 1.0),
            trail: Color::srgb(0.4, 0.1, 0.6),
        },
        animation_type: AnimationType::Teleport { fade_duration: 0.3 },
        sound_effect: Some("teleport.ogg".to_string()),
        screen_shake: 0.2,
        glow_intensity: 1.2,
    });
    
    effects.insert("Shield".to_string(), EffectTemplate {
        name: "Shield".to_string(),
        duration: 2.0,
        particle_count: 20,
        color_scheme: ColorScheme {
            primary: Color::srgb(0.2, 0.6, 1.0),
            secondary: Color::srgb(0.4, 0.8, 1.0),
            accent: Color::srgb(0.6, 0.9, 1.0),
            trail: Color::srgb(0.1, 0.4, 0.8),
        },
        animation_type: AnimationType::Shield { thickness: 0.2, segments: 8 },
        sound_effect: Some("shield.ogg".to_string()),
        screen_shake: 0.0,
        glow_intensity: 0.8,
    });
    
    effects.insert("Heal".to_string(), EffectTemplate {
        name: "Heal".to_string(),
        duration: 1.5,
        particle_count: 35,
        color_scheme: ColorScheme {
            primary: Color::srgb(0.2, 1.0, 0.3),
            secondary: Color::srgb(0.4, 1.0, 0.6),
            accent: Color::srgb(0.6, 1.0, 0.8),
            trail: Color::srgb(0.1, 0.8, 0.2),
        },
        animation_type: AnimationType::Heal { rise_speed: 2.0, sparkles: 15 },
        sound_effect: Some("heal.ogg".to_string()),
        screen_shake: 0.0,
        glow_intensity: 1.0,
    });
    
    // Movement Power Effects
    effects.insert("Dash".to_string(), EffectTemplate {
        name: "Dash".to_string(),
        duration: 0.6,
        particle_count: 15,
        color_scheme: ColorScheme {
            primary: Color::srgb(1.0, 1.0, 0.2),
            secondary: Color::srgb(1.0, 0.8, 0.0),
            accent: Color::srgb(1.0, 1.0, 0.8),
            trail: Color::srgb(0.8, 0.6, 0.0),
        },
        animation_type: AnimationType::Beam { width: 0.5, length: 3.0 },
        sound_effect: Some("dash.ogg".to_string()),
        screen_shake: 0.1,
        glow_intensity: 0.6,
    });
    
    // Terrain Manipulation Effects
    effects.insert("RaiseColumn".to_string(), EffectTemplate {
        name: "RaiseColumn".to_string(),
        duration: 2.0,
        particle_count: 40,
        color_scheme: ColorScheme {
            primary: Color::srgb(0.6, 0.4, 0.2),
            secondary: Color::srgb(0.8, 0.6, 0.4),
            accent: Color::srgb(1.0, 0.8, 0.6),
            trail: Color::srgb(0.4, 0.2, 0.1),
        },
        animation_type: AnimationType::Spiral { rotations: 2.0, radius: 1.5 },
        sound_effect: Some("earth_rise.ogg".to_string()),
        screen_shake: 0.3,
        glow_intensity: 0.4,
    });
    
    effects
}

fn create_animation_presets() -> HashMap<String, AnimationPreset> {
    let mut presets = HashMap::new();
    
    presets.insert("PowerPickup".to_string(), AnimationPreset {
        name: "PowerPickup".to_string(),
        keyframes: vec![
            Keyframe {
                time: 0.0,
                position: Vec3::ZERO,
                scale: Vec3::ONE,
                rotation: 0.0,
                color: Color::WHITE,
                alpha: 1.0,
            },
            Keyframe {
                time: 0.3,
                position: Vec3::new(0.0, 0.5, 0.0),
                scale: Vec3::splat(1.2),
                rotation: 0.5,
                color: Color::YELLOW,
                alpha: 1.0,
            },
            Keyframe {
                time: 1.0,
                position: Vec3::new(0.0, 1.0, 0.0),
                scale: Vec3::ZERO,
                rotation: 2.0,
                color: Color::WHITE,
                alpha: 0.0,
            },
        ],
        easing: EasingType::EaseOut,
        loop_type: LoopType::None,
    });
    
    presets.insert("PieceCaptured".to_string(), AnimationPreset {
        name: "PieceCaptured".to_string(),
        keyframes: vec![
            Keyframe {
                time: 0.0,
                position: Vec3::ZERO,
                scale: Vec3::ONE,
                rotation: 0.0,
                color: Color::WHITE,
                alpha: 1.0,
            },
            Keyframe {
                time: 0.2,
                position: Vec3::ZERO,
                scale: Vec3::splat(1.3),
                rotation: 0.0,
                color: Color::srgb(1.0, 0.3, 0.3),
                alpha: 0.8,
            },
            Keyframe {
                time: 0.8,
                position: Vec3::ZERO,
                scale: Vec3::splat(0.1),
                rotation: 3.14,
                color: Color::srgb(0.5, 0.1, 0.1),
                alpha: 0.0,
            },
        ],
        easing: EasingType::EaseInOut,
        loop_type: LoopType::None,
    });
    
    presets
}

/// Spawn enhanced power effect with professional animations
pub fn spawn_power_effect(
    mut commands: Commands,
    mut effects_manager: ResMut<VisualEffectsManager>,
    asset_server: Res<AssetServer>,
    power_type: &str,
    position: Vec3,
    target: Option<Vec3>,
    intensity: f32,
) {
    if let Some(template) = effects_manager.effect_templates.get(power_type).cloned() {
        let particle_count = match effects_manager.quality_level {
            VisualQuality::Ultra => template.particle_count,
            VisualQuality::High => (template.particle_count as f32 * 0.8) as usize,
            VisualQuality::Medium => (template.particle_count as f32 * 0.6) as usize,
            VisualQuality::Low => (template.particle_count as f32 * 0.4) as usize,
            VisualQuality::Potato => (template.particle_count as f32 * 0.2) as usize,
        };
        
        let mut particles = Vec::new();
        
        // Spawn particles based on animation type
        match &template.animation_type {
            AnimationType::Burst { radius, speed } => {
                particles = spawn_burst_particles(&mut commands, position, *radius, *speed, 
                                                particle_count, &template.color_scheme);
            },
            AnimationType::Lightning { branches, chaos } => {
                particles = spawn_lightning_particles(&mut commands, position, target.unwrap_or(position), 
                                                    *branches, *chaos, &template.color_scheme);
            },
            AnimationType::Teleport { fade_duration } => {
                particles = spawn_teleport_particles(&mut commands, position, *fade_duration, 
                                                   particle_count, &template.color_scheme);
            },
            AnimationType::Shield { thickness, segments } => {
                particles = spawn_shield_particles(&mut commands, position, *thickness, *segments, 
                                                 &template.color_scheme);
            },
            AnimationType::Heal { rise_speed, sparkles } => {
                particles = spawn_heal_particles(&mut commands, position, *rise_speed, *sparkles, 
                                                &template.color_scheme);
            },
            AnimationType::Beam { width, length } => {
                particles = spawn_beam_particles(&mut commands, position, target.unwrap_or(position), 
                                                *width, *length, &template.color_scheme);
            },
            AnimationType::Spiral { rotations, radius } => {
                particles = spawn_spiral_particles(&mut commands, position, *rotations, *radius, 
                                                  particle_count, &template.color_scheme);
            },
            AnimationType::Pulse { frequency, amplitude } => {
                particles = spawn_pulse_particles(&mut commands, position, *frequency, *amplitude, 
                                                 particle_count, &template.color_scheme);
            },
        }
        
        // Add screen shake if intensity warrants it
        if template.screen_shake > 0.0 && intensity > 0.5 {
            commands.spawn(ScreenShake {
                intensity: template.screen_shake * intensity,
                duration: template.duration * 0.3,
                frequency: 15.0,
                decay: 0.9,
            });
        }
        
        // Add glow effect
        if template.glow_intensity > 0.0 {
            commands.spawn((
                TransformBundle::from_transform(Transform::from_translation(position)),
                GlowEffect {
                    intensity: template.glow_intensity * intensity,
                    radius: 2.0,
                    color: template.color_scheme.primary,
                    pulse_speed: 2.0,
                },
            ));
        }
        
        // Store active effect
        effects_manager.active_effects.push(ActiveEffect {
            template,
            start_time: 0.0, // Will be set by time system
            position,
            target,
            intensity,
            particles,
        });
    }
}

fn spawn_burst_particles(
    commands: &mut Commands,
    position: Vec3,
    radius: f32,
    speed: f32,
    count: usize,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    
    for i in 0..count {
        let angle = (i as f32 / count as f32) * std::f32::consts::TAU;
        let direction = Vec3::new(angle.cos(), angle.sin(), 0.0);
        let velocity = direction * speed * (0.8 + 0.4 * (i as f32 / count as f32));
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(position),
                sprite: Sprite {
                    color: if i % 3 == 0 { colors.primary } else if i % 3 == 1 { colors.secondary } else { colors.accent },
                    custom_size: Some(Vec2::new(0.2, 0.2)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity,
                acceleration: Vec3::new(0.0, -2.0, 0.0),
                lifetime: 0.0,
                max_lifetime: 1.0 + (i as f32 / count as f32) * 0.5,
                size: 0.2 + (i as f32 / count as f32) * 0.1,
                color: colors.primary,
                fade_curve: FadeCurve::FadeOut,
                physics: ParticlePhysics {
                    gravity: 0.5,
                    drag: 0.95,
                    bounce: 0.3,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_lightning_particles(
    commands: &mut Commands,
    start: Vec3,
    end: Vec3,
    branches: usize,
    chaos: f32,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    let direction = (end - start).normalize();
    let distance = start.distance(end);
    
    // Main lightning bolt
    for i in 0..10 {
        let t = i as f32 / 9.0;
        let pos = start + direction * distance * t;
        let offset = Vec3::new(
            (rand::random::<f32>() - 0.5) * chaos,
            (rand::random::<f32>() - 0.5) * chaos,
            0.0,
        );
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(pos + offset),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(0.3, 0.1)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::ZERO,
                acceleration: Vec3::ZERO,
                lifetime: 0.0,
                max_lifetime: 0.2,
                size: 0.3,
                color: colors.primary,
                fade_curve: FadeCurve::FadeOut,
                physics: ParticlePhysics {
                    gravity: 0.0,
                    drag: 1.0,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_teleport_particles(
    commands: &mut Commands,
    position: Vec3,
    fade_duration: f32,
    count: usize,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    
    for i in 0..count {
        let height = (i as f32 / count as f32) * 2.0;
        let angle = (i as f32 * 137.5).to_radians(); // Golden angle for spiral
        let radius = 0.5 + height * 0.3;
        
        let pos = position + Vec3::new(
            angle.cos() * radius,
            height,
            angle.sin() * radius,
        );
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(pos),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(0.15, 0.15)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::new(0.0, 1.0, 0.0),
                acceleration: Vec3::ZERO,
                lifetime: 0.0,
                max_lifetime: fade_duration + (i as f32 / count as f32) * 0.3,
                size: 0.15,
                color: colors.primary,
                fade_curve: FadeCurve::FadeInOut,
                physics: ParticlePhysics {
                    gravity: 0.0,
                    drag: 0.98,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_shield_particles(
    commands: &mut Commands,
    position: Vec3,
    thickness: f32,
    segments: usize,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    
    for i in 0..segments {
        let angle = (i as f32 / segments as f32) * std::f32::consts::TAU;
        let radius = 1.5;
        let pos = position + Vec3::new(angle.cos() * radius, angle.sin() * radius, 0.0);
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(pos),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(thickness, thickness * 2.0)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::ZERO,
                acceleration: Vec3::ZERO,
                lifetime: 0.0,
                max_lifetime: 2.0,
                size: thickness,
                color: colors.primary,
                fade_curve: FadeCurve::Pulse,
                physics: ParticlePhysics {
                    gravity: 0.0,
                    drag: 1.0,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_heal_particles(
    commands: &mut Commands,
    position: Vec3,
    rise_speed: f32,
    sparkles: usize,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    
    for i in 0..sparkles {
        let offset = Vec3::new(
            (rand::random::<f32>() - 0.5) * 2.0,
            (rand::random::<f32>() - 0.5) * 0.5,
            (rand::random::<f32>() - 0.5) * 2.0,
        );
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(position + offset),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(0.1, 0.1)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::new(0.0, rise_speed, 0.0),
                acceleration: Vec3::new(0.0, 0.5, 0.0),
                lifetime: 0.0,
                max_lifetime: 1.5,
                size: 0.1,
                color: colors.primary,
                fade_curve: FadeCurve::FadeInOut,
                physics: ParticlePhysics {
                    gravity: -0.1,
                    drag: 0.95,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_beam_particles(
    commands: &mut Commands,
    start: Vec3,
    end: Vec3,
    width: f32,
    length: f32,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    let direction = (end - start).normalize();
    let segments = (start.distance(end) / 0.5) as usize;
    
    for i in 0..segments {
        let t = i as f32 / segments as f32;
        let pos = start + direction * start.distance(end) * t;
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(pos),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(width, 0.3)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::ZERO,
                acceleration: Vec3::ZERO,
                lifetime: 0.0,
                max_lifetime: 0.6,
                size: width,
                color: colors.primary,
                fade_curve: FadeCurve::FadeOut,
                physics: ParticlePhysics {
                    gravity: 0.0,
                    drag: 1.0,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_spiral_particles(
    commands: &mut Commands,
    position: Vec3,
    rotations: f32,
    radius: f32,
    count: usize,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    
    for i in 0..count {
        let t = i as f32 / count as f32;
        let angle = t * rotations * std::f32::consts::TAU;
        let height = t * 2.0;
        let current_radius = radius * (1.0 - t * 0.5);
        
        let pos = position + Vec3::new(
            angle.cos() * current_radius,
            height,
            angle.sin() * current_radius,
        );
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(pos),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(0.2, 0.2)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::new(0.0, 1.0, 0.0),
                acceleration: Vec3::ZERO,
                lifetime: 0.0,
                max_lifetime: 2.0,
                size: 0.2,
                color: colors.primary,
                fade_curve: FadeCurve::FadeInOut,
                physics: ParticlePhysics {
                    gravity: 0.0,
                    drag: 0.98,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

fn spawn_pulse_particles(
    commands: &mut Commands,
    position: Vec3,
    frequency: f32,
    amplitude: f32,
    count: usize,
    colors: &ColorScheme,
) -> Vec<Entity> {
    let mut particles = Vec::new();
    
    for i in 0..count {
        let angle = (i as f32 / count as f32) * std::f32::consts::TAU;
        let pos = position + Vec3::new(angle.cos() * amplitude, angle.sin() * amplitude, 0.0);
        
        let entity = commands.spawn((
            SpriteBundle {
                transform: Transform::from_translation(pos),
                sprite: Sprite {
                    color: colors.primary,
                    custom_size: Some(Vec2::new(0.3, 0.3)),
                    ..default()
                },
                ..default()
            },
            EnhancedParticle {
                velocity: Vec3::ZERO,
                acceleration: Vec3::ZERO,
                lifetime: 0.0,
                max_lifetime: 1.0 / frequency,
                size: 0.3,
                color: colors.primary,
                fade_curve: FadeCurve::Pulse,
                physics: ParticlePhysics {
                    gravity: 0.0,
                    drag: 1.0,
                    bounce: 0.0,
                    collision: false,
                },
            },
        )).id();
        
        particles.push(entity);
    }
    
    particles
}

/// Update particle systems with enhanced physics and animations
pub fn update_enhanced_particles(
    mut commands: Commands,
    mut particles: Query<(Entity, &mut Transform, &mut Sprite, &mut EnhancedParticle)>,
    time: Res<Time>,
) {
    let dt = time.delta_seconds();
    
    for (entity, mut transform, mut sprite, mut particle) in particles.iter_mut() {
        particle.lifetime += dt;
        
        // Remove expired particles
        if particle.lifetime >= particle.max_lifetime {
            commands.entity(entity).despawn();
            continue;
        }
        
        // Update physics
        particle.velocity += particle.acceleration * dt;
        particle.velocity.y -= particle.physics.gravity * dt;
        particle.velocity *= particle.physics.drag;
        
        transform.translation += particle.velocity * dt;
        
        // Update size and alpha based on fade curve
        let life_progress = particle.lifetime / particle.max_lifetime;
        let alpha = match particle.fade_curve {
            FadeCurve::Linear => 1.0 - life_progress,
            FadeCurve::FadeIn => life_progress,
            FadeCurve::FadeOut => 1.0 - life_progress,
            FadeCurve::FadeInOut => {
                if life_progress < 0.5 {
                    life_progress * 2.0
                } else {
                    (1.0 - life_progress) * 2.0
                }
            },
            FadeCurve::Pulse => (life_progress * std::f32::consts::TAU * 3.0).sin().abs(),
        };
        
        sprite.color.set_alpha(alpha);
        
        // Update size
        let size_scale = 1.0 + (1.0 - life_progress) * 0.5;
        transform.scale = Vec3::splat(size_scale);
    }
}

/// Apply screen shake effect
pub fn apply_screen_shake(
    mut camera_query: Query<&mut Transform, With<Camera>>,
    mut shake_query: Query<(Entity, &mut ScreenShake)>,
    mut commands: Commands,
    time: Res<Time>,
) {
    let dt = time.delta_seconds();
    
    let mut total_shake = Vec3::ZERO;
    
    for (entity, mut shake) in shake_query.iter_mut() {
        shake.duration -= dt;
        
        if shake.duration <= 0.0 {
            commands.entity(entity).despawn();
            continue;
        }
        
        let shake_amount = shake.intensity * (shake.duration / 2.0).min(1.0);
        let shake_x = (time.elapsed_seconds() * shake.frequency).sin() * shake_amount;
        let shake_y = (time.elapsed_seconds() * shake.frequency * 1.3).cos() * shake_amount;
        
        total_shake += Vec3::new(shake_x, shake_y, 0.0);
        shake.intensity *= shake.decay;
    }
    
    // Apply shake to camera
    if let Ok(mut camera_transform) = camera_query.get_single_mut() {
        camera_transform.translation += total_shake;
    }
}

/// Update glow effects
pub fn update_glow_effects(
    mut glow_query: Query<(&mut GlowEffect, &mut Transform)>,
    time: Res<Time>,
) {
    for (mut glow, mut transform) in glow_query.iter_mut() {
        let pulse = (time.elapsed_seconds() * glow.pulse_speed).sin() * 0.5 + 0.5;
        let scale = glow.radius * (0.8 + pulse * 0.4);
        transform.scale = Vec3::splat(scale);
    }
}