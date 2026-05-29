-- 2048 for muOS — Global constants and scaling helpers

_G.timer = require("timer")

local sem_ver = {
    major = 1,
    minor = 0,
    patch = 2,
    extra = ""
}

_G.version = (function()
    local version = string.format("v%d.%d.%d", sem_ver.major, sem_ver.minor, sem_ver.patch)
    if sem_ver.extra ~= "" then
        version = version .. "-" .. sem_ver.extra
    end
    return version
end)()

_G.resolution = "640x480"
_G.design_w = 640
_G.design_h = 480
_G.sx = 1
_G.sy = 1
_G.scale = 1

function _G.update_ui_scale()
    local w, h = love.graphics.getDimensions()
    _G.sx = w / _G.design_w
    _G.sy = h / _G.design_h
    _G.scale = math.min(_G.sx, _G.sy)

    -- Snap to 1.0 if very close (prevents tiny rounding errors on 640x480)
    if math.abs(_G.scale - 1) < 0.01 then
        _G.scale = 1
        _G.sx = 1
        _G.sy = 1
    end
end

-- Global scaling helper — multiply any design-space value by current scale
function _G.g(val)
    return val * _G.scale
end

-- Working directory (set after love.load)
_G.WORK_DIR = ""

-- Current visual theme (light / dark / oled / neon / retro / peach / ocean / forest / sunset / candy)
_G.theme = "light"

-- Achievements and Unlockables
_G.achievements = {
    -- Simple achievements (color-only themes, no custom tiles)
    ach_first_game = false,  -- First Steps -> unlocks 'ocean'
    ach_score_1k = false,    -- Getting Started -> unlocks 'forest'
    ach_score_5k = false,    -- Rising Star -> unlocks 'sunset'
    ach_merge_512 = false,   -- Half Way There -> unlocks 'candy'
    
    -- Premium achievements (full custom tile themes)
    ach_2048 = false,        -- 2048 Master -> unlocks 'oled'
    ach_score_10k = false,   -- High Roller -> unlocks 'neon'
    ach_demolition = false,  -- Demolition Expert (10 bombs used) -> unlocks 'retro'
    ach_untouchable = false, -- Untouchable (1024 without powerups) -> unlocks 'peach'
    
    -- Dark simple achievements (color-only dark themes)
    ach_merge_1024 = false,  -- Almost There -> unlocks 'midnight'
    ach_score_2k = false,    -- Gaining Momentum -> unlocks 'volcano'
    ach_score_7k = false,    -- High Scorer -> unlocks 'abyss'
    ach_first_bomb = false,  -- Boom! -> unlocks 'eclipse'
    
    -- Hidden tracking stats
    bombs_used = 0,
    powerups_used_this_run = 0
}

_G.unlocked_themes = {"light", "dark"}
