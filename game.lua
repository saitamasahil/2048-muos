-- Core 2048 Game Logic
-- Ported from MainGame.java

local Grid = require("grid")
local Tile = require("tile")
local save = require("save")

local Game = {}
Game.__index = Game

-- Game states
Game.STATE_PLAYING  = 0
Game.STATE_WON      = 1
Game.STATE_LOST     = 2
Game.STATE_ENDLESS  = 3   -- Continuing after winning
Game.STATE_PAUSED   = 4 -- Confirming accidental restart

-- Direction constants: 0=up, 1=right, 2=down, 3=left
Game.DIR_UP    = 0
Game.DIR_RIGHT = 1
Game.DIR_DOWN  = 2
Game.DIR_LEFT  = 3

-- Direction vectors (dx, dy)
local vectors = {
    [0] = {x =  0, y = -1},  -- up
    [1] = {x =  1, y =  0},  -- right
    [2] = {x =  0, y =  1},  -- down
    [3] = {x = -1, y =  0},  -- left
}

function Game.new()
    local self = setmetatable({}, Game)
    self.size = 4
    self.grid = Grid.new(self.size, self.size)
    self.score = 0
    self.highScore = save.loadHighScore()
    self.state = Game.STATE_PLAYING
    self.won = false
    self.moved = false

    -- Undo state
    self.undoState = nil
    self.undoScore = 0
    self.canUndo = false

    -- Animation tracking
    self.animationTimer = 0
    self.animationDuration = 0.12  -- seconds

    -- Try to load saved game state
    local savedState = save.loadState()
    if savedState and savedState.gridState then
        self.score = savedState.score or 0
        self.state = savedState.state or Game.STATE_PLAYING
        self.won = savedState.won or false
        self.canUndo = savedState.canUndo or false
        self.undoScore = savedState.undoScore or 0
        self.grid:restoreState(savedState.gridState)
        if savedState.undoState then
            self.undoState = savedState.undoState
        end
        if savedState.theme then
            _G.theme = savedState.theme
        end
    else
        -- Start a fresh game if no save state exists
        self:addStartTiles()
        if savedState and savedState.theme then
            _G.theme = savedState.theme
        end
    end

    return self
end

function Game:saveGameState()
    local stateTable = {
        score = self.score,
        state = self.state,
        won = self.won,
        canUndo = self.canUndo,
        undoScore = self.undoScore,
        gridState = self.grid:saveState(),
        undoState = self.undoState,
        theme = _G.theme
    }
    save.saveState(stateTable)
end

function Game:addStartTiles()
    for _ = 1, 2 do
        self:addRandomTile()
    end
end

function Game:addRandomTile()
    if self.grid:cellsAvailable() then
        local value = math.random() < 0.9 and 2 or 4
        local cell = self.grid:randomAvailableCell()
        if cell then
            local tile = Tile.new(cell.x, cell.y, value)
            tile.isNew = true
            self.grid:insertTile(tile)
        end
    end
end

function Game:prepareTiles()
    self.grid:eachCell(function(x, y, tile)
        if tile then
            tile.mergedFrom = nil
            tile.isNew = false
            tile.isMerged = false
            tile:savePosition()
        end
    end)
end

function Game:moveTile(tile, x, y)
    self.grid.cells[tile.x][tile.y] = nil
    tile:setPosition(x, y)
    self.grid.cells[x][y] = tile
end

-- Build traversal order based on direction
function Game:buildTraversals(direction)
    local traversalsX = {}
    local traversalsY = {}

    for i = 1, self.size do
        table.insert(traversalsX, i)
        table.insert(traversalsY, i)
    end

    -- If moving right, traverse right-to-left
    if vectors[direction].x == 1 then
        local reversed = {}
        for i = #traversalsX, 1, -1 do
            table.insert(reversed, traversalsX[i])
        end
        traversalsX = reversed
    end

    -- If moving down, traverse bottom-to-top
    if vectors[direction].y == 1 then
        local reversed = {}
        for i = #traversalsY, 1, -1 do
            table.insert(reversed, traversalsY[i])
        end
        traversalsY = reversed
    end

    return traversalsX, traversalsY
end

-- Find the farthest position a tile can move to
function Game:findFarthestPosition(x, y, direction)
    local vec = vectors[direction]
    local prevX, prevY = x, y
    local nextX, nextY = x + vec.x, y + vec.y

    while self.grid:withinBounds(nextX, nextY) and self.grid:cellAvailable(nextX, nextY) do
        prevX, prevY = nextX, nextY
        nextX = nextX + vec.x
        nextY = nextY + vec.y
    end

    return prevX, prevY, nextX, nextY
end

function Game:move(direction)
    if self.state == Game.STATE_LOST or self.state == Game.STATE_WON then
        return false
    end

    -- Save undo state before the move
    self.undoState = self.grid:saveState()
    self.undoScore = self.score

    local traversalsX, traversalsY = self:buildTraversals(direction)
    local moved = false

    self:prepareTiles()

    for _, x in ipairs(traversalsX) do
        for _, y in ipairs(traversalsY) do
            local tile = self.grid:cellContent(x, y)
            if tile then
                local farthestX, farthestY, nextX, nextY = self:findFarthestPosition(x, y, direction)
                local nextTile = self.grid:cellContent(nextX, nextY)

                -- Can we merge with the next tile?
                if nextTile and nextTile.value == tile.value and nextTile.mergedFrom == nil then
                    -- Merge!
                    local merged = Tile.new(nextX, nextY, tile.value * 2)
                    merged.mergedFrom = {tile, nextTile}
                    merged.isMerged = true
                    merged.previousPosition = {x = tile.x, y = tile.y}

                    self.grid:insertTile(merged)
                    self.grid:removeTile(tile)

                    -- Update score
                    self.score = self.score + merged.value
                    if self.score > self.highScore then
                        self.highScore = self.score
                        save.saveHighScore(self.highScore)
                    end

                    -- Check for win (2048 tile!)
                    if merged.value == 2048 and self.state == Game.STATE_PLAYING then
                        self.state = Game.STATE_WON
                        self.won = true
                    end

                    moved = true
                else
                    -- Just move to farthest available position
                    if farthestX ~= x or farthestY ~= y then
                        self:moveTile(tile, farthestX, farthestY)
                        moved = true
                    end
                end
            end
        end
    end

    if moved then
        self.canUndo = true
        self:addRandomTile()
        self.animationTimer = self.animationDuration

        -- Check for loss
        if not self:movesAvailable() then
            self.state = Game.STATE_LOST
        end
    end

    self.moved = moved
    self:saveGameState()
    return moved
end

function Game:movesAvailable()
    if self.grid:cellsAvailable() then
        return true
    end

    -- Check if any adjacent tiles can merge
    for x = 1, self.size do
        for y = 1, self.size do
            local tile = self.grid:cellContent(x, y)
            if tile then
                for dir = 0, 3 do
                    local vec = vectors[dir]
                    local nx, ny = x + vec.x, y + vec.y
                    local other = self.grid:cellContent(nx, ny)
                    if other and other.value == tile.value then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function Game:undo()
    if self.canUndo and self.undoState then
        -- Snapshot the current tiles before restoring the old grid
        local current_cells = {}
        for x = 1, self.size do
            current_cells[x] = {}
            for y = 1, self.size do
                current_cells[x][y] = self.grid.cells[x][y]
            end
        end

        self.grid:restoreState(self.undoState)
        self.score = self.undoScore
        self.canUndo = false

        -- Reset game state if we were lost/won
        if self.state == Game.STATE_LOST then
            self.state = Game.STATE_PLAYING
        elseif self.state == Game.STATE_WON then
            self.state = Game.STATE_PLAYING
            self.won = false
        end

        -- Clear animation states
        self.grid:eachCell(function(x, y, tile)
            if tile then
                tile.isNew = false
                tile.isMerged = false
                tile.previousPosition = nil
                tile.mergedFrom = nil
            end
        end)

        -- Apply reverse animation data
        for x = 1, self.size do
            for y = 1, self.size do
                local c_tile = current_cells[x][y]
                if c_tile then
                    if c_tile.isMerged and c_tile.mergedFrom then
                        local t1 = c_tile.mergedFrom[1]
                        local t2 = c_tile.mergedFrom[2]
                        if t1 and t1.previousPosition then
                            local r_t1 = self.grid:cellContent(t1.previousPosition.x, t1.previousPosition.y)
                            if r_t1 then r_t1.previousPosition = {x = x, y = y} end
                        end
                        if t2 and t2.previousPosition then
                            local r_t2 = self.grid:cellContent(t2.previousPosition.x, t2.previousPosition.y)
                            if r_t2 then r_t2.previousPosition = {x = x, y = y} end
                        end
                    elseif not c_tile.isNew then
                        if c_tile.previousPosition then
                            local r_t = self.grid:cellContent(c_tile.previousPosition.x, c_tile.previousPosition.y)
                            if r_t then r_t.previousPosition = {x = x, y = y} end
                        end
                    end
                end
            end
        end

        -- Trigger animation timer
        self.animationTimer = self.animationDuration

        self:saveGameState()
    end
end

function Game:continueGame()
    -- Continue playing after winning (endless mode)
    if self.state == Game.STATE_WON then
        self.state = Game.STATE_ENDLESS
        self:saveGameState()
    end
end

function Game:restart()
    self.grid:clear()
    self.score = 0
    self.state = Game.STATE_PLAYING
    self.won = false
    self.canUndo = false
    self.undoState = nil
    self.animationTimer = 0
    self:addStartTiles()
    self:saveGameState()
end

function Game:togglePause()
    if self.state == Game.STATE_PLAYING or self.state == Game.STATE_ENDLESS then
        self.prevState = self.state
        self.state = Game.STATE_PAUSED
    elseif self.state == Game.STATE_PAUSED then
        self.state = self.prevState or Game.STATE_PLAYING
    else
        self:restart()
    end
end

function Game:cancelPause()
    if self.state == Game.STATE_PAUSED then
        self.state = self.prevState or Game.STATE_PLAYING
    end
end

function Game:update(dt)
    if self.animationTimer > 0 then
        self.animationTimer = self.animationTimer - dt
        if self.animationTimer < 0 then
            self.animationTimer = 0
        end
    end
end

function Game:getAnimationProgress()
    if self.animationDuration <= 0 then return 1 end
    return 1 - (self.animationTimer / self.animationDuration)
end

function Game:isAnimating()
    return self.animationTimer > 0
end

function Game:isPlaying()
    return self.state == Game.STATE_PLAYING or self.state == Game.STATE_ENDLESS
end

return Game
