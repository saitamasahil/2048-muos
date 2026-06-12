local sound = {}
local save = require("save")

local enabled = true
local achSource = nil
local splashSource = nil
local victorySource = nil
local gameOverSource = nil
local menuMoveSource = nil
local menuSelectSource = nil
local menuBackSource = nil

local function triangle(phase)
    local p = phase - math.floor(phase)
    if p < 0.25 then
        return 4 * p
    elseif p < 0.75 then
        return 2 - 4 * p
    else
        return 4 * p - 4
    end
end

function sound.init()
    enabled = save.loadSound()

    -- Pre-generate the sounds so they are ready to play instantly
    if love.sound and love.audio then
        local sampleRate = 44100

        -- 1. Achievement Sound (Retro Arpeggio)
        local achDuration = 0.6
        local achLength = math.floor(sampleRate * achDuration)
        local achSoundData = love.sound.newSoundData(achLength, sampleRate, 16, 1)
        local phase = 0
        for i = 0, achLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.08 then
                freq = 523.25 -- C5
                env = math.exp(-15 * t)
            elseif t < 0.16 then
                freq = 659.25 -- E5
                env = math.exp(-15 * (t - 0.08))
            elseif t < 0.24 then
                freq = 783.99 -- G5
                env = math.exp(-15 * (t - 0.16))
            else
                freq = 1046.50 -- C6
                env = math.exp(-6 * (t - 0.24))
            end
            phase = phase + freq / sampleRate
            local val = triangle(phase) * env * 0.4
            achSoundData:setSample(i, val)
        end
        achSource = love.audio.newSource(achSoundData)

        -- 2. Splash Sound (Warm Synth Chord)
        local splashDuration = 2.0
        local splashLength = math.floor(sampleRate * splashDuration)
        local splashSoundData = love.sound.newSoundData(splashLength, sampleRate, 16, 1)
        local freqs = { 130.81, 196.00, 261.63, 293.66, 329.63, 392.00, 493.88 }
        for i = 0, splashLength - 1 do
            local t = i / sampleRate
            local env
            if t < 0.4 then
                env = t / 0.4
            else
                env = math.max(0, 1 - (t - 0.4) / (splashDuration - 0.4))
            end
            local val = 0
            for _, f in ipairs(freqs) do
                val = val + math.sin(2 * math.pi * f * t)
            end
            val = (val / #freqs) * env * 0.4
            splashSoundData:setSample(i, val)
        end
        splashSource = love.audio.newSource(splashSoundData)

        -- 3. Victory Sound (Triumphant Ascending Fanfare)
        local victoryDuration = 1.0
        local victoryLength = math.floor(sampleRate * victoryDuration)
        local victorySoundData = love.sound.newSoundData(victoryLength, sampleRate, 16, 1)
        local vPhase = 0
        for i = 0, victoryLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.07 then
                freq = 523.25 -- C5
                env = math.exp(-15 * t)
            elseif t < 0.14 then
                freq = 659.25 -- E5
                env = math.exp(-15 * (t - 0.07))
            elseif t < 0.21 then
                freq = 783.99 -- G5
                env = math.exp(-15 * (t - 0.14))
            elseif t < 0.28 then
                freq = 1046.50 -- C6
                env = math.exp(-15 * (t - 0.21))
            elseif t < 0.35 then
                freq = 1318.51 -- E6
                env = math.exp(-15 * (t - 0.28))
            elseif t < 0.42 then
                freq = 1567.98 -- G6
                env = math.exp(-15 * (t - 0.35))
            else
                freq = 2093.00 -- C7
                env = math.exp(-5 * (t - 0.42))
            end
            vPhase = vPhase + freq / sampleRate
            local val = triangle(vPhase) * env * 0.4
            victorySoundData:setSample(i, val)
        end
        victorySource = love.audio.newSource(victorySoundData)

        -- 4. Game Over Sound (Melancholic Descending Cadence)
        local gameOverDuration = 0.8
        local gameOverLength = math.floor(sampleRate * gameOverDuration)
        local gameOverSoundData = love.sound.newSoundData(gameOverLength, sampleRate, 16, 1)
        local goPhase = 0
        for i = 0, gameOverLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.2 then
                freq = 130.81 -- C3
                env = math.exp(-8 * t)
            elseif t < 0.4 then
                freq = 103.83 -- Ab2
                env = math.exp(-8 * (t - 0.2))
            else
                freq = 87.31 -- F2
                env = math.exp(-4 * (t - 0.4))
            end
            goPhase = goPhase + freq / sampleRate
            local val = triangle(goPhase) * env * 0.4
            gameOverSoundData:setSample(i, val)
        end
        gameOverSource = love.audio.newSource(gameOverSoundData)

        -- 5. Menu Hover (Move) Sound (Soft Retro Tick)
        local menuMoveDuration = 0.03
        local menuMoveLength = math.floor(sampleRate * menuMoveDuration)
        local menuMoveSoundData = love.sound.newSoundData(menuMoveLength, sampleRate, 16, 1)
        local mmPhase = 0
        for i = 0, menuMoveLength - 1 do
            local t = i / sampleRate
            local freq = 600
            local env = math.exp(-120 * t)
            mmPhase = mmPhase + freq / sampleRate
            local val = triangle(mmPhase) * env * 0.12
            menuMoveSoundData:setSample(i, val)
        end
        menuMoveSource = love.audio.newSource(menuMoveSoundData)

        -- 6. Menu Select (Confirm) Sound (Bright Double Beep)
        local menuSelectDuration = 0.13
        local menuSelectLength = math.floor(sampleRate * menuSelectDuration)
        local menuSelectSoundData = love.sound.newSoundData(menuSelectLength, sampleRate, 16, 1)
        local msPhase = 0
        for i = 0, menuSelectLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.05 then
                freq = 1318.51 -- E6
                env = math.exp(-40 * t)
            else
                freq = 1760.00 -- A6
                env = math.exp(-25 * (t - 0.05))
            end
            msPhase = msPhase + freq / sampleRate
            local val = triangle(msPhase) * env * 0.25
            menuSelectSoundData:setSample(i, val)
        end
        menuSelectSource = love.audio.newSource(menuSelectSoundData)

        -- 7. Menu Back (Cancel) Sound (Descending Retro Double Beep)
        local menuBackDuration = 0.13
        local menuBackLength = math.floor(sampleRate * menuBackDuration)
        local menuBackSoundData = love.sound.newSoundData(menuBackLength, sampleRate, 16, 1)
        local mbPhase = 0
        for i = 0, menuBackLength - 1 do
            local t = i / sampleRate
            local freq, env
            if t < 0.05 then
                freq = 1567.98 -- G6
                env = math.exp(-40 * t)
            else
                freq = 1174.66 -- D6
                env = math.exp(-25 * (t - 0.05))
            end
            mbPhase = mbPhase + freq / sampleRate
            local val = triangle(mbPhase) * env * 0.22
            menuBackSoundData:setSample(i, val)
        end
        menuBackSource = love.audio.newSource(menuBackSoundData)
    end
end

function sound.isEnabled()
    return enabled
end

function sound.toggle()
    enabled = not enabled
    save.saveSound(enabled)
end

function sound.playAchievement()
    if enabled and achSource then
        achSource:seek(0)
        achSource:play()
    end
end

function sound.playSplash()
    if enabled and splashSource then
        splashSource:seek(0)
        splashSource:play()
    end
end

function sound.stopSplash()
    if splashSource then
        splashSource:stop()
    end
end

function sound.playVictory()
    if enabled and victorySource then
        victorySource:seek(0)
        victorySource:play()
    end
end

function sound.playGameOver()
    if enabled and gameOverSource then
        gameOverSource:seek(0)
        gameOverSource:play()
    end
end

function sound.playMenuMove()
    if enabled and menuMoveSource then
        menuMoveSource:seek(0)
        menuMoveSource:play()
    end
end

function sound.playMenuSelect()
    if enabled and menuSelectSource then
        menuSelectSource:seek(0)
        menuSelectSource:play()
    end
end

function sound.playMenuBack()
    if enabled and menuBackSource then
        menuBackSource:seek(0)
        menuBackSource:play()
    end
end

return sound
