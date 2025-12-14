use bevy::diagnostic::{DiagnosticsStore, FrameTimeDiagnosticsPlugin};
use bevy::prelude::*;
use std::collections::VecDeque;

/// Performance monitoring resource
#[derive(Resource)]
pub struct PerformanceMonitor {
    pub frame_times: VecDeque<f32>,
    pub target_fps: f32,
    pub performance_budget: f32,
    pub low_performance_threshold: f32,
    pub optimization_level: OptimizationLevel,
}

#[derive(Clone, Copy, PartialEq)]
pub enum OptimizationLevel {
    High,   // Full quality
    Medium, // Balanced
    Low,    // Performance priority
}

impl Default for PerformanceMonitor {
    fn default() -> Self {
        Self {
            frame_times: VecDeque::with_capacity(60),
            target_fps: 60.0,
            performance_budget: 16.67, // ~60fps in milliseconds
            low_performance_threshold: 30.0,
            optimization_level: OptimizationLevel::High,
        }
    }
}

/// Component for LOD (Level of Detail) management
#[derive(Component)]
pub struct LevelOfDetail {
    pub high_detail_distance: f32,
    pub medium_detail_distance: f32,
    pub low_detail_distance: f32,
    pub current_lod: u8,
}

/// System to monitor frame rate and adjust optimization level
pub fn monitor_performance(
    mut performance_monitor: ResMut<PerformanceMonitor>,
    diagnostics: Res<DiagnosticsStore>,
    _time: Res<Time>,
) {
    // Get current frame time from diagnostics
    if let Some(frame_time_diagnostic) = diagnostics.get(FrameTimeDiagnosticsPlugin::FRAME_TIME) {
        if let Some(frame_time) = frame_time_diagnostic.smoothed() {
            // Convert to milliseconds
            let frame_time_ms = frame_time * 1000.0;

            // Add to rolling average
            performance_monitor
                .frame_times
                .push_back(frame_time_ms as f32);
            if performance_monitor.frame_times.len() > 60 {
                performance_monitor.frame_times.pop_front();
            }

            // Calculate average frame time
            let avg_frame_time: f32 = performance_monitor.frame_times.iter().sum::<f32>()
                / performance_monitor.frame_times.len() as f32;

            // Adjust optimization level based on performance
            let current_fps = 1000.0 / avg_frame_time;

            performance_monitor.optimization_level = match current_fps {
                fps if fps >= 55.0 => OptimizationLevel::High,
                fps if fps >= 35.0 => OptimizationLevel::Medium,
                _ => OptimizationLevel::Low,
            };
        }
    }
}

/// System to apply LOD based on camera distance and performance level
pub fn update_level_of_detail(
    mut lod_query: Query<(&mut LevelOfDetail, &Transform, &mut Visibility)>,
    camera_query: Query<&Transform, (With<Camera>, Without<LevelOfDetail>)>,
    performance_monitor: Res<PerformanceMonitor>,
) {
    if let Ok(camera_transform) = camera_query.get_single() {
        for (mut lod, transform, mut visibility) in lod_query.iter_mut() {
            let distance = camera_transform.translation.distance(transform.translation);

            // Determine LOD level based on distance and performance
            let new_lod = match performance_monitor.optimization_level {
                OptimizationLevel::High => {
                    if distance < lod.high_detail_distance {
                        2
                    } else if distance < lod.medium_detail_distance {
                        1
                    } else {
                        0
                    }
                }
                OptimizationLevel::Medium => {
                    if distance < lod.medium_detail_distance {
                        1
                    } else {
                        0
                    }
                }
                OptimizationLevel::Low => 0,
            };

            // Apply visibility culling for very distant objects
            if distance > lod.low_detail_distance * 2.0 {
                *visibility = Visibility::Hidden;
            } else {
                *visibility = Visibility::Visible;
                lod.current_lod = new_lod;
            }
        }
    }
}

/// System to optimize visual effects based on performance
pub fn optimize_visual_effects(
    mut particle_query: Query<
        &mut Visibility,
        With<crate::systems::visual_effects::ParticleEffect>,
    >,
    mut glow_query: Query<&mut crate::systems::enhanced_visual_feedback::GlowEffect>,
    performance_monitor: Res<PerformanceMonitor>,
) {
    match performance_monitor.optimization_level {
        OptimizationLevel::Low => {
            // Disable non-essential particle effects
            for mut visibility in particle_query.iter_mut() {
                *visibility = Visibility::Hidden;
            }

            // Reduce glow intensity
            for mut glow in glow_query.iter_mut() {
                glow.glow_intensity *= 0.5;
            }
        }
        OptimizationLevel::Medium => {
            // Reduce some effects
            for mut glow in glow_query.iter_mut() {
                glow.glow_intensity *= 0.8;
            }
        }
        OptimizationLevel::High => {
            // Full quality - no changes needed
        }
    }
}

/// System to manage material complexity based on performance
pub fn optimize_materials(
    mut materials: ResMut<Assets<StandardMaterial>>,
    performance_monitor: Res<PerformanceMonitor>,
    mut optimized: Local<bool>,
) {
    let should_optimize = matches!(
        performance_monitor.optimization_level,
        OptimizationLevel::Low
    );

    if should_optimize && !*optimized {
        // Reduce material complexity for low performance
        for (_, material) in materials.iter_mut() {
            material.metallic *= 0.5;
            material.perceptual_roughness = material.perceptual_roughness.max(0.3);
        }
        *optimized = true;
    } else if !should_optimize && *optimized {
        // Restore full quality materials
        *optimized = false;
        // Note: Would need to store original values to restore properly
    }
}

/// Debug system to display performance information
pub fn display_performance_debug(
    performance_monitor: Res<PerformanceMonitor>,
    diagnostics: Res<DiagnosticsStore>,
    mut commands: Commands,
    debug_text_query: Query<Entity, With<PerformanceDebugText>>,
) {
    // Remove old debug text
    for entity in debug_text_query.iter() {
        commands.entity(entity).despawn();
    }

    // Get current FPS
    let fps = if let Some(fps_diagnostic) = diagnostics.get(FrameTimeDiagnosticsPlugin::FPS) {
        fps_diagnostic.smoothed().unwrap_or(0.0)
    } else {
        0.0
    };

    let optimization_level_text = match performance_monitor.optimization_level {
        OptimizationLevel::High => "High Quality",
        OptimizationLevel::Medium => "Balanced",
        OptimizationLevel::Low => "Performance Mode",
    };

    // Spawn new debug text
    commands.spawn((
        TextBundle::from_section(
            format!("FPS: {:.1} | Quality: {}", fps, optimization_level_text),
            TextStyle {
                font_size: 16.0,
                color: Color::WHITE,
                ..default()
            },
        )
        .with_style(Style {
            position_type: PositionType::Absolute,
            top: Val::Px(10.0),
            right: Val::Px(10.0),
            ..default()
        }),
        PerformanceDebugText,
    ));
}

#[derive(Component)]
pub struct PerformanceDebugText;

/// Initialize LOD for board tiles
pub fn setup_tile_lod(
    mut commands: Commands,
    tiles: Query<Entity, (With<crate::components::BoardTile>, Without<LevelOfDetail>)>,
) {
    for entity in tiles.iter() {
        commands.entity(entity).insert(LevelOfDetail {
            high_detail_distance: 20.0,
            medium_detail_distance: 40.0,
            low_detail_distance: 80.0,
            current_lod: 2,
        });
    }
}

/// Initialize LOD for pieces
pub fn setup_piece_lod(
    mut commands: Commands,
    pieces: Query<Entity, (With<crate::components::GamePiece>, Without<LevelOfDetail>)>,
) {
    for entity in pieces.iter() {
        commands.entity(entity).insert(LevelOfDetail {
            high_detail_distance: 25.0,
            medium_detail_distance: 50.0,
            low_detail_distance: 100.0,
            current_lod: 2,
        });
    }
}
