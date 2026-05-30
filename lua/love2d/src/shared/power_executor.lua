-- Power Executor Module
-- Dispatches power activation to the correct PowerEffects function.
-- No Love2D dependencies - pure game logic.
--
-- The dispatch table is GENERATED from Powers.definitions by naming convention
-- (power id `destroy_row` -> PowerEffects.activateDestroyRow), so a power can
-- never be defined without a wired handler. Powers needing special argument
-- handling (orb threading, target-piece resolution) are listed in OVERRIDES.
-- This eliminates the hand-maintained-table drift that previously left powers
-- like centerpult/hotspot undispatched.

local PowerExecutor = {}

local PowerEffects = require("src.shared.power_effects")
local Powers = require("src.shared.powers")

--- Convert a snake_case power id to its PowerEffects function name.
--- e.g. "orb_spy_row" -> "activateOrbSpyRow"
---@param id string Power id
---@return string Function name on the PowerEffects module
local function effectFnName(id)
	local parts = {}
	for segment in id:gmatch("[^_]+") do
		parts[#parts + 1] = segment:sub(1, 1):upper() .. segment:sub(2)
	end
	return "activate" .. table.concat(parts)
end

--- Generic handler: forwards (state, piece, target) to the effect function.
--- Effect functions that ignore `target` simply receive an unused extra arg.
local function genericHandler(fnName)
	return function(state, piece, target)
		return PowerEffects[fnName](state, piece, target)
	end
end

--- Orb-threading handler: effect returns (newState, newOrbs); re-attach orbs.
local function orbHandler(fnName)
	return function(state, piece)
		local newState, newOrbs = PowerEffects[fnName](state, piece, state.orbs)
		newState.orbs = newOrbs
		return newState
	end
end

--- Target-piece handler: resolves the piece at the target position before the
--- effect (recruit/switcheroo operate on a piece, not a tile).
local function targetPieceHandler(fnName)
	return function(state, piece, target)
		local targetPiece = nil
		for _, p in ipairs(state.pieces) do
			if p.row == target.row and p.col == target.col then
				targetPiece = p
				break
			end
		end
		if targetPiece then
			return PowerEffects[fnName](state, piece, targetPiece)
		end
		return state
	end
end

-- Powers whose handler cannot be the generic forwarder.
local OVERRIDES = {
	orb_spy_row = orbHandler("activateOrbSpyRow"),
	orb_spy_column = orbHandler("activateOrbSpyColumn"),
	orb_spy_radial = orbHandler("activateOrbSpyRadial"),
	orbic_rehash = orbHandler("activateOrbicRehash"),
	recruit = targetPieceHandler("activateRecruit"),
	switcheroo = targetPieceHandler("activateSwitcheroo"),
}

-- Dispatchable ids that are NOT standalone power definitions (secondary actions
-- of another power). hotspot_teleport is the follow-up to the hotspot power.
local SECONDARY_ACTIONS = {
	hotspot_teleport = genericHandler("activateHotspotTeleport"),
}

-- Build the dispatch table from the power definitions.
local DISPATCH = {}
for id in pairs(Powers.definitions) do
	if OVERRIDES[id] then
		DISPATCH[id] = OVERRIDES[id]
	else
		local fnName = effectFnName(id)
		assert(
			type(PowerEffects[fnName]) == "function",
			string.format("PowerExecutor: power '%s' has no effect function PowerEffects.%s", id, fnName)
		)
		DISPATCH[id] = genericHandler(fnName)
	end
end

-- Register secondary actions.
for id, handler in pairs(SECONDARY_ACTIONS) do
	DISPATCH[id] = handler
end

--- Execute a power's game logic.
---@param state table Game state (includes orbs)
---@param piece table Piece activating
---@param powerId string Power ID
---@param target table|nil Target for targeted powers
---@return table newState
function PowerExecutor.execute(state, piece, powerId, target)
	local handler = DISPATCH[powerId]
	if handler then
		return handler(state, piece, target)
	end
	return state -- Unknown power, no change
end

--- Whether a power id resolves to a registered handler.
---@param powerId string Power ID
---@return boolean
function PowerExecutor.isRegistered(powerId)
	return DISPATCH[powerId] ~= nil
end

--- All registered dispatch ids (defined powers + secondary actions).
---@return table Array of power/action ids
function PowerExecutor.registeredIds()
	local ids = {}
	for id in pairs(DISPATCH) do
		ids[#ids + 1] = id
	end
	return ids
end

--- Get valid targets for a targeted power.
---@param state table Game state
---@param piece table Piece activating
---@param powerId string Power ID
---@return table Array of valid targets
function PowerExecutor.getTargets(state, piece, powerId)
	-- TODO: Implement targeting dispatch
	return {}
end

--- Get animation info for a power.
---@param powerId string Power ID
---@param piece table Piece activating
---@param target table|nil Target if applicable
---@return string animationType, table animData, boolean blocking
function PowerExecutor.getAnimationInfo(powerId, piece, target)
	local def = Powers.definitions[powerId]
	-- Default to blocking=true, but respect explicit blocking=false
	local blocking = true
	if def and def.blocking == false then
		blocking = false
	end

	-- Determine animation type based on targeting
	local animType = "power_self"
	if def then
		if def.targeting == "self_row" then
			animType = "power_row"
		elseif def.targeting == "self_column" then
			animType = "power_column"
		elseif def.targeting == "area_3x3" then
			animType = "power_radial"
		elseif def.targeting == "global" then
			animType = "power_global"
		end
	end

	local animData = {
		row = piece.row,
		col = piece.col,
	}

	return animType, animData, blocking
end

return PowerExecutor
