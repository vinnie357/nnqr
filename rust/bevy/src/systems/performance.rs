use crate::components::*;
use bevy::diagnostic::{DiagnosticsStore, FrameTimeDiagnosticsPlugin};
use bevy::prelude::*;
use std::collections::VecDeque;

// Performance monitoring and optimization system
#[derive(Resource)]
pub struct PerformanceMonitor {
    pub frame_times: VecDeque<f32>,
    pub entity_counts: VecDeque<usize>,
    pub system_times: std::collections::HashMap<String, f32>,
    pub performance_warnings: Vec<String>,
    pub max_samples: usize,
    pub target_fps: f32,
}

impl Default for PerformanceMonitor {
    fn default() -> Self {
        Self {
            frame_times: VecDeque::with_capacity(120), // 2 seconds at 60fps
            entity_counts: VecDeque::with_capacity(120),
            system_times: std::collections::HashMap::new(),
            performance_warnings: Vec::new(),
            max_samples: 120,
            target_fps: 60.0,
        }
    }
}

#[derive(Component)]
pub struct PerformanceOptimized;

#[derive(Component)]
pub struct EntityPool {
    pub pool_type: PoolType,
    pub available: Vec<Entity>,
    pub in_use: Vec<Entity>,
}

#[derive(Clone, PartialEq)]
pub enum PoolType {
    PowerOrbs,
    VisualEffects,
    UIElements,
    Particles,
}

// Monitor frame rate and entity count
pub fn monitor_performance(
    mut monitor: ResMut<PerformanceMonitor>,
    diagnostics: Res<DiagnosticsStore>,
    // world: &World,  // Removed to avoid parameter conflict
    _time: Res<Time>,
) {
    // Track frame times
    if let Some(fps_diagnostic) = diagnostics.get(FrameTimeDiagnosticsPlugin::FPS) {
        if let Some(fps) = fps_diagnostic.smoothed() {
            let frame_time = 1.0 / fps as f32;

            monitor.frame_times.push_back(frame_time);
            if monitor.frame_times.len() > monitor.max_samples {
                monitor.frame_times.pop_front();
            }

            // Check for performance issues
            if fps < monitor.target_fps as f64 * 0.8 {
                let warning = format!("Low FPS detected: {:.1} fps", fps);
                if !monitor.performance_warnings.contains(&warning) {
                    monitor.performance_warnings.push(warning);
                }
            }
        }
    }

    // Track entity count - simplified without world access
    // Note: Entity count tracking disabled for now to avoid parameter conflicts
    // TODO: Implement entity count tracking using queries instead
}

// Display performance statistics
pub fn display_performance_stats(
    monitor: Res<PerformanceMonitor>,
    keyboard: Res<Input<KeyCode>>,
    diagnostics: Res<DiagnosticsStore>,
) {
    if keyboard.just_pressed(KeyCode::F8) {
        println!("\n📊 PERFORMANCE STATISTICS");
        println!("====================================");

        // Current FPS
        if let Some(fps_diagnostic) = diagnostics.get(FrameTimeDiagnosticsPlugin::FPS) {
            if let Some(fps) = fps_diagnostic.smoothed() {
                println!("🎯 Current FPS: {:.1}", fps);

                let status = if fps >= monitor.target_fps as f64 * 0.9 {
                    "✅ EXCELLENT"
                } else if fps >= monitor.target_fps as f64 * 0.7 {
                    "⚠️  GOOD"
                } else if fps >= monitor.target_fps as f64 * 0.5 {
                    "❌ POOR"
                } else {
                    "🚨 CRITICAL"
                };
                println!("   Status: {}", status);
            }
        }

        // Entity statistics
        if let Some(&current_entities) = monitor.entity_counts.back() {
            println!("🎭 Entity Count: {}", current_entities);

            let avg_entities = monitor.entity_counts.iter().sum::<usize>() as f32
                / monitor.entity_counts.len() as f32;
            println!("   Average: {:.0} entities", avg_entities);

            if current_entities > 800 {
                println!("   ⚠️  High entity count - consider entity pooling");
            }
        }

        // Frame time statistics
        if !monitor.frame_times.is_empty() {
            let avg_frame_time =
                monitor.frame_times.iter().sum::<f32>() / monitor.frame_times.len() as f32;
            let min_frame_time = monitor
                .frame_times
                .iter()
                .cloned()
                .fold(f32::INFINITY, f32::min);
            let max_frame_time = monitor.frame_times.iter().cloned().fold(0.0, f32::max);

            println!("⏱️  Frame Times:");
            println!(
                "   Average: {:.2}ms ({:.1} fps)",
                avg_frame_time * 1000.0,
                1.0 / avg_frame_time
            );
            println!(
                "   Best: {:.2}ms ({:.1} fps)",
                min_frame_time * 1000.0,
                1.0 / min_frame_time
            );
            println!(
                "   Worst: {:.2}ms ({:.1} fps)",
                max_frame_time * 1000.0,
                1.0 / max_frame_time
            );
        }

        // Performance warnings
        if !monitor.performance_warnings.is_empty() {
            println!("\n⚠️  PERFORMANCE WARNINGS:");
            for warning in &monitor.performance_warnings {
                println!("   {}", warning);
            }
        }

        println!("\n💡 OPTIMIZATION TIPS:");
        println!("   - Use F9 for entity cleanup");
        println!("   - Use F10 for visual effect optimization");
        println!("   - Use F11 for query optimization report");
        println!("====================================\n");
    }
}

// Entity cleanup and optimization
pub fn cleanup_entities(
    mut commands: Commands,
    keyboard: Res<Input<KeyCode>>,
    mut monitor: ResMut<PerformanceMonitor>,
    // Cleanup various entity types
    old_particles: Query<
        Entity,
        (
            With<crate::systems::visual_effects::ParticleEffect>,
            With<PerformanceOptimized>,
        ),
    >,
    old_indicators: Query<
        Entity,
        (
            With<crate::systems::power_effects::PowerTargetIndicator>,
            With<PerformanceOptimized>,
        ),
    >,
    old_effects: Query<
        Entity,
        (
            With<crate::systems::power_effects::ActivePowerEffect>,
            With<PerformanceOptimized>,
        ),
    >,
) {
    if keyboard.just_pressed(KeyCode::F9) {
        println!("🧹 Performing entity cleanup...");

        let mut cleaned = 0;

        // Clean up old particles
        for entity in old_particles.iter() {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
                cleaned += 1;
            }
        }

        // Clean up old indicators
        for entity in old_indicators.iter() {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
                cleaned += 1;
            }
        }

        // Clean up old effects
        for entity in old_effects.iter() {
            if let Some(mut entity_commands) = commands.get_entity(entity) {
                entity_commands.despawn();
                cleaned += 1;
            }
        }

        // Clear performance warnings
        monitor.performance_warnings.clear();

        println!("✅ Cleaned up {} entities", cleaned);

        if cleaned > 0 {
            println!("   Performance should improve");
        } else {
            println!("   No entities needed cleanup");
        }
    }
}

// Optimize visual effects for performance
pub fn optimize_visual_effects(
    mut commands: Commands,
    keyboard: Res<Input<KeyCode>>,
    particles: Query<(Entity, &crate::systems::visual_effects::ParticleEffect)>,
    _monitor: ResMut<PerformanceMonitor>,
) {
    if keyboard.just_pressed(KeyCode::F10) {
        println!("✨ Optimizing visual effects...");

        let particle_count = particles.iter().count();
        println!("   Current particles: {}", particle_count);

        if particle_count > 50 {
            let mut removed = 0;

            // Remove oldest particles
            for (entity, particle) in particles.iter() {
                if particle.lifetime < particle.max_lifetime * 0.1 {
                    if let Some(mut entity_commands) = commands.get_entity(entity) {
                        entity_commands.despawn();
                        removed += 1;
                    }
                }

                if removed >= particle_count / 2 {
                    break;
                }
            }

            println!("   Removed {} old particles", removed);
        }

        // Add performance optimization marker
        for (entity, _) in particles.iter() {
            commands.entity(entity).insert(PerformanceOptimized);
        }

        println!("✅ Visual effects optimized");
    }
}

// System performance analysis
pub fn analyze_system_performance(keyboard: Res<Input<KeyCode>>, _monitor: Res<PerformanceMonitor>) {
    if keyboard.just_pressed(KeyCode::F11) {
        println!("\n🔍 SYSTEM PERFORMANCE ANALYSIS");
        println!("=====================================");

        println!("📋 QUERY OPTIMIZATION SUGGESTIONS:");
        println!("   1. Use ParamSet for conflicting queries");
        println!("   2. Add Without<T> filters to disjoint queries");
        println!("   3. Use Changed<T> filters to reduce work");
        println!("   4. Consider system ordering with .before()/.after()");

        println!("\n🎯 ENTITY OPTIMIZATION:");
        println!("   1. Implement entity pooling for frequent spawns");
        println!("   2. Use markers like PerformanceOptimized");
        println!("   3. Batch entity operations");
        println!("   4. Remove unused components");

        println!("\n⚡ VISUAL OPTIMIZATION:");
        println!("   1. Limit particle counts");
        println!("   2. Use object pooling for UI elements");
        println!("   3. Reduce sprite complexity");
        println!("   4. Optimize transform updates");

        println!("\n🔧 SYSTEM SCHEDULING:");
        println!("   1. Group related systems together");
        println!("   2. Use run conditions to skip unnecessary work");
        println!("   3. Consider fixed timestep for physics");
        println!("   4. Parallelize independent systems");

        println!("=====================================\n");
    }
}

// Auto-optimization based on performance
pub fn auto_optimize_performance(
    mut commands: Commands,
    monitor: Res<PerformanceMonitor>,
    diagnostics: Res<DiagnosticsStore>,
    particles: Query<Entity, With<crate::systems::visual_effects::ParticleEffect>>,
    orbs: Query<Entity, With<PowerOrb>>,
) {
    // Auto-optimize when FPS drops below threshold
    if let Some(fps_diagnostic) = diagnostics.get(FrameTimeDiagnosticsPlugin::FPS) {
        if let Some(fps) = fps_diagnostic.smoothed() {
            if fps < monitor.target_fps as f64 * 0.6 {
                // Emergency performance optimization

                // Limit particles
                let particle_count = particles.iter().count();
                if particle_count > 30 {
                    for (i, entity) in particles.iter().enumerate() {
                        if i >= 20 {
                            // Keep only 20 particles
                            if let Some(mut entity_commands) = commands.get_entity(entity) {
                                entity_commands.despawn();
                            }
                        }
                    }
                }

                // Limit power orbs if too many
                let orb_count = orbs.iter().count();
                if orb_count > 5 {
                    for (i, entity) in orbs.iter().enumerate() {
                        if i >= 3 {
                            // Keep only 3 orbs
                            if let Some(mut entity_commands) = commands.get_entity(entity) {
                                entity_commands.despawn();
                            }
                        }
                    }
                }
            }
        }
    }
}

// Entity pooling system for better performance
pub fn setup_entity_pools(mut commands: Commands) {
    // Create pools for frequently spawned entities
    commands.spawn(EntityPool {
        pool_type: PoolType::PowerOrbs,
        available: Vec::with_capacity(10),
        in_use: Vec::new(),
    });

    commands.spawn(EntityPool {
        pool_type: PoolType::VisualEffects,
        available: Vec::with_capacity(20),
        in_use: Vec::new(),
    });

    commands.spawn(EntityPool {
        pool_type: PoolType::Particles,
        available: Vec::with_capacity(50),
        in_use: Vec::new(),
    });
}

// Get entity from pool instead of spawning new
pub fn get_pooled_entity(
    pool_type: PoolType,
    pools: &mut Query<&mut EntityPool>,
    _commands: &mut Commands,
) -> Option<Entity> {
    for mut pool in pools.iter_mut() {
        if pool.pool_type == pool_type {
            if let Some(entity) = pool.available.pop() {
                pool.in_use.push(entity);
                return Some(entity);
            }
        }
    }
    None
}

// Return entity to pool instead of despawning
pub fn return_to_pool(entity: Entity, pool_type: PoolType, pools: &mut Query<&mut EntityPool>) {
    for mut pool in pools.iter_mut() {
        if pool.pool_type == pool_type {
            if let Some(pos) = pool.in_use.iter().position(|&e| e == entity) {
                pool.in_use.remove(pos);
                pool.available.push(entity);
                break;
            }
        }
    }
}

// Performance-aware power orb spawning
pub fn spawn_optimized_power_orb(
    commands: &mut Commands,
    power_type: PowerType,
    position: (u8, u8),
    pools: &mut Query<&mut EntityPool>,
) -> Entity {
    // Try to get from pool first
    if let Some(entity) = get_pooled_entity(PoolType::PowerOrbs, pools, commands) {
        // Reuse entity
        commands.entity(entity).insert((
            PowerOrb {
                power_type,
                board_position: position,
            },
            SpriteBundle {
                sprite: Sprite {
                    color: power_type.color(),
                    custom_size: Some(Vec2::new(25.0, 25.0)),
                    ..default()
                },
                transform: Transform::from_translation(Vec3::new(
                    position.0 as f32 * 75.0 - 262.5,
                    position.1 as f32 * 75.0 - 262.5,
                    1.0,
                )),
                ..default()
            },
            PerformanceOptimized,
        ));
        entity
    } else {
        // Create new entity if pool is empty
        commands
            .spawn((
                PowerOrb {
                    power_type,
                    board_position: position,
                },
                SpriteBundle {
                    sprite: Sprite {
                        color: power_type.color(),
                        custom_size: Some(Vec2::new(25.0, 25.0)),
                        ..default()
                    },
                    transform: Transform::from_translation(Vec3::new(
                        position.0 as f32 * 75.0 - 262.5,
                        position.1 as f32 * 75.0 - 262.5,
                        1.0,
                    )),
                    ..default()
                },
                PerformanceOptimized,
            ))
            .id()
    }
}
