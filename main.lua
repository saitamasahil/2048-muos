-- 2048 for muOS — Main entry point
-- A faithful port of the classic 2048 game for aarch64 handhelds

require("globals")

local Game     = require("game")
local input    = require("input")
local renderer = require("renderer")
local save     = require("save")
local splash   = require("splash")

_G.appState = "MENU" -- "MENU" or "GAME"
local menuSelection = 1 -- 1: Classic, 2: Plus, 3: Quit

local game

function love.load(args)
    love.math.setRandomSeed(os.time())

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
    if game then
        game:update(dt)
    end
    renderer.updateTransition(dt)

    -- Update input (hold-to-repeat)
    input.update(dt)

    -- Process input events
    input.processEvents(function(event)
        if event == input.events.Y then
            if _G.appState == "MENU" then
                renderer.startThemeTransition(function() renderer.drawMainMenu(menuSelection, true) end)
            else
                renderer.startThemeTransition(game)
            end
            _G.theme = _G.theme == "light" and "dark" or "light"
            renderer.applyTheme()
            if game then game:saveGameState() end
            return
        end

        if _G.appState == "MENU" then
            if event == input.events.UP then
                menuSelection = menuSelection > 1 and (menuSelection - 1) or 3
            elseif event == input.events.DOWN then
                menuSelection = menuSelection < 3 and (menuSelection + 1) or 1
            elseif event == input.events.CONFIRM then
                if menuSelection == 1 then
                    _G.appState = "GAME"
                    game = Game.new("classic")
                elseif menuSelection == 2 then
                    _G.appState = "GAME"
                    game = Game.new("plus")
                elseif menuSelection == 3 then
                    love.event.quit()
                end
            end
            return
        end

        -- GAME inputs below
        if game.state == Game.STATE_TARGETING_BOMB or game.state == Game.STATE_TARGETING_SWAP_1 or game.state == Game.STATE_TARGETING_SWAP_2 then
            if event == input.events.UP then
                game:moveCursor(0, -1)
            elseif event == input.events.DOWN then
                game:moveCursor(0, 1)
            elseif event == input.events.LEFT then
                game:moveCursor(-1, 0)
            elseif event == input.events.RIGHT then
                game:moveCursor(1, 0)
            elseif event == input.events.CONFIRM then
                game:confirmTarget()
            elseif event == input.events.BACK then
                game:cancelTargeting()
            end
        elseif game:isPlaying() then
            -- Directional moves
            if event == input.events.UP then
                game:move(Game.DIR_UP)
            elseif event == input.events.RIGHT then
                game:move(Game.DIR_RIGHT)
            elseif event == input.events.DOWN then
                game:move(Game.DIR_DOWN)
            elseif event == input.events.LEFT then
                game:move(Game.DIR_LEFT)
            -- Powerups
            elseif event == input.events.L1 then
                if game.mode == "plus" and game.powerups.swap <= 0 then
                    renderer.showToast("No Swap Powerup!")
                else
                    game:startSwapTargeting()
                end
            elseif event == input.events.R1 then
                if game.mode == "plus" and game.powerups.bomb <= 0 then
                    renderer.showToast("No Bomb Powerup!")
                else
                    game:startBombTargeting()
                end
            -- Undo
            elseif event == input.events.BACK then
                if game.mode == "plus" and game.powerups.undo <= 0 then
                    renderer.showToast("No Undo Powerup!")
                else
                    game:undo()
                end
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
                if game then game:saveGameState() end
                _G.appState = "MENU"
                game = nil
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
    if not splash.finished then
        splash.draw()
    elseif _G.appState == "MENU" then
        renderer.drawMainMenu(menuSelection)
    else
        renderer.draw(game)
    end
end
