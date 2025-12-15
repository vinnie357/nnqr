-- Sound Manager Module
-- Handles sound volume control, event-to-sound mapping, and sound queue
-- No Love2D dependencies - fully testable

local SoundManager = {}

-- Event to sound file mapping
SoundManager.EVENT_SOUNDS = {
	move = "move.ogg",
	capture = "capture.ogg",
	select = "select.ogg",
	menu_move = "menu_select.ogg",
	menu_confirm = "menu_confirm.ogg",
}

-- Power to sound file mapping
SoundManager.POWER_SOUNDS = {
	bomb = "explosion.ogg",
	destroy_row = "explosion.ogg",
	destroy_column = "explosion.ogg",
	relocate = "teleport.ogg",
	jump_proof = "shield.ogg",
	recruit = "recruit.ogg",
	multiply = "multiply.ogg",
}

-- Default sound for powers not in the mapping
SoundManager.DEFAULT_POWER_SOUND = "power_activate.ogg"

--- Create a new sound manager instance
---@return table Sound manager state
function SoundManager.create()
	return {
		masterVolume = 1.0,
		sfxVolume = 1.0,
		musicVolume = 0.5,
		muted = false,
		pending = {},
	}
end

--- Get master volume
---@param mgr table Sound manager state
---@return number Master volume (0-1)
function SoundManager.getMasterVolume(mgr)
	return mgr.masterVolume
end

--- Set master volume
---@param mgr table Sound manager state
---@param volume number Volume level (will be clamped to 0-1)
function SoundManager.setMasterVolume(mgr, volume)
	mgr.masterVolume = math.max(0, math.min(1, volume))
end

--- Get SFX volume
---@param mgr table Sound manager state
---@return number SFX volume (0-1)
function SoundManager.getSFXVolume(mgr)
	return mgr.sfxVolume
end

--- Set SFX volume
---@param mgr table Sound manager state
---@param volume number Volume level (will be clamped to 0-1)
function SoundManager.setSFXVolume(mgr, volume)
	mgr.sfxVolume = math.max(0, math.min(1, volume))
end

--- Get music volume
---@param mgr table Sound manager state
---@return number Music volume (0-1)
function SoundManager.getMusicVolume(mgr)
	return mgr.musicVolume
end

--- Set music volume
---@param mgr table Sound manager state
---@param volume number Volume level (will be clamped to 0-1)
function SoundManager.setMusicVolume(mgr, volume)
	mgr.musicVolume = math.max(0, math.min(1, volume))
end

--- Check if sound is muted
---@param mgr table Sound manager state
---@return boolean True if muted
function SoundManager.isMuted(mgr)
	return mgr.muted
end

--- Set mute state
---@param mgr table Sound manager state
---@param muted boolean Mute state
function SoundManager.setMuted(mgr, muted)
	mgr.muted = muted
end

--- Get effective volume for a category (combines master and category volume)
---@param mgr table Sound manager state
---@param category string "sfx" or "music"
---@return number Effective volume (0-1)
function SoundManager.getEffectiveVolume(mgr, category)
	if mgr.muted then
		return 0
	end

	local categoryVolume
	if category == "sfx" then
		categoryVolume = mgr.sfxVolume
	elseif category == "music" then
		categoryVolume = mgr.musicVolume
	else
		categoryVolume = 1.0
	end

	return mgr.masterVolume * categoryVolume
end

--- Get sound file for a game event
---@param event string Event name (move, capture, select, etc.)
---@return string|nil Sound file name or nil if not found
function SoundManager.getSoundForEvent(event)
	return SoundManager.EVENT_SOUNDS[event]
end

--- Get sound file for a power
---@param powerId string Power ID
---@return string Sound file name (defaults to generic power sound)
function SoundManager.getSoundForPower(powerId)
	return SoundManager.POWER_SOUNDS[powerId] or SoundManager.DEFAULT_POWER_SOUND
end

--- Queue a sound to be played
---@param mgr table Sound manager state
---@param soundFile string Sound file to play
function SoundManager.queueSound(mgr, soundFile)
	table.insert(mgr.pending, soundFile)
end

--- Get pending sounds to play
---@param mgr table Sound manager state
---@return table Array of sound file names
function SoundManager.getPendingSounds(mgr)
	return mgr.pending
end

--- Clear pending sounds
---@param mgr table Sound manager state
function SoundManager.clearPending(mgr)
	mgr.pending = {}
end

return SoundManager
