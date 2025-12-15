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

	if piece.isJumpProof then
		table.insert(indicators, "jump_proof")
	end

	if piece.canMoveDiagonally then
		table.insert(indicators, "move_diagonal")
	end

	if piece.isInvisible then
		table.insert(indicators, "invisible")
	end

	return indicators
end

return Indicators
