use crate::resources::render_config::RenderConfig;
use bevy::prelude::*;

// Settings menu state
#[derive(States, Debug, Clone, PartialEq, Eq, Hash, Default)]
pub enum SettingsMenuState {
    #[default]
    Hidden,
    Visible,
}

// Settings menu components
#[derive(Component)]
pub struct SettingsMenu;

#[derive(Component)]
pub struct SettingsButton {
    pub action: SettingsAction,
}

#[derive(Clone, Copy)]
pub enum SettingsAction {
    ToggleBoardView,
    Back,
}

#[derive(Component)]
pub struct BoardViewLabel;

// Setup settings menu
pub fn setup_settings_menu(mut commands: Commands, render_config: Res<RenderConfig>) {
    let board_view_text = if render_config.use_3d {
        "Board View: 3D Isometric"
    } else {
        "Board View: 2D Top-Down"
    };

    commands
        .spawn((
            NodeBundle {
                style: Style {
                    width: Val::Percent(100.0),
                    height: Val::Percent(100.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    ..default()
                },
                background_color: BackgroundColor(Color::rgb(0.05, 0.05, 0.1)),
                ..default()
            },
            SettingsMenu,
        ))
        .with_children(|parent| {
            // Title
            parent.spawn(TextBundle {
                text: Text::from_section(
                    "SETTINGS",
                    TextStyle {
                        font_size: 48.0,
                        color: Color::rgb(0.9, 0.9, 0.95),
                        ..default()
                    },
                ),
                style: Style {
                    position_type: PositionType::Absolute,
                    top: Val::Percent(15.0),
                    ..default()
                },
                ..default()
            });

            // Settings container
            parent
                .spawn(NodeBundle {
                    style: Style {
                        flex_direction: FlexDirection::Column,
                        align_items: AlignItems::Center,
                        row_gap: Val::Px(30.0),
                        ..default()
                    },
                    ..default()
                })
                .with_children(|parent| {
                    // Board view toggle section
                    parent
                        .spawn(NodeBundle {
                            style: Style {
                                flex_direction: FlexDirection::Column,
                                align_items: AlignItems::Center,
                                row_gap: Val::Px(15.0),
                                ..default()
                            },
                            ..default()
                        })
                        .with_children(|parent| {
                            // Board view label
                            parent.spawn((
                                TextBundle::from_section(
                                    board_view_text,
                                    TextStyle {
                                        font_size: 24.0,
                                        color: Color::rgb(0.8, 0.8, 0.9),
                                        ..default()
                                    },
                                ),
                                BoardViewLabel,
                            ));

                            // Toggle button
                            spawn_settings_button(
                                parent,
                                "Switch View",
                                SettingsAction::ToggleBoardView,
                            );
                        });

                    // Back button
                    spawn_settings_button(parent, "Back", SettingsAction::Back);
                });

            // Instructions
            parent.spawn(TextBundle {
                text: Text::from_section(
                    "Switch between 2D top-down and 3D isometric views",
                    TextStyle {
                        font_size: 16.0,
                        color: Color::rgb(0.6, 0.6, 0.7),
                        ..default()
                    },
                ),
                style: Style {
                    position_type: PositionType::Absolute,
                    bottom: Val::Px(60.0),
                    ..default()
                },
                ..default()
            });
        });
}

fn spawn_settings_button(parent: &mut ChildBuilder, text: &str, action: SettingsAction) {
    parent
        .spawn((
            ButtonBundle {
                style: Style {
                    width: Val::Px(250.0),
                    height: Val::Px(60.0),
                    justify_content: JustifyContent::Center,
                    align_items: AlignItems::Center,
                    border: UiRect::all(Val::Px(3.0)),
                    ..default()
                },
                background_color: BackgroundColor(Color::rgb(0.15, 0.15, 0.2)),
                border_color: BorderColor(Color::rgb(0.4, 0.4, 0.5)),
                ..default()
            },
            SettingsButton { action },
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                text,
                TextStyle {
                    font_size: 28.0,
                    color: Color::rgb(0.9, 0.9, 0.9),
                    ..default()
                },
            ));
        });
}

// Handle settings button interactions
pub fn handle_settings_buttons(
    mut interaction_query: Query<
        (&Interaction, &SettingsButton, &mut BackgroundColor),
        Changed<Interaction>,
    >,
    mut render_config: ResMut<RenderConfig>,
    mut board_view_query: Query<&mut Text, With<BoardViewLabel>>,
    mut next_settings_state: ResMut<NextState<SettingsMenuState>>,
    mut next_menu_state: ResMut<NextState<crate::systems::game_menu::GameMenuState>>,
) {
    for (interaction, button, mut background) in interaction_query.iter_mut() {
        match *interaction {
            Interaction::Pressed => {
                match button.action {
                    SettingsAction::ToggleBoardView => {
                        // Toggle the board view
                        render_config.use_3d = !render_config.use_3d;

                        // Update the label text
                        if let Ok(mut text) = board_view_query.get_single_mut() {
                            text.sections[0].value = if render_config.use_3d {
                                "Board View: 3D Isometric".to_string()
                            } else {
                                "Board View: 2D Top-Down".to_string()
                            };
                        }

                        info!(
                            "Board view toggled to: {}",
                            if render_config.use_3d {
                                "3D Isometric"
                            } else {
                                "2D Top-Down"
                            }
                        );
                    }
                    SettingsAction::Back => {
                        next_settings_state.set(SettingsMenuState::Hidden);
                        next_menu_state.set(crate::systems::game_menu::GameMenuState::MainMenu);
                    }
                }
            }
            Interaction::Hovered => {
                background.0 = Color::rgb(0.25, 0.25, 0.35);
            }
            Interaction::None => {
                background.0 = Color::rgb(0.15, 0.15, 0.2);
            }
        }
    }
}

// Cleanup settings menu
pub fn cleanup_settings_menu(
    mut commands: Commands,
    settings_query: Query<Entity, With<SettingsMenu>>,
) {
    for entity in settings_query.iter() {
        commands.entity(entity).despawn_recursive();
    }
}

// System to handle board view changes and trigger re-rendering
pub fn handle_board_view_change(
    render_config: Res<RenderConfig>,
    mut visibility_queries: ParamSet<(
        Query<&mut Visibility, With<crate::components::Board>>,
        Query<&mut Visibility, With<crate::systems::board_3d::BoardTile3D>>,
        Query<&mut Visibility, With<crate::components::GamePiece>>,
        Query<&mut Visibility, With<crate::systems::pieces_3d::GamePiece3D>>,
        Query<&mut Visibility, With<crate::components::PowerOrb>>,
        Query<&mut Visibility, With<crate::systems::power_orbs_3d::PowerOrb3D>>,
    )>,
    mut camera_2d_query: Query<&mut Camera, (With<Camera2D>, Without<Camera3D>)>,
    mut camera_3d_query: Query<&mut Camera, (With<Camera3D>, Without<Camera2D>)>,
) {
    if render_config.is_changed() {
        if render_config.use_3d {
            // Show 3D entities, hide 2D entities
            for mut visibility in visibility_queries.p0().iter_mut() {
                *visibility = Visibility::Hidden;
            }
            for mut visibility in visibility_queries.p1().iter_mut() {
                *visibility = Visibility::Visible;
            }
            for mut visibility in visibility_queries.p2().iter_mut() {
                *visibility = Visibility::Hidden;
            }
            for mut visibility in visibility_queries.p3().iter_mut() {
                *visibility = Visibility::Visible;
            }
            for mut visibility in visibility_queries.p4().iter_mut() {
                *visibility = Visibility::Hidden;
            }
            for mut visibility in visibility_queries.p5().iter_mut() {
                *visibility = Visibility::Visible;
            }

            // Enable 3D camera, disable 2D camera
            for mut camera in camera_2d_query.iter_mut() {
                camera.is_active = false;
            }
            for mut camera in camera_3d_query.iter_mut() {
                camera.is_active = true;
            }
        } else {
            // Show 2D entities, hide 3D entities
            for mut visibility in visibility_queries.p0().iter_mut() {
                *visibility = Visibility::Visible;
            }
            for mut visibility in visibility_queries.p1().iter_mut() {
                *visibility = Visibility::Hidden;
            }
            for mut visibility in visibility_queries.p2().iter_mut() {
                *visibility = Visibility::Visible;
            }
            for mut visibility in visibility_queries.p3().iter_mut() {
                *visibility = Visibility::Hidden;
            }
            for mut visibility in visibility_queries.p4().iter_mut() {
                *visibility = Visibility::Visible;
            }
            for mut visibility in visibility_queries.p5().iter_mut() {
                *visibility = Visibility::Hidden;
            }

            // Enable 2D camera, disable 3D camera
            for mut camera in camera_2d_query.iter_mut() {
                camera.is_active = true;
            }
            for mut camera in camera_3d_query.iter_mut() {
                camera.is_active = false;
            }
        }
    }
}

// Component to mark cameras for different views
#[derive(Component)]
pub struct Camera2D;

#[derive(Component)]
pub struct Camera3D;

// Setup initial visibility based on render config
pub fn setup_initial_visibility(
    render_config: Res<RenderConfig>,
    mut visibility_queries: ParamSet<(
        Query<&mut Visibility, With<crate::components::Board>>,
        Query<&mut Visibility, With<crate::systems::board_3d::BoardTile3D>>,
        Query<&mut Visibility, With<crate::components::GamePiece>>,
        Query<&mut Visibility, With<crate::systems::pieces_3d::GamePiece3D>>,
        Query<&mut Visibility, With<crate::components::PowerOrb>>,
        Query<&mut Visibility, With<crate::systems::power_orbs_3d::PowerOrb3D>>,
    )>,
    mut camera_2d_query: Query<&mut Camera, (With<Camera2D>, Without<Camera3D>)>,
    mut camera_3d_query: Query<&mut Camera, (With<Camera3D>, Without<Camera2D>)>,
) {
    if render_config.use_3d {
        // Show 3D entities, hide 2D entities
        for mut visibility in visibility_queries.p0().iter_mut() {
            *visibility = Visibility::Hidden;
        }
        for mut visibility in visibility_queries.p1().iter_mut() {
            *visibility = Visibility::Visible;
        }
        for mut visibility in visibility_queries.p2().iter_mut() {
            *visibility = Visibility::Hidden;
        }
        for mut visibility in visibility_queries.p3().iter_mut() {
            *visibility = Visibility::Visible;
        }
        for mut visibility in visibility_queries.p4().iter_mut() {
            *visibility = Visibility::Hidden;
        }
        for mut visibility in visibility_queries.p5().iter_mut() {
            *visibility = Visibility::Visible;
        }

        // Enable 3D camera, disable 2D camera
        for mut camera in camera_2d_query.iter_mut() {
            camera.is_active = false;
        }
        for mut camera in camera_3d_query.iter_mut() {
            camera.is_active = true;
        }
    } else {
        // Show 2D entities, hide 3D entities
        for mut visibility in visibility_queries.p0().iter_mut() {
            *visibility = Visibility::Visible;
        }
        for mut visibility in visibility_queries.p1().iter_mut() {
            *visibility = Visibility::Hidden;
        }
        for mut visibility in visibility_queries.p2().iter_mut() {
            *visibility = Visibility::Visible;
        }
        for mut visibility in visibility_queries.p3().iter_mut() {
            *visibility = Visibility::Hidden;
        }
        for mut visibility in visibility_queries.p4().iter_mut() {
            *visibility = Visibility::Visible;
        }
        for mut visibility in visibility_queries.p5().iter_mut() {
            *visibility = Visibility::Hidden;
        }

        // Enable 2D camera, disable 3D camera
        for mut camera in camera_2d_query.iter_mut() {
            camera.is_active = true;
        }
        for mut camera in camera_3d_query.iter_mut() {
            camera.is_active = false;
        }
    }
}

// System to synchronize pieces between 2D and 3D representations
pub fn synchronize_piece_representations(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    pieces_2d: Query<
        (Entity, &crate::components::GamePiece),
        Without<crate::systems::pieces_3d::GamePiece3D>,
    >,
    pieces_3d: Query<
        (Entity, &crate::systems::pieces_3d::GamePiece3D),
        Without<crate::components::GamePiece>,
    >,
    all_pieces_2d: Query<&crate::components::GamePiece>,
    all_pieces_3d: Query<&crate::systems::pieces_3d::GamePiece3D>,
    render_config: Res<RenderConfig>,
) {
    // Create missing 3D pieces for existing 2D pieces
    for (entity_2d, piece_2d) in pieces_2d.iter() {
        // Check if a 3D version already exists at this position
        let has_3d_counterpart = all_pieces_3d.iter().any(|p3d| {
            p3d.board_position == piece_2d.board_position && p3d.player == piece_2d.player
        });

        if !has_3d_counterpart {
            spawn_3d_piece_for_2d(&mut commands, &mut meshes, &mut materials, piece_2d);
        }
    }

    // Create missing 2D pieces for existing 3D pieces
    for (entity_3d, piece_3d) in pieces_3d.iter() {
        // Check if a 2D version already exists at this position
        let has_2d_counterpart = all_pieces_2d.iter().any(|p2d| {
            p2d.board_position == piece_3d.board_position && p2d.player == piece_3d.player
        });

        if !has_2d_counterpart {
            spawn_2d_piece_for_3d(&mut commands, piece_3d);
        }
    }
}

fn spawn_3d_piece_for_2d(
    commands: &mut Commands,
    meshes: &mut ResMut<Assets<Mesh>>,
    materials: &mut ResMut<Assets<StandardMaterial>>,
    piece_2d: &crate::components::GamePiece,
) {
    use crate::components::TILE_SIZE;
    use crate::resources::QuadradiusTheme;
    use crate::systems::depth_sorting::{IsometricDepthSort, PIECE_LAYER};
    use crate::systems::isometric_camera::board_to_isometric;
    use crate::systems::pieces_3d::GamePiece3D;

    // Create meshes for the 3D piece
    let piece_mesh = meshes.add(Mesh::from(shape::Cylinder {
        radius: TILE_SIZE * 0.35,
        height: TILE_SIZE * 0.15,
        resolution: 32,
        segments: 1,
    }));

    let rim_mesh = meshes.add(Mesh::from(shape::Torus {
        radius: TILE_SIZE * 0.32,
        ring_radius: TILE_SIZE * 0.03,
        subdivisions_segments: 24,
        subdivisions_sides: 12,
    }));

    // Create materials
    let base_color = match piece_2d.player {
        crate::components::Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
        crate::components::Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
    };

    let piece_material = materials.add(StandardMaterial {
        base_color,
        metallic: 0.8,
        perceptual_roughness: 0.2,
        ..default()
    });

    let rim_material = materials.add(StandardMaterial {
        base_color: Color::rgb(0.9, 0.9, 0.95),
        metallic: 0.9,
        perceptual_roughness: 0.1,
        ..default()
    });

    // Calculate 3D position with proper Y offset for enhanced tiles
    let world_pos = board_to_isometric(piece_2d.board_position, 0.0);
    let enhanced_tile_size = TILE_SIZE * 1.5; // TILE_SIZE_MULTIPLIER_3D
    let piece_y_offset = enhanced_tile_size * (0.6 / 2.0 + 0.2 / 2.0 + 0.2); // tile_height/2 + piece_height/2 + clearance
    let piece_position = Vec3::new(world_pos.x, world_pos.y + piece_y_offset, world_pos.z);

    // Spawn the 3D piece
    commands.spawn((
        GamePiece3D {
            player: piece_2d.player,
            board_position: piece_2d.board_position,
        },
        PbrBundle {
            mesh: piece_mesh,
            material: piece_material,
            transform: Transform::from_translation(piece_position),
            visibility: Visibility::Hidden, // Start hidden, will be shown by visibility system if needed
            ..default()
        },
        IsometricDepthSort {
            grid_x: piece_2d.board_position.0 as f32,
            grid_y: piece_2d.board_position.1 as f32,
            height: 0.0,
            layer_offset: PIECE_LAYER,
        },
    ));
}

fn spawn_2d_piece_for_3d(
    commands: &mut Commands,
    piece_3d: &crate::systems::pieces_3d::GamePiece3D,
) {
    use crate::components::{GamePiece, BOARD_HEIGHT, BOARD_WIDTH, TILE_SIZE};
    use crate::resources::QuadradiusTheme;

    let color = match piece_3d.player {
        crate::components::Player::Player1 => QuadradiusTheme::TEAM_1_PRIMARY,
        crate::components::Player::Player2 => QuadradiusTheme::TEAM_2_PRIMARY,
    };

    // Use same enhanced tile size as board for proper alignment - match 3D version
    let enhanced_tile_size = TILE_SIZE * 1.2;
    let world_x =
        (piece_3d.board_position.0 as f32 - BOARD_WIDTH as f32 / 2.0 + 0.5) * enhanced_tile_size;
    let world_y =
        (piece_3d.board_position.1 as f32 - BOARD_HEIGHT as f32 / 2.0 + 0.5) * enhanced_tile_size;

    commands.spawn((
        GamePiece {
            player: piece_3d.player,
            board_position: piece_3d.board_position,
        },
        SpriteBundle {
            sprite: Sprite {
                color,
                custom_size: Some(Vec2::splat(enhanced_tile_size * 0.8)),
                ..default()
            },
            transform: Transform::from_xyz(world_x, world_y, 1.0),
            visibility: Visibility::Hidden, // Start hidden, will be shown by visibility system if needed
            ..default()
        },
    ));
}
