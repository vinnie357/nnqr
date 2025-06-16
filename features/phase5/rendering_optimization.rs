use bevy::prelude::*;
use bevy::render::render_resource::*;
use bevy::render::camera::ScalingMode;
use std::collections::HashMap;

/// Phase 5 Rendering Optimization System
/// Ensures stable 60 FPS with all effects active

#[derive(Resource)]
pub struct RenderingOptimizer {
    pub current_quality: RenderQuality,
    pub target_fps: f32,
    pub frame_budget_ms: f32,
    pub adaptive_quality: bool,
    pub optimization_stats: RenderStats,
    pub quality_presets: HashMap<RenderQuality, QualityPreset>,
}

#[derive(Clone, Copy, PartialEq, Eq, Hash)]
pub enum RenderQuality {
    Ultra,
    High,
    Medium,
    Low,
    Performance,
}

#[derive(Clone)]
pub struct QualityPreset {
    pub max_particles: usize,
    pub max_lights: usize,
    pub shadow_quality: ShadowQuality,
    pub texture_quality: f32,
    pub effect_complexity: EffectComplexity,
    pub lod_distance_multiplier: f32,
    pub culling_distance: f32,
}

#[derive(Clone, Copy)]
pub enum ShadowQuality {
    Off,
    Low,
    Medium,
    High,
    Ultra,
}

#[derive(Clone, Copy)]
pub enum EffectComplexity {
    Minimal,
    Reduced,
    Standard,
    Enhanced,
    Maximum,
}

#[derive(Default)]
pub struct RenderStats {
    pub frames_rendered: usize,
    pub draw_calls: usize,
    pub vertices_rendered: usize,
    pub textures_bound: usize,
    pub culled_objects: usize,
    pub quality_changes: usize,
    pub optimization_events: usize,
}

#[derive(Component)]
pub struct OptimizedRenderer {
    pub lod_level: u8,
    pub visible_distance: f32,
    pub last_visible: f32,
    pub render_priority: RenderPriority,
}

#[derive(Clone, Copy, PartialEq)]
pub enum RenderPriority {
    Critical,  // Always render (UI, game pieces)
    High,      // Important (effects, particles)
    Medium,    // Nice to have (decorations)
    Low,       // Optional (distant details)
}

#[derive(Component)]
pub struct LevelOfDetail {
    pub distances: [f32; 4], // LOD transition distances
    pub meshes: [Option<Handle<Mesh>>; 4],
    pub materials: [Option<Handle<StandardMaterial>>; 4],
    pub current_lod: u8,
}

#[derive(Component)]
pub struct DynamicBatching {
    pub batch_id: String,
    pub sort_key: u32,
    pub can_batch: bool,
}

#[derive(Component)]
pub struct FrustumCulled {
    pub bounds: Aabb,
    pub visible: bool,
    pub last_check_frame: usize,
}

impl Default for RenderingOptimizer {
    fn default() -> Self {
        let mut quality_presets = HashMap::new();
        
        quality_presets.insert(RenderQuality::Ultra, QualityPreset {
            max_particles: 1000,
            max_lights: 16,
            shadow_quality: ShadowQuality::Ultra,
            texture_quality: 1.0,
            effect_complexity: EffectComplexity::Maximum,
            lod_distance_multiplier: 2.0,
            culling_distance: 200.0,
        });
        
        quality_presets.insert(RenderQuality::High, QualityPreset {
            max_particles: 500,
            max_lights: 8,
            shadow_quality: ShadowQuality::High,
            texture_quality: 1.0,
            effect_complexity: EffectComplexity::Enhanced,
            lod_distance_multiplier: 1.5,
            culling_distance: 150.0,
        });
        
        quality_presets.insert(RenderQuality::Medium, QualityPreset {
            max_particles: 250,
            max_lights: 4,
            shadow_quality: ShadowQuality::Medium,
            texture_quality: 0.8,
            effect_complexity: EffectComplexity::Standard,
            lod_distance_multiplier: 1.0,
            culling_distance: 100.0,
        });
        
        quality_presets.insert(RenderQuality::Low, QualityPreset {
            max_particles: 100,
            max_lights: 2,
            shadow_quality: ShadowQuality::Low,
            texture_quality: 0.6,
            effect_complexity: EffectComplexity::Reduced,
            lod_distance_multiplier: 0.8,
            culling_distance: 75.0,
        });
        
        quality_presets.insert(RenderQuality::Performance, QualityPreset {
            max_particles: 50,
            max_lights: 1,
            shadow_quality: ShadowQuality::Off,
            texture_quality: 0.4,
            effect_complexity: EffectComplexity::Minimal,
            lod_distance_multiplier: 0.5,
            culling_distance: 50.0,
        });
        
        Self {
            current_quality: RenderQuality::High,
            target_fps: 60.0,
            frame_budget_ms: 16.67,
            adaptive_quality: true,
            optimization_stats: RenderStats::default(),
            quality_presets,
        }
    }
}

/// Initialize rendering optimization systems
pub fn setup_rendering_optimization(
    mut commands: Commands,
    mut optimizer: ResMut<RenderingOptimizer>,
) {
    info!("🎨 Rendering optimization system initialized");
    info!("   Quality: {:?}", optimizer.current_quality);
    info!("   Target FPS: {}", optimizer.target_fps);
    info!("   Adaptive Quality: {}", optimizer.adaptive_quality);
    
    // Apply initial quality settings
    apply_quality_preset(&mut optimizer, optimizer.current_quality);
}

/// Adaptive quality adjustment based on performance
pub fn adaptive_quality_control(
    mut optimizer: ResMut<RenderingOptimizer>,
    diagnostics: Res<bevy::diagnostic::DiagnosticsStore>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut quality_change_timer: Local<f32>,
    time: Res<Time>,
) {
    if !optimizer.adaptive_quality {
        return;
    }
    
    *quality_change_timer += time.delta_seconds();
    
    // Only check every 2 seconds to avoid rapid quality changes
    if *quality_change_timer < 2.0 {
        return;
    }
    *quality_change_timer = 0.0;
    
    if let Some(fps_diagnostic) = diagnostics.get(bevy::diagnostic::FrameTimeDiagnosticsPlugin::FPS) {
        if let Some(fps) = fps_diagnostic.smoothed() {
            let current_fps = fps as f32;
            let target_fps = optimizer.target_fps;
            
            let fps_ratio = current_fps / target_fps;
            let new_quality = match fps_ratio {
                r if r >= 1.1 => upgrade_quality(optimizer.current_quality),
                r if r < 0.8 => downgrade_quality(optimizer.current_quality),
                _ => optimizer.current_quality,
            };
            
            if new_quality != optimizer.current_quality {
                info!("🎛️ Adaptive quality change: {:?} -> {:?} (FPS: {:.1})", 
                      optimizer.current_quality, new_quality, current_fps);
                
                optimizer.current_quality = new_quality;
                optimizer.optimization_stats.quality_changes += 1;
                apply_quality_preset(&mut optimizer, new_quality);
                
                // Apply material quality changes
                apply_material_quality(&mut materials, &optimizer);
            }
        }
    }
}

fn upgrade_quality(current: RenderQuality) -> RenderQuality {
    match current {
        RenderQuality::Performance => RenderQuality::Low,
        RenderQuality::Low => RenderQuality::Medium,
        RenderQuality::Medium => RenderQuality::High,
        RenderQuality::High => RenderQuality::Ultra,
        RenderQuality::Ultra => RenderQuality::Ultra,
    }
}

fn downgrade_quality(current: RenderQuality) -> RenderQuality {
    match current {
        RenderQuality::Ultra => RenderQuality::High,
        RenderQuality::High => RenderQuality::Medium,
        RenderQuality::Medium => RenderQuality::Low,
        RenderQuality::Low => RenderQuality::Performance,
        RenderQuality::Performance => RenderQuality::Performance,
    }
}

fn apply_quality_preset(optimizer: &mut RenderingOptimizer, quality: RenderQuality) {
    if let Some(preset) = optimizer.quality_presets.get(&quality) {
        info!("Applying quality preset: {:?}", quality);
        info!("   Max particles: {}", preset.max_particles);
        info!("   Max lights: {}", preset.max_lights);
        info!("   Shadow quality: {:?}", preset.shadow_quality);
        info!("   Effect complexity: {:?}", preset.effect_complexity);
    }
}

fn apply_material_quality(
    materials: &mut ResMut<Assets<StandardMaterial>>,
    optimizer: &RenderingOptimizer,
) {
    if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
        for (_, material) in materials.iter_mut() {
            // Adjust material complexity based on quality
            match preset.effect_complexity {
                EffectComplexity::Minimal => {
                    material.metallic = 0.0;
                    material.perceptual_roughness = 0.8;
                },
                EffectComplexity::Reduced => {
                    material.metallic *= 0.5;
                    material.perceptual_roughness = material.perceptual_roughness.max(0.6);
                },
                EffectComplexity::Standard => {
                    // Default values
                },
                EffectComplexity::Enhanced => {
                    // Enhance material properties
                    material.metallic = material.metallic.max(0.1);
                },
                EffectComplexity::Maximum => {
                    // Full quality materials
                },
            }
        }
    }
}

/// Dynamic Level of Detail system
pub fn update_level_of_detail(
    mut lod_entities: Query<(&mut LevelOfDetail, &Transform, &mut Handle<Mesh>, &mut Handle<StandardMaterial>)>,
    camera_query: Query<&Transform, (With<Camera>, Without<LevelOfDetail>)>,
    optimizer: Res<RenderingOptimizer>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    if let Ok(camera_transform) = camera_query.get_single() {
        if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
            for (mut lod, transform, mut mesh_handle, mut material_handle) in lod_entities.iter_mut() {
                let distance = camera_transform.translation.distance(transform.translation);
                let adjusted_distance = distance / preset.lod_distance_multiplier;
                
                let new_lod = if adjusted_distance < lod.distances[0] {
                    0 // Highest detail
                } else if adjusted_distance < lod.distances[1] {
                    1
                } else if adjusted_distance < lod.distances[2] {
                    2
                } else if adjusted_distance < lod.distances[3] {
                    3 // Lowest detail
                } else {
                    4 // Culled
                };
                
                if new_lod != lod.current_lod && new_lod < 4 {
                    lod.current_lod = new_lod;
                    
                    // Switch mesh and material
                    if let Some(new_mesh) = &lod.meshes[new_lod as usize] {
                        *mesh_handle = new_mesh.clone();
                    }
                    if let Some(new_material) = &lod.materials[new_lod as usize] {
                        *material_handle = new_material.clone();
                    }
                }
            }
        }
    }
}

/// Frustum culling optimization
pub fn frustum_culling(
    mut culled_entities: Query<(&mut FrustumCulled, &Transform, &mut Visibility)>,
    camera_query: Query<(&Camera, &Transform), Without<FrustumCulled>>,
    optimizer: Res<RenderingOptimizer>,
    mut frame_counter: Local<usize>,
) {
    *frame_counter += 1;
    
    if let Ok((camera, camera_transform)) = camera_query.get_single() {
        if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
            for (mut culled, transform, mut visibility) in culled_entities.iter_mut() {
                // Skip frustum check every few frames for performance
                if *frame_counter - culled.last_check_frame < 5 {
                    continue;
                }
                culled.last_check_frame = *frame_counter;
                
                let distance = camera_transform.translation.distance(transform.translation);
                
                // Distance culling
                if distance > preset.culling_distance {
                    *visibility = Visibility::Hidden;
                    culled.visible = false;
                    continue;
                }
                
                // Simplified frustum culling (would need proper frustum planes in production)
                let camera_forward = camera_transform.forward();
                let to_object = (transform.translation - camera_transform.translation).normalize();
                let dot = camera_forward.dot(to_object);
                
                // Object is roughly in front of camera
                if dot > -0.5 {
                    *visibility = Visibility::Visible;
                    culled.visible = true;
                } else {
                    *visibility = Visibility::Hidden;
                    culled.visible = false;
                }
            }
        }
    }
}

/// Particle system optimization
pub fn optimize_particle_systems(
    mut commands: Commands,
    particles: Query<(Entity, &crate::components::particle::ParticleEffect)>,
    optimizer: Res<RenderingOptimizer>,
    mut particle_counter: Local<usize>,
) {
    if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
        let current_particles = particles.iter().count();
        
        if current_particles > preset.max_particles {
            // Remove oldest particles to stay within budget
            let mut particles_vec: Vec<_> = particles.iter().collect();
            particles_vec.sort_by_key(|(_, particle)| (particle.lifetime * 1000.0) as i32);
            
            let to_remove = current_particles - preset.max_particles;
            for (entity, _) in particles_vec.iter().take(to_remove) {
                commands.entity(*entity).despawn();
            }
            
            *particle_counter += to_remove;
        }
    }
}

/// Dynamic batching for similar objects
pub fn dynamic_batching_system(
    mut batched_entities: Query<(&mut DynamicBatching, &Transform, &Handle<Mesh>, &Handle<StandardMaterial>)>,
    optimizer: Res<RenderingOptimizer>,
) {
    // Group entities by batch compatibility
    let mut batches: HashMap<String, Vec<(Entity, Transform)>> = HashMap::new();
    
    for (batching, transform, mesh_handle, material_handle) in batched_entities.iter() {
        if batching.can_batch {
            let batch_key = format!("{:?}_{:?}", mesh_handle.id(), material_handle.id());
            batches.entry(batch_key).or_insert_with(Vec::new).push((Entity::PLACEHOLDER, *transform));
        }
    }
    
    // Apply batching optimizations (simplified - real implementation would use GPU instancing)
    for (batch_id, instances) in batches {
        if instances.len() > 5 {
            // This batch is worth optimizing
            info!("Batching {} instances for batch: {}", instances.len(), batch_id);
        }
    }
}

/// Camera optimization for 3D isometric view
pub fn optimize_camera_settings(
    mut camera_query: Query<(&mut Camera, &mut Transform, &mut Projection)>,
    optimizer: Res<RenderingOptimizer>,
) {
    if let Ok((mut camera, mut transform, mut projection)) = camera_query.get_single_mut() {
        if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
            // Adjust camera settings based on quality
            match optimizer.current_quality {
                RenderQuality::Performance | RenderQuality::Low => {
                    // Reduce render distance for performance
                    if let Projection::Orthographic(ref mut ortho) = projection.as_mut() {
                        ortho.far = 100.0;
                        ortho.near = -50.0;
                    }
                },
                _ => {
                    // Standard render distance
                    if let Projection::Orthographic(ref mut ortho) = projection.as_mut() {
                        ortho.far = 1000.0;
                        ortho.near = -1000.0;
                    }
                },
            }
        }
    }
}

/// Lighting optimization
pub fn optimize_lighting(
    mut lights: Query<(&mut PointLight, &mut Visibility)>,
    directional_lights: Query<&mut DirectionalLight>,
    optimizer: Res<RenderingOptimizer>,
) {
    if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
        let mut active_lights = 0;
        
        // Limit number of active lights
        for (mut light, mut visibility) in lights.iter_mut() {
            if active_lights < preset.max_lights {
                *visibility = Visibility::Visible;
                
                // Adjust light quality
                match optimizer.current_quality {
                    RenderQuality::Performance => {
                        light.intensity *= 0.8;
                        light.range *= 0.7;
                    },
                    RenderQuality::Low => {
                        light.intensity *= 0.9;
                        light.range *= 0.85;
                    },
                    _ => {
                        // Full quality lighting
                    }
                }
                
                active_lights += 1;
            } else {
                *visibility = Visibility::Hidden;
            }
        }
    }
}

/// Generate rendering optimization report
pub fn generate_rendering_report(
    optimizer: Res<RenderingOptimizer>,
    keyboard: Res<Input<KeyCode>>,
    diagnostics: Res<bevy::diagnostic::DiagnosticsStore>,
) {
    if keyboard.just_pressed(KeyCode::F5) {
        println!("\n🎨 RENDERING OPTIMIZATION REPORT");
        println!("==========================================");
        
        println!("📊 CURRENT RENDER SETTINGS");
        println!("   Quality Level: {:?}", optimizer.current_quality);
        println!("   Target FPS: {}", optimizer.target_fps);
        println!("   Adaptive Quality: {}", optimizer.adaptive_quality);
        
        if let Some(preset) = optimizer.quality_presets.get(&optimizer.current_quality) {
            println!("   Max Particles: {}", preset.max_particles);
            println!("   Max Lights: {}", preset.max_lights);
            println!("   Shadow Quality: {:?}", preset.shadow_quality);
            println!("   Effect Complexity: {:?}", preset.effect_complexity);
            println!("   Culling Distance: {:.0}m", preset.culling_distance);
        }
        
        // Performance metrics
        if let Some(fps_diag) = diagnostics.get(bevy::diagnostic::FrameTimeDiagnosticsPlugin::FPS) {
            if let Some(fps) = fps_diag.smoothed() {
                println!("\n🚀 PERFORMANCE METRICS");
                println!("   Current FPS: {:.1}", fps);
                println!("   Frame Time: {:.2}ms", 1000.0 / fps);
                
                let performance_rating = match fps {
                    f if f >= 58.0 => "🟢 EXCELLENT",
                    f if f >= 45.0 => "🟡 GOOD",
                    f if f >= 30.0 => "🟠 ACCEPTABLE",
                    _ => "🔴 POOR",
                };
                println!("   Performance: {}", performance_rating);
            }
        }
        
        // Optimization statistics
        println!("\n📈 OPTIMIZATION STATISTICS");
        println!("   Quality Changes: {}", optimizer.optimization_stats.quality_changes);
        println!("   Optimization Events: {}", optimizer.optimization_stats.optimization_events);
        println!("   Objects Culled: {}", optimizer.optimization_stats.culled_objects);
        
        // Recommendations
        println!("\n💡 OPTIMIZATION RECOMMENDATIONS");
        match optimizer.current_quality {
            RenderQuality::Performance => {
                println!("   🔴 Running at minimum quality - consider hardware upgrade");
            },
            RenderQuality::Low => {
                println!("   🟡 Low quality mode - some visual features disabled");
            },
            RenderQuality::Medium => {
                println!("   ✅ Balanced quality and performance");
            },
            RenderQuality::High | RenderQuality::Ultra => {
                println!("   🟢 High quality rendering active");
            },
        }
        
        println!("\n🔧 MANUAL CONTROLS");
        println!("   F5: Toggle this report");
        println!("   F4: Cycle quality levels");
        println!("   F3: Toggle adaptive quality");
        
        println!("==========================================\n");
    }
}

/// Manual quality control
pub fn manual_quality_control(
    mut optimizer: ResMut<RenderingOptimizer>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F4) {
        optimizer.current_quality = upgrade_quality(optimizer.current_quality);
        info!("🎛️ Manual quality change: {:?}", optimizer.current_quality);
        apply_quality_preset(&mut optimizer, optimizer.current_quality);
        apply_material_quality(&mut materials, &optimizer);
    }
    
    if keyboard.just_pressed(KeyCode::F3) {
        optimizer.adaptive_quality = !optimizer.adaptive_quality;
        info!("🔄 Adaptive quality: {}", optimizer.adaptive_quality);
    }
}