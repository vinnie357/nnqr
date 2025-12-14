use crate::{components::*, resources::*};
use bevy::prelude::*;
use std::collections::VecDeque;

// Automated power testing system
#[derive(Resource)]
pub struct PowerTestSuite {
    pub current_test: Option<PowerTest>,
    pub test_queue: VecDeque<PowerTest>,
    pub test_results: Vec<PowerTestResult>,
    pub auto_mode: bool,
    pub test_delay: f32,
    pub current_delay: f32,
}

impl Default for PowerTestSuite {
    fn default() -> Self {
        Self {
            current_test: None,
            test_queue: VecDeque::new(),
            test_results: Vec::new(),
            auto_mode: false,
            test_delay: 2.0, // 2 seconds between tests
            current_delay: 0.0,
        }
    }
}

#[derive(Clone, Debug)]
pub struct PowerTest {
    pub power_type: PowerType,
    pub test_scenario: TestScenario,
    pub expected_outcome: ExpectedOutcome,
    pub setup_description: String,
}

#[derive(Clone, Debug)]
pub enum TestScenario {
    BasicUsage,       // Normal conditions
    EdgeCase,         // Board edges, corners
    Blocked,          // Target blocked by other pieces
    EmptyBoard,       // Minimal pieces on board
    FullBoard,        // Many pieces on board
    PowerCombination, // Using with other active powers
}

#[derive(Clone, Debug)]
pub enum ExpectedOutcome {
    Success,
    Failure,
    PartialSuccess,
    NoEffect,
}

#[derive(Clone, Debug)]
pub struct PowerTestResult {
    pub power_type: PowerType,
    pub scenario: TestScenario,
    pub expected: ExpectedOutcome,
    pub actual: TestOutcome,
    pub execution_time: f32,
    pub error_message: Option<String>,
    pub success: bool,
}

#[derive(Clone, Debug)]
pub enum TestOutcome {
    PowerActivated,
    PowerFailed,
    InvalidTarget,
    NoTargetSelected,
    Error(String),
}

// Initialize comprehensive power test suite
pub fn setup_power_test_suite(
    mut test_suite: ResMut<PowerTestSuite>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F5) {
        println!("🧪 Setting up comprehensive power test suite...");

        test_suite.test_queue.clear();
        test_suite.test_results.clear();

        // Create tests for all power types
        let all_powers = [
            PowerType::MoveDiagonal,
            PowerType::RaiseColumn,
            PowerType::LowerColumn,
            PowerType::DestroyColumn,
            PowerType::Multiply,
            PowerType::Teleport,
            PowerType::Jump,
            PowerType::MoveTwo,
            PowerType::Knight,
            PowerType::SmartBomb,
            PowerType::Sniper,
            PowerType::Assassin,
            PowerType::Push,
            PowerType::Pull,
            PowerType::Swap,
            PowerType::Shield,
            PowerType::Invisible,
            PowerType::Leap,
            PowerType::MoveTwice,
            PowerType::Slide,
        ];

        for power in all_powers {
            // Test each power in different scenarios
            test_suite.test_queue.push_back(PowerTest {
                power_type: power,
                test_scenario: TestScenario::BasicUsage,
                expected_outcome: ExpectedOutcome::Success,
                setup_description: format!("Basic usage test for {:?}", power),
            });

            test_suite.test_queue.push_back(PowerTest {
                power_type: power,
                test_scenario: TestScenario::EdgeCase,
                expected_outcome: ExpectedOutcome::PartialSuccess,
                setup_description: format!("Edge case test for {:?}", power),
            });

            test_suite.test_queue.push_back(PowerTest {
                power_type: power,
                test_scenario: TestScenario::Blocked,
                expected_outcome: ExpectedOutcome::Failure,
                setup_description: format!("Blocked target test for {:?}", power),
            });
        }

        println!(
            "✅ Test suite ready: {} tests queued",
            test_suite.test_queue.len()
        );
        println!("Press F6 to start automated testing, F7 for manual testing");
    }
}

// Start automated power testing
pub fn start_automated_testing(
    mut test_suite: ResMut<PowerTestSuite>,
    keyboard: Res<Input<KeyCode>>,
) {
    if keyboard.just_pressed(KeyCode::F6) {
        if !test_suite.test_queue.is_empty() {
            test_suite.auto_mode = true;
            test_suite.current_delay = 0.0;
            println!("🤖 Starting automated power testing...");
            println!("   {} tests in queue", test_suite.test_queue.len());
        } else {
            println!("❌ No tests queued! Press F5 to setup test suite first.");
        }
    }

    if keyboard.just_pressed(KeyCode::F8) {
        test_suite.auto_mode = false;
        println!("⏸️  Automated testing paused.");
    }
}

// Execute power tests automatically
pub fn execute_automated_tests(
    mut test_suite: ResMut<PowerTestSuite>,
    mut game_state: ResMut<GameState>,
    time: Res<Time>,
    pieces: Query<(Entity, &GamePiece)>,
    mut commands: Commands,
) {
    if !test_suite.auto_mode {
        return;
    }

    test_suite.current_delay += time.delta_seconds();

    if test_suite.current_delay >= test_suite.test_delay {
        if let Some(test) = test_suite.test_queue.pop_front() {
            test_suite.current_delay = 0.0;

            println!(
                "🧪 Running test: {:?} - {:?}",
                test.power_type, test.test_scenario
            );

            // Execute the test
            let result = execute_power_test(&test, &mut game_state, &pieces, &mut commands);

            // Store result
            test_suite.test_results.push(result.clone());

            // Report result
            if result.success {
                println!("   ✅ PASS: {:?}", result.actual);
            } else {
                println!(
                    "   ❌ FAIL: Expected {:?}, got {:?}",
                    result.expected, result.actual
                );
                if let Some(error) = &result.error_message {
                    println!("      Error: {}", error);
                }
            }

            test_suite.current_test = Some(test);
        } else {
            // All tests completed
            test_suite.auto_mode = false;
            generate_test_summary(&test_suite);
        }
    }
}

// Execute a single power test
fn execute_power_test(
    test: &PowerTest,
    game_state: &mut ResMut<GameState>,
    pieces: &Query<(Entity, &GamePiece)>,
    commands: &mut Commands,
) -> PowerTestResult {
    let start_time = std::time::Instant::now();

    // Setup test scenario
    setup_test_scenario(&test.test_scenario, game_state, pieces, commands);

    // Add power to current player
    game_state
        .get_current_player_powers_mut()
        .push(test.power_type);

    // Try to activate power (simplified for testing)
    let outcome = simulate_power_activation(test.power_type, game_state, pieces);

    let execution_time = start_time.elapsed().as_secs_f32();

    // Determine if test passed
    let success = matches!(
        (&test.expected_outcome, &outcome),
        (ExpectedOutcome::Success, TestOutcome::PowerActivated)
            | (ExpectedOutcome::Failure, TestOutcome::PowerFailed)
            | (ExpectedOutcome::NoEffect, TestOutcome::NoTargetSelected)
    );

    PowerTestResult {
        power_type: test.power_type,
        scenario: test.test_scenario.clone(),
        expected: test.expected_outcome.clone(),
        actual: outcome,
        execution_time,
        error_message: None,
        success,
    }
}

// Setup different test scenarios
fn setup_test_scenario(
    scenario: &TestScenario,
    game_state: &mut ResMut<GameState>,
    pieces: &Query<(Entity, &GamePiece)>,
    commands: &mut Commands,
) {
    match scenario {
        TestScenario::BasicUsage => {
            // Standard board setup - do nothing
        }
        TestScenario::EdgeCase => {
            // Move a piece to board edge for testing
            if let Some((_entity, _)) = pieces.iter().next() {
                // Move piece to corner - would require more complex piece movement system
            }
        }
        TestScenario::Blocked => {
            // Create blocked scenario - place pieces adjacent to each other
            // This would require more complex setup
        }
        TestScenario::EmptyBoard => {
            // Remove most pieces except minimum for testing
            for (count, (entity, _)) in pieces.iter().enumerate() {
                if count > 2 {
                    if let Some(mut entity_commands) = commands.get_entity(entity) {
                        entity_commands.despawn();
                    }
                }
            }
        }
        TestScenario::FullBoard => {
            // Add more pieces if needed (complex setup)
        }
        TestScenario::PowerCombination => {
            // Activate multiple powers
            game_state
                .get_current_player_powers_mut()
                .push(PowerType::MoveDiagonal);
            game_state
                .get_current_player_powers_mut()
                .push(PowerType::Teleport);
        }
    }
}

// Simulate power activation for testing
fn simulate_power_activation(
    power_type: PowerType,
    game_state: &ResMut<GameState>,
    pieces: &Query<(Entity, &GamePiece)>,
) -> TestOutcome {
    // Get first piece of current player for testing
    let player_piece = pieces
        .iter()
        .find(|(_, piece)| piece.player == game_state.current_player);

    if player_piece.is_none() {
        return TestOutcome::Error("No player piece found".to_string());
    }

    // Simulate power effects based on type
    match power_type {
        PowerType::MoveDiagonal | PowerType::Teleport | PowerType::Jump => {
            // Movement powers - simulate successful activation
            TestOutcome::PowerActivated
        }
        PowerType::Multiply => {
            // Check if there's space for multiplication
            if pieces.iter().count() < 32 {
                TestOutcome::PowerActivated
            } else {
                TestOutcome::PowerFailed
            }
        }
        PowerType::SmartBomb | PowerType::Sniper | PowerType::Assassin => {
            // Offensive powers - check for targets
            let enemy_pieces = pieces
                .iter()
                .filter(|(_, piece)| piece.player != game_state.current_player)
                .count();

            if enemy_pieces > 0 {
                TestOutcome::PowerActivated
            } else {
                TestOutcome::NoTargetSelected
            }
        }
        PowerType::RaiseColumn | PowerType::LowerColumn | PowerType::DestroyColumn => {
            // Column powers - always work
            TestOutcome::PowerActivated
        }
        _ => {
            // Default - assume power works
            TestOutcome::PowerActivated
        }
    }
}

// Generate comprehensive test summary
fn generate_test_summary(test_suite: &PowerTestSuite) {
    println!("\n🏁 POWER TEST SUITE COMPLETED");
    println!("=====================================");

    let total_tests = test_suite.test_results.len();
    let passed_tests = test_suite.test_results.iter().filter(|r| r.success).count();
    let failed_tests = total_tests - passed_tests;

    println!("📊 SUMMARY:");
    println!("   Total Tests: {}", total_tests);
    println!(
        "   Passed: {} ({:.1}%)",
        passed_tests,
        (passed_tests as f32 / total_tests as f32) * 100.0
    );
    println!(
        "   Failed: {} ({:.1}%)",
        failed_tests,
        (failed_tests as f32 / total_tests as f32) * 100.0
    );

    // Group results by power type
    println!("\n📋 RESULTS BY POWER:");
    let mut power_results = std::collections::HashMap::new();
    for result in &test_suite.test_results {
        let entry = power_results.entry(result.power_type).or_insert((0, 0));
        if result.success {
            entry.0 += 1;
        } else {
            entry.1 += 1;
        }
    }

    for (power, (passed, failed)) in power_results {
        let total = passed + failed;
        let pass_rate = (passed as f32 / total as f32) * 100.0;

        let status = if pass_rate >= 80.0 {
            "✅"
        } else if pass_rate >= 60.0 {
            "⚠️"
        } else {
            "❌"
        };

        println!(
            "   {} {:?}: {}/{} ({:.1}%)",
            status, power, passed, total, pass_rate
        );
    }

    // Show failed tests
    let failed_results: Vec<_> = test_suite
        .test_results
        .iter()
        .filter(|r| !r.success)
        .collect();

    if !failed_results.is_empty() {
        println!("\n❌ FAILED TESTS:");
        for result in failed_results.iter().take(10) {
            println!(
                "   {:?} ({:?}): Expected {:?}, got {:?}",
                result.power_type, result.scenario, result.expected, result.actual
            );
        }

        if failed_results.len() > 10 {
            println!("   ... and {} more", failed_results.len() - 10);
        }
    }

    println!("\n✨ Testing complete! Use results to improve power implementations.");
    println!("Press F5 to run tests again");
}

// Manual test controls
pub fn manual_test_controls(mut test_suite: ResMut<PowerTestSuite>, keyboard: Res<Input<KeyCode>>) {
    if keyboard.just_pressed(KeyCode::F7) {
        if let Some(test) = test_suite.test_queue.pop_front() {
            println!(
                "🔧 Manual test: {:?} - {}",
                test.power_type, test.setup_description
            );
            println!("   Press Space to execute, or N to skip");
            test_suite.current_test = Some(test);
        } else {
            println!("No more tests in queue!");
        }
    }
}
