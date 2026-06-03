-- High score persistence (file-based)

local save = {}

local SAVE_DIR = ""
local SAVE_FILE = "highscore.dat"
local STATE_FILE = "gamestate.dat"
local ACHIEVEMENTS_FILE = "achievements.dat"
local THEME_FILE = "theme.dat"

function save.init(dir)
    SAVE_DIR = dir or ""
    -- Ensure directory exists
    if SAVE_DIR ~= "" then
        os.execute('mkdir -p "' .. SAVE_DIR .. '"')
    end
end

function save.getPath(mode)
    local file
    if mode == "plus" then
        file = "highscore_plus.dat"
    elseif mode == "timeattack" then
        file = "highscore_timeattack.dat"
    else
        file = SAVE_FILE  -- classic
    end
    if SAVE_DIR ~= "" then
        return SAVE_DIR .. "/" .. file
    end
    return file
end

function save.getStatePath(mode)
    local file
    if mode == "plus" then
        file = "gamestate_plus.dat"
    elseif mode == "timeattack" then
        file = "gamestate_timeattack.dat"
    else
        file = STATE_FILE  -- classic
    end
    if SAVE_DIR ~= "" then
        return SAVE_DIR .. "/" .. file
    end
    return file
end

function save.getAchievementsPath()
    if SAVE_DIR ~= "" then
        return SAVE_DIR .. "/" .. ACHIEVEMENTS_FILE
    end
    return ACHIEVEMENTS_FILE
end

function save.saveTheme(themeName)
    local path = SAVE_DIR ~= "" and (SAVE_DIR .. "/" .. THEME_FILE) or THEME_FILE
    local file = io.open(path, "w")
    if file then
        file:write(themeName)
        file:close()
    end
end

function save.loadTheme()
    local path = SAVE_DIR ~= "" and (SAVE_DIR .. "/" .. THEME_FILE) or THEME_FILE
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if content and content ~= "" then
            return content
        end
    end
    return nil
end

local TEXT_SIZE_FILE = "text_size.dat"

function save.saveTextSize(size)
    local path = SAVE_DIR ~= "" and (SAVE_DIR .. "/" .. TEXT_SIZE_FILE) or TEXT_SIZE_FILE
    local file = io.open(path, "w")
    if file then
        file:write(size)
        file:close()
    end
end

function save.loadTextSize()
    local path = SAVE_DIR ~= "" and (SAVE_DIR .. "/" .. TEXT_SIZE_FILE) or TEXT_SIZE_FILE
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if content and content ~= "" then
            return content
        end
    end
    return "normal"
end

local CHEATS_FILE = "cheats.dat"

function save.saveCheats(unlocked)
    local path = SAVE_DIR ~= "" and (SAVE_DIR .. "/" .. CHEATS_FILE) or CHEATS_FILE
    local file = io.open(path, "w")
    if file then
        file:write(unlocked and "1" or "0")
        file:close()
    end
end

function save.loadCheats()
    local path = SAVE_DIR ~= "" and (SAVE_DIR .. "/" .. CHEATS_FILE) or CHEATS_FILE
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content == "1"
    end
    return false
end

function save.loadHighScore(mode)
    local path = save.getPath(mode)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local score = tonumber(content)
        if score then
            return score
        end
    end
    return 0
end

function save.saveHighScore(score, mode)
    local path = save.getPath(mode)
    local file = io.open(path, "w")
    if file then
        file:write(tostring(math.floor(score)))
        file:close()
    end
end

function save.loadAchievements()
    local path = save.getAchievementsPath()
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        -- Use basic load implementation to parse serialized table
        local chunk = load(content)
        if chunk then
            return chunk()
        end
    end
    return nil
end

function save.saveAchievements(achievements)
    local path = save.getAchievementsPath()
    local file = io.open(path, "w")
    if file then
        local function serialize(o)
            if type(o) == "number" then
                return tostring(o)
            elseif type(o) == "string" then
                return string.format("%q", o)
            elseif type(o) == "boolean" then
                return tostring(o)
            elseif type(o) == "table" then
                local s = "{"
                for k, v in pairs(o) do
                    local key = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
                    s = s .. key .. "=" .. serialize(v) .. ","
                end
                return s .. "}"
            end
            return "nil"
        end
        file:write("return " .. serialize(achievements))
        file:close()
    end
end

function save.saveState(state, mode)
    local path = save.getStatePath(mode)
    local file = io.open(path, "w")
    if file then
        local function serialize(o)
            if type(o) == "number" then
                return tostring(o)
            elseif type(o) == "string" then
                return string.format("%q", o)
            elseif type(o) == "boolean" then
                return tostring(o)
            elseif type(o) == "table" then
                local s = "{"
                for k, v in pairs(o) do
                    -- Skip mixed tables or complex keys for simplicity, assume string or number keys
                    local key = type(k) == "string" and string.format("[%q]", k) or "[" .. tostring(k) .. "]"
                    s = s .. key .. "=" .. serialize(v) .. ","
                end
                return s .. "}"
            end
            return "nil"
        end

        file:write("return " .. serialize(state))
        file:close()
    end
end

function save.loadState(mode)
    local path = save.getStatePath(mode)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        -- Warning: load() evaluates the string. In a real environment, you'd use a safe JSON parser
        -- But for a local game save, this works as long as the file isn't tampered with maliciously.
        local chunk = load(content)
        if chunk then
            return chunk()
        end
    end
    return nil
end

function save.clearState(mode)
    local path = save.getStatePath(mode)
    os.remove(path)
end

return save
