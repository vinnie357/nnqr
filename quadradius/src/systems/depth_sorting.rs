use crate::components::*;
use bevy::prelude::*;

/// Component for entities that need depth sorting in isometric view
#[derive(Component)]
pub struct IsometricDepthSort {
    pub grid_x: f32,
    pub grid_y: f32,
    pub height: f32,
    pub layer_offset: f32, // For different entity types (tiles, pieces, effects)
}

/// Layer offsets for different entity types
pub const TILE_LAYER: f32 = 0.0;
pub const PIECE_LAYER: f32 = 1.0;
pub const EFFECT_LAYER: f32 = 2.0;
pub const UI_LAYER: f32 = 10.0;

/// Update Z-order for proper isometric depth sorting
pub fn update_isometric_depth_sorting(
    mut query: Query<(&mut Transform, &IsometricDepthSort), Changed<IsometricDepthSort>>,
) {
    for (mut transform, depth_sort) in query.iter_mut() {
        // Calculate depth: further back and lower objects render first
        // Formula: larger Y coordinates (further back) get smaller Z values (render first)
        let base_depth = -((depth_sort.grid_y * 1000.0)
            + (depth_sort.grid_x * 10.0)
            + (depth_sort.height * 0.1));

        transform.translation.z = base_depth + depth_sort.layer_offset;
    }
}

/// Initialize depth sorting for board tiles
pub fn setup_tile_depth_sorting(
    mut commands: Commands,
    tiles: Query<(Entity, &BoardTile), Without<IsometricDepthSort>>,
) {
    for (entity, tile) in tiles.iter() {
        commands.entity(entity).insert(IsometricDepthSort {
            grid_x: tile.coordinates.0 as f32,
            grid_y: tile.coordinates.1 as f32,
            height: tile.height as f32,
            layer_offset: TILE_LAYER,
        });
    }
}

/// Initialize depth sorting for pieces (both 2D and 3D)
pub fn setup_piece_depth_sorting(
    mut commands: Commands,
    pieces_2d: Query<
        (Entity, &GamePiece),
        (
            Without<IsometricDepthSort>,
            Without<crate::systems::pieces_3d::GamePiece3D>,
        ),
    >,
    pieces_3d: Query<
        (Entity, &crate::systems::pieces_3d::GamePiece3D),
        Without<IsometricDepthSort>,
    >,
    tiles: Query<&BoardTile>,
) {
    // Handle 2D pieces
    for (entity, piece) in pieces_2d.iter() {
        let height = tiles
            .iter()
            .find(|tile| tile.coordinates == piece.board_position)
            .map(|tile| tile.height as f32)
            .unwrap_or(0.0);

        commands.entity(entity).insert(IsometricDepthSort {
            grid_x: piece.board_position.0 as f32,
            grid_y: piece.board_position.1 as f32,
            height,
            layer_offset: PIECE_LAYER,
        });
    }

    // Handle 3D pieces
    for (entity, piece) in pieces_3d.iter() {
        let height = tiles
            .iter()
            .find(|tile| tile.coordinates == piece.board_position)
            .map(|tile| tile.height as f32)
            .unwrap_or(0.0);

        commands.entity(entity).insert(IsometricDepthSort {
            grid_x: piece.board_position.0 as f32,
            grid_y: piece.board_position.1 as f32,
            height,
            layer_offset: PIECE_LAYER,
        });
    }
}

/// Update piece depth sorting when pieces move
pub fn update_piece_depth_sorting(
    mut pieces_2d: Query<
        (&GamePiece, &mut IsometricDepthSort),
        (
            Changed<GamePiece>,
            Without<crate::systems::pieces_3d::GamePiece3D>,
        ),
    >,
    mut pieces_3d: Query<
        (
            &crate::systems::pieces_3d::GamePiece3D,
            &mut IsometricDepthSort,
        ),
        Changed<crate::systems::pieces_3d::GamePiece3D>,
    >,
    tiles: Query<&BoardTile>,
) {
    // Update 2D pieces
    for (piece, mut depth_sort) in pieces_2d.iter_mut() {
        let height = tiles
            .iter()
            .find(|tile| tile.coordinates == piece.board_position)
            .map(|tile| tile.height as f32)
            .unwrap_or(0.0);

        depth_sort.grid_x = piece.board_position.0 as f32;
        depth_sort.grid_y = piece.board_position.1 as f32;
        depth_sort.height = height;
    }

    // Update 3D pieces
    for (piece, mut depth_sort) in pieces_3d.iter_mut() {
        let height = tiles
            .iter()
            .find(|tile| tile.coordinates == piece.board_position)
            .map(|tile| tile.height as f32)
            .unwrap_or(0.0);

        depth_sort.grid_x = piece.board_position.0 as f32;
        depth_sort.grid_y = piece.board_position.1 as f32;
        depth_sort.height = height;
    }
}

/// Setup depth sorting for power orbs
pub fn setup_power_orb_depth_sorting(
    mut commands: Commands,
    orbs_2d: Query<(Entity, &PowerOrb), Without<IsometricDepthSort>>,
    orbs_3d: Query<
        (Entity, &crate::systems::power_orbs_3d::PowerOrb3D),
        Without<IsometricDepthSort>,
    >,
) {
    // Handle 2D power orbs
    for (entity, orb) in orbs_2d.iter() {
        commands.entity(entity).insert(IsometricDepthSort {
            grid_x: orb.board_position.0 as f32,
            grid_y: orb.board_position.1 as f32,
            height: 0.5, // Floating above tiles
            layer_offset: EFFECT_LAYER,
        });
    }

    // Handle 3D power orbs
    for (entity, orb) in orbs_3d.iter() {
        commands.entity(entity).insert(IsometricDepthSort {
            grid_x: orb.board_position.0 as f32,
            grid_y: orb.board_position.1 as f32,
            height: 0.5, // Floating above tiles
            layer_offset: EFFECT_LAYER,
        });
    }
}
