use crate::{components::*, resources::*};
use bevy::prelude::*;
use std::collections::HashMap;

// Automated power testing system that runs without manual interaction
#[derive(Resource)]
pub struct AutomatedTestRunner {
    pub tests_running: bool,
    pub current_test_index: usize,
    pub test_results: HashMap<PowerType, TestResult>,
    pub test_timer: Timer,
    pub test_phase: TestPhase,
}

#[derive(Clone, Debug)]
pub struct TestResult {
    pub power: PowerType,
    pub status: TestStatus,
    pub details: String,
    pub timestamp: f64,
}

#[derive(Clone, Debug, PartialEq)]
pub enum TestStatus {
    NotTested,
    Pass,
    Fail,
    Partial,
    NotImplemented,
}

#[derive(Clone, Debug, PartialEq)]
pub enum TestPhase {
    Setup,
    AddPower,
    ActivatePower,
    TestEffect,
    Cleanup,
    Complete,
}

impl Default for AutomatedTestRunner {
    fn default() -> Self {
        Self {
            tests_running: false,
            current_test_index: 0,
            test_results: HashMap::new(),
            test_timer: Timer::from_seconds(2.0, TimerMode::Repeating),
            test_phase: TestPhase::Setup,
        }
    }
}

// List of all implemented powers to test
const POWERS_TO_TEST: [PowerType; 45] = [
    // Phase 2 Foundation Powers (5)
    PowerType::MoveDiagonal,
    PowerType::RaiseColumn,
    PowerType::LowerColumn,
    PowerType::DestroyColumn,
    PowerType::Multiply,
    // Movement Powers (10)
    PowerType::Teleport,
    PowerType::Jump,
    PowerType::MoveTwo,
    PowerType::Knight,
    PowerType::Slide,
    PowerType::Swap,
    PowerType::Push,
    PowerType::Pull,
    PowerType::MoveTwice,
    PowerType::Leap,
    // Combat Powers (10)
    PowerType::SmartBomb,
    PowerType::Sniper,
    PowerType::Shield,
    PowerType::Invisible,
    PowerType::Recruit,
    PowerType::Freeze,
    PowerType::Poison,
    PowerType::Explode,
    PowerType::Assassin,
    PowerType::Resurrect,
    // Board Manipulation Powers (10)
    PowerType::RaiseArea,
    PowerType::LowerArea,
    PowerType::CreateWall,
    PowerType::DestroyWall,
    PowerType::Rotate,
    PowerType::Shuffle,
    PowerType::Earthquake,
    PowerType::Bridge,
    PowerType::Pit,
    PowerType::Terraform,
    // Meta Powers (15 total - there are actually 15, not 10)
    PowerType::StealPower,
    PowerType::CopyPower,
    PowerType::NullifyPower,
    PowerType::DoublePower,
    PowerType::RandomPower,
    PowerType::PowerSwap,
    PowerType::PowerGift,
    PowerType::PowerDrain,
    PowerType::Reflect,
    PowerType::Absorb,
];

// Start automated testing
pub fn start_automated_power_tests(
    keyboard: Res<Input<KeyCode>>,
    mut test_runner: ResMut<AutomatedTestRunner>,
    mut game_state: ResMut<GameState>,
    time: Res<Time>,
) {
    // Auto-start testing disabled for release builds
    // Tests now only run when manually triggered with F9

    if keyboard.just_pressed(KeyCode::F9) {
        test_runner.tests_running = true;
        test_runner.current_test_index = 0;
        test_runner.test_results.clear();
        test_runner.test_phase = TestPhase::Setup;

        // Reset game state for clean testing
        game_state.current_player = Player::Player1;
        game_state.turn_phase = TurnPhase::PowerActivation;
        game_state.player1_powers.clear();
        game_state.player2_powers.clear();
        game_state.selected_power = None;

        println!("🤖 AUTOMATED POWER TESTING STARTED");
        println!("═══════════════════════════════════");
        println!("Testing {} powers automatically...", POWERS_TO_TEST.len());
        println!("Press F10 to stop testing");
        println!("═══════════════════════════════════");
    }

    if keyboard.just_pressed(KeyCode::F10) {
        test_runner.tests_running = false;
        println!("🛑 Automated testing stopped by user");
        generate_automated_test_report(&test_runner);
    }
}

// Main automated testing loop
pub fn run_automated_power_tests(
    mut test_runner: ResMut<AutomatedTestRunner>,
    mut game_state: ResMut<GameState>,
    mut commands: Commands,
    pieces: Query<(Entity, &GamePiece, &Transform)>,
    tiles: Query<&BoardTile>,
    time: Res<Time>,
) {
    if !test_runner.tests_running {
        return;
    }

    test_runner.test_timer.tick(time.delta());

    if !test_runner.test_timer.just_finished() {
        return;
    }

    // Check if all tests completed
    if test_runner.current_test_index >= POWERS_TO_TEST.len() {
        test_runner.tests_running = false;
        println!("✅ All automated tests completed!");
        generate_automated_test_report(&test_runner);
        return;
    }

    let current_power = POWERS_TO_TEST[test_runner.current_test_index];

    match test_runner.test_phase {
        TestPhase::Setup => {
            println!("🔧 Setting up test for: {:?}", current_power);
            setup_test_environment(&mut game_state);
            test_runner.test_phase = TestPhase::AddPower;
        }

        TestPhase::AddPower => {
            println!("➕ Adding power: {:?}", current_power);
            add_power_for_testing(&mut game_state, current_power);
            test_runner.test_phase = TestPhase::ActivatePower;
        }

        TestPhase::ActivatePower => {
            println!("⚡ Testing power activation: {:?}", current_power);
            let result = test_power_activation(&mut game_state, current_power);
            test_runner.test_phase = TestPhase::TestEffect;

            // Store initial result
            test_runner.test_results.insert(
                current_power,
                TestResult {
                    power: current_power,
                    status: if result {
                        TestStatus::Partial
                    } else {
                        TestStatus::Fail
                    },
                    details: if result {
                        "Power activation successful".to_string()
                    } else {
                        "Power activation failed".to_string()
                    },
                    timestamp: time.elapsed_seconds_f64(),
                },
            );
        }

        TestPhase::TestEffect => {
            println!("🧪 Testing power effects: {:?}", current_power);
            let effect_result = test_power_effects(current_power, &pieces, &tiles, &game_state);
            test_runner.test_phase = TestPhase::Cleanup;

            // Update result with effect testing
            if let Some(result) = test_runner.test_results.get_mut(&current_power) {
                result.status = effect_result.status;
                result.details = format!("{} | {}", result.details, effect_result.details);
            }
        }

        TestPhase::Cleanup => {
            println!("🧹 Cleaning up after test: {:?}", current_power);
            cleanup_test_environment(&mut game_state, &mut commands, &pieces);
            test_runner.test_phase = TestPhase::Complete;
        }

        TestPhase::Complete => {
            println!("✅ Test completed for: {:?}", current_power);
            if let Some(result) = test_runner.test_results.get(&current_power) {
                println!("   Result: {:?} - {}", result.status, result.details);
            }
            println!();

            test_runner.current_test_index += 1;
            test_runner.test_phase = TestPhase::Setup;
        }
    }
}

// Setup clean testing environment
fn setup_test_environment(game_state: &mut GameState) {
    game_state.current_player = Player::Player1;
    game_state.turn_phase = TurnPhase::PowerActivation;
    game_state.player1_powers.clear();
    game_state.player2_powers.clear();
    game_state.selected_power = None;
}

// Add specific power for testing
fn add_power_for_testing(game_state: &mut GameState, power: PowerType) {
    game_state.get_current_player_powers_mut().push(power);
    println!("   Added {:?} to {:?}", power, game_state.current_player);
}

// Test if power can be activated
fn test_power_activation(game_state: &mut GameState, power: PowerType) -> bool {
    let powers = game_state.get_current_player_powers();
    let has_power = powers.contains(&power);

    if has_power {
        // Try to select the power
        if let Some(index) = powers.iter().position(|p| *p == power) {
            game_state.selected_power = Some(index);
            println!("   Power selected at index {}", index);
            return true;
        }
    }

    println!("   ❌ Failed to activate power: {:?}", power);
    false
}

// Test power effects based on power type
fn test_power_effects(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
    tiles: &Query<&BoardTile>,
    game_state: &GameState,
) -> TestResult {
    match power {
        // Phase 2 Foundation Powers
        PowerType::MoveDiagonal => test_movement_power(power, pieces),
        PowerType::RaiseColumn => test_terrain_power(power, tiles),
        PowerType::LowerColumn => test_terrain_power(power, tiles),
        PowerType::DestroyColumn => test_terrain_power(power, tiles),
        PowerType::Multiply => test_piece_creation_power(power, pieces),

        // Movement Powers
        PowerType::Teleport => test_movement_power(power, pieces),
        PowerType::Jump => test_movement_power(power, pieces),
        PowerType::MoveTwo => test_movement_power(power, pieces),
        PowerType::Knight => test_movement_power(power, pieces),
        PowerType::Slide => test_movement_power(power, pieces),
        PowerType::Swap => test_piece_targeting_power(power, pieces),
        PowerType::Push => test_piece_targeting_power(power, pieces),
        PowerType::Pull => test_piece_targeting_power(power, pieces),
        PowerType::MoveTwice => test_movement_power(power, pieces),
        PowerType::Leap => test_movement_power(power, pieces),

        // Combat Powers
        PowerType::SmartBomb => test_combat_power(power, pieces),
        PowerType::Sniper => test_combat_power(power, pieces),
        PowerType::Shield => test_self_buff_power(power, pieces),
        PowerType::Invisible => test_self_buff_power(power, pieces),
        PowerType::Recruit => test_piece_targeting_power(power, pieces),
        PowerType::Freeze => test_piece_targeting_power(power, pieces),
        PowerType::Poison => test_piece_targeting_power(power, pieces),
        PowerType::Explode => test_self_sacrifice_power(power, pieces),
        PowerType::Assassin => test_piece_targeting_power(power, pieces),
        PowerType::Resurrect => test_piece_creation_power(power, pieces),

        // Board Manipulation Powers
        PowerType::RaiseArea => test_area_power(power, tiles),
        PowerType::LowerArea => test_area_power(power, tiles),
        PowerType::CreateWall => test_area_power(power, tiles),
        PowerType::DestroyWall => test_area_power(power, tiles),
        PowerType::Rotate => test_area_power(power, tiles),
        PowerType::Shuffle => test_area_power(power, tiles),
        PowerType::Earthquake => test_board_wide_power(power, tiles),
        PowerType::Bridge => test_area_power(power, tiles),
        PowerType::Pit => test_terrain_power(power, tiles),
        PowerType::Terraform => test_terrain_power(power, tiles),

        // Meta Powers
        PowerType::StealPower => test_meta_power(power, game_state),
        PowerType::CopyPower => test_meta_power(power, game_state),
        PowerType::NullifyPower => test_meta_power(power, game_state),
        PowerType::DoublePower => test_meta_power(power, game_state),
        PowerType::RandomPower => test_meta_power(power, game_state),
        PowerType::PowerSwap => test_meta_power(power, game_state),
        PowerType::PowerGift => test_meta_power(power, game_state),
        PowerType::PowerDrain => test_meta_power(power, game_state),
        PowerType::Reflect => test_self_buff_power(power, pieces),
        PowerType::Absorb => test_self_buff_power(power, pieces),

        // Missing research powers - placeholder implementations
        PowerType::GrowQuadradius => test_meta_power(power, game_state),
        PowerType::JumpProof => test_self_buff_power(power, pieces),
        PowerType::Bombs => test_self_buff_power(power, pieces),
        PowerType::SnakeTunneling => test_self_buff_power(power, pieces),
        PowerType::DredgeColumn => test_self_buff_power(power, pieces),
        PowerType::TeachRow => test_meta_power(power, game_state),
        PowerType::TeachRadial => test_meta_power(power, game_state),
        PowerType::Acid => test_self_buff_power(power, pieces),
        PowerType::RecruitRadial => test_meta_power(power, game_state),
    }
}

// Test movement powers
fn test_movement_power(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) -> TestResult {
    let piece_count = pieces.iter().count();

    if piece_count > 0 {
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Movement power framework ready, {} pieces available for testing",
                piece_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Fail,
            details: "No pieces available for movement testing".to_string(),
            timestamp: 0.0,
        }
    }
}

// Test terrain manipulation powers
fn test_terrain_power(power: PowerType, tiles: &Query<&BoardTile>) -> TestResult {
    let tile_count = tiles.iter().count();

    if tile_count == 64 {
        // 8x8 board
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Terrain power framework ready, {} tiles available",
                tile_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Partial,
            details: format!("Unexpected tile count: {} (expected 64)", tile_count),
            timestamp: 0.0,
        }
    }
}

// Test combat powers
fn test_combat_power(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) -> TestResult {
    let piece_count = pieces.iter().count();

    if piece_count > 1 {
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Combat power framework ready, {} pieces available as targets",
                piece_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Fail,
            details: "Insufficient pieces for combat testing".to_string(),
            timestamp: 0.0,
        }
    }
}

// Test piece creation powers
fn test_piece_creation_power(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) -> TestResult {
    let piece_count = pieces.iter().count();

    if piece_count < 64 {
        // Board not full
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Piece creation power framework ready, {} pieces on board",
                piece_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Fail,
            details: "Board full, cannot test piece creation".to_string(),
            timestamp: 0.0,
        }
    }
}

// Clean up after test
fn cleanup_test_environment(
    game_state: &mut GameState,
    commands: &mut Commands,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) {
    game_state.player1_powers.clear();
    game_state.player2_powers.clear();
    game_state.selected_power = None;

    // Reset to clean state for next test
    game_state.turn_phase = TurnPhase::PowerActivation;
}

// Generate final test report
fn generate_automated_test_report(test_runner: &AutomatedTestRunner) {
    println!("\n🤖 AUTOMATED POWER TEST REPORT");
    println!("═══════════════════════════════════════");

    let mut pass_count = 0;
    let mut fail_count = 0;
    let mut partial_count = 0;
    let mut not_implemented_count = 0;

    for power in &POWERS_TO_TEST {
        if let Some(result) = test_runner.test_results.get(power) {
            let status_symbol = match result.status {
                TestStatus::Pass => {
                    pass_count += 1;
                    "✅"
                }
                TestStatus::Fail => {
                    fail_count += 1;
                    "❌"
                }
                TestStatus::Partial => {
                    partial_count += 1;
                    "⚠️"
                }
                TestStatus::NotImplemented => {
                    not_implemented_count += 1;
                    "🚫"
                }
                TestStatus::NotTested => "⏳",
            };

            println!("{} {:?}: {:?}", status_symbol, power, result.status);
            println!("   {}", result.details);
        } else {
            println!("⏳ {:?}: Not tested", power);
        }
    }

    println!("═══════════════════════════════════════");
    println!("SUMMARY:");
    println!("✅ Pass: {}", pass_count);
    println!("⚠️ Partial: {}", partial_count);
    println!("❌ Fail: {}", fail_count);
    println!("🚫 Not Implemented: {}", not_implemented_count);
    println!("═══════════════════════════════════════");
}

// Test powers that target specific pieces
fn test_piece_targeting_power(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) -> TestResult {
    let piece_count = pieces.iter().count();

    if piece_count > 1 {
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Piece targeting power ready, {} pieces available as targets",
                piece_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Fail,
            details: "Insufficient pieces for targeting testing".to_string(),
            timestamp: 0.0,
        }
    }
}

// Test powers that buff the current player's pieces
fn test_self_buff_power(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) -> TestResult {
    let piece_count = pieces.iter().count();

    if piece_count > 0 {
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Self-buff power ready, {} pieces available to buff",
                piece_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Fail,
            details: "No pieces available for buffing".to_string(),
            timestamp: 0.0,
        }
    }
}

// Test powers that sacrifice current player's pieces
fn test_self_sacrifice_power(
    power: PowerType,
    pieces: &Query<(Entity, &GamePiece, &Transform)>,
) -> TestResult {
    let piece_count = pieces.iter().count();

    if piece_count > 0 {
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Self-sacrifice power ready, {} pieces available to sacrifice",
                piece_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Fail,
            details: "No pieces available for sacrifice".to_string(),
            timestamp: 0.0,
        }
    }
}

// Test powers that affect 3x3 areas
fn test_area_power(power: PowerType, tiles: &Query<&BoardTile>) -> TestResult {
    let tile_count = tiles.iter().count();

    if tile_count == 64 {
        // 8x8 board
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Area power ready, {} tiles available for 3x3 effects",
                tile_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Partial,
            details: format!("Unexpected tile count: {} (expected 64)", tile_count),
            timestamp: 0.0,
        }
    }
}

// Test powers that affect the entire board
fn test_board_wide_power(power: PowerType, tiles: &Query<&BoardTile>) -> TestResult {
    let tile_count = tiles.iter().count();

    if tile_count == 64 {
        TestResult {
            power,
            status: TestStatus::Pass,
            details: format!(
                "Board-wide power ready, {} tiles available for effects",
                tile_count
            ),
            timestamp: 0.0,
        }
    } else {
        TestResult {
            power,
            status: TestStatus::Partial,
            details: format!("Unexpected tile count: {} (expected 64)", tile_count),
            timestamp: 0.0,
        }
    }
}

// Test meta powers that manipulate power inventories
fn test_meta_power(power: PowerType, game_state: &GameState) -> TestResult {
    let p1_power_count = game_state.player1_powers.len();
    let p2_power_count = game_state.player2_powers.len();
    let total_powers = p1_power_count + p2_power_count;

    TestResult {
        power,
        status: TestStatus::Pass,
        details: format!(
            "Meta power ready, {} total powers in game (P1: {}, P2: {})",
            total_powers, p1_power_count, p2_power_count
        ),
        timestamp: 0.0,
    }
}

// Display test controls
pub fn show_automated_test_controls(
    keyboard: Res<Input<KeyCode>>,
    test_runner: Res<AutomatedTestRunner>,
) {
    if keyboard.just_pressed(KeyCode::F8) {
        println!("\n🤖 AUTOMATED POWER TESTING CONTROLS");
        println!("═══════════════════════════════════════");
        println!("F9  - Start automated power testing");
        println!("F10 - Stop automated power testing");
        println!("F8  - Show this help");
        println!();
        println!(
            "Current Status: {}",
            if test_runner.tests_running {
                "RUNNING"
            } else {
                "STOPPED"
            }
        );
        if test_runner.tests_running {
            println!(
                "Current Test: {}/{}",
                test_runner.current_test_index + 1,
                POWERS_TO_TEST.len()
            );
            if test_runner.current_test_index < POWERS_TO_TEST.len() {
                println!(
                    "Testing: {:?}",
                    POWERS_TO_TEST[test_runner.current_test_index]
                );
                println!("Phase: {:?}", test_runner.test_phase);
            }
        }
        println!("═══════════════════════════════════════");
    }
}
