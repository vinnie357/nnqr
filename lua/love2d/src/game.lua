-- Quadradius Game Module
-- Main game loop integrating shared modules with Love2D rendering

local GameLogic = require("src.shared.game_logic")
local Rendering = require("src.shared.rendering")
local Height = require("src.shared.height")
local Powers = require("src.shared.powers")
local PowerEffects = require("src.shared.power_effects")
local GameAnimations = require("src.shared.game_animations")
local Animations = require("src.shared.animations")
local Indicators = require("src.shared.indicators")

local Game = {}

-- Game state (managed by GameLogic)
Game.state = nil

-- Visual settings
Game.boardOffsetX = 0
Game.boardOffsetY = 0

-- Animation/interaction state
Game.hoveredTile = nil
Game.orbs = {}

-- Power activation mode
Game.powerMode = nil -- nil or {powerId, piece, targets}
Game.powerTargets = {}

-- Animation state
Game.animations = nil

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

	-- Initialize animation system
	Game.animations = GameAnimations.create()
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
	-- Update animations
	if Game.animations then
		GameAnimations.update(Game.animations, dt)
	end

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
	Game.drawPowerTargets()
	Game.drawPieces()
	Game.drawAnimations()
	Game.drawUI()
	Game.drawPowerMenu()
end

function Game.drawPowerTargets()
	if not Game.powerMode then
		return
	end

	for _, target in ipairs(Game.powerTargets) do
		local height = GameLogic.getHeight(Game.state, target.row, target.col)
		local x, y = Rendering.boardToScreen(target.row, target.col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height)

		-- Purple for power targets
		love.graphics.setColor(0.8, 0.3, 0.9, 0.5)
		local verts = Rendering.getTileVertices(x, y)
		love.graphics.polygon("fill", verts)

		love.graphics.setColor(0.9, 0.4, 1.0)
		love.graphics.setLineWidth(2)
		love.graphics.polygon("line", verts)
		love.graphics.setLineWidth(1)
	end
end

function Game.drawPowerMenu()
	local piece = Game.state.selectedPiece
	if not piece or not piece.powers or #piece.powers == 0 then
		return
	end

	-- Draw power menu on right side
	local menuX = love.graphics.getWidth() - 200
	local menuY = 100
	local menuWidth = 190
	local itemHeight = 30

	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", menuX, menuY, menuWidth, 30 + #piece.powers * itemHeight, 8, 8)

	love.graphics.setColor(1, 0.9, 0.3)
	love.graphics.print("Powers (1-9 to use):", menuX + 10, menuY + 8)

	for i, powerId in ipairs(piece.powers) do
		local def = Powers.definitions[powerId]
		local itemY = menuY + 25 + (i - 1) * itemHeight

		-- Highlight if in power mode for this power
		if Game.powerMode and Game.powerMode.powerId == powerId then
			love.graphics.setColor(0.8, 0.3, 0.9, 0.5)
			love.graphics.rectangle("fill", menuX + 5, itemY, menuWidth - 10, itemHeight - 2, 4, 4)
		end

		love.graphics.setColor(1, 1, 1)
		love.graphics.print(i .. ". " .. (def and def.name or powerId), menuX + 10, itemY + 5)
	end

	-- Instructions if in power mode
	if Game.powerMode then
		love.graphics.setColor(0.9, 0.4, 1.0)
		love.graphics.print("Click target or ESC to cancel", menuX + 10, menuY + 30 + #piece.powers * itemHeight + 5)
	end
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

		-- Persistent power indicators
		local indicators = Indicators.getPieceIndicators(piece)
		for _, indicator in ipairs(indicators) do
			if indicator == "jump_proof" then
				-- Jump Proof: 2 metallic cyan armor bands wrapped around piece
				love.graphics.setColor(0.5, 0.8, 1, 0.9)
				love.graphics.setLineWidth(2)
				love.graphics.ellipse("line", x, y - 8, 22, 11) -- Lower band
				love.graphics.ellipse("line", x, y - 16, 18, 9) -- Upper band
				-- White highlight arc on bands
				love.graphics.setColor(1, 1, 1, 0.5)
				love.graphics.arc("line", "open", x, y - 8, 22, math.pi + 0.3, math.pi * 2 - 0.3)
				love.graphics.setLineWidth(1)
			elseif indicator == "move_diagonal" then
				-- Move Diagonal: 4 short diagonal lines extending from piece
				love.graphics.setColor(0.3, 0.9, 0.5, 0.8)
				love.graphics.setLineWidth(2)
				local cx, cy = x, y - 10 -- Center of piece
				local inner, outer = 18, 28 -- Line distances
				-- Four diagonal directions (isometric squash on Y)
				for _, dir in ipairs({ { -1, -0.5 }, { 1, -0.5 }, { -1, 0.5 }, { 1, 0.5 } }) do
					love.graphics.line(
						cx + dir[1] * inner,
						cy + dir[2] * inner,
						cx + dir[1] * outer,
						cy + dir[2] * outer
					)
				end
				love.graphics.setLineWidth(1)
			elseif indicator == "invisible" then
				-- Invisible: Subtle shimmer effect (piece is semi-transparent)
				love.graphics.setColor(0.7, 0.7, 0.9, 0.3)
				love.graphics.ellipse("fill", x, y - 10, 24, 12)
			end
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

function Game.drawAnimations()
	if not Game.animations then
		return
	end

	local activeAnims = GameAnimations.getActiveAnimations(Game.animations)
	for _, anim in ipairs(activeAnims) do
		local progress = Animations.getProgress(anim)
		Game.drawAnimation(anim, progress)
	end
end

function Game.drawAnimation(anim, progress)
	if anim.type == "destroy_row" then
		Game.drawDestroyRowAnimation(anim, progress)
	elseif anim.type == "destroy_column" then
		Game.drawDestroyColumnAnimation(anim, progress)
	elseif anim.type == "bomb" then
		Game.drawBombAnimation(anim, progress)
	elseif anim.type == "relocate" then
		Game.drawRelocateAnimation(anim, progress)
	elseif anim.type == "raise_tile" or anim.type == "lower_tile" then
		Game.drawTileHeightAnimation(anim, progress)
	elseif anim.type == "recruit" then
		Game.drawRecruitAnimation(anim, progress)
	elseif anim.type == "multiply" then
		Game.drawMultiplyAnimation(anim, progress)
	elseif anim.type == "move_diagonal" then
		Game.drawMoveDiagonalAnimation(anim, progress)
	elseif anim.type == "jump_proof" then
		Game.drawJumpProofAnimation(anim, progress)
	elseif anim.type == "invisible" then
		Game.drawInvisibleAnimation(anim, progress)
	elseif anim.type == "move_again" then
		Game.drawMoveAgainAnimation(anim, progress)
	end
end

-- Destroy Row: Horizontal energy wave sweeping across the row
function Game.drawDestroyRowAnimation(anim, progress)
	local wavePos = Animations.getDestroyRowWavePosition(anim, progress)
	local row = anim.data.row
	local originCol = anim.data.originCol

	-- Calculate wave X position (0-1 maps to full board width)
	for col = 1, Game.state.cols do
		local colProgress = (col - 1) / (Game.state.cols - 1)
		local distance = math.abs(colProgress - wavePos)

		if distance < 0.15 then
			local height = GameLogic.getHeight(Game.state, row, col)
			local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
			y = y + Rendering.getHeightOffset(height)

			-- Bright energy glow
			local intensity = 1 - (distance / 0.15)
			love.graphics.setColor(1, 0.8, 0.2, intensity * 0.8)
			local verts = Rendering.getTileVertices(x, y)
			love.graphics.polygon("fill", verts)

			-- Energy core
			love.graphics.setColor(1, 1, 1, intensity)
			love.graphics.circle("fill", x, y, 8 * intensity)
		end
	end

	-- Draw horizontal beam
	local startX, startY = Rendering.boardToScreen(row, 1, Game.boardOffsetX, Game.boardOffsetY)
	local endX, endY = Rendering.boardToScreen(row, Game.state.cols, Game.boardOffsetX, Game.boardOffsetY)
	local beamX = startX + (endX - startX) * wavePos

	love.graphics.setColor(1, 0.9, 0.3, 0.6)
	love.graphics.setLineWidth(4)
	love.graphics.line(beamX - 30, startY, beamX + 30, startY)
	love.graphics.setLineWidth(1)
end

-- Destroy Column: Vertical energy wave sweeping down the column
function Game.drawDestroyColumnAnimation(anim, progress)
	local wavePos = Animations.getDestroyRowWavePosition(anim, progress) -- reuse same easing
	local col = anim.data.col
	local originRow = anim.data.originRow

	for row = 1, Game.state.rows do
		local rowProgress = (row - 1) / (Game.state.rows - 1)
		local distance = math.abs(rowProgress - wavePos)

		if distance < 0.15 then
			local height = GameLogic.getHeight(Game.state, row, col)
			local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
			y = y + Rendering.getHeightOffset(height)

			local intensity = 1 - (distance / 0.15)
			love.graphics.setColor(0.2, 0.8, 1, intensity * 0.8)
			local verts = Rendering.getTileVertices(x, y)
			love.graphics.polygon("fill", verts)

			love.graphics.setColor(1, 1, 1, intensity)
			love.graphics.circle("fill", x, y, 8 * intensity)
		end
	end

	-- Draw vertical beam
	local startX, startY = Rendering.boardToScreen(1, col, Game.boardOffsetX, Game.boardOffsetY)
	local endX, endY = Rendering.boardToScreen(Game.state.rows, col, Game.boardOffsetX, Game.boardOffsetY)
	local beamY = startY + (endY - startY) * wavePos

	love.graphics.setColor(0.3, 0.9, 1, 0.6)
	love.graphics.setLineWidth(4)
	love.graphics.line(startX, beamY - 30, startX, beamY + 30)
	love.graphics.setLineWidth(1)
end

-- Bomb: Expanding explosion circle with screen shake effect
function Game.drawBombAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	local radius = Animations.getBombRadius(anim, progress) * Rendering.TILE_WIDTH

	-- Outer glow
	love.graphics.setColor(1, 0.5, 0, 0.3)
	love.graphics.circle("fill", x, y, radius * 1.5)

	-- Main explosion
	love.graphics.setColor(1, 0.7, 0.2, 0.7)
	love.graphics.circle("fill", x, y, radius)

	-- Inner core
	love.graphics.setColor(1, 1, 0.8, 0.9)
	love.graphics.circle("fill", x, y, radius * 0.5)

	-- Explosion particles
	local particleCount = 8
	for i = 1, particleCount do
		local angle = (i / particleCount) * math.pi * 2 + progress * 2
		local dist = radius * (0.8 + math.sin(progress * 10 + i) * 0.3)
		local px = x + math.cos(angle) * dist
		local py = y + math.sin(angle) * dist * 0.5 -- isometric squash

		love.graphics.setColor(1, 0.8, 0.3, 1 - progress)
		love.graphics.circle("fill", px, py, 4)
	end
end

-- Relocate: Fade out -> particles -> fade in at new location
function Game.drawRelocateAnimation(anim, progress)
	local alpha = Animations.getRelocateFadeAlpha(anim, progress)
	local row, col = Animations.getRelocatePosition(anim, progress)
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	-- Teleport particles
	local particleAlpha = 1 - math.abs(progress - 0.5) * 2
	if particleAlpha > 0 then
		for i = 1, 12 do
			local angle = (i / 12) * math.pi * 2
			local dist = 30 * particleAlpha
			local px = x + math.cos(angle) * dist
			local py = y + math.sin(angle) * dist * 0.5

			love.graphics.setColor(0.6, 0.3, 1, particleAlpha * 0.8)
			love.graphics.circle("fill", px, py - 10, 3)
		end
	end

	-- Glow ring at position
	love.graphics.setColor(0.7, 0.4, 1, alpha * 0.5)
	love.graphics.setLineWidth(3)
	love.graphics.ellipse("line", x, y - 10, 25, 12)
	love.graphics.setLineWidth(1)
end

-- Raise/Lower Tile: Tile smoothly changes height
function Game.drawTileHeightAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local currentHeight = Animations.getTileHeightOffset(anim, progress)

	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(currentHeight)

	-- Highlight tile being modified
	local isRaising = anim.type == "raise_tile"
	if isRaising then
		love.graphics.setColor(0.3, 1, 0.5, 0.5 * (1 - progress))
	else
		love.graphics.setColor(1, 0.5, 0.3, 0.5 * (1 - progress))
	end

	local verts = Rendering.getTileVertices(x, y)
	love.graphics.polygon("fill", verts)

	-- Rising/falling particles
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local dist = 20
		local px = x + math.cos(angle) * dist
		local baseY = y + math.sin(angle) * dist * 0.5
		local particleOffset = isRaising and (-20 * progress) or (20 * progress)

		love.graphics.setColor(isRaising and 0.5 or 1, isRaising and 1 or 0.5, 0.3, 1 - progress)
		love.graphics.circle("fill", px, baseY + particleOffset, 2)
	end
end

-- Recruit: Enemy piece changes color to your team
function Game.drawRecruitAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	local r, g, b = Animations.getRecruitColor(anim, progress)

	-- Conversion glow ring
	love.graphics.setColor(r, g, b, 0.6)
	love.graphics.setLineWidth(3)
	love.graphics.ellipse("line", x, y - 10, 30 - 5 * progress, 15 - 2.5 * progress)
	love.graphics.setLineWidth(1)

	-- Spiraling particles
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2 + progress * math.pi * 4
		local dist = 25 * (1 - progress * 0.5)
		local px = x + math.cos(angle) * dist
		local py = y - 10 + math.sin(angle) * dist * 0.5

		love.graphics.setColor(r, g, b, 1 - progress * 0.5)
		love.graphics.circle("fill", px, py, 3)
	end
end

-- Multiply: Clone splits from original piece
function Game.drawMultiplyAnimation(anim, progress)
	local fromRow, fromCol = anim.data.originRow, anim.data.originCol
	local toRow, toCol = anim.data.targetRow, anim.data.targetCol

	local fromHeight = GameLogic.getHeight(Game.state, fromRow, fromCol)
	local toHeight = GameLogic.getHeight(Game.state, toRow, toCol)

	local fromX, fromY = Rendering.boardToScreen(fromRow, fromCol, Game.boardOffsetX, Game.boardOffsetY)
	fromY = fromY + Rendering.getHeightOffset(fromHeight)

	local toX, toY = Rendering.boardToScreen(toRow, toCol, Game.boardOffsetX, Game.boardOffsetY)
	toY = toY + Rendering.getHeightOffset(toHeight)

	-- Interpolate clone position
	local easedProgress = Animations.ease.easeOutBack(progress)
	local cloneX = fromX + (toX - fromX) * easedProgress
	local cloneY = fromY + (toY - fromY) * easedProgress

	-- Draw ghost clone
	love.graphics.setColor(1, 1, 1, 0.7 * progress)
	love.graphics.ellipse("fill", cloneX, cloneY - 10, 18, 9)

	-- Trail particles
	for i = 1, 5 do
		local t = (progress - i * 0.1)
		if t > 0 then
			local trailX = fromX + (toX - fromX) * t
			local trailY = fromY + (toY - fromY) * t
			love.graphics.setColor(0.8, 0.9, 1, 0.3 * (1 - t))
			love.graphics.circle("fill", trailX, trailY - 10, 4)
		end
	end
end

-- Move Diagonal: Lines extend outward from piece center
function Game.drawMoveDiagonalAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	-- Phase 1 (0-50%): Lines extend outward from center
	-- Phase 2 (50-100%): Lines reach full length, glow settles
	local extendProgress = math.min(1, progress * 2) -- Reaches full extension at 50%
	local glowAlpha = 1 - math.max(0, (progress - 0.5) * 1.5) -- Glow fades in second half

	local cx, cy = x, y - 10 -- Center of piece
	local inner = 18 * extendProgress -- Lines extend from center
	local outer = 28 * extendProgress

	-- Four diagonal directions (isometric squash on Y)
	local dirs = { { -1, -0.5 }, { 1, -0.5 }, { -1, 0.5 }, { 1, 0.5 } }

	-- Glow effect around extending lines
	if glowAlpha > 0.2 then
		love.graphics.setColor(0.3, 0.9, 0.5, glowAlpha * 0.4)
		for _, dir in ipairs(dirs) do
			love.graphics.circle("fill", cx + dir[1] * outer, cy + dir[2] * outer, 6 * extendProgress)
		end
	end

	-- Extending diagonal lines
	love.graphics.setColor(0.3, 0.9, 0.5, 0.8)
	love.graphics.setLineWidth(2)
	for _, dir in ipairs(dirs) do
		love.graphics.line(cx + dir[1] * inner, cy + dir[2] * inner, cx + dir[1] * outer, cy + dir[2] * outer)
	end
	love.graphics.setLineWidth(1)

	-- Sparkles during extension
	if progress < 0.6 then
		for i = 1, 4 do
			local angle = (i / 4) * math.pi * 2 + progress * 4
			local dist = 20 * extendProgress
			local sx = cx + math.cos(angle) * dist
			local sy = cy + math.sin(angle) * dist * 0.5

			love.graphics.setColor(0.5, 1, 0.7, 1 - progress * 1.5)
			love.graphics.circle("fill", sx, sy, 2)
		end
	end
end

-- Jump Proof: Armor bands wrap around piece
function Game.drawJumpProofAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	local scale = Animations.getShieldScale(anim, progress)

	-- Phase 1 (0-50%): Armor bands scale from 0 to full size (wrapping effect)
	-- Phase 2 (50-100%): Bands settle, metallic highlight appears
	local bandScale = math.min(1, progress * 2) -- Reaches full size at 50%
	local highlightAlpha = math.max(0, (progress - 0.5) * 2) -- Fades in after 50%

	-- Metallic cyan armor bands wrapping around
	love.graphics.setColor(0.5, 0.8, 1, 0.9 * bandScale)
	love.graphics.setLineWidth(2 + bandScale)
	love.graphics.ellipse("line", x, y - 8, 22 * bandScale, 11 * bandScale) -- Lower band
	love.graphics.ellipse("line", x, y - 16, 18 * bandScale, 9 * bandScale) -- Upper band
	love.graphics.setLineWidth(1)

	-- White metallic highlight appears as bands settle
	if highlightAlpha > 0 then
		love.graphics.setColor(1, 1, 1, 0.5 * highlightAlpha)
		love.graphics.arc("line", "open", x, y - 8, 22, math.pi + 0.3, math.pi * 2 - 0.3)
	end

	-- Sparkles during wrapping phase
	if progress < 0.6 then
		for i = 1, 6 do
			local angle = (i / 6) * math.pi * 2 + progress * 6
			local dist = 25 * (1 - progress)
			local sx = x + math.cos(angle) * dist
			local sy = y - 12 + math.sin(angle) * dist * 0.5

			love.graphics.setColor(0.5, 0.8, 1, 1 - progress * 1.5)
			love.graphics.circle("fill", sx, sy, 2)
		end
	end
end

-- Invisible: Piece fades to semi-transparent
function Game.drawInvisibleAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	local alpha = Animations.getInvisibleAlpha(anim, progress)

	-- Fading mist effect
	love.graphics.setColor(0.7, 0.7, 0.9, (1 - alpha) * 0.5)
	love.graphics.ellipse("fill", x, y - 10, 25, 12)

	-- Sparkling fade particles
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2 + progress * 2
		local dist = 20 + 10 * progress
		local px = x + math.cos(angle) * dist
		local py = y - 10 + math.sin(angle) * dist * 0.5

		love.graphics.setColor(0.8, 0.8, 1, (1 - progress) * 0.6)
		love.graphics.circle("fill", px, py, 2)
	end
end

-- Move Again: Speed lines burst from piece
function Game.drawMoveAgainAnimation(anim, progress)
	local row, col = anim.data.row, anim.data.col
	local height = GameLogic.getHeight(Game.state, row, col)
	local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
	y = y + Rendering.getHeightOffset(height)

	-- Burst of speed lines
	local lineCount = 12
	for i = 1, lineCount do
		local angle = (i / lineCount) * math.pi * 2
		local innerDist = 15 + 20 * progress
		local outerDist = 25 + 40 * progress

		local x1 = x + math.cos(angle) * innerDist
		local y1 = y - 10 + math.sin(angle) * innerDist * 0.5
		local x2 = x + math.cos(angle) * outerDist
		local y2 = y - 10 + math.sin(angle) * outerDist * 0.5

		love.graphics.setColor(1, 0.9, 0.3, 1 - progress)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	end
	love.graphics.setLineWidth(1)

	-- Central flash
	if progress < 0.3 then
		love.graphics.setColor(1, 1, 0.8, 1 - progress * 3)
		love.graphics.circle("fill", x, y - 10, 15)
	end
end

function Game.mousepressed(x, y, button)
	-- Block input during blocking animations
	if Game.animations and GameAnimations.isBlocking(Game.animations) then
		return
	end

	if button == 1 and Game.state.gameState == "playing" then
		local row, col = Rendering.screenToBoard(x, y, Game.boardOffsetX, Game.boardOffsetY)

		if row >= 1 and row <= Game.state.rows and col >= 1 and col <= Game.state.cols then
			-- Check if in power targeting mode
			if Game.powerMode then
				local validTarget = nil
				for _, target in ipairs(Game.powerTargets) do
					if target.row == row and target.col == col then
						validTarget = target
						break
					end
				end

				if validTarget then
					-- For recruit, find the actual piece
					if Game.powerMode.powerId == "recruit" then
						validTarget = GameLogic.getPieceAt(Game.state, row, col)
					end
					Game.executepower(Game.powerMode.piece, Game.powerMode.powerId, validTarget)
				else
					-- Invalid target, cancel power mode
					Game.powerMode = nil
					Game.powerTargets = {}
				end
				return
			end

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
					local movingPiece = Game.state.selectedPiece
					Game.state = GameLogic.movePiece(Game.state, movingPiece, row, col)
					-- Collect orb if present
					Powers.collectOrb(movingPiece, Game.orbs)

					-- Check for extra move from move_again
					if Game.state.extraMove then
						Game.state.extraMove = nil
						Game.state = GameLogic.selectPiece(Game.state, movingPiece)
					else
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
	-- Allow escape and reset even during animations
	if key == "escape" then
		if Game.powerMode then
			Game.powerMode = nil
			Game.powerTargets = {}
		end
		return
	elseif key == "r" then
		Game.init()
		return
	end

	-- Block other input during blocking animations
	if Game.animations and GameAnimations.isBlocking(Game.animations) then
		return
	end

	if key == "h" and Game.hoveredTile then
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
	elseif tonumber(key) and Game.state.selectedPiece then
		-- Number key: activate power
		local index = tonumber(key)
		local piece = Game.state.selectedPiece
		if piece.powers and piece.powers[index] then
			Game.activatePower(piece, piece.powers[index])
		end
	end
end

function Game.activatePower(piece, powerId)
	local def = Powers.definitions[powerId]
	if not def then
		return
	end

	-- Check if power needs targeting
	local needsTarget = def.targeting == "adjacent"
		or def.targeting == "adjacent_enemy"
		or def.targeting == "adjacent_empty"

	if needsTarget then
		-- Enter power targeting mode
		Game.powerMode = { powerId = powerId, piece = piece }
		Game.powerTargets = Game.getPowerTargets(piece, powerId)
	else
		-- Activate immediately
		Game.executepower(piece, powerId, nil)
	end
end

function Game.getPowerTargets(piece, powerId)
	if powerId == "raise_tile" or powerId == "lower_tile" then
		return PowerEffects.getRaiseTileTargets(Game.state, piece)
	elseif powerId == "recruit" then
		return PowerEffects.getRecruitTargets(Game.state, piece)
	elseif powerId == "multiply" then
		return PowerEffects.getMultiplyTargets(Game.state, piece)
	end
	return {}
end

function Game.executepower(piece, powerId, target)
	local anim = nil

	-- Create animation with onComplete callback to apply effect
	if powerId == "destroy_row" then
		anim = Animations.createDestroyRow(piece.row, piece.col, function()
			Game.state = PowerEffects.activateDestroyRow(Game.state, piece)
			Game.refreshSelection()
		end)
	elseif powerId == "destroy_column" then
		anim = Animations.createDestroyColumn(piece.col, piece.row, function()
			Game.state = PowerEffects.activateDestroyColumn(Game.state, piece)
			Game.refreshSelection()
		end)
	elseif powerId == "raise_tile" and target then
		local fromHeight = GameLogic.getHeight(Game.state, target.row, target.col)
		anim = Animations.createRaiseTile(target.row, target.col, fromHeight, fromHeight + 1, function()
			Game.state = PowerEffects.activateRaiseTile(Game.state, piece, target)
			Game.refreshSelection()
		end)
	elseif powerId == "lower_tile" and target then
		local fromHeight = GameLogic.getHeight(Game.state, target.row, target.col)
		anim = Animations.createLowerTile(target.row, target.col, fromHeight, fromHeight - 1, function()
			Game.state = PowerEffects.activateLowerTile(Game.state, piece, target)
			Game.refreshSelection()
		end)
	elseif powerId == "recruit" and target then
		anim = Animations.createRecruit(target.row, target.col, target.player, piece.player, function()
			Game.state = PowerEffects.activateRecruit(Game.state, piece, target)
			Game.refreshSelection()
		end)
	elseif powerId == "multiply" and target then
		anim = Animations.createMultiply(piece.row, piece.col, target.row, target.col, function()
			Game.state = PowerEffects.activateMultiply(Game.state, piece, target)
			Game.refreshSelection()
		end)
	elseif powerId == "bomb" then
		anim = Animations.createBomb(piece.row, piece.col, function()
			Game.state = PowerEffects.activateBomb(Game.state, piece)
			Game.refreshSelection()
		end)
	elseif powerId == "relocate" then
		-- For relocate, we need to calculate destination first for animation
		-- For now, apply immediately and animate at new position
		local oldRow, oldCol = piece.row, piece.col
		Game.state = PowerEffects.activateRelocate(Game.state, piece)
		anim = Animations.createRelocate(oldRow, oldCol, piece.row, piece.col, function()
			Game.refreshSelection()
		end)
	elseif powerId == "move_again" then
		anim = Animations.createMoveAgain(piece.row, piece.col, function()
			Game.state = PowerEffects.activateMoveAgain(Game.state, piece)
			Game.refreshSelection()
		end)
	elseif powerId == "move_diagonal" then
		anim = Animations.createMoveDiagonal(piece.row, piece.col, function()
			Game.state = PowerEffects.activateMoveDiagonal(Game.state, piece)
			Game.refreshSelection()
		end)
	elseif powerId == "jump_proof" then
		anim = Animations.createJumpProof(piece.row, piece.col, function()
			Game.state = PowerEffects.activateJumpProof(Game.state, piece)
			Game.refreshSelection()
		end)
	elseif powerId == "invisible" then
		anim = Animations.createInvisible(piece.row, piece.col, function()
			Game.state = PowerEffects.activateInvisible(Game.state, piece)
			Game.refreshSelection()
		end)
	end

	-- Queue animation if created
	if anim and Game.animations then
		Animations.AnimationQueue.add(Game.animations.queue, anim)
	end

	-- Clear power mode
	Game.powerMode = nil
	Game.powerTargets = {}
end

function Game.refreshSelection()
	-- Refresh valid moves if piece still selected
	if Game.state.selectedPiece then
		Game.state = GameLogic.selectPiece(Game.state, Game.state.selectedPiece)
	end
end

function Game.wheelmoved(x, y) end

return Game
