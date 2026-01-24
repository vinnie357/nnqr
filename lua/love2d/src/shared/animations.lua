-- Animations Module
-- Core animation state management, easing functions, and animation factories
-- No Love2D dependencies - pure math functions

local Animations = {}

-- Easing functions namespace
Animations.ease = {}

--- Create a new animation state
---@param animType string Animation type identifier
---@param duration number Duration in seconds
---@param data table|nil Optional animation-specific data
---@param blocking boolean|nil Whether animation blocks input (default false)
---@param onComplete function|nil Callback when animation completes
---@return table Animation state object
function Animations.createAnimation(animType, duration, data, blocking, onComplete)
	return {
		type = animType,
		duration = duration,
		elapsed = 0,
		data = data or {},
		blocking = blocking or false,
		onComplete = onComplete,
	}
end

--- Update an animation's elapsed time
---@param anim table Animation state
---@param dt number Delta time in seconds
function Animations.updateAnimation(anim, dt)
	anim.elapsed = math.min(anim.elapsed + dt, anim.duration)
end

--- Get animation progress (0 to 1)
---@param anim table Animation state
---@return number Progress from 0 to 1
function Animations.getProgress(anim)
	if anim.duration <= 0 then
		return 1
	end
	return math.min(anim.elapsed / anim.duration, 1)
end

--- Check if animation is complete
---@param anim table Animation state
---@return boolean True if animation is complete
function Animations.isComplete(anim)
	return anim.elapsed >= anim.duration
end

-- =============================================================================
-- Easing Functions
-- =============================================================================

--- Linear easing (no easing)
---@param t number Progress (0 to 1)
---@return number Eased value (0 to 1)
function Animations.ease.linear(t)
	return t
end

--- Quadratic ease out (decelerating)
--- Formula: 1 - (1-t)^2
---@param t number Progress (0 to 1)
---@return number Eased value (0 to 1)
function Animations.ease.easeOutQuad(t)
	return 1 - (1 - t) * (1 - t)
end

--- Cubic ease in-out (accelerate then decelerate)
---@param t number Progress (0 to 1)
---@return number Eased value (0 to 1)
function Animations.ease.easeInOutCubic(t)
	if t < 0.5 then
		return 4 * t * t * t
	else
		return 1 - math.pow(-2 * t + 2, 3) / 2
	end
end

--- Elastic ease out (overshoot with bounce)
---@param t number Progress (0 to 1)
---@return number Eased value (may exceed 1 during animation)
function Animations.ease.easeOutElastic(t)
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end

	local c4 = (2 * math.pi) / 3
	return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

--- Back ease out (overshoot then settle)
---@param t number Progress (0 to 1)
---@return number Eased value (may exceed 1 during animation)
function Animations.ease.easeOutBack(t)
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end

	local c1 = 1.70158
	local c3 = c1 + 1

	return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

-- =============================================================================
-- Animation Type Factories
-- =============================================================================

-- Duration constants for elaborate animations
local DURATION_DESTROY = 0.7
local DURATION_BOMB = 0.9
local DURATION_RELOCATE = 0.8
local DURATION_TERRAIN = 0.5
local DURATION_RECRUIT = 0.6
local DURATION_MULTIPLY = 0.7
local DURATION_PASSIVE = 0.4

--- Create destroy row animation
---@param row number Row being destroyed
---@param originCol number Column of the piece activating the power
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createDestroyRow(row, originCol, onComplete)
	return Animations.createAnimation("destroy_row", DURATION_DESTROY, {
		row = row,
		originCol = originCol,
	}, true, onComplete)
end

--- Create destroy column animation
---@param col number Column being destroyed
---@param originRow number Row of the piece activating the power
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createDestroyColumn(col, originRow, onComplete)
	return Animations.createAnimation("destroy_column", DURATION_DESTROY, {
		col = col,
		originRow = originRow,
	}, true, onComplete)
end

--- Create bomb explosion animation
---@param row number Center row of explosion
---@param col number Center column of explosion
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createBomb(row, col, onComplete)
	return Animations.createAnimation("bomb", DURATION_BOMB, {
		row = row,
		col = col,
	}, true, onComplete)
end

--- Create relocate (teleport) animation
---@param fromRow number Starting row
---@param fromCol number Starting column
---@param toRow number Destination row
---@param toCol number Destination column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createRelocate(fromRow, fromCol, toRow, toCol, onComplete)
	return Animations.createAnimation("relocate", DURATION_RELOCATE, {
		fromRow = fromRow,
		fromCol = fromCol,
		toRow = toRow,
		toCol = toCol,
	}, true, onComplete)
end

--- Create raise tile animation
---@param row number Tile row
---@param col number Tile column
---@param fromHeight number Starting height
---@param toHeight number Target height
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createRaiseTile(row, col, fromHeight, toHeight, onComplete)
	return Animations.createAnimation("raise_tile", DURATION_TERRAIN, {
		row = row,
		col = col,
		fromHeight = fromHeight,
		toHeight = toHeight,
	}, true, onComplete)
end

--- Create lower tile animation
---@param row number Tile row
---@param col number Tile column
---@param fromHeight number Starting height
---@param toHeight number Target height
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createLowerTile(row, col, fromHeight, toHeight, onComplete)
	return Animations.createAnimation("lower_tile", DURATION_TERRAIN, {
		row = row,
		col = col,
		fromHeight = fromHeight,
		toHeight = toHeight,
	}, true, onComplete)
end

--- Create recruit (convert enemy) animation
---@param row number Piece row
---@param col number Piece column
---@param fromPlayer number Original player
---@param toPlayer number New player
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createRecruit(row, col, fromPlayer, toPlayer, onComplete)
	return Animations.createAnimation("recruit", DURATION_RECRUIT, {
		row = row,
		col = col,
		fromPlayer = fromPlayer,
		toPlayer = toPlayer,
	}, true, onComplete)
end

--- Create multiply (clone) animation
---@param originRow number Original piece row
---@param originCol number Original piece column
---@param targetRow number Clone destination row
---@param targetCol number Clone destination column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createMultiply(originRow, originCol, targetRow, targetCol, onComplete)
	return Animations.createAnimation("multiply", DURATION_MULTIPLY, {
		originRow = originRow,
		originCol = originCol,
		targetRow = targetRow,
		targetCol = targetCol,
	}, true, onComplete)
end

--- Create move diagonal activation animation (non-blocking passive)
---@param row number Piece row
---@param col number Piece column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createMoveDiagonal(row, col, onComplete)
	return Animations.createAnimation("move_diagonal", DURATION_PASSIVE, {
		row = row,
		col = col,
	}, false, onComplete)
end

--- Create jump proof activation animation (non-blocking passive)
---@param row number Piece row
---@param col number Piece column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createJumpProof(row, col, onComplete)
	return Animations.createAnimation("jump_proof", DURATION_PASSIVE, {
		row = row,
		col = col,
	}, false, onComplete)
end

--- Create invisible activation animation (non-blocking passive)
---@param row number Piece row
---@param col number Piece column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createInvisible(row, col, onComplete)
	return Animations.createAnimation("invisible", DURATION_PASSIVE, {
		row = row,
		col = col,
	}, false, onComplete)
end

--- Create move again activation animation (non-blocking)
---@param row number Piece row
---@param col number Piece column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createMoveAgain(row, col, onComplete)
	return Animations.createAnimation("move_again", DURATION_PASSIVE, {
		row = row,
		col = col,
	}, false, onComplete)
end

-- =============================================================================
-- Generic Power Animation Factories
-- =============================================================================

--- Create generic self power animation (glow effect at piece)
---@param row number Piece row
---@param col number Piece column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createPowerSelf(row, col, onComplete)
	return Animations.createAnimation("power_self", DURATION_PASSIVE, {
		row = row,
		col = col,
	}, false, onComplete)
end

--- Create generic row power animation (sweep across row)
---@param row number Row being affected
---@param originCol number Column of piece activating power
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createPowerRow(row, originCol, onComplete)
	return Animations.createAnimation("power_row", DURATION_DESTROY, {
		row = row,
		originCol = originCol,
	}, true, onComplete)
end

--- Create generic column power animation (sweep across column)
---@param col number Column being affected
---@param originRow number Row of piece activating power
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createPowerColumn(col, originRow, onComplete)
	return Animations.createAnimation("power_column", DURATION_DESTROY, {
		col = col,
		originRow = originRow,
	}, true, onComplete)
end

--- Create generic radial power animation (pulse from center)
---@param row number Center row
---@param col number Center column
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createPowerRadial(row, col, onComplete)
	return Animations.createAnimation("power_radial", DURATION_BOMB, {
		row = row,
		col = col,
	}, true, onComplete)
end

--- Create generic global power animation (screen flash)
---@param onComplete function|nil Callback when animation completes
---@return table Animation state
function Animations.createPowerGlobal(onComplete)
	return Animations.createAnimation("power_global", DURATION_DESTROY, {}, true, onComplete)
end

-- =============================================================================
-- Interpolation Helpers
-- =============================================================================

-- Player colors for recruit animation
local PLAYER_COLORS = {
	[1] = { 0.25, 0.55, 0.95 }, -- Blue
	[2] = { 0.95, 0.35, 0.35 }, -- Red
}

--- Get wave position for destroy row animation (0 to 1)
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number Wave position (0 to 1)
function Animations.getDestroyRowWavePosition(anim, progress)
	return Animations.ease.easeOutQuad(progress)
end

--- Get explosion radius for bomb animation
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number Radius (expands then contracts)
function Animations.getBombRadius(anim, progress)
	-- Expand to max radius at 50%, then contract
	local maxRadius = 1.5 -- 1.5 tile widths
	if progress < 0.5 then
		-- Expanding phase
		return maxRadius * Animations.ease.easeOutQuad(progress * 2)
	else
		-- Contracting phase
		return maxRadius * (1 - Animations.ease.easeOutQuad((progress - 0.5) * 2))
	end
end

--- Get fade alpha for relocate animation (1 -> 0 -> 1)
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number Alpha (1 = visible, 0 = invisible)
function Animations.getRelocateFadeAlpha(anim, progress)
	if progress < 0.5 then
		-- Fading out
		return 1 - (progress * 2)
	else
		-- Fading in
		return (progress - 0.5) * 2
	end
end

--- Get current position for relocate animation
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number, number Row and column
function Animations.getRelocatePosition(anim, progress)
	if progress < 0.5 then
		return anim.data.fromRow, anim.data.fromCol
	else
		return anim.data.toRow, anim.data.toCol
	end
end

--- Get interpolated tile height
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number Current height
function Animations.getTileHeightOffset(anim, progress)
	local from = anim.data.fromHeight
	local to = anim.data.toHeight
	local easedProgress = Animations.ease.easeOutQuad(progress)
	return from + (to - from) * easedProgress
end

--- Get interpolated color for recruit animation
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number, number, number RGB values
function Animations.getRecruitColor(anim, progress)
	local fromColor = PLAYER_COLORS[anim.data.fromPlayer]
	local toColor = PLAYER_COLORS[anim.data.toPlayer]
	local easedProgress = Animations.ease.easeInOutCubic(progress)

	local r = fromColor[1] + (toColor[1] - fromColor[1]) * easedProgress
	local g = fromColor[2] + (toColor[2] - fromColor[2]) * easedProgress
	local b = fromColor[3] + (toColor[3] - fromColor[3]) * easedProgress

	return r, g, b
end

--- Get shield scale for jump_proof animation (bounce effect)
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number Scale (0 to ~1.2 then back to 1)
function Animations.getShieldScale(anim, progress)
	return Animations.ease.easeOutBack(progress)
end

--- Get alpha for invisible animation (fade to semi-transparent)
---@param anim table Animation state
---@param progress number Progress (0 to 1)
---@return number Alpha (1 -> 0.3)
function Animations.getInvisibleAlpha(anim, progress)
	local targetAlpha = 0.3
	local easedProgress = Animations.ease.easeOutQuad(progress)
	return 1 - (1 - targetAlpha) * easedProgress
end

-- =============================================================================
-- Animation Queue System
-- =============================================================================

Animations.AnimationQueue = {}

--- Create a new animation queue
---@return table Queue object
function Animations.AnimationQueue.create()
	return {
		animations = {},
	}
end

--- Add an animation to the queue
---@param queue table Queue object
---@param anim table Animation to add
function Animations.AnimationQueue.add(queue, anim)
	table.insert(queue.animations, anim)
end

--- Update all animations in the queue
---@param queue table Queue object
---@param dt number Delta time in seconds
function Animations.AnimationQueue.update(queue, dt)
	-- Update all animations
	for _, anim in ipairs(queue.animations) do
		Animations.updateAnimation(anim, dt)
	end

	-- Check for completed animations and fire callbacks
	local i = 1
	while i <= #queue.animations do
		local anim = queue.animations[i]
		if Animations.isComplete(anim) then
			-- Fire callback if exists
			if anim.onComplete then
				anim.onComplete()
			end
			-- Remove from queue
			table.remove(queue.animations, i)
		else
			i = i + 1
		end
	end
end

--- Get all active animations
---@param queue table Queue object
---@return table Array of active animations
function Animations.AnimationQueue.getActive(queue)
	return queue.animations
end

--- Check if any blocking animation is active
---@param queue table Queue object
---@return boolean True if any blocking animation is running
function Animations.AnimationQueue.isBlocking(queue)
	for _, anim in ipairs(queue.animations) do
		if anim.blocking then
			return true
		end
	end
	return false
end

--- Clear all animations without firing callbacks
---@param queue table Queue object
function Animations.AnimationQueue.clear(queue)
	queue.animations = {}
end

--- Check if queue has any animations
---@param queue table Queue object
---@return boolean True if animations are present
function Animations.AnimationQueue.hasAnimations(queue)
	return #queue.animations > 0
end

return Animations
