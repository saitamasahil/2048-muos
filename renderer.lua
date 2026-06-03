-- 2048 Renderer
-- All drawing logic — board, tiles, score, overlays, controls help
-- Colors extracted from the original Android XML drawables

local Game = require("game")
local save = require("save")

local renderer = {}

-- Theme transition animation state
local transition_canvas = nil
local transition_timer = 0
local transition_duration = 0.5
local transition_center_x = 0
local transition_center_y = 0
renderer.theme_button_x = nil
renderer.theme_button_y = nil

-- Menu selection animation state
local menu_anim_y = nil
local menu_anim_target_y = nil
local logo_2048 = nil

-- Win animation state
local win_timer = 0

-- Text size flash animation state (triggered when text size is toggled)
local text_size_flash_timer = 0
local TEXT_SIZE_FLASH_DURATION = 0.4

-- Arcade Menu animation state
local arcade_panel_y_offset = 9999  -- starts fully hidden (off screen below)
local arcade_panel_target = 9999    -- target offset
local arcade_menu_bg_alpha = 0      -- dim overlay alpha (0..0.75)

function renderer.setArcadeMenuOpen(open)
    if open then
        arcade_panel_target = 0
    else
        -- Will be set to panel height by drawArcadeMenu; use a big number for now
        arcade_panel_target = 9999
    end
end

function renderer.flashTextSize()
    text_size_flash_timer = TEXT_SIZE_FLASH_DURATION
end

-- Toast state
local toast_message = nil
local toast_timer = 0
local toast_queue = {}
local toast_max_duration = 1.5
local TOAST_DURATION = 1.5

function renderer.showToast(msg, custom_duration)
    local duration = custom_duration or TOAST_DURATION
    if toast_timer > 0 then
        table.insert(toast_queue, {msg = msg, duration = duration})
    else
        toast_message = msg
        toast_timer = duration
        toast_max_duration = duration
    end
end

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
    },
    oled = {
        tile_colors = {
            [0]    = {hex("#1a1a1a")},   -- empty cell
            [2]    = {hex("#333333")},
            [4]    = {hex("#4d4d4d")},
            [8]    = {hex("#666666")},
            [16]   = {hex("#808080")},
            [32]   = {hex("#999999")},
            [64]   = {hex("#b3b3b3")},
            [128]  = {hex("#cccccc")},
            [256]  = {hex("#e6e6e6")},
            [512]  = {hex("#ffffff")},
            [1024] = {hex("#ffffff")},
            [2048] = {hex("#ffffff")},
        },
        super_tile_color = {hex("#ffffff")},
        dark_text        = {hex("#000000")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#ffffff")},
        bg_color         = {hex("#000000")},
        board_color      = {hex("#0f0f0f")},
        score_bg_color   = {hex("#0f0f0f")},
        score_label      = {hex("#888888")},
        score_value      = {hex("#ffffff")},
        overlay_win      = {hex("#ffffff")},
        overlay_lose     = {hex("#0f0f0f")},
        help_bg_color    = {hex("#0f0f0f")},
        help_key_color   = {hex("#333333")},
        help_key_text    = {hex("#ffffff")},
    },
    neon = {
        tile_colors = {
            [0]    = {hex("#1f2833")},   -- empty cell
            [2]    = {hex("#0f172a")},
            [4]    = {hex("#23194d")},
            [8]    = {hex("#371b71")},
            [16]    = {hex("#4c1d95")},
            [32]    = {hex("#711b82")},
            [64]    = {hex("#97196f")},
            [128]    = {hex("#be185d")},
            [256]    = {hex("#cd454b")},
            [512]    = {hex("#dc7239")},
            [1024]    = {hex("#eb9f27")},
            [2048]    = {hex("#facc15")},
        },
        super_tile_color = {hex("#ff00ff")},
        dark_text        = {hex("#0b0c10")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#66fcf1")},
        bg_color         = {hex("#0b0c10")},
        board_color      = {hex("#1f2833")},
        score_bg_color   = {hex("#1f2833")},
        score_label      = {hex("#45a29e")},
        score_value      = {hex("#66fcf1")},
        overlay_win      = {hex("#ff00ff")},
        overlay_lose     = {hex("#1f2833")},
        help_bg_color    = {hex("#1f2833")},
        help_key_color   = {hex("#45a29e")},
        help_key_text    = {hex("#0b0c10")},
    },
    retro = {
        tile_colors = {
            [0]    = {hex("#306230")},   -- empty cell (mid-dark green so tiles pop)
            [2]    = {hex("#9bbc0f")},
            [4]    = {hex("#8fb00f")},
            [8]    = {hex("#83a40f")},
            [16]   = {hex("#77980f")},
            [32]   = {hex("#6b8c0f")},
            [64]   = {hex("#5f800f")},
            [128]  = {hex("#53740f")},
            [256]  = {hex("#47680f")},
            [512]  = {hex("#3b5c0f")},
            [1024] = {hex("#2f500f")},
            [2048] = {hex("#0f380f")},
        },
        super_tile_color = {hex("#0f380f")},
        dark_text        = {hex("#0f380f")},
        light_text       = {hex("#9bbc0f")},
        ui_text          = {hex("#0f380f")},
        bg_color         = {hex("#9bbc0f")},
        board_color      = {hex("#306230")},
        score_bg_color   = {hex("#306230")},
        score_label      = {hex("#0f380f")},
        score_value      = {hex("#9bbc0f")},
        overlay_win      = {hex("#306230")},
        overlay_lose     = {hex("#8bac0f")},
        help_bg_color    = {hex("#8bac0f")},
        help_key_color   = {hex("#0f380f")},
        help_key_text    = {hex("#9bbc0f")},
    },
    peach = {
        tile_colors = {
            [0]    = {hex("#ffdab9")},   -- empty cell
            [2]    = {hex("#ffe5b4")},
            [4]    = {hex("#f3cea2")},
            [8]    = {hex("#e7b790")},
            [16]    = {hex("#dca07e")},
            [32]    = {hex("#d0896c")},
            [64]    = {hex("#c5725a")},
            [128]    = {hex("#b95b48")},
            [256]    = {hex("#ad4436")},
            [512]    = {hex("#a22d24")},
            [1024]    = {hex("#961612")},
            [2048]    = {hex("#8b0000")},
        },
        super_tile_color = {hex("#c27a7e")},
        dark_text        = {hex("#783f44")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#c27a7e")},
        bg_color         = {hex("#ffe5b4")},
        board_color      = {hex("#ffdab9")},
        score_bg_color   = {hex("#ffdab9")},
        score_label      = {hex("#c27a7e")},
        score_value      = {hex("#c27a7e")},
        overlay_win      = {hex("#ff69b4")},
        overlay_lose     = {hex("#ffdab9")},
        help_bg_color    = {hex("#ffdab9")},
        help_key_color   = {hex("#c27a7e")},
        help_key_text    = {hex("#ffffff")},
    },
    ascii = {
        tile_colors = {
            [0]    = {hex("#000000")},
            [2]    = {hex("#00ff00")},
            [4]    = {hex("#00ff00")},
            [8]    = {hex("#00ff00")},
            [16]   = {hex("#00ff00")},
            [32]   = {hex("#00ff00")},
            [64]   = {hex("#00ff00")},
            [128]  = {hex("#00ff00")},
            [256]  = {hex("#00ff00")},
            [512]  = {hex("#00ff00")},
            [1024] = {hex("#00ff00")},
            [2048] = {hex("#00ff00")},
        },
        super_tile_color = {hex("#00ff00")},
        dark_text        = {hex("#00ff00")},
        light_text       = {hex("#00ff00")},
        ui_text          = {hex("#00ff00")},
        bg_color         = {hex("#000000")},
        board_color      = {hex("#00ff00")},
        score_bg_color   = {hex("#000000")},
        score_label      = {hex("#00ff00")},
        score_value      = {hex("#00ff00")},
        overlay_win      = {hex("#00ff00")},
        overlay_lose     = {hex("#000000")},
        help_bg_color    = {hex("#000000")},
        help_key_color   = {hex("#00ff00")},
        help_key_text    = {hex("#00ff00")},
    },
    -- Simple themes (color-only, no custom tiles — use default light tile colors)
    ocean = {
        tile_colors = {
            [0]    = {hex("#b8d4e3")},
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
        super_tile_color = {hex("#1a5276")},
        dark_text        = {hex("#1a5276")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#1a5276")},
        bg_color         = {hex("#d6eaf8")},
        board_color      = {hex("#aed6f1")},
        score_bg_color   = {hex("#aed6f1")},
        score_label      = {hex("#2980b9")},
        score_value      = {hex("#1a5276")},
        overlay_win      = {hex("#2980b9")},
        overlay_lose     = {hex("#aed6f1")},
        help_bg_color    = {hex("#aed6f1")},
        help_key_color   = {hex("#2980b9")},
        help_key_text    = {hex("#ffffff")},
    },
    forest = {
        tile_colors = {
            [0]    = {hex("#c8dbbe")},
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
        super_tile_color = {hex("#1e6b3a")},
        dark_text        = {hex("#2d5016")},
        light_text       = {hex("#f9f6f2")},
        ui_text          = {hex("#2d5016")},
        bg_color         = {hex("#e8f5e9")},
        board_color      = {hex("#a5d6a7")},
        score_bg_color   = {hex("#a5d6a7")},
        score_label      = {hex("#388e3c")},
        score_value      = {hex("#1b5e20")},
        overlay_win      = {hex("#388e3c")},
        overlay_lose     = {hex("#a5d6a7")},
        help_bg_color    = {hex("#a5d6a7")},
        help_key_color   = {hex("#388e3c")},
        help_key_text    = {hex("#ffffff")},
    },
    sunset = {
        tile_colors = {
            [0]    = {hex("#f5cba7")},
            [2]    = {hex("#fadbd8")},
            [4]    = {hex("#f5b7b1")},
            [8]    = {hex("#f1948a")},
            [16]   = {hex("#ec7063")},
            [32]   = {hex("#e74c3c")},
            [64]   = {hex("#cb4335")},
            [128]  = {hex("#b03a2e")},
            [256]  = {hex("#f9e79f")},
            [512]  = {hex("#f7dc6f")},
            [1024] = {hex("#f4d03f")},
            [2048] = {hex("#f1c40f")},
        },
        super_tile_color = {hex("#922b21")},
        dark_text        = {hex("#784212")},
        light_text       = {hex("#fef9e7")},
        ui_text          = {hex("#922b21")},
        bg_color         = {hex("#fdebd0")},
        board_color      = {hex("#f0b27a")},
        score_bg_color   = {hex("#f0b27a")},
        score_label      = {hex("#d35400")},
        score_value      = {hex("#922b21")},
        overlay_win      = {hex("#e67e22")},
        overlay_lose     = {hex("#f0b27a")},
        help_bg_color    = {hex("#f0b27a")},
        help_key_color   = {hex("#d35400")},
        help_key_text    = {hex("#ffffff")},
    },
    candy = {
        tile_colors = {
            [0]    = {hex("#f8c8dc")},
            [2]    = {hex("#f5eef8")},
            [4]    = {hex("#ebdef0")},
            [8]    = {hex("#d7bde2")},
            [16]   = {hex("#c39bd3")},
            [32]   = {hex("#af7ac5")},
            [64]   = {hex("#9b59b6")},
            [128]  = {hex("#884ea0")},
            [256]  = {hex("#76448a")},
            [512]  = {hex("#f1948a")},
            [1024] = {hex("#ec7063")},
            [2048] = {hex("#e74c3c")},
        },
        super_tile_color = {hex("#9b2335")},
        dark_text        = {hex("#6c3483")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#9b2335")},
        bg_color         = {hex("#fdedec")},
        board_color      = {hex("#f5b7b1")},
        score_bg_color   = {hex("#f5b7b1")},
        score_label      = {hex("#c0392b")},
        score_value      = {hex("#9b2335")},
        overlay_win      = {hex("#e74c3c")},
        overlay_lose     = {hex("#f5b7b1")},
        help_bg_color    = {hex("#f5b7b1")},
        help_key_color   = {hex("#c0392b")},
        help_key_text    = {hex("#ffffff")},
    },
    midnight = {
        tile_colors = {
            [0]    = {hex("#334155")},
            [2]    = {hex("#2c3e50")},
            [4]    = {hex("#3f3f62")},
            [8]    = {hex("#534075")},
            [16]    = {hex("#664187")},
            [32]    = {hex("#7a429a")},
            [64]    = {hex("#8e44ad")},
            [128]    = {hex("#a15d8d")},
            [256]    = {hex("#b5776d")},
            [512]    = {hex("#c9904e")},
            [1024]    = {hex("#ddaa2e")},
            [2048]    = {hex("#f1c40f")},
        },
        super_tile_color = {hex("#818cf8")},
        dark_text        = {hex("#0f172a")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#cbd5e1")},
        bg_color         = {hex("#0f172a")},
        board_color      = {hex("#1e293b")},
        score_bg_color   = {hex("#1e293b")},
        score_label      = {hex("#cbd5e1")},
        score_value      = {hex("#f8fafc")},
        overlay_win      = {hex("#6366f1")},
        overlay_lose     = {hex("#1e293b")},
        help_bg_color    = {hex("#1e293b")},
        help_key_color   = {hex("#6366f1")},
        help_key_text    = {hex("#ffffff")},
    },
    volcano = {
        tile_colors = {
            [0]    = {hex("#404040")},
            [2]    = {hex("#d6dbdf")},
            [4]    = {hex("#aeb6bf")},
            [8]    = {hex("#85929e")},
            [16]   = {hex("#5d6d7e")},
            [32]   = {hex("#34495e")},
            [64]   = {hex("#2e4053")},
            [128]  = {hex("#f5b041")},
            [256]  = {hex("#f39c12")},
            [512]  = {hex("#e67e22")},
            [1024] = {hex("#d35400")},
            [2048] = {hex("#e74c3c")},
        },
        super_tile_color = {hex("#ef4444")},
        dark_text        = {hex("#1a1a1a")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#e5e5e5")},
        bg_color         = {hex("#1a1a1a")},
        board_color      = {hex("#2d2d2d")},
        score_bg_color   = {hex("#2d2d2d")},
        score_label      = {hex("#ef4444")},
        score_value      = {hex("#fca5a5")},
        overlay_win      = {hex("#dc2626")},
        overlay_lose     = {hex("#2d2d2d")},
        help_bg_color    = {hex("#2d2d2d")},
        help_key_color   = {hex("#dc2626")},
        help_key_text    = {hex("#ffffff")},
    },
    abyss = {
        tile_colors = {
            [0]    = {hex("#0f766e")},
            [2]    = {hex("#a3e4d7")},
            [4]    = {hex("#76d7c4")},
            [8]    = {hex("#48c9b0")},
            [16]   = {hex("#1abc9c")},
            [32]   = {hex("#17a589")},
            [64]   = {hex("#148f77")},
            [128]  = {hex("#094a40")},
            [256]  = {hex("#053029")},
            [512]  = {hex("#58d68d")},
            [1024] = {hex("#2ecc71")},
            [2048] = {hex("#27ae60")},
        },
        super_tile_color = {hex("#14b8a6")},
        dark_text        = {hex("#042f2e")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#ccfbf1")},
        bg_color         = {hex("#042f2e")},
        board_color      = {hex("#115e59")},
        score_bg_color   = {hex("#115e59")},
        score_label      = {hex("#ccfbf1")},
        score_value      = {hex("#5eead4")},
        overlay_win      = {hex("#0d9488")},
        overlay_lose     = {hex("#115e59")},
        help_bg_color    = {hex("#115e59")},
        help_key_color   = {hex("#0d9488")},
        help_key_text    = {hex("#ffffff")},
    },
    eclipse = {
        tile_colors = {
            [0]    = {hex("#3f3f46")},
            [2]    = {hex("#f2f3f4")},
            [4]    = {hex("#e5e7e9")},
            [8]    = {hex("#d7dbdd")},
            [16]   = {hex("#cacfd2")},
            [32]   = {hex("#bdc3c7")},
            [64]   = {hex("#a6acaf")},
            [128]  = {hex("#909497")},
            [256]  = {hex("#797d7f")},
            [512]  = {hex("#626567")},
            [1024] = {hex("#4d5656")},
            [2048] = {hex("#f1c40f")},
        },
        super_tile_color = {hex("#facc15")},
        dark_text        = {hex("#18181b")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#f4f4f5")},
        bg_color         = {hex("#18181b")},
        board_color      = {hex("#27272a")},
        score_bg_color   = {hex("#27272a")},
        score_label      = {hex("#fde047")},
        score_value      = {hex("#fef08a")},
        overlay_win      = {hex("#eab308")},
        overlay_lose     = {hex("#27272a")},
        help_bg_color    = {hex("#27272a")},
        help_key_color   = {hex("#eab308")},
        help_key_text    = {hex("#ffffff")},
    },
    cyberpunk = {
        tile_colors = {
            [0]    = {hex("#2d1b4e")},
            [2]    = {hex("#2d1b4e")},
            [4]    = {hex("#472583")},
            [8]    = {hex("#612fb8")},
            [16]    = {hex("#7c3aed")},
            [32]    = {hex("#a44cda")},
            [64]    = {hex("#cc5fc8")},
            [128]    = {hex("#f472b6")},
            [256]    = {hex("#8ba2d2")},
            [512]    = {hex("#22d3ee")},
            [1024]    = {hex("#8ecf81")},
            [2048]    = {hex("#facc15")},
        },
        super_tile_color = {hex("#facc15")},
        dark_text        = {hex("#0f172a")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#f472b6")},
        bg_color         = {hex("#0f172a")},
        board_color      = {hex("#1e1b4b")},
        score_bg_color   = {hex("#1e1b4b")},
        score_label      = {hex("#e879f9")},
        score_value      = {hex("#facc15")},
        overlay_win      = {hex("#f472b6")},
        overlay_lose     = {hex("#1e1b4b")},
        help_bg_color    = {hex("#1e1b4b")},
        help_key_color   = {hex("#f472b6")},
        help_key_text    = {hex("#ffffff")},
    },
    matrix = {
        tile_colors = {
            [0]    = {hex("#022c22")},
            [2]    = {hex("#064e3b")},
            [4]    = {hex("#065f46")},
            [8]    = {hex("#047857")},
            [16]   = {hex("#059669")},
            [32]   = {hex("#10b981")},
            [64]   = {hex("#34d399")},
            [128]  = {hex("#6ee7b7")},
            [256]  = {hex("#a7f3d0")},
            [512]  = {hex("#d1fae5")},
            [1024] = {hex("#ecfdf5")},
            [2048] = {hex("#ffffff")},
        },
        super_tile_color = {hex("#10b981")},
        dark_text        = {hex("#022c22")},
        light_text       = {hex("#a7f3d0")},
        ui_text          = {hex("#10b981")},
        bg_color         = {hex("#000000")},
        board_color      = {hex("#020617")},
        score_bg_color   = {hex("#020617")},
        score_label      = {hex("#059669")},
        score_value      = {hex("#10b981")},
        overlay_win      = {hex("#10b981")},
        overlay_lose     = {hex("#020617")},
        help_bg_color    = {hex("#020617")},
        help_key_color   = {hex("#10b981")},
        help_key_text    = {hex("#000000")},
    },
    vaporwave = {
        tile_colors = {
            [0]    = {hex("#312e81")},
            [2]    = {hex("#1e3a8a")},
            [4]    = {hex("#433c9e")},
            [8]    = {hex("#683eb2")},
            [16]    = {hex("#8e41c6")},
            [32]    = {hex("#b343da")},
            [64]    = {hex("#d946ef")},
            [128]    = {hex("#c366e3")},
            [256]    = {hex("#ae86d8")},
            [512]    = {hex("#98a6cd")},
            [1024]    = {hex("#83c6c2")},
            [2048]    = {hex("#6ee7b7")},
        },
        super_tile_color = {hex("#c084fc")},
        dark_text        = {hex("#1e1b4b")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#f472b6")},
        bg_color         = {hex("#172554")},
        board_color      = {hex("#1e1b4b")},
        score_bg_color   = {hex("#1e1b4b")},
        score_label      = {hex("#818cf8")},
        score_value      = {hex("#e879f9")},
        overlay_win      = {hex("#f472b6")},
        overlay_lose     = {hex("#1e1b4b")},
        help_bg_color    = {hex("#1e1b4b")},
        help_key_color   = {hex("#c084fc")},
        help_key_text    = {hex("#ffffff")},
    },
    dracula = {
        tile_colors = {
            [0]    = {hex("#44475a")},
            [2]    = {hex("#282a36")},
            [4]    = {hex("#3b425a")},
            [8]    = {hex("#4e597f")},
            [16]    = {hex("#6272a4")},
            [32]    = {hex("#9674af")},
            [64]    = {hex("#ca76ba")},
            [128]    = {hex("#ff79c6")},
            [256]    = {hex("#fb99b7")},
            [512]    = {hex("#f8b9a9")},
            [1024]    = {hex("#f4d99a")},
            [2048]    = {hex("#f1fa8c")},
        },
        super_tile_color = {hex("#ff79c6")},
        dark_text        = {hex("#282a36")},
        light_text       = {hex("#f8f8f2")},
        ui_text          = {hex("#ff79c6")},
        bg_color         = {hex("#282a36")},
        board_color      = {hex("#44475a")},
        score_bg_color   = {hex("#44475a")},
        score_label      = {hex("#6272a4")},
        score_value      = {hex("#f8f8f2")},
        overlay_win      = {hex("#ff79c6")},
        overlay_lose     = {hex("#44475a")},
        help_bg_color    = {hex("#44475a")},
        help_key_color   = {hex("#bd93f9")},
        help_key_text    = {hex("#f8f8f2")},
    },
    gold = {
        tile_colors = {
            [0]    = {hex("#262626")},
            [2]    = {hex("#78716c")},
            [4]    = {hex("#a8a29e")},
            [8]    = {hex("#d6d3d1")},
            [16]   = {hex("#f5f5f4")},
            [32]   = {hex("#d4a373")},
            [64]   = {hex("#dda15e")},
            [128]  = {hex("#e6ccb2")},
            [256]  = {hex("#ede0d4")},
            [512]  = {hex("#fcd5ce")},
            [1024] = {hex("#f8edeb")},
            [2048] = {hex("#ffd700")},
        },
        super_tile_color = {hex("#ffd700")},
        dark_text        = {hex("#171717")},
        light_text       = {hex("#f5f5f5")},
        ui_text          = {hex("#d4af37")},
        bg_color         = {hex("#0f0f0f")},
        board_color      = {hex("#171717")},
        score_bg_color   = {hex("#171717")},
        score_label      = {hex("#a8a29e")},
        score_value      = {hex("#ffd700")},
        overlay_win      = {hex("#ffd700")},
        overlay_lose     = {hex("#171717")},
        help_bg_color    = {hex("#171717")},
        help_key_color   = {hex("#d4af37")},
        help_key_text    = {hex("#171717")},
    },
    matcha = {
        tile_colors = {
            [0]    = {hex("#d7ccc8")},
            [2]    = {hex("#fff8e1")},
            [4]    = {hex("#ffecb3")},
            [8]    = {hex("#dce775")},
            [16]   = {hex("#cddc39")},
            [32]   = {hex("#aed581")},
            [64]   = {hex("#8bc34a")},
            [128]  = {hex("#689f38")},
            [256]  = {hex("#558b2f")},
            [512]  = {hex("#33691e")},
            [1024] = {hex("#8d6e63")},
            [2048] = {hex("#5d4037")},
        },
        super_tile_color = {hex("#5d4037")},
        dark_text        = {hex("#4e342e")},
        light_text       = {hex("#fff8e1")},
        ui_text          = {hex("#558b2f")},
        bg_color         = {hex("#efebe9")},
        board_color      = {hex("#bcaaa4")},
        score_bg_color   = {hex("#bcaaa4")},
        score_label      = {hex("#8d6e63")},
        score_value      = {hex("#4e342e")},
        overlay_win      = {hex("#558b2f")},
        overlay_lose     = {hex("#bcaaa4")},
        help_bg_color    = {hex("#bcaaa4")},
        help_key_color   = {hex("#8bc34a")},
        help_key_text    = {hex("#4e342e")},
    },
    aurora = {
        -- Deep-space Northern Lights: pitch-black void, tiles shift from
        -- electric teal → violet → magenta → blinding white as they grow.
        -- UI text is a soft spectral cyan that pops against the darkness.
        tile_colors = {
            [0]    = {hex("#050d14")},   -- near-void dark
            [2]    = {hex("#062e2e")},   -- deep teal abyss
            [4]    = {hex("#0a3d3d")},   -- dark teal
            [8]    = {hex("#0e6666")},   -- glowing teal
            [16]   = {hex("#0aabb5")},   -- electric cyan
            [32]   = {hex("#0dd4e0")},   -- bright arctic
            [64]   = {hex("#2854a0")},   -- deep violet-blue
            [128]  = {hex("#5b2c8b")},   -- royal violet
            [256]  = {hex("#8b24a0")},   -- deep magenta-violet
            [512]  = {hex("#bf1ea8")},   -- vivid magenta
            [1024] = {hex("#e01d9e")},   -- hot pink-magenta
            [2048] = {hex("#ffffff")},   -- pure blinding white — the peak
        },
        super_tile_color = {hex("#ffffff")},
        dark_text        = {hex("#010810")},
        light_text       = {hex("#ffffff")},
        ui_text          = {hex("#5efcee")},   -- spectral aurora cyan
        bg_color         = {hex("#010810")},   -- deep space black
        board_color      = {hex("#050d14")},   -- near-void board
        score_bg_color   = {hex("#050d14")},
        score_label      = {hex("#2cd4c4")},   -- aurora teal label
        score_value      = {hex("#5efcee")},   -- spectral cyan value
        overlay_win      = {hex("#0dd4e0")},   -- arctic cyan win
        overlay_lose     = {hex("#050d14")},
        help_bg_color    = {hex("#050d14")},
        help_key_color   = {hex("#0aabb5")},   -- electric teal highlight
        help_key_text    = {hex("#ffffff")},
    }
}

-- Returns all theme names defined in the themes table, excluding always-unlocked ones.
-- Used by cheats to dynamically unlock everything without a hardcoded list.
function renderer.getAllThemeNames()
    -- "light" and "dark" are always unlocked; "ascii" auto-unlocks on cheat entry
    local always_unlocked = { light = true, dark = true, ascii = true }
    local names = {}
    for name in pairs(themes) do
        if not always_unlocked[name] then
            table.insert(names, name)
        end
    end
    return names
end

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

function renderer.getThemeBgColor()
    return bg_color
end

function renderer.getThemeTileColors()
    local t = themes[_G.theme] or themes.light
    return t.tile_colors, t.super_tile_color
end

function renderer.getThemeHighlightColors()
    local t = themes[_G.theme] or themes.light
    return t.super_tile_color or {hex("#edc22e")}, t.board_color or {hex("#bbada0")}
end

-- ============================================================================
-- Fonts
-- ============================================================================
local font_tile_large
local font_tile_small
local font_tile_tiny   -- for 5+ digit numbers
local font_score
local font_title
local font_main_menu_title
local font_cheats_title
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
    local text_scale = 1.0
    local tile_scale = 1.0
    if _G.text_size == "large" then
        text_scale = 1.15
        tile_scale = 1.05
    end

    local tile_font_size = math.floor(cell_size * 0.45 * tile_scale)
    local tile_small_size = math.floor(cell_size * 0.35 * tile_scale)
    local tile_tiny_size = math.floor(cell_size * 0.28 * tile_scale)
    font_tile_large = love.graphics.newFont(font_path, tile_font_size)
    font_tile_small = love.graphics.newFont(font_path, tile_small_size)
    font_tile_tiny  = love.graphics.newFont(font_path, tile_tiny_size)
    font_score      = love.graphics.newFont(font_path, math.floor(20 * scale * text_scale))
    font_title      = love.graphics.newFont(font_path, math.floor(36 * scale * text_scale))
    font_main_menu_title = love.graphics.newFont(font_path, math.floor(72 * scale))
    font_cheats_title = love.graphics.newFont(font_path, math.floor(56 * scale))
    font_label      = love.graphics.newFont(font_path, math.floor(16 * scale * text_scale))
    font_message    = love.graphics.newFont(font_path, math.floor(28 * scale * text_scale))
    font_help_key   = love.graphics.newFont(font_path, math.floor(16 * scale * text_scale))
    font_help_label = love.graphics.newFont(font_path, math.floor(16 * scale * text_scale))
    logo_2048 = love.graphics.newImage("assets/logo_2048.png")
end

-- ============================================================================
-- Helper: draw a rounded rectangle
-- ============================================================================
local function roundedRect(mode, x, y, w, h, r)
    if _G.theme == "ascii" then
        if mode == "fill" then
            local cr, cg, cb, ca = love.graphics.getColor()
            love.graphics.setColor(0, 0, 0, ca)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(cr, cg, cb, ca)
        end
        
        local font = font_help_label
        if not font then font = love.graphics.getFont() end
        
        -- Use plain rectangle for very small UI elements to avoid clutter
        if w < 40 * _G.scale or h < 40 * _G.scale then
            love.graphics.rectangle("line", x, y, w, h)
            return
        end

        local prev_font = love.graphics.getFont()
        love.graphics.setFont(font)

        local char_w = math.max(1, font:getWidth("-"))
        local char_h = math.max(1, font:getHeight())

        love.graphics.print("+", x, y)
        love.graphics.print("+", x + w - char_w, y)
        love.graphics.print("+", x, y + h - char_h)
        love.graphics.print("+", x + w - char_w, y + h - char_h)

        if w > char_w * 2 then
            for bx = x + char_w, x + w - char_w * 1.5, char_w do
                love.graphics.print("-", bx, y)
                love.graphics.print("-", bx, y + h - char_h)
            end
        end

        if h > char_h * 2 then
            for by = y + char_h, y + h - char_h * 1.5, char_h do
                love.graphics.print("|", x, by)
                love.graphics.print("|", x + w - char_w, by)
            end
        end

        love.graphics.setFont(prev_font)
        return
    end

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
    -- Preserve classic 2048 text colors for default themes
    if _G.theme == "light" or _G.theme == "dark" or _G.theme == "ocean" or _G.theme == "forest" then
        if value <= 4 then return dark_text end
        if value >= 4096 and _G.theme == "dark" then return dark_text end
        return light_text
    end
    
    -- Dynamic contrast for all other custom/premium themes
    local color = getTileColor(value)
    local luminance = 0.299 * color[1] + 0.587 * color[2] + 0.114 * color[3]
    if luminance > 0.5 then
        return dark_text
    else
        return light_text
    end
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

    if _G.theme == "ascii" then
        love.graphics.setColor(board_color)
    else
        love.graphics.setColor(tile_colors[0])
    end
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

    if game.floatingNotifications then
        local bx, by = layout.board_x, layout.board_y
        local cs = layout.cell_size
        local cg = layout.cell_gap
        for _, n in ipairs(game.floatingNotifications) do
            local cx = bx + cg + (n.col - 1) * (cs + cg) + cs / 2
            local cy = by + cg + (n.row - 1) * (cs + cg) + cs / 2
            
            -- Float upward based on elapsed life
            local elapsed = n.max_life - n.timer
            local float_y = cy - (elapsed * 55 * _G.scale)
            
            -- Fade out
            local alpha = math.min(1, n.timer / 0.3)
            
            love.graphics.setFont(font_help_key)
            
            -- Text shadow for legibility
            love.graphics.setColor(0, 0, 0, alpha * 0.75)
            love.graphics.printf(n.text, cx - 100 * _G.scale, float_y + 1, 200 * _G.scale, "center")
            
            -- Text fill (bold emerald green / neon green)
            if _G.theme == "ascii" then
                love.graphics.setColor(0, 1, 0, alpha)
            else
                love.graphics.setColor(0.18, 0.72, 0.35, alpha)
            end
            love.graphics.printf(n.text, cx - 100 * _G.scale, float_y, 200 * _G.scale, "center")
        end
    end
end

-- ============================================================================
-- Draw score boxes
-- ============================================================================
function renderer.drawScores(game)
    local bx = layout.board_x
    local bs = layout.board_size
    local scale = _G.scale

    local box_w = math.floor((_G.text_size == "large" and 115 or 105) * scale)
    local box_h = math.floor((_G.text_size == "large" and 56 or 48) * scale)
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

    if game.mode == "timeattack" and game.timeLeft ~= nil then
        -- TIMER box (replaces BEST in Time Attack)
        local t = math.max(0, game.timeLeft)
        local mins = math.floor(t / 60)
        local secs = math.floor(t % 60)
        local timer_str = string.format("%d:%02d", mins, secs)

        -- Box background (subtly different tint when urgent or flashing)
        if game.timerFlashTimer and game.timerFlashTimer > 0 then
            local f = game.timerFlashTimer / 0.3
            local r_col = score_bg_color[1] * (1 - f) + 0.0 * f
            local g_col = score_bg_color[2] * (1 - f) + 0.8 * f
            local b_col = score_bg_color[3] * (1 - f) + 0.7 * f
            love.graphics.setColor(r_col, g_col, b_col, 0.95)
        else
            love.graphics.setColor(score_bg_color)
        end
        roundedRect("fill", best_x, box_y, box_w, box_h, cr)

        -- "TIME" label
        love.graphics.setFont(font_label)
        if t <= 10 then
            -- Pulsing red label
            local pulse = (math.sin(love.timer.getTime() * 8) * 0.5 + 0.5)
            love.graphics.setColor(1.0, 0.25 + pulse * 0.25, 0.2, 1.0)
        elseif t <= 30 then
            love.graphics.setColor(1.0, 0.65, 0.1, 1.0)   -- warm orange
        else
            love.graphics.setColor(score_label)
        end
        love.graphics.printf("TIME", best_x, label_y, box_w, "center")

        -- Timer value
        love.graphics.setFont(font_score)
        if t <= 10 then
            local pulse = (math.sin(love.timer.getTime() * 8) * 0.5 + 0.5)
            love.graphics.setColor(1.0, 0.2 + pulse * 0.3, 0.2, 1.0)
        elseif t <= 30 then
            love.graphics.setColor(1.0, 0.65, 0.1, 1.0)
        else
            love.graphics.setColor(score_value)
        end
        love.graphics.printf(timer_str, best_x, score_y, box_w, "center")

        -- Draw floating time attack popups
        if game.timePopups then
            love.graphics.setFont(font_help_label)
            for _, p in ipairs(game.timePopups) do
                local p_str = p.text
                local p_w = font_help_label:getWidth(p_str)
                local px = best_x + (box_w - p_w) / 2
                local py = box_y - math.floor(10 * scale) + p.y_offset
                
                -- Shadow
                love.graphics.setColor(0, 0, 0, p.alpha * 0.75)
                love.graphics.print(p_str, px + 1, py + 1)
                
                -- Main text
                love.graphics.setColor(0.18, 0.85, 0.45, p.alpha)
                love.graphics.print(p_str, px)
            end
        end
    else
        -- Normal BEST box
        love.graphics.setColor(score_bg_color)
        roundedRect("fill", best_x, box_y, box_w, box_h, cr)

        love.graphics.setFont(font_label)
        love.graphics.setColor(score_label)
        love.graphics.printf("BEST", best_x, label_y, box_w, "center")

        love.graphics.setFont(font_score)
        love.graphics.setColor(score_value)
        love.graphics.printf(tostring(game.highScore), best_x, score_y, box_w, "center")
    end
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
        local offset = math.floor((_G.text_size == "large" and 10 or 4) * scale)
        
        local text = "Endless Mode"
        local tw = font_label:getWidth(text)
        local box_w = math.floor((_G.text_size == "large" and 115 or 105) * scale)
        local box_gap = math.floor(8 * scale)
        local best_x = bx + layout.board_size - box_w
        local score_x = best_x - box_w - box_gap
        
        local avail_w = math.max(1, score_x - bx - math.floor(6 * scale))
        local text_s = 1.0
        if tw > avail_w then
            text_s = avail_w / tw
        end
        
        love.graphics.print(text, bx, title_y + font_title:getHeight() - offset, 0, text_s, text_s)
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
    local scale = _G.scale
    local visual_offset_y = -math.max(1, math.floor(1.5 * scale))

    -- Save dynamically tracked coordinates for the Theme Y button
    if text == "Y" then
        renderer.theme_button_x = x + w / 2
        renderer.theme_button_y = y + h / 2
    end

    -- Determine if this button is currently pressed for visual feedback
    local is_pressed = false
    local is_left = false
    local is_right = false
    local is_up = false
    local is_down = false

    local success, Input = pcall(require, "input")
    if success and Input and Input.state then
        if text == "DPAD" then
            is_left = Input.state["left"] == true
            is_right = Input.state["right"] == true
            is_up = Input.state["up"] == true
            is_down = Input.state["down"] == true
            is_pressed = is_left or is_right or is_up or is_down
        else
            if text == "START" then
                is_pressed = (Input.state["space"] == true) or (Input.state["rshift"] == true)
            else
                local mapping = {
                    A = "return",
                    B = "backspace",
                    X = "x",
                    Y = "y",
                    L1 = "l1",
                    R1 = "r1"
                }
                local mapped = mapping[text]
                if mapped then
                    is_pressed = Input.state[mapped] == true
                end
            end
        end
    end

    -- Apply tactile button depression shifts
    local press_shift_y = 0
    local shadow_shrink = 1.0
    if is_pressed then
        press_shift_y = math.max(1, math.floor(1.5 * scale))
        shadow_shrink = 0.3
    end

    if text == "DPAD" then
        local aw = w * 0.32
        local cr = math.floor(aw * 0.25)
        
        if _G.theme == "ascii" then
            -- Black background cross (shifted by press_shift_y)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", x, y + (h - aw) / 2 + press_shift_y, w, aw)
            love.graphics.rectangle("fill", x + (w - aw) / 2, y + press_shift_y, aw, h)
            
            -- Green outline cross (shifted by press_shift_y)
            love.graphics.setColor(help_key_color)
            love.graphics.setLineWidth(math.max(1, math.floor(1 * scale)))
            love.graphics.rectangle("line", x, y + (h - aw) / 2 + press_shift_y, w, aw)
            love.graphics.rectangle("line", x + (w - aw) / 2, y + press_shift_y, aw, h)
            
            -- Center core circle outline
            love.graphics.circle("line", x + w/2, y + h/2 + press_shift_y, aw * 0.7)

            -- Draw four small direction dots inside in help_key_text (press-feedback highlights)
            love.graphics.setColor(help_key_text)
            local dot_r = math.max(1.2 * scale, 1)
            local offset = w * 0.35
            
            local dot_l = is_left and math.max(2.5 * scale, 2) or dot_r
            local dot_r_active = is_right and math.max(2.5 * scale, 2) or dot_r
            local dot_u = is_up and math.max(2.5 * scale, 2) or dot_r
            local dot_d = is_down and math.max(2.5 * scale, 2) or dot_r
            
            love.graphics.circle("fill", x + w/2 - offset, y + h/2 + press_shift_y, dot_l) -- Left
            love.graphics.circle("fill", x + w/2 + offset, y + h/2 + press_shift_y, dot_r_active) -- Right
            love.graphics.circle("fill", x + w/2, y + h/2 - offset + press_shift_y, dot_u) -- Up
            love.graphics.circle("fill", x + w/2, y + h/2 + offset + press_shift_y, dot_d) -- Down
            return
        end

        -- D-Pad shadow (shrinks when depressed)
        love.graphics.setColor(0, 0, 0, 0.2)
        local sh = math.max(1, math.floor(1.5 * scale)) * shadow_shrink
        love.graphics.rectangle("fill", x, y + (h - aw) / 2 + sh, w, aw, cr)
        love.graphics.rectangle("fill", x + (w - aw) / 2, y + sh, aw, h, cr)

        -- D-Pad body (shifted by press_shift_y)
        love.graphics.setColor(help_key_color)
        love.graphics.rectangle("fill", x, y + (h - aw) / 2 + press_shift_y, w, aw, cr)
        love.graphics.rectangle("fill", x + (w - aw) / 2, y + press_shift_y, aw, h, cr)
        
        -- Center core circle to blend the intersection
        love.graphics.circle("fill", x + w/2, y + h/2 + press_shift_y, aw * 0.7)

        -- Draw four small direction dots inside in help_key_text (press-feedback highlights)
        love.graphics.setColor(help_key_text)
        local dot_r = math.max(1.2 * scale, 1)
        local offset = w * 0.35
        
        local dot_l = is_left and math.max(2.5 * scale, 2) or dot_r
        local dot_r_active = is_right and math.max(2.5 * scale, 2) or dot_r
        local dot_u = is_up and math.max(2.5 * scale, 2) or dot_r
        local dot_d = is_down and math.max(2.5 * scale, 2) or dot_r
        
        love.graphics.circle("fill", x + w/2 - offset, y + h/2 + press_shift_y, dot_l) -- Left
        love.graphics.circle("fill", x + w/2 + offset, y + h/2 + press_shift_y, dot_r_active) -- Right
        love.graphics.circle("fill", x + w/2, y + h/2 - offset + press_shift_y, dot_u) -- Up
        love.graphics.circle("fill", x + w/2, y + h/2 + offset + press_shift_y, dot_d) -- Down
        return
    end

    if text == "A" or text == "B" or text == "X" or text == "Y" then
        local cx, cy = x + w/2, y + h/2
        local r = h * 0.45
        
        if _G.theme == "ascii" then
            -- Black background circle
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.circle("fill", cx, cy + press_shift_y, r)
            
            -- Green outline circle
            love.graphics.setColor(help_key_color)
            love.graphics.setLineWidth(math.max(1, math.floor(1 * scale)))
            love.graphics.circle("line", cx, cy + press_shift_y, r)
            
            -- Text letter
            love.graphics.setFont(font_help_key)
            love.graphics.setColor(help_key_text)
            local tw = font_help_key:getWidth(text)
            local th = font_help_key:getHeight()
            love.graphics.print(text, cx - tw/2, cy - th/2 + visual_offset_y + press_shift_y)
            return
        end

        -- Button shadow (shrinks when depressed)
        love.graphics.setColor(0, 0, 0, 0.25)
        local sh = math.max(1, math.floor(1.5 * scale)) * shadow_shrink
        love.graphics.circle("fill", cx, cy + sh, r)
        
        -- Button body (shifted by press_shift_y)
        love.graphics.setColor(help_key_color)
        love.graphics.circle("fill", cx, cy + press_shift_y, r)
        
        -- Button border
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.setLineWidth(math.max(1, math.floor(1 * scale)))
        love.graphics.circle("line", cx, cy + press_shift_y, r)
        
        -- Text letter
        love.graphics.setFont(font_help_key)
        love.graphics.setColor(help_key_text)
        local tw = font_help_key:getWidth(text)
        local th = font_help_key:getHeight()
        love.graphics.print(text, cx - tw/2, cy - th/2 + visual_offset_y + press_shift_y)
        return
    end

    if text == "L1" or text == "R1" or text == "L" or text == "R" then
        local cr = math.floor(h * 0.4)
        
        if _G.theme == "ascii" then
            -- Black background capsule
            love.graphics.setColor(0, 0, 0, 1)
            roundedRect("fill", x, y + press_shift_y, w, h, cr)
            
            -- Green outline capsule
            love.graphics.setColor(help_key_color)
            love.graphics.setLineWidth(math.max(1, math.floor(1 * scale)))
            roundedRect("line", x, y + press_shift_y, w, h, cr)
            
            -- Text
            love.graphics.setFont(font_help_key)
            love.graphics.setColor(help_key_text)
            local tw = font_help_key:getWidth(text)
            local th = font_help_key:getHeight()
            love.graphics.print(text, x + (w - tw) / 2, y + (h - th) / 2 + visual_offset_y + press_shift_y)
            return
        end

        -- Shadow (shrinks when depressed)
        love.graphics.setColor(0, 0, 0, 0.2)
        local sh = math.max(1, math.floor(1.5 * scale)) * shadow_shrink
        roundedRect("fill", x, y + sh, w, h, cr)
        
        -- Body (shifted by press_shift_y)
        love.graphics.setColor(help_key_color)
        roundedRect("fill", x, y + press_shift_y, w, h, cr)
        
        -- Border
        love.graphics.setColor(1, 1, 1, 0.15)
        love.graphics.setLineWidth(math.max(1, math.floor(1 * scale)))
        roundedRect("line", x, y + press_shift_y, w, h, cr)
        
        -- Text
        love.graphics.setFont(font_help_key)
        love.graphics.setColor(help_key_text)
        local tw = font_help_key:getWidth(text)
        local th = font_help_key:getHeight()
        love.graphics.print(text, x + (w - tw) / 2, y + (h - th) / 2 + visual_offset_y + press_shift_y)
        return
    end

    local cr = math.floor(h * 0.3)

    -- Badge shadow (smooth depth effect, shrinks when depressed)
    love.graphics.setColor(0, 0, 0, 0.2)
    local sh_off = math.max(1, math.floor(2 * scale)) * shadow_shrink
    roundedRect("fill", x, y + sh_off, w, h, cr)

    -- Badge background (shifted by press_shift_y)
    love.graphics.setColor(help_key_color)
    roundedRect("fill", x, y + press_shift_y, w, h, cr)

    -- Subtle border for a clean, premium feel
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.setLineWidth(math.max(1, math.floor(1 * scale)))
    roundedRect("line", x, y + press_shift_y, w, h, cr)

    -- Badge text
    love.graphics.setFont(font_help_key)
    love.graphics.setColor(help_key_text)
    local tw = font_help_key:getWidth(text)
    local th = font_help_key:getHeight()

    -- Visual alignment corrections for arrows in ClearSans
    local offset_x, offset_y = 0, visual_offset_y + press_shift_y
    if text == "←" then
        offset_y = offset_y - math.floor(2 * scale)
        offset_x = math.floor(1 * scale)
    elseif text == "→" then
        offset_y = offset_y - math.floor(2 * scale)
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



    local badge_h = math.floor(28 * scale)
    local badge_y = hy + (hh - badge_h) / 2
    local item_gap = math.floor(8 * scale)
    local label_gap = math.floor(4 * scale)

    -- --- D-PAD section (left side) ---
    local dpad_x = bar_x + math.floor(10 * scale)
    local dpad_size = math.floor(24 * scale)
    
    -- Draw unified vector D-pad icon
    drawKeyBadge("DPAD", dpad_x, badge_y + (badge_h - dpad_size) / 2, dpad_size, dpad_size)
    dpad_x = dpad_x + dpad_size + math.floor(6 * scale)
    
    -- D-pad Label
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text)
    love.graphics.print("Move", dpad_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- Action buttons (right side) ---
    local right_x = bar_x + bar_w - math.floor(10 * scale)

    -- Determine which actions to show based on game state
    local actions = {}

    if game.state == Game.STATE_WON then
        table.insert(actions, 1, {key = "A", label = "Continue"})
        table.insert(actions, 1, {key = "X", label = "Quit"})
        table.insert(actions, 1, {key = "SELECT", label = "Restart"})
        table.insert(actions, 1, {key = "Y", label = "Switch Theme"})
        if game.mode ~= "timeattack" and game.canUndo then
            if game.mode == "plus" and game.powerups.undo > 0 then
                table.insert(actions, 1, {key = "B", label = "Undo:" .. game.powerups.undo})
            elseif game.mode ~= "plus" then
                table.insert(actions, 1, {key = "B", label = "Undo"})
            end
        end
    elseif game.state == Game.STATE_LOST then
        table.insert(actions, 1, {key = "A", label = "New Game"})
        table.insert(actions, 1, {key = "X", label = "Quit"})
        table.insert(actions, 1, {key = "Y", label = "Switch Theme"})
        if game.mode ~= "timeattack" and game.canUndo then
            if game.mode == "plus" and game.powerups.undo > 0 then
                table.insert(actions, 1, {key = "B", label = "Undo:" .. game.powerups.undo})
            elseif game.mode ~= "plus" then
                table.insert(actions, 1, {key = "B", label = "Undo"})
            end
        end
    elseif game.state == Game.STATE_PAUSED then
        table.insert(actions, 1, {key = "A", label = "Restart"})
        table.insert(actions, 1, {key = "X", label = "Quit"})
        table.insert(actions, 1, {key = "START", label = "Resume"})
        table.insert(actions, 1, {key = "Y", label = "Switch Theme"})
    elseif game.state == Game.STATE_TARGETING_BOMB or game.state == Game.STATE_TARGETING_SWAP_1 or game.state == Game.STATE_TARGETING_SWAP_2 then
        table.insert(actions, 1, {key = "A", label = "Confirm"})
        table.insert(actions, 1, {key = "B", label = "Cancel"})
    else
        if game.mode == "plus" then
            table.insert(actions, 1, {key = "START", label = "Pause"})
            table.insert(actions, 1, {key = "L1", label = "Swap:" .. game.powerups.swap})
            table.insert(actions, 1, {key = "R1", label = "Bomb:" .. game.powerups.bomb})
            table.insert(actions, 1, {key = "B", label = "Undo:" .. game.powerups.undo})
        elseif game.mode == "timeattack" then
            -- Time Attack: no undo, no powerups — keep it clean
            table.insert(actions, 1, {key = "START", label = "Pause"})
            table.insert(actions, 1, {key = "Y", label = "Switch Theme"})
        else
            table.insert(actions, 1, {key = "START", label = "Pause"})
            table.insert(actions, 1, {key = "Y", label = "Switch Theme"})
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
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
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
        love.graphics.setColor(super_tile_color[1], super_tile_color[2], super_tile_color[3], ease_t)
        
        love.graphics.push()
        love.graphics.translate(textX, textY)
        love.graphics.scale(text_scale, text_scale)
        love.graphics.print(msg, -tw/2, -th/2)
        love.graphics.pop()
    else
        win_timer = 0
        
        if game.state == Game.STATE_PAUSED then
            love.graphics.setColor(0, 0, 0, 0.65)
        elseif game.mode == "timeattack" and game.timesUp then
            -- Urgent orange overlay for Time's Up
            love.graphics.setColor(0.85, 0.35, 0.1, 0.6)
        else
            love.graphics.setColor(overlay_lose[1], overlay_lose[2], overlay_lose[3], 0.5)
        end
        roundedRect("fill", bx, by, bs, bs, layout.corner_radius * 2)

        local msg
        if game.state == Game.STATE_PAUSED then
            msg = "Paused"
        elseif game.mode == "timeattack" and game.timesUp then
            msg = "Time's Up!"
        else
            msg = "Game Over!"
        end
        love.graphics.setFont(font_message)
        if game.state == Game.STATE_PAUSED then
            love.graphics.setColor(light_text)
        elseif game.mode == "timeattack" and game.timesUp then
            love.graphics.setColor(1.0, 0.95, 0.7, 1.0)   -- warm cream text
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
    -- The Y button coordinates are tracked dynamically!
    transition_center_x = renderer.theme_button_x or (w - math.floor(90 * _G.scale))
    transition_center_y = renderer.theme_button_y or (h - math.floor(30 * _G.scale))
end

function renderer.updateTransition(dt)
    if transition_timer > 0 then
        transition_timer = math.max(0, transition_timer - dt)
    end
    if toast_timer > 0 then
        toast_timer = math.max(0, toast_timer - dt)
        if toast_timer == 0 and #toast_queue > 0 then
            local next_toast = table.remove(toast_queue, 1)
            toast_message = next_toast.msg
            toast_timer = next_toast.duration
            toast_max_duration = next_toast.duration
        end
    end
    
    if menu_anim_target_y then
        if not menu_anim_y then
            menu_anim_y = menu_anim_target_y
        end
        local lerp_factor = 1 - math.exp(-25 * dt)
        menu_anim_y = menu_anim_y + (menu_anim_target_y - menu_anim_y) * lerp_factor
        if math.abs(menu_anim_y - menu_anim_target_y) < 0.5 then
            menu_anim_y = menu_anim_target_y
        end
    end

    -- Arcade panel slide animation
    local panel_lerp = 1 - math.exp(-20 * dt)
    arcade_panel_y_offset = arcade_panel_y_offset + (arcade_panel_target - arcade_panel_y_offset) * panel_lerp
    if math.abs(arcade_panel_y_offset - arcade_panel_target) < 0.5 then
        arcade_panel_y_offset = arcade_panel_target
    end
    -- Bg alpha: fully visible (0.75) when panel is near open (offset ~0), fades as panel closes
    local h = love.graphics.getHeight()
    local raw_t = 1 - math.min(1, arcade_panel_y_offset / math.max(1, h * 0.7))
    arcade_menu_bg_alpha = raw_t * 0.75

    -- Text size flash timer
    if text_size_flash_timer > 0 then
        text_size_flash_timer = math.max(0, text_size_flash_timer - dt)
    end
end

local function drawToast()
    if toast_timer <= 0 or not toast_message then return end

    local w, h = love.graphics.getDimensions()
    love.graphics.setFont(font_message)
    
    local tw = font_message:getWidth(toast_message)
    local th = font_message:getHeight()
    local padX = 20 * _G.scale
    local padY = 10 * _G.scale
    local max_text_w = w - (padX * 2) - (40 * _G.scale)
    
    local text_w, wrapped_lines = font_message:getWrap(toast_message, max_text_w)
    local th = font_message:getHeight() * #wrapped_lines

    local boxW = text_w + padX * 2
    local boxH = th + padY * 2
    
    -- Fade in/out
    local alpha = 1.0
    if toast_timer < 0.3 then
        alpha = toast_timer / 0.3
    elseif toast_timer > toast_max_duration - 0.3 then
        alpha = (toast_max_duration - toast_timer) / 0.3
    end
    
    local y = h - (70 * _G.scale) - boxH
    -- Slide up slightly
    y = y + (1.0 - alpha) * 10 * _G.scale

    love.graphics.setColor(0.1, 0.1, 0.1, 0.85 * alpha)
    roundedRect("fill", (w - boxW) / 2, y, boxW, boxH, 12 * _G.scale)
    
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.printf(toast_message, (w - text_w) / 2, y + padY, text_w, "center")
end

-- Internal functions
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
-- Tutorial
-- ============================================================================

-- Draw a mini 4x4 board at a given position with static tile data
-- tiles is a flat table: tiles[col][row] = value (or nil/0 for empty)
local mini_fonts = {}
local mini_fonts_cell_size = 0

local function drawMiniBoard(bx, by, board_size, tiles, highlight)
    local scale = _G.scale
    local cell_gap = math.floor(board_size * 0.022)
    local cell_size = math.floor((board_size - cell_gap * 5) / 4)
    local cr = math.floor(cell_size * 0.06)

    -- Create/cache mini fonts sized for this cell size
    if cell_size ~= mini_fonts_cell_size then
        mini_fonts_cell_size = cell_size
        mini_fonts.large = love.graphics.newFont(font_path, math.max(8, math.floor(cell_size * 0.45)))
        mini_fonts.small = love.graphics.newFont(font_path, math.max(7, math.floor(cell_size * 0.35)))
        mini_fonts.tiny  = love.graphics.newFont(font_path, math.max(6, math.floor(cell_size * 0.28)))
    end

    -- Board background
    love.graphics.setColor(board_color)
    roundedRect("fill", bx, by, board_size, board_size, cr * 2)

    -- Draw cells
    for col = 1, 4 do
        for row = 1, 4 do
            local cx = bx + cell_gap + (col - 1) * (cell_size + cell_gap)
            local cy = by + cell_gap + (row - 1) * (cell_size + cell_gap)
            local val = tiles and tiles[col] and tiles[col][row] or 0

            -- Tile background
            local color = getTileColor(val)
            if _G.theme == "ascii" and val == 0 then
                love.graphics.setColor(board_color)
            else
                love.graphics.setColor(color)
            end
            roundedRect("fill", cx, cy, cell_size, cell_size, cr)

            -- Tile text
            if val > 0 then
                local textColor = getTileTextColor(val)
                love.graphics.setColor(textColor)

                local font
                if val >= 10000 then
                    font = mini_fonts.tiny
                elseif val >= 1000 then
                    font = mini_fonts.small
                else
                    font = mini_fonts.large
                end
                love.graphics.setFont(font)

                local text = tostring(val)
                local tw = font:getWidth(text)
                local th = font:getHeight()
                love.graphics.print(text, cx + (cell_size - tw) / 2, cy + (cell_size - th) / 2)
            end

            -- Highlight specific cells
            if highlight then
                for _, h in ipairs(highlight) do
                    if h.col == col and h.row == row then
                        local time = love.timer.getTime()
                        local alpha = 0.3 + 0.3 * math.sin(time * 4)
                        love.graphics.setColor(h.r or 0.3, h.g or 1, h.b or 0.3, alpha)
                        love.graphics.setLineWidth(math.max(2, math.floor(3 * scale)))
                        roundedRect("line", cx, cy, cell_size, cell_size, cr)
                    end
                end
            end
        end
    end
end

function renderer.drawTutorial(page, skip_transition)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale
    local padding = math.floor(20 * scale)

    -- Tutorial slide data
    local slides = {
        {
            title = "HOW TO PLAY",
            lines = {
                "Use the D-Pad to slide all tiles.",
                "Tiles with the same number merge",
                "into one when they collide!",
                "Goal: Create the 2048 tile!"
            },
            tiles = {
                {0, 0, 0, 2},
                {0, 0, 0, 0},
                {0, 0, 0, 2},
                {0, 0, 4, 0}
            }
        },
        {
            title = "MERGING TILES",
            lines = {
                "When two tiles of the same value",
                "touch, they merge into one!",
                "2 + 2 = 4,  4 + 4 = 8,  8 + 8 = 16",
                "Keep merging to reach 2048!"
            },
            tiles = {
                {0, 0, 2, 0},
                {0, 0, 0, 0},
                {0, 2, 0, 4},
                {2, 0, 2, 8}
            },
            highlight = {
                {col = 1, row = 4, r = 0.3, g = 1, b = 0.3},
                {col = 3, row = 4, r = 0.3, g = 1, b = 0.3}
            }
        },
        {
            title = "GAME MODES",
            lines = {
                "Classic Mode:",
                "  Unlimited undo with B button.",
                "Plus Mode:",
                "  Limited powerups: Undo, Bomb, Swap.",
                "  Earn more at tile milestones!"
            },
            tiles = {
                {0, 0, 0, 0},
                {0, 128, 0, 0},
                {16, 64, 256, 0},
                {2, 8, 32, 512}
            }
        },
        {
            title = "UNDO  [B]",
            lines = {
                "Made a mistake? Press B to undo!",
                "",
                "Classic: Unlimited undos.",
                "Plus: Limited undo powerups.",
                "Using undo counts as a powerup."
            },
            tiles = {
                {0, 0, 0, 2},
                {0, 0, 0, 2},
                {0, 0, 2, 4},
                {0, 0, 0, 16}
            }
        },
        {
            title = "SWAP  [L1]  (Plus Mode)",
            lines = {
                "Press L1 to swap any two tiles!",
                "Select first tile, then second.",
                "",
                "Use it to rearrange your board",
                "and set up big merges!"
            },
            tiles = {
                {0, 0, 0, 0},
                {0, 0, 0, 0},
                {0, 0, 4, 0},
                {2, 0, 8, 16}
            },
            highlight = {
                {col = 3, row = 3, r = 0.3, g = 0.7, b = 1},
                {col = 3, row = 4, r = 0.3, g = 0.7, b = 1}
            }
        },
        {
            title = "BOMB  [R1]  (Plus Mode)",
            lines = {
                "Press R1 to enter bomb mode.",
                "Select any tile to destroy it!",
                "",
                "Great for clearing high tiles",
                "that are blocking your merges."
            },
            tiles = {
                {0, 0, 0, 0},
                {0, 0, 0, 0},
                {0, 0, 64, 0},
                {2, 4, 8, 16}
            },
            highlight = {
                {col = 3, row = 3, r = 1, g = 0.2, b = 0.2}
            }
        },
        {
            title = "THEMES  [Y]",
            lines = {
                "Press Y anytime to change theme!",
                "",
                "Unlock new themes by earning",
                "achievements. 20 themes total!"
            },
            tiles = {
                {2, 0, 0, 0},
                {4, 0, 0, 0},
                {8, 16, 0, 0},
                {32, 64, 128, 256}
            }
        },
        {
            title = "STRATEGY TIPS",
            lines = {
                "Keep your highest tile in a corner.",
                "Build a chain along one edge.",
                "Never push your big tile away!",
                "",
                "Plan ahead and don't fill the board."
            },
            tiles = {
                {0, 0, 0, 0},
                {0, 0, 0, 0},
                {4, 8, 16, 32},
                {256, 128, 64, 2048}
            },
            highlight = {
                {col = 4, row = 4, r = 1, g = 0.85, b = 0.2}
            }
        }
    }

    local total_pages = #slides
    local slide = slides[page] or slides[1]

    -- Header: title
    love.graphics.setFont(font_title)
    love.graphics.setColor(ui_text)
    local title_text = slide.title
    local title_w = font_title:getWidth(title_text)
    love.graphics.print(title_text, (w - title_w) / 2, padding)

    -- Page indicator (dots)
    local dot_r = math.floor(4 * scale)
    local dot_gap = math.floor(14 * scale)
    local dots_w = total_pages * (dot_r * 2 + dot_gap) - dot_gap
    local dots_x = (w - dots_w) / 2
    local dots_y = padding + font_title:getHeight() + math.floor(8 * scale)

    for i = 1, total_pages do
        local dx = dots_x + (i - 1) * (dot_r * 2 + dot_gap) + dot_r
        if i == page then
            love.graphics.setColor(help_key_color)
            love.graphics.circle("fill", dx, dots_y, dot_r)
        else
            love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.3)
            love.graphics.circle("fill", dx, dots_y, dot_r)
        end
    end

    -- Message box area
    local msg_y = dots_y + dot_r * 2 + math.floor(12 * scale)
    local max_content_w = math.min(w - padding * 2, math.floor(480 * scale))
    local msg_pad = math.floor(15 * scale)

    love.graphics.setFont(font_help_label)
    local max_line_w = 0
    for _, line in ipairs(slide.lines) do
        local lw = font_help_label:getWidth(line)
        if lw > max_line_w then max_line_w = lw end
    end
    local msg_box_w = math.min(max_content_w, max_line_w + msg_pad * 2)
    local msg_box_x = math.floor((w - msg_box_w) / 2)

    -- Calculate message box height from lines
    local line_h = font_help_label:getHeight()
    local num_lines = #slide.lines
    local msg_box_h = msg_pad * 2 + num_lines * (line_h + math.floor(3 * scale))

    -- Message box background
    love.graphics.setColor(board_color[1], board_color[2], board_color[3], 0.85)
    roundedRect("fill", msg_box_x, msg_y, msg_box_w, msg_box_h, math.floor(10 * scale))

    -- Message box border
    love.graphics.setColor(help_key_color[1], help_key_color[2], help_key_color[3], 0.5)
    love.graphics.setLineWidth(math.max(1, math.floor(1.5 * scale)))
    roundedRect("line", msg_box_x, msg_y, msg_box_w, msg_box_h, math.floor(10 * scale))

    -- Message text
    love.graphics.setColor(ui_text)
    local text_y = msg_y + msg_pad
    for _, line in ipairs(slide.lines) do
        love.graphics.print(line, msg_box_x + msg_pad, text_y)
        text_y = text_y + line_h + math.floor(3 * scale)
    end

    -- Mini board
    local board_top = msg_y + msg_box_h + math.floor(12 * scale)
    local footer_h = math.floor(55 * scale)
    local available_h = h - board_top - footer_h - math.floor(10 * scale)
    local available_w = max_content_w
    local board_size = math.min(available_w, available_h)

    -- Limit the mini-board size to keep it perfectly symmetrical and consistent
    local max_board_size = math.floor(204 * scale)
    if board_size > max_board_size then
        board_size = max_board_size
    end

    -- Snap board_size so cells fit perfectly with no floating point gaps
    local cell_gap = math.floor(board_size * 0.022)
    local cell_size = math.floor((board_size - cell_gap * 5) / 4)
    board_size = cell_size * 4 + cell_gap * 5

    -- Center the board vertically in the remaining space
    local extra_y = (available_h - board_size) / 2
    local board_y = board_top + math.floor(extra_y)
    local board_x = math.floor((w - board_size) / 2)

    drawMiniBoard(board_x, board_y, board_size, slide.tiles, slide.highlight)

    -- Footer: navigation hints
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local item_gap = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- Build action list
    local actions = {}
    if page < total_pages then
        table.insert(actions, 1, {key = "A", label = "Next"})
    else
        table.insert(actions, 1, {key = "A", label = "Exit"})
    end
    table.insert(actions, 1, {key = "Y", label = "Switch Theme"})
    if page > 1 then
        table.insert(actions, 1, {key = "B", label = "Back"})
    else
        table.insert(actions, 1, {key = "B", label = "Exit"})
    end

    -- Page counter on the left
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.6)
    local page_text = page .. "/" .. total_pages
    love.graphics.print(page_text, padding, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- DPAD on the left
    local dpad_x = padding + math.floor(45 * scale)
    local dpad_size = math.floor(24 * scale)
    drawKeyBadge("DPAD", dpad_x, badge_y + (badge_h - dpad_size) / 2, dpad_size, dpad_size)
    dpad_x = dpad_x + dpad_size + math.floor(6 * scale)
    love.graphics.setColor(ui_text)
    love.graphics.print("Page", dpad_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- Draw actions right-to-left
    local right_x = w - math.floor(10 * scale)
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
    end

    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end

    drawToast()
end

-- ============================================================================
-- Main Menu
-- ============================================================================
function renderer.drawMainMenu(selection, skip_transition)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale

    local text_size_lbl = "Text Size: " .. (_G.text_size == "large" and "Large" or "Normal")
    local theme_name = _G.theme:gsub("^%l", string.upper)
    local options = {"Play Classic Mode", "Play Plus Mode", "Select Theme: " .. theme_name, "Achievements", "Tutorial", text_size_lbl, "About", "Quit"}
    if _G.cheats_unlocked then
        table.insert(options, 6, "Cheats")
    end
    love.graphics.setFont(font_message)
    local gap = (_G.text_size == "large" and 34 or 31) * scale
    local menu_h = (#options - 1) * gap + font_message:getHeight()
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    
    -- Dynamically space a beautiful theme-colored 2048 tile logo header
    local header_h = math.floor((_G.text_size == "large" and 80 or 95) * scale)
    
    local total_h = header_h + math.floor(15 * scale) + menu_h
    local available_h = badge_y - math.floor(10 * scale)
    local start_y = math.max(math.floor(10 * scale), math.floor(math.floor(10 * scale) + (available_h - total_h) / 2))
    
    -- Draw beautifully stylized header
    local tile_size = header_h - math.floor((_G.text_size == "large" and 15 or 20) * scale)
    if tile_size > 0 then
        local tile_x = (w - tile_size) / 2
        local tile_y = start_y + (header_h - tile_size) / 2
        
        -- Draw tile background (using 2048 tile color from active theme!)
        love.graphics.setColor(getTileColor(2048))
        roundedRect("fill", tile_x, tile_y, tile_size, tile_size, tile_size * 0.12)
        
        -- Draw "2048" text
        love.graphics.setColor(getTileTextColor(2048))
        local f_logo = font_tile_small
        if tile_size < math.floor(50 * scale) then
            f_logo = font_tile_tiny
        end
        love.graphics.setFont(f_logo)
        local tw = f_logo:getWidth("2048")
        local th = f_logo:getHeight()
        
        -- Safe dynamic scaling for logo text inside the tile
        local logo_s = 1.0
        local max_w = tile_size - math.floor(8 * scale)
        if tw > max_w then
            logo_s = max_w / tw
        end
        love.graphics.print("2048", tile_x + (tile_size - tw * logo_s) / 2, tile_y + (tile_size - th * logo_s) / 2, 0, logo_s, logo_s)
    end
    
    -- Menu options start position
    local menu_start_y = start_y + header_h + math.floor(15 * scale)

    local max_ow = 0
    for _, opt in ipairs(options) do
        local display_opt = opt
        if opt:find("^Select Theme:") then
            display_opt = "Select Theme: Cyberpunk"
        end
        local ow = font_message:getWidth(display_opt)
        if ow > max_ow then
            max_ow = ow
        end
    end
    local block_x = (w - max_ow) / 2

    local target_oy = menu_start_y + (selection - 1) * gap
    menu_anim_target_y = target_oy
    if not menu_anim_y then menu_anim_y = target_oy end

    love.graphics.setColor(help_key_color)
    roundedRect("fill", block_x - 20 * scale, menu_anim_y - 2 * scale, max_ow + 40 * scale, font_message:getHeight() + 4 * scale, 8 * scale)

    for i, opt in ipairs(options) do
        local oy = menu_start_y + (i - 1) * gap
        if i == selection then
            love.graphics.setColor(help_key_text)
        else
            love.graphics.setColor(ui_text)
        end
        love.graphics.setFont(font_message)
        love.graphics.print(opt, block_x, oy)
    end

    -- Footer bar for Main Menu
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local item_gap = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- DPAD on the left
    local dpad_x = math.floor(20 * scale)
    local dpad_size = math.floor(24 * scale)
    drawKeyBadge("DPAD", dpad_x, badge_y + (badge_h - dpad_size) / 2, dpad_size, dpad_size)
    dpad_x = dpad_x + dpad_size + math.floor(6 * scale)
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text)
    love.graphics.print("Navigate", dpad_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- Right side actions: A (Select), X (Arcade), Y (Theme)
    local right_x = w - math.floor(20 * scale)
    local actions = {
        {key = "A", label = "Select"},
        {key = "X", label = "Arcade"},
        {key = "Y", label = "Switch Theme"}
    }
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
    end

    -- Text size toggle flash: brief full-screen white flash, fades out cleanly
    if text_size_flash_timer > 0 then
        local p = text_size_flash_timer / TEXT_SIZE_FLASH_DURATION  -- 1→0
        local alpha = p * p * 0.45  -- ease-out, max ~45% white overlay
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1, 1)
    end

    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end
    
    drawToast()
end

-- ============================================================================
-- Arcade Menu
-- ============================================================================
-- Vector helper to draw an animated stopwatch
local function drawStopwatch(cx, cy, scale, is_selected)
    local t = love.timer.getTime()
    local r = 18 * scale
    
    love.graphics.push("all")
    love.graphics.setLineWidth(math.floor(2 * scale))
    
    if is_selected then
        love.graphics.setColor(0.0, 0.85, 0.8, 1.0)
    else
        love.graphics.setColor(0.45, 0.5, 0.58, 0.7)
    end
    
    -- Outer circle
    love.graphics.circle("line", cx, cy, r)
    
    -- Top crown
    love.graphics.rectangle("fill", cx - math.floor(3 * scale), cy - r - math.floor(4 * scale), math.floor(6 * scale), math.floor(3 * scale))
    -- Left button (rotated)
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(-math.pi / 4)
    love.graphics.rectangle("fill", -math.floor(2 * scale), -r - math.floor(3 * scale), math.floor(4 * scale), math.floor(2 * scale))
    love.graphics.pop()
    
    -- Center pin
    love.graphics.circle("fill", cx, cy, math.floor(3 * scale))
    
    -- Clock hands
    -- Minute hand (pointing slightly offset)
    love.graphics.setLineWidth(math.floor(1.5 * scale))
    love.graphics.line(cx, cy, cx, cy - r + math.floor(6 * scale))
    
    -- Second hand (rotates full circle every 8 seconds, modulo prevents overflow precision issues)
    local angle = -math.pi / 2 + (t % 8) * (2 * math.pi / 8)
    local hand_len = r - math.floor(4 * scale)
    love.graphics.setLineWidth(math.floor(1 * scale))
    if is_selected then
        love.graphics.setColor(0.95, 0.15, 0.45, 0.95) -- Active pink-red ticking hand
    else
        love.graphics.setColor(0.45, 0.5, 0.58, 0.6)
    end
    love.graphics.line(cx, cy, cx + hand_len * math.cos(angle), cy + hand_len * math.sin(angle))
    
    love.graphics.pop()
end

-- Vector helper to draw a modern lock
local function drawLock(cx, cy, scale)
    local w = math.floor(24 * scale)
    local h = math.floor(18 * scale)
    local r = math.floor(7 * scale)
    
    love.graphics.push("all")
    love.graphics.setLineWidth(math.floor(2 * scale))
    love.graphics.setColor(0.35, 0.38, 0.45, 0.7)
    
    -- Lock shackle (top arch)
    love.graphics.arc("line", "open", cx, cy - h/2 + math.floor(3 * scale), r, math.pi, 2 * math.pi)
    love.graphics.line(cx - r, cy - h/2 + math.floor(3 * scale), cx - r, cy - h/2 + math.floor(6 * scale))
    love.graphics.line(cx + r, cy - h/2 + math.floor(3 * scale), cx + r, cy - h/2 + math.floor(6 * scale))
    
    -- Lock body
    love.graphics.rectangle("fill", cx - w/2, cy - h/2 + math.floor(5 * scale), w, h, math.floor(3 * scale))
    
    -- Keyhole
    love.graphics.setColor(0.08, 0.08, 0.12, 0.9)
    love.graphics.circle("fill", cx, cy + math.floor(2 * scale), math.floor(3 * scale))
    love.graphics.rectangle("fill", cx - math.floor(1 * scale), cy + math.floor(2 * scale), math.floor(2 * scale), math.floor(4 * scale))
    
    love.graphics.pop()
end

function renderer.drawArcadeMenu(selection, skip_transition, current_menu_selection)
    local w, h = love.graphics.getDimensions()
    local scale = _G.scale

    -- First draw the main menu underneath (dimmed) using the current menu selection to prevent header jump
    renderer.drawMainMenu(current_menu_selection or 1, true)

    -- Dim overlay
    if arcade_menu_bg_alpha > 0 then
        love.graphics.setColor(0, 0, 0, arcade_menu_bg_alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end

    -- Panel geometry
    local panel_pad_x = math.floor(24 * scale)
    local panel_pad_y = math.floor(16 * scale)
    local card_gap    = math.floor(12 * scale)
    local card_h      = math.floor(96 * scale)
    local num_cards   = 2   -- Time Attack + Coming Soon
    local header_h    = math.floor(74 * scale)
    local footer_h    = math.floor(44 * scale)
    local panel_h     = header_h + panel_pad_y + num_cards * card_h + (num_cards - 1) * card_gap + panel_pad_y + footer_h

    local panel_x = math.floor(panel_pad_x)
    local panel_w = w - panel_pad_x * 2

    -- Animate sliding up from bottom
    local raw_offset = arcade_panel_y_offset
    if raw_offset > panel_h then raw_offset = panel_h end
    local panel_y_base = h - panel_h
    local panel_y = panel_y_base + raw_offset

    -- Ambient floating light blobs inside the panel (aurora theme)
    local t = love.timer.getTime()
    local alpha_mult = 1 - raw_offset / panel_h

    -- Glassy panel background
    love.graphics.setColor(0.04, 0.04, 0.08, 0.95)
    roundedRect("fill", panel_x, panel_y, panel_w, panel_h, math.floor(18 * scale))

    -- Draw sliding/waving light blobs (aurora effect)
    love.graphics.push("all")
    love.graphics.setScissor(panel_x, panel_y, panel_w, panel_h)
    
    -- Blob 1: Aurora Teal
    local b1x = panel_x + panel_w * 0.25 + math.sin(t * 0.6) * 50 * scale
    local b1y = panel_y + panel_h * 0.35 + math.cos(t * 0.5) * 30 * scale
    love.graphics.setColor(0.0, 0.78, 0.73, 0.12 * alpha_mult)
    love.graphics.circle("fill", b1x, b1y, 110 * scale)

    -- Blob 2: Aurora Purple
    local b2x = panel_x + panel_w * 0.75 + math.cos(t * 0.7) * 60 * scale
    local b2y = panel_y + panel_h * 0.45 + math.sin(t * 0.8) * 25 * scale
    love.graphics.setColor(0.55, 0.20, 0.90, 0.10 * alpha_mult)
    love.graphics.circle("fill", b2x, b2y, 120 * scale)

    -- Blob 3: Aurora Magenta/Pink
    local b3x = panel_x + panel_w * 0.5 + math.sin(t * 0.4) * 70 * scale
    local b3y = panel_y + panel_h * 0.7 + math.sin(t * 0.7) * 35 * scale
    love.graphics.setColor(0.90, 0.05, 0.55, 0.08 * alpha_mult)
    love.graphics.circle("fill", b3x, b3y, 90 * scale)

    love.graphics.setScissor()
    love.graphics.pop()

    -- Glassy panel border highlight
    love.graphics.setColor(1, 1, 1, 0.08)
    love.graphics.setLineWidth(math.floor(1.5 * scale))
    roundedRect("line", panel_x, panel_y, panel_w, panel_h, math.floor(18 * scale))

    -- ── Header ──────────────────────────────────────────────────────────────
    local header_y = panel_y + panel_pad_y
    love.graphics.setFont(font_title) -- Use font_title (size 36) to prevent overlap!
    local title = "Arcade Modes"
    local tw = font_title:getWidth(title)
    
    -- Draw drop shadow for text
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.print(title, panel_x + (panel_w - tw) / 2 + 1, header_y + 1)
    
    -- Draw main title text in glowing Teal
    love.graphics.setColor(0.0, 0.9, 0.85, 1.0)
    love.graphics.print(title, panel_x + (panel_w - tw) / 2, header_y)

    -- Neon glow separator line
    love.graphics.setColor(0.0, 0.78, 0.73, 0.15)
    love.graphics.setLineWidth(math.floor(3 * scale))
    love.graphics.line(
        panel_x + math.floor(20 * scale),
        header_y + font_title:getHeight() + math.floor(8 * scale),
        panel_x + panel_w - math.floor(20 * scale),
        header_y + font_title:getHeight() + math.floor(8 * scale)
    )
    love.graphics.setColor(0.0, 0.78, 0.73, 0.6)
    love.graphics.setLineWidth(math.floor(1 * scale))
    love.graphics.line(
        panel_x + math.floor(30 * scale),
        header_y + font_title:getHeight() + math.floor(8 * scale),
        panel_x + panel_w - math.floor(30 * scale),
        header_y + font_title:getHeight() + math.floor(8 * scale)
    )

    -- ── Mode cards ──────────────────────────────────────────────────────────
    local cards_top = header_y + header_h
    local card_x    = panel_x + math.floor(16 * scale)
    local card_w    = panel_w - math.floor(32 * scale)
    local card_cr   = math.floor(12 * scale)

    local modes = {
        {
            name        = "Time Attack",
            desc        = "Score as high as possible before time runs out!",
            icon        = "stopwatch",
            bestScore   = save.loadHighScore("timeattack"),
            available   = true,
            accentR = 0.0, accentG = 0.85, accentB = 0.8,
        },
        {
            name        = "Coming Soon...",
            desc        = "More exciting modes are on their way.",
            icon        = "lock",
            available   = false,
            accentR = 0.4, accentG = 0.4, accentB = 0.5,
        }
    }

    for i, mode in ipairs(modes) do
        local cy = cards_top + (i - 1) * (card_h + card_gap)
        local is_sel = (i == selection) and mode.available

        -- Stagger pop-in
        local slide_t = math.max(0, 1 - raw_offset / math.max(1, panel_h * 0.5) - (i - 1) * 0.05)
        local card_scale = 0.92 + slide_t * 0.08

        love.graphics.push()
        love.graphics.translate(card_x + card_w / 2, cy + card_h / 2)
        love.graphics.scale(card_scale, card_scale)
        love.graphics.translate(-(card_x + card_w / 2), -(cy + card_h / 2))

        if is_sel then
            -- Rich dark glassy teal backdrop for selected
            love.graphics.setColor(0.04, 0.12, 0.16, 0.85)
            roundedRect("fill", card_x, cy, card_w, card_h, card_cr)
            
            -- Glowing pulsing border
            local pulse = 0.65 + 0.25 * math.sin(t * 5)
            love.graphics.setLineWidth(math.floor(2 * scale))
            love.graphics.setColor(mode.accentR, mode.accentG, mode.accentB, pulse)
            roundedRect("line", card_x, cy, card_w, card_h, card_cr)
            
            -- Accent side bar
            love.graphics.setColor(mode.accentR, mode.accentG, mode.accentB, 0.9)
            local bar_h = math.floor(36 * scale)
            local bar_w = math.floor(4 * scale)
            local bar_y = cy + (card_h - bar_h) / 2
            roundedRect("fill", card_x + math.floor(6 * scale), bar_y, bar_w, bar_h, math.floor(2 * scale))
        elseif mode.available then
            -- Elegant dark grey glassy unselected
            love.graphics.setColor(0.08, 0.08, 0.12, 0.6)
            roundedRect("fill", card_x, cy, card_w, card_h, card_cr)
            love.graphics.setColor(0.2, 0.22, 0.28, 0.35)
            love.graphics.setLineWidth(math.floor(1 * scale))
            roundedRect("line", card_x, cy, card_w, card_h, card_cr)
        else
            -- Locked card styling
            love.graphics.setColor(0.05, 0.05, 0.08, 0.5)
            roundedRect("fill", card_x, cy, card_w, card_h, card_cr)
            love.graphics.setColor(0.15, 0.16, 0.20, 0.2)
            love.graphics.setLineWidth(math.floor(1 * scale))
            roundedRect("line", card_x, cy, card_w, card_h, card_cr)
        end

        -- Draw vector icon on the left
        local icon_cx = card_x + math.floor(36 * scale)
        local icon_cy = cy + card_h / 2
        if mode.icon == "stopwatch" then
            drawStopwatch(icon_cx, icon_cy, scale, is_sel)
        elseif mode.icon == "lock" then
            drawLock(icon_cx, icon_cy, scale)
        end

        -- Mode name
        local text_x = card_x + math.floor(68 * scale)
        local name_y = cy + math.floor(14 * scale)
        love.graphics.setFont(font_message)
        if is_sel then
            love.graphics.setColor(mode.accentR, mode.accentG, mode.accentB, 1.0)
        elseif mode.available then
            love.graphics.setColor(0.9, 0.92, 0.95, 1.0)
        else
            love.graphics.setColor(0.4, 0.42, 0.48, 0.7)
        end
        love.graphics.print(mode.name, text_x, name_y)

        -- Description
        local desc_y = name_y + font_message:getHeight() + math.floor(4 * scale)
        love.graphics.setFont(font_help_label)
        if mode.available then
            love.graphics.setColor(0.65, 0.68, 0.75, 1.0)
        else
            love.graphics.setColor(0.3, 0.32, 0.38, 0.7)
        end
        love.graphics.printf(mode.desc, text_x, desc_y, card_w - math.floor(68 * scale) - math.floor(110 * scale), "left")

        -- Best score (drawn as a beautiful badge)
        if mode.available and mode.bestScore and mode.bestScore > 0 then
            love.graphics.setFont(font_help_label)
            local best_label = "BEST"
            local best_val   = tostring(mode.bestScore)
            local blw = font_help_label:getWidth(best_label)
            local bvw = font_help_label:getWidth(best_val)
            
            local badge_w = math.max(math.floor(70 * scale), math.max(blw, bvw) + math.floor(18 * scale))
            local badge_h = math.floor(52 * scale) -- Larger/taller badge box
            local br_x = card_x + card_w - math.floor(18 * scale)
            local bx = br_x - badge_w
            local by = cy + (card_h - badge_h) / 2
            
            -- Glassy badge back
            if is_sel then
                love.graphics.setColor(mode.accentR * 0.15, mode.accentG * 0.15, mode.accentB * 0.15, 0.4)
                roundedRect("fill", bx, by, badge_w, badge_h, math.floor(8 * scale))
                love.graphics.setColor(mode.accentR, mode.accentG, mode.accentB, 0.45)
                roundedRect("line", bx, by, badge_w, badge_h, math.floor(8 * scale))
            else
                love.graphics.setColor(0.12, 0.12, 0.18, 0.4)
                roundedRect("fill", bx, by, badge_w, badge_h, math.floor(8 * scale))
                love.graphics.setColor(0.3, 0.32, 0.38, 0.4)
                roundedRect("line", bx, by, badge_w, badge_h, math.floor(8 * scale))
            end
            
            -- Dynamic vertical centering of text inside the badge
            local lbl_h = font_help_label:getHeight()
            local val_h = font_help_label:getHeight()
            local badge_spacing = math.floor(2 * scale)
            local badge_text_h = lbl_h + val_h + badge_spacing
            local badge_top_pad = math.floor((badge_h - badge_text_h) / 2)
            
            local bl_y = by + badge_top_pad
            local bv_y = by + badge_top_pad + lbl_h + badge_spacing
            
            -- Badge text
            love.graphics.setColor(0.55, 0.58, 0.65, 0.8)
            love.graphics.print(best_label, bx + (badge_w - blw) / 2, bl_y)
            if is_sel then
                love.graphics.setColor(mode.accentR, mode.accentG, mode.accentB, 1.0)
            else
                love.graphics.setColor(0.85, 0.85, 0.9, 1.0)
            end
            love.graphics.print(best_val, bx + (badge_w - bvw) / 2, bv_y)
        end

        love.graphics.pop()
    end

    -- ── Footer ──────────────────────────────────────────────────────────────
    local footer_y = cards_top + num_cards * card_h + (num_cards - 1) * card_gap + math.floor(8 * scale)
    local badge_h   = math.floor(28 * scale)
    local badge_y   = footer_y + (footer_h - badge_h) / 2
    local item_gap  = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- Right side: A (Play) + B/X (Back)
    local right_x = panel_x + panel_w - math.floor(12 * scale)
    local footer_actions = {
        {key = "A", label = "Play"},
        {key = "B", label = "Back"},
    }
    for _, action in ipairs(footer_actions) do
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(0.7, 0.75, 0.8, 1.0)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)
        right_x = right_x - item_gap
    end

    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end

    drawToast()
end

-- ============================================================================
-- Cheats Menu
-- ============================================================================
function renderer.drawCheatsMenu(selection, skip_transition)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale

    love.graphics.setFont(font_title)
    love.graphics.setColor(ui_text)
    local title = "Cheats Menu"
    local tw = font_title:getWidth(title)
    local title_y = math.floor(8 * scale)
    love.graphics.print(title, (w - tw) / 2, title_y)

    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.7)
    local subtitle = "Cheats will reset when you quit the game"
    local sw = font_help_label:getWidth(subtitle)
    local subtitle_y = title_y + font_title:getHeight() - math.floor(2 * scale)
    love.graphics.print(subtitle, (w - sw) / 2, subtitle_y)

    local options = {
        "Unlock All Themes",
        "Max Powerups: " .. (_G.cheat_max_powerups and "ON" or "OFF"),
        "Start with 1024 (Classic Mode): " .. (_G.cheat_start_1024_classic and "ON" or "OFF"),
        "Start with 1024 (Plus Mode): " .. (_G.cheat_start_1024_plus and "ON" or "OFF"),
        "Debug: Test All Tiles: " .. (_G.cheat_test_tiles and "ON" or "OFF"),
        "Debug: Two 1024 Tiles: " .. (_G.cheat_two_1024s and "ON" or "OFF"),
        "Debug: Fill 2,4,8,16,32...: " .. (_G.cheat_fill_24816 and "ON" or "OFF"),
        "Lock Cheats",
        "Back"
    }
    love.graphics.setFont(font_message)
    local gap = (_G.text_size == "large" and 37 or 32) * scale
    local menu_h = (#options - 1) * gap + font_message:getHeight()
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local subtitle_h = font_help_label:getHeight()
    local available_h = badge_y - subtitle_y - subtitle_h
    local start_y = math.floor(subtitle_y + subtitle_h + (available_h - menu_h) / 2)

    local max_ow = 0
    for _, opt in ipairs(options) do
        local ow = font_message:getWidth(opt)
        if ow > max_ow then
            max_ow = ow
        end
    end
    local block_x = (w - max_ow) / 2

    local target_oy = start_y + (selection - 1) * gap
    menu_anim_target_y = target_oy
    if not menu_anim_y then menu_anim_y = target_oy end

    love.graphics.setColor(help_key_color)
    roundedRect("fill", block_x - 20 * scale, menu_anim_y - 2 * scale, max_ow + 40 * scale, font_message:getHeight() + 4 * scale, 8 * scale)

    for i, opt in ipairs(options) do
        local oy = start_y + (i - 1) * gap
        if i == selection then
            love.graphics.setColor(help_key_text)
        else
            love.graphics.setColor(ui_text)
        end
        love.graphics.print(opt, block_x, oy)
    end

    -- Footer bar for Cheats Menu
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local item_gap = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- DPAD on the left
    local dpad_x = math.floor(20 * scale)
    local dpad_size = math.floor(24 * scale)
    drawKeyBadge("DPAD", dpad_x, badge_y + (badge_h - dpad_size) / 2, dpad_size, dpad_size)
    dpad_x = dpad_x + dpad_size + math.floor(6 * scale)
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text)
    love.graphics.print("Navigate", dpad_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- Right side actions: B (Back), A (Toggle), Y (Theme)
    local right_x = w - math.floor(20 * scale)
    local actions = {
        {key = "B", label = "Back"},
        {key = "A", label = "Toggle"},
        {key = "Y", label = "Switch Theme"}
    }
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
    end
    
    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end
    
    drawToast()
end


-- ============================================================================
-- Theme Selection / Preview Screen
-- ============================================================================
function renderer.drawThemeSelect(skip_transition)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale

    -- Title: "Select Theme"
    love.graphics.setFont(font_cheats_title)
    love.graphics.setColor(ui_text)
    local title = "Select Theme"
    local tw = font_cheats_title:getWidth(title)
    local title_y = h * 0.04
    love.graphics.print(title, (w - tw) / 2, title_y)

    -- Subtitle showing Theme Name (index/total)
    local theme_disp = _G.theme:gsub("^%l", string.upper)
    local current_idx = 1
    for i, t in ipairs(_G.unlocked_themes) do
        if t == _G.theme then current_idx = i break end
    end
    local subtitle = theme_disp .. " (" .. current_idx .. "/" .. #_G.unlocked_themes .. ")"

    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.7)
    local sw = font_help_label:getWidth(subtitle)
    local subtitle_y = title_y + font_cheats_title:getHeight() + math.floor(5 * scale)
    love.graphics.print(subtitle, (w - sw) / 2, subtitle_y)

    -- Draw preview swatches (2x2 palette card) and horizontal color strip
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local board_top = subtitle_y + font_help_label:getHeight() + math.floor(10 * scale)
    local board_bottom = badge_y - math.floor(10 * scale)
    local avail_h = board_bottom - board_top
    
    -- Define palette strip height and padding
    local strip_h = math.floor(14 * scale)
    local pad_x = math.floor(6 * scale)
    local pad_y = math.floor(5 * scale)
    local panel_h = strip_h + pad_y * 2
    local strip_gap = math.floor(12 * scale)
    local avail_h_for_board = avail_h - (panel_h + strip_gap)
    
    -- Keep the palette card as a beautifully sized square/rect
    local board_size = math.min(math.floor(190 * scale), avail_h_for_board)
    local board_x = math.floor((w - board_size) / 2)
    
    -- Calculate vertical positions so everything is perfectly centered as a single block!
    local total_block_h = board_size + strip_gap + panel_h
    local block_y = board_top + (avail_h - total_block_h) / 2
    
    local board_y = block_y
    local strip_y = board_y + board_size + strip_gap
    local strip_x = board_x

    local cell_gap = math.floor(board_size * 0.05)
    local cell_size = math.floor((board_size - cell_gap * 3) / 2)
    local cr = math.floor(cell_size * 0.06)
    
    -- Draw board background (representing theme board_color)
    love.graphics.setColor(board_color)
    roundedRect("fill", board_x, board_y, board_size, board_size, cr * 2)

    -- Swatches to display
    local swatches = {
        { color = bg_color, label = "BG", textColor = ui_text, hasOutline = true },
        { color = board_color, label = "BOARD", textColor = ui_text, hasOutline = true },
        { color = tile_colors[2], label = "2", textColor = getTileTextColor(2) },
        { color = tile_colors[2048] or tile_colors[2], label = "2048", textColor = getTileTextColor(2048) }
    }

    local positions = {
        { x = board_x + cell_gap, y = board_y + cell_gap },
        { x = board_x + cell_gap * 2 + cell_size, y = board_y + cell_gap },
        { x = board_x + cell_gap, y = board_y + cell_gap * 2 + cell_size },
        { x = board_x + cell_gap * 2 + cell_size, y = board_y + cell_gap * 2 + cell_size }
    }

    -- Set up font for swatch labels
    local font_swatch = love.graphics.newFont(font_path, math.max(10, math.floor(cell_size * 0.20)))

    for i, sw in ipairs(swatches) do
        local sx = positions[i].x
        local sy = positions[i].y

        -- Draw swatch color block
        love.graphics.setColor(sw.color)
        roundedRect("fill", sx, sy, cell_size, cell_size, cr)

        if sw.hasOutline then
            love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.2)
            love.graphics.setLineWidth(math.floor(1 * scale))
            roundedRect("line", sx, sy, cell_size, cell_size, cr)
        end

        -- Draw centered swatch label text
        love.graphics.setFont(font_swatch)
        love.graphics.setColor(sw.textColor)
        local th = font_swatch:getHeight()
        love.graphics.printf(sw.label, sx, sy + (cell_size - th) / 2, cell_size, "center")
    end

    -- Draw horizontal color palette strip representing all tile colors with a glassy background card
    -- Glassy dark backing card (0, 0, 0, 0.4) that provides gorgeous contrast against theme backgrounds
    love.graphics.setColor(0, 0, 0, 0.4)
    roundedRect("fill", strip_x, strip_y, board_size, panel_h, cr)
    -- Glassy light outline (ui_text with 0.15 opacity) for a clean, professional frosted look
    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.15)
    love.graphics.setLineWidth(math.floor(1 * scale))
    roundedRect("line", strip_x, strip_y, board_size, panel_h, cr)

    -- Draw the 11 tile color blocks inside the glassy capsule
    local tile_values = {2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048}
    local bgap = math.max(1, math.floor(2 * scale))
    local avail_w = board_size - pad_x * 2
    local block_w = (avail_w - bgap * 10) / 11
    local bcr = math.max(2, math.floor(block_w * 0.20))
    
    for idx, val in ipairs(tile_values) do
        local color = tile_colors[val] or tile_colors[2]
        love.graphics.setColor(color)
        local bx = strip_x + pad_x + (idx - 1) * (block_w + bgap)
        roundedRect("fill", bx, strip_y + pad_y, block_w, strip_h, bcr)
    end

    -- Draw standardized help footer
    local item_gap = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- Right side actions: B (Cancel), A (Select), Y (Switch Theme)
    local right_x = w - math.floor(20 * scale)
    local actions = {
        {key = "B", label = "Cancel"},
        {key = "A", label = "Select"},
        {key = "Y", label = "Switch Theme"}
    }
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
    end

    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end

    drawToast()
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

    drawToast()
end

-- ============================================================================
-- Achievements Screen
-- ============================================================================
function renderer.drawAchievements(scroll, skip_transition)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale
    local padding = math.floor(20 * scale)

    -- Header
    love.graphics.setFont(font_title)
    love.graphics.setColor(ui_text)
    local title = "Achievements"
    love.graphics.print(title, padding, padding)

    -- Achievement definitions
    local achievementsList = {
        { id = "ach_first_game", name = "First Steps", desc = "Play your first game", reward = "Ocean Theme" },
        { id = "ach_score_1k", name = "Getting Started", desc = "Reach 1,000 points", reward = "Forest Theme" },
        { id = "ach_score_2k", name = "Gaining Momentum", desc = "Reach 2,000 points", reward = "Volcano Theme" },
        { id = "ach_score_5k", name = "Rising Star", desc = "Reach 5,000 points", reward = "Sunset Theme" },
        { id = "ach_score_7k", name = "High Scorer", desc = "Reach 7,500 points", reward = "Abyss Theme" },
        { id = "ach_merge_512", name = "Half Way There", desc = "Create a 512 tile", reward = "Candy Theme" },
        { id = "ach_merge_1024", name = "Almost There", desc = "Create a 1024 tile", reward = "Midnight Theme" },
        { id = "ach_2048", name = "2048 Master", desc = "Create a 2048 tile in Classic Mode", reward = "OLED Dark Theme" },
        { id = "ach_score_10k", name = "High Roller", desc = "Reach 10,000 points", reward = "Neon Theme" },
        { id = "ach_first_bomb", name = "Boom!", desc = "Use your first bomb in Plus Mode", reward = "Eclipse Theme" },
        { id = "ach_demolition", name = "Demolition Expert", desc = "Use 10 bombs in Plus Mode", reward = "Retro Theme" },
        { id = "ach_untouchable", name = "Untouchable", desc = "Create a 1024 tile without using undos or powerups", reward = "Peach Theme" },
        { id = "ach_2048_plus", name = "Plus Mode Master", desc = "Create a 2048 tile in Plus Mode", reward = "Cyberpunk Theme" },
        { id = "ach_4096", name = "The One", desc = "Create a 4096 tile", reward = "Matrix Theme" },
        { id = "ach_score_25k", name = "Aesthetic", desc = "Reach 25,000 points", reward = "Vaporwave Theme" },
        { id = "ach_score_50k", name = "Vampire Lord", desc = "Reach 50,000 points", reward = "Dracula Theme" },
        { id = "ach_score_100k", name = "Midas Touch", desc = "Reach 100,000 points", reward = "Gold Theme" },
        { id = "ach_untouchable_2048", name = "Zen Master", desc = "Create a 2048 tile without using undos or powerups", reward = "Matcha Theme" },
        { id = "ach_timeattack_2048", name = "Aurora", desc = "Create a 2048 tile in Time Attack mode", reward = "Aurora Theme" }
    }

    local list_y = padding + font_title:getHeight() + math.floor(20 * scale)
    local item_h = math.floor(85 * scale)
    local footer_h = math.floor(55 * scale)

    love.graphics.setScissor(0, list_y - math.floor(5 * scale), w, h - list_y - footer_h + math.floor(5 * scale))

    local current_y = list_y - (scroll * item_h)
    for i, ach in ipairs(achievementsList) do
        do
            local isUnlocked = _G.achievements[ach.id]

            -- Card background
            love.graphics.setColor(board_color[1], board_color[2], board_color[3], isUnlocked and 0.9 or 0.4)
            roundedRect("fill", padding, current_y, w - padding * 2, item_h - math.floor(10 * scale), math.floor(12 * scale))
            
            -- Card border
            if isUnlocked then
                love.graphics.setColor(help_key_color)
            else
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.2)
            end
            love.graphics.setLineWidth(math.floor(2 * scale))
            roundedRect("line", padding, current_y, w - padding * 2, item_h - math.floor(10 * scale), math.floor(12 * scale))

            -- Icon Area (centered vertically in card)
            local icon_s = math.floor(48 * scale)
            local card_h = item_h - math.floor(10 * scale)
            local icon_x = padding + math.floor(12 * scale)
            local icon_y = current_y + (card_h - icon_s) / 2
            
            if _G.theme == "ascii" then
                local cx = icon_x + icon_s / 2
                local cy = icon_y + icon_s / 2
                
                -- Outer wireframe box for icon
                love.graphics.setColor(ui_text)
                love.graphics.setLineWidth(math.max(1, math.floor(1.5 * scale)))
                roundedRect("line", icon_x, icon_y, icon_s, icon_s)
                
                if isUnlocked then
                    -- ASCII checkmark [X]
                    love.graphics.setFont(font_message)
                    love.graphics.setColor(ui_text)
                    local txt = "X"
                    local tw = font_message:getWidth(txt)
                    local th = font_message:getHeight()
                    love.graphics.print(txt, cx - tw / 2, cy - th / 2)
                else
                    -- ASCII Lock
                    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.7)
                    local lock_w = math.floor(20 * scale)
                    local lock_h = math.floor(15 * scale)
                    local lock_x = cx - lock_w / 2
                    local lock_y = cy - lock_h / 2 + math.floor(4 * scale)
                    
                    -- Wireframe lock body
                    roundedRect("line", lock_x, lock_y, lock_w, lock_h)
                    
                    -- Lock shackle
                    local shackle_r = math.floor(7 * scale)
                    local shackle_cy = lock_y - math.floor(1 * scale)
                    love.graphics.setLineWidth(math.max(2, math.floor(2.5 * scale)))
                    love.graphics.arc("line", "open", cx, shackle_cy, shackle_r, math.pi, math.pi*2, 12)
                    love.graphics.line(cx - shackle_r, shackle_cy, cx - shackle_r, lock_y)
                    love.graphics.line(cx + shackle_r, shackle_cy, cx + shackle_r, lock_y)
                end
            else
                if isUnlocked then
                    -- Solid green circle background
                    local cx = icon_x + icon_s / 2
                    local cy = icon_y + icon_s / 2
                    local r = icon_s / 2
                    love.graphics.setColor(0.18, 0.72, 0.35)
                    love.graphics.circle("fill", cx, cy, r)
                    -- Darker green border
                    love.graphics.setColor(0.12, 0.55, 0.25)
                    love.graphics.setLineWidth(math.max(1, math.floor(2 * scale)))
                    love.graphics.circle("line", cx, cy, r)
                    
                    -- White checkmark drawn with thick lines
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setLineWidth(math.max(2, math.floor(3 * scale)))
                    local check_s = icon_s * 0.3
                    love.graphics.line(
                        cx - check_s, cy,
                        cx - check_s * 0.3, cy + check_s * 0.7,
                        cx + check_s, cy - check_s * 0.6
                    )
                else
                    -- Muted circle background using ui_text at low alpha
                    local cx = icon_x + icon_s / 2
                    local cy = icon_y + icon_s / 2
                    local r = icon_s / 2
                    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.15)
                    love.graphics.circle("fill", cx, cy, r)
                    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.3)
                    love.graphics.setLineWidth(math.max(1, math.floor(1.5 * scale)))
                    love.graphics.circle("line", cx, cy, r)
                    
                    -- Draw Padlock using ui_text color (always visible)
                    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.7)
                    local lock_w = math.floor(20 * scale)
                    local lock_h = math.floor(15 * scale)
                    local lock_x = cx - lock_w / 2
                    local lock_y = cy - lock_h / 2 + math.floor(4 * scale)
                    
                    -- Lock body
                    roundedRect("fill", lock_x, lock_y, lock_w, lock_h, math.floor(3 * scale))
                    
                    -- Lock keyhole
                    love.graphics.setColor(bg_color[1], bg_color[2], bg_color[3], 0.8)
                    love.graphics.circle("fill", lock_x + lock_w/2, lock_y + lock_h * 0.4, math.max(1, math.floor(2 * scale)))
                    love.graphics.rectangle("fill", lock_x + lock_w/2 - math.floor(1 * scale), lock_y + lock_h * 0.4, math.floor(2 * scale), math.floor(5 * scale))
                    
                    -- Lock shackle (arc + vertical lines)
                    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.7)
                    local shackle_r = math.floor(7 * scale)
                    local shackle_cy = lock_y - math.floor(1 * scale)
                    love.graphics.setLineWidth(math.max(2, math.floor(2.5 * scale)))
                    love.graphics.arc("line", "open", cx, shackle_cy, shackle_r, math.pi, math.pi*2, 12)
                    love.graphics.line(cx - shackle_r, shackle_cy, cx - shackle_r, lock_y)
                    love.graphics.line(cx + shackle_r, shackle_cy, cx + shackle_r, lock_y)
                end
            end

            -- Name & Desc
            local text_x = icon_x + icon_s + math.floor(15 * scale)
            if isUnlocked then
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 1)
            else
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.5)
            end
            love.graphics.setFont(font_label)
            love.graphics.print(ach.name, text_x, current_y + math.floor(12 * scale))
            
            love.graphics.setFont(font_help_label)
            if isUnlocked then
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.8)
            else
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.35)
            end
            love.graphics.print(ach.desc, text_x, current_y + math.floor(42 * scale))
            
            -- Reward Tag
            love.graphics.setFont(font_help_label)
            local rew_text = "Unlocks: " .. ach.reward
            local rw = font_help_label:getWidth(rew_text)
            local tag_x = w - padding - rw - math.floor(25 * scale)
            local tag_y = current_y + math.floor(22 * scale)
            
            -- Tag background
            if isUnlocked then
                love.graphics.setColor(super_tile_color[1], super_tile_color[2], super_tile_color[3], 0.2)
            else
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.1)
            end
            roundedRect("fill", tag_x - math.floor(8 * scale), tag_y - math.floor(4 * scale), rw + math.floor(16 * scale), font_help_label:getHeight() + math.floor(8 * scale), math.floor(6 * scale))
            
            if isUnlocked then
                love.graphics.setColor(super_tile_color[1], super_tile_color[2], super_tile_color[3], 1)
            else
                love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.4)
            end
            love.graphics.print(rew_text, tag_x, tag_y)

            current_y = current_y + item_h
        end
    end

    love.graphics.setScissor()

    -- Footer bar for Achievements
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local item_gap = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- Left side: DPAD (Scroll)
    local dpad_x = padding
    local dpad_size = math.floor(24 * scale)
    drawKeyBadge("DPAD", dpad_x, badge_y + (badge_h - dpad_size) / 2, dpad_size, dpad_size)
    dpad_x = dpad_x + dpad_size + math.floor(6 * scale)
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text)
    love.graphics.print("Scroll", dpad_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

    -- Right side actions: B (Back), Y (Theme)
    local right_x = w - padding
    local actions = {
        {key = "B", label = "Back"},
        {key = "Y", label = "Switch Theme"}
    }
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
    end

    -- Theme transition overlay
    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end
end

-- ============================================================================
-- About Screen
-- ============================================================================
local qr_image
function renderer.drawAbout(skip_transition)
    love.graphics.setColor(bg_color)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())

    local w, h = love.graphics.getDimensions()
    local scale = _G.scale
    local padding = math.floor(20 * scale)

    love.graphics.setFont(font_title)
    love.graphics.setColor(ui_text)
    local title = "About 2048"
    local tw = font_title:getWidth(title)
    love.graphics.print(title, (w - tw) / 2, padding)

    love.graphics.setFont(font_label)
    love.graphics.setColor(ui_text)
    local version_text = _G.version or "v2.0.1"
    local vw = font_label:getWidth(version_text)
    love.graphics.print(version_text, (w - vw) / 2, padding + font_title:getHeight() - math.floor(2 * scale))

    local start_y = padding + font_title:getHeight() + font_label:getHeight() + math.floor(15 * scale)
    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text)

    local text = "Developed by saitamasahil for muOS.\n" ..
                 "A port of the classic 2048 puzzle game.\n\n" ..
                 "If you enjoy the game, consider supporting!"

    local text_w = font_help_label:getWidth("Developed by saitamasahil for muOS.")
    love.graphics.printf(text, 0, start_y, w, "center")

    if not qr_image then
        local success, img = pcall(love.graphics.newImage, "assets/kofi_qr.png")
        if success then qr_image = img end
    end

    if qr_image then
        local iw, ih = qr_image:getDimensions()
        local qr_size = math.floor(160 * scale)
        local qr_scale = qr_size / math.max(iw, ih)
        local scaled_w = iw * qr_scale
        local scaled_h = ih * qr_scale

        -- Calculate position
        local _, wrapped = font_help_label:getWrap(text, w)
        local qr_y = start_y + #wrapped * font_help_label:getHeight() + math.floor(30 * scale)
        local qr_x = (w - scaled_w) / 2

        -- Draw white background behind QR
        local bg_pad = math.floor(6 * scale)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", qr_x - bg_pad, qr_y - bg_pad, scaled_w + bg_pad * 2, scaled_h + bg_pad * 2, math.floor(4 * scale), math.floor(4 * scale))

        -- Draw QR
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(qr_image, qr_x, qr_y, 0, qr_scale, qr_scale)
        
        -- Caption
        love.graphics.setFont(font_help_label)
        love.graphics.setColor(ui_text)
        love.graphics.printf("Scan to support on Ko-fi", 0, qr_y + scaled_h + math.floor(10 * scale), w, "center")
    end

    -- Footer bar for About
    local badge_h = math.floor(28 * scale)
    local badge_y = h - badge_h - math.floor(15 * scale)
    local item_gap = math.floor(10 * scale)
    local label_gap = math.floor(4 * scale)

    -- Right side actions: B (Back), Y (Theme)
    local right_x = w - math.floor(20 * scale)
    local actions = {
        {key = "B", label = "Back"},
        {key = "Y", label = "Switch Theme"}
    }
    for _, action in ipairs(actions) do
        -- Label
        love.graphics.setFont(font_help_label)
        local lbl_w = font_help_label:getWidth(action.label)
        right_x = right_x - lbl_w
        love.graphics.setColor(ui_text)
        love.graphics.print(action.label, right_x, badge_y + (badge_h - font_help_label:getHeight()) / 2)

        -- Badge
        right_x = right_x - label_gap
        local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth(action.key) + math.floor(12 * scale))
        right_x = right_x - key_w
        drawKeyBadge(action.key, right_x, badge_y, key_w, badge_h)

        right_x = right_x - item_gap
    end

    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end

    drawToast()
end

return renderer
