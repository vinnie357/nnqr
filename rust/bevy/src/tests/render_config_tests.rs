use crate::resources::RenderConfig;

#[cfg(test)]
mod render_config_tests {
    use super::*;

    #[test]
    fn test_default_render_config() {
        let config = RenderConfig::default();
        // Currently defaults to 2D mode for debugging board visibility
        assert!(!config.use_3d);
    }

    #[test]
    fn test_2d_render_config() {
        let config = RenderConfig::new_2d();
        assert!(!config.use_3d);
    }

    #[test]
    fn test_3d_render_config() {
        let config = RenderConfig::new_3d();
        assert!(config.use_3d);
    }

    #[test]
    fn test_render_config_clone() {
        let config1 = RenderConfig::new_3d();
        let config2 = config1.clone();
        assert_eq!(config1.use_3d, config2.use_3d);
    }
}
