#![allow(unused_variables)]
#![allow(dead_code)]
#![allow(clippy::too_many_arguments)]
#![allow(clippy::type_complexity)]

use bevy::diagnostic::FrameTimeDiagnosticsPlugin;
use bevy::prelude::*;

mod components;
mod resources;
mod systems;

use resources::*;
use systems::win_condition::GameResult;
use systems::*;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Quadradius".into(),
                resolution: (800.0, 600.0).into(),
                ..default()
            }),
            ..default()
        }))
        .add_plugins((
            FrameTimeDiagnosticsPlugin,
            // LogDiagnosticsPlugin::default(), // Uncomment for console diagnostics
        ))
        .init_resource::<GameState>()
        .init_resource::<GameResult>()
        .init_resource::<RenderConfig>()
        .init_resource::<ScreenShake>()
        .init_resource::<MatchTimer>()
        .init_resource::<TurnCounter>()
        .init_resource::<GameBalanceData>()
        .init_resource::<PowerTestSuite>()
        .init_resource::<PowerBalanceConfig>()
        .init_resource::<PowerUsageTracker>()
        .init_resource::<AutoBalanceTest>()
        .init_resource::<PerformanceMonitor>()
        .init_resource::<AutomatedTestRunner>()
        .init_resource::<systems::power_orbs::LastTurnTracker>()
        .add_state::<GameMenuState>()
        .add_event::<PowerUsageEvent>()
        .add_event::<GameEndEvent>()
        .add_systems(
            Startup,
            (
                // Camera systems - 3D takes precedence if enabled
                setup_isometric_camera.run_if(|config: Res<RenderConfig>| config.use_3d),
                setup_camera.run_if(|config: Res<RenderConfig>| !config.use_3d),
                
                // Board systems - 3D takes precedence if enabled
                setup_board_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                setup_board.run_if(|config: Res<RenderConfig>| !config.use_3d),
                
                // Piece systems - 3D takes precedence if enabled
                setup_pieces_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                setup_pieces.run_if(|config: Res<RenderConfig>| !config.use_3d),
                
                // Common systems
                setup_ui,
                setup_enhanced_ui,
                setup_power_activation_ui,
                initialize_terrain_heights,
                setup_entity_pools,
                // setup_networking,
                // setup_client_server,
                // setup_lobby_system,
            ),
        )
        .add_systems(
            Update,
            (
                // Input and movement systems - 2D
                handle_drag_start.run_if(|config: Res<RenderConfig>| !config.use_3d),
                handle_drag_update.run_if(|config: Res<RenderConfig>| !config.use_3d),
                handle_drag_end.run_if(|config: Res<RenderConfig>| !config.use_3d).before(update_turn_indicator),
                cleanup_indicators.run_if(|config: Res<RenderConfig>| !config.use_3d),
                
                // Input and movement systems - 3D
                handle_drag_start_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                handle_drag_update_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                handle_drag_end_3d.run_if(|config: Res<RenderConfig>| config.use_3d).before(update_turn_indicator),
                cleanup_indicators_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                
                // Common systems
                align_pieces_to_grid,
                show_valid_moves_for_powers,
                cleanup_movement_powers,
            ),
        )
        .add_systems(
            Update,
            (
                // Feedback and animation systems
                animate_invalid_moves,
                flash_invalid_moves,
                spawn_invalid_move_text,
                update_invalid_move_text,
            ),
        )
        .add_systems(
            Update,
            (
                // Game state and UI systems
                check_win_condition,
                update_turn_indicator,
                update_turn_indicator_enhanced,
                update_power_inventory,
                update_power_inventory_ui,
                update_power_activation_ui,
                animate_ui_elements,
                show_power_tooltips,
                // Scoreboard systems
                update_piece_count,
                animate_score_changes,
                update_power_notifications,
                update_match_timer,
                increment_turn_counter,
            ),
        )
        .add_systems(
            Update,
            (
                // Power systems
                handle_power_button_interaction,
                handle_skip_button_interaction,
                handle_power_selection,
                handle_power_activation,
                cleanup_power_effects,
                
                // Power orb systems - 2D
                spawn_power_orbs.run_if(|config: Res<RenderConfig>| !config.use_3d).before(update_power_activation_ui),
                collect_power_orbs.run_if(|config: Res<RenderConfig>| !config.use_3d),
                animate_power_orbs.run_if(|config: Res<RenderConfig>| !config.use_3d),
                
                // Power orb systems - 3D
                spawn_power_orbs_3d.run_if(|config: Res<RenderConfig>| config.use_3d).before(update_power_activation_ui),
                collect_power_orbs_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                animate_power_orbs_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
            ),
        )
        .add_systems(
            Update,
            (
                // Visual effects systems
                update_particle_effects,
                update_floating_text,
                update_animated_scale,
                update_pulse_effects,
                update_screen_shake,
                enhance_power_orbs,
                // Enhanced board visuals - temporarily disabled
                // setup_enhanced_board,
                // animate_board_tiles,
                // enhance_piece_visuals,
                // update_piece_shadows,
                // update_piece_glow,
            ),
        )
        // Debug and testing systems only in debug builds - disabled for release
        .add_systems(
            Update,
            (
                // Debug systems
                debug_spawn_powers,
                debug_display_powers,
                generate_power_test_report,
                test_individual_power,
                // Crash debug systems
                debug_crash_scenarios,
                validate_game_safety,
                validate_entity_cleanup,
                detect_performance_crashes,
                show_debug_controls,
                // Automated testing systems
                start_automated_power_tests,
                run_automated_power_tests,
                show_automated_test_controls,
            ),
        )
        // Balance and testing systems - disabled for release
        //.add_systems(
        //    Update,
        //    (
        //        // Balance and testing systems
        //        track_power_usage,
        //        track_game_completion,
        //        generate_balance_report,
        //        analyze_power_effectiveness,
        //        analyze_power_spawn_balance,
        //        generate_balance_recommendations,
        //    ),
        //)
        //.add_systems(
        //    Update,
        //    (
        //        // Power testing systems
        //        setup_power_test_suite,
        //        start_automated_testing,
        //        execute_automated_tests,
        //        manual_test_controls,
        //    ),
        //)
        //.add_systems(
        //    Update,
        //    (
        //        // Power balance systems
        //        apply_dynamic_balance,
        //        enforce_power_limits,
        //        track_power_usage_for_balance,
        //        balance_mode_controls,
        //    ),
        //)
        .add_systems(
            Update,
            (
                // Terrain height systems
                update_terrain_visuals,
                update_height_sprite_colors,
                animate_terrain_changes,
                spawn_height_indicators,
                update_height_indicators,
                // debug_terrain_commands, // Temporarily disabled due to query conflicts
                
                // 3D systems (conditional)
                update_isometric_camera,
                update_tile_heights,
                highlight_board_tiles,
                update_piece_positions_3d,
            ),
        )
        .add_systems(
            Update,
            (
                // Performance monitoring systems
                monitor_performance,
                display_performance_stats,
                cleanup_entities,
                optimize_visual_effects,
                analyze_system_performance,
                auto_optimize_performance,
            ),
        )
        // Networking systems temporarily disabled for testing
        // .add_systems(
        //     Update,
        //     (
        //         update_networking,
        //         debug_network_commands,
        //         display_network_info,
        //         sync_game_state_to_clients,
        //         server_tick_update,
        //         client_prediction_update,
        //         handle_server_reconciliation,
        //         debug_client_server_commands,
        //         display_client_server_status,
        //         update_matchmaking,
        //         debug_lobby_commands,
        //     ),
        // )
        .add_systems(OnEnter(GameMenuState::MainMenu), setup_main_menu)
        .add_systems(OnEnter(GameMenuState::Paused), setup_pause_menu)
        .add_systems(OnEnter(GameMenuState::GameOver), setup_game_over_menu)
        .add_systems(OnExit(GameMenuState::MainMenu), cleanup_menu)
        .add_systems(OnExit(GameMenuState::Paused), cleanup_menu)
        .add_systems(OnExit(GameMenuState::GameOver), cleanup_menu)
        .add_systems(
            Update,
            (
                handle_menu_buttons.run_if(not(in_state(GameMenuState::Playing))),
                handle_pause_input,
            ),
        )
        .run();
}

fn setup_camera(mut commands: Commands) {
    commands.spawn(Camera2dBundle::default());
}
