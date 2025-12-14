-- Quadradius Pure Game Logic
-- No Love2D dependencies - fully testable

local Logic = {}

-- Board dimensions
Logic.BOARD_COLS = 10
Logic.BOARD_ROWS = 8

-- Tile dimensions for coordinate conversion
Logic.TILE_WIDTH = 64
Logic.TILE_HEIGHT = 32

--- Convert board coordinates to screen coordinates (isometric)
-- @param row number Board row (1-indexed)
-- @param col number Board column (1-indexed)
-- @param offsetX number Screen X offset
-- @param offsetY number Screen Y offset
-- @return number, number Screen X and Y coordinates
function Logic.boardToScreen(row, col, offsetX, offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0
	local x = offsetX + (col - row) * (Logic.TILE_WIDTH / 2)
	local y = offsetY + (col + row) * (Logic.TILE_HEIGHT / 2)
	return x, y
end

--- Convert screen coordinates to board coordinates
-- @param screenX number Screen X coordinate
-- @param screenY number Screen Y coordinate
-- @param offsetX number Screen X offset
-- @param offsetY number Screen Y offset
-- @return number, number Board row and column (may be fractional)
function Logic.screenToBoard(screenX, screenY, offsetX, offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0
	local x = screenX - offsetX
	local y = screenY - offsetY

	local col = (x / (Logic.TILE_WIDTH / 2) + y / (Logic.TILE_HEIGHT / 2)) / 2
	local row = (y / (Logic.TILE_HEIGHT / 2) - x / (Logic.TILE_WIDTH / 2)) / 2

	return math.floor(row + 0.5), math.floor(col + 0.5)
end

--- Check if board position is valid
-- @param row number Board row
-- @param col number Board column
-- @return boolean True if position is on the board
function Logic.isValidPosition(row, col)
	return row >= 1 and row <= Logic.BOARD_ROWS and col >= 1 and col <= Logic.BOARD_COLS
end

--- Check if a move is valid (basic orthogonal movement)
-- @param fromRow number Starting row
-- @param fromCol number Starting column
-- @param toRow number Target row
-- @param toCol number Target column
-- @param piecePlayer number Player who owns the piece (1 or 2)
-- @param targetPiecePlayer number|nil Player who owns target piece, or nil if empty
-- @return boolean True if move is valid
function Logic.isValidMove(fromRow, fromCol, toRow, toCol, piecePlayer, targetPiecePlayer)
	-- Must move exactly one square orthogonally
	local dr = math.abs(toRow - fromRow)
	local dc = math.abs(toCol - fromCol)

	if not ((dr == 1 and dc == 0) or (dr == 0 and dc == 1)) then
		return false
	end

	-- Check target position is on board
	if not Logic.isValidPosition(toRow, toCol) then
		return false
	end

	-- Can't capture own piece
	if targetPiecePlayer and targetPiecePlayer == piecePlayer then
		return false
	end

	return true
end

--- Get all valid moves for a piece
-- @param row number Piece row
-- @param col number Piece column
-- @param player number Player who owns the piece
-- @param getPieceAt function Function to check if piece exists at position
-- @return table Array of {row, col} valid move positions
function Logic.getValidMoves(row, col, player, getPieceAt)
	local moves = {}
	local directions = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }

	for _, dir in ipairs(directions) do
		local newRow = row + dir[1]
		local newCol = col + dir[2]

		if Logic.isValidPosition(newRow, newCol) then
			local targetPiece = getPieceAt(newRow, newCol)
			local targetPlayer = targetPiece and targetPiece.player or nil

			if Logic.isValidMove(row, col, newRow, newCol, player, targetPlayer) then
				table.insert(moves, { row = newRow, col = newCol })
			end
		end
	end

	return moves
end

--- Create initial piece setup for a player
-- @param player number Player number (1 or 2)
-- @return table Array of piece objects
function Logic.createInitialPieces(player)
	local pieces = {}
	local startRows

	if player == 1 then
		startRows = { 1, 2 }
	else
		startRows = { Logic.BOARD_ROWS - 1, Logic.BOARD_ROWS }
	end

	for _, row in ipairs(startRows) do
		for col = 1, Logic.BOARD_COLS do
			table.insert(pieces, {
				player = player,
				row = row,
				col = col,
				powers = {},
			})
		end
	end

	return pieces
end

--- Count pieces for each player
-- @param pieces table Array of piece objects
-- @return number, number Player 1 count, Player 2 count
function Logic.countPieces(pieces)
	local p1 = 0
	local p2 = 0

	for _, piece in ipairs(pieces) do
		if piece.player == 1 then
			p1 = p1 + 1
		else
			p2 = p2 + 1
		end
	end

	return p1, p2
end

--- Check for game over condition
-- @param pieces table Array of piece objects
-- @return number|nil Winning player (1 or 2), or nil if game continues
function Logic.checkWinner(pieces)
	local p1, p2 = Logic.countPieces(pieces)

	if p1 == 0 then
		return 2
	elseif p2 == 0 then
		return 1
	end

	return nil
end

--- Get the next player
-- @param currentPlayer number Current player (1 or 2)
-- @return number Next player
function Logic.nextPlayer(currentPlayer)
	return currentPlayer == 1 and 2 or 1
end

return Logic
