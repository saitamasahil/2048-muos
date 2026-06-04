-- 2048 for muOS — Main entry point
-- A faithful port of the classic 2048 game for aarch64 handhelds

require("globals")

local Game     = require("game")
local input    = require("input")
local renderer = require("renderer")
local save     = require("save")
local splash   = require("splash")

_G.appState = "MENU" -- "MENU", "GAME", "ARCADE_MENU", etc.
local menuSelection = 1 -- 1: Classic, 2: Plus, 3: Theme Selection, 4: Achievements, 5: Tutorial, 6: Text, 7: About, 8: Quit
_G.arcade_selection = 1

local game

_G.cheats_unlocked = false
local konami_sequence = { "up", "up", "down", "down", "left", "right", "left", "right", "backspace", "return", "space" }

-- Screen Transition System
local last_app_state = nil
local screen_transition_timer = 0
local screen_transition_duration = 0.28
local screen_canvas = nil       -- canvas of the NEW (incoming) screen
local old_screen_canvas = nil   -- canvas of the OLD (outgoing) screen
local transition_direction = 1  -- +1 = forward (new slides in from right), -1 = backward (from left)
local konami_progress = 1

local transition_delay_timer = 0
local transition_delay_action = nil
local transition_delay_key = nil
-- Direction hint set before queueing a transition: +1 forward, -1 backward
local transition_next_direction = 1
local arcade_menu_closing_action = nil

-- Hierarchy order for determining forward/backward direction
local STATE_DEPTH = {
    MENU          = 0,
    ARCADE_MENU   = 1,
    GAME          = 2,
    TUTORIAL      = 1,
    ABOUT         = 1,
    ACHIEVEMENTS  = 1,
    THEME_SELECT  = 1,
    CHEATS_MENU   = 1,
}

-- Forward declaration (defined later in the file, after love.update's helper logic)
local drawCurrentScreen

local function captureOldScreen()
    local w, h = love.graphics.getDimensions()
    if not old_screen_canvas then
        old_screen_canvas = love.graphics.newCanvas(w, h)
    end
    love.graphics.setCanvas({old_screen_canvas, stencil = true})
    love.graphics.clear()
    drawCurrentScreen()
    love.graphics.setCanvas()
end

local function queueTransitionAction(key, delay, action, direction)
    transition_next_direction = direction or 1
    transition_delay_key = key
    transition_delay_timer = 0.12 -- Extended visual hold duration for a satisfying physical button click
    transition_delay_action = action
end

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
    if _G.achievements.ach_timeattack_2048 then table.insert(_G.unlocked_themes, "aurora") end
    if _G.achievements.ach_huge_2048 then table.insert(_G.unlocked_themes, "nebula") end
    if _G.achievements.ach_nomercy_1024 then table.insert(_G.unlocked_themes, "inferno") end
    if _G.achievements.ach_goose_2048 then table.insert(_G.unlocked_themes, "honk") end

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
                ach_untouchable_2048 = "matcha",
                ach_timeattack_2048 = "aurora",
                ach_huge_2048 = "nebula",
                ach_nomercy_1024 = "inferno",
                ach_goose_2048 = "honk"
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
                ach_untouchable_2048 = "Zen Master",
                ach_timeattack_2048 = "Aurora",
                ach_huge_2048 = "Spacious Giant",
                ach_nomercy_1024 = "No Escape",
                ach_goose_2048 = "Honk Honk!"
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
    _G.text_size = save.loadTextSize() or "normal"
    -- Crucially apply the loaded theme to the renderer NOW
    renderer.applyTheme()

    -- Initialize input
    input.load()

    -- Initialize renderer (compute layout, load fonts)
    renderer.init()
    local w, h = love.graphics.getDimensions()
    screen_canvas = love.graphics.newCanvas(w, h)

    -- Load splash screen
    splash.load()
end

function love.update(dt)
    -- Cap dt to prevent animation glitches on frame drops
    dt = math.min(dt, 0.05)

    -- Trigger screen transitions on appState change (smooth slide animation)
    if _G.appState ~= last_app_state then
        if splash.finished and last_app_state ~= nil then
            -- ARCADE_MENU has its own panel slide animation; skip global slide for it
            local skip_slide = (_G.appState == "ARCADE_MENU" or last_app_state == "ARCADE_MENU")
            if not skip_slide then
                -- Determine direction from hierarchy depth
                local old_depth = STATE_DEPTH[last_app_state] or 0
                local new_depth = STATE_DEPTH[_G.appState] or 0
                if new_depth > old_depth then
                    transition_direction = 1   -- deeper = slide from right
                elseif new_depth < old_depth then
                    transition_direction = -1  -- back = slide from left
                else
                    transition_direction = transition_next_direction
                end
                transition_next_direction = 1
                screen_transition_timer = screen_transition_duration
            end
        end
        last_app_state = _G.appState
    end

    if screen_transition_timer > 0 then
        screen_transition_timer = math.max(0, screen_transition_timer - dt)
    end

    -- Check for global exit combo (MENU + START)
    if input.state[input.events.MENU] and input.state[input.events.START] then
        love.event.quit()
        return
    end

    -- Update timer system (drives splash animations)
    timer.update(dt)

    -- Handle visual transition delays to show key badge animations
    if transition_delay_timer > 0 then
        transition_delay_timer = transition_delay_timer - dt
        if transition_delay_key then
            input.state[transition_delay_key] = true
        end
        if transition_delay_timer <= 0 then
            transition_delay_timer = 0
            if transition_delay_key then
                input.state[transition_delay_key] = false
                transition_delay_key = nil
            end
            if transition_delay_action then
                -- Capture the current (old) screen BEFORE state changes
                captureOldScreen()
                local action = transition_delay_action
                transition_delay_action = nil
                action()
            end
        end
        if game then
            game:update(dt)
        end
        renderer.updateTransition(dt)
        input.update(dt)
        return
    end

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

    -- If arcade menu is closing, wait until it is fully closed, then trigger the action
    if arcade_menu_closing_action and renderer.isArcadeMenuClosed() then
        local action = arcade_menu_closing_action
        arcade_menu_closing_action = nil
        action()
    end

    -- Update input (hold-to-repeat)
    input.update(dt)

    -- Process input events
    input.processEvents(function(event)
        if event == input.events.Y then
            local function getCurrentDrawTarget()
                if _G.appState == "MENU" then
                    return function() renderer.drawMainMenu(menuSelection, true) end
                elseif _G.appState == "GAME" and game then
                    return game
                elseif _G.appState == "ACHIEVEMENTS" then
                    return function() renderer.drawAchievements(_G.achievements_scroll or 0, true) end
                elseif _G.appState == "TUTORIAL" then
                    return function() renderer.drawTutorial(_G.tutorial_page or 1, true) end
                elseif _G.appState == "ABOUT" then
                    return function() renderer.drawAbout(true) end
                elseif _G.appState == "CHEATS_MENU" then
                    return function() renderer.drawCheatsMenu(_G.cheats_selection or 1, true) end
                elseif _G.appState == "THEME_SELECT" then
                    return function() renderer.drawThemeSelect(true) end
                elseif _G.appState == "ARCADE_MENU" then
                    return function() renderer.drawArcadeMenu(_G.arcade_selection or 1, true) end
                end
                return function() end
            end

            local drawTarget = getCurrentDrawTarget()
            renderer.startThemeTransition(drawTarget)

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
            if _G.appState ~= "THEME_SELECT" then
                save.saveTheme(_G.theme)
                if game then game:saveGameState() end
            end
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
            
            -- X button → Arcade Modes menu
            if event == input.events.X then
                queueTransitionAction(event, 0.08, function()
                    _G.appState = "ARCADE_MENU"
                    _G.arcade_selection = 1
                    renderer.setArcadeMenuOpen(true)
                end)
                return
            end

            local max_menu = _G.cheats_unlocked and 9 or 8
            if event == input.events.UP then
                menuSelection = menuSelection > 1 and (menuSelection - 1) or max_menu
            elseif event == input.events.DOWN then
                menuSelection = menuSelection < max_menu and (menuSelection + 1) or 1
            elseif event == input.events.CONFIRM then
                queueTransitionAction(event, 0.08, function()
                    if menuSelection == 1 then
                        _G.appState = "GAME"
                        game = Game.new("classic")
                    elseif menuSelection == 2 then
                        _G.appState = "GAME"
                        game = Game.new("plus")
                    elseif menuSelection == 3 then
                        _G.themeSelectPrevState = "MENU"
                        _G.themeSelectInitialTheme = _G.theme
                        _G.appState = "THEME_SELECT"
                    elseif menuSelection == 4 then
                        _G.appState = "ACHIEVEMENTS"
                    elseif menuSelection == 5 then
                        _G.appState = "TUTORIAL"
                        _G.tutorial_page = 1
                    else
                        if _G.cheats_unlocked then
                            if menuSelection == 6 then
                                if not _G.achievements.ach_secret_ascii then
                                    _G.achievements.ach_secret_ascii = true
                                    table.insert(_G.unlocked_themes, "ascii")
                                    save.saveAchievements(_G.achievements)
                                    renderer.showToast("Beep Boop! Cheater detected! Enjoy your punishment: the super-retro ASCII Art Theme!", 4.0)
                                end
                                _G.appState = "CHEATS_MENU"
                                _G.cheats_selection = 1
                            elseif menuSelection == 7 then
                                _G.text_size = (_G.text_size == "large") and "normal" or "large"
                                save.saveTextSize(_G.text_size)
                                renderer.init()
                                renderer.flashTextSize()
                            elseif menuSelection == 8 then
                                _G.appState = "ABOUT"
                            elseif menuSelection == 9 then
                                love.event.quit()
                            end
                        else
                            if menuSelection == 6 then
                                _G.text_size = (_G.text_size == "large") and "normal" or "large"
                                save.saveTextSize(_G.text_size)
                                renderer.init()
                                renderer.flashTextSize()
                            elseif menuSelection == 7 then
                                _G.appState = "ABOUT"
                            elseif menuSelection == 8 then
                                love.event.quit()
                            end
                        end
                    end
                end)
            end
            return
        elseif _G.appState == "ARCADE_MENU" then
            if arcade_menu_closing_action then return end
            local row = math.floor((_G.arcade_selection - 1) / 2) + 1
            local col = ((_G.arcade_selection - 1) % 2) + 1
            if event == input.events.UP then
                row = math.max(1, row - 1)
            elseif event == input.events.DOWN then
                row = math.min(2, row + 1)
            elseif event == input.events.LEFT then
                col = math.max(1, col - 1)
            elseif event == input.events.RIGHT then
                col = math.min(2, col + 1)
            elseif event == input.events.CONFIRM then
                queueTransitionAction(event, 0.08, function()
                    renderer.setArcadeMenuOpen(false)
                    arcade_menu_closing_action = function()
                        _G.appState = "GAME"
                        local mode = "timeattack"
                        if _G.arcade_selection == 2 then
                            mode = "huge"
                        elseif _G.arcade_selection == 3 then
                            mode = "nomercy"
                        elseif _G.arcade_selection == 4 then
                            mode = "goose"
                        end
                        game = Game.new(mode)
                    end
                end)
            elseif event == input.events.BACK or event == input.events.X then
                queueTransitionAction(event, 0.08, function()
                    renderer.setArcadeMenuOpen(false)
                    arcade_menu_closing_action = function()
                        _G.appState = "MENU"
                    end
                end)
            end
            _G.arcade_selection = (row - 1) * 2 + col
            return
        elseif _G.appState == "TUTORIAL" then
            if event == input.events.BACK then
                if (_G.tutorial_page or 1) > 1 then
                    _G.tutorial_page = _G.tutorial_page - 1
                else
                    queueTransitionAction(event, 0.08, function()
                        _G.appState = "MENU"
                    end)
                end
            elseif event == input.events.CONFIRM then
                if (_G.tutorial_page or 1) < 8 then
                    _G.tutorial_page = (_G.tutorial_page or 1) + 1
                else
                    queueTransitionAction(event, 0.08, function()
                        _G.appState = "MENU"
                    end)
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
        elseif _G.appState == "ABOUT" then
            if event == input.events.BACK or event == input.events.CONFIRM then
                queueTransitionAction(event, 0.08, function()
                    _G.appState = "MENU"
                end)
            end
            return
        elseif _G.appState == "ACHIEVEMENTS" then
            if event == input.events.BACK then
                queueTransitionAction(event, 0.08, function()
                    _G.appState = "MENU"
                    _G.achievements_scroll = 0
                    _G.achievements_scroll_target = 0
                end)
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
                local total_items = 19
                local total_height = total_items * item_h
                local max_scroll = math.max(0, math.ceil((total_height - visible_area) / item_h) + 1)
                _G.achievements_scroll_target = math.min(max_scroll, (_G.achievements_scroll_target or 0) + 1)
            end
            return
        elseif _G.appState == "CHEATS_MENU" then
            if event == input.events.BACK then
                queueTransitionAction(event, 0.08, function()
                    _G.appState = "MENU"
                end)
            elseif event == input.events.UP then
                _G.cheats_selection = _G.cheats_selection > 1 and (_G.cheats_selection - 1) or 9
            elseif event == input.events.DOWN then
                _G.cheats_selection = _G.cheats_selection < 9 and (_G.cheats_selection + 1) or 1
            elseif event == input.events.CONFIRM then
                if _G.cheats_selection == 1 then
                    for _, t in ipairs(renderer.getAllThemeNames()) do
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
                    _G.cheat_fill_24816 = not _G.cheat_fill_24816
                    if _G.cheat_fill_24816 then
                        renderer.showToast("Fill 2,4,8,16,32... is ON. Start a new game to see it.")
                    else
                        renderer.showToast("Fill 2,4,8,16,32... is OFF.")
                    end
                elseif _G.cheats_selection == 8 then
                    queueTransitionAction(event, 0.08, function()
                        _G.cheats_unlocked = false
                        save.saveCheats(false)
                        _G.appState = "MENU"
                        renderer.showToast("Cheats Locked. Enter the code to unlock again.", 4.0)
                    end)
                elseif _G.cheats_selection == 9 then
                    queueTransitionAction(event, 0.08, function()
                        _G.appState = "MENU"
                    end)
                end
            end
            return
        elseif _G.appState == "THEME_SELECT" then
            if event == input.events.CONFIRM then
                queueTransitionAction(event, 0.08, function()
                    save.saveTheme(_G.theme)
                    if game then game:saveGameState() end
                    _G.appState = _G.themeSelectPrevState or "MENU"
                end)
            elseif event == input.events.BACK then
                queueTransitionAction(event, 0.08, function()
                    _G.theme = _G.themeSelectInitialTheme or "light"
                    renderer.applyTheme()
                    _G.appState = _G.themeSelectPrevState or "MENU"
                end)
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
                    queueTransitionAction(event, 0.08, function()
                        game:startSwapTargeting()
                    end)
                end
            elseif event == input.events.R1 then
                if game.mode == "plus" and game.powerups.bomb <= 0 then
                    renderer.showToast("No Bomb Powerup!")
                else
                    queueTransitionAction(event, 0.08, function()
                        game:startBombTargeting()
                    end)
                end
            -- Undo
            elseif event == input.events.BACK then
                if game.mode == "timeattack" or game.mode == "nomercy" or game.mode == "goose" then
                    local modeName = "Time Attack"
                    if game.mode == "nomercy" then modeName = "No Mercy"
                    elseif game.mode == "goose" then modeName = "Goose Mode" end
                    renderer.showToast("No Undo in " .. modeName .. "!")
                elseif game.mode == "plus" and game.powerups.undo <= 0 then
                    renderer.showToast("No Undo Powerup!")
                else
                    queueTransitionAction(event, 0.08, function()
                        game:undo()
                    end)
                end
            -- Pause menu (select or start button)
            elseif event == input.events.SELECT or event == input.events.START then
                queueTransitionAction(event, 0.08, function()
                    game:togglePause()
                end)
            end
        elseif game.state == Game.STATE_PAUSED then
            if event == input.events.CONFIRM then
                queueTransitionAction(event, 0.08, function()
                    game:restart()
                end)
            elseif event == input.events.BACK or event == input.events.SELECT or event == input.events.START then
                queueTransitionAction(event, 0.08, function()
                    game:cancelPause()
                end)
            elseif event == input.events.X then
                queueTransitionAction(event, 0.08, function()
                    local is_arcade = game and (game.mode == "timeattack" or game.mode == "huge" or game.mode == "nomercy" or game.mode == "goose")
                    local arcade_idx = 1
                    if game then
                        if game.mode == "huge" then arcade_idx = 2
                        elseif game.mode == "nomercy" then arcade_idx = 3
                        elseif game.mode == "goose" then arcade_idx = 4 end
                        game:saveGameState()
                    end
                    if is_arcade then
                        _G.appState = "ARCADE_MENU"
                        _G.arcade_selection = arcade_idx
                        renderer.setArcadeMenuOpen(true)
                    else
                        _G.appState = "MENU"
                    end
                    game = nil
                end)
            end
        elseif game.state == Game.STATE_WON then
            if event == input.events.CONFIRM then
                queueTransitionAction(event, 0.08, function()
                    game:continueGame()
                end)
            elseif event == input.events.BACK then
                if game.mode == "timeattack" or game.mode == "nomercy" or game.mode == "goose" then
                    local modeName = "Time Attack"
                    if game.mode == "nomercy" then modeName = "No Mercy"
                    elseif game.mode == "goose" then modeName = "Goose Mode" end
                    renderer.showToast("No Undo in " .. modeName .. "!")
                else
                    queueTransitionAction(event, 0.08, function()
                        game:undo()
                    end)
                end
            elseif event == input.events.SELECT then
                queueTransitionAction(event, 0.08, function()
                    game:restart()
                end)
            elseif event == input.events.X then
                queueTransitionAction(event, 0.08, function()
                    local is_arcade = game and (game.mode == "timeattack" or game.mode == "huge" or game.mode == "nomercy" or game.mode == "goose")
                    local arcade_idx = 1
                    if game then
                        if game.mode == "huge" then arcade_idx = 2
                        elseif game.mode == "nomercy" then arcade_idx = 3
                        elseif game.mode == "goose" then arcade_idx = 4 end
                        game:saveGameState()
                    end
                    if is_arcade then
                        _G.appState = "ARCADE_MENU"
                        _G.arcade_selection = arcade_idx
                        renderer.setArcadeMenuOpen(true)
                    else
                        _G.appState = "MENU"
                    end
                    game = nil
                end)
            end
        elseif game.state == Game.STATE_LOST then
            if event == input.events.CONFIRM or event == input.events.SELECT then
                queueTransitionAction(event, 0.08, function()
                    game:restart()
                end)
            elseif event == input.events.BACK then
                if game.mode == "timeattack" or game.mode == "nomercy" or game.mode == "goose" then
                    local modeName = "Time Attack"
                    if game.mode == "nomercy" then modeName = "No Mercy"
                    elseif game.mode == "goose" then modeName = "Goose Mode" end
                    renderer.showToast("No Undo in " .. modeName .. "!")
                else
                    queueTransitionAction(event, 0.08, function()
                        game:undo()
                    end)
                end
            elseif event == input.events.X then
                queueTransitionAction(event, 0.08, function()
                    local is_arcade = game and (game.mode == "timeattack" or game.mode == "huge" or game.mode == "nomercy" or game.mode == "goose")
                    local arcade_idx = 1
                    if game then
                        if game.mode == "huge" then arcade_idx = 2
                        elseif game.mode == "nomercy" then arcade_idx = 3
                        elseif game.mode == "goose" then arcade_idx = 4 end
                        game:saveGameState()
                    end
                    if is_arcade then
                        _G.appState = "ARCADE_MENU"
                        _G.arcade_selection = arcade_idx
                        renderer.setArcadeMenuOpen(true)
                    else
                        _G.appState = "MENU"
                    end
                    game = nil
                end)
            end
        end
    end)
end

drawCurrentScreen = function()
    if _G.appState == "MENU" then
        renderer.drawMainMenu(menuSelection)
    elseif _G.appState == "ARCADE_MENU" then
        renderer.drawArcadeMenu(_G.arcade_selection or 1, false, menuSelection)
    elseif _G.appState == "TUTORIAL" then
        renderer.drawTutorial(_G.tutorial_page or 1)
    elseif _G.appState == "ABOUT" then
        renderer.drawAbout()
    elseif _G.appState == "CHEATS_MENU" then
        renderer.drawCheatsMenu(_G.cheats_selection or 1)
    elseif _G.appState == "ACHIEVEMENTS" then
        renderer.drawAchievements(_G.achievements_scroll or 0)
    elseif _G.appState == "THEME_SELECT" then
        renderer.drawThemeSelect()
    elseif _G.appState == "GAME" and game then
        renderer.draw(game)
    end
end

function love.draw()
    if not splash.finished then
        splash.draw()
        return
    end

    if screen_transition_timer > 0 then
        local w, h = love.graphics.getDimensions()
        if not screen_canvas then
            screen_canvas = love.graphics.newCanvas(w, h)
        end

        -- Draw the NEW (incoming) screen to screen_canvas
        love.graphics.setCanvas({screen_canvas, stencil = true})
        love.graphics.clear()
        drawCurrentScreen()
        love.graphics.setCanvas()

        -- Cubic ease-out progress  (0 → 1)
        local t_progress = 1 - (screen_transition_timer / screen_transition_duration)
        local p = 1 - math.pow(1 - t_progress, 3)  -- ease-out cubic

        local dir = transition_direction  -- +1 or -1

        -- New screen: slides in from off-screen (dir=+1 → from right; dir=-1 → from left)
        local new_x = dir * w * (1 - p)
        -- Old screen: slides out to the opposite side, at half speed (parallax feel)
        local old_x = -dir * w * 0.35 * p

        -- Draw background fill to avoid any gaps
        love.graphics.clear(0.05, 0.05, 0.08, 1.0)

        -- Draw old screen sliding out (with slight fade-out)
        if old_screen_canvas then
            love.graphics.setColor(1, 1, 1, 1 - p * 0.4)
            love.graphics.draw(old_screen_canvas, math.floor(old_x), 0)
        end

        -- Draw new screen sliding in
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(screen_canvas, math.floor(new_x), 0)

        love.graphics.setColor(1, 1, 1, 1)
    else
        drawCurrentScreen()
    end
end
