-- 2048 for muOS — Main entry point
-- A faithful port of the classic 2048 game for aarch64 handhelds

require("globals")

local Game     = require("game")
local input    = require("input")
local renderer = require("renderer")
local save     = require("save")
local splash   = require("splash")

local game

function love.load(args)
    math.randomseed(os.time())

    -- Handle resolution arguments (same pattern as Scrappy)
    if args and #args > 0 then
        local w, h = 640, 480
        if #args >= 2 then
            w = tonumber(args[1]) or 640
            h = tonumber(args[2]) or 480
            _G.resolution = w .. "x" .. h
        else
            local parts = {}
            for part in args[1]:gmatch("[^x]+") do
                table.insert(parts, part)
            end
            w = tonumber(parts[1]) or 640
            h = tonumber(parts[2]) or 480
            _G.resolution = args[1]
        end
        love.window.setMode(w, h)
        update_ui_scale()
    end

    update_ui_scale()

    -- Initialize save system (high scores stored in static/ dir)
    _G.WORK_DIR = love.filesystem.getWorkingDirectory() or "."
    save.init(_G.WORK_DIR .. "/static")

    -- Load theme early for renderer and splash screen
    local savedState = save.loadState()
    if savedState and savedState.theme then
        _G.theme = savedState.theme
    end
    -- Crucially apply the loaded theme to the renderer NOW
    renderer.applyTheme()

    -- Initialize input
    input.load()

    -- Initialize renderer (compute layout, load fonts)
    renderer.init()

    -- Load splash screen
    splash.load()

    -- Start a new game
    game = Game.new()
end

function love.update(dt)
    -- Cap dt to prevent animation glitches on frame drops
    dt = math.min(dt, 0.05)

    -- Check for global exit combo (MENU + START)
    if input.state[input.events.MENU] and input.state[input.events.START] then
        love.event.quit()
        return
    end

    -- Update timer system (drives splash animations)
    timer.update(dt)

    -- Don't process game input during splash
    if not splash.finished then
        -- Allow skipping splash with any button
        input.update(dt)
        input.processEvents(function(event)
            if event == input.events.CONFIRM or event == input.events.SELECT or event == input.events.START then
                splash.finished = true
                splash.is_revealing = false
            end
        end)
        return
    end

    -- Update game animations
    game:update(dt)
    renderer.updateTransition(dt)

    -- Update input (hold-to-repeat)
    input.update(dt)

    -- Process input events
    input.processEvents(function(event)
        if event == input.events.Y then
            renderer.startThemeTransition(game)
            _G.theme = _G.theme == "light" and "dark" or "light"
            renderer.applyTheme()
            if game then game:saveGameState() end
            return
        end

        if game:isPlaying() then
            -- Directional moves
            if event == input.events.UP then
                game:move(Game.DIR_UP)
            elseif event == input.events.RIGHT then
                game:move(Game.DIR_RIGHT)
            elseif event == input.events.DOWN then
                game:move(Game.DIR_DOWN)
            elseif event == input.events.LEFT then
                game:move(Game.DIR_LEFT)
            -- Undo
            elseif event == input.events.BACK then
                game:undo()
            -- Pause menu (select or start button)
            elseif event == input.events.SELECT or event == input.events.START then
                game:togglePause()
            end
        elseif game.state == Game.STATE_PAUSED then
            if event == input.events.CONFIRM then
                game:restart()
            elseif event == input.events.BACK or event == input.events.SELECT or event == input.events.START then
                game:cancelPause()
            elseif event == input.events.X then
                love.event.quit()
            end
        elseif game.state == Game.STATE_WON then
            if event == input.events.CONFIRM then
                game:continueGame()
            elseif event == input.events.BACK then
                game:undo()
            elseif event == input.events.SELECT then
                game:restart()
            end
        elseif game.state == Game.STATE_LOST then
            if event == input.events.CONFIRM or event == input.events.SELECT then
                game:restart()
            elseif event == input.events.BACK then
                game:undo()
            end
        end
    end)
end

function love.draw()
    if splash.finished then
        renderer.draw(game)
    else
        splash.draw()
    end
end
