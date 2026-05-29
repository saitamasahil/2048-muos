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
local win_timer = 0

-- Toast state
local toast_message = nil
local toast_timer = 0
local toast_queue = {}
local TOAST_DURATION = 1.5

function renderer.showToast(msg)
    if toast_timer > 0 then
        table.insert(toast_queue, msg)
    else
        toast_message = msg
        toast_timer = TOAST_DURATION
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

function renderer.getThemeBgColor()
    return bg_color
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
    local tile_font_size = math.floor(cell_size * 0.45)
    local tile_small_size = math.floor(cell_size * 0.35)
    local tile_tiny_size = math.floor(cell_size * 0.28)
    font_tile_large = love.graphics.newFont(font_path, tile_font_size)
    font_tile_small = love.graphics.newFont(font_path, tile_small_size)
    font_tile_tiny  = love.graphics.newFont(font_path, tile_tiny_size)
    font_score      = love.graphics.newFont(font_path, math.floor(20 * scale))
    font_title      = love.graphics.newFont(font_path, math.floor(36 * scale))
    font_main_menu_title = love.graphics.newFont(font_path, math.floor(96 * scale))
    font_cheats_title = love.graphics.newFont(font_path, math.floor(54 * scale))
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
    local item_gap = math.floor(8 * scale)
    local label_gap = math.floor(4 * scale)

    -- --- D-PAD section (left side) ---
    local dpad_x = bar_x + math.floor(10 * scale)

    -- Arrow key badges (the 'Move' label has been removed to free up space)
    local arrow_w = math.floor(30 * scale)
    local arrows = {"←", "↑", "↓", "→"}
    for _, arrow in ipairs(arrows) do
        drawKeyBadge(arrow, dpad_x, badge_y, arrow_w, badge_h)
        dpad_x = dpad_x + arrow_w + math.floor(4 * scale)
    end

    -- Action buttons (right side) ---
    local right_x = bar_x + bar_w - math.floor(10 * scale)

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
        if game.canUndo then
            if game.mode == "plus" and game.powerups.undo > 0 then
                table.insert(actions, 1, {key = "B", label = "Undo:" .. game.powerups.undo})
            elseif game.mode ~= "plus" then
                table.insert(actions, 1, {key = "B", label = "Undo"})
            end
        end
    elseif game.state == Game.STATE_PAUSED then
        table.insert(actions, 1, {key = "A", label = "Restart"})
        table.insert(actions, 1, {key = "X", label = "Quit"})
        table.insert(actions, 1, {key = "B", label = "Resume"})
    elseif game.state == Game.STATE_TARGETING_BOMB or game.state == Game.STATE_TARGETING_SWAP_1 or game.state == Game.STATE_TARGETING_SWAP_2 then
        table.insert(actions, 1, {key = "A", label = "Confirm"})
        table.insert(actions, 1, {key = "B", label = "Cancel"})
    else
        if game.mode == "plus" then
            table.insert(actions, 1, {key = "START", label = "Pause"})
            -- Theme is hidden in Plus Mode to prevent overlapping the D-Pad
            table.insert(actions, 1, {key = "L1", label = "Swap:" .. game.powerups.swap})
            table.insert(actions, 1, {key = "R1", label = "Bomb:" .. game.powerups.bomb})
            table.insert(actions, 1, {key = "B", label = "Undo:" .. game.powerups.undo})
        else
            table.insert(actions, 1, {key = "START", label = "Pause"})
            table.insert(actions, 1, {key = "Y", label = "Theme"})
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
    if toast_timer > 0 then
        toast_timer = math.max(0, toast_timer - dt)
        if toast_timer == 0 and #toast_queue > 0 then
            toast_message = table.remove(toast_queue, 1)
            toast_timer = TOAST_DURATION
        end
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

    local boxW = tw + padX * 2
    local boxH = th + padY * 2
    
    -- Fade in/out
    local alpha = 1.0
    if toast_timer < 0.3 then
        alpha = toast_timer / 0.3
    elseif toast_timer > TOAST_DURATION - 0.3 then
        alpha = (TOAST_DURATION - toast_timer) / 0.3
    end
    
    local y = h - (70 * _G.scale) - boxH
    -- Slide up slightly
    y = y + (1.0 - alpha) * 10 * _G.scale

    love.graphics.setColor(0.1, 0.1, 0.1, 0.85 * alpha)
    roundedRect("fill", (w - boxW) / 2, y, boxW, boxH, 12 * _G.scale)
    
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(toast_message, (w - tw) / 2, y + padY)
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
            love.graphics.setColor(color)
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
    local msg_pad = math.floor(15 * scale)
    local msg_box_x = padding
    local msg_box_w = w - padding * 2

    -- Calculate message box height from lines
    love.graphics.setFont(font_help_label)
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
    local available_w = w - padding * 2
    local board_size = math.min(available_w, available_h)
    local board_x = math.floor((w - board_size) / 2)

    drawMiniBoard(board_x, board_top, board_size, slide.tiles, slide.highlight)

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
    table.insert(actions, 1, {key = "Y", label = "Theme"})
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

    love.graphics.setFont(font_main_menu_title)
    love.graphics.setColor(ui_text)
    local title = "2048"
    local tw = font_main_menu_title:getWidth(title)
    love.graphics.print(title, (w - tw) / 2, h * 0.08)
    
    local options = {"Play Classic Mode", "Play Plus Mode", "Achievements", "Tutorial", "Quit"}
    if _G.cheats_unlocked then
        table.insert(options, 5, "Cheats")
    end
    local start_y = h * 0.35
    local gap = math.floor(40 * scale)

    love.graphics.setFont(font_message)
    local max_ow = 0
    for _, opt in ipairs(options) do
        local ow = font_message:getWidth(opt)
        if ow > max_ow then
            max_ow = ow
        end
    end
    local block_x = (w - max_ow) / 2

    for i, opt in ipairs(options) do
        local oy = start_y + (i - 1) * gap
        if i == selection then
            love.graphics.setColor(help_key_color)
            roundedRect("fill", block_x - 20 * scale, oy - 5 * scale, max_ow + 40 * scale, font_message:getHeight() + 10 * scale, 8 * scale)
            love.graphics.setColor(help_key_text)
        else
            love.graphics.setColor(ui_text)
        end
        love.graphics.print(opt, block_x, oy)
    end

    -- Draw Theme hint at the bottom right
    local badge_h = math.floor(28 * scale)
    local hy = h - badge_h - math.floor(20 * scale)
    
    love.graphics.setFont(font_help_label)
    local lbl_text = "Theme"
    local lbl_w = font_help_label:getWidth(lbl_text)
    local key_w = math.max(math.floor(28 * scale), font_help_key:getWidth("Y") + math.floor(12 * scale))
    local total_w = key_w + math.floor(4 * scale) + lbl_w
    local start_x = w - total_w - math.floor(20 * scale) -- Align right with 20px padding

    drawKeyBadge("Y", start_x, hy, key_w, badge_h)
    love.graphics.setColor(ui_text)
    love.graphics.print(lbl_text, start_x + key_w + math.floor(4 * scale), hy + (badge_h - font_help_label:getHeight()) / 2)

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

    love.graphics.setFont(font_cheats_title)
    love.graphics.setColor(ui_text)
    local title = "Cheats Menu"
    local tw = font_cheats_title:getWidth(title)
    love.graphics.print(title, (w - tw) / 2, h * 0.10)



    local options = {
        "Unlock All Themes",
        "Max Powerups: " .. (_G.cheat_max_powerups and "ON" or "OFF"),
        "Start with 1024 (Classic Mode): " .. (_G.cheat_start_1024_classic and "ON" or "OFF"),
        "Start with 1024 (Plus Mode): " .. (_G.cheat_start_1024_plus and "ON" or "OFF"),
        "Debug: Test All Tiles: " .. (_G.cheat_test_tiles and "ON" or "OFF"),
        "Debug: Two 1024 Tiles: " .. (_G.cheat_two_1024s and "ON" or "OFF"),
        "Back"
    }
    local start_y = h * 0.28
    local gap = math.floor(40 * scale)

    love.graphics.setFont(font_message)
    local max_ow = 0
    for _, opt in ipairs(options) do
        local ow = font_message:getWidth(opt)
        if ow > max_ow then
            max_ow = ow
        end
    end
    local block_x = (w - max_ow) / 2

    for i, opt in ipairs(options) do
        local oy = start_y + (i - 1) * gap
        if i == selection then
            love.graphics.setColor(help_key_color)
            roundedRect("fill", block_x - 20 * scale, oy - 5 * scale, max_ow + 40 * scale, font_message:getHeight() + 10 * scale, 8 * scale)
            love.graphics.setColor(help_key_text)
        else
            love.graphics.setColor(ui_text)
        end
        love.graphics.print(opt, block_x, oy)
    end

    love.graphics.setFont(font_help_label)
    love.graphics.setColor(ui_text[1], ui_text[2], ui_text[3], 0.7)
    local subtitle = "Cheats are only active for the current session"
    local sw = font_help_label:getWidth(subtitle)
    local subtitle_y = start_y + (#options * gap) + math.floor(10 * scale)
    love.graphics.print(subtitle, (w - sw) / 2, subtitle_y)

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
        { id = "ach_untouchable_2048", name = "Zen Master", desc = "Create a 2048 tile without using undos or powerups", reward = "Matcha Theme" }
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

    -- Footer bar
    local badge_h = math.floor(28 * scale)
    local hy = h - badge_h - math.floor(10 * scale)

    -- Back button hint (left side)
    love.graphics.setFont(font_help_label)
    local back_text = "Back"
    drawKeyBadge("B", padding, hy, math.floor(28 * scale), badge_h)
    love.graphics.setColor(ui_text)
    love.graphics.print(back_text, padding + math.floor(34 * scale), hy + (badge_h - font_help_label:getHeight()) / 2 - math.floor(2 * scale))

    -- Theme button hint (right side)
    local lbl_text = "Theme"
    local lbl_w = font_help_label:getWidth(lbl_text)
    local key_w = math.floor(28 * scale)
    local theme_x = w - lbl_w - key_w - math.floor(24 * scale)
    drawKeyBadge("Y", theme_x, hy, key_w, badge_h)
    love.graphics.setColor(ui_text)
    love.graphics.print(lbl_text, theme_x + key_w + math.floor(4 * scale), hy + (badge_h - font_help_label:getHeight()) / 2 - math.floor(2 * scale))

    -- Theme transition overlay
    if not skip_transition and transition_timer > 0 and transition_canvas then
        love.graphics.stencil(drawStencilCircle, "replace", 1)
        love.graphics.setStencilTest("equal", 0)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(transition_canvas, 0, 0)
        love.graphics.setStencilTest()
    end
end

return renderer
