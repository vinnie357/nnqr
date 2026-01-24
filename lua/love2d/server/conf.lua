-- Love2D configuration for NNQR Server
-- Headless by default, optional GUI mode with --gui flag

function love.conf(t)
	t.identity = "nnqr-server"
	t.version = "11.5"
	t.console = true -- Enable console output

	-- Check for --gui flag in command line args
	local guiMode = false
	for _, arg in ipairs(arg or {}) do
		if arg == "--gui" then
			guiMode = true
			break
		end
	end

	if guiMode then
		-- GUI mode for admin monitoring
		t.window.title = "NNQR Server"
		t.window.width = 800
		t.window.height = 600
		t.window.resizable = true
		t.window.vsync = 1
	else
		-- Headless mode (no window)
		t.modules.window = false
		t.modules.graphics = false
		t.modules.audio = false
		t.modules.sound = false
		t.modules.image = false
		t.modules.font = false
		t.modules.video = false
		t.modules.joystick = false
		t.modules.touch = false
		t.modules.mouse = false
		t.modules.keyboard = false
	end

	-- Always needed
	t.modules.timer = true
	t.modules.event = true
	t.modules.system = true
	t.modules.thread = true
	t.modules.data = true
	t.modules.math = true
end
