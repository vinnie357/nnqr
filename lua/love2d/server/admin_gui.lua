-- Admin GUI for server monitoring
-- Provides visual interface for server management in --gui mode

local AdminGui = {}

-- UI Constants
local PANEL_PADDING = 10
local LINE_HEIGHT = 18
local HEADER_HEIGHT = 25
local BUTTON_HEIGHT = 25
local BUTTON_WIDTH = 80

-- Colors
local COLORS = {
	background = { 0.15, 0.15, 0.18 },
	panel = { 0.2, 0.2, 0.25 },
	panelHeader = { 0.25, 0.25, 0.3 },
	text = { 1, 1, 1 },
	textDim = { 0.7, 0.7, 0.7 },
	success = { 0.3, 0.8, 0.3 },
	warning = { 0.9, 0.7, 0.2 },
	error = { 0.9, 0.3, 0.3 },
	button = { 0.3, 0.3, 0.4 },
	buttonHover = { 0.4, 0.4, 0.5 },
	buttonDanger = { 0.6, 0.2, 0.2 },
	buttonDangerHover = { 0.7, 0.3, 0.3 },
}

-- State
local state = {
	startTime = nil,
	logScrollOffset = 0,
	selectedPlayer = nil,
	selectedGame = nil,
	hoveredButton = nil,
}

--- Initialize the admin GUI
---@param server table Server instance
function AdminGui.init(server)
	state.startTime = os.time()
	state.server = server
end

--- Format uptime as human-readable string
---@param seconds number Uptime in seconds
---@return string Formatted uptime
local function formatUptime(seconds)
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d:%02d", hours, mins, secs)
end

--- Draw a panel with header
---@param x number X position
---@param y number Y position
---@param width number Panel width
---@param height number Panel height
---@param title string Panel title
local function drawPanel(x, y, width, height, title)
	-- Panel background
	love.graphics.setColor(COLORS.panel)
	love.graphics.rectangle("fill", x, y, width, height, 5, 5)

	-- Header
	love.graphics.setColor(COLORS.panelHeader)
	love.graphics.rectangle("fill", x, y, width, HEADER_HEIGHT, 5, 5)
	love.graphics.rectangle("fill", x, y + 5, width, HEADER_HEIGHT - 5)

	-- Title
	love.graphics.setColor(COLORS.text)
	love.graphics.print(title, x + PANEL_PADDING, y + 5)
end

--- Draw a button
---@param x number X position
---@param y number Y position
---@param width number Button width
---@param text string Button text
---@param isDanger boolean Use danger color
---@param id string Button identifier for hover state
---@return boolean clicked
local function drawButton(x, y, width, text, isDanger, id)
	local mx, my = love.mouse.getPosition()
	local isHovered = mx >= x and mx <= x + width and my >= y and my <= y + BUTTON_HEIGHT

	if isHovered then
		state.hoveredButton = id
		if isDanger then
			love.graphics.setColor(COLORS.buttonDangerHover)
		else
			love.graphics.setColor(COLORS.buttonHover)
		end
	else
		if isDanger then
			love.graphics.setColor(COLORS.buttonDanger)
		else
			love.graphics.setColor(COLORS.button)
		end
	end

	love.graphics.rectangle("fill", x, y, width, BUTTON_HEIGHT, 3, 3)

	love.graphics.setColor(COLORS.text)
	local textWidth = love.graphics.getFont():getWidth(text)
	love.graphics.print(text, x + (width - textWidth) / 2, y + 5)

	return isHovered and love.mouse.isDown(1)
end

--- Draw server status panel
---@param x number X position
---@param y number Y position
---@param width number Panel width
---@param config table Server config
---@param running boolean Server running state
---@param clientCount number Connected client count
local function drawStatusPanel(x, y, width, config, running, clientCount)
	local height = 140
	drawPanel(x, y, width, height, "Server Status")

	local contentY = y + HEADER_HEIGHT + PANEL_PADDING
	love.graphics.setColor(COLORS.text)

	-- Status indicator
	if running then
		love.graphics.setColor(COLORS.success)
		love.graphics.print("● Running", x + PANEL_PADDING, contentY)
	else
		love.graphics.setColor(COLORS.error)
		love.graphics.print("● Stopped", x + PANEL_PADDING, contentY)
	end

	love.graphics.setColor(COLORS.textDim)
	love.graphics.print("Port:", x + PANEL_PADDING, contentY + LINE_HEIGHT)
	love.graphics.print("Uptime:", x + PANEL_PADDING, contentY + LINE_HEIGHT * 2)
	love.graphics.print("Clients:", x + PANEL_PADDING, contentY + LINE_HEIGHT * 3)

	love.graphics.setColor(COLORS.text)
	love.graphics.print(tostring(config.port), x + 80, contentY + LINE_HEIGHT)
	love.graphics.print(formatUptime(os.time() - state.startTime), x + 80, contentY + LINE_HEIGHT * 2)
	love.graphics.print(tostring(clientCount), x + 80, contentY + LINE_HEIGHT * 3)

	return height
end

--- Draw players panel
---@param x number X position
---@param y number Y position
---@param width number Panel width
---@param server table Server instance
---@param kickCallback function Callback for kick button
local function drawPlayersPanel(x, y, width, server, kickCallback)
	local players = {}
	for playerId, player in pairs(server.lobby.players) do
		table.insert(players, { id = playerId, name = player.name, gameId = player.gameId })
	end

	local height = math.max(100, HEADER_HEIGHT + PANEL_PADDING * 2 + #players * (LINE_HEIGHT + 5))
	drawPanel(x, y, width, height, "Players (" .. #players .. ")")

	local contentY = y + HEADER_HEIGHT + PANEL_PADDING

	if #players == 0 then
		love.graphics.setColor(COLORS.textDim)
		love.graphics.print("No players connected", x + PANEL_PADDING, contentY)
	else
		for i, player in ipairs(players) do
			local rowY = contentY + (i - 1) * (LINE_HEIGHT + 5)

			-- Player name
			love.graphics.setColor(COLORS.text)
			love.graphics.print(player.name, x + PANEL_PADDING, rowY)

			-- Game status
			if player.gameId then
				love.graphics.setColor(COLORS.success)
				love.graphics.print("In game", x + 120, rowY)
			else
				love.graphics.setColor(COLORS.textDim)
				love.graphics.print("In lobby", x + 120, rowY)
			end

			-- Kick button
			if
				drawButton(x + width - BUTTON_WIDTH - PANEL_PADDING, rowY - 2, 50, "Kick", true, "kick_" .. player.id)
			then
				if kickCallback then
					kickCallback(player.id)
				end
			end
		end
	end

	return height
end

--- Draw games panel
---@param x number X position
---@param y number Y position
---@param width number Panel width
---@param server table Server instance
---@param endGameCallback function Callback for end game button
local function drawGamesPanel(x, y, width, server, endGameCallback)
	local games = {}
	for gameId, game in pairs(server.lobby.games) do
		table.insert(games, { id = gameId, name = game.name, status = game.status, playerCount = #game.players })
	end

	local height = math.max(100, HEADER_HEIGHT + PANEL_PADDING * 2 + #games * (LINE_HEIGHT + 5))
	drawPanel(x, y, width, height, "Games (" .. #games .. ")")

	local contentY = y + HEADER_HEIGHT + PANEL_PADDING

	if #games == 0 then
		love.graphics.setColor(COLORS.textDim)
		love.graphics.print("No active games", x + PANEL_PADDING, contentY)
	else
		for i, game in ipairs(games) do
			local rowY = contentY + (i - 1) * (LINE_HEIGHT + 5)

			-- Game name
			love.graphics.setColor(COLORS.text)
			love.graphics.print(game.name, x + PANEL_PADDING, rowY)

			-- Status
			if game.status == "playing" then
				love.graphics.setColor(COLORS.success)
			elseif game.status == "waiting" then
				love.graphics.setColor(COLORS.warning)
			else
				love.graphics.setColor(COLORS.textDim)
			end
			love.graphics.print(game.status .. " (" .. game.playerCount .. "/2)", x + 150, rowY)

			-- End button
			if drawButton(x + width - BUTTON_WIDTH - PANEL_PADDING, rowY - 2, 50, "End", true, "end_" .. game.id) then
				if endGameCallback then
					endGameCallback(game.id)
				end
			end
		end
	end

	return height
end

--- Draw log panel
---@param x number X position
---@param y number Y position
---@param width number Panel width
---@param height number Panel height
---@param logMessages table Array of log messages
local function drawLogPanel(x, y, width, height, logMessages)
	drawPanel(x, y, width, height, "Server Log")

	local contentY = y + HEADER_HEIGHT + PANEL_PADDING
	local contentHeight = height - HEADER_HEIGHT - PANEL_PADDING * 2
	local visibleLines = math.floor(contentHeight / LINE_HEIGHT)

	-- Calculate scroll
	local totalLines = #logMessages
	local maxScroll = math.max(0, totalLines - visibleLines)
	state.logScrollOffset = math.min(state.logScrollOffset, maxScroll)

	-- Set scissor for clipping
	love.graphics.setScissor(x + PANEL_PADDING, contentY, width - PANEL_PADDING * 2, contentHeight)

	local startIdx = math.max(1, totalLines - visibleLines - state.logScrollOffset + 1)
	local endIdx = math.min(totalLines, startIdx + visibleLines)

	for i = startIdx, endIdx do
		local msg = logMessages[i]
		local lineY = contentY + (i - startIdx) * LINE_HEIGHT

		-- Color based on log level
		if msg:find("%[ERROR%]") then
			love.graphics.setColor(COLORS.error)
		elseif msg:find("%[WARN%]") then
			love.graphics.setColor(COLORS.warning)
		elseif msg:find("%[DEBUG%]") then
			love.graphics.setColor(COLORS.textDim)
		else
			love.graphics.setColor(COLORS.text)
		end

		love.graphics.print(msg, x + PANEL_PADDING, lineY)
	end

	love.graphics.setScissor()
end

--- Main draw function
---@param config table Server config
---@param server table Server instance
---@param running boolean Server running state
---@param logMessages table Array of log messages
---@param callbacks table Optional callbacks {kick, endGame, toggleServer}
function AdminGui.draw(config, server, running, logMessages, callbacks)
	callbacks = callbacks or {}

	local screenWidth = love.graphics.getWidth()
	local screenHeight = love.graphics.getHeight()

	-- Background
	love.graphics.setColor(COLORS.background)
	love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

	-- Title
	love.graphics.setColor(COLORS.text)
	love.graphics.print("NNQR Server Admin", PANEL_PADDING, PANEL_PADDING)

	-- Reset hover state
	state.hoveredButton = nil

	-- Left column - Status and controls
	local leftX = PANEL_PADDING
	local leftWidth = 250
	local currentY = 40

	local statusHeight = drawStatusPanel(leftX, currentY, leftWidth, config, running, Server.getClientCount(server))
	currentY = currentY + statusHeight + PANEL_PADDING

	-- Start/Stop button
	local buttonText = running and "Stop Server" or "Start Server"
	if drawButton(leftX, currentY, leftWidth, buttonText, running, "toggle_server") then
		if callbacks.toggleServer then
			callbacks.toggleServer()
		end
	end
	currentY = currentY + BUTTON_HEIGHT + PANEL_PADDING * 2

	-- Players panel
	local playersHeight = drawPlayersPanel(leftX, currentY, leftWidth, server, callbacks.kick)
	currentY = currentY + playersHeight + PANEL_PADDING

	-- Games panel
	drawGamesPanel(leftX, currentY, leftWidth, server, callbacks.endGame)

	-- Right column - Log
	local rightX = leftX + leftWidth + PANEL_PADDING
	local rightWidth = screenWidth - rightX - PANEL_PADDING
	local logHeight = screenHeight - 40 - PANEL_PADDING
	drawLogPanel(rightX, 40, rightWidth, logHeight, logMessages)
end

--- Handle mouse wheel for log scrolling
---@param y number Scroll amount
function AdminGui.wheelmoved(x, y)
	state.logScrollOffset = math.max(0, state.logScrollOffset - y * 3)
end

--- Handle key presses
---@param key string Key pressed
---@return boolean handled
function AdminGui.keypressed(key)
	if key == "home" then
		state.logScrollOffset = 0
		return true
	elseif key == "end" then
		state.logScrollOffset = 999999 -- Will be clamped
		return true
	end
	return false
end

return AdminGui
