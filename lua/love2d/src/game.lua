-- Quadradius Game Module
-- Main game loop integrating shared modules with Love2D rendering

local GameLogic = require("src.shared.game_logic")
local Rendering = require("src.shared.rendering")
local Height = require("src.shared.height")
local Powers = require("src.shared.powers")

local Game = {}

-- Game state (managed by GameLogic)
Game.state = nil

-- Visual settings
Game.boardOffsetX = 0
Game.boardOffsetY = 0

-- Animation/interaction state
Game.hoveredTile = nil
Game.orbs = {}

-- Colors - Clean Modern Style
Game.colors = {
	player1 = { 0.25, 0.55, 0.95 },
	player1Dark = { 0.15, 0.35, 0.75 },
	player2 = { 0.95, 0.35, 0.35 },
	player2Dark = { 0.75, 0.2, 0.2 },
	selected = { 1.0, 0.85, 0.2 },
	validMove = { 0.3, 0.9, 0.4 },
	validMoveCapture = { 0.95, 0.5, 0.2 },
	orb = { 0.9, 0.8, 0.2 },
	background = { 0.12, 0.14, 0.18 },
}

function Game.init()
	love.graphics.setBackgroundColor(Game.colors.background)

	-- Center the board
	Game.boardOffsetX = love.graphics.getWidth() / 2
	Game.boardOffsetY = 120

	-- Create initial game state
	Game.state = GameLogic.createInitialState()

	-- Add some terrain variation for visual interest
	Game.generateTerrain()

	-- Initialize orbs
	Game.orbs = {}
end

function Game.generateTerrain()
	-- Create interesting terrain with height variations
	for row = 3, 6 do
		for col = 4, 7 do
			GameLogic.setHeight(Game.state, row, col, 1)
		end
	end
	GameLogic.setHeight(Game.state, 4, 5, 2)
	GameLogic.setHeight(Game.state, 5, 6, 2)
	GameLogic.setHeight(Game.state, 4, 6, 3)
end

function Game.update(dt)
	-- Update hovered tile
	local mx, my = love.mouse.getPosition()
	local row, col = Rendering.screenToBoard(mx, my, Game.boardOffsetX, Game.boardOffsetY)
	if row >= 1 and row <= Game.state.rows and col >= 1 and col <= Game.state.cols then
		Game.hoveredTile = { row = row, col = col }
	else
		Game.hoveredTile = nil
	end
end

function Game.draw()
	Game.drawBoard()
	Game.drawOrbs()
	Game.drawValidMoves()
	Game.drawPieces()
	Game.drawUI()
end

function Game.drawBoard()
	for row = 1, Game.state.rows do
		for col = 1, Game.state.cols do
			local height = GameLogic.getHeight(Game.state, row, col)
			local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
			y = y + Rendering.getHeightOffset(height)

			-- Get height-based color with slight variation
			local r, g, b = Rendering.getHeightColor(height)
			local variation = ((row + col) % 2 == 0) and 0.05 or 0
			r = math.min(1, r + variation)
			g = math.min(1, g + variation)
			b = math.min(1, b + variation)

			-- Draw tile sides for raised tiles
			if height > 0 then
				Game.drawTileSides(x, y, height, r, g, b)
			end

			-- Draw tile top
			love.graphics.setColor(r, g, b)
			local verts = Rendering.getTileVertices(x, y)
			love.graphics.polygon("fill", verts)

			-- Draw tile border
			love.graphics.setColor(r * 0.6, g * 0.6, b * 0.6)
			love.graphics.setLineWidth(1)
			love.graphics.polygon("line", verts)

			-- Hover highlight
			if Game.hoveredTile and Game.hoveredTile.row == row and Game.hoveredTile.col == col then
				love.graphics.setColor(1, 1, 1, 0.15)
				love.graphics.polygon("fill", verts)
			end
		end
	end
end

function Game.drawTileSides(x, y, height, r, g, b)
	-- Left side (darker)
	love.graphics.setColor(r * 0.5, g * 0.5, b * 0.5)
	local leftVerts = Rendering.getTileSideVertices(x, y, height, "left")
	love.graphics.polygon("fill", leftVerts)

	-- Right side (medium dark)
	love.graphics.setColor(r * 0.65, g * 0.65, b * 0.65)
	local rightVerts = Rendering.getTileSideVertices(x, y, height, "right")
	love.graphics.polygon("fill", rightVerts)
end

function Game.drawOrbs()
	for _, orb in ipairs(Game.orbs) do
		local height = GameLogic.getHeight(Game.state, orb.row, orb.col)
		local x, y = Rendering.boardToScreen(orb.row, orb.col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height)

		-- Draw orb glow
		love.graphics.setColor(Game.colors.orb[1], Game.colors.orb[2], Game.colors.orb[3], 0.3)
		love.graphics.circle("fill", x, y - 8, 14)

		-- Draw orb
		love.graphics.setColor(Game.colors.orb)
		love.graphics.circle("fill", x, y - 8, 10)

		-- Highlight
		love.graphics.setColor(1, 1, 1, 0.5)
		love.graphics.circle("fill", x - 3, y - 11, 4)
	end
end

function Game.drawValidMoves()
	if not Game.state.selectedPiece then
		return
	end

	for _, move in ipairs(Game.state.validMoves) do
		local height = GameLogic.getHeight(Game.state, move.row, move.col)
		local x, y = Rendering.boardToScreen(move.row, move.col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height)

		local targetPiece = GameLogic.getPieceAt(Game.state, move.row, move.col)
		local color = targetPiece and Game.colors.validMoveCapture or Game.colors.validMove

		love.graphics.setColor(color[1], color[2], color[3], 0.5)
		local verts = Rendering.getTileVertices(x, y)
		love.graphics.polygon("fill", verts)

		love.graphics.setColor(color)
		love.graphics.setLineWidth(2)
		love.graphics.polygon("line", verts)
		love.graphics.setLineWidth(1)
	end
end

function Game.drawPieces()
	-- Sort for proper depth
	local sorted = Rendering.sortByDepth(Game.state.pieces)

	for _, piece in ipairs(sorted) do
		local height = GameLogic.getHeight(Game.state, piece.row, piece.col)
		local x, y = Rendering.boardToScreen(piece.row, piece.col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height)

		local mainColor = piece.player == 1 and Game.colors.player1 or Game.colors.player2
		local darkColor = piece.player == 1 and Game.colors.player1Dark or Game.colors.player2Dark

		-- Shadow
		love.graphics.setColor(0, 0, 0, 0.3)
		love.graphics.ellipse("fill", x, y + 2, 18, 9)

		-- Bottom ellipse
		love.graphics.setColor(darkColor)
		love.graphics.ellipse("fill", x, y - 6, 20, 10)

		-- Disc side
		local sideVerts = {}
		for i = 0, 32 do
			local angle = math.pi + (math.pi * i / 32)
			table.insert(sideVerts, x + math.cos(angle) * 20)
			table.insert(sideVerts, y - 6 + math.sin(angle) * 10)
		end
		for i = 32, 0, -1 do
			local angle = math.pi + (math.pi * i / 32)
			table.insert(sideVerts, x + math.cos(angle) * 20)
			table.insert(sideVerts, y - 14 + math.sin(angle) * 10)
		end
		if #sideVerts >= 6 then
			love.graphics.polygon("fill", sideVerts)
		end

		-- Top ellipse
		love.graphics.setColor(mainColor)
		love.graphics.ellipse("fill", x, y - 14, 20, 10)

		-- Highlight
		love.graphics.setColor(1, 1, 1, 0.3)
		love.graphics.ellipse("fill", x - 5, y - 17, 8, 4)

		-- Power indicator
		if piece.powers and #piece.powers > 0 then
			love.graphics.setColor(1, 0.9, 0.3, 0.8)
			love.graphics.circle("fill", x + 12, y - 20, 6)
			love.graphics.setColor(0, 0, 0)
			love.graphics.printf(tostring(#piece.powers), x + 8, y - 24, 10, "center")
		end

		-- Selection ring
		if Game.state.selectedPiece == piece then
			love.graphics.setColor(Game.colors.selected)
			love.graphics.setLineWidth(3)
			love.graphics.ellipse("line", x, y - 10, 24, 12)
			love.graphics.setLineWidth(1)

			local pulse = (math.sin(love.timer.getTime() * 4) + 1) / 2
			love.graphics.setColor(
				Game.colors.selected[1],
				Game.colors.selected[2],
				Game.colors.selected[3],
				0.3 * pulse
			)
			love.graphics.ellipse("fill", x, y - 10, 28, 14)
		end
	end
end

function Game.drawUI()
	-- Panel background
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", 5, 5, 260, 125, 8, 8)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("NNQR - Love2D (TDD)", 15, 12)

	-- Current player
	local playerColor = Game.state.currentPlayer == 1 and Game.colors.player1 or Game.colors.player2
	love.graphics.setColor(playerColor)
	love.graphics.circle("fill", 25, 45, 10)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Player " .. Game.state.currentPlayer .. "'s turn", 42, 38)

	-- Piece counts
	local p1, p2 = 0, 0
	for _, p in ipairs(Game.state.pieces) do
		if p.player == 1 then
			p1 = p1 + 1
		else
			p2 = p2 + 1
		end
	end
	love.graphics.setColor(Game.colors.player1)
	love.graphics.print("P1: " .. p1, 15, 62)
	love.graphics.setColor(Game.colors.player2)
	love.graphics.print("P2: " .. p2, 75, 62)

	-- Turn counter
	love.graphics.setColor(0.7, 0.7, 0.7)
	love.graphics.print("Turn: " .. Game.state.turn, 140, 62)

	-- Controls
	love.graphics.print("R=Reset  H/L=Height  ESC=Quit", 15, 85)

	-- Hovered tile info
	if Game.hoveredTile then
		local h = GameLogic.getHeight(Game.state, Game.hoveredTile.row, Game.hoveredTile.col)
		love.graphics.print(string.format("Tile: %d,%d  H:%d", Game.hoveredTile.row, Game.hoveredTile.col, h), 15, 105)
	end

	-- Game over
	if Game.state.gameState == "gameover" then
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

		local winColor = Game.state.winner == 1 and Game.colors.player1 or Game.colors.player2
		love.graphics.setColor(winColor)
		local text = "Player " .. Game.state.winner .. " Wins!"
		local font = love.graphics.getFont()
		love.graphics.print(
			text,
			(love.graphics.getWidth() - font:getWidth(text)) / 2,
			love.graphics.getHeight() / 2 - 20
		)

		love.graphics.setColor(1, 1, 1)
		love.graphics.print(
			"Press R to play again",
			(love.graphics.getWidth() - font:getWidth("Press R to play again")) / 2,
			love.graphics.getHeight() / 2 + 20
		)
	end
end

function Game.mousepressed(x, y, button)
	if button == 1 and Game.state.gameState == "playing" then
		local row, col = Rendering.screenToBoard(x, y, Game.boardOffsetX, Game.boardOffsetY)

		if row >= 1 and row <= Game.state.rows and col >= 1 and col <= Game.state.cols then
			local clickedPiece = GameLogic.getPieceAt(Game.state, row, col)

			if Game.state.selectedPiece then
				-- Check if valid move
				local isValid = false
				for _, move in ipairs(Game.state.validMoves) do
					if move.row == row and move.col == col then
						isValid = true
						break
					end
				end

				if isValid then
					Game.state = GameLogic.movePiece(Game.state, Game.state.selectedPiece, row, col)
					-- Collect orb if present
					Powers.collectOrb(Game.state.selectedPiece, Game.orbs)
					Game.state = GameLogic.endTurn(Game.state)
					-- Check for orb spawn
					if Powers.shouldSpawnOrbs(Game.state.turn) then
						local newOrbs = Powers.spawnOrbs(
							Game.state.cols,
							Game.state.rows,
							Game.state.pieces,
							Game.orbs,
							Powers.getOrbSpawnCount()
						)
						for _, orb in ipairs(newOrbs) do
							table.insert(Game.orbs, orb)
						end
					end
				elseif clickedPiece and clickedPiece.player == Game.state.currentPlayer then
					Game.state = GameLogic.selectPiece(Game.state, clickedPiece)
				else
					Game.state = GameLogic.selectPiece(Game.state, nil)
				end
			elseif clickedPiece and clickedPiece.player == Game.state.currentPlayer then
				Game.state = GameLogic.selectPiece(Game.state, clickedPiece)
			end
		end
	end
end

function Game.mousereleased(x, y, button) end

function Game.mousemoved(x, y, dx, dy) end

function Game.keypressed(key)
	if key == "r" then
		Game.init()
	elseif key == "h" and Game.hoveredTile then
		local h = GameLogic.getHeight(Game.state, Game.hoveredTile.row, Game.hoveredTile.col)
		Game.state = GameLogic.setHeight(Game.state, Game.hoveredTile.row, Game.hoveredTile.col, h + 1)
		if Game.state.selectedPiece then
			Game.state = GameLogic.selectPiece(Game.state, Game.state.selectedPiece)
		end
	elseif key == "l" and Game.hoveredTile then
		local h = GameLogic.getHeight(Game.state, Game.hoveredTile.row, Game.hoveredTile.col)
		Game.state = GameLogic.setHeight(Game.state, Game.hoveredTile.row, Game.hoveredTile.col, h - 1)
		if Game.state.selectedPiece then
			Game.state = GameLogic.selectPiece(Game.state, Game.state.selectedPiece)
		end
	elseif key == "o" then
		-- Debug: spawn orbs manually
		local newOrbs = Powers.spawnOrbs(Game.state.cols, Game.state.rows, Game.state.pieces, Game.orbs, 3)
		for _, orb in ipairs(newOrbs) do
			table.insert(Game.orbs, orb)
		end
	end
end

function Game.wheelmoved(x, y) end

return Game
