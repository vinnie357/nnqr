use bevy::prelude::*;

mod components;
mod systems;
mod resources;

use systems::*;
use resources::*;

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
        .init_resource::<GameState>()
        .init_resource::<GameResult>()
        .add_systems(Startup, (setup_camera, setup_board, setup_pieces, setup_ui))
        .add_systems(Update, (
            handle_piece_selection, 
            handle_piece_movement, 
            check_win_condition,
            update_turn_indicator
        ))
        .run();
}

fn setup_camera(mut commands: Commands) {
    commands.spawn(Camera2dBundle::default());
}