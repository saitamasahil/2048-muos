-- High score persistence (file-based)

local save = {}

local SAVE_DIR = ""
local SAVE_FILE = "highscore.dat"
local STATE_FILE = "gamestate.dat"

function save.init(dir)
    SAVE_DIR = dir or ""
    -- Ensure directory exists
    if SAVE_DIR ~= "" then
        os.execute('mkdir -p "' .. SAVE_DIR .. '"')
    end
end

function save.getPath()
    if SAVE_DIR ~= "" then
        return SAVE_DIR .. "/" .. SAVE_FILE
    end
    return SAVE_FILE
end

function save.getStatePath()
    if SAVE_DIR ~= "" then
        return SAVE_DIR .. "/" .. STATE_FILE
    end
    return STATE_FILE
end

function save.loadHighScore()
    local path = save.getPath()
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

function save.saveHighScore(score)
    local path = save.getPath()
    local file = io.open(path, "w")
    if file then
        file:write(tostring(math.floor(score)))
        file:close()
    end
end

function save.saveState(state)
    local path = save.getStatePath()
    local file = io.open(path, "w")
    if file then
        local function serialize(o)
            if type(o) == "number" or type(o) == "boolean" then
                return tostring(o)
            elseif type(o) == "string" then
                return string.format("%q", o)
            elseif type(o) == "table" then
                local s = "{"
                for k, v in pairs(o) do
                    if type(k) == "number" then
                        s = s .. "[" .. k .. "]=" .. serialize(v) .. ","
                    else
                        -- Ensure keys are valid lua identifiers
                        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                            s = s .. k .. "=" .. serialize(v) .. ","
                        else
                            s = s .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ","
                        end
                    end
                end
                return s .. "}"
            else
                return "nil"
            end
        end
        file:write("return " .. serialize(state))
        file:close()
    end
end

function save.loadState()
    local path = save.getStatePath()
    local file = io.open(path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        if content and content ~= "" then
            local f = loadstring and loadstring(content) or load(content)
            if f then
                -- Run in empty env for safety (Lua 5.1/LuaJIT compatible)
                if setfenv then setfenv(f, {}) end
                local success, result = pcall(f)
                if success and type(result) == "table" then
                    return result
                end
            end
        end
    end
    return nil
end

function save.clearState()
    local path = save.getStatePath()
    os.remove(path)
end

return save
