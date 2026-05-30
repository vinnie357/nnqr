-- Quadradius Love2D Implementation
-- A faithful recreation of the classic Flash strategy game

local Game = require("src.game")
local lovetest = require("test.lovetest")
local ScenarioRunner = require("src.scenario_runner")

-- Set when --scenario mode is active; cleared after the first draw.
local _scenarioMode = false
local _scenarioCaptured = false
local _qaDir = nil

function love.load(arg)
	-- Run tests if --test flag is passed
	if lovetest.detect(arg) then
		lovetest.run()
		return
	end

	-- Run scenario harness if --scenario <path> is passed
	if ScenarioRunner.detect(arg) then
		_scenarioMode = true
		_scenarioCaptured = false
		-- Derive .qa/ directory: absolute path inside the game directory.
		-- love.filesystem.getSource() returns the game directory (lua/love2d/).
		local root = love.filesystem.getSource()
		_qaDir = root .. "/.qa"
		ScenarioRunner.run(arg, Game)
		love.window.setTitle("Quadradius - Scenario Mode")
		return
	end

	love.window.setTitle("Quadradius - Love2D")
	Game.init()
end

function love.update(dt)
	Game.update(dt)
end

function love.draw()
	if _scenarioMode and not _scenarioCaptured then
		-- Capture on first draw, then quit
		_scenarioCaptured = true
		ScenarioRunner.captureAndQuit(Game, _qaDir)
		return
	end
	Game.draw()
end

function love.mousepressed(x, y, button)
	Game.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	Game.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
	Game.mousemoved(x, y, dx, dy)
end

function love.keypressed(key)
	-- Let the game handle escape for screen transitions
	Game.keypressed(key)
end

function love.wheelmoved(x, y)
	Game.wheelmoved(x, y)
end
