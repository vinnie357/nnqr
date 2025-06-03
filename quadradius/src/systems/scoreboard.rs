use crate::{components::*, resources::*};
use bevy::prelude::*;

#[derive(Component)]
pub struct PieceCounter {
    pub player: Player,
}

#[derive(Component)]
pub struct ScoreText;

// Update piece count display
pub fn update_piece_count(
    pieces: Query<&GamePiece>,
    mut score_texts: Query<(&mut Text, &PieceCounter)>,
) {
    let mut player1_count = 0;
    let mut player2_count = 0;
    
    for piece in pieces.iter() {
        match piece.player {
            Player::Player1 => player1_count += 1,
            Player::Player2 => player2_count += 1,
        }
    }
    
    for (mut text, counter) in score_texts.iter_mut() {
        let count = match counter.player {
            Player::Player1 => player1_count,
            Player::Player2 => player2_count,
        };
        
        text.sections[0].value = format!("P{}: {}", 
            match counter.player {
                Player::Player1 => "1",
                Player::Player2 => "2",
            },
            count
        );
    }
}

// Create animated score change effect
#[derive(Component)]
pub struct ScoreChangeAnimation {
    pub start_value: i32,
    pub end_value: i32,
    pub duration: f32,
    pub elapsed: f32,
}

pub fn animate_score_changes(
    mut commands: Commands,
    time: Res<Time>,
    mut animated_scores: Query<(Entity, &mut Text, &mut ScoreChangeAnimation)>,
) {
    for (entity, mut text, mut animation) in animated_scores.iter_mut() {
        animation.elapsed += time.delta_seconds();
        
        if animation.elapsed >= animation.duration {
            text.sections[0].value = animation.end_value.to_string();
            commands.entity(entity).remove::<ScoreChangeAnimation>();
        } else {
            let progress = animation.elapsed / animation.duration;
            let current = animation.start_value as f32 + 
                (animation.end_value - animation.start_value) as f32 * progress;
            text.sections[0].value = (current as i32).to_string();
        }
    }
}

// Power collection notification
#[derive(Component)]
pub struct PowerNotification {
    pub lifetime: f32,
}

pub fn spawn_power_notification(
    commands: &mut Commands,
    power_type: PowerType,
    player: Player,
) {
    let player_color = match player {
        Player::Player1 => Color::rgb(0.9, 0.3, 0.3),
        Player::Player2 => Color::rgb(0.3, 0.3, 0.9),
    };
    
    commands
        .spawn((
            NodeBundle {
                style: Style {
                    position_type: PositionType::Absolute,
                    right: Val::Px(20.0),
                    top: Val::Px(100.0),
                    padding: UiRect::all(Val::Px(15.0)),
                    border: UiRect::all(Val::Px(2.0)),
                    ..default()
                },
                background_color: BackgroundColor(Color::rgba(0.1, 0.1, 0.15, 0.9)),
                border_color: BorderColor(power_type.color()),
                ..default()
            },
            PowerNotification { lifetime: 3.0 },
        ))
        .with_children(|parent| {
            parent.spawn(TextBundle::from_section(
                format!("Player {} collected {}", 
                    match player {
                        Player::Player1 => "1",
                        Player::Player2 => "2",
                    },
                    power_type.name()
                ),
                TextStyle {
                    font_size: 18.0,
                    color: player_color,
                    ..default()
                },
            ));
        });
}

pub fn update_power_notifications(
    mut commands: Commands,
    time: Res<Time>,
    mut notifications: Query<(Entity, &mut PowerNotification, &mut BackgroundColor)>,
) {
    for (entity, mut notification, mut bg_color) in notifications.iter_mut() {
        notification.lifetime -= time.delta_seconds();
        
        if notification.lifetime <= 0.0 {
            commands.entity(entity).despawn_recursive();
        } else if notification.lifetime < 1.0 {
            // Fade out
            bg_color.0.set_a(notification.lifetime * 0.9);
        }
    }
}

// Match timer
#[derive(Resource)]
pub struct MatchTimer {
    pub elapsed: f32,
}

impl Default for MatchTimer {
    fn default() -> Self {
        Self { elapsed: 0.0 }
    }
}

#[derive(Component)]
pub struct TimerDisplay;

pub fn update_match_timer(
    time: Res<Time>,
    mut timer: ResMut<MatchTimer>,
    mut timer_displays: Query<&mut Text, With<TimerDisplay>>,
) {
    timer.elapsed += time.delta_seconds();
    
    let minutes = (timer.elapsed / 60.0) as i32;
    let seconds = (timer.elapsed % 60.0) as i32;
    
    for mut text in timer_displays.iter_mut() {
        text.sections[0].value = format!("{:02}:{:02}", minutes, seconds);
    }
}

// Turn counter
#[derive(Resource)]
pub struct TurnCounter {
    pub turn_number: u32,
}

impl Default for TurnCounter {
    fn default() -> Self {
        Self { turn_number: 1 }
    }
}

pub fn increment_turn_counter(
    mut turn_counter: ResMut<TurnCounter>,
    game_state: Res<GameState>,
) {
    if game_state.is_changed() && game_state.turn_phase == TurnPhase::PowerActivation {
        turn_counter.turn_number += 1;
    }
}