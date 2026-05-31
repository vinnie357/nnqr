-- Game input sub-module
-- Augments the shared Game table with all input handler functions.
-- Loaded by src/game.lua via: require("src.game.input")(Game)

local GameLogic = require("src.shared.game_logic")
local Rendering = require("src.shared.rendering")
local Powers = require("src.shared.powers")
local GameAnimations = require("src.shared.game_animations")
local UI = require("src.shared.ui")

-- Multiplayer modules (optional - may not have luasocket)
local Multiplayer
pcall(function()
	Multiplayer = require("src.client.multiplayer")
end)

return function(Game)
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

						-- Server-side AI game: send move to server instead of local execution
						if Game.serverAIGame and Game.multiplayer then
							local from = { col = movingPiece.col, row = movingPiece.row }
							local to = { col = col, row = row }
							Multiplayer.sendMove(Game.multiplayer, from, to)
							-- Clear selection - server will respond with updated GAME_STATE
							Game.state.selectedPiece = nil
							Game.state.validMoves = {}
							return
						end

						-- Local game: execute move directly
						local targetPiece = GameLogic.getPieceAt(Game.state, row, col)
						Game.state = GameLogic.movePiece(Game.state, movingPiece, row, col)

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

						-- Check for extra move from move_again
						if Game.state.extraMove then
							Game.state.extraMove = nil
							Game.state = GameLogic.selectPiece(Game.state, movingPiece)
						else
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
					elseif clickedPiece and clickedPiece.player == Game.state.currentPlayer then
						Game.state = GameLogic.selectPiece(Game.state, clickedPiece)
						Game.playSoundForEvent("select")
					else
						Game.state = GameLogic.selectPiece(Game.state, nil)
					end
				elseif clickedPiece and clickedPiece.player == Game.state.currentPlayer then
					Game.state = GameLogic.selectPiece(Game.state, clickedPiece)
					Game.playSoundForEvent("select")
				end
			end
		end
	end

	function Game.mousereleased(x, y, button) end

	function Game.mousemoved(x, y, dx, dy)
		Game.mouseX = x
		Game.mouseY = y

		-- Guard against nil uiState (e.g. during tests)
		if not Game.uiState then
			return
		end

		-- Check for power menu hover (only on playing screen with selected piece)
		local screen = UI.getScreen(Game.uiState)
		if screen == "playing" then
			local piece = Game.state.selectedPiece
			if piece and piece.powers and #piece.powers > 0 then
				-- Power menu bounds
				local menuX = love.graphics.getWidth() - 200
				local menuY = 100
				local menuWidth = 190
				local itemHeight = 30
				local headerHeight = 25

				-- Check if mouse is over a power item
				Game.hoveredPowerIndex = nil
				for i = 1, #piece.powers do
					local itemY = menuY + headerHeight + (i - 1) * itemHeight
					if x >= menuX and x <= menuX + menuWidth and y >= itemY and y <= itemY + itemHeight then
						Game.hoveredPowerIndex = i
						break
					end
				end
			else
				Game.hoveredPowerIndex = nil
			end
		else
			Game.hoveredPowerIndex = nil
		end
	end

	function Game.keypressed(key)
		local screen = UI.getScreen(Game.uiState)

		-- Handle menu screens
		if screen == "menu" then
			Game.handleMenuInput(key)
			return
		elseif screen == "gamemode" then
			Game.handleGameModeInput(key)
			return
		elseif screen == "aiselect" then
			Game.handleAISelectInput(key)
			return
		elseif screen == "settings" then
			Game.handleSettingsInput(key)
			return
		elseif screen == "gameover" then
			Game.handleGameOverInput(key)
			return
		elseif screen == "paused" then
			Game.handlePausedInput(key)
			return
		elseif screen == "confirm" then
			Game.handleConfirmInput(key)
			return
		elseif screen == "mpconnect" then
			Game.handleMPConnectInput(key)
			return
		elseif screen == "mplobby" then
			Game.handleMPLobbyInput(key)
			return
		elseif screen == "mpwaiting" then
			Game.handleMPWaitingInput(key)
			return
		elseif screen == "mpopponent" then
			Game.handleMPOpponentInput(key)
			return
		elseif screen == "history" then
			Game.handleHistoryInput(key)
			return
		end

		-- Playing screen input
		-- Allow escape and reset even during animations
		if key == "escape" then
			if Game.powerMode then
				Game.powerMode = nil
				Game.powerTargets = {}
			else
				-- Open pause menu
				UI.setScreen(Game.uiState, "paused")
			end
			return
		elseif key == "r" then
			Game.startNewGame()
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

	function Game.handleMenuInput(key)
		if key == "up" then
			UI.selectPrev(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "down" then
			UI.selectNext(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "return" or key == "space" then
			Game.playSoundForEvent("menu_confirm")
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "New Game" then
				UI.setScreen(Game.uiState, "gamemode")
			elseif selected == "Match History" then
				Game.uiState.historyScrollOffset = 0
				UI.setScreen(Game.uiState, "history")
			elseif selected == "Settings" then
				Game.settingsReturnScreen = "menu"
				UI.setScreen(Game.uiState, "settings")
			elseif selected == "Quit" then
				love.event.quit()
			end
		end
	end

	function Game.handleHistoryInput(key)
		if key == "escape" or key == "backspace" then
			Game.playSoundForEvent("menu_back")
			UI.setScreen(Game.uiState, "menu")
		elseif key == "return" or key == "space" then
			Game.playSoundForEvent("menu_confirm")
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Back" then
				UI.setScreen(Game.uiState, "menu")
			end
		elseif key == "up" then
			if Game.uiState.historyScrollOffset > 0 then
				Game.uiState.historyScrollOffset = Game.uiState.historyScrollOffset - 1
			end
		elseif key == "down" then
			Game.uiState.historyScrollOffset = Game.uiState.historyScrollOffset + 1
		end
	end

	function Game.handleGameModeInput(key)
		if key == "up" then
			UI.selectPrev(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "down" then
			UI.selectNext(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "escape" then
			Game.playSoundForEvent("menu_back")
			UI.setScreen(Game.uiState, "menu")
		elseif key == "return" or key == "space" then
			Game.playSoundForEvent("menu_confirm")
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Local 2-Player" then
				Game.startTwoPlayer()
				UI.setScreen(Game.uiState, "playing")
				Game.showTurnBanner(1)
			elseif selected == "VS AI" then
				UI.setScreen(Game.uiState, "aiselect")
			elseif selected == "Multiplayer" then
				if Game.startMultiplayer() then
					-- Multiplayer started successfully
				else
					-- Show error - multiplayer not available
					Game.multiplayer = Game.multiplayer or {}
					if Game.multiplayer then
						Game.multiplayer.errorMessage = "Multiplayer requires luasocket"
					end
				end
			elseif selected == "Back" then
				UI.setScreen(Game.uiState, "menu")
			end
		end
	end

	function Game.handleAISelectInput(key)
		if key == "up" then
			UI.selectPrev(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "down" then
			UI.selectNext(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "escape" then
			Game.playSoundForEvent("menu_back")
			UI.setScreen(Game.uiState, "gamemode")
		elseif key == "return" or key == "space" then
			Game.playSoundForEvent("menu_confirm")
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Back" then
				UI.setScreen(Game.uiState, "gamemode")
			else
				-- Easy, Medium, Hard, Expert - convert to lowercase for AI.create
				local difficulty = string.lower(selected)
				Game.startVsAI(difficulty)
				UI.setScreen(Game.uiState, "playing")
				Game.showTurnBanner(1)
			end
		end
	end

	function Game.handleSettingsInput(key)
		if key == "up" then
			UI.selectPrev(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "down" then
			UI.selectNext(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "left" then
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Master Volume" then
				UI.adjustVolume(Game.uiState, "master", -0.1)
				Game.syncSoundSettings()
			elseif selected == "SFX Volume" then
				UI.adjustVolume(Game.uiState, "sfx", -0.1)
				Game.syncSoundSettings()
			elseif selected == "Music Volume" then
				UI.adjustVolume(Game.uiState, "music", -0.1)
				Game.syncSoundSettings()
			end
		elseif key == "right" then
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Master Volume" then
				UI.adjustVolume(Game.uiState, "master", 0.1)
				Game.syncSoundSettings()
			elseif selected == "SFX Volume" then
				UI.adjustVolume(Game.uiState, "sfx", 0.1)
				Game.syncSoundSettings()
			elseif selected == "Music Volume" then
				UI.adjustVolume(Game.uiState, "music", 0.1)
				Game.syncSoundSettings()
			end
		elseif key == "return" or key == "space" then
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Sound Enabled" then
				UI.toggleMuted(Game.uiState)
				Game.syncSoundSettings()
			elseif selected == "Back" then
				local returnScreen = Game.settingsReturnScreen or "menu"
				Game.settingsReturnScreen = nil
				UI.setScreen(Game.uiState, returnScreen)
			end
		elseif key == "escape" then
			local returnScreen = Game.settingsReturnScreen or "menu"
			Game.settingsReturnScreen = nil
			UI.setScreen(Game.uiState, returnScreen)
		end
	end

	function Game.handleGameOverInput(key)
		if key == "up" then
			UI.selectPrev(Game.uiState)
		elseif key == "down" then
			UI.selectNext(Game.uiState)
		elseif key == "return" or key == "space" then
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Play Again" then
				Game.startNewGame()
				UI.setScreen(Game.uiState, "playing")
				Game.showTurnBanner(1)
			elseif selected == "Main Menu" then
				UI.setScreen(Game.uiState, "menu")
			end
		end
	end

	function Game.handlePausedInput(key)
		if key == "up" then
			UI.selectPrev(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "down" then
			UI.selectNext(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "escape" then
			-- Resume game
			UI.setScreen(Game.uiState, "playing")
		elseif key == "return" or key == "space" then
			Game.playSoundForEvent("menu_confirm")
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Continue" then
				UI.setScreen(Game.uiState, "playing")
			elseif selected == "New Game" then
				-- Show confirmation dialog
				UI.setConfirmAction(Game.uiState, "new_game")
				UI.setScreen(Game.uiState, "confirm")
			elseif selected == "Settings" then
				Game.settingsReturnScreen = "paused"
				UI.setScreen(Game.uiState, "settings")
			elseif selected == "Quit" then
				love.event.quit()
			end
		end
	end

	function Game.handleConfirmInput(key)
		if key == "left" then
			UI.selectPrev(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "right" then
			UI.selectNext(Game.uiState)
			Game.playSoundForEvent("menu_move")
		elseif key == "escape" then
			-- Cancel and return to paused screen
			UI.clearConfirmAction(Game.uiState)
			UI.setScreen(Game.uiState, "paused")
		elseif key == "return" or key == "space" then
			local selected = UI.getSelectedMenuItem(Game.uiState)
			local action = UI.getConfirmAction(Game.uiState)

			if selected == "Yes" then
				Game.playSoundForEvent("menu_confirm")
				if action == "new_game" then
					Game.startNewGame()
					UI.setScreen(Game.uiState, "playing")
					Game.showTurnBanner(1)
				elseif action == "quit" then
					love.event.quit()
				end
				UI.clearConfirmAction(Game.uiState)
			elseif selected == "No" then
				Game.playSoundForEvent("menu_back")
				UI.clearConfirmAction(Game.uiState)
				UI.setScreen(Game.uiState, "paused")
			end
		end
	end

	function Game.wheelmoved(x, y)
		local screen = UI.getScreen(Game.uiState)
		if screen == "history" then
			-- Scroll up (y > 0) decreases offset; scroll down increases it
			local newOffset = Game.uiState.historyScrollOffset - y
			if newOffset < 0 then
				newOffset = 0
			end
			Game.uiState.historyScrollOffset = newOffset
		end
	end

	-- Multiplayer Connect Input Handler
	function Game.handleMPConnectInput(key)
		if not Game.multiplayer then
			return
		end

		local fields = { "name", "host", "port" }
		local currentIndex = 1
		for i, f in ipairs(fields) do
			if Game.multiplayer.inputField == f then
				currentIndex = i
				break
			end
		end

		if key == "tab" or key == "down" then
			-- Cycle through fields
			currentIndex = currentIndex + 1
			if currentIndex > #fields then
				currentIndex = 1
			end
			Multiplayer.setInputField(Game.multiplayer, fields[currentIndex])
		elseif key == "up" then
			currentIndex = currentIndex - 1
			if currentIndex < 1 then
				currentIndex = #fields
			end
			Multiplayer.setInputField(Game.multiplayer, fields[currentIndex])
		elseif key == "backspace" then
			Multiplayer.backspace(Game.multiplayer)
		elseif key == "return" then
			-- Connect to server
			Multiplayer.clearError(Game.multiplayer)
			local success = Multiplayer.connect(Game.multiplayer)
			if success then
				-- Request lobby state
				Multiplayer.requestLobby(Game.multiplayer)
				UI.setScreen(Game.uiState, "mplobby")
			end
		elseif key == "escape" then
			-- Go back to game mode selection
			Game.multiplayer = nil
			UI.setScreen(Game.uiState, "gamemode")
		end
	end

	-- Multiplayer Lobby Input Handler
	function Game.handleMPLobbyInput(key)
		if not Game.multiplayer then
			return
		end

		if key == "up" then
			Multiplayer.selectPrevGame(Game.multiplayer)
		elseif key == "down" then
			Multiplayer.selectNextGame(Game.multiplayer)
		elseif key == "c" then
			-- Go to opponent selection screen
			UI.setScreen(Game.uiState, "mpopponent")
		elseif key == "j" or key == "return" then
			-- Join selected game
			local game = Multiplayer.getSelectedGame(Game.multiplayer)
			if game and game.id then
				Multiplayer.clearError(Game.multiplayer)
				Multiplayer.joinGame(Game.multiplayer, game.id)
			end
		elseif key == "r" then
			-- Refresh lobby
			Multiplayer.requestLobby(Game.multiplayer)
		elseif key == "escape" then
			-- Disconnect and go back
			Multiplayer.disconnect(Game.multiplayer)
			Game.multiplayer = nil
			UI.setScreen(Game.uiState, "gamemode")
		end
	end

	-- Multiplayer Waiting Input Handler
	function Game.handleMPWaitingInput(key)
		if not Game.multiplayer then
			return
		end

		if key == "escape" then
			-- Cancel waiting - leave game and return to lobby
			Multiplayer.leaveGame(Game.multiplayer)
			UI.setScreen(Game.uiState, "mplobby")
		elseif key == "a" then
			-- Switch to local AI game instead of waiting
			Multiplayer.leaveGame(Game.multiplayer)
			Multiplayer.disconnect(Game.multiplayer)
			Game.multiplayer = nil
			-- Start with medium difficulty by default
			Game.startVsAI("medium")
			UI.setScreen(Game.uiState, "playing")
			Game.showTurnBanner(1)
		end
	end

	-- Text input handler for multiplayer fields
	function Game.textinput(text)
		local screen = UI.getScreen(Game.uiState)

		if screen == "mpconnect" and Game.multiplayer then
			Multiplayer.textInput(Game.multiplayer, text)
		end
	end

	-- Multiplayer Opponent Selection Input Handler
	function Game.handleMPOpponentInput(key)
		if not Game.multiplayer then
			return
		end

		if key == "up" then
			UI.selectPrev(Game.uiState)
		elseif key == "down" then
			UI.selectNext(Game.uiState)
		elseif key == "return" or key == "space" then
			local selected = UI.getSelectedMenuItem(Game.uiState)
			if selected == "Wait for Player" then
				-- Create game and wait for human opponent
				Multiplayer.clearError(Game.multiplayer)
				local gameName = Game.multiplayer.playerName .. "'s Game"
				Multiplayer.createGame(Game.multiplayer, gameName)
				UI.setScreen(Game.uiState, "mpwaiting")
			elseif selected == "AI Practice - Easy" then
				Game.startMultiplayerAIGame("easy")
			elseif selected == "AI Practice - Medium" then
				Game.startMultiplayerAIGame("medium")
			elseif selected == "AI Practice - Hard" then
				Game.startMultiplayerAIGame("hard")
			elseif selected == "AI Practice - Expert" then
				Game.startMultiplayerAIGame("expert")
			elseif selected == "Cancel" then
				UI.setScreen(Game.uiState, "mplobby")
			end
		elseif key == "escape" then
			UI.setScreen(Game.uiState, "mplobby")
		end
	end
end
