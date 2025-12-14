use bevy::prelude::*;
use std::collections::{HashMap, VecDeque};
use std::sync::atomic::{AtomicUsize, Ordering};

/// Phase 5 Memory Optimization System
/// Prevents memory leaks and optimizes memory usage for production

#[derive(Resource)]
pub struct MemoryProfiler {
    pub entity_counts: HashMap<String, usize>,
    pub component_counts: HashMap<String, usize>,
    pub memory_samples: VecDeque<MemorySample>,
    pub leak_detection: LeakDetector,
    pub optimization_stats: OptimizationStats,
    pub memory_budget: MemoryBudget,
}

#[derive(Clone)]
pub struct MemorySample {
    pub timestamp: f32,
    pub entity_count: usize,
    pub component_count: usize,
    pub estimated_memory_mb: f32,
    pub gc_events: usize,
    pub allocation_rate: f32,
}

#[derive(Default)]
pub struct LeakDetector {
    pub baseline_entities: usize,
    pub max_entities_seen: usize,
    pub persistent_growth_frames: usize,
    pub growth_threshold: usize,
    pub potential_leaks: Vec<LeakReport>,
}

#[derive(Clone)]
pub struct LeakReport {
    pub entity_type: String,
    pub count: usize,
    pub growth_rate: f32,
    pub first_detected: f32,
    pub severity: LeakSeverity,
}

#[derive(Clone, PartialEq)]
pub enum LeakSeverity {
    Low,      // Slow growth, might be normal
    Medium,   // Moderate growth, investigate
    High,     // Fast growth, likely leak
    Critical, // Rapid growth, immediate action needed
}

#[derive(Default)]
pub struct OptimizationStats {
    pub entities_pooled: usize,
    pub entities_despawned: usize,
    pub components_removed: usize,
    pub memory_freed_mb: f32,
    pub optimizations_performed: usize,
}

#[derive(Default)]
pub struct MemoryBudget {
    pub max_entities: usize,
    pub max_particles: usize,
    pub max_ui_elements: usize,
    pub max_effects: usize,
    pub max_memory_mb: f32,
    pub cleanup_threshold: f32,
}

// Entity tracking components
#[derive(Component)]
pub struct MemoryTracked {
    pub category: String,
    pub created_at: f32,
    pub size_estimate_bytes: usize,
}

#[derive(Component)]
pub struct PooledEntity {
    pub pool_id: String,
    pub last_used: f32,
    pub reuse_count: usize,
}

#[derive(Component)]
pub struct TemporaryEntity {
    pub lifetime: f32,
    pub max_lifetime: f32,
    pub auto_cleanup: bool,
}

#[derive(Component)]
pub struct MemoryIntensive;

// Memory pools for efficient entity reuse
#[derive(Resource)]
pub struct EntityPools {
    pub pools: HashMap<String, EntityPool>,
    pub stats: PoolingStats,
}

pub struct EntityPool {
    pub available: Vec<Entity>,
    pub in_use: Vec<Entity>,
    pub max_size: usize,
    pub total_created: usize,
    pub total_reused: usize,
}

#[derive(Default)]
pub struct PoolingStats {
    pub total_pools: usize,
    pub total_entities_pooled: usize,
    pub reuse_ratio: f32,
    pub memory_saved_mb: f32,
}

impl Default for MemoryProfiler {
    fn default() -> Self {
        Self {
            entity_counts: HashMap::new(),
            component_counts: HashMap::new(),
            memory_samples: VecDeque::with_capacity(300), // 5 minutes at 60fps
            leak_detection: LeakDetector::default(),
            optimization_stats: OptimizationStats::default(),
            memory_budget: MemoryBudget {
                max_entities: 2000,
                max_particles: 500,
                max_ui_elements: 200,
                max_effects: 100,
                max_memory_mb: 1024.0,
                cleanup_threshold: 0.8,
            },
        }
    }
}

impl Default for EntityPools {
    fn default() -> Self {
        let mut pools = HashMap::new();
        
        // Create default pools for common entity types
        pools.insert("particles".to_string(), EntityPool {
            available: Vec::with_capacity(200),
            in_use: Vec::new(),
            max_size: 200,
            total_created: 0,
            total_reused: 0,
        });
        
        pools.insert("ui_elements".to_string(), EntityPool {
            available: Vec::with_capacity(50),
            in_use: Vec::new(),
            max_size: 50,
            total_created: 0,
            total_reused: 0,
        });
        
        pools.insert("effects".to_string(), EntityPool {
            available: Vec::with_capacity(100),
            in_use: Vec::new(),
            max_size: 100,
            total_created: 0,
            total_reused: 0,
        });
        
        Self {
            pools,
            stats: PoolingStats::default(),
        }
    }
}

/// Initialize memory optimization systems
pub fn setup_memory_optimization(mut commands: Commands) {
    commands.insert_resource(MemoryProfiler::default());
    commands.insert_resource(EntityPools::default());
    
    info!("🧠 Memory optimization system initialized");
    info!("   Max entities: {}", 2000);
    info!("   Max memory: {}MB", 1024);
    info!("   Entity pooling enabled");
}

/// Track memory usage and detect potential leaks
pub fn monitor_memory_usage(
    mut profiler: ResMut<MemoryProfiler>,
    entities: Query<Entity>,
    tracked_entities: Query<&MemoryTracked>,
    particles: Query<&crate::components::particle::ParticleEffect>,
    ui_elements: Query<&Node>,
    effects: Query<&crate::components::power::ActivePowerEffect>,
    time: Res<Time>,
) {
    let current_time = time.elapsed_seconds();
    let total_entities = entities.iter().count();
    let total_components = tracked_entities.iter().count() + 
                          particles.iter().count() + 
                          ui_elements.iter().count() + 
                          effects.iter().count();
    
    // Estimate memory usage (simplified calculation)
    let estimated_memory_mb = estimate_total_memory_usage(
        total_entities,
        total_components,
        &tracked_entities,
    );
    
    // Create memory sample
    let sample = MemorySample {
        timestamp: current_time,
        entity_count: total_entities,
        component_count: total_components,
        estimated_memory_mb,
        gc_events: 0, // Would be tracked by actual GC
        allocation_rate: calculate_allocation_rate(&profiler.memory_samples, estimated_memory_mb),
    };
    
    // Store sample
    profiler.memory_samples.push_back(sample);
    if profiler.memory_samples.len() > 300 {
        profiler.memory_samples.pop_front();
    }
    
    // Update entity counts by category
    profiler.entity_counts.clear();
    for tracked in tracked_entities.iter() {
        *profiler.entity_counts.entry(tracked.category.clone()).or_insert(0) += 1;
    }
    
    // Leak detection
    detect_memory_leaks(&mut profiler, total_entities, current_time);
    
    // Check memory budget
    if estimated_memory_mb > profiler.memory_budget.max_memory_mb * profiler.memory_budget.cleanup_threshold {
        warn!("Memory usage approaching limit: {:.1}MB / {:.1}MB", 
              estimated_memory_mb, profiler.memory_budget.max_memory_mb);
    }
    
    // Log significant changes
    if total_entities > profiler.memory_budget.max_entities {
        warn!("Entity count exceeded budget: {} / {}", 
              total_entities, profiler.memory_budget.max_entities);
    }
}

fn estimate_total_memory_usage(
    entity_count: usize,
    component_count: usize,
    tracked_entities: &Query<&MemoryTracked>,
) -> f32 {
    let base_memory = 50.0; // Base game memory in MB
    let entity_memory = entity_count as f32 * 0.5; // ~500 bytes per entity
    let component_memory = component_count as f32 * 0.2; // ~200 bytes per component
    
    // Add tracked entity memory estimates
    let tracked_memory: usize = tracked_entities.iter()
        .map(|tracked| tracked.size_estimate_bytes)
        .sum();
    
    let tracked_memory_mb = tracked_memory as f32 / (1024.0 * 1024.0);
    
    base_memory + (entity_memory + component_memory) / 1024.0 + tracked_memory_mb
}

fn calculate_allocation_rate(samples: &VecDeque<MemorySample>, current_memory: f32) -> f32 {
    if samples.len() < 2 {
        return 0.0;
    }
    
    let recent_samples: Vec<&MemorySample> = samples.iter().rev().take(10).collect();
    if recent_samples.len() < 2 {
        return 0.0;
    }
    
    let oldest = recent_samples.last().unwrap();
    let newest = recent_samples.first().unwrap();
    
    let time_diff = newest.timestamp - oldest.timestamp;
    let memory_diff = newest.estimated_memory_mb - oldest.estimated_memory_mb;
    
    if time_diff > 0.0 {
        memory_diff / time_diff
    } else {
        0.0
    }
}

fn detect_memory_leaks(profiler: &mut MemoryProfiler, current_entities: usize, current_time: f32) {
    // Initialize baseline if not set
    if profiler.leak_detection.baseline_entities == 0 {
        profiler.leak_detection.baseline_entities = current_entities;
        return;
    }
    
    // Track maximum entities seen
    profiler.leak_detection.max_entities_seen = profiler.leak_detection.max_entities_seen.max(current_entities);
    
    // Check for persistent growth
    let growth = current_entities as f32 / profiler.leak_detection.baseline_entities as f32;
    
    if growth > 1.5 { // 50% growth threshold
        profiler.leak_detection.persistent_growth_frames += 1;
        
        if profiler.leak_detection.persistent_growth_frames > 300 { // 5 seconds at 60fps
            // Potential leak detected
            for (category, &count) in &profiler.entity_counts {
                if count > 100 { // Threshold for concern
                    let growth_rate = count as f32 / 60.0; // entities per second
                    
                    let severity = match growth_rate {
                        r if r > 20.0 => LeakSeverity::Critical,
                        r if r > 10.0 => LeakSeverity::High,
                        r if r > 5.0 => LeakSeverity::Medium,
                        _ => LeakSeverity::Low,
                    };
                    
                    // Check if this leak is already reported
                    let already_reported = profiler.leak_detection.potential_leaks
                        .iter()
                        .any(|leak| leak.entity_type == *category);
                    
                    if !already_reported {
                        profiler.leak_detection.potential_leaks.push(LeakReport {
                            entity_type: category.clone(),
                            count,
                            growth_rate,
                            first_detected: current_time,
                            severity,
                        });
                        
                        match severity {
                            LeakSeverity::Critical | LeakSeverity::High => {
                                error!("🚨 Potential memory leak detected: {} entities of type '{}' (growth: {:.1}/s)", 
                                       count, category, growth_rate);
                            },
                            LeakSeverity::Medium => {
                                warn!("⚠️ Potential memory leak: {} entities of type '{}' (growth: {:.1}/s)", 
                                      count, category, growth_rate);
                            },
                            LeakSeverity::Low => {
                                info!("ℹ️ Memory growth detected: {} entities of type '{}' (growth: {:.1}/s)", 
                                      count, category, growth_rate);
                            },
                        }
                    }
                }
            }
        }
    } else {
        profiler.leak_detection.persistent_growth_frames = 0;
    }
}

/// Automatic memory cleanup when approaching limits
pub fn automatic_memory_cleanup(
    mut commands: Commands,
    mut profiler: ResMut<MemoryProfiler>,
    mut pools: ResMut<EntityPools>,
    temporary_entities: Query<(Entity, &TemporaryEntity)>,
    old_particles: Query<(Entity, &crate::components::particle::ParticleEffect)>,
    completed_effects: Query<(Entity, &crate::components::power::ActivePowerEffect)>,
    time: Res<Time>,
) {
    let current_memory = profiler.memory_samples.back()
        .map(|s| s.estimated_memory_mb)
        .unwrap_or(0.0);
    
    // Trigger cleanup if approaching memory limit
    if current_memory > profiler.memory_budget.max_memory_mb * profiler.memory_budget.cleanup_threshold {
        info!("🧹 Automatic memory cleanup triggered ({}MB / {}MB)", 
              current_memory, profiler.memory_budget.max_memory_mb);
        
        let mut entities_cleaned = 0;
        let current_time = time.elapsed_seconds();
        
        // Clean up expired temporary entities
        for (entity, temp) in temporary_entities.iter() {
            if temp.auto_cleanup && temp.lifetime >= temp.max_lifetime {
                commands.entity(entity).despawn();
                entities_cleaned += 1;
            }
        }
        
        // Clean up old particles (keep newest 50%)
        let particle_count = old_particles.iter().count();
        if particle_count > profiler.memory_budget.max_particles {
            let mut particles: Vec<_> = old_particles.iter().collect();
            particles.sort_by_key(|(_, particle)| (particle.lifetime * 1000.0) as i32);
            
            let to_remove = particle_count - profiler.memory_budget.max_particles;
            for (entity, _) in particles.iter().take(to_remove) {
                return_entity_to_pool(&mut pools, *entity, "particles".to_string());
                entities_cleaned += 1;
            }
        }
        
        // Clean up completed effects
        for (entity, effect) in completed_effects.iter() {
            if effect.completed {
                return_entity_to_pool(&mut pools, entity, "effects".to_string());
                entities_cleaned += 1;
            }
        }
        
        profiler.optimization_stats.entities_despawned += entities_cleaned;
        profiler.optimization_stats.optimizations_performed += 1;
        
        if entities_cleaned > 0 {
            info!("✅ Cleaned up {} entities", entities_cleaned);
        }
    }
}

/// Get entity from pool or create new one
pub fn get_pooled_entity(
    pools: &mut ResMut<EntityPools>,
    commands: &mut Commands,
    pool_id: &str,
    category: &str,
) -> Entity {
    if let Some(pool) = pools.pools.get_mut(pool_id) {
        if let Some(entity) = pool.available.pop() {
            pool.in_use.push(entity);
            pool.total_reused += 1;
            pools.stats.total_entities_pooled += 1;
            
            // Add components for tracking
            commands.entity(entity).insert((
                PooledEntity {
                    pool_id: pool_id.to_string(),
                    last_used: 0.0, // Will be set by time system
                    reuse_count: pool.total_reused,
                },
                MemoryTracked {
                    category: category.to_string(),
                    created_at: 0.0, // Will be set by time system
                    size_estimate_bytes: 1024, // 1KB default
                },
            ));
            
            return entity;
        }
    }
    
    // Pool empty or doesn't exist, create new entity
    let entity = commands.spawn((
        MemoryTracked {
            category: category.to_string(),
            created_at: 0.0, // Will be set by time system
            size_estimate_bytes: 1024,
        },
    )).id();
    
    // Add to pool
    if let Some(pool) = pools.pools.get_mut(pool_id) {
        pool.total_created += 1;
        pool.in_use.push(entity);
    }
    
    entity
}

/// Return entity to pool instead of despawning
pub fn return_entity_to_pool(
    pools: &mut ResMut<EntityPools>,
    entity: Entity,
    pool_id: String,
) {
    if let Some(pool) = pools.pools.get_mut(&pool_id) {
        // Move from in_use to available
        if let Some(pos) = pool.in_use.iter().position(|&e| e == entity) {
            pool.in_use.remove(pos);
            
            // Only add back if pool isn't full
            if pool.available.len() < pool.max_size {
                pool.available.push(entity);
            }
        }
    }
}

/// Update temporary entity lifetimes
pub fn update_temporary_entities(
    mut commands: Commands,
    mut temporary_entities: Query<(Entity, &mut TemporaryEntity)>,
    time: Res<Time>,
) {
    let dt = time.delta_seconds();
    
    for (entity, mut temp) in temporary_entities.iter_mut() {
        temp.lifetime += dt;
        
        if temp.lifetime >= temp.max_lifetime && temp.auto_cleanup {
            commands.entity(entity).despawn();
        }
    }
}

/// Generate memory optimization report
pub fn generate_memory_report(
    profiler: Res<MemoryProfiler>,
    pools: Res<EntityPools>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F7) {
        println!("\n🧠 MEMORY OPTIMIZATION REPORT");
        println!("=======================================");
        
        // Current memory status
        if let Some(latest_sample) = profiler.memory_samples.back() {
            println!("📊 CURRENT MEMORY STATUS");
            println!("   Total Memory: {:.1}MB / {:.1}MB", 
                     latest_sample.estimated_memory_mb, profiler.memory_budget.max_memory_mb);
            println!("   Total Entities: {} / {}", 
                     latest_sample.entity_count, profiler.memory_budget.max_entities);
            println!("   Components: {}", latest_sample.component_count);
            println!("   Allocation Rate: {:.2}MB/s", latest_sample.allocation_rate);
            
            let memory_usage_percent = (latest_sample.estimated_memory_mb / profiler.memory_budget.max_memory_mb) * 100.0;
            let status = match memory_usage_percent {
                p if p < 50.0 => "✅ EXCELLENT",
                p if p < 70.0 => "🟡 GOOD",
                p if p < 85.0 => "🟠 WARNING",
                _ => "🔴 CRITICAL",
            };
            println!("   Status: {} ({:.1}%)", status, memory_usage_percent);
        }
        
        // Entity breakdown
        println!("\n🎭 ENTITY BREAKDOWN");
        for (category, count) in &profiler.entity_counts {
            println!("   {}: {} entities", category, count);
        }
        
        // Memory leak detection
        if !profiler.leak_detection.potential_leaks.is_empty() {
            println!("\n🚨 POTENTIAL MEMORY LEAKS");
            for leak in &profiler.leak_detection.potential_leaks {
                let severity_icon = match leak.severity {
                    LeakSeverity::Critical => "🚨",
                    LeakSeverity::High => "⚠️",
                    LeakSeverity::Medium => "🟡",
                    LeakSeverity::Low => "ℹ️",
                };
                println!("   {} {}: {} entities (growth: {:.1}/s)", 
                         severity_icon, leak.entity_type, leak.count, leak.growth_rate);
            }
        } else {
            println!("\n✅ NO MEMORY LEAKS DETECTED");
        }
        
        // Entity pooling stats
        println!("\n♻️ ENTITY POOLING STATISTICS");
        for (pool_name, pool) in &pools.pools {
            let reuse_ratio = if pool.total_created > 0 {
                pool.total_reused as f32 / pool.total_created as f32
            } else {
                0.0
            };
            
            println!("   {}: {}/{} available, {:.1}% reuse rate", 
                     pool_name, pool.available.len(), pool.max_size, reuse_ratio * 100.0);
        }
        
        // Optimization statistics
        println!("\n🔧 OPTIMIZATION STATISTICS");
        println!("   Entities Pooled: {}", profiler.optimization_stats.entities_pooled);
        println!("   Entities Cleaned: {}", profiler.optimization_stats.entities_despawned);
        println!("   Components Removed: {}", profiler.optimization_stats.components_removed);
        println!("   Memory Freed: {:.1}MB", profiler.optimization_stats.memory_freed_mb);
        println!("   Total Optimizations: {}", profiler.optimization_stats.optimizations_performed);
        
        // Recommendations
        println!("\n💡 OPTIMIZATION RECOMMENDATIONS");
        
        if profiler.memory_samples.back().map(|s| s.estimated_memory_mb).unwrap_or(0.0) > 
           profiler.memory_budget.max_memory_mb * 0.8 {
            println!("   🔴 High memory usage - consider reducing entity count");
        }
        
        if !profiler.leak_detection.potential_leaks.is_empty() {
            println!("   🚨 Memory leaks detected - investigate entity cleanup");
        }
        
        let total_pooled = pools.pools.values().map(|p| p.total_reused).sum::<usize>();
        let total_created = pools.pools.values().map(|p| p.total_created).sum::<usize>();
        if total_created > 0 && (total_pooled as f32 / total_created as f32) < 0.5 {
            println!("   ♻️ Low pooling efficiency - optimize entity reuse");
        }
        
        println!("=======================================\n");
    }
}

/// Force garbage collection and cleanup
pub fn force_memory_cleanup(
    mut commands: Commands,
    mut profiler: ResMut<MemoryProfiler>,
    mut pools: ResMut<EntityPools>,
    keyboard: Res<Input<KeyCode>>,
    all_entities: Query<Entity>,
    tracked_entities: Query<(Entity, &MemoryTracked)>,
) {
    if keyboard.just_pressed(KeyCode::F6) {
        info!("🧹 Force memory cleanup initiated...");
        
        let before_count = all_entities.iter().count();
        let mut cleaned = 0;
        
        // Remove all temporary entities
        for (entity, tracked) in tracked_entities.iter() {
            if tracked.category == "temporary" || tracked.category == "particle" {
                commands.entity(entity).despawn();
                cleaned += 1;
            }
        }
        
        // Clear all pools
        for pool in pools.pools.values_mut() {
            pool.available.clear();
            pool.in_use.clear();
        }
        
        // Reset leak detection
        profiler.leak_detection.potential_leaks.clear();
        profiler.leak_detection.persistent_growth_frames = 0;
        
        // Update stats
        profiler.optimization_stats.entities_despawned += cleaned;
        profiler.optimization_stats.optimizations_performed += 1;
        
        info!("✅ Force cleanup completed: {} entities removed", cleaned);
    }
}