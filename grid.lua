-- Grid management
-- Ported from Grid.java

local Tile = require("tile")

local Grid = {}
Grid.__index = Grid

function Grid.new(sizeX, sizeY)
    local self = setmetatable({}, Grid)
    self.sizeX = sizeX or 4
    self.sizeY = sizeY or 4
    self.cells = {}
    self:clear()
    return self
end

function Grid:clear()
    self.cells = {}
    for x = 1, self.sizeX do
        self.cells[x] = {}
        for y = 1, self.sizeY do
            self.cells[x][y] = nil
        end
    end
end

function Grid:getAvailableCells()
    local available = {}
    for x = 1, self.sizeX do
        for y = 1, self.sizeY do
            if self.cells[x][y] == nil then
                table.insert(available, {x = x, y = y})
            end
        end
    end
    return available
end

function Grid:randomAvailableCell()
    local cells = self:getAvailableCells()
    if #cells > 0 then
        return cells[math.random(#cells)]
    end
    return nil
end

function Grid:cellsAvailable()
    return #self:getAvailableCells() > 0
end

function Grid:cellAvailable(x, y)
    return self:withinBounds(x, y) and self.cells[x][y] == nil
end

function Grid:cellOccupied(x, y)
    return self:withinBounds(x, y) and self.cells[x][y] ~= nil
end

function Grid:cellContent(x, y)
    if self:withinBounds(x, y) then
        return self.cells[x][y]
    end
    return nil
end

function Grid:withinBounds(x, y)
    return x >= 1 and x <= self.sizeX and y >= 1 and y <= self.sizeY
end

function Grid:insertTile(tile)
    self.cells[tile.x][tile.y] = tile
end

function Grid:removeTile(tile)
    self.cells[tile.x][tile.y] = nil
end

-- Save current state for undo
function Grid:saveState()
    local state = {}
    for x = 1, self.sizeX do
        state[x] = {}
        for y = 1, self.sizeY do
            local tile = self.cells[x][y]
            if tile then
                state[x][y] = {value = tile.value}
            else
                state[x][y] = nil
            end
        end
    end
    return state
end

-- Restore from saved state
function Grid:restoreState(state)
    for x = 1, self.sizeX do
        for y = 1, self.sizeY do
            if state[x][y] then
                self.cells[x][y] = Tile.new(x, y, state[x][y].value)
            else
                self.cells[x][y] = nil
            end
        end
    end
end

-- Iterate over all tiles (for rendering)
function Grid:eachCell(callback)
    for x = 1, self.sizeX do
        for y = 1, self.sizeY do
            callback(x, y, self.cells[x][y])
        end
    end
end

return Grid
