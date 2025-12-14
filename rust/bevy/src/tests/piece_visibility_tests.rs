use bevy::prelude::*;
use crate::components::*;
use crate::resources::*;
use crate::systems::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_2d_piece_visibility_z_order() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        app.init_resource::<RenderConfig>();
        
        // Set 2D mode
        let mut render_config = app.world_mut().resource_mut::<RenderConfig>();
        render_config.use_3d = false;
        
        // Setup board and pieces
        app.add_systems(Startup, (setup_board, setup_pieces));
        app.update();
        
        // Check that pieces have higher Z values than tiles
        let tile_z_values: Vec<f32> = app.world()
            .query::<(&BoardTile, &Transform)>()
            .iter(&app.world())
            .map(|(_, transform)| transform.translation.z)
            .collect();
            
        let piece_z_values: Vec<f32> = app.world()
            .query::<(&GamePiece, &Transform)>()
            .iter(&app.world())
            .map(|(_, transform)| transform.translation.z)
            .collect();
            
        // All pieces should have Z > 0 (above tiles)
        for piece_z in &piece_z_values {
            assert!(*piece_z > 0.0, "Piece Z position {} should be above tiles", piece_z);
        }
        
        // All tiles should have Z <= 0 (at or below ground level)
        for tile_z in &tile_z_values {
            assert!(*tile_z <= 0.0, "Tile Z position {} should be at or below ground", tile_z);
        }
        
        // Pieces should be above tiles
        let max_tile_z = tile_z_values.iter().fold(f32::NEG_INFINITY, |a, &b| a.max(b));
        let min_piece_z = piece_z_values.iter().fold(f32::INFINITY, |a, &b| a.min(b));
        
        assert!(min_piece_z > max_tile_z, 
               "All pieces (min Z: {}) should be above all tiles (max Z: {})", 
               min_piece_z, max_tile_z);
    }
    
    #[test]
    fn test_3d_piece_visibility_depth_sorting() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        app.init_resource::<RenderConfig>();
        
        // Set 3D mode
        let mut render_config = app.world_mut().resource_mut::<RenderConfig>();
        render_config.use_3d = true;
        
        // Setup board and pieces with depth sorting
        app.add_systems(Startup, (setup_board_3d, setup_pieces_3d));
        app.add_systems(Update, (
            setup_tile_depth_sorting,
            setup_piece_depth_sorting,
            update_isometric_depth_sorting,
        ));
        app.update();
        
        // Give depth sorting systems a chance to run
        app.update();
        
        // Check that pieces have IsometricDepthSort component with correct layer offset
        let pieces_with_depth: Vec<(IsometricDepthSort, Transform)> = app.world()
            .query::<(&IsometricDepthSort, &Transform, &GamePiece3D)>()
            .iter(&app.world())
            .map(|(depth, transform, _)| (*depth, *transform))
            .collect();
            
        let tiles_with_depth: Vec<(IsometricDepthSort, Transform)> = app.world()
            .query::<(&IsometricDepthSort, &Transform, &BoardTile3D)>()
            .iter(&app.world())
            .map(|(depth, transform, _)| (*depth, *transform))
            .collect();
        
        // All pieces should have PIECE_LAYER offset
        for (depth, _) in &pieces_with_depth {
            assert_eq!(depth.layer_offset, depth_sorting::PIECE_LAYER, 
                      "Piece should have PIECE_LAYER offset");
        }
        
        // All tiles should have TILE_LAYER offset  
        for (depth, _) in &tiles_with_depth {
            assert_eq!(depth.layer_offset, depth_sorting::TILE_LAYER,
                      "Tile should have TILE_LAYER offset");
        }
        
        // For pieces and tiles at the same grid position, pieces should have higher Z
        for (piece_depth, piece_transform) in &pieces_with_depth {
            for (tile_depth, tile_transform) in &tiles_with_depth {
                if piece_depth.grid_x == tile_depth.grid_x && 
                   piece_depth.grid_y == tile_depth.grid_y {
                    assert!(piece_transform.translation.z > tile_transform.translation.z,
                           "Piece at ({}, {}) with Z {} should be above tile with Z {}",
                           piece_depth.grid_x, piece_depth.grid_y,
                           piece_transform.translation.z, tile_transform.translation.z);
                }
            }
        }
    }
    
    #[test]
    fn test_depth_sorting_systems_conditional_on_3d_mode() {
        let mut app = App::new();
        app.add_plugins(MinimalPlugins);
        app.init_resource::<RenderConfig>();
        
        // Test 2D mode - depth sorting should not run
        let mut render_config = app.world_mut().resource_mut::<RenderConfig>();
        render_config.use_3d = false;
        
        app.add_systems(Startup, (setup_board, setup_pieces));
        app.add_systems(Update, (
            setup_tile_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
            setup_piece_depth_sorting.run_if(|config: Res<RenderConfig>| config.use_3d),
        ));
        app.update();
        app.update();
        
        // No entities should have IsometricDepthSort in 2D mode
        let depth_sort_count = app.world()
            .query::<&IsometricDepthSort>()
            .iter(&app.world())
            .count();
            
        assert_eq!(depth_sort_count, 0, 
                  "No entities should have IsometricDepthSort in 2D mode");
        
        // Test 3D mode - depth sorting should run
        let mut render_config = app.world_mut().resource_mut::<RenderConfig>();
        render_config.use_3d = true;
        
        app.update();
        app.update();
        
        // Some entities should have IsometricDepthSort in 3D mode
        let depth_sort_count = app.world()
            .query::<&IsometricDepthSort>()
            .iter(&app.world())
            .count();
            
        assert!(depth_sort_count > 0, 
               "Some entities should have IsometricDepthSort in 3D mode");
    }
}