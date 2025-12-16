-- Piece helpers for power executor tests
-- Create, place, and query pieces

local Pieces = {}

--- Create a new piece
---@param row number Row position
---@param col number Column position
---@param player number Player (1 or 2)
---@param opts? table Optional {powers = {}}
---@return table Piece
function Pieces.createPiece(row, col, player, opts)
	opts = opts or {}
	return {
		row = row,
		col = col,
		player = player,
		powers = opts.powers or {},
	}
end

--- Place a new piece in state and return it
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@param player number Player (1 or 2)
---@param opts? table Optional {powers = {}}
---@return table Piece
function Pieces.placePiece(state, row, col, player, opts)
	local piece = Pieces.createPiece(row, col, player, opts)
	table.insert(state.pieces, piece)
	return piece
end

--- Get piece at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return table|nil Piece or nil
function Pieces.getPieceAt(state, row, col)
	for _, piece in ipairs(state.pieces) do
		if piece.row == row and piece.col == col then
			return piece
		end
	end
	return nil
end

--- Count pieces by player
---@param state table Game state
---@param player? number Optional player filter
---@return number Count
function Pieces.countPieces(state, player)
	local count = 0
	for _, piece in ipairs(state.pieces) do
		if player == nil or piece.player == player then
			count = count + 1
		end
	end
	return count
end

--- Remove piece from state
---@param state table Game state
---@param piece table Piece to remove
function Pieces.removePiece(state, piece)
	for i, p in ipairs(state.pieces) do
		if p == piece then
			table.remove(state.pieces, i)
			return
		end
	end
end

--- Get all pieces in a row
---@param state table Game state
---@param row number Row to check
---@param player? number Optional player filter
---@return table Array of pieces
function Pieces.getPiecesInRow(state, row, player)
	local pieces = {}
	for _, piece in ipairs(state.pieces) do
		if piece.row == row and (player == nil or piece.player == player) then
			table.insert(pieces, piece)
		end
	end
	return pieces
end

--- Get all pieces in a column
---@param state table Game state
---@param col number Column to check
---@param player? number Optional player filter
---@return table Array of pieces
function Pieces.getPiecesInColumn(state, col, player)
	local pieces = {}
	for _, piece in ipairs(state.pieces) do
		if piece.col == col and (player == nil or piece.player == player) then
			table.insert(pieces, piece)
		end
	end
	return pieces
end

--- Get all pieces in a 3x3 area centered on position
---@param state table Game state
---@param centerRow number Center row
---@param centerCol number Center column
---@param player? number Optional player filter
---@return table Array of pieces
function Pieces.getPiecesInArea(state, centerRow, centerCol, player)
	local pieces = {}
	for _, piece in ipairs(state.pieces) do
		local dr = math.abs(piece.row - centerRow)
		local dc = math.abs(piece.col - centerCol)
		if dr <= 1 and dc <= 1 and (player == nil or piece.player == player) then
			table.insert(pieces, piece)
		end
	end
	return pieces
end

-- Alias for placePiece (addPiece is more intuitive name)
Pieces.addPiece = Pieces.placePiece

--- Check if a piece exists at position
---@param state table Game state
---@param row number Row position
---@param col number Column position
---@return boolean True if a piece exists at position
function Pieces.hasPiece(state, row, col)
	return Pieces.getPieceAt(state, row, col) ~= nil
end

return Pieces
