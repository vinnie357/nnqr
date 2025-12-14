-- Quadradius Game Module
-- Core game logic and rendering

local Game = {}

-- Board dimensions matching original Quadradius
Game.BOARD_COLS = 10
Game.BOARD_ROWS = 8

-- Game state
Game.board = {}
Game.pieces = {}
Game.currentPlayer = 1
Game.selectedPiece = nil
Game.gameState = "playing" -- "playing", "paused", "gameover"

-- Visual settings
Game.tileWidth = 64
Game.tileHeight = 32 -- Isometric half-height
Game.boardOffsetX = 0
Game.boardOffsetY = 0

-- Colors
Game.colors = {
	player1 = { 0.2, 0.4, 0.8 }, -- Blue
	player2 = { 0.8, 0.2, 0.2 }, -- Red
	tileLight = { 0.9, 0.9, 0.85 },
	tileDark = { 0.7, 0.7, 0.65 },
	selected = { 1.0, 0.9, 0.2 },
	validMove = { 0.2, 0.8, 0.2, 0.5 },
}

function Game.init()
	-- Center the board
	Game.boardOffsetX = love.graphics.getWidth() / 2
	Game.boardOffsetY = 100

	-- Initialize empty board
	for row = 1, Game.BOARD_ROWS do
		Game.board[row] = {}
		for col = 1, Game.BOARD_COLS do
			Game.board[row][col] = {
				height = 0,
				power = nil,
			}
		end
	end

	-- Place initial pieces
	Game.setupPieces()
end

function Game.setupPieces()
	Game.pieces = {}

	-- Player 1 pieces (top two rows)
	for col = 1, Game.BOARD_COLS do
		table.insert(Game.pieces, {
			player = 1,
			row = 1,
			col = col,
			powers = {},
		})
		table.insert(Game.pieces, {
			player = 1,
			row = 2,
			col = col,
		})
	end

	-- Player 2 pieces (bottom two rows)
	for col = 1, Game.BOARD_COLS do
		table.insert(Game.pieces, {
			player = 2,
			row = Game.BOARD_ROWS - 1,
			col = col,
			powers = {},
		})
		table.insert(Game.pieces, {
			player = 2,
			row = Game.BOARD_ROWS,
			col = col,
			powers = {},
		})
	end
end

function Game.update(dt)
	-- Game logic updates here
end

function Game.draw()
	-- Draw board
	Game.drawBoard()

	-- Draw pieces
	Game.drawPieces()

	-- Draw UI
	Game.drawUI()
end

function Game.drawBoard()
	for row = 1, Game.BOARD_ROWS do
		for col = 1, Game.BOARD_COLS do
			local x, y = Game.boardToScreen(row, col)

			-- Alternate tile colors
			local color = ((row + col) % 2 == 0) and Game.colors.tileLight or Game.colors.tileDark
			love.graphics.setColor(color)

			-- Draw isometric tile
			Game.drawIsometricTile(x, y)
		end
	end
end

function Game.drawIsometricTile(x, y)
	local hw = Game.tileWidth / 2
	local hh = Game.tileHeight / 2

	local vertices = {
		x,
		y - hh, -- Top
		x + hw,
		y, -- Right
		x,
		y + hh, -- Bottom
		x - hw,
		y, -- Left
	}

	love.graphics.polygon("fill", vertices)
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.polygon("line", vertices)
end

function Game.drawPieces()
	for _, piece in ipairs(Game.pieces) do
		local x, y = Game.boardToScreen(piece.row, piece.col)
		local color = piece.player == 1 and Game.colors.player1 or Game.colors.player2

		love.graphics.setColor(color)
		love.graphics.circle("fill", x, y - 10, 20)

		-- Highlight selected piece
		if Game.selectedPiece == piece then
			love.graphics.setColor(Game.colors.selected)
			love.graphics.setLineWidth(3)
			love.graphics.circle("line", x, y - 10, 22)
			love.graphics.setLineWidth(1)
		end
	end
end

function Game.drawUI()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Quadradius - Love2D", 10, 10)
	love.graphics.print("Player " .. Game.currentPlayer .. "'s turn", 10, 30)
	love.graphics.print("Click to select, click again to move", 10, 50)
	love.graphics.print("ESC to quit", 10, 70)
end

function Game.boardToScreen(row, col)
	-- Convert board coordinates to isometric screen coordinates
	local x = Game.boardOffsetX + (col - row) * (Game.tileWidth / 2)
	local y = Game.boardOffsetY + (col + row) * (Game.tileHeight / 2)
	return x, y
end

function Game.screenToBoard(screenX, screenY)
	-- Convert screen coordinates to board coordinates
	local x = screenX - Game.boardOffsetX
	local y = screenY - Game.boardOffsetY

	local col = (x / (Game.tileWidth / 2) + y / (Game.tileHeight / 2)) / 2
	local row = (y / (Game.tileHeight / 2) - x / (Game.tileWidth / 2)) / 2

	return math.floor(row + 0.5), math.floor(col + 0.5)
end

function Game.mousepressed(x, y, button)
	if button == 1 then -- Left click
		local row, col = Game.screenToBoard(x, y)

		-- Check if valid board position
		if row >= 1 and row <= Game.BOARD_ROWS and col >= 1 and col <= Game.BOARD_COLS then
			local clickedPiece = Game.getPieceAt(row, col)

			if Game.selectedPiece then
				-- Try to move selected piece
				if Game.isValidMove(Game.selectedPiece, row, col) then
					Game.movePiece(Game.selectedPiece, row, col)
					Game.selectedPiece = nil
					Game.endTurn()
				else
					Game.selectedPiece = nil
				end
			elseif clickedPiece and clickedPiece.player == Game.currentPlayer then
				-- Select piece
				Game.selectedPiece = clickedPiece
			end
		end
	end
end

function Game.mousereleased(x, y, button)
	-- Drag and drop handling (future)
end

function Game.mousemoved(x, y, dx, dy)
	-- Hover effects (future)
end

function Game.keypressed(key)
	if key == "r" then
		Game.init() -- Reset game
	end
end

function Game.wheelmoved(x, y)
	-- Zoom handling (future)
end

function Game.getPieceAt(row, col)
	for _, piece in ipairs(Game.pieces) do
		if piece.row == row and piece.col == col then
			return piece
		end
	end
	return nil
end

function Game.isValidMove(piece, toRow, toCol)
	-- Basic movement: one square orthogonally
	local dr = math.abs(toRow - piece.row)
	local dc = math.abs(toCol - piece.col)

	-- Must move exactly one square orthogonally
	if not ((dr == 1 and dc == 0) or (dr == 0 and dc == 1)) then
		return false
	end

	-- Check if destination is empty or has enemy piece
	local targetPiece = Game.getPieceAt(toRow, toCol)
	if targetPiece and targetPiece.player == piece.player then
		return false -- Can't capture own piece
	end

	return true
end

function Game.movePiece(piece, toRow, toCol)
	-- Check for capture
	local targetPiece = Game.getPieceAt(toRow, toCol)
	if targetPiece then
		-- Remove captured piece
		for i, p in ipairs(Game.pieces) do
			if p == targetPiece then
				table.remove(Game.pieces, i)
				break
			end
		end
	end

	-- Move piece
	piece.row = toRow
	piece.col = toCol
end

function Game.endTurn()
	Game.currentPlayer = Game.currentPlayer == 1 and 2 or 1

	-- Check for game over
	local player1Pieces = 0
	local player2Pieces = 0

	for _, piece in ipairs(Game.pieces) do
		if piece.player == 1 then
			player1Pieces = player1Pieces + 1
		else
			player2Pieces = player2Pieces + 1
		end
	end

	if player1Pieces == 0 then
		Game.gameState = "gameover"
		print("Player 2 wins!")
	elseif player2Pieces == 0 then
		Game.gameState = "gameover"
		print("Player 1 wins!")
	end
end

return Game
