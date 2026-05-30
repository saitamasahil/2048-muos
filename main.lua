-- 2048 for muOS — Main entry point
-- A faithful port of the classic 2048 game for aarch64 handhelds

require("globals")

local Game     = require("game")
local input    = require("input")
local renderer = require("renderer")
local save     = require("save")
local splash   = require("splash")

_G.appState = "MENU" -- "MENU" or "GAME"
local menuSelection = 1 -- 1: Classic, 2: Plus, 3: Achievements, 4: Tutorial, 5: Quit

local game

_G.cheats_unlocked = false
local konami_sequence = { "up", "up", "down", "down", "left", "right", "left", "right", "backspace", "return", "space" }
local konami_progress = 1

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

    -- Load achievements
    local loadedAchievements = save.loadAchievements()
    if loadedAchievements then
        -- Merge loaded achievements to avoid overwriting new ones in future updates
        for k, v in pairs(loadedAchievements) do
            _G.achievements[k] = v
        end
    end
    -- Rebuild unlocked themes based on loaded achievements
    _G.unlocked_themes = {"light", "dark"}
    if _G.achievements.ach_first_game then table.insert(_G.unlocked_themes, "ocean") end
    if _G.achievements.ach_score_1k then table.insert(_G.unlocked_themes, "forest") end
    if _G.achievements.ach_score_5k then table.insert(_G.unlocked_themes, "sunset") end
    if _G.achievements.ach_merge_512 then table.insert(_G.unlocked_themes, "candy") end
    if _G.achievements.ach_2048 then table.insert(_G.unlocked_themes, "oled") end
    if _G.achievements.ach_score_10k then table.insert(_G.unlocked_themes, "neon") end
    if _G.achievements.ach_demolition then table.insert(_G.unlocked_themes, "retro") end
    if _G.achievements.ach_untouchable then table.insert(_G.unlocked_themes, "peach") end
    if _G.achievements.ach_merge_1024 then table.insert(_G.unlocked_themes, "midnight") end
    if _G.achievements.ach_score_2k then table.insert(_G.unlocked_themes, "volcano") end
    if _G.achievements.ach_score_7k then table.insert(_G.unlocked_themes, "abyss") end
    if _G.achievements.ach_first_bomb then table.insert(_G.unlocked_themes, "eclipse") end
    
    if _G.achievements.ach_2048_plus then table.insert(_G.unlocked_themes, "cyberpunk") end
    if _G.achievements.ach_4096 then table.insert(_G.unlocked_themes, "matrix") end
    if _G.achievements.ach_score_25k then table.insert(_G.unlocked_themes, "vaporwave") end
    if _G.achievements.ach_score_50k then table.insert(_G.unlocked_themes, "dracula") end
    if _G.achievements.ach_score_100k then table.insert(_G.unlocked_themes, "gold") end
    if _G.achievements.ach_untouchable_2048 then table.insert(_G.unlocked_themes, "matcha") end
    if _G.achievements.ach_secret_ascii then table.insert(_G.unlocked_themes, "ascii") end

    function _G.unlockAchievement(id)
        if not _G.achievements[id] then
            _G.achievements[id] = true
            save.saveAchievements(_G.achievements)
            
            local theme_map = {
                ach_first_game = "ocean",
                ach_score_1k = "forest",
                ach_score_5k = "sunset",
                ach_merge_512 = "candy",
                ach_2048 = "oled",
                ach_score_10k = "neon",
                ach_demolition = "retro",
                ach_untouchable = "peach",
                ach_merge_1024 = "midnight",
                ach_score_2k = "volcano",
                ach_score_7k = "abyss",
                ach_first_bomb = "eclipse",
                ach_2048_plus = "cyberpunk",
                ach_4096 = "matrix",
                ach_score_25k = "vaporwave",
                ach_score_50k = "dracula",
                ach_score_100k = "gold",
                ach_untouchable_2048 = "matcha"
            }
            if theme_map[id] then
                table.insert(_G.unlocked_themes, theme_map[id])
            end
            
            local names = {
                ach_first_game = "First Steps",
                ach_score_1k = "Getting Started",
                ach_score_5k = "Rising Star",
                ach_merge_512 = "Half Way There",
                ach_2048 = "2048 Master",
                ach_score_10k = "High Roller",
                ach_demolition = "Demolition Expert",
                ach_untouchable = "Untouchable",
                ach_merge_1024 = "Almost There",
                ach_score_2k = "Gaining Momentum",
                ach_score_7k = "High Scorer",
                ach_first_bomb = "Boom!",
                ach_2048_plus = "Plus Mode Master",
                ach_4096 = "The One",
                ach_score_25k = "Aesthetic",
                ach_score_50k = "Vampire Lord",
                ach_score_100k = "Midas Touch",
                ach_untouchable_2048 = "Zen Master"
            }
            renderer.showToast("Unlocked: " .. (names[id] or id) .. "!")
        end
    end

    -- Load theme from dedicated file
    local savedTheme = save.loadTheme()
    if savedTheme then
        _G.theme = savedTheme
    end
    
    _G.cheats_unlocked = save.loadCheats()
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

    -- Smooth scroll interpolation for achievements
    if _G.achievements_scroll == nil then _G.achievements_scroll = 0 end
    if _G.achievements_scroll_target == nil then _G.achievements_scroll_target = 0 end
    if _G.achievements_scroll ~= _G.achievements_scroll_target then
        local diff = _G.achievements_scroll_target - _G.achievements_scroll
        _G.achievements_scroll = _G.achievements_scroll + diff * 15 * dt
        if math.abs(_G.achievements_scroll - _G.achievements_scroll_target) < 0.01 then
            _G.achievements_scroll = _G.achievements_scroll_target
        end
    end

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
            elseif _G.appState == "CHEATS_MENU" then
                renderer.startThemeTransition(function() renderer.drawCheatsMenu(_G.cheats_selection or 1, true) end)
            elseif _G.appState == "ACHIEVEMENTS" then
                renderer.startThemeTransition(function() renderer.drawAchievements(_G.achievements_scroll or 0, true) end)
            elseif _G.appState == "TUTORIAL" then
                renderer.startThemeTransition(function() renderer.drawTutorial(_G.tutorial_page or 1, true) end)
            else
                renderer.startThemeTransition(game)
            end
            local current_idx = 1
            for i, t in ipairs(_G.unlocked_themes) do
                if t == _G.theme then
                    current_idx = i
                    break
                end
            end
            local next_idx = (current_idx % #_G.unlocked_themes) + 1
            _G.theme = _G.unlocked_themes[next_idx]
            renderer.applyTheme()
            save.saveTheme(_G.theme)
            if game then game:saveGameState() end
            return
        end

        if _G.appState == "MENU" then
            if not _G.cheats_unlocked then
                if event == konami_sequence[konami_progress] then
                    konami_progress = konami_progress + 1
                    if konami_progress == 7 then
                        renderer.showToast("What you think this is a Konami game?")
                    elseif konami_progress == 9 then
                        renderer.showToast("Wait, what are you doing?")
                    elseif konami_progress > #konami_sequence then
                        renderer.showToast("You weren't supposed to do this. But OK.")
                        _G.cheats_unlocked = true
                        save.saveCheats(true)
                        konami_progress = 1
                    end
                    if event == input.events.BACK or event == input.events.CONFIRM or event == input.events.START then
                        return
                    end
                else
                    if event == konami_sequence[1] then
                        konami_progress = 2
                    else
                        konami_progress = 1
                    end
                end
            end
            
            local max_menu = _G.cheats_unlocked and 6 or 5
            if event == input.events.UP then
                menuSelection = menuSelection > 1 and (menuSelection - 1) or max_menu
            elseif event == input.events.DOWN then
                menuSelection = menuSelection < max_menu and (menuSelection + 1) or 1
            elseif event == input.events.CONFIRM then
                if menuSelection == 1 then
                    _G.appState = "GAME"
                    game = Game.new("classic")
                elseif menuSelection == 2 then
                    _G.appState = "GAME"
                    game = Game.new("plus")
                elseif menuSelection == 3 then
                    _G.appState = "ACHIEVEMENTS"
                elseif menuSelection == 4 then
                    _G.appState = "TUTORIAL"
                    _G.tutorial_page = 1
                else
                    if _G.cheats_unlocked then
                        if menuSelection == 5 then
                            if not _G.achievements.ach_secret_ascii then
                                _G.achievements.ach_secret_ascii = true
                                table.insert(_G.unlocked_themes, "ascii")
                                save.saveAchievements(_G.achievements)
                                renderer.showToast("Beep Boop! Cheater detected! Enjoy your punishment: the super-retro ASCII Art Theme!", 4.0)
                            end
                            _G.appState = "CHEATS_MENU"
                            _G.cheats_selection = 1
                        elseif menuSelection == 6 then
                            love.event.quit()
                        end
                    else
                        if menuSelection == 5 then
                            love.event.quit()
                        end
                    end
                end
            end
            return
        elseif _G.appState == "TUTORIAL" then
            if event == input.events.BACK then
                if (_G.tutorial_page or 1) > 1 then
                    _G.tutorial_page = _G.tutorial_page - 1
                else
                    _G.appState = "MENU"
                end
            elseif event == input.events.CONFIRM then
                if (_G.tutorial_page or 1) < 8 then
                    _G.tutorial_page = (_G.tutorial_page or 1) + 1
                else
                    _G.appState = "MENU"
                end
            elseif event == input.events.RIGHT then
                if (_G.tutorial_page or 1) < 8 then
                    _G.tutorial_page = (_G.tutorial_page or 1) + 1
                end
            elseif event == input.events.LEFT then
                if (_G.tutorial_page or 1) > 1 then
                    _G.tutorial_page = _G.tutorial_page - 1
                end
            end
            return
        elseif _G.appState == "ACHIEVEMENTS" then
            if event == input.events.BACK then
                _G.appState = "MENU"
                _G.achievements_scroll = 0
                _G.achievements_scroll_target = 0
            elseif event == input.events.UP then
                _G.achievements_scroll_target = math.max(0, (_G.achievements_scroll_target or 0) - 1)
            elseif event == input.events.DOWN then
                -- 18 achievements total, allow scrolling only if items overflow visible area
                local w, h = love.graphics.getDimensions()
                local scale = _G.scale
                local item_h = math.floor(85 * scale)
                local header_h = math.floor(90 * scale)
                local footer_h = math.floor(55 * scale)
                local visible_area = h - header_h - footer_h
                local total_items = 18
                local total_height = total_items * item_h
                local max_scroll = math.max(0, math.ceil((total_height - visible_area) / item_h) + 1)
                _G.achievements_scroll_target = math.min(max_scroll, (_G.achievements_scroll_target or 0) + 1)
            end
            return
        elseif _G.appState == "CHEATS_MENU" then
            if event == input.events.BACK then
                _G.appState = "MENU"
            elseif event == input.events.UP then
                _G.cheats_selection = _G.cheats_selection > 1 and (_G.cheats_selection - 1) or 7
            elseif event == input.events.DOWN then
                _G.cheats_selection = _G.cheats_selection < 7 and (_G.cheats_selection + 1) or 1
            elseif event == input.events.CONFIRM then
                if _G.cheats_selection == 1 then
                    local all_themes = {"ocean", "forest", "sunset", "candy", "oled", "neon", "retro", "peach", "midnight", "volcano", "abyss", "eclipse", "cyberpunk", "matrix", "vaporwave", "dracula", "gold", "matcha"}
                    for _, t in ipairs(all_themes) do
                        local found = false
                        for _, existing in ipairs(_G.unlocked_themes) do
                            if existing == t then found = true break end
                        end
                        if not found then table.insert(_G.unlocked_themes, t) end
                    end
                    renderer.showToast("All Themes Unlocked!")
                elseif _G.cheats_selection == 2 then
                    _G.cheat_max_powerups = not _G.cheat_max_powerups
                    renderer.showToast("Max Powerups: " .. (_G.cheat_max_powerups and "ON" or "OFF"))
                elseif _G.cheats_selection == 3 then
                    _G.cheat_start_1024_classic = not _G.cheat_start_1024_classic
                    if _G.cheat_start_1024_classic then
                        renderer.showToast("Start with 1024 (Classic Mode) is ON. Start a new game to apply.")
                    else
                        renderer.showToast("Start with 1024 (Classic Mode) is OFF.")
                    end
                elseif _G.cheats_selection == 4 then
                    _G.cheat_start_1024_plus = not _G.cheat_start_1024_plus
                    if _G.cheat_start_1024_plus then
                        renderer.showToast("Start with 1024 (Plus Mode) is ON. Start a new game to apply.")
                    else
                        renderer.showToast("Start with 1024 (Plus Mode) is OFF.")
                    end
                elseif _G.cheats_selection == 5 then
                    _G.cheat_test_tiles = not _G.cheat_test_tiles
                    if _G.cheat_test_tiles then
                        renderer.showToast("Test All Tiles is ON. Start a new game to see them.")
                    else
                        renderer.showToast("Test All Tiles is OFF.")
                    end
                elseif _G.cheats_selection == 6 then
                    _G.cheat_two_1024s = not _G.cheat_two_1024s
                    if _G.cheat_two_1024s then
                        renderer.showToast("Two 1024 Tiles is ON. Start a new game to apply.")
                    else
                        renderer.showToast("Two 1024 Tiles is OFF.")
                    end
                elseif _G.cheats_selection == 7 then
                    _G.appState = "MENU"
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
    elseif _G.appState == "TUTORIAL" then
        renderer.drawTutorial(_G.tutorial_page or 1)
    elseif _G.appState == "CHEATS_MENU" then
        renderer.drawCheatsMenu(_G.cheats_selection or 1)
    elseif _G.appState == "ACHIEVEMENTS" then
        renderer.drawAchievements(_G.achievements_scroll or 0)
    elseif _G.appState == "GAME" and game then
        renderer.draw(game)
    end
end
