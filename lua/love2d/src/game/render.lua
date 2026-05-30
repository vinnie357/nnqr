-- Game rendering sub-module
-- Augments the shared Game table with all draw* functions.
-- Loaded by src/game.lua via: require("src.game.render")(Game)

local GameLogic = require("src.shared.game_logic")
local Rendering = require("src.shared.rendering")
local Powers = require("src.shared.powers")
local GameAnimations = require("src.shared.game_animations")
local Animations = require("src.shared.animations")
local Indicators = require("src.shared.indicators")
local UI = require("src.shared.ui")
local Tooltip = require("src.shared.tooltip")
local Particles = require("src.shared.particles")
local AI = require("src.shared.ai.ai")

-- Multiplayer modules (optional - may not have luasocket)
local Multiplayer
pcall(function()
	Multiplayer = require("src.client.multiplayer")
end)

return function(Game)
	function Game.draw()
		local screen = UI.getScreen(Game.uiState)

		if screen == "menu" then
			Game.drawMenuScreen()
		elseif screen == "gamemode" then
			Game.drawGameModeScreen()
		elseif screen == "aiselect" then
			Game.drawAISelectScreen()
		elseif screen == "settings" then
			Game.drawSettingsScreen()
		elseif screen == "playing" then
			Game.drawPlayingScreen()
		elseif screen == "gameover" then
			Game.drawPlayingScreen() -- Draw board in background
			Game.drawGameOverScreen()
		elseif screen == "paused" then
			Game.drawPlayingScreen() -- Draw board in background
			Game.drawPausedScreen()
		elseif screen == "confirm" then
			Game.drawPlayingScreen() -- Draw board in background
			Game.drawConfirmScreen()
		elseif screen == "mpconnect" then
			Game.drawMPConnectScreen()
		elseif screen == "mplobby" then
			Game.drawMPLobbyScreen()
		elseif screen == "mpwaiting" then
			Game.drawMPWaitingScreen()
		elseif screen == "mpopponent" then
			Game.drawMPOpponentScreen()
		end
	end

	function Game.drawPlayingScreen()
		Game.drawBoard()
		Game.drawOrbs()
		Game.drawValidMoves()
		Game.drawPowerTargets()
		Game.drawPieces()
		Game.drawAnimations()
		Game.drawParticles()
		Game.drawUI()
		Game.drawPowerMenu()
		Game.drawTurnBanner()
		Game.drawAIIndicator()
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
			love.graphics.print(
				"Click target or ESC to cancel",
				menuX + 10,
				menuY + 30 + #piece.powers * itemHeight + 5
			)
		end

		-- Draw tooltip if hovering over a power
		if Game.hoveredPowerIndex and piece.powers[Game.hoveredPowerIndex] then
			Game.drawPowerTooltip(piece.powers[Game.hoveredPowerIndex])
		end
	end

	function Game.drawPowerTooltip(powerId)
		local lines = Tooltip.formatPowerTooltip(powerId)
		if not lines then
			return
		end

		local font = love.graphics.getFont()
		local charWidth = font:getWidth("M")
		local lineHeight = font:getHeight() * 1.2

		-- Calculate dimensions
		local maxWidth = 0
		for _, line in ipairs(lines) do
			maxWidth = math.max(maxWidth, font:getWidth(line))
		end
		local padding = 10
		local tooltipWidth = maxWidth + padding * 2
		local tooltipHeight = #lines * lineHeight + padding * 2

		-- Calculate position
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()
		local x, y = Tooltip.calculatePosition(Game.mouseX, Game.mouseY, tooltipWidth, tooltipHeight, screenW, screenH)

		-- Draw background
		love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
		love.graphics.rectangle("fill", x, y, tooltipWidth, tooltipHeight, 6, 6)

		-- Draw border
		love.graphics.setColor(0.5, 0.5, 0.6)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", x, y, tooltipWidth, tooltipHeight, 6, 6)

		-- Draw text
		for i, line in ipairs(lines) do
			local lineY = y + padding + (i - 1) * lineHeight
			if i == 1 then
				-- Title line - yellow/gold
				love.graphics.setColor(1, 0.9, 0.3)
			elseif line:match("^Category:") or line:match("^Duration:") then
				-- Label lines - gray
				love.graphics.setColor(0.7, 0.7, 0.7)
			else
				-- Description - white
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.print(line, x + padding, lineY)
		end
	end

	function Game.drawBoard()
		for row = 1, Game.state.rows do
			for col = 1, Game.state.cols do
				local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)

				-- Check if tile is destroyed
				if GameLogic.isTileDestroyed(Game.state, row, col) then
					-- Draw destroyed tile as a black pit
					Game.drawDestroyedTile(x, y)
				else
					local height = GameLogic.getHeight(Game.state, row, col)
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

	--- Draw a destroyed tile as a black hexagonal pit
	---@param x number Screen X position
	---@param y number Screen Y position
	function Game.drawDestroyedTile(x, y)
		local verts = Rendering.getTileVertices(x, y)

		-- Draw outer dark edge (pit rim)
		love.graphics.setColor(0.15, 0.1, 0.1)
		love.graphics.polygon("fill", verts)

		-- Draw inner pit (darker center)
		local innerScale = 0.7
		local innerVerts = {}
		for i = 1, #verts, 2 do
			local vx, vy = verts[i], verts[i + 1]
			-- Scale towards center
			table.insert(innerVerts, x + (vx - x) * innerScale)
			table.insert(innerVerts, y + (vy - y) * innerScale)
		end
		love.graphics.setColor(0.05, 0.02, 0.02)
		love.graphics.polygon("fill", innerVerts)

		-- Draw pit border
		love.graphics.setColor(0.08, 0.05, 0.05)
		love.graphics.setLineWidth(2)
		love.graphics.polygon("line", verts)
		love.graphics.setLineWidth(1)
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

			-- Overheat warning (8+ of same power)
			local maxPowerCount = Game.getMaxPowerCount(piece)
			if maxPowerCount >= 8 then
				local warningIntensity = (maxPowerCount - 7) / 3 -- 8=0.33, 9=0.67, 10+=1.0
				local pulse = (math.sin(love.timer.getTime() * (4 + maxPowerCount)) + 1) / 2

				-- Orange/red glow around piece
				if maxPowerCount >= 9 then
					-- Critical: Rapid red pulse
					love.graphics.setColor(1, 0.2, 0.1, 0.5 * pulse * warningIntensity)
				else
					-- Warning: Orange glow
					love.graphics.setColor(1, 0.5, 0.1, 0.3 * pulse * warningIntensity)
				end
				love.graphics.ellipse("fill", x, y - 10, 30, 15)

				-- Warning ring
				love.graphics.setLineWidth(2)
				if maxPowerCount >= 9 then
					love.graphics.setColor(1, 0.2, 0.1, 0.8 * pulse)
				else
					love.graphics.setColor(1, 0.6, 0.2, 0.6 * pulse)
				end
				love.graphics.ellipse("line", x, y - 10, 28, 14)
				love.graphics.setLineWidth(1)
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
				elseif indicator == "climb_tile" then
					-- Climb Tile: Upward arrows around piece
					love.graphics.setColor(0.9, 0.7, 0.3, 0.8)
					love.graphics.setLineWidth(2)
					local cx, cy = x, y - 10
					-- Draw small upward arrows
					for _, dx in ipairs({ -12, 12 }) do
						love.graphics.line(cx + dx, cy + 5, cx + dx, cy - 8)
						love.graphics.line(cx + dx - 4, cy - 4, cx + dx, cy - 8)
						love.graphics.line(cx + dx + 4, cy - 4, cx + dx, cy - 8)
					end
					love.graphics.setLineWidth(1)
				elseif indicator == "flat_to_sphere" then
					-- Flat to Sphere: Circular wrap indicator
					love.graphics.setColor(0.8, 0.4, 0.9, 0.7)
					love.graphics.setLineWidth(2)
					love.graphics.arc("line", "open", x, y - 10, 26, 0, math.pi * 2)
					-- Small arrows showing wrap direction
					love.graphics.setLineWidth(1)
				elseif indicator == "beneficiary" then
					-- Beneficiary: Blue plus sign (receives from allies)
					love.graphics.setColor(0.3, 0.6, 1, 0.9)
					love.graphics.setLineWidth(3)
					love.graphics.line(x - 6, y - 24, x + 6, y - 24)
					love.graphics.line(x, y - 30, x, y - 18)
					love.graphics.setLineWidth(1)
				elseif indicator == "scavenger" then
					-- Scavenger: Red X (receives from enemies)
					love.graphics.setColor(1, 0.3, 0.3, 0.9)
					love.graphics.setLineWidth(3)
					love.graphics.line(x - 5, y - 28, x + 5, y - 20)
					love.graphics.line(x + 5, y - 28, x - 5, y - 20)
					love.graphics.setLineWidth(1)
				elseif indicator == "tripwire" then
					-- Tripwire: Yellow warning triangle
					love.graphics.setColor(1, 0.9, 0.2, 0.9)
					love.graphics.setLineWidth(2)
					love.graphics.polygon("line", x, y - 30, x - 8, y - 18, x + 8, y - 18)
					love.graphics.setLineWidth(1)
				elseif indicator == "inhibited" then
					-- Inhibited: Red circle with slash (disabled)
					love.graphics.setColor(1, 0.2, 0.2, 0.8)
					love.graphics.setLineWidth(2)
					love.graphics.circle("line", x, y - 24, 8)
					love.graphics.line(x - 6, y - 18, x + 6, y - 30)
					love.graphics.setLineWidth(1)
				elseif indicator == "multiplied" then
					-- Multiplied: Small "x2" indicator
					love.graphics.setColor(0.5, 1, 0.5, 0.9)
					love.graphics.setLineWidth(1)
					-- Draw a small clone/copy icon
					love.graphics.rectangle("line", x + 10, y - 28, 8, 8)
					love.graphics.rectangle("line", x + 13, y - 31, 8, 8)
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
			love.graphics.print(
				string.format("Tile: %d,%d  H:%d", Game.hoveredTile.row, Game.hoveredTile.col, h),
				15,
				105
			)
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

	function Game.drawMenuScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Draw animated board in background (dimmed)
		Game.drawBoard()
		Game.drawPieces()

		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.2
		love.graphics.setColor(1, 1, 1)
		local title = "QUADRADIUS"
		local subtitle = "NNQR Edition"
		local font = love.graphics.getFont()
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)
		love.graphics.setColor(0.7, 0.7, 0.7)
		love.graphics.print(subtitle, (screenW - font:getWidth(subtitle)) / 2, titleY + 25)

		-- Menu items
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.45
		local itemSpacing = 35

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			if isSelected then
				-- Highlight background
				love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
				love.graphics.rectangle("fill", screenW / 2 - 100, itemY - 5, 200, 30, 5, 5)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, (screenW - font:getWidth("> " .. item)) / 2, itemY)
			else
				love.graphics.setColor(0.7, 0.7, 0.7)
				love.graphics.print(item, (screenW - font:getWidth(item)) / 2, itemY)
			end
		end

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Arrow Keys to navigate, Enter to select"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	function Game.drawSettingsScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Dark background
		love.graphics.setColor(0.1, 0.12, 0.15)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.15
		love.graphics.setColor(1, 1, 1)
		local title = "SETTINGS"
		local font = love.graphics.getFont()
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Menu items with volume bars
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.3
		local itemSpacing = 50

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			-- Item label
			if isSelected then
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, screenW * 0.2, itemY)
			else
				love.graphics.setColor(0.7, 0.7, 0.7)
				love.graphics.print(item, screenW * 0.2 + 10, itemY)
			end

			-- Volume bar for volume settings
			if item == "Master Volume" then
				Game.drawVolumeBar(screenW * 0.55, itemY, UI.getMasterVolume(Game.uiState), isSelected)
			elseif item == "SFX Volume" then
				Game.drawVolumeBar(screenW * 0.55, itemY, UI.getSFXVolume(Game.uiState), isSelected)
			elseif item == "Music Volume" then
				Game.drawVolumeBar(screenW * 0.55, itemY, UI.getMusicVolume(Game.uiState), isSelected)
			elseif item == "Sound Enabled" then
				Game.drawCheckbox(screenW * 0.55, itemY, not UI.isMuted(Game.uiState), isSelected)
			end
		end

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Left/Right to adjust, Enter to toggle, Escape to go back"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	function Game.drawVolumeBar(x, y, value, isSelected)
		local barWidth = 150
		local barHeight = 16
		local fillWidth = barWidth * value

		-- Background
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.rectangle("fill", x, y, barWidth, barHeight, 3, 3)

		-- Fill
		if isSelected then
			love.graphics.setColor(0.3, 0.6, 0.9)
		else
			love.graphics.setColor(0.4, 0.5, 0.6)
		end
		love.graphics.rectangle("fill", x, y, fillWidth, barHeight, 3, 3)

		-- Border
		love.graphics.setColor(0.5, 0.5, 0.5)
		love.graphics.rectangle("line", x, y, barWidth, barHeight, 3, 3)

		-- Percentage text
		love.graphics.setColor(1, 1, 1)
		local pct = string.format("%d%%", math.floor(value * 100))
		love.graphics.print(pct, x + barWidth + 10, y)
	end

	function Game.drawCheckbox(x, y, checked, isSelected)
		local size = 16

		-- Background
		love.graphics.setColor(0.2, 0.2, 0.2)
		love.graphics.rectangle("fill", x, y, size, size, 2, 2)

		-- Check mark
		if checked then
			if isSelected then
				love.graphics.setColor(0.3, 0.9, 0.4)
			else
				love.graphics.setColor(0.4, 0.7, 0.5)
			end
			love.graphics.setLineWidth(2)
			love.graphics.line(x + 3, y + 8, x + 6, y + 12, x + 13, y + 4)
			love.graphics.setLineWidth(1)
		end

		-- Border
		if isSelected then
			love.graphics.setColor(0.5, 0.8, 1)
		else
			love.graphics.setColor(0.5, 0.5, 0.5)
		end
		love.graphics.rectangle("line", x, y, size, size, 2, 2)
	end

	function Game.drawGameOverScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.8)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Winner announcement
		local winnerName = Game.state.winner == 1 and "BLUE" or "RED"
		local winColor = Game.state.winner == 1 and Game.colors.player1 or Game.colors.player2

		-- Pulsing glow effect
		local pulse = (math.sin(love.timer.getTime() * 3) + 1) / 2
		love.graphics.setColor(winColor[1], winColor[2], winColor[3], 0.3 + 0.2 * pulse)
		love.graphics.rectangle("fill", screenW / 2 - 150, screenH * 0.3 - 20, 300, 80, 10, 10)

		-- Winner text
		love.graphics.setColor(winColor)
		local font = love.graphics.getFont()
		local text = winnerName .. " WINS!"
		love.graphics.print(text, (screenW - font:getWidth(text)) / 2, screenH * 0.3)

		-- Final score
		local p1, p2 = 0, 0
		for _, p in ipairs(Game.state.pieces) do
			if p.player == 1 then
				p1 = p1 + 1
			else
				p2 = p2 + 1
			end
		end
		love.graphics.setColor(0.7, 0.7, 0.7)
		local scoreText = string.format("Final Score: %d - %d  |  Turns: %d", p1, p2, Game.state.turn)
		love.graphics.print(scoreText, (screenW - font:getWidth(scoreText)) / 2, screenH * 0.45)

		-- Menu items
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.55
		local itemSpacing = 35

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			if isSelected then
				love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
				love.graphics.rectangle("fill", screenW / 2 - 100, itemY - 5, 200, 30, 5, 5)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, (screenW - font:getWidth("> " .. item)) / 2, itemY)
			else
				love.graphics.setColor(0.7, 0.7, 0.7)
				love.graphics.print(item, (screenW - font:getWidth(item)) / 2, itemY)
			end
		end
	end

	function Game.drawPausedScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.8)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.25
		love.graphics.setColor(1, 1, 1)
		local title = "PAUSED"
		local font = love.graphics.getFont()
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Menu items
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.4
		local itemSpacing = 35

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			if isSelected then
				love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
				love.graphics.rectangle("fill", screenW / 2 - 100, itemY - 5, 200, 30, 5, 5)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, (screenW - font:getWidth("> " .. item)) / 2, itemY)
			else
				love.graphics.setColor(0.7, 0.7, 0.7)
				love.graphics.print(item, (screenW - font:getWidth(item)) / 2, itemY)
			end
		end

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Arrow Keys to navigate, Enter to select"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	function Game.drawConfirmScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.85)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Confirm dialog box
		local boxW, boxH = 400, 180
		local boxX = (screenW - boxW) / 2
		local boxY = (screenH - boxH) / 2

		-- Box background
		love.graphics.setColor(0.15, 0.17, 0.2)
		love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 10, 10)
		love.graphics.setColor(0.4, 0.5, 0.6)
		love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 10, 10)

		-- Title
		love.graphics.setColor(1, 0.8, 0.3)
		local font = love.graphics.getFont()
		local title = "Confirm"
		love.graphics.print(title, boxX + (boxW - font:getWidth(title)) / 2, boxY + 20)

		-- Message based on action
		local action = UI.getConfirmAction(Game.uiState)
		local message = "Are you sure?"
		if action == "new_game" then
			message = "Start a new game? Current progress will be lost."
		elseif action == "quit" then
			message = "Quit to desktop?"
		end

		love.graphics.setColor(0.9, 0.9, 0.9)
		love.graphics.print(message, boxX + (boxW - font:getWidth(message)) / 2, boxY + 60)

		-- Menu items (Yes/No)
		local menuItems = UI.getMenuItems(Game.uiState)
		local buttonY = boxY + 110
		local buttonSpacing = 100

		for i, item in ipairs(menuItems) do
			local buttonX = boxX + boxW / 2 + (i - 1.5) * buttonSpacing
			local isSelected = i == Game.uiState.selectedIndex

			if isSelected then
				love.graphics.setColor(0.3, 0.5, 0.8, 0.7)
				love.graphics.rectangle("fill", buttonX - 40, buttonY - 5, 80, 30, 5, 5)
				love.graphics.setColor(1, 1, 1)
			else
				love.graphics.setColor(0.6, 0.6, 0.6)
			end
			love.graphics.print(item, buttonX - font:getWidth(item) / 2, buttonY)
		end
	end

	function Game.drawGameModeScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Draw animated board in background (dimmed)
		Game.drawBoard()
		Game.drawPieces()

		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.2
		love.graphics.setColor(1, 1, 1)
		local title = "SELECT GAME MODE"
		local font = love.graphics.getFont()
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Menu items
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.4
		local itemSpacing = 35

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			if isSelected then
				-- Highlight background
				love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
				love.graphics.rectangle("fill", screenW / 2 - 100, itemY - 5, 200, 30, 5, 5)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, (screenW - font:getWidth("> " .. item)) / 2, itemY)
			else
				love.graphics.setColor(0.7, 0.7, 0.7)
				love.graphics.print(item, (screenW - font:getWidth(item)) / 2, itemY)
			end
		end

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Arrow Keys to navigate, Enter to select, Escape to go back"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	function Game.drawAISelectScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()

		-- Draw animated board in background (dimmed)
		Game.drawBoard()
		Game.drawPieces()

		-- Dark overlay
		love.graphics.setColor(0, 0, 0, 0.7)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.2
		love.graphics.setColor(1, 1, 1)
		local title = "SELECT DIFFICULTY"
		local font = love.graphics.getFont()
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Menu items
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.35
		local itemSpacing = 35

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			if isSelected then
				-- Highlight background
				love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
				love.graphics.rectangle("fill", screenW / 2 - 100, itemY - 5, 200, 30, 5, 5)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, (screenW - font:getWidth("> " .. item)) / 2, itemY)
			else
				love.graphics.setColor(0.7, 0.7, 0.7)
				love.graphics.print(item, (screenW - font:getWidth(item)) / 2, itemY)
			end
		end

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Arrow Keys to navigate, Enter to select, Escape to go back"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	function Game.drawAIIndicator()
		if not Game.ai then
			return
		end

		local screenW = love.graphics.getWidth()
		local font = love.graphics.getFont()
		local difficultyName = AI.getDifficultyDisplayName(Game.ai.difficulty)
		local text = "VS AI (" .. difficultyName .. ")"

		-- Background
		local textW = font:getWidth(text)
		local padding = 8
		local x = screenW - textW - padding * 2 - 10
		local y = 10

		love.graphics.setColor(0, 0, 0, 0.6)
		love.graphics.rectangle("fill", x, y, textW + padding * 2, 24, 4, 4)

		-- Text
		love.graphics.setColor(0.9, 0.9, 0.9)
		love.graphics.print(text, x + padding, y + 4)
	end

	function Game.drawTurnBanner()
		if not Game.turnBanner.active then
			return
		end

		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()
		local progress = Game.turnBanner.timer / Game.turnBanner.duration
		local player = Game.turnBanner.player

		-- Animation phases
		local sweepIn = math.min(1, progress * 5) -- 0-0.2s
		local scaleUp = math.max(0, math.min(1, (progress - 0.1) * 5)) -- 0.1-0.3s
		local fadeOut = math.max(0, (progress - 0.75) * 4) -- 0.75-1.0s

		-- Dark overlay sweep
		if sweepIn < 1 then
			love.graphics.setColor(0, 0, 0, 0.7 * sweepIn)
			love.graphics.rectangle("fill", 0, 0, screenW * sweepIn, screenH)
		else
			love.graphics.setColor(0, 0, 0, 0.7 * (1 - fadeOut))
			love.graphics.rectangle("fill", 0, 0, screenW, screenH)
		end

		-- Text
		if scaleUp > 0 then
			local playerName = player == 1 and "BLUE" or "RED"
			local text = playerName .. "'S TURN"
			local playerColor = player == 1 and Game.colors.player1 or Game.colors.player2

			-- Scale and alpha
			local scale = 0.5 + scaleUp * 0.7
			if scaleUp > 0.8 then
				scale = 1.2 - (scaleUp - 0.8) * 1.0 -- Settle from 1.2 to 1.0
			end
			local alpha = 1 - fadeOut

			-- Glow
			love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3], 0.4 * alpha)
			local font = love.graphics.getFont()
			local textW = font:getWidth(text) * scale
			love.graphics.rectangle(
				"fill",
				(screenW - textW) / 2 - 20,
				screenH / 2 - 30 * scale,
				textW + 40,
				60 * scale,
				10,
				10
			)

			-- Text
			love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3], alpha)
			love.graphics.print(text, (screenW - font:getWidth(text)) / 2, screenH / 2 - 10)
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

	function Game.drawParticles()
		if not Game.particles then
			return
		end

		local effects = Particles.getActiveEffects(Game.particles)
		for _, effect in ipairs(effects) do
			local progress = Particles.getProgress(effect)
			Game.drawParticleEffect(effect, progress)
		end
	end

	function Game.drawParticleEffect(effect, progress)
		local x, y = effect.x, effect.y
		local count = effect.count
		local spread = effect.spread
		local speed = effect.speed
		local speedY = effect.speedY or 0
		local size = effect.size
		local color = effect.color
		local fadeOut = effect.fadeOut

		-- Calculate alpha based on fadeOut
		local alpha = 1
		if fadeOut and progress > 0.5 then
			alpha = 1 - (progress - 0.5) * 2
		end

		-- Draw particles radiating outward
		for i = 1, count do
			-- Use a deterministic seed based on index for consistent particle positions
			local angle = (i / count) * math.rad(spread) - math.rad(spread / 2)
			local speedVal = speed.min + (speed.max - speed.min) * ((i % 5) / 4) -- Vary speed

			-- Calculate particle position based on elapsed time and speed
			local elapsed = effect.elapsed
			local px = x + math.cos(angle) * speedVal * elapsed
			local py = y + math.sin(angle) * speedVal * elapsed * 0.5 -- Isometric squash
			py = py + speedY * elapsed -- Apply vertical movement

			-- Size interpolation
			local currentSize = size.start + (size.finish - size.start) * progress

			-- Draw particle
			love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
			love.graphics.circle("fill", px, py, currentSize)
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

		-- Ground crack/rumble effect at start of animation
		if progress < 0.3 then
			local crackAlpha = (0.3 - progress) / 0.3
			love.graphics.setColor(0.4, 0.3, 0.2, crackAlpha * 0.8)
			love.graphics.setLineWidth(2)
			-- Draw crack lines radiating from center
			for i = 1, 4 do
				local angle = (i / 4) * math.pi * 2 + 0.4
				local len = 15 + math.random() * 10
				love.graphics.line(x, y, x + math.cos(angle) * len, y + math.sin(angle) * len * 0.5)
			end
			love.graphics.setLineWidth(1)
		end

		-- Rising/falling particles (more particles, varied sizes)
		for i = 1, 8 do
			local angle = (i / 8) * math.pi * 2
			local dist = 18 + (i % 3) * 4
			local px = x + math.cos(angle) * dist
			local baseY = y + math.sin(angle) * dist * 0.5
			local particleOffset = isRaising and (-25 * progress) or (25 * progress)
			local size = 2 + (i % 2)

			love.graphics.setColor(isRaising and 0.5 or 1, isRaising and 1 or 0.5, 0.3, 1 - progress)
			love.graphics.circle("fill", px, baseY + particleOffset, size)
		end

		-- Dust cloud at base
		if progress > 0.2 and progress < 0.8 then
			local dustAlpha = math.sin((progress - 0.2) / 0.6 * math.pi) * 0.4
			love.graphics.setColor(0.6, 0.5, 0.4, dustAlpha)
			love.graphics.ellipse("fill", x, y + 5, 25, 8)
		end

		-- Height indicator arrow
		local arrowAlpha = 0.8 * (1 - progress)
		if isRaising then
			love.graphics.setColor(0.3, 1, 0.5, arrowAlpha)
			love.graphics.polygon("fill", x, y - 30, x - 8, y - 20, x + 8, y - 20)
		else
			love.graphics.setColor(1, 0.5, 0.3, arrowAlpha)
			love.graphics.polygon("fill", x, y + 10, x - 8, y, x + 8, y)
		end
	end

	-- Recruit: Enemy piece changes color to your team
	function Game.drawRecruitAnimation(anim, progress)
		local row, col = anim.data.row, anim.data.col
		local height = GameLogic.getHeight(Game.state, row, col)
		local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height)

		local r, g, b = Animations.getRecruitColor(anim, progress)
		local fromPlayer = anim.data.fromPlayer
		local toPlayer = anim.data.toPlayer

		-- Get player colors
		local fromColor = fromPlayer == 1 and Game.colors.player1 or Game.colors.player2
		local toColor = toPlayer == 1 and Game.colors.player1 or Game.colors.player2

		-- Pulsing conversion aura
		local pulseScale = 1 + math.sin(progress * math.pi * 6) * 0.1
		love.graphics.setColor(r, g, b, 0.3 * (1 - progress))
		love.graphics.ellipse("fill", x, y - 10, 35 * pulseScale, 18 * pulseScale)

		-- Conversion glow ring (shrinking)
		love.graphics.setColor(r, g, b, 0.8)
		love.graphics.setLineWidth(3)
		love.graphics.ellipse("line", x, y - 10, 30 - 10 * progress, 15 - 5 * progress)
		love.graphics.setLineWidth(1)

		-- Color transition effect - old color fading out
		if progress < 0.5 then
			local fadeOut = 1 - progress * 2
			love.graphics.setColor(fromColor[1], fromColor[2], fromColor[3], fadeOut * 0.5)
			love.graphics.ellipse("fill", x, y - 10 - 15 * progress, 12, 6)
		end

		-- Color transition effect - new color fading in
		if progress > 0.3 then
			local fadeIn = (progress - 0.3) / 0.7
			love.graphics.setColor(toColor[1], toColor[2], toColor[3], fadeIn * 0.7)
			love.graphics.ellipse("fill", x, y - 10 + 15 * (1 - progress), 12, 6)
		end

		-- Spiraling particles (two colors interleaved)
		for i = 1, 12 do
			local angle = (i / 12) * math.pi * 2 + progress * math.pi * 6
			local dist = 28 * (1 - progress * 0.6)
			local px = x + math.cos(angle) * dist
			local py = y - 10 + math.sin(angle) * dist * 0.5

			-- Alternate between old and new color
			if i % 2 == 0 then
				local alpha = math.max(0, 1 - progress * 1.5)
				love.graphics.setColor(fromColor[1], fromColor[2], fromColor[3], alpha)
			else
				local alpha = math.min(1, progress * 1.5)
				love.graphics.setColor(toColor[1], toColor[2], toColor[3], alpha)
			end
			love.graphics.circle("fill", px, py, 3)
		end

		-- Conversion flash at midpoint
		if progress > 0.4 and progress < 0.6 then
			local flashAlpha = 1 - math.abs(progress - 0.5) * 10
			love.graphics.setColor(1, 1, 1, flashAlpha * 0.6)
			love.graphics.ellipse("fill", x, y - 10, 40, 20)
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

	-- Multiplayer Connect Screen
	function Game.drawMPConnectScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()
		local font = love.graphics.getFont()

		-- Dark background
		love.graphics.setColor(0.1, 0.12, 0.15)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.12
		love.graphics.setColor(1, 1, 1)
		local title = "MULTIPLAYER"
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Connection form
		local formY = screenH * 0.25
		local formX = screenW * 0.3
		local labelWidth = 120
		local fieldWidth = 200
		local fieldHeight = 28
		local spacing = 45

		-- Field indices for navigation
		local fields = { "name", "host", "port" }
		local fieldIndex = 1
		for i, f in ipairs(fields) do
			if Game.multiplayer and Game.multiplayer.inputField == f then
				fieldIndex = i
				break
			end
		end

		-- Player Name field
		local y = formY
		love.graphics.setColor(0.8, 0.8, 0.8)
		love.graphics.print("Player Name:", formX, y + 5)
		Game.drawInputField(
			formX + labelWidth,
			y,
			fieldWidth,
			fieldHeight,
			Game.multiplayer and Game.multiplayer.playerName or "Player",
			fieldIndex == 1
		)

		-- Server Host field
		y = y + spacing
		love.graphics.setColor(0.8, 0.8, 0.8)
		love.graphics.print("Server:", formX, y + 5)
		Game.drawInputField(
			formX + labelWidth,
			y,
			fieldWidth,
			fieldHeight,
			Game.multiplayer and Game.multiplayer.serverHost or "localhost",
			fieldIndex == 2
		)

		-- Port field
		y = y + spacing
		love.graphics.setColor(0.8, 0.8, 0.8)
		love.graphics.print("Port:", formX, y + 5)
		Game.drawInputField(
			formX + labelWidth,
			y,
			fieldWidth,
			fieldHeight,
			Game.multiplayer and tostring(Game.multiplayer.serverPort) or "7777",
			fieldIndex == 3
		)

		-- Status/Error messages
		y = y + spacing + 20
		if Game.multiplayer and Game.multiplayer.errorMessage and #Game.multiplayer.errorMessage > 0 then
			love.graphics.setColor(1, 0.4, 0.4)
			love.graphics.print(
				Game.multiplayer.errorMessage,
				(screenW - font:getWidth(Game.multiplayer.errorMessage)) / 2,
				y
			)
		elseif Game.multiplayer and Game.multiplayer.statusMessage and #Game.multiplayer.statusMessage > 0 then
			love.graphics.setColor(0.4, 0.8, 0.4)
			love.graphics.print(
				Game.multiplayer.statusMessage,
				(screenW - font:getWidth(Game.multiplayer.statusMessage)) / 2,
				y
			)
		end

		-- Buttons
		local buttonY = screenH * 0.65
		local buttonW = 120
		local buttonH = 35
		local buttonSpacing = 30

		-- Connect button
		local connectX = screenW / 2 - buttonW - buttonSpacing / 2
		Game.drawButton(connectX, buttonY, buttonW, buttonH, "Connect", fieldIndex == 4)

		-- Back button
		local backX = screenW / 2 + buttonSpacing / 2
		Game.drawButton(backX, buttonY, buttonW, buttonH, "Back", fieldIndex == 5)

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Tab/Arrow keys to navigate, Enter to connect/select, Escape to go back"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	-- Multiplayer Lobby Screen
	function Game.drawMPLobbyScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()
		local font = love.graphics.getFont()

		-- Dark background
		love.graphics.setColor(0.1, 0.12, 0.15)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.08
		love.graphics.setColor(1, 1, 1)
		local title = "GAME LOBBY"
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Connection status
		local statusY = titleY + 30
		love.graphics.setColor(0.4, 0.8, 0.4)
		local status = "Connected as: " .. (Game.multiplayer and Game.multiplayer.playerName or "Player")
		love.graphics.print(status, (screenW - font:getWidth(status)) / 2, statusY)

		-- Game list panel
		local listX = screenW * 0.15
		local listY = screenH * 0.2
		local listW = screenW * 0.7
		local listH = screenH * 0.45
		local itemH = 35

		-- Panel background
		love.graphics.setColor(0.15, 0.17, 0.2)
		love.graphics.rectangle("fill", listX, listY, listW, listH, 8, 8)
		love.graphics.setColor(0.3, 0.3, 0.35)
		love.graphics.rectangle("line", listX, listY, listW, listH, 8, 8)

		-- Header
		love.graphics.setColor(0.6, 0.6, 0.7)
		love.graphics.print("Available Games", listX + 10, listY + 10)

		-- Game list
		local games = Game.multiplayer and Multiplayer.getWaitingGames(Game.multiplayer) or {}
		local selectedIndex = Game.multiplayer and Game.multiplayer.selectedGameIndex or 1

		if #games == 0 then
			love.graphics.setColor(0.5, 0.5, 0.5)
			love.graphics.print("No games available. Create one!", listX + 10, listY + 50)
		else
			for i, game in ipairs(games) do
				local itemY = listY + 40 + (i - 1) * itemH
				if itemY + itemH > listY + listH - 10 then
					break -- Don't draw beyond panel
				end

				-- Selection highlight
				if i == selectedIndex then
					love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
					love.graphics.rectangle("fill", listX + 5, itemY, listW - 10, itemH - 5, 4, 4)
				end

				-- Game info
				love.graphics.setColor(1, 1, 1)
				local gameText = game.name or ("Game " .. (game.id or "?"))
				if game.host then
					gameText = gameText .. " (by " .. game.host .. ")"
				end
				love.graphics.print(gameText, listX + 15, itemY + 8)
			end
		end

		-- Error message
		if Game.multiplayer and Game.multiplayer.errorMessage and #Game.multiplayer.errorMessage > 0 then
			love.graphics.setColor(1, 0.4, 0.4)
			local errY = listY + listH + 10
			love.graphics.print(
				Game.multiplayer.errorMessage,
				(screenW - font:getWidth(Game.multiplayer.errorMessage)) / 2,
				errY
			)
		end

		-- Buttons
		local buttonY = screenH * 0.72
		local buttonW = 100
		local buttonH = 32
		local buttonSpacing = 15
		local totalButtonW = buttonW * 4 + buttonSpacing * 3
		local buttonStartX = (screenW - totalButtonW) / 2

		Game.drawButton(buttonStartX, buttonY, buttonW, buttonH, "Create", false)
		Game.drawButton(buttonStartX + buttonW + buttonSpacing, buttonY, buttonW, buttonH, "Join", false)
		Game.drawButton(buttonStartX + (buttonW + buttonSpacing) * 2, buttonY, buttonW, buttonH, "Refresh", false)
		Game.drawButton(buttonStartX + (buttonW + buttonSpacing) * 3, buttonY, buttonW, buttonH, "Disconnect", false)

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Up/Down to select, C=Create, J=Join, R=Refresh, Escape=Disconnect"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end

	-- Multiplayer Waiting Screen
	function Game.drawMPWaitingScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()
		local font = love.graphics.getFont()

		-- Dark background
		love.graphics.setColor(0.1, 0.12, 0.15)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.25
		love.graphics.setColor(1, 1, 1)
		local title = "WAITING FOR OPPONENT"
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Animated dots
		local dots = string.rep(".", math.floor(love.timer.getTime() * 2) % 4)
		love.graphics.setColor(0.7, 0.7, 0.7)
		love.graphics.print(dots, (screenW - font:getWidth("...")) / 2, titleY + 30)

		-- Available players count
		local availableY = screenH * 0.4
		local availablePlayers = 0
		if Game.multiplayer then
			availablePlayers = Multiplayer.getAvailablePlayerCount(Game.multiplayer)
		end
		if availablePlayers > 0 then
			love.graphics.setColor(0.4, 0.8, 0.4)
			local availableText =
				string.format("%d player%s available", availablePlayers, availablePlayers == 1 and "" or "s")
			love.graphics.print(availableText, (screenW - font:getWidth(availableText)) / 2, availableY)
		else
			love.graphics.setColor(0.8, 0.5, 0.3)
			local noPlayersText = "No other players available"
			love.graphics.print(noPlayersText, (screenW - font:getWidth(noPlayersText)) / 2, availableY)
		end

		-- Game info
		local infoY = screenH * 0.5
		love.graphics.setColor(0.6, 0.6, 0.7)
		local infoText = "You created a game. Waiting for someone to join..."
		love.graphics.print(infoText, (screenW - font:getWidth(infoText)) / 2, infoY)

		-- AI option hint
		local aiHintY = screenH * 0.6
		love.graphics.setColor(0.5, 0.8, 0.5)
		local aiHint = "Press A to play vs AI instead"
		love.graphics.print(aiHint, (screenW - font:getWidth(aiHint)) / 2, aiHintY)

		-- Cancel button hint
		local hintY = screenH * 0.75
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Press Escape to cancel and return to lobby"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, hintY)
	end

	-- Helper: Draw input field
	function Game.drawInputField(x, y, w, h, text, selected)
		-- Background
		if selected then
			love.graphics.setColor(0.25, 0.27, 0.32)
		else
			love.graphics.setColor(0.18, 0.2, 0.24)
		end
		love.graphics.rectangle("fill", x, y, w, h, 4, 4)

		-- Border
		if selected then
			love.graphics.setColor(0.4, 0.6, 0.9)
		else
			love.graphics.setColor(0.35, 0.35, 0.4)
		end
		love.graphics.rectangle("line", x, y, w, h, 4, 4)

		-- Text
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(text, x + 8, y + 6)

		-- Cursor for selected field
		if selected then
			local cursorX = x + 8 + love.graphics.getFont():getWidth(text)
			local blink = math.floor(love.timer.getTime() * 2) % 2 == 0
			if blink then
				love.graphics.setColor(1, 1, 1)
				love.graphics.rectangle("fill", cursorX, y + 5, 2, h - 10)
			end
		end
	end

	-- Helper: Draw button
	function Game.drawButton(x, y, w, h, text, selected)
		-- Background
		if selected then
			love.graphics.setColor(0.3, 0.5, 0.8)
		else
			love.graphics.setColor(0.25, 0.27, 0.32)
		end
		love.graphics.rectangle("fill", x, y, w, h, 5, 5)

		-- Border
		love.graphics.setColor(0.4, 0.4, 0.45)
		love.graphics.rectangle("line", x, y, w, h, 5, 5)

		-- Text
		love.graphics.setColor(1, 1, 1)
		local font = love.graphics.getFont()
		local textW = font:getWidth(text)
		local textH = font:getHeight()
		love.graphics.print(text, x + (w - textW) / 2, y + (h - textH) / 2)
	end

	-- Multiplayer Opponent Selection Screen (Phase 4: AI Practice)
	function Game.drawMPOpponentScreen()
		local screenW = love.graphics.getWidth()
		local screenH = love.graphics.getHeight()
		local font = love.graphics.getFont()

		-- Dark background
		love.graphics.setColor(0.1, 0.12, 0.15)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)

		-- Title
		local titleY = screenH * 0.12
		love.graphics.setColor(1, 1, 1)
		local title = "CREATE GAME"
		love.graphics.print(title, (screenW - font:getWidth(title)) / 2, titleY)

		-- Subtitle
		love.graphics.setColor(0.7, 0.7, 0.7)
		local subtitle = "Select opponent type"
		love.graphics.print(subtitle, (screenW - font:getWidth(subtitle)) / 2, titleY + 25)

		-- Menu items
		local menuItems = UI.getMenuItems(Game.uiState)
		local menuY = screenH * 0.28
		local itemSpacing = 38

		for i, item in ipairs(menuItems) do
			local itemY = menuY + (i - 1) * itemSpacing
			local isSelected = i == Game.uiState.selectedIndex

			-- Draw separator before AI Practice options
			if i == 2 then
				love.graphics.setColor(0.3, 0.3, 0.35)
				love.graphics.line(screenW / 2 - 100, itemY - 10, screenW / 2 + 100, itemY - 10)
			end

			-- Draw separator before Cancel
			if i == #menuItems then
				love.graphics.setColor(0.3, 0.3, 0.35)
				love.graphics.line(screenW / 2 - 100, itemY - 10, screenW / 2 + 100, itemY - 10)
			end

			if isSelected then
				-- Highlight background
				love.graphics.setColor(0.3, 0.5, 0.8, 0.5)
				love.graphics.rectangle("fill", screenW / 2 - 120, itemY - 5, 240, 32, 5, 5)
				love.graphics.setColor(1, 1, 1)
				love.graphics.print("> " .. item, (screenW - font:getWidth("> " .. item)) / 2, itemY)
			else
				-- Color AI Practice items differently
				if item:match("^AI Practice") then
					love.graphics.setColor(0.6, 0.8, 0.6)
				else
					love.graphics.setColor(0.7, 0.7, 0.7)
				end
				love.graphics.print(item, (screenW - font:getWidth(item)) / 2, itemY)
			end
		end

		-- Available players info
		local availableY = screenH * 0.78
		local availablePlayers = 0
		if Game.multiplayer then
			availablePlayers = Multiplayer.getAvailablePlayerCount
					and Multiplayer.getAvailablePlayerCount(Game.multiplayer)
				or 0
		end
		love.graphics.setColor(0.5, 0.5, 0.5)
		local availableText =
			string.format("%d player%s available", availablePlayers, availablePlayers == 1 and "" or "s")
		love.graphics.print(availableText, (screenW - font:getWidth(availableText)) / 2, availableY)

		-- Controls hint
		love.graphics.setColor(0.5, 0.5, 0.5)
		local hint = "Up/Down to navigate, Enter to select, Escape to cancel"
		love.graphics.print(hint, (screenW - font:getWidth(hint)) / 2, screenH - 50)
	end
end
