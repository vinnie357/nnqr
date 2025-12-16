-- Power Executor Module
-- Dispatches power activation to correct PowerEffects function
-- No Love2D dependencies - pure game logic
--
-- This module solves the bug where 70+ powers have PowerEffects.activate*()
-- functions but are never called from Game.executepower()

local PowerExecutor = {}

local PowerEffects = require("src.shared.power_effects")
local Powers = require("src.shared.powers")

-- Dispatch table mapping power IDs to their effect functions
-- Self-targeting powers (12)
local DISPATCH = {
	move_diagonal = function(state, piece)
		return PowerEffects.activateMoveDiagonal(state, piece)
	end,
	move_again = function(state, piece)
		return PowerEffects.activateMoveAgain(state, piece)
	end,
	relocate = function(state, piece)
		return PowerEffects.activateRelocate(state, piece)
	end,
	jump_proof = function(state, piece)
		return PowerEffects.activateJumpProof(state, piece)
	end,
	invisible = function(state, piece)
		return PowerEffects.activateInvisible(state, piece)
	end,
	climb_tile = function(state, piece)
		return PowerEffects.activateClimbTile(state, piece)
	end,
	double_powers = function(state, piece)
		return PowerEffects.activateDoublePowers(state, piece)
	end,
	grow_quadradius = function(state, piece)
		return PowerEffects.activateGrowQuadradius(state, piece)
	end,
	beneficiary = function(state, piece)
		return PowerEffects.activateBeneficiary(state, piece)
	end,
	scavenger = function(state, piece)
		return PowerEffects.activateScavenger(state, piece)
	end,
	flat_to_sphere = function(state, piece)
		return PowerEffects.activateFlatToSphere(state, piece)
	end,
	hotspot = function(state, piece)
		return PowerEffects.activateHotspot(state, piece)
	end,

	-- Row-targeting powers (20)
	destroy_row = function(state, piece)
		return PowerEffects.activateDestroyRow(state, piece)
	end,
	kamikaze_row = function(state, piece)
		return PowerEffects.activateKamikazeRow(state, piece)
	end,
	recruit_row = function(state, piece)
		return PowerEffects.activateRecruitRow(state, piece)
	end,
	acidic_row = function(state, piece)
		return PowerEffects.activateAcidicRow(state, piece)
	end,
	scramble_row = function(state, piece)
		return PowerEffects.activateScrambleRow(state, piece)
	end,
	trench_row = function(state, piece)
		return PowerEffects.activateTrenchRow(state, piece)
	end,
	wall_row = function(state, piece)
		return PowerEffects.activateWallRow(state, piece)
	end,
	invert_row = function(state, piece)
		return PowerEffects.activateInvertRow(state, piece)
	end,
	dredge_row = function(state, piece)
		return PowerEffects.activateDredgeRow(state, piece)
	end,
	teach_row = function(state, piece)
		return PowerEffects.activateTeachRow(state, piece)
	end,
	learn_row = function(state, piece)
		return PowerEffects.activateLearnRow(state, piece)
	end,
	pilfer_row = function(state, piece)
		return PowerEffects.activatePilferRow(state, piece)
	end,
	spyware_row = function(state, piece)
		return PowerEffects.activateSpywareRow(state, piece)
	end,
	orb_spy_row = function(state, piece)
		return PowerEffects.activateOrbSpyRow(state, piece, state.orbs)
	end,
	refurb_row = function(state, piece)
		return PowerEffects.activateRefurbRow(state, piece)
	end,
	bankrupt_row = function(state, piece)
		return PowerEffects.activateBankruptRow(state, piece)
	end,
	tripwire_row = function(state, piece)
		return PowerEffects.activateTripwireRow(state, piece)
	end,
	inhibit_row = function(state, piece)
		return PowerEffects.activateInhibitRow(state, piece)
	end,
	parasite_row = function(state, piece)
		return PowerEffects.activateParasiteRow(state, piece)
	end,
	purify_row = function(state, piece)
		return PowerEffects.activatePurifyRow(state, piece)
	end,

	-- Column-targeting powers (20)
	destroy_column = function(state, piece)
		return PowerEffects.activateDestroyColumn(state, piece)
	end,
	kamikaze_column = function(state, piece)
		return PowerEffects.activateKamikazeColumn(state, piece)
	end,
	recruit_column = function(state, piece)
		return PowerEffects.activateRecruitColumn(state, piece)
	end,
	acidic_column = function(state, piece)
		return PowerEffects.activateAcidicColumn(state, piece)
	end,
	scramble_column = function(state, piece)
		return PowerEffects.activateScrambleColumn(state, piece)
	end,
	trench_column = function(state, piece)
		return PowerEffects.activateTrenchColumn(state, piece)
	end,
	wall_column = function(state, piece)
		return PowerEffects.activateWallColumn(state, piece)
	end,
	invert_column = function(state, piece)
		return PowerEffects.activateInvertColumn(state, piece)
	end,
	dredge_column = function(state, piece)
		return PowerEffects.activateDredgeColumn(state, piece)
	end,
	teach_column = function(state, piece)
		return PowerEffects.activateTeachColumn(state, piece)
	end,
	learn_column = function(state, piece)
		return PowerEffects.activateLearnColumn(state, piece)
	end,
	pilfer_column = function(state, piece)
		return PowerEffects.activatePilferColumn(state, piece)
	end,
	spyware_column = function(state, piece)
		return PowerEffects.activateSpywareColumn(state, piece)
	end,
	orb_spy_column = function(state, piece)
		return PowerEffects.activateOrbSpyColumn(state, piece, state.orbs)
	end,
	refurb_column = function(state, piece)
		return PowerEffects.activateRefurbColumn(state, piece)
	end,
	bankrupt_column = function(state, piece)
		return PowerEffects.activateBankruptColumn(state, piece)
	end,
	tripwire_column = function(state, piece)
		return PowerEffects.activateTripwireColumn(state, piece)
	end,
	inhibit_column = function(state, piece)
		return PowerEffects.activateInhibitColumn(state, piece)
	end,
	parasite_column = function(state, piece)
		return PowerEffects.activateParasiteColumn(state, piece)
	end,
	purify_column = function(state, piece)
		return PowerEffects.activatePurifyColumn(state, piece)
	end,
}

--- Execute a power's game logic
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

--- Get valid targets for a targeted power
---@param state table Game state
---@param piece table Piece activating
---@param powerId string Power ID
---@return table Array of valid targets
function PowerExecutor.getTargets(state, piece, powerId)
	-- TODO: Implement targeting dispatch
	return {}
end

--- Get animation info for a power
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
