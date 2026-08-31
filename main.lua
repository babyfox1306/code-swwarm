-- CODE SWARM — LÖVE2D Entry Point
-- M2: Static world + HUD shell

local world = require("game.world")
local Demo = require("game.demo")
local Api = require("scripting.api")
local runner = require("scripting.runner")
local Assets = require("game.assets")

local hud = require("ui.hud")

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
    world.setAssets(Assets)
    world.init()
    Api.setWorld(world)
    runner.init(world, Api)
    Api.setRunner(runner)
    hud.init(runner, world)
end

function love.update(dt)
    runner:update(dt)
    if not runner:isRunning() then
        Demo.update(dt, world)
    end
    world.update(dt)
    -- check win
    if world.isWon() and runner:getStatus() ~= "won" then
        runner:onWin()
    end
    -- sync error to HUD
    if runner:getStatus() == "error" then
        hud:setError(runner:getError())
    end
    hud:update(dt)
end

function love.draw()
    world.draw()
    hud:draw()
end

function love.mousepressed(x, y, button)
    hud:mousepressed(x, y, button)
end

function love.keypressed(key)
    local action = hud:keypressed(key)
    if action == "RUN" then
        Demo.stop()
        runner:run()
        if runner:getStatus() == "error" then
            hud:setError(runner:getError())
        else
            hud:clearError()
        end
    elseif action == "STOP" then
        runner:stop()
        hud:clearError()
    elseif action == "RESET" then
        Demo.stop()
        runner:reset()
        hud:clearError()
    elseif key == "t" then
        runner:stop()
        Demo.start(world)
        runner.status = "running"
    elseif key == "escape" then
        love.event.quit()
    end
end
