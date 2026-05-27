-- 2048 Renderer
-- All drawing logic — board, tiles, score, overlays, controls help
-- Colors extracted from the original Android XML drawables

local Game = require("game")

local renderer = {}

-- ============================================================================
-- Color palette (from Android cell_rectangle_*.xml and colors.xml)
-- ============================================================================
local function hex(h)
    h = h:gsub("#", "")
    return tonumber(h:sub(1, 2), 16) / 255,
           tonumber(h:sub(3, 4), 16) / 255,
           tonumber(h:sub(5, 6), 16) / 255
end

-- Tile background colors indexed by value
local tile_colors = {
    [0]    = {hex("#cdc1b4")},   -- empty cell
    [2]    = {hex("#eee4da")},
    [4]    = {hex("#ede0c8")},
    [8]    = {hex("#f2b179")},
    [16]   = {hex("#f59563")},
    [32]   = {hex("#f67c5f")},
    [64]   = {hex("#f65e3b")},
    [128]  = {hex("#edcf72")},
    [256]  = {hex("#edcc61")},
    [512]  = {hex("#edc850")},
    [1024] = {hex("#edc53f")},
    [2048] = {hex("#edc22e")},
}
local super_tile_color = {hex("#3c3a32")}

-- Text colors
local dark_text   = {hex("#776e65")}
local light_text  = {hex("#f9f6f2")}

-- UI colors
local bg_color       = {hex("#faf8ef")}
local board_color    = {hex("#bbada0")}
local score_bg_color = {hex("#bbada0")}
local score_label    = {hex("#eee4da")}
local score_value    = {hex("#ffffff")}
local overlay_win    = {hex("#edc22e")}
local overlay_lose   = {hex("#eee4da")}
local help_bg_color  = {hex("#bbada0")}
local help_key_color = {hex("#edc22e")}

-- ============================================================================
-- Fonts
-- ============================================================================
local font_tile_large
local font_tile_small
local font_tile_tiny   -- for 5+ digit numbers
local font_score
local font_title
local font_label
local font_message
local font_help_key
local font_help_label
local font_path = "assets/ClearSans-Bold.ttf"

-- ============================================================================
-- Layout
-- ============================================================================
local layout = {
    board_x = 0, board_y = 0,
    board_size = 0,
    cell_size = 0,
    cell_gap = 0,
    corner_radius = 0,
    -- Help section
    help_y = 0,
    help_h = 0,
}

-- ============================================================================
-- Initialization
-- ============================================================================
function renderer.init()
    local w, h = love.graphics.getDimensions()
    local scale = _G.scale

    -- Layout strategy: the board is a square that fills most of the screen.
    -- We need space for: top header (title + scores) + board + bottom help bar.
    local header_h = math.floor(65 * scale)   -- title + score boxes
    local help_h   = math.floor(55 * scale)   -- controls help section
    local padding  = math.floor(10 * scale)

    -- Available height for the board
    local avail_h = h - header_h - help_h - padding * 2
    local avail_w = w - padding * 2

    -- Board is a square — fit to the smaller dimension
    local board_size = math.min(avail_w, avail_h)
    local cell_gap = math.floor(board_size * 0.022)
    local cell_size = math.floor((board_size - cell_gap * 5) / 4)
    board_size = cell_size * 4 + cell_gap * 5

    layout.board_size = board_size
    layout.cell_size = cell_size
    layout.cell_gap = cell_gap
    layout.board_x = math.floor((w - board_size) / 2)
    layout.board_y = header_h + padding
    layout.corner_radius = math.floor(cell_size * 0.06)
    layout.help_y = layout.board_y + board_size + padding
    layout.help_h = help_h

    -- Load fonts — sizes relative to cell size for proper scaling
    local tile_font_size = math.floor(cell_size * 0.45)
    local tile_small_size = math.floor(cell_size * 0.35)
    local tile_tiny_size = math.floor(cell_size * 0.28)
    font_tile_large = love.graphics.newFont(font_path, tile_font_size)
    font_tile_small = love.graphics.newFont(font_path, tile_small_size)
    font_tile_tiny  = love.graphics.newFont(font_path, tile_tiny_size)
    font_score      = love.graphics.newFont(font_path, math.floor(19 * scale))
    font_title      = love.graphics.newFont(font_path, math.floor(36 * scale))
    font_label      = love.graphics.newFont(font_path, math.floor(19 * scale))
    font_message    = love.graphics.newFont(font_path, math.floor(28 * scale))
    font_help_key   = love.graphics.newFont(font_path, math.floor(16 * scale))
    font_help_label = love.graphics.newFont(font_path, math.floor(16 * scale))
end

-- ============================================================================
-- Helper: draw a rounded rectangle
-- ============================================================================
local function roundedRect(mode, x, y, w, h, r)
    r = r or 0
    if r <= 0 then
        love.graphics.rectangle(mode, x, y, w, h)
    else
        love.graphics.rectangle(mode, x, y, w, h, r, r)
    end
end

-- ============================================================================
-- Get tile color / text color
-- ============================================================================
local function getTileColor(value)
    return tile_colors[value] or super_tile_color
end

local function getTileTextColor(value)
    if value <= 4 then return dark_text end
    return light_text
end

-- ============================================================================
-- Draw the board background (grid of empty cells)
-- ============================================================================
function renderer.drawBoard()
    local bx, by = layout.board_x, layout.board_y
    local bs = layout.board_size
    local cs = layout.cell_size
    local cg = layout.cell_gap
    local cr = layout.corner_radius

    love.graphics.setColor(board_color)
    roundedRect("fill", bx, by, bs, bs, cr * 2)

    love.graphics.setColor(tile_colors[0])
    for col = 1, 4 do
        for row = 1, 4 do
            local cx = bx + cg + (col - 1) * (cs + cg)
            local cy = by + cg + (row - 1) * (cs + cg)
            roundedRect("fill", cx, cy, cs, cs, cr)
        end
    end
end

-- ============================================================================
-- Draw a single tile
-- ============================================================================
function renderer.drawTile(tile, animProgress)
    local bx, by = layout.board_x, layout.board_y
    local cs = layout.cell_size
    local cg = layout.cell_gap
    local cr = layout.corner_radius

    local tx = bx + cg + (tile.x - 1) * (cs + cg)
    local ty = by + cg + (tile.y - 1) * (cs + cg)

    -- Slide animation
    if tile.previousPosition and animProgress < 1 then
        local px = bx + cg + (tile.previousPosition.x - 1) * (cs + cg)
        local py = by + cg + (tile.previousPosition.y - 1) * (cs + cg)
        tx = px + (tx - px) * animProgress
        ty = py + (ty - py) * animProgress
    end

    -- Scale for spawn / merge animation
    local tileScale = 1
    if tile.isNew and animProgress < 1 then
        tileScale = animProgress
    elseif tile.isMerged and animProgress < 1 then
        if animProgress < 0.5 then
            tileScale = 1 + 0.25 * (animProgress / 0.5)
        else
            tileScale = 1.25 - 0.25 * ((animProgress - 0.5) / 0.5)
        end
    end

    local cx = tx + cs / 2
    local cy = ty + cs / 2
    local scaledSize = cs * tileScale
    local sx = cx - scaledSize / 2
    local sy = cy - scaledSize / 2

    -- Tile background
    local color = getTileColor(tile.value)
    love.graphics.setColor(color)
    roundedRect("fill", sx, sy, scaledSize, scaledSize, cr * tileScale)

    -- Tile text
    local textColor = getTileTextColor(tile.value)
    love.graphics.setColor(textColor)

    local font
    if tile.value >= 10000 then
        font = font_tile_tiny
    elseif tile.value >= 1000 then
        font = font_tile_small
    else
        font = font_tile_large
    end
    love.graphics.setFont(font)

    local text = tostring(tile.value)
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.print(text, cx - tw / 2, cy - th / 2)
end

-- ============================================================================
-- Draw all tiles (layered: normal → merged → new)
-- ============================================================================
function renderer.drawTiles(game)
    local animProgress = game:getAnimationProgress()

    game.grid:eachCell(function(x, y, tile)
        if tile and not tile.isMerged and not tile.isNew then
            renderer.drawTile(tile, animProgress)
        end
    end)

    game.grid:eachCell(function(x, y, tile)
        if tile and tile.isMerged then
            renderer.drawTile(tile, animProgress)
        end
    end)

    game.grid:eachCell(function(x, y, tile)
        if tile and tile.isNew then
            renderer.drawTile(tile, animProgress)
        end
    end)
end

-- ============================================================================
-- Draw score boxes
-- ============================================================================
function renderer.drawScores(game)
    local bx = layout.board_x
    local bs = layout.board_size
    local scale = _G.scale

    local box_w = math.floor(105 * scale)
    local box_h = math.floor(48 * scale)
    local box_gap = math.floor(8 * scale)
    local cr = math.floor(6 * scale)

    local best_x = bx + bs - box_w
    local score_x = best_x - box_w - box_gap
    
    -- Center vertically in the header area (above the board)
    local box_y = math.floor((layout.board_y - box_h) / 2)

    -- SCORE box
    love.graphics.setColor(score_bg_color)
    roundedRect("fill", score_x, box_y, box_w, box_h, cr)

    love.graphics.setFont(font_label)
    love.graphics.setColor(score_label)
    love.graphics.printf("SCORE", score_x, box_y + math.floor(3 * scale), box_w, "center")

    love.graphics.setFont(font_score)
    love.graphics.setColor(score_value)
    love.graphics.printf(tostring(game.score), score_x, box_y + math.floor(24 * scale), box_w, "center")

    -- BEST box
    love.graphics.setColor(score_bg_color)
    roundedRect("fill", best_x, box_y, box_w, box_h, cr)

    love.graphics.setFont(font_label)
    love.graphics.setColor(score_label)
    love.graphics.printf("BEST", best_x, box_y + math.floor(3 * scale), box_w, "center")

    love.graphics.setFont(font_score)
    love.graphics.setColor(score_value)
    love.graphics.printf(tostring(game.highScore), best_x, box_y + math.floor(24 * scale), box_w, "center")
end

-- ============================================================================
-- Draw header ("2048" title)
-- ============================================================================
function renderer.drawHeader()
    local bx = layout.board_x
    local scale = _G.scale

    love.graphics.setFont(font_title)
    love.graphics.setColor(dark_text)
    
    -- Center title vertically in the header area
    local title_y = math.floor((layout.board_y - font_title:getHeight()) / 2)
    love.graphics.print("2048", bx, title_y)
end

-- ============================================================================
-- Draw a key badge (rounded rectangle with text inside)
-- ============================================================================
local function drawKeyBadge(text, x, y, w, h)
    local cr = math.floor(h * 0.3)
    local scale = _G.scale

    -- Badge shadow (depth effect)
    love.graphics.setColor(0, 0, 0, 0.12)
    roundedRect("fill", x, y + math.floor(2 * scale), w, h, cr)

    -- Badge background
    love.graphics.setColor(help_key_color)
    roundedRect("fill", x, y, w, h, cr)

    -- Subtle highlight on top half
    love.graphics.setColor(1, 1, 1, 0.15)
    roundedRect("fill", x, y, w, math.floor(h * 0.5), cr)

    -- Badge text
    love.graphics.setFont(font_help_key)
    love.graphics.setColor(dark_text)
    local tw = font_help_key:getWidth(text)
    local th = font_help_key:getHeight()
    love.graphics.print(text, x + (w - tw) / 2, y + (h - th) / 2)
end

-- ============================================================================
-- Draw controls help section
-- ============================================================================
function renderer.drawHelp(game)
    local w, h = love.graphics.getDimensions()
    local scale = _G.scale
    local padding = math.floor(10 * scale)
    local bar_x = padding
    local bar_w = w - padding * 2
    local hy = layout.help_y
    local hh = layout.help_h
    local cr = math.floor(8 * scale)

    -- Help background bar — solid with subtle border
    love.graphics.setColor(board_color[1], board_color[2], board_color[3], 0.45)
    roundedRect("fill", bar_x, hy, bar_w, hh, cr)
    love.graphics.setColor(board_color[1], board_color[2], board_color[3], 0.25)
    love.graphics.setLineWidth(math.max(1, math.floor(1.5 * scale)))
    roundedRect("line", bar_x, hy, bar_w, hh, cr)

    local badge_h = math.floor(28 * scale)
    local badge_y = hy + (hh - badge_h) / 2
    local gap = math.floor(10 * scale)
    local label_gap = math.floor(6 * scale)

    -- --- D-PAD section (left side) ---
    local dpad_x = bar_x + math.floor(12 * scale)

    -- Arrow key badges
    local arrow_w = math.floor(32 * scale)
    local arrows = {"←", "↑", "↓", "→"}
    for _, arrow in ipairs(arrows) do
        drawKeyBadge(arrow, dpad_x, badge_y, arrow_w, badge_h)
        dpad_x = dpad_x + arrow_w + math.floor(4 * scale)
    end

    -- "Move" label
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(dark_text)
    love.graphics.print("Move", dpad_x + label_gap, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- --- Action buttons (right side) ---
    local right_x = bar_x + bar_w - math.floor(12 * scale)

    -- Determine which actions to show based on game state
    local actions = {}
    if game.state == Game.STATE_WON then
        table.insert(actions, 1, {key = "A", label = "Continue"})
        table.insert(actions, 1, {key = "B", label = "Undo"})
    elseif game.state == Game.STATE_LOST then
        table.insert(actions, 1, {key = "A", label = "New Game"})
        if game.canUndo then
            table.insert(actions, 1, {key = "B", label = "Undo"})
        end
    elseif game.state == Game.STATE_CONFIRM_RESTART then
        table.insert(actions, 1, {key = "A", label = "Yes"})
        table.insert(actions, 1, {key = "B", label = "No"})
    else
        table.insert(actions, 1, {key = "SELECT", label = "New Game"})
        if game.canUndo then
            table.insert(actions, 1, {key = "B", label = "Undo"})
        end
    end

    -- Draw actions right-to-left
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(dark_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(32 * scale), font_help_key:getWidth(action.key) + math.floor(16 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - gap * 2
    end
end

-- ============================================================================
-- Draw game over / win / confirm restart overlay
-- ============================================================================
function renderer.drawOverlay(game)
    if game:isPlaying() then return end
    if game:isAnimating() and game.state ~= Game.STATE_CONFIRM_RESTART then return end

    local bx, by = layout.board_x, layout.board_y
    local bs = layout.board_size

    if game.state == Game.STATE_WON then
        love.graphics.setColor(overlay_win[1], overlay_win[2], overlay_win[3], 0.5)
    elseif game.state == Game.STATE_CONFIRM_RESTART then
        love.graphics.setColor(0, 0, 0, 0.65)
    else
        love.graphics.setColor(overlay_lose[1], overlay_lose[2], overlay_lose[3], 0.5)
    end
    roundedRect("fill", bx, by, bs, bs, layout.corner_radius * 2)

    love.graphics.setFont(font_message)
    if game.state == Game.STATE_WON then
        love.graphics.setColor(light_text)
    elseif game.state == Game.STATE_CONFIRM_RESTART then
        love.graphics.setColor(light_text)
    else
        love.graphics.setColor(dark_text)
    end

    local msg
    if game.state == Game.STATE_WON then
        msg = "You Win!"
    elseif game.state == Game.STATE_CONFIRM_RESTART then
        msg = "Restart Game?"
    else
        msg = "Game Over!"
    end

    local tw = font_message:getWidth(msg)
    local th = font_message:getHeight()
    love.graphics.print(msg, bx + (bs - tw) / 2, by + (bs - th) / 2)
end

-- ============================================================================
-- Main draw function
-- ============================================================================
function renderer.draw(game)
    -- Fill background
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    renderer.drawHeader()
    renderer.drawScores(game)
    renderer.drawBoard()
    renderer.drawTiles(game)
    renderer.drawOverlay(game)
    renderer.drawHelp(game)
end

return renderer
