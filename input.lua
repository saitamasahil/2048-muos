-- Input handler for D-pad / keyboard controls
-- Modeled after Scrappy's helpers/input.lua

local input = {}

local joystick

-- Hold-to-repeat configuration
local repeat_delay = 0.3    -- initial delay before auto-repeat
local repeat_rate  = 0.15   -- time between repeats while holding (slower than Scrappy — game moves are heavier)
local holding = {
    dir = nil,
    start_time = 0,
    started = false,
    last_fire = 0
}

-- Event queue
local event_queue = {}

-- Button mappings
input.events = {
    LEFT   = "left",
    RIGHT  = "right",
    UP     = "up",
    DOWN   = "down",
    CONFIRM = "return",   -- A button
    BACK   = "backspace", -- B button
    SELECT = "rshift",    -- Select button
    START  = "space",     -- Start button
    MENU   = "escape",    -- Physical Menu/Function button
    X      = "x",         -- X button
    Y      = "y",         -- Y button
    L1     = "l1",        -- Left shoulder
    R1     = "r1",        -- Right shoulder
}

input.state = {}

input.joystick_mapping = {
    ["dpleft"]    = input.events.LEFT,
    ["dpright"]   = input.events.RIGHT,
    ["dpup"]      = input.events.UP,
    ["dpdown"]    = input.events.DOWN,
    ["a"]         = input.events.CONFIRM,
    ["b"]         = input.events.BACK,
    ["x"]         = input.events.X,
    ["y"]         = input.events.Y,
    ["back"]      = input.events.SELECT,
    ["start"]     = input.events.START,
    ["guide"]     = input.events.MENU,
    ["leftshoulder"] = input.events.L1,
    ["rightshoulder"] = input.events.R1,
}

-- Cooldown to prevent accidental double-inputs
local cooldown_duration = 0.12
local last_trigger_time = -cooldown_duration

local function can_trigger()
    local now = love.timer.getTime()
    if now - last_trigger_time >= cooldown_duration then
        last_trigger_time = now
        return true
    end
    return false
end

local function emit(event, bypass)
    if bypass or can_trigger() then
        table.insert(event_queue, event)
    end
end

function input.load()
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        joystick = joysticks[1]
    end
end

function input.update(dt)
    -- Process hold-to-repeat for directional events
    if holding.dir then
        local now = love.timer.getTime()
        if not holding.started then
            if now - holding.start_time >= repeat_delay then
                holding.started = true
                holding.last_fire = now
                emit(holding.dir, true)
            end
        else
            if now - holding.last_fire >= repeat_rate then
                holding.last_fire = now
                emit(holding.dir, true)
            end
        end
    end
end

-- Process all queued events via callback
function input.processEvents(callback)
    for _, event in ipairs(event_queue) do
        callback(event)
    end
    event_queue = {}
end

-- Check if a direction is being held
local function is_directional(event)
    return event == input.events.LEFT or event == input.events.RIGHT
        or event == input.events.UP or event == input.events.DOWN
end

function love.keypressed(key)
    for _, k in pairs(input.events) do
        if key == k then
            input.state[key] = true
            emit(key, false)
        end
    end

    if is_directional(key) then
        holding.dir = key
        holding.start_time = love.timer.getTime()
        holding.started = false
        holding.last_fire = holding.start_time
    end
end

function love.keyreleased(key)
    for _, k in pairs(input.events) do
        if key == k then
            input.state[key] = false
        end
    end

    if key == holding.dir then
        holding.dir = nil
        holding.started = false
    end
end

function love.gamepadpressed(js, button)
    local event = input.joystick_mapping[button]
    if event then
        input.state[event] = true
        emit(event, false)

        if is_directional(event) then
            holding.dir = event
            holding.start_time = love.timer.getTime()
            holding.started = false
            holding.last_fire = holding.start_time
        end
    end
end

function love.gamepadreleased(js, button)
    local event = input.joystick_mapping[button]
    if event then
        input.state[event] = false
        if event == holding.dir then
            holding.dir = nil
            holding.started = false
        end
    end
end

return input
