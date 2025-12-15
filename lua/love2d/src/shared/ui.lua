-- UI State Module
-- Manages UI state for menus, settings, and tooltips
-- No Love2D dependencies - fully testable

local UI = {}

-- Valid screens
UI.SCREENS = {
	menu = true,
	playing = true,
	settings = true,
	gameover = true,
}

-- Menu items for each screen
UI.MENU_ITEMS = {
	menu = { "New Game", "Settings", "Quit" },
	settings = { "Master Volume", "SFX Volume", "Music Volume", "Sound Enabled", "Back" },
	gameover = { "Play Again", "Main Menu" },
	playing = {},
}

--- Create initial UI state
---@return table UI state object
function UI.createState()
	return {
		screen = "menu",
		selectedIndex = 1,
		hoveredPower = nil,
		masterVolume = 1.0,
		sfxVolume = 1.0,
		musicVolume = 0.5,
		muted = false,
	}
end

--- Get current screen
---@param state table UI state
---@return string Current screen name
function UI.getScreen(state)
	return state.screen
end

--- Set current screen
---@param state table UI state
---@param screen string Screen name to switch to
---@return boolean True if successful, false if invalid screen
function UI.setScreen(state, screen)
	if not UI.SCREENS[screen] then
		return false
	end
	state.screen = screen
	state.selectedIndex = 1
	return true
end

--- Get menu items for current screen
---@param state table UI state
---@return table Array of menu item strings
function UI.getMenuItems(state)
	return UI.MENU_ITEMS[state.screen] or {}
end

--- Select next menu item
---@param state table UI state
function UI.selectNext(state)
	local items = UI.getMenuItems(state)
	if #items == 0 then
		return
	end
	state.selectedIndex = state.selectedIndex + 1
	if state.selectedIndex > #items then
		state.selectedIndex = 1
	end
end

--- Select previous menu item
---@param state table UI state
function UI.selectPrev(state)
	local items = UI.getMenuItems(state)
	if #items == 0 then
		return
	end
	state.selectedIndex = state.selectedIndex - 1
	if state.selectedIndex < 1 then
		state.selectedIndex = #items
	end
end

--- Get currently selected menu item
---@param state table UI state
---@return string|nil Selected menu item or nil if none
function UI.getSelectedMenuItem(state)
	local items = UI.getMenuItems(state)
	return items[state.selectedIndex]
end

--- Set hovered power for tooltip display
---@param state table UI state
---@param powerId string Power ID being hovered
---@param x number X position for tooltip
---@param y number Y position for tooltip
function UI.setHoveredPower(state, powerId, x, y)
	state.hoveredPower = {
		powerId = powerId,
		x = x,
		y = y,
	}
end

--- Get hovered power info
---@param state table UI state
---@return table|nil Hovered power info or nil
function UI.getHoveredPower(state)
	return state.hoveredPower
end

--- Clear hovered power
---@param state table UI state
function UI.clearHoveredPower(state)
	state.hoveredPower = nil
end

--- Get master volume
---@param state table UI state
---@return number Master volume (0-1)
function UI.getMasterVolume(state)
	return state.masterVolume
end

--- Set master volume
---@param state table UI state
---@param volume number Volume level (will be clamped to 0-1)
function UI.setMasterVolume(state, volume)
	state.masterVolume = math.max(0, math.min(1, volume))
end

--- Get SFX volume
---@param state table UI state
---@return number SFX volume (0-1)
function UI.getSFXVolume(state)
	return state.sfxVolume
end

--- Set SFX volume
---@param state table UI state
---@param volume number Volume level (will be clamped to 0-1)
function UI.setSFXVolume(state, volume)
	state.sfxVolume = math.max(0, math.min(1, volume))
end

--- Get music volume
---@param state table UI state
---@return number Music volume (0-1)
function UI.getMusicVolume(state)
	return state.musicVolume
end

--- Set music volume
---@param state table UI state
---@param volume number Volume level (will be clamped to 0-1)
function UI.setMusicVolume(state, volume)
	state.musicVolume = math.max(0, math.min(1, volume))
end

--- Check if sound is muted
---@param state table UI state
---@return boolean True if muted
function UI.isMuted(state)
	return state.muted
end

--- Set mute state
---@param state table UI state
---@param muted boolean Mute state
function UI.setMuted(state, muted)
	state.muted = muted
end

--- Toggle mute state
---@param state table UI state
function UI.toggleMuted(state)
	state.muted = not state.muted
end

--- Adjust volume by delta
---@param state table UI state
---@param volumeType string "master", "sfx", or "music"
---@param delta number Amount to adjust (-1 to 1)
function UI.adjustVolume(state, volumeType, delta)
	if volumeType == "master" then
		UI.setMasterVolume(state, state.masterVolume + delta)
	elseif volumeType == "sfx" then
		UI.setSFXVolume(state, state.sfxVolume + delta)
	elseif volumeType == "music" then
		UI.setMusicVolume(state, state.musicVolume + delta)
	end
end

return UI
