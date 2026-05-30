-- Game controller sub-module
-- Augments the shared Game table with update, action, and multiplayer-event functions.
-- Loaded by src/game.lua via: require("src.game.controller")(Game)

local GameLogic = require("src.shared.game_logic")
local Rendering = require("src.shared.rendering")
local Powers = require("src.shared.powers")
local PowerEffects = require("src.shared.power_effects")
local PowerExecutor = require("src.shared.power_executor")
local GameAnimations = require("src.shared.game_animations")
local Animations = require("src.shared.animations")
local UI = require("src.shared.ui")
local Particles = require("src.shared.particles")
local ParticleConfig = require("src.shared.particle_config")
local AI = require("src.shared.ai.ai")

-- Multiplayer modules (optional - may not have luasocket)
local Multiplayer
pcall(function()
	Multiplayer = require("src.client.multiplayer")
end)

return function(Game)
	function Game.update(dt)
		local screen = UI.getScreen(Game.uiState)

		-- Update turn banner
		if Game.turnBanner.active then
			Game.turnBanner.timer = Game.turnBanner.timer + dt
			if Game.turnBanner.timer >= Game.turnBanner.duration then
				Game.turnBanner.active = false
			end
		end

		-- Update multiplayer networking
		if Game.multiplayer and Multiplayer.isConnected(Game.multiplayer) then
			local event = Multiplayer.update(Game.multiplayer)
			if event then
				Game.handleMultiplayerEvent(event)
			end
		end

		-- Only update game state when playing
		if screen ~= "playing" then
			return
		end

		-- Update animations
		if Game.animations then
			GameAnimations.update(Game.animations, dt)
		end

		-- Update particles
		if Game.particles then
			Particles.update(Game.particles, dt)
		end

		-- Update hovered tile
		local mx, my = love.mouse.getPosition()
		local row, col = Rendering.screenToBoard(mx, my, Game.boardOffsetX, Game.boardOffsetY)
		if row >= 1 and row <= Game.state.rows and col >= 1 and col <= Game.state.cols then
			Game.hoveredTile = { row = row, col = col }
		else
			Game.hoveredTile = nil
		end

		-- Handle AI turn
		if Game.ai and AI.isAITurn(Game.ai, Game.state) and Game.state.gameState == "playing" then
			Game.aiThinkingTimer = Game.aiThinkingTimer + dt
			if Game.aiThinkingTimer >= Game.aiThinkingDelay then
				Game.executeAIMove()
				Game.aiThinkingTimer = 0
			end
		end
	end

	--- Execute the AI's chosen move
	function Game.executeAIMove()
		if not Game.ai then
			return
		end

		local move = AI.chooseMove(Game.ai, Game.state)
		if not move then
			-- No valid moves - end turn (or handle stalemate)
			Game.state = GameLogic.endTurn(Game.state)
			return
		end

		local movingPiece = Game.state.pieces[move.piece]
		local targetPiece = GameLogic.getPieceAt(Game.state, move.target.row, move.target.col)

		-- Execute the move
		Game.state = GameLogic.movePiece(Game.state, movingPiece, move.target.row, move.target.col)

		-- Play move or capture sound
		if targetPiece then
			Game.playSoundForEvent("capture")
		else
			Game.playSoundForEvent("move")
		end

		-- Collect orb if present
		local collectedOrb = Powers.collectOrb(movingPiece, Game.orbs)
		if collectedOrb then
			Game.spawnOrbParticles(movingPiece.row, movingPiece.col)

			-- Check for overheat (10+ of same power = explosion)
			local overheatedPower = Powers.checkOverheat(movingPiece)
			if overheatedPower then
				Game.handlePieceOverheat(movingPiece, overheatedPower)
			end
		end

		-- End the turn (AI doesn't use extra moves for now)
		Game.state = GameLogic.endTurn(Game.state)

		-- Check for game over
		if Game.state.gameState == "gameover" then
			UI.setScreen(Game.uiState, "gameover")
		else
			-- Show turn banner for new player
			Game.showTurnBanner(Game.state.currentPlayer)

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
	end

	function Game.showTurnBanner(player)
		Game.turnBanner.active = true
		Game.turnBanner.timer = 0
		Game.turnBanner.player = player
	end

	function Game.startNewGame()
		-- Reset game state
		Game.state = GameLogic.createInitialState()
		Game.generateTerrain()
		Game.orbs = {}
		Game.animations = GameAnimations.create()
		Game.particles = Particles.create()
		Game.powerMode = nil
		Game.powerTargets = {}
		Game.turnBanner = {
			active = false,
			timer = 0,
			duration = 2.0,
			player = 1,
		}
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
			or def.targeting == "adjacent_destroyed"
			or def.targeting == "special"

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
		elseif powerId == "refurb" then
			return PowerEffects.getRefurbTargets(Game.state, piece)
		elseif powerId == "switcheroo" then
			return PowerEffects.getSwitcherooTargets(Game.state, piece)
		elseif powerId == "centerpult" then
			return PowerEffects.getCenterpultTargets(Game.state, piece)
		end
		return {}
	end

	function Game.executepower(piece, powerId, target)
		-- Play power sound
		Game.playSoundForPower(powerId)

		-- Spawn particles at piece position
		Game.spawnPowerParticles(powerId, piece.row, piece.col)

		local anim = nil

		-- Handle special animation cases that need target or position data
		if powerId == "raise_tile" and target then
			local fromHeight = GameLogic.getHeight(Game.state, target.row, target.col)
			anim = Animations.createRaiseTile(target.row, target.col, fromHeight, fromHeight + 1, function()
				Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
				Game.refreshSelection()
			end)
		elseif powerId == "lower_tile" and target then
			local fromHeight = GameLogic.getHeight(Game.state, target.row, target.col)
			anim = Animations.createLowerTile(target.row, target.col, fromHeight, fromHeight - 1, function()
				Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
				Game.refreshSelection()
			end)
		elseif powerId == "recruit" and target then
			anim = Animations.createRecruit(target.row, target.col, target.player, piece.player, function()
				Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
				Game.refreshSelection()
			end)
		elseif powerId == "multiply" and target then
			anim = Animations.createMultiply(piece.row, piece.col, target.row, target.col, function()
				Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
				Game.refreshSelection()
			end)
		elseif powerId == "relocate" then
			-- For relocate, we need to calculate destination first for animation
			-- Apply immediately to get new position, then animate
			local oldRow, oldCol = piece.row, piece.col
			Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
			anim = Animations.createRelocate(oldRow, oldCol, piece.row, piece.col, function()
				Game.refreshSelection()
			end)
		elseif powerId == "refurb" and target then
			-- Refurb restores a destroyed tile - use a raise animation to show restoration
			anim = Animations.createRaiseTile(target.row, target.col, -1, 0, function()
				Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
				Game.refreshSelection()
			end)
		elseif powerId == "switcheroo" and target then
			-- Switcheroo swaps positions - use relocate animation for visual swap
			local oldRow, oldCol = piece.row, piece.col
			Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
			-- Animate piece moving to target position
			anim = Animations.createRelocate(oldRow, oldCol, piece.row, piece.col, function()
				Game.refreshSelection()
			end)
		else
			-- Use generic animation system for all other powers
			anim = GameAnimations.createPowerAnimation(piece, powerId, function()
				Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
				Game.refreshSelection()
			end)
		end

		-- Queue animation if created
		if anim and Game.animations then
			Animations.AnimationQueue.add(Game.animations.queue, anim)
		elseif not anim then
			-- No animation - execute power immediately
			Game.state = PowerExecutor.execute(Game.state, piece, powerId, target)
			Game.refreshSelection()
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

	function Game.spawnPowerParticles(powerId, row, col)
		if not Game.particles then
			return
		end

		local height = GameLogic.getHeight(Game.state, row, col)
		local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height) - 10 -- Center on piece

		local effectType = ParticleConfig.getPowerEffect(powerId)
		Particles.spawn(Game.particles, effectType, x, y)
	end

	function Game.spawnOrbParticles(row, col)
		if not Game.particles then
			return
		end

		local height = GameLogic.getHeight(Game.state, row, col)
		local x, y = Rendering.boardToScreen(row, col, Game.boardOffsetX, Game.boardOffsetY)
		y = y + Rendering.getHeightOffset(height) - 8 -- Center on orb

		Particles.spawn(Game.particles, "orb_collect", x, y)
	end

	--- Handle piece overheating (10+ of same power causes explosion)
	---@param piece table The piece that overheated
	---@param powerId string The power ID that caused the overheat
	function Game.handlePieceOverheat(piece, powerId)
		-- Spawn explosion particles at piece location
		if Game.particles then
			local height = GameLogic.getHeight(Game.state, piece.row, piece.col)
			local x, y = Rendering.boardToScreen(piece.row, piece.col, Game.boardOffsetX, Game.boardOffsetY)
			y = y + Rendering.getHeightOffset(height) - 10

			Particles.spawn(Game.particles, "explosion", x, y)
		end

		-- Play explosion sound
		Game.playSoundForEvent("capture") -- Reuse capture sound for now

		-- Remove piece from game
		for i, p in ipairs(Game.state.pieces) do
			if p == piece then
				table.remove(Game.state.pieces, i)
				break
			end
		end

		-- Clear selection if this was the selected piece
		if Game.state.selectedPiece == piece then
			Game.state.selectedPiece = nil
			Game.state.validMoves = {}
		end
	end

	--- Get the highest count of any single power on a piece (for visual warnings)
	---@param piece table The piece to check
	---@return number, string|nil The highest count and the power ID, or 0, nil
	function Game.getMaxPowerCount(piece)
		if not piece.powers or #piece.powers == 0 then
			return 0, nil
		end

		local counts = {}
		for _, powerId in ipairs(piece.powers) do
			counts[powerId] = (counts[powerId] or 0) + 1
		end

		local maxCount = 0
		local maxPower = nil
		for powerId, count in pairs(counts) do
			if count > maxCount then
				maxCount = count
				maxPower = powerId
			end
		end

		return maxCount, maxPower
	end

	-- Handle multiplayer events from network
	function Game.handleMultiplayerEvent(event)
		if not Game.multiplayer then
			return
		end

		local screen = UI.getScreen(Game.uiState)

		if event == "game_started" then
			-- Game started! Initialize game state and switch to playing
			Game.init()
			Game.ai = nil -- Not vs AI
			-- Sync game state from server if available
			if Game.multiplayer.gameState then
				Game.applyServerGameState(Game.multiplayer.gameState)
			end
			UI.setScreen(Game.uiState, "playing")
			Game.showTurnBanner(1)
		elseif event == "game_state_updated" then
			-- Game state updated (e.g., after our move or AI move)
			if Game.multiplayer.gameState then
				local previousPlayer = Game.state.currentPlayer
				Game.applyServerGameState(Game.multiplayer.gameState)
				-- Show turn banner if player changed
				if Game.state.currentPlayer ~= previousPlayer then
					Game.showTurnBanner(Game.state.currentPlayer)
				end
				-- Check for game over
				if Game.state.gameState == "gameover" then
					UI.setScreen(Game.uiState, "gameover")
				end
			end
		elseif event == "ai_game_created" then
			-- AI game created on server - initialize and sync with server state
			Game.init()
			Game.ai = nil -- AI is on server, not local
			-- Mark this as a server-side AI game
			Game.serverAIGame = true

			-- Apply server game state (surgically update deltas)
			if Game.multiplayer.gameState then
				Game.applyServerGameState(Game.multiplayer.gameState)
			end

			UI.setScreen(Game.uiState, "playing")
			Game.showTurnBanner(1)
		elseif event == "game_joined" then
			-- We joined a game, wait for game state
			if screen == "mplobby" then
				UI.setScreen(Game.uiState, "mpwaiting")
			end
		elseif event == "game_over" then
			-- Game ended
			if Game.multiplayer.gameState then
				Game.state.gameState = "gameover"
				Game.state.winner = Game.multiplayer.gameState.winner
			end
			UI.setScreen(Game.uiState, "gameover")
		elseif event == "disconnected" then
			-- Lost connection to server
			if screen == "mplobby" or screen == "mpwaiting" or screen == "playing" or screen == "mpopponent" then
				UI.setScreen(Game.uiState, "mpconnect")
			end
		elseif event == "lobby_updated" then
			-- Lobby state refreshed - nothing special needed
		elseif event == "error" then
			-- Error occurred - message is already set in multiplayer.errorMessage
		end
	end

	--- Apply server game state to local state (surgical delta update)
	---@param serverState table Server game state
	function Game.applyServerGameState(serverState)
		if not serverState then
			return
		end

		-- Track game ID for future server communication
		Game.serverGameId = serverState.game_id

		-- Update turn info
		if serverState.turn then
			Game.state.turn = serverState.turn
		end
		if serverState.current_player then
			Game.state.currentPlayer = serverState.current_player
		end

		-- Update winner/game over state
		if serverState.winner then
			Game.state.winner = serverState.winner
		end
		if serverState.game_over then
			Game.state.gameState = "gameover"
		end

		-- Update board heights from tiles
		if serverState.board and serverState.board.tiles then
			for _, tile in ipairs(serverState.board.tiles) do
				if tile.height then
					GameLogic.setHeight(Game.state, tile.row, tile.col, tile.height)
				end
				if tile.destroyed then
					Game.state.destroyedTiles[tile.row .. "," .. tile.col] = true
				end
			end
		end

		-- Update pieces
		if serverState.pieces then
			Game.state.pieces = {}
			for _, sp in ipairs(serverState.pieces) do
				local piece = {
					col = sp.col,
					row = sp.row,
					player = sp.player,
					powers = sp.powers or {},
					canMoveDiagonally = sp.canMoveDiagonally,
					isJumpProof = sp.isJumpProof,
					isInvisible = not sp.visible,
				}
				table.insert(Game.state.pieces, piece)
			end
		end

		-- Update orbs if present in tile data
		if serverState.board and serverState.board.tiles then
			Game.orbs = {}
			for _, tile in ipairs(serverState.board.tiles) do
				if tile.orb then
					table.insert(Game.orbs, {
						row = tile.row,
						col = tile.col,
						power_id = tile.orb,
					})
				end
			end
		end
	end

	-- Start multiplayer AI practice game
	function Game.startMultiplayerAIGame(difficulty)
		if not Game.multiplayer then
			return
		end

		-- TODO: Send CREATE_AI_GAME to server and handle response
		-- For now, fall back to local AI game with multiplayer context
		Multiplayer.clearError(Game.multiplayer)

		-- Check if multiplayer module supports AI games
		if Multiplayer.createAIGame then
			Multiplayer.createAIGame(Game.multiplayer, difficulty)
			-- Server will respond with AI_GAME_CREATED, then GAME_STATE
		else
			-- Fallback: disconnect and play local AI game
			Multiplayer.disconnect(Game.multiplayer)
			Game.multiplayer = nil
			Game.startVsAI(difficulty)
			UI.setScreen(Game.uiState, "playing")
			Game.showTurnBanner(1)
		end
	end
end
