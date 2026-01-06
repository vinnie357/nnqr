-- Game Animations Integration Module
-- Bridges animation system with game logic for power effects
-- No Love2D dependencies - fully testable

local Animations = require("src.shared.animations")
local PowerEffects = require("src.shared.power_effects")
local PowerExecutor = require("src.shared.power_executor")
local Powers = require("src.shared.powers")

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
	-- Special cases with unique animations
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

	-- Generic animations based on power targeting type
	local def = Powers.definitions[powerId]
	if def then
		if def.targeting == "self" then
			return Animations.createPowerSelf(piece.row, piece.col, onComplete)
		elseif def.targeting == "self_row" then
			return Animations.createPowerRow(piece.row, piece.col, onComplete)
		elseif def.targeting == "self_column" then
			return Animations.createPowerColumn(piece.col, piece.row, onComplete)
		elseif def.targeting == "area_3x3" then
			return Animations.createPowerRadial(piece.row, piece.col, onComplete)
		elseif def.targeting == "global" then
			return Animations.createPowerGlobal(onComplete)
		end
	end

	return nil
end

--- Apply power effect to game state
---@param state table Game state
---@param piece table Piece activating power
---@param powerId string Power ID
---@param target table|nil Optional target for targeted powers
---@return table Updated game state
function GameAnimations.applyPowerEffect(state, piece, powerId, target)
	return PowerExecutor.execute(state, piece, powerId, target)
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
