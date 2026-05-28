-- 2048 Renderer
-- All drawing logic — board, tiles, score, overlays, controls help
-- Colors extracted from the original Android XML drawables

local Game = require("game")

local renderer = {}

-- Theme transition animation state
local transition_canvas = nil
local transition_timer = 0
local transition_duration = 0.5
local transition_center_x = 0
local transition_center_y = 0

-- Win animation state
local win_particles = {}
local win_timer = 0
local win_text_bounce = 0

-- Color palette (from Android cell_rectangle_*.xml and colors.xml)
-- ============================================================================
local function hex(h)
    h = h:gsub("#", "")
    return tonumber(h:sub(1, 2), 16) / 255,
           tonumber(h:sub(3, 4), 16) / 255,
           tonumber(h:sub(5, 6), 16) / 255
end

local themes = {
    light = {
        tile_colors = {
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
        },
        super_tile_color = {hex("#3c3a32")},
        dark_text        = {hex("#776e65")},
        light_text       = {hex("#f9f6f2")},
        ui_text          = {hex("#776e65")},
        bg_color         = {hex("#faf8ef")},
        board_color      = {hex("#bbada0")},
        score_bg_color   = {hex("#bbada0")},
        score_label      = {hex("#eee4da")},
        score_value      = {hex("#ffffff")},
        overlay_win      = {hex("#edc22e")},
        overlay_lose     = {hex("#eee4da")},
        help_bg_color    = {hex("#bbada0")},
        help_key_color   = {hex("#edc22e")},
        help_key_text    = {hex("#776e65")},
    },
    dark = {
        tile_colors = {
            [0]    = {hex("#3a3a3a")},   -- empty cell
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
        },
        super_tile_color = {hex("#eee4da")},
        dark_text        = {hex("#776e65")},  -- Kept dark for light tiles
        light_text       = {hex("#f9f6f2")},
        ui_text          = {hex("#eee4da")},  -- Light color for UI text
        bg_color         = {hex("#121212")},
        board_color      = {hex("#2d2d2d")},
        score_bg_color   = {hex("#2d2d2d")},
        score_label      = {hex("#bbada0")},
        score_value      = {hex("#ffffff")},
        overlay_win      = {hex("#edc22e")},
        overlay_lose     = {hex("#2d2d2d")},
        help_bg_color    = {hex("#2d2d2d")},
        help_key_color   = {hex("#4a4a4a")},
        help_key_text    = {hex("#eee4da")},
    }
}

-- Current active colors (will be populated by applyTheme)
local tile_colors, super_tile_color, dark_text, light_text, ui_text
local bg_color, board_color, score_bg_color, score_label, score_value
local overlay_win, overlay_lose, help_bg_color, help_key_color, help_key_text

function renderer.applyTheme()
    local t = themes[_G.theme] or themes.light
    tile_colors = t.tile_colors
    super_tile_color = t.super_tile_color
    dark_text = t.dark_text
    light_text = t.light_text
    ui_text = t.ui_text
    bg_color = t.bg_color
    board_color = t.board_color
    score_bg_color = t.score_bg_color
    score_label = t.score_label
    score_value = t.score_value
    overlay_win = t.overlay_win
    overlay_lose = t.overlay_lose
    help_bg_color = t.help_bg_color
    help_key_color = t.help_key_color
    help_key_text = t.help_key_text
end

-- Initialize theme immediately
renderer.applyTheme()

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
    font_score      = love.graphics.newFont(font_path, math.floor(20 * scale))
    font_title      = love.graphics.newFont(font_path, math.floor(36 * scale))
    font_label      = love.graphics.newFont(font_path, math.floor(16 * scale))
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
    if value >= 4096 and _G.theme == "dark" then return dark_text end
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

    -- Scale for spawn / merge / bomb animation
    local tileScale = 1
    if tile.isBombing then
        tileScale = 1 - animProgress
    elseif tile.isNew and animProgress < 1 then
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
        if tile and not tile.isMerged and not tile.isNew and not tile.isSwapping then
            renderer.drawTile(tile, animProgress)
        end
    end)

    game.grid:eachCell(function(x, y, tile)
        if tile and tile.isMerged and not tile.isSwapping then
            renderer.drawTile(tile, animProgress)
        end
    end)

    game.grid:eachCell(function(x, y, tile)
        if tile and tile.isNew and not tile.isSwapping then
            renderer.drawTile(tile, animProgress)
        end
    end)

    if game.bombAnimation then
        local p = 1 - (game.bombAnimation.timer / game.bombAnimation.duration)
        local t = {
            x = game.bombAnimation.x,
            y = game.bombAnimation.y,
            value = game.bombAnimation.tileValue,
            isBombing = true
        }
        renderer.drawTile(t, p)
    end

    if game.swapAnimation then
        local p = 1 - (game.swapAnimation.timer / game.swapAnimation.duration)
        
        local drawSwapTile = function(s)
            if not s then return end
            local t = {
                x = s.endX,
                y = s.endY,
                value = s.val,
                previousPosition = {x = s.startX, y = s.startY}
            }
            renderer.drawTile(t, p)
        end

        drawSwapTile(game.swapAnimation.t1)
        drawSwapTile(game.swapAnimation.t2)
    end
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

    -- Dynamic vertical centering of text inside score boxes
    local label_h = font_label:getHeight()
    local score_h = font_score:getHeight()
    local spacing = math.floor(1 * scale)
    local total_text_h = label_h + score_h + spacing
    local top_padding = math.floor((box_h - total_text_h) / 2)
    
    -- Subtract 1px visually to account for optical baseline offset of all-caps text
    local label_y = box_y + top_padding - math.floor(1 * scale)
    local score_y = box_y + top_padding + label_h + spacing

    -- SCORE box
    love.graphics.setColor(score_bg_color)
    roundedRect("fill", score_x, box_y, box_w, box_h, cr)

    love.graphics.setFont(font_label)
    love.graphics.setColor(score_label)
    love.graphics.printf("SCORE", score_x, label_y, box_w, "center")

    love.graphics.setFont(font_score)
    love.graphics.setColor(score_value)
    love.graphics.printf(tostring(game.score), score_x, score_y, box_w, "center")

    -- BEST box
    love.graphics.setColor(score_bg_color)
    roundedRect("fill", best_x, box_y, box_w, box_h, cr)

    love.graphics.setFont(font_label)
    love.graphics.setColor(score_label)
    love.graphics.printf("BEST", best_x, label_y, box_w, "center")

    love.graphics.setFont(font_score)
    love.graphics.setColor(score_value)
    love.graphics.printf(tostring(game.highScore), best_x, score_y, box_w, "center")
end

-- ============================================================================
-- Draw header ("2048" title)
-- ============================================================================
function renderer.drawHeader(game)
    local bx = layout.board_x
    local scale = _G.scale

    love.graphics.setFont(font_title)
    love.graphics.setColor(ui_text)
    
    if game and game.won then
        local total_h = font_title:getHeight() + font_label:getHeight() - math.floor(4 * scale)
        local title_y = math.floor((layout.board_y - total_h) / 2)
        love.graphics.print("2048", bx, title_y)
        
        love.graphics.setFont(font_label)
        love.graphics.print("Endless Mode", bx, title_y + font_title:getHeight() - math.floor(4 * scale))
    else
        -- Center title vertically in the header area
        local title_y = math.floor((layout.board_y - font_title:getHeight()) / 2)
        love.graphics.print("2048", bx, title_y)
    end
end

-- ============================================================================
-- Draw a key badge (rounded rectangle with text inside)
-- ============================================================================
local function drawKeyBadge(text, x, y, w, h)
    local cr = math.floor(h * 0.3)
    local scale = _G.scale

    -- Badge shadow (depth effect) - inset to prevent edge fringing
    love.graphics.setColor(0, 0, 0, 0.15)
    local sh_in = math.max(1, math.floor(1 * scale))
    local sh_off = math.max(1, math.floor(2 * scale))
    roundedRect("fill", x + sh_in, y + sh_off, w - sh_in * 2, h, cr)

    -- Badge background
    love.graphics.setColor(help_key_color)
    roundedRect("fill", x, y, w, h, cr)

    -- Subtle highlight on top half
    love.graphics.setColor(1, 1, 1, 0.15)
    roundedRect("fill", x, y, w, math.floor(h * 0.5), cr)

    -- Badge text
    love.graphics.setFont(font_help_key)
    love.graphics.setColor(help_key_text)
    local tw = font_help_key:getWidth(text)
    local th = font_help_key:getHeight()

    -- Visual alignment corrections for arrows in ClearSans
    local offset_x, offset_y = 0, 0
    if text == "←" then
        offset_y = -math.floor(2 * scale)
        offset_x = math.floor(1 * scale)
    elseif text == "→" then
        offset_y = -math.floor(2 * scale)
        offset_x = -math.floor(1 * scale)
    end

    love.graphics.print(text, x + (w - tw) / 2 + offset_x, y + (h - th) / 2 + offset_y)
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

    -- Arrow key badges (the 'Move' label has been removed to free up space)
    local arrow_w = math.floor(32 * scale)
    local arrows = {"←", "↑", "↓", "→"}
    for _, arrow in ipairs(arrows) do
        drawKeyBadge(arrow, dpad_x, badge_y, arrow_w, badge_h)
        dpad_x = dpad_x + arrow_w + math.floor(4 * scale)
    end

    -- Action buttons (right side) ---
    local right_x = bar_x + bar_w - math.floor(12 * scale)

    -- Determine which actions to show based on game state
    local actions = {}

    if game.state == Game.STATE_WON then
        table.insert(actions, 1, {key = "A", label = "Continue"})
        table.insert(actions, 1, {key = "Y", label = "Theme"})
        if game.mode ~= "plus" then
            table.insert(actions, 1, {key = "B", label = "Undo"})
        end
    elseif game.state == Game.STATE_LOST then
        table.insert(actions, 1, {key = "A", label = "New Game"})
        table.insert(actions, 1, {key = "Y", label = "Theme"})
        if game.canUndo and game.mode ~= "plus" then
            table.insert(actions, 1, {key = "B", label = "Undo"})
        end
    elseif game.state == Game.STATE_PAUSED then
        table.insert(actions, 1, {key = "A", label = "Restart"})
        table.insert(actions, 1, {key = "X", label = "Quit"})
        table.insert(actions, 1, {key = "B", label = "Resume"})
    elseif game.state == Game.STATE_TARGETING_BOMB or game.state == Game.STATE_TARGETING_SWAP_1 or game.state == Game.STATE_TARGETING_SWAP_2 then
        table.insert(actions, 1, {key = "A", label = "Confirm"})
        table.insert(actions, 1, {key = "B", label = "Cancel"})
    else
        table.insert(actions, 1, {key = "START", label = "Pause"})
        table.insert(actions, 1, {key = "Y", label = "Theme"})
        if game.mode == "plus" then
            table.insert(actions, 1, {key = "L1", label = "Swap:" .. game.powerups.swap})
            table.insert(actions, 1, {key = "R1", label = "Bomb:" .. game.powerups.bomb})
            table.insert(actions, 1, {key = "B", label = "Undo:" .. game.powerups.undo})
        else
            if game.canUndo then
                table.insert(actions, 1, {key = "B", label = "Undo"})
            end
        end
    end

    -- Draw actions right-to-left
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(32 * scale), font_help_key:getWidth(action.key) + math.floor(16 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - math.floor(gap * 1.5)
    end
end

-- ============================================================================
-- Draw game over / win / confirm restart overlay
-- ============================================================================
function renderer.drawOverlay(game)
    if game:isPlaying() then 
        win_timer = 0
        return 
    end
    if game:isAnimating() and game.state ~= Game.STATE_PAUSED then return end

    local bx, by = layout.board_x, layout.board_y
    local bs = layout.board_size
    local dt = love.timer.getDelta()

    if game.state == Game.STATE_WON then
        win_timer = win_timer + dt
        local fade_t = math.min(win_timer / 0.8, 1.0)
        -- Smooth ease out
        local ease_t = 1 - math.pow(1 - fade_t, 3)
        
        love.graphics.setColor(overlay_win[1], overlay_win[2], overlay_win[3], 0.6 * ease_t)
        roundedRect("fill", bx, by, bs, bs, layout.corner_radius * 2)

        local msg = "You Win!"
        love.graphics.setFont(font_message)
        local tw = font_message:getWidth(msg)
        local th = font_message:getHeight()
        local textX = bx + bs / 2
        local textY = by + bs / 2

        -- Pulsing golden glow behind the text
        local glow_alpha = (math.sin(win_timer * 3) * 0.5 + 0.5) * 0.4 * ease_t
        local glow_color = getTileColor(2048)
        love.graphics.setColor(glow_color[1], glow_color[2], glow_color[3], glow_alpha)
        
        -- Draw soft glow by drawing multiple scaled rounded rectangles
        for i = 1, 3 do
            local gw = tw + (40 * _G.scale * i)
            local gh = th + (40 * _G.scale * i)
            roundedRect("fill", textX - gw/2, textY - gh/2, gw, gh, layout.corner_radius * 2)
        end

        -- Draw the text
        local text_scale = 0.8 + (0.2 * ease_t)
        love.graphics.setColor(light_text[1], light_text[2], light_text[3], ease_t)
        
        love.graphics.push()
        love.graphics.translate(textX, textY)
        love.graphics.scale(text_scale, text_scale)
        love.graphics.print(msg, -tw/2, -th/2)
        love.graphics.pop()
    else
        win_timer = 0
        
        if game.state == Game.STATE_PAUSED then
            love.graphics.setColor(0, 0, 0, 0.65)
        else
            love.graphics.setColor(overlay_lose[1], overlay_lose[2], overlay_lose[3], 0.5)
        end
        roundedRect("fill", bx, by, bs, bs, layout.corner_radius * 2)

        local msg = game.state == Game.STATE_PAUSED and "Paused" or "Game Over!"
        love.graphics.setFont(font_message)
        if game.state == Game.STATE_PAUSED then
            love.graphics.setColor(light_text)
        else
            love.graphics.setColor(ui_text)
        end

        local tw = font_message:getWidth(msg)
        local th = font_message:getHeight()
        love.graphics.print(msg, bx + (bs - tw) / 2, by + (bs - th) / 2)
    end
end

-- ============================================================================
-- Main draw function
-- ============================================================================
local function drawStencilCircle()
    local progress = 1 - (transition_timer / transition_duration)
    -- Ease out cubic: 1 - (1 - t)^3
    local p = 1 - math.pow(1 - progress, 3)
    local w, h = love.graphics.getDimensions()
    -- Max radius needs to cover the entire screen from the bottom right
    local max_radius = math.sqrt(w*w + h*h)
    local radius = max_radius * p
    love.graphics.circle("fill", transition_center_x, transition_center_y, radius)
end

function renderer.startThemeTransition(drawTarget)
    local w, h = love.graphics.getDimensions()
    if not transition_canvas then
        transition_canvas = love.graphics.newCanvas(w, h)
    end
    -- Capture current screen to canvas
    love.graphics.setCanvas(transition_canvas)
    love.graphics.clear()
    if type(drawTarget) == "function" then
        drawTarget()
    else
        renderer.draw(drawTarget, true) -- Pass true to skip transition drawing inside
    end
    love.graphics.setCanvas()
    
    transition_timer = transition_duration
    -- The Y button is approximately at the bottom right
    transition_center_x = w - math.floor(90 * _G.scale)
    transition_center_y = h - math.floor(30 * _G.scale)
end

function renderer.updateTransition(dt)
    if transition_timer > 0 then
        transition_timer = math.max(0, transition_timer - dt)
    end
end

-- ============================================================================
-- Draw targeting cursor
-- ============================================================================
function renderer.drawTargetingCursor(game)
    if game.state ~= Game.STATE_TARGETING_BOMB and 
       game.state ~= Game.STATE_TARGETING_SWAP_1 and 
       game.state ~= Game.STATE_TARGETING_SWAP_2 then
        return
    end

    local bx, by = layout.board_x, layout.board_y
    local cs = layout.cell_size
    local cg = layout.cell_gap
    local cr = layout.corner_radius

    -- Darken the board slightly
    love.graphics.setColor(0, 0, 0, 0.4)
    roundedRect("fill", bx, by, layout.board_size, layout.board_size, cr * 2)

    -- Draw swap target 1 if active
    if game.swapTarget then
        local stx = bx + cg + (game.swapTarget.x - 1) * (cs + cg)
        local sty = by + cg + (game.swapTarget.y - 1) * (cs + cg)
        love.graphics.setColor(0.3, 0.7, 1, 0.5)
        roundedRect("fill", stx, sty, cs, cs, cr)
        love.graphics.setLineWidth(4 * _G.scale)
        love.graphics.setColor(0.3, 0.7, 1, 1)
        roundedRect("line", stx, sty, cs, cs, cr)
    end

    -- Draw cursor
    local tx = bx + cg + (game.cursorX - 1) * (cs + cg)
    local ty = by + cg + (game.cursorY - 1) * (cs + cg)

    -- Blink effect
    local time = love.timer.getTime()
    local alpha = 0.5 + 0.5 * math.sin(time * 10)
    
    if game.state == Game.STATE_TARGETING_BOMB then
        love.graphics.setColor(1, 0.2, 0.2, alpha)
    else
        love.graphics.setColor(0.3, 1, 0.3, alpha)
    end
    
    love.graphics.setLineWidth(6 * _G.scale)
    roundedRect("line", tx, ty, cs, cs, cr)
end

-- ============================================================================
-- Main Menu
-- ============================================================================
function renderer.drawMainMenu(selection)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale

    love.graphics.setFont(font_title)
    love.graphics.setColor(ui_text)
    local title = "2048"
    local tw = font_title:getWidth(title)
    love.graphics.print(title, (w - tw) / 2, h * 0.2)
    
    love.graphics.setFont(font_label)
    local sub = "Select Mode"
    local sw = font_label:getWidth(sub)
    love.graphics.print(sub, (w - sw) / 2, h * 0.2 + font_title:getHeight())

    local options = {"Play Classic", "Play Plus", "Quit"}
    local start_y = h * 0.45
    local gap = math.floor(40 * scale)

    love.graphics.setFont(font_message)
    for i, opt in ipairs(options) do
        local ow = font_message:getWidth(opt)
        local oy = start_y + (i - 1) * gap
        if i == selection then
            love.graphics.setColor(help_key_color)
            roundedRect("fill", (w - ow) / 2 - 20 * scale, oy - 5 * scale, ow + 40 * scale, font_message:getHeight() + 10 * scale, 8 * scale)
            love.graphics.setColor(help_key_text)
        else
            love.graphics.setColor(ui_text)
        end
        love.graphics.print(opt, (w - ow) / 2, oy)
    end
end

-- ============================================================================
-- Main draw function
-- ============================================================================
function renderer.draw(game, skip_transition)
    -- Fill background
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    renderer.drawHeader(game)
    renderer.drawScores(game)
    renderer.drawBoard()
    renderer.drawTiles(game)
    renderer.drawTargetingCursor(game)
    renderer.drawOverlay(game)
    renderer.drawHelp(game)
    
    if not skip_transition and transition_timer > 0 and transition_canvas then
        -- We want to draw the OLD screen (transition_canvas) everywhere EXCEPT where the stencil is.
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0) -- Draw where stencil is 0
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest() -- Disable stencil
    end
end

return renderer
