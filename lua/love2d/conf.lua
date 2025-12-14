function love.conf(t)
	t.title = "Quadradius"
	t.version = "11.5" -- Love2D version
	t.window.width = 1280
	t.window.height = 720
	t.window.resizable = true
	t.window.vsync = 1

	-- Console for debugging (Windows only)
	t.console = false

	-- Modules
	t.modules.physics = false -- Not needed for turn-based
	t.modules.joystick = false
	t.modules.touch = false
end
