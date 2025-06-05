use crate::{components::*, resources::*};
use bevy::prelude::*;

// Components for movement power effects
#[derive(Component)]
pub struct TeleportActive;

#[derive(Component)]
pub struct JumpActive;

#[derive(Component)]
pub struct MoveTwoActive;

#[derive(Component)]
pub struct KnightMoveActive;

#[derive(Component)]
pub struct MoveTwiceActive {
    pub moves_remaining: u8,
}

// Activation functions for movement powers
pub fn activate_teleport(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    // Add TeleportActive to all current player's pieces
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            commands.entity(entity).insert(TeleportActive);
        }
    }
}

pub fn activate_jump(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            commands.entity(entity).insert(JumpActive);
        }
    }
}

pub fn activate_move_two(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            commands.entity(entity).insert(MoveTwoActive);
        }
    }
}

pub fn activate_knight(
    commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    for (entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            commands.entity(entity).insert(KnightMoveActive);
        }
    }
}

pub fn activate_swap(
    _commands: &mut Commands,
    target_pos: (u8, u8),
    game_state: &GameState,
    pieces: &Query<(Entity, &mut GamePiece, &mut Transform)>,
) -> bool {
    // Find pieces at current position and target position
    let mut source_piece = None;
    let mut target_piece = None;

    for (entity, piece, transform) in pieces.iter() {
        if piece.player == game_state.current_player && source_piece.is_none() {
            source_piece = Some((entity, piece.board_position, transform.translation));
        }
        if piece.board_position == target_pos {
            target_piece = Some((entity, piece.board_position, transform.translation));
        }
    }

    // If we have both pieces, swap their positions
    if let (Some((_source_entity, source_pos, _)), Some((_target_entity, target_pos, _))) =
        (source_piece, target_piece)
    {
        // This would need mutable access - in real implementation, use events
        println!("Swapping pieces at {:?} and {:?}", source_pos, target_pos);
        true
    } else {
        false
    }
}

pub fn activate_push(
    _commands: &mut Commands,
    target_pos: (u8, u8),
    direction: (i8, i8),
    pieces: &Query<(Entity, &GamePiece)>,
    _tiles: &Query<&BoardTile>,
) -> bool {
    // Find piece at target position
    for (_entity, piece) in pieces.iter() {
        if piece.board_position == target_pos {
            // Calculate push destination
            let push_to = (
                (target_pos.0 as i8 + direction.0) as u8,
                (target_pos.1 as i8 + direction.1) as u8,
            );

            // Check if destination is valid and empty
            if push_to.0 < BOARD_SIZE && push_to.1 < BOARD_SIZE {
                let occupied = pieces.iter().any(|(_, p)| p.board_position == push_to);
                if !occupied {
                    // Apply push effect
                    println!("Pushing piece from {:?} to {:?}", target_pos, push_to);
                    return true;
                }
            }
        }
    }
    false
}

pub fn activate_pull(
    _commands: &mut Commands,
    puller_pos: (u8, u8),
    target_pos: (u8, u8),
    pieces: &Query<(Entity, &GamePiece)>,
) -> bool {
    // Calculate direction from target to puller
    let dx = puller_pos.0 as i8 - target_pos.0 as i8;
    let dy = puller_pos.1 as i8 - target_pos.1 as i8;

    // Normalize to get pull direction
    let pull_dir = (
        if dx != 0 { dx / dx.abs() } else { 0 },
        if dy != 0 { dy / dy.abs() } else { 0 },
    );

    // Calculate where piece will be pulled to
    let pull_to = (
        (target_pos.0 as i8 + pull_dir.0) as u8,
        (target_pos.1 as i8 + pull_dir.1) as u8,
    );

    // Check if destination is valid and empty
    if pull_to.0 < BOARD_SIZE && pull_to.1 < BOARD_SIZE {
        let occupied = pieces.iter().any(|(_, p)| p.board_position == pull_to);
        if !occupied {
            println!("Pulling piece from {:?} to {:?}", target_pos, pull_to);
            return true;
        }
    }
    false
}

pub fn activate_slide(
    _commands: &mut Commands,
    game_state: &GameState,
    pieces: &Query<(Entity, &GamePiece)>,
) {
    // Slide moves piece until it hits obstacle
    for (_entity, piece) in pieces.iter() {
        if piece.player == game_state.current_player {
            // Would need special movement logic
            println!(
                "Slide power activated for player {}'s pieces",
                match game_state.current_player {
                    Player::Player1 => "1",
                    Player::Player2 => "2",
                }
            );
        }
    }
}

pub fn activate_move_twice(_commands: &mut Commands, _game_state: &mut GameState) {
    // Allow player to move twice this turn
    println!("Move Twice activated - player can take another move after this one");
    // This would need special turn management
}

pub fn activate_leap(
    _commands: &mut Commands,
    source_pos: (u8, u8),
    target_pos: (u8, u8),
    pieces: &Query<(Entity, &GamePiece)>,
) -> bool {
    // Check if target is within 3 tiles
    let dx = (target_pos.0 as i8 - source_pos.0 as i8).abs();
    let dy = (target_pos.1 as i8 - source_pos.1 as i8).abs();

    if dx <= 3 && dy <= 3 {
        // Check if target is empty
        let occupied = pieces.iter().any(|(_, p)| p.board_position == target_pos);
        if !occupied {
            println!("Leaping from {:?} to {:?}", source_pos, target_pos);
            return true;
        }
    }
    false
}

// Check if a move is valid for special movement powers
pub fn is_valid_special_move(
    from: (u8, u8),
    to: (u8, u8),
    move_type: &PowerType,
    pieces: &Query<&GamePiece>,
) -> bool {
    let dx = (to.0 as i8 - from.0 as i8).abs();
    let dy = (to.1 as i8 - from.1 as i8).abs();

    match move_type {
        PowerType::Teleport => {
            // Can teleport to any empty square
            !pieces.iter().any(|p| p.board_position == to)
        }
        PowerType::Jump => {
            // Can jump over pieces in straight line
            (dx == 0 || dy == 0) && !pieces.iter().any(|p| p.board_position == to)
        }
        PowerType::MoveTwo => {
            // Move exactly 2 squares in one direction
            ((dx == 2 && dy == 0) || (dx == 0 && dy == 2))
                && !pieces.iter().any(|p| p.board_position == to)
        }
        PowerType::Knight => {
            // L-shaped move like chess knight
            ((dx == 2 && dy == 1) || (dx == 1 && dy == 2))
                && !pieces.iter().any(|p| p.board_position == to)
        }
        PowerType::Leap => {
            // Jump to any square within 3 tiles
            dx <= 3 && dy <= 3 && !pieces.iter().any(|p| p.board_position == to)
        }
        _ => false,
    }
}
