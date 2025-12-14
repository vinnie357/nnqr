-- Quadradius Love2D Implementation
-- A faithful recreation of the classic Flash strategy game

local Game = require("src.game")

function love.load()
	love.window.setTitle("Quadradius - Love2D")
	Game.init()
end

function love.update(dt)
	Game.update(dt)
end

function love.draw()
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
	if key == "escape" then
		love.event.quit()
	end
	Game.keypressed(key)
end

function love.wheelmoved(x, y)
	Game.wheelmoved(x, y)
end
