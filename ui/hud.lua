local C = require("game.constants")

local HUD = {
    world = nil,
    runner = nil,
    buttons = {},
    errorText = nil,
}

function HUD.init(runner, world)
    HUD.runner = runner
    HUD.world = world
    HUD.buttons = {
        { label = "RUN",  x = 820, y = 500, w = 80, h = 30, key = "r" },
        { label = "STOP", x = 910, y = 500, w = 80, h = 30, key = "escape" },
        { label = "RESET", x = 1000, y = 500, w = 80, h = 30, key = "f8" },
    }
    HUD.errorText = nil
end

function HUD.update(dt)
    -- button hover feedback handled in draw
end

function HUD.draw()
    local deposited = HUD.world.getDepositedOre()
    local drone = HUD.world.getDrone()
    local cargo = drone:getCargo()
    local capacity = drone:getCapacity()
    local status = HUD.runner and HUD.runner.getStatus() or "idle"

    -- header bar
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", 0, 0, 960, 50)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CODE SWARM", 10, 15)

    -- ore counter
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.print(string.format("ORE  %d / %d", deposited, C.WIN_ORE_TARGET), 200, 15)

    -- cargo
    love.graphics.setColor(0.4, 0.9, 0.5)
    love.graphics.print(string.format("CARGO  %d / %d", cargo, capacity), 400, 15)

    -- status
    local statusColor = { idle = {0.6,0.6,0.6}, running = {0.2,0.9,0.3}, stopped = {0.9,0.6,0.2}, error = {0.9,0.2,0.2}, won = {1,0.85,0.1} }
    local sc = statusColor[status] or {1,1,1}
    love.graphics.setColor(sc[1], sc[2], sc[3])
    love.graphics.print(string.upper(status), 600, 15)

    -- buttons
    for _, btn in ipairs(HUD.buttons) do
        love.graphics.setColor(0.25, 0.25, 0.3)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 4, 4)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(btn.label, btn.x + 16, btn.y + 7)
    end

    -- error display
    if HUD.errorText then
        love.graphics.setColor(0.3, 0.05, 0.05)
        love.graphics.rectangle("fill", C.WORLD_X, C.WORLD_Y + C.WORLD_H + 10, C.WORLD_W, 40, 4, 4)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print("ERROR: " .. HUD.errorText, C.WORLD_X + 10, C.WORLD_Y + C.WORLD_H + 18)
    end

    -- win overlay
    if HUD.world.isWon() then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        love.graphics.setColor(1, 0.85, 0.1)
        love.graphics.printf("WIN!", 0, 220, 960, "center")
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf("All ore deposited. Press RESET to play again.", 0, 280, 960, "center")
    end
end

function HUD.mousepressed(x, y, button)
    if button ~= 1 then return false end
    for _, btn in ipairs(HUD.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            return btn.label
        end
    end
    return false
end

function HUD.keypressed(key)
    for _, btn in ipairs(HUD.buttons) do
        if key == btn.key then
            return btn.label
        end
    end
    return false
end

function HUD.setError(msg)
    HUD.errorText = msg
end

function HUD.clearError()
    HUD.errorText = nil
end

return HUD
