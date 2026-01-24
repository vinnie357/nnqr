-- Indicators Module
-- Tracks visual indicators for pieces based on their active flags
-- No Love2D dependencies - fully testable

local Indicators = {}

--- Get list of visual indicators for a piece based on its flags
--- Returns indicator names that should be rendered on the piece
---@param piece table Piece to check
---@return table Array of indicator names (e.g., "jump_proof", "move_diagonal", "invisible")
function Indicators.getPieceIndicators(piece)
	local indicators = {}

	-- Movement modifiers
	if piece.isJumpProof then
		table.insert(indicators, "jump_proof")
	end

	if piece.canMoveDiagonally then
		table.insert(indicators, "move_diagonal")
	end

	if piece.canClimbAny then
		table.insert(indicators, "climb_tile")
	end

	if piece.canWrap then
		table.insert(indicators, "flat_to_sphere")
	end

	-- Status effects
	if piece.isInvisible then
		table.insert(indicators, "invisible")
	end

	if piece.isBeneficiary then
		table.insert(indicators, "beneficiary")
	end

	if piece.isScavenger then
		table.insert(indicators, "scavenger")
	end

	if piece.isTripwired then
		table.insert(indicators, "tripwire")
	end

	if piece.isInhibited then
		table.insert(indicators, "inhibited")
	end

	if piece.isMultiplied then
		table.insert(indicators, "multiplied")
	end

	return indicators
end

return Indicators
