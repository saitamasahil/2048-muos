-- 2048 for muOS — Global constants and scaling helpers

_G.timer = require("timer")

local sem_ver = {
    major = 1,
    minor = 0,
    patch = 1,
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
