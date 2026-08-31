local C = require("game.constants")

local Audio = {
    sources = {},
    ambience = nil,
    ambiencePlaying = false,
    droneHum = nil,
    dronePlaying = false,
}

function Audio.load()
    -- SFX from files
    local sfxFiles = {
        ui_click = "assets/audio/sfx/ui_click.wav",
        run_start = "assets/audio/sfx/run_start.wav",
        run_stop = "assets/audio/sfx/run_stop.wav",
        mine = "assets/audio/sfx/mine.wav",
        deposit = "assets/audio/sfx/deposit.wav",
        error = "assets/audio/sfx/error.wav",
        win = "assets/audio/sfx/win.wav",
    }
    for name, path in pairs(sfxFiles) do
        local info = love.filesystem.getInfo(path)
        if info then
            Audio.sources[name] = love.audio.newSource(path, "static")
        end
    end

    -- Generate drone hum (low frequency oscillator)
    local sampleRate = 44100
    local duration = 2
    local samples = sampleRate * duration
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- low hum + subtle overtones
        local sample = 0.15 * math.sin(2 * math.pi * 80 * t)
            + 0.08 * math.sin(2 * math.pi * 160 * t)
            + 0.04 * math.sin(2 * math.pi * 240 * t)
        -- fade in/out for seamless loop
        local env = 1
        if t < 0.05 then env = t / 0.05 end
        if t > duration - 0.05 then env = (duration - t) / 0.05 end
        soundData:setSample(i, sample * env)
    end
    Audio.droneHum = love.audio.newSource(soundData)
    Audio.droneHum:setLooping(true)
    Audio.droneHum:setVolume(C.VOL_DRONE_LOOP)

    -- Generate ambient drone (dark low pad)
    local ambSamples = sampleRate * 4
    local ambData = love.sound.newSoundData(ambSamples, sampleRate, 16, 1)
    for i = 0, ambSamples - 1 do
        local t = i / sampleRate
        local sample = 0.06 * math.sin(2 * math.pi * 55 * t)
            + 0.03 * math.sin(2 * math.pi * 82.5 * t)
            + 0.02 * math.sin(2 * math.pi * 110 * t + math.sin(2 * math.pi * 0.1 * t) * 2)
        local env = 1
        if t < 0.1 then env = t / 0.1 end
        if t > 4 - 0.1 then env = (4 - t) / 0.1 end
        ambData:setSample(i, sample * env)
    end
    Audio.ambience = love.audio.newSource(ambData)
    Audio.ambience:setLooping(true)
    Audio.ambience:setVolume(C.VOL_MUSIC)
end

function Audio.play(name)
    local s = Audio.sources[name]
    if s then
        local clone = s:clone()
        clone:setVolume(C.VOL_SFX)
        clone:play()
    end
end

function Audio.startDroneHum()
    if Audio.droneHum and not Audio.dronePlaying then
        Audio.droneHum:play()
        Audio.dronePlaying = true
    end
end

function Audio.stopDroneHum()
    if Audio.droneHum and Audio.dronePlaying then
        Audio.droneHum:stop()
        Audio.dronePlaying = false
    end
end

function Audio.startAmbience()
    if Audio.ambience and not Audio.ambiencePlaying then
        Audio.ambience:play()
        Audio.ambiencePlaying = true
    end
end

function Audio.stopAmbience()
    if Audio.ambience and Audio.ambiencePlaying then
        Audio.ambience:stop()
        Audio.ambiencePlaying = false
    end
end

function Audio.update(dt, droneState)
    if droneState == "moving" then
        Audio.startDroneHum()
    else
        Audio.stopDroneHum()
    end
end

return Audio
