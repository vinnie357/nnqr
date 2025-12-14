use bevy::diagnostic::{DiagnosticsStore, FrameTimeDiagnosticsPlugin, SystemInformationDiagnosticsPlugin};
use bevy::prelude::*;
use std::collections::HashMap;
use std::time::{Duration, Instant};

/// Phase 5 Performance Benchmarking System
/// Provides comprehensive performance analysis for production readiness

#[derive(Resource)]
pub struct PerformanceBenchmark {
    pub start_time: Instant,
    pub samples: Vec<PerformanceSample>,
    pub power_activation_times: HashMap<String, Vec<f32>>,
    pub memory_usage: Vec<usize>,
    pub target_metrics: PerformanceTargets,
    pub current_status: BenchmarkStatus,
    pub test_scenarios: Vec<TestScenario>,
}

#[derive(Clone)]
pub struct PerformanceTargets {
    pub target_fps: f32,
    pub max_memory_mb: usize,
    pub max_power_activation_ms: f32,
    pub max_frame_time_ms: f32,
    pub stability_threshold: f32,
}

impl Default for PerformanceTargets {
    fn default() -> Self {
        Self {
            target_fps: 60.0,
            max_memory_mb: 1024, // 1GB
            max_power_activation_ms: 50.0,
            max_frame_time_ms: 16.67, // ~60fps
            stability_threshold: 0.95, // 95% of frames must meet target
        }
    }
}

#[derive(Clone)]
pub struct PerformanceSample {
    pub timestamp: Duration,
    pub fps: f32,
    pub frame_time_ms: f32,
    pub entity_count: usize,
    pub active_powers: usize,
    pub memory_mb: usize,
    pub scenario: String,
}

#[derive(Clone, PartialEq)]
pub enum BenchmarkStatus {
    NotStarted,
    Running,
    Completed,
    Failed(String),
}

#[derive(Clone)]
pub struct TestScenario {
    pub name: String,
    pub description: String,
    pub duration_seconds: f32,
    pub active_powers: Vec<String>,
    pub target_fps: f32,
    pub completed: bool,
}

impl Default for PerformanceBenchmark {
    fn default() -> Self {
        Self {
            start_time: Instant::now(),
            samples: Vec::new(),
            power_activation_times: HashMap::new(),
            memory_usage: Vec::new(),
            target_metrics: PerformanceTargets::default(),
            current_status: BenchmarkStatus::NotStarted,
            test_scenarios: create_test_scenarios(),
        }
    }
}

fn create_test_scenarios() -> Vec<TestScenario> {
    vec![
        TestScenario {
            name: "Baseline".to_string(),
            description: "Empty board, no powers active".to_string(),
            duration_seconds: 30.0,
            active_powers: vec![],
            target_fps: 60.0,
            completed: false,
        },
        TestScenario {
            name: "Standard Gameplay".to_string(),
            description: "Normal game with 3-5 powers active".to_string(),
            duration_seconds: 60.0,
            active_powers: vec!["MoveDiagonal".to_string(), "Jump".to_string(), "Shield".to_string()],
            target_fps: 60.0,
            completed: false,
        },
        TestScenario {
            name: "Heavy Effects".to_string(),
            description: "10+ visual effects active simultaneously".to_string(),
            duration_seconds: 45.0,
            active_powers: vec![
                "Bomb".to_string(), "Lightning".to_string(), "Teleport".to_string(),
                "Invisible".to_string(), "Freeze".to_string(), "Poison".to_string(),
                "Heal".to_string(), "Shield".to_string(), "Dash".to_string(),
                "Multiply".to_string()
            ],
            target_fps: 50.0, // Reduced target for heavy load
            completed: false,
        },
        TestScenario {
            name: "Terrain Manipulation".to_string(),
            description: "Multiple terrain-changing powers active".to_string(),
            duration_seconds: 60.0,
            active_powers: vec![
                "RaiseColumn".to_string(), "LowerColumn".to_string(),
                "RaiseArea".to_string(), "LowerArea".to_string(),
                "Terraform".to_string()
            ],
            target_fps: 55.0,
            completed: false,
        },
        TestScenario {
            name: "Stress Test".to_string(),
            description: "Maximum powers and effects active".to_string(),
            duration_seconds: 120.0,
            active_powers: vec![
                "Bomb".to_string(), "Lightning".to_string(), "Teleport".to_string(),
                "Invisible".to_string(), "Freeze".to_string(), "Poison".to_string(),
                "Heal".to_string(), "Shield".to_string(), "Dash".to_string(),
                "Multiply".to_string(), "RaiseColumn".to_string(), "LowerColumn".to_string(),
                "RaiseArea".to_string(), "LowerArea".to_string(), "Terraform".to_string(),
                "Wall".to_string(), "Destroy".to_string(), "Push".to_string(),
                "Pull".to_string(), "Swap".to_string()
            ],
            target_fps: 30.0, // Minimum acceptable performance
            completed: false,
        },
    ]
}

/// Initialize performance benchmark system
pub fn start_performance_benchmark(
    mut commands: Commands,
    mut benchmark: ResMut<PerformanceBenchmark>,
) {
    benchmark.start_time = Instant::now();
    benchmark.current_status = BenchmarkStatus::Running;
    benchmark.samples.clear();
    benchmark.power_activation_times.clear();
    benchmark.memory_usage.clear();
    
    // Reset test scenarios
    for scenario in &mut benchmark.test_scenarios {
        scenario.completed = false;
    }
    
    info!("🚀 Phase 5 Performance Benchmark Started");
    info!("Target: {} FPS, {} MB RAM, {} ms max frame time", 
          benchmark.target_metrics.target_fps,
          benchmark.target_metrics.max_memory_mb,
          benchmark.target_metrics.max_frame_time_ms);
}

/// Collect performance samples during benchmark
pub fn collect_performance_samples(
    mut benchmark: ResMut<PerformanceBenchmark>,
    diagnostics: Res<DiagnosticsStore>,
    time: Res<Time>,
    entity_count: Query<Entity>,
    active_powers: Query<&crate::components::power::ActivePower>,
) {
    if benchmark.current_status != BenchmarkStatus::Running {
        return;
    }

    // Collect current metrics
    let current_time = benchmark.start_time.elapsed();
    let entity_count = entity_count.iter().count();
    let active_power_count = active_powers.iter().count();
    
    if let Some(fps_diagnostic) = diagnostics.get(FrameTimeDiagnosticsPlugin::FPS) {
        if let Some(fps) = fps_diagnostic.smoothed() {
            let frame_time_ms = 1000.0 / fps as f32;
            
            // Estimate memory usage (simplified - in real implementation would use actual memory API)
            let estimated_memory_mb = estimate_memory_usage(entity_count, active_power_count);
            
            let sample = PerformanceSample {
                timestamp: current_time,
                fps: fps as f32,
                frame_time_ms,
                entity_count,
                active_powers: active_power_count,
                memory_mb: estimated_memory_mb,
                scenario: get_current_scenario(&benchmark, current_time),
            };
            
            benchmark.samples.push(sample);
            benchmark.memory_usage.push(estimated_memory_mb);
            
            // Log significant performance events
            if fps < benchmark.target_metrics.target_fps as f64 * 0.8 {
                warn!("Performance warning: FPS dropped to {:.1} (target: {})", 
                      fps, benchmark.target_metrics.target_fps);
            }
            
            if frame_time_ms > benchmark.target_metrics.max_frame_time_ms * 1.5 {
                warn!("Frame time spike: {:.2}ms (target: {:.2}ms)", 
                      frame_time_ms, benchmark.target_metrics.max_frame_time_ms);
            }
        }
    }
}

/// Track power activation performance
pub fn track_power_activation_performance(
    mut benchmark: ResMut<PerformanceBenchmark>,
    power_events: EventReader<crate::events::PowerActivatedEvent>,
) {
    for event in power_events.iter() {
        let power_name = format!("{:?}", event.power_type);
        let activation_time = event.activation_duration_ms;
        
        benchmark.power_activation_times
            .entry(power_name.clone())
            .or_insert_with(Vec::new)
            .push(activation_time);
        
        if activation_time > benchmark.target_metrics.max_power_activation_ms {
            warn!("Slow power activation: {} took {:.2}ms (target: {:.2}ms)",
                  power_name, activation_time, benchmark.target_metrics.max_power_activation_ms);
        }
    }
}

/// Generate comprehensive performance report
pub fn generate_performance_report(
    benchmark: Res<PerformanceBenchmark>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F12) {
        println!("\n🎯 PHASE 5 PERFORMANCE BENCHMARK REPORT");
        println!("================================================");
        
        if benchmark.samples.is_empty() {
            println!("❌ No performance data collected yet");
            return;
        }
        
        // Overall performance metrics
        let avg_fps = benchmark.samples.iter().map(|s| s.fps).sum::<f32>() / benchmark.samples.len() as f32;
        let min_fps = benchmark.samples.iter().map(|s| s.fps).fold(f32::INFINITY, f32::min);
        let max_fps = benchmark.samples.iter().map(|s| s.fps).fold(0.0, f32::max);
        
        let avg_frame_time = benchmark.samples.iter().map(|s| s.frame_time_ms).sum::<f32>() / benchmark.samples.len() as f32;
        let max_frame_time = benchmark.samples.iter().map(|s| s.frame_time_ms).fold(0.0, f32::max);
        
        let avg_memory = benchmark.memory_usage.iter().sum::<usize>() as f32 / benchmark.memory_usage.len() as f32;
        let max_memory = benchmark.memory_usage.iter().max().unwrap_or(&0);
        
        // Performance assessment
        let fps_target_met = avg_fps >= benchmark.target_metrics.target_fps;
        let frame_time_target_met = avg_frame_time <= benchmark.target_metrics.max_frame_time_ms;
        let memory_target_met = *max_memory <= benchmark.target_metrics.max_memory_mb;
        
        println!("📊 OVERALL PERFORMANCE");
        println!("   Average FPS: {:.1} {} (target: {})", 
                 avg_fps, 
                 if fps_target_met { "✅" } else { "❌" },
                 benchmark.target_metrics.target_fps);
        println!("   FPS Range: {:.1} - {:.1}", min_fps, max_fps);
        println!("   Average Frame Time: {:.2}ms {} (target: {:.2}ms)", 
                 avg_frame_time,
                 if frame_time_target_met { "✅" } else { "❌" },
                 benchmark.target_metrics.max_frame_time_ms);
        println!("   Worst Frame Time: {:.2}ms", max_frame_time);
        println!("   Average Memory: {:.0}MB", avg_memory);
        println!("   Peak Memory: {}MB {} (target: {}MB)", 
                 max_memory,
                 if memory_target_met { "✅" } else { "❌" },
                 benchmark.target_metrics.max_memory_mb);
        
        // Stability analysis
        let stable_frames = benchmark.samples.iter()
            .filter(|s| s.fps >= benchmark.target_metrics.target_fps * benchmark.target_metrics.stability_threshold)
            .count();
        let stability_percentage = stable_frames as f32 / benchmark.samples.len() as f32;
        let stability_target_met = stability_percentage >= benchmark.target_metrics.stability_threshold;
        
        println!("\n📈 STABILITY ANALYSIS");
        println!("   Stable Frames: {}/{} ({:.1}%) {}", 
                 stable_frames, benchmark.samples.len(), 
                 stability_percentage * 100.0,
                 if stability_target_met { "✅" } else { "❌" });
        println!("   Target Stability: {:.1}%", benchmark.target_metrics.stability_threshold * 100.0);
        
        // Power activation performance
        if !benchmark.power_activation_times.is_empty() {
            println!("\n⚡ POWER ACTIVATION PERFORMANCE");
            for (power_name, times) in &benchmark.power_activation_times {
                if !times.is_empty() {
                    let avg_time = times.iter().sum::<f32>() / times.len() as f32;
                    let max_time = times.iter().fold(0.0, |a, &b| a.max(b));
                    let target_met = avg_time <= benchmark.target_metrics.max_power_activation_ms;
                    
                    println!("   {}: {:.2}ms avg, {:.2}ms max {} (target: {:.2}ms)", 
                             power_name, avg_time, max_time,
                             if target_met { "✅" } else { "❌" },
                             benchmark.target_metrics.max_power_activation_ms);
                }
            }
        }
        
        // Test scenarios
        println!("\n🧪 TEST SCENARIO RESULTS");
        for scenario in &benchmark.test_scenarios {
            let status = if scenario.completed { "✅ COMPLETED" } else { "⏳ PENDING" };
            println!("   {}: {} (target: {:.0} FPS)", scenario.name, status, scenario.target_fps);
            println!("      {}", scenario.description);
        }
        
        // Overall grade
        let overall_grade = calculate_performance_grade(
            fps_target_met,
            frame_time_target_met,
            memory_target_met,
            stability_target_met,
        );
        
        println!("\n🎯 OVERALL PERFORMANCE GRADE: {}", overall_grade);
        
        // Recommendations
        println!("\n💡 OPTIMIZATION RECOMMENDATIONS:");
        if !fps_target_met {
            println!("   📉 FPS below target - consider reducing visual complexity");
        }
        if !frame_time_target_met {
            println!("   ⏱️  Frame time spikes detected - optimize heavy operations");
        }
        if !memory_target_met {
            println!("   🧠 Memory usage high - implement entity pooling");
        }
        if !stability_target_met {
            println!("   📊 Performance unstable - investigate frame time variance");
        }
        
        println!("\n🔧 NEXT STEPS:");
        println!("   1. Run specific optimization passes");
        println!("   2. Profile individual power systems");
        println!("   3. Test on lower-end hardware");
        println!("   4. Implement adaptive quality settings");
        
        println!("================================================\n");
    }
}

fn estimate_memory_usage(entity_count: usize, active_powers: usize) -> usize {
    // Rough estimation based on entity count and active systems
    // In a real implementation, this would use actual memory profiling
    let base_memory = 50; // 50MB base
    let entity_memory = entity_count * 2; // ~2KB per entity
    let power_memory = active_powers * 10; // ~10KB per active power
    
    (base_memory + entity_memory / 1024 + power_memory / 1024).min(2048) // Cap at 2GB
}

fn get_current_scenario(benchmark: &PerformanceBenchmark, elapsed: Duration) -> String {
    let elapsed_secs = elapsed.as_secs_f32();
    
    for scenario in &benchmark.test_scenarios {
        if !scenario.completed && elapsed_secs < scenario.duration_seconds {
            return scenario.name.clone();
        }
    }
    
    "Free Play".to_string()
}

fn calculate_performance_grade(
    fps_ok: bool, 
    frame_time_ok: bool, 
    memory_ok: bool, 
    stability_ok: bool
) -> String {
    let score = [fps_ok, frame_time_ok, memory_ok, stability_ok]
        .iter()
        .filter(|&&x| x)
        .count();
    
    match score {
        4 => "🏆 EXCELLENT (A+)".to_string(),
        3 => "🥇 GOOD (A)".to_string(),
        2 => "🥈 ACCEPTABLE (B)".to_string(),
        1 => "🥉 POOR (C)".to_string(),
        0 => "❌ FAILING (F)".to_string(),
        _ => "UNKNOWN".to_string(),
    }
}

/// System to automatically run test scenarios
pub fn run_benchmark_scenarios(
    mut benchmark: ResMut<PerformanceBenchmark>,
    time: Res<Time>,
    mut game_state: ResMut<crate::resources::GameState>,
) {
    if benchmark.current_status != BenchmarkStatus::Running {
        return;
    }
    
    let elapsed = benchmark.start_time.elapsed().as_secs_f32();
    
    // Check if current scenario should be completed
    for scenario in &mut benchmark.test_scenarios {
        if !scenario.completed && elapsed >= scenario.duration_seconds {
            scenario.completed = true;
            info!("✅ Completed benchmark scenario: {}", scenario.name);
            
            // Move to next scenario or complete benchmark
            if benchmark.test_scenarios.iter().all(|s| s.completed) {
                benchmark.current_status = BenchmarkStatus::Completed;
                info!("🏁 Performance benchmark completed!");
            }
        }
    }
}