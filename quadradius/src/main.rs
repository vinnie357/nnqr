#![allow(unused_variables)]
#![allow(dead_code)]
#![allow(clippy::too_many_arguments)]
#![allow(clippy::type_complexity)]

use bevy::diagnostic::FrameTimeDiagnosticsPlugin;
use bevy::prelude::*;

mod components;
mod resources;
mod systems;

use components::ChatState;
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
        .insert_resource(ClearColor(Color::rgb(0.05, 0.05, 0.1))) // Dark background to show light tiles
        .init_resource::<GameState>()
        .init_resource::<GameResult>()
        .init_resource::<RenderConfig>()
        .init_resource::<systems::performance_optimization::PerformanceMonitor>()
        .init_resource::<ScreenShake>()
        .init_resource::<MatchTimer>()
        .init_resource::<crate::resources::game_state::TurnCounter>()
        .init_resource::<GameBalanceData>()
        .init_resource::<PowerTestSuite>()
        .init_resource::<PowerBalanceConfig>()
        .init_resource::<PowerUsageTracker>()
        .init_resource::<AutoBalanceTest>()
        .init_resource::<PerformanceMonitor>()
        .init_resource::<AutomatedTestRunner>()
        .init_resource::<systems::power_orbs::LastTurnTracker>()
        .init_resource::<PowerSpawningTimer>()
        .init_resource::<ChatState>()
        .init_resource::<PowerSpawningTracker>()
        .init_resource::<systems::isometric_camera::CameraTransition>()
        .init_resource::<EffectProcessor>()
        .init_resource::<AreaTargetingState>()
        .add_state::<GameMenuState>()
        .add_state::<SettingsMenuState>()
        .add_event::<PowerUsageEvent>()
        .add_event::<GameEndEvent>()
        .add_systems(
            Startup,
            (
                // Always spawn both camera types
                setup_isometric_camera,
                setup_camera,
                // Enhanced 3D lighting system
                board_3d::setup_enhanced_lighting,
                // Always spawn both board types
                setup_board_3d,
                setup_board,
                // Always spawn both piece types
                setup_pieces_3d,
                setup_pieces,
                // Common systems
                setup_enhanced_ui,
                setup_power_activation_ui,
                setup_chat_ui,
                initialize_terrain_heights,
                initialize_turn_phase,
                setup_entity_pools,
                // setup_networking,
                // setup_client_server,
                // setup_lobby_system,
            ),
        )
        .add_systems(PostStartup, setup_initial_visibility)
        .add_systems(
            Update,
            (
                // Input and movement systems - 2D
                handle_drag_start.run_if(|config: Res<RenderConfig>| !config.use_3d),
                handle_drag_update.run_if(|config: Res<RenderConfig>| !config.use_3d),
                handle_drag_end
                    .run_if(|config: Res<RenderConfig>| !config.use_3d)
                    .before(update_turn_indicator),
                cleanup_indicators.run_if(|config: Res<RenderConfig>| !config.use_3d),
                // Input and movement systems - 3D (primary drag system)
                handle_drag_start_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                handle_drag_update_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                handle_drag_end_3d
                    .run_if(|config: Res<RenderConfig>| config.use_3d)
                    .before(update_turn_indicator),
                cleanup_indicators_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                // Alternative raycast-based piece selection (backup system)
                raycast_piece_selection.run_if(|config: Res<RenderConfig>| config.use_3d),
                // Piece visibility fixes
                fix_piece_visibility.run_if(|config: Res<RenderConfig>| config.use_3d),
                ensure_piece_visibility.run_if(|config: Res<RenderConfig>| config.use_3d),
                // Common systems
                align_pieces_to_grid,
                // Enhanced 3D move indicators - 3D takes precedence if enabled
                show_valid_moves_for_powers_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                show_valid_moves_for_powers.run_if(|config: Res<RenderConfig>| !config.use_3d),
                // Cleanup orphaned indicators when turn phase changes or no selection
                enhanced_move_indicators_3d::cleanup_orphaned_indicators_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
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
                handle_power_spawning_phase,
                power_spawning_phase_ui,
                // Effect processing systems (before turn indicator)
                reset_effect_processing,
                process_turn_effects,
                process_pending_effects,
                update_effect_indicators,
            ),
        )
        .add_systems(
            Update,
            (
                // Combat effects systems
                process_combat_with_effects,
                apply_invisibility_targeting,
                apply_frozen_movement_restriction,
                process_poison_death,
                apply_invisibility_rendering,
                apply_movement_enhancements,
                apply_recruitment_effects,
            ),
        )
        .add_systems(
            Update,
            (
                // UI and scoreboard systems
                update_turn_indicator_enhanced,
                update_power_inventory_ui,
                update_power_activation_ui,
                handle_chat_input,
                update_chat_display,
                toggle_chat_visibility,
                handle_chat_minimize_maximize,
                update_unread_indicator,
            ),
        )
        .add_systems(
            Update,
            (
                // Animation and utility systems
                add_demo_chat_messages,
                animate_ui_elements,
                show_power_tooltips,
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
                handle_area_targeting,
                cleanup_power_effects,
                // Power orb systems - 2D
                spawn_power_orbs
                    .run_if(|config: Res<RenderConfig>| !config.use_3d)
                    .before(update_power_activation_ui),
                collect_power_orbs.run_if(|config: Res<RenderConfig>| !config.use_3d),
                animate_power_orbs.run_if(|config: Res<RenderConfig>| !config.use_3d),
                // Power orb systems - 3D
                spawn_power_orbs_3d
                    .run_if(|config: Res<RenderConfig>| config.use_3d)
                    .before(update_power_activation_ui),
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
                update_power_activation_text,
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
        // Commented out for release builds to improve performance
        //.add_systems(
        //    Update,
        //    (
        //        // Debug systems
        //        debug_spawn_powers,
        //        debug_display_powers,
        //        generate_power_test_report,
        //        test_individual_power,
        //        // Crash debug systems
        //        debug_crash_scenarios,
        //        validate_game_safety,
        //        validate_entity_cleanup,
        //        detect_performance_crashes,
        //        show_debug_controls,
        //        // Automated testing systems
        //        start_automated_power_tests,
        //        run_automated_power_tests,
        //        show_automated_test_controls,
        //    ),
        //)
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

                // View switching system (always active)
                handle_view_switching,
                update_camera_transition,
                // 3D systems (conditional)
                update_isometric_camera.run_if(|config: Res<RenderConfig>| config.use_3d),
                update_tile_heights.run_if(|config: Res<RenderConfig>| config.use_3d),
                highlight_board_tiles.run_if(|config: Res<RenderConfig>| config.use_3d),
                update_piece_positions_3d.run_if(|config: Res<RenderConfig>| config.use_3d),
                update_piece_outlines.run_if(|config: Res<RenderConfig>| config.use_3d),
                animate_piece_outlines.run_if(|config: Res<RenderConfig>| config.use_3d),
                update_selection_highlighting.run_if(|config: Res<RenderConfig>| config.use_3d),
                // Depth sorting systems (conditional on 3D mode)
                setup_tile_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
                setup_piece_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
                setup_power_orb_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
                update_piece_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
                update_isometric_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
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
                // Debug systems
                debug_piece_count,
                // Temporary visibility debug systems
                systems::debug_visibility::debug_log_visible_entities,
                // systems::debug_visibility::force_piece_visibility, // DISABLED: This was forcing 2D pieces to magenta
                systems::debug_visibility::debug_3d_piece_positions,
                // Enhanced visual feedback systems
                systems::enhanced_visual_feedback::add_selection_feedback,
                systems::enhanced_visual_feedback::add_move_feedback,
                systems::enhanced_visual_feedback::update_pulse_animations,
                systems::enhanced_visual_feedback::add_hover_effects,
                systems::enhanced_visual_feedback::cleanup_visual_feedback,
                // Performance optimization systems
                systems::performance_optimization::monitor_performance,
                systems::performance_optimization::update_level_of_detail,
                systems::performance_optimization::optimize_visual_effects,
                debug_piece_selection,
                debug_mouse_clicks,
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
        .add_systems(OnEnter(SettingsMenuState::Visible), setup_settings_menu)
        .add_systems(OnExit(SettingsMenuState::Visible), cleanup_settings_menu)
        .add_systems(
            Update,
            (
                handle_menu_buttons.run_if(not(in_state(GameMenuState::Playing))),
                handle_settings_buttons.run_if(in_state(SettingsMenuState::Visible)),
                handle_board_view_change,
                synchronize_piece_representations,
                handle_pause_input,
            ),
        )
        .run();
}

fn setup_camera(mut commands: Commands) {
    commands.spawn((
        Camera2dBundle {
            projection: OrthographicProjection {
                scaling_mode: bevy::render::camera::ScalingMode::FixedVertical(800.0), // Increased to show more of the board
                ..default()
            },
            transform: Transform::from_xyz(0.0, 0.0, 999.9), // Center camera on board
            ..default()
        },
        crate::systems::settings::Camera2D,
    ));
}
