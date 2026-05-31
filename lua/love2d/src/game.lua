-- Quadradius Game Module
-- Main game loop integrating shared modules with Love2D rendering

local GameLogic = require("src.shared.game_logic")
local Rendering = require("src.shared.rendering")
local Height = require("src.shared.height")
local Powers = require("src.shared.powers")
local PowerEffects = require("src.shared.power_effects")
local PowerExecutor = require("src.shared.power_executor")
local GameAnimations = require("src.shared.game_animations")
local Animations = require("src.shared.animations")
local Indicators = require("src.shared.indicators")
local UI = require("src.shared.ui")
local Tooltip = require("src.shared.tooltip")
local SoundManager = require("src.shared.sound_manager")
local Particles = require("src.shared.particles")
local ParticleConfig = require("src.shared.particle_config")
local AI = require("src.shared.ai.ai")
local MatchHistory = require("src.shared.match_history")

-- Multiplayer modules (optional - may not have luasocket)
local Multiplayer
local hasMultiplayer = pcall(function()
	Multiplayer = require("src.client.multiplayer")
end)

local Game = {}

-- Game state (managed by GameLogic)
Game.state = nil

-- UI state (managed by UI module)
Game.uiState = nil

-- Visual settings
Game.boardOffsetX = 0
Game.boardOffsetY = 0

-- Animation/interaction state
Game.hoveredTile = nil
Game.orbs = {}

-- Mouse position for tooltips
Game.mouseX = 0
Game.mouseY = 0
Game.hoveredPowerIndex = nil -- Index of power being hovered in menu

-- Power activation mode
Game.powerMode = nil -- nil or {powerId, piece, targets}
Game.powerTargets = {}

-- Animation state
Game.animations = nil

-- Sound state
Game.soundManager = nil
Game.loadedSounds = {} -- Cache for Love2D sound sources

-- Particle system state
Game.particles = nil

-- AI state
Game.ai = nil -- AI state (nil for 2-player, or AI.create() for vs AI)
Game.aiThinkingTimer = 0 -- Delay before AI moves
Game.aiThinkingDelay = 0.8 -- Seconds to wait before AI makes move

-- Multiplayer state
Game.multiplayer = nil -- Multiplayer state (nil for local games)

-- Turn banner state
Game.turnBanner = {
	active = false,
	timer = 0,
	duration = 2.0,
	player = 1,
}

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

	-- Initialize UI state
	Game.uiState = UI.createState()

	-- Create initial game state
	Game.state = GameLogic.createInitialState()

	-- Add some terrain variation for visual interest
	Game.generateTerrain()

	-- Initialize orbs
	Game.orbs = {}

	-- Initialize animation system
	Game.animations = GameAnimations.create()

	-- Initialize sound system
	Game.soundManager = SoundManager.create()
	Game.loadedSounds = {}
	Game.preloadSounds()

	-- Initialize particle system
	Game.particles = Particles.create()

	-- Reset turn banner
	Game.turnBanner = {
		active = false,
		timer = 0,
		duration = 2.0,
		player = 1,
	}

	-- Reset AI state
	Game.ai = nil
	Game.aiThinkingTimer = 0

	-- Reset multiplayer state
	Game.multiplayer = nil

	-- Match history: reset per-game guard and record start time
	Game._matchRecordGuard = MatchHistory.createRecordGuard()
	Game._matchStartTime = love.timer.getTime()
end

--- Start a new game against AI
---@param difficulty string "easy"|"medium"|"hard"|"expert"
function Game.startVsAI(difficulty)
	Game.init()
	Game.ai = AI.create(difficulty or "easy", 2)
	UI.setScreen(Game.uiState, "playing")
end

--- Start a new 2-player game
function Game.startTwoPlayer()
	Game.init()
	Game.ai = nil
	UI.setScreen(Game.uiState, "playing")
end

--- Start multiplayer mode (go to connect screen)
function Game.startMultiplayer()
	if not hasMultiplayer then
		-- Multiplayer not available
		return false
	end
	Game.multiplayer = Multiplayer.create()
	Multiplayer.init(Game.multiplayer, "Player")
	UI.setScreen(Game.uiState, "mpconnect")
	return true
end

--- Check if in multiplayer mode
---@return boolean
function Game.isMultiplayer()
	return Game.multiplayer ~= nil and Multiplayer.isConnected(Game.multiplayer)
end

--- Check if multiplayer is available
---@return boolean
function Game.hasMultiplayerSupport()
	return hasMultiplayer
end

--- Check if current game is against AI
---@return boolean
function Game.isVsAI()
	return Game.ai ~= nil
end

--- Get AI difficulty if playing vs AI
---@return string|nil
function Game.getAIDifficulty()
	if Game.ai then
		return Game.ai.difficulty
	end
	return nil
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

-- Sound system functions
function Game.preloadSounds()
	-- Collect all unique sound files from mappings
	local soundFiles = {}
	for _, file in pairs(SoundManager.EVENT_SOUNDS) do
		soundFiles[file] = true
	end
	for _, file in pairs(SoundManager.POWER_SOUNDS) do
		soundFiles[file] = true
	end
	soundFiles[SoundManager.DEFAULT_POWER_SOUND] = true

	-- Try to load each sound file
	for file, _ in pairs(soundFiles) do
		Game.loadSound(file)
	end
end

function Game.loadSound(filename)
	if Game.loadedSounds[filename] then
		return Game.loadedSounds[filename]
	end

	local path = "assets/sounds/" .. filename
	local success, source = pcall(function()
		return love.audio.newSource(path, "static")
	end)

	if success and source then
		Game.loadedSounds[filename] = source
		return source
	end
	-- Sound file not found - gracefully continue without it
	return nil
end

function Game.playSound(filename)
	if not Game.soundManager or SoundManager.isMuted(Game.soundManager) then
		return
	end

	local source = Game.loadedSounds[filename]
	if source then
		local volume = SoundManager.getEffectiveVolume(Game.soundManager, "sfx")
		source:setVolume(volume)
		source:stop() -- Stop if already playing
		source:play()
	end
end

function Game.playSoundForEvent(event)
	local filename = SoundManager.getSoundForEvent(event)
	if filename then
		Game.playSound(filename)
	end
end

function Game.playSoundForPower(powerId)
	local filename = SoundManager.getSoundForPower(powerId)
	Game.playSound(filename)
end

function Game.syncSoundSettings()
	-- Sync UI volume settings to sound manager
	if Game.soundManager and Game.uiState then
		SoundManager.setMasterVolume(Game.soundManager, UI.getMasterVolume(Game.uiState))
		SoundManager.setSFXVolume(Game.soundManager, UI.getSFXVolume(Game.uiState))
		SoundManager.setMusicVolume(Game.soundManager, UI.getMusicVolume(Game.uiState))
		SoundManager.setMuted(Game.soundManager, UI.isMuted(Game.uiState))
	end
end

require("src.game.render")(Game)
require("src.game.input")(Game)
require("src.game.controller")(Game)

return Game
