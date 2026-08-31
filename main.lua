-- CODE SWARM — LÖVE2D Entry Point

local world = require("game.world")
local Api = require("scripting.api")
local runner = require("scripting.runner")
local Assets = require("game.assets")
local Audio = require("game.audio")
local hud = require("ui.hud")
local lastRunnerStatus = "idle"

-- Shared action handler (keyboard + mouse)
local function doAction(action)
    if action == "run" then
        Audio.play("ui_click")
        Audio.play("run_start")
        runner:run()
        if runner:getStatus() == "error" then
            Audio.play("error")
            hud:setError(runner:getError())
        else
            hud:clearError()
        end
    elseif action == "stop" then
        Audio.play("ui_click")
        Audio.play("run_stop")
        runner:stop()
        hud:clearError()
    elseif action == "reset" then
        Audio.play("ui_click")
        Audio.stopDroneHum()
        runner:reset()
        hud:clearError()
    end
end

function love.load()
    local root = love.filesystem.getSource()
    if root and root ~= "" then
        package.path = package.path
            .. ";" .. root .. "/?.lua"
            .. ";" .. root .. "/?/init.lua"
    end
    love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
    love.graphics.setDefaultFilter("nearest", "nearest")

    Assets.load()
    Audio.load()
    world.setAssets(Assets)
    world.setAudio(Audio)
    world.init()
    Api.setWorld(world)
    runner.init(world, Api)
    Api.setRunner(runner)
    hud.init(runner, world)

    -- start ambience
    Audio.startAmbience()
end

function love.update(dt)
    runner:update(dt)
    world.update(dt)
    -- win detection: stop script immediately when deposit hits 20
    if world.isWon() and runner:getStatus() ~= "won" then
        runner:onWin()
    end
    -- sync error to HUD + play error SFX once on transition
    local status = runner:getStatus()
    if status == "error" then
        if lastRunnerStatus ~= "error" then
            Audio.play("error")
        end
        hud:setError(runner:getError())
    end
    lastRunnerStatus = status
    Audio.update(dt, world.getDrone().state)
    hud:update(dt)
end

function love.draw()
    world.draw()
    hud:draw()
end

function love.mousepressed(x, y, button)
    local action = hud:mousepressed(x, y, button)
    if action then
        doAction(action)
    end
end

function love.keypressed(key)
    local action = hud:keypressed(key)
    if action then
        doAction(action)
    elseif key == "f5" then
        doAction("run")
    elseif key == "escape" then
        if runner:getStatus() == "idle" or runner:getStatus() == "stopped" then
            love.event.quit()
        end
    end
end
