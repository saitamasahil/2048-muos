local socket = require("socket")


local server = {}

local tcp_server = nil
local port = 8080

local MIME_TYPES = {
    html = "text/html",
    js = "application/javascript",
    wasm = "application/wasm",
    css = "text/css",
    png = "image/png",
    data = "application/octet-stream",
    json = "application/json"
}

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*all")
    f:close()
    return content
end

local function sendResponse(client, status_code, status_text, content_type, body)
    local res = "HTTP/1.1 " .. status_code .. " " .. status_text .. "\r\n"
    res = res .. "Content-Type: " .. content_type .. "\r\n"
    res = res .. "Content-Length: " .. (body and #body or 0) .. "\r\n"
    res = res .. "Connection: close\r\n\r\n"
    if body then
        res = res .. body
    end
    client:send(res)
end

function server.start()
    tcp_server = socket.bind("*", port)
    if not tcp_server then return false end
    tcp_server:settimeout(0)
    return true
end

function server.stop()
    if tcp_server then
        tcp_server:close()
        tcp_server = nil
    end
end

function server.isActive()
    return tcp_server ~= nil
end

function server.getLocalIP()
    local udp = socket.udp()
    udp:setpeername("8.8.8.8", 80)
    local ip, _ = udp:getsockname()
    udp:close()
    return ip or "0.0.0.0"
end

function server.hasNetwork()
    local ip = server.getLocalIP()
    return ip ~= nil and ip ~= "0.0.0.0" and ip ~= ""
end

function server.getPort()
    return port
end

function server.update()
    if not tcp_server then return end

    local ready = socket.select({tcp_server}, nil, 0.01)
    if ready and #ready > 0 then
        local client = tcp_server:accept()
        if client then
            client:settimeout(1) -- Short timeout for request parsing

            local request, err = client:receive("*l")
            if not err and request then
                local method, path = request:match("^(%u+)%s+(%S+)%s+HTTP")

                local content_length = 0
                while true do
                    local header, herr = client:receive("*l")
                    if herr or not header or header == "" then break end
                    local k, v = header:match("^(%S-):%s*(.*)")
                    if k and k:lower() == "content-length" then
                        content_length = tonumber(v) or 0
                    end
                end

                if method == "GET" then
                    if path == "/api/sync" then
                        -- Package all save files from static/
                        local files = {
                            "highscore.dat", "highscore_plus.dat", "highscore_timeattack.dat",
                            "highscore_huge.dat", "highscore_nomercy.dat", "highscore_goose.dat", "highscore_tiny.dat",
                            "theme.dat", "achievements.dat", "cheats.dat", "text_size.dat",
                            "gamestate.dat", "gamestate_plus.dat", "gamestate_timeattack.dat",
                            "gamestate_huge.dat", "gamestate_nomercy.dat", "gamestate_goose.dat", "gamestate_tiny.dat"
                        }

                        local response_map = {}
                        for _, file in ipairs(files) do
                            local content = readFile((_G.WORK_DIR and _G.WORK_DIR .. "/static/" or "static/") .. file)
                            if content then
                                response_map[file] = content
                            end
                        end

                        local json = "{"
                        local first = true
                        for k, v in pairs(response_map) do
                            if not first then json = json .. "," end
                            v = v:gsub('"', '\\"'):gsub('\n', '\\n')
                            json = json .. '"' .. k .. '":"' .. v .. '"'
                            first = false
                        end
                        json = json .. "}"

                        sendResponse(client, 200, "OK", "application/json", json)

                    else
                        if path == "/" then path = "/index.html" end
                        path = path:gsub("%?.*", "")

                        -- Prevent directory traversal
                        local safe_path = path:gsub("%.%.", "")
                        local full_path = (_G.WORK_DIR and _G.WORK_DIR .. "/static/webgame" or "static/webgame") .. safe_path

                        local ext = safe_path:match("%.([^%.]+)$")
                        local mime = MIME_TYPES[ext] or "application/octet-stream"

                        local content = readFile(full_path)
                        if content then
                            sendResponse(client, 200, "OK", mime, content)
                        else
                            sendResponse(client, 404, "Not Found", "text/plain", "File not found")
                        end
                    end
                elseif method == "POST" and path == "/api/sync" then
                    if content_length > 0 then
                        local body, berr = client:receive(content_length)
                        if body and not berr then
                            -- Parse basic JSON manually
                            for k, v in body:gmatch('"([^"]+)":"([^"]*)"') do
                                v = v:gsub('\\n', '\n'):gsub('\\"', '"')
                                local path = (_G.WORK_DIR and _G.WORK_DIR .. "/static/" or "static/") .. k
                                local f = io.open(path, "w")
                                if f then
                                    f:write(v)
                                    f:close()
                                end
                            end
                            sendResponse(client, 200, "OK", "application/json", '{"status":"ok"}')
                        else
                            sendResponse(client, 400, "Bad Request", "application/json", '{"error":"Failed to read body"}')
                        end
                    else
                        sendResponse(client, 400, "Bad Request", "application/json", '{"error":"No content length"}')
                    end
                elseif method == "POST" and path == "/api/stop" then
                    sendResponse(client, 200, "OK", "application/json", '{"status":"stopped"}')
                    love.event.quit()
                else
                    sendResponse(client, 405, "Method Not Allowed", "text/plain", "Method not allowed")
                end
            end
            client:close()
        end
    end
end

return server
