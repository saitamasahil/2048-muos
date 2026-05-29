local f = io.open("renderer.lua", "r")
local content = f:read("*a")
f:close()

local start_idx = content:find("local themes = {")
local end_idx = content:find("local tile_colors", start_idx)
local themes_str = content:sub(start_idx, end_idx - 1)

local get_l = function(r, g, b)
    return 0.299 * r + 0.587 * g + 0.114 * b
end

local func = load("local function hex(h) h=h:gsub('#','') return {tonumber(h:sub(1,2),16)/255, tonumber(h:sub(3,4),16)/255, tonumber(h:sub(5,6),16)/255} end\n" .. themes_str .. "\nreturn themes")
local th = func()

for name, t in pairs(th) do
    print("Theme: " .. name)
    local vals = {2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048}
    local prev_l = nil
    local dir = nil
    for _, v in ipairs(vals) do
        local color = t.tile_colors[v][1] -- unpack
        if color then
            local l = get_l(color[1], color[2], color[3])
            local note = ""
            if prev_l then
                if dir == nil then
                    if math.abs(l - prev_l) > 0.001 then
                        dir = (l > prev_l) and 1 or -1
                    end
                else
                    if dir == 1 and l < prev_l - 0.001 then note = "<-- BUMP DOWN!" end
                    if dir == -1 and l > prev_l + 0.001 then note = "<-- BUMP UP!" end
                end
            end
            print(string.format("  %-4d : (L=%.3f) %s", v, l, note))
            prev_l = l
        end
    end
end
