-- Game Animations Integration Module
-- Bridges animation system with game logic for power effects
-- No Love2D dependencies - fully testable

local Animations = require("src.shared.animations")
local PowerEffects = require("src.shared.power_effects")

local GameAnimations = {}

--- Create game animations state
---@return table Game animations state with queue
function GameAnimations.create()
	return {
		queue = Animations.AnimationQueue.create(),
	}
end

--- Queue a power animation (without effect callback)
---@param ga table Game animations state
---@param state table Game state
---@param piece table Piece activating power
---@param powerId string Power being activated
function GameAnimations.queuePowerAnimation(ga, state, piece, powerId)
	local anim = GameAnimations.createPowerAnimation(piece, powerId)
	if anim then
		Animations.AnimationQueue.add(ga.queue, anim)
	end
end

--- Queue a power animation with effect applied on completion
---@param ga table Game animations state
---@param state table Game state
---@param piece table Piece activating power
---@param powerId string Power being activated
function GameAnimations.queuePowerAnimationWithEffect(ga, state, piece, powerId)
	local onComplete = function()
		GameAnimations.applyPowerEffect(state, piece, powerId)
	end

	local anim = GameAnimations.createPowerAnimation(piece, powerId, onComplete)
	if anim then
		Animations.AnimationQueue.add(ga.queue, anim)
	end
end

--- Create animation for a specific power
---@param piece table Piece activating power
---@param powerId string Power ID
---@param onComplete function|nil Callback when animation completes
---@return table|nil Animation state or nil if no animation for this power
function GameAnimations.createPowerAnimation(piece, powerId, onComplete)
	if powerId == "destroy_row" then
		return Animations.createDestroyRow(piece.row, piece.col, onComplete)
	elseif powerId == "destroy_column" then
		return Animations.createDestroyColumn(piece.col, piece.row, onComplete)
	elseif powerId == "bomb" then
		return Animations.createBomb(piece.row, piece.col, onComplete)
	elseif powerId == "relocate" then
		-- Note: relocate position not known until effect applied
		-- For now, use piece position for both
		return Animations.createRelocate(piece.row, piece.col, piece.row, piece.col, onComplete)
	elseif powerId == "move_diagonal" then
		return Animations.createMoveDiagonal(piece.row, piece.col, onComplete)
	elseif powerId == "jump_proof" then
		return Animations.createJumpProof(piece.row, piece.col, onComplete)
	elseif powerId == "invisible" then
		return Animations.createInvisible(piece.row, piece.col, onComplete)
	elseif powerId == "move_again" then
		return Animations.createMoveAgain(piece.row, piece.col, onComplete)
	end

	return nil
end

--- Apply power effect to game state
---@param state table Game state
---@param piece table Piece activating power
---@param powerId string Power ID
function GameAnimations.applyPowerEffect(state, piece, powerId)
	if powerId == "destroy_row" then
		PowerEffects.activateDestroyRow(state, piece)
	elseif powerId == "destroy_column" then
		PowerEffects.activateDestroyColumn(state, piece)
	elseif powerId == "bomb" then
		PowerEffects.activateBomb(state, piece)
	elseif powerId == "relocate" then
		PowerEffects.activateRelocate(state, piece)
	elseif powerId == "move_diagonal" then
		PowerEffects.activateMoveDiagonal(state, piece)
	elseif powerId == "jump_proof" then
		PowerEffects.activateJumpProof(state, piece)
	elseif powerId == "invisible" then
		PowerEffects.activateInvisible(state, piece)
	elseif powerId == "move_again" then
		PowerEffects.activateMoveAgain(state, piece)
	end
end

--- Check if any blocking animation is active
---@param ga table Game animations state
---@return boolean True if blocking animation is running
function GameAnimations.isBlocking(ga)
	return Animations.AnimationQueue.isBlocking(ga.queue)
end

--- Update animations
---@param ga table Game animations state
---@param dt number Delta time in seconds
function GameAnimations.update(ga, dt)
	Animations.AnimationQueue.update(ga.queue, dt)
end

--- Get all active animations
---@param ga table Game animations state
---@return table Array of active animations
function GameAnimations.getActiveAnimations(ga)
	return Animations.AnimationQueue.getActive(ga.queue)
end

--- Clear all animations
---@param ga table Game animations state
function GameAnimations.clear(ga)
	Animations.AnimationQueue.clear(ga.queue)
end

return GameAnimations
