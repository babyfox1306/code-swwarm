local C = require("game.constants")

-- Color palette from doc/07-ui-hud.md
local Colors = {
    bg_dark = { 0.05, 0.067, 0.09 },        -- #0d1117
    panel = { 0.086, 0.106, 0.133 },         -- #161b22
    panel_border = { 0.188, 0.212, 0.239 },  -- #30363d
    text_primary = { 0.902, 0.929, 0.953 },  -- #e6edf3
    text_muted = { 0.545, 0.580, 0.620 },    -- #8b949e
    accent_cyan = { 0.345, 0.651, 1.0 },     -- #58a6ff
    status_idle = { 0.545, 0.580, 0.620 },
    status_run = { 0.247, 0.725, 0.314 },    -- #3fb950
    status_stop = { 0.545, 0.580, 0.620 },
    status_error = { 0.973, 0.318, 0.286 },  -- #f85149
    status_won = { 0.824, 0.588, 0.133 },    -- #d29922
    button_run = { 0.137, 0.525, 0.212 },    -- #238636
    button_stop = { 0.855, 0.212, 0.200 },   -- #da3633
    button_reset = { 0.431, 0.463, 0.506 },  -- #6e7681
}

local HUD = {
    world = nil,
    runner = nil,
    buttons = {},
    errorText = nil,
    mouseOver = nil,
}

function HUD.init(runner, world)
    HUD.runner = runner
    HUD.world = world
    HUD.buttons = {
        { id = "run",   label = "RUN",   x = 80,  y = 500, w = 120, h = 36, color = Colors.button_run,  key = "r",   enabled = true },
        { id = "stop",  label = "STOP",  x = 220, y = 500, w = 120, h = 36, color = Colors.button_stop,  key = "escape", enabled = true },
        { id = "reset", label = "RESET", x = 360, y = 500, w = 120, h = 36, color = Colors.button_reset, key = "f8",  enabled = true },
    }
    HUD.errorText = nil
end

function HUD.update(dt)
    -- hover detection
    local mx, my = love.mouse.getPosition()
    HUD.mouseOver = nil
    for _, btn in ipairs(HUD.buttons) do
        if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            HUD.mouseOver = btn.id
        end
    end
    -- disable RUN when won
    for _, btn in ipairs(HUD.buttons) do
        if btn.id == "run" then
            btn.enabled = not HUD.world.isWon()
        end
    end
end

local function drawPanel(x, y, w, h)
    love.graphics.setColor(Colors.panel[1], Colors.panel[2], Colors.panel[3])
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(Colors.panel_border[1], Colors.panel_border[2], Colors.panel_border[3])
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
end

local function drawButton(btn)
    local r, g, b = btn.color[1], btn.color[2], btn.color[3]
    if not btn.enabled then
        r, g, b = r * 0.4, g * 0.4, b * 0.4
    elseif HUD.mouseOver == btn.id then
        r = math.min(r + 0.1, 1)
        g = math.min(g + 0.1, 1)
        b = math.min(b + 0.1, 1)
    end
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(btn.label, btn.x, btn.y + 9, btn.w, "center")
end

function HUD.draw()
    local deposited = HUD.world.getDepositedOre()
    local drone = HUD.world.getDrone()
    local cargo = drone:getCargo()
    local capacity = drone:getCapacity()
    local status = HUD.runner.getStatus(HUD.runner)

    -- top bar panel
    drawPanel(0, 0, 960, 56)

    -- title
    love.graphics.setColor(Colors.accent_cyan[1], Colors.accent_cyan[2], Colors.accent_cyan[3])
    love.graphics.print("CODE SWARM", 16, 18)
    love.graphics.setColor(Colors.text_muted[1], Colors.text_muted[2], Colors.text_muted[3])
    love.graphics.print("v0.1", 145, 22)

    -- ore counter
    love.graphics.setColor(Colors.text_primary[1], Colors.text_primary[2], Colors.text_primary[3])
    love.graphics.print("ORE", 260, 10)
    love.graphics.setColor(Colors.accent_cyan[1], Colors.accent_cyan[2], Colors.accent_cyan[3])
    love.graphics.print(string.format("%d / %d", deposited, C.WIN_ORE_TARGET), 260, 28)

    -- cargo
    love.graphics.setColor(Colors.text_primary[1], Colors.text_primary[2], Colors.text_primary[3])
    love.graphics.print("CARGO", 400, 10)
    love.graphics.setColor(Colors.accent_cyan[1], Colors.accent_cyan[2], Colors.accent_cyan[3])
    love.graphics.print(string.format("%d / %d", cargo, capacity), 400, 28)

    -- status indicator
    local statusColors = {
        idle = Colors.status_idle,
        running = Colors.status_run,
        stopped = Colors.status_stop,
        error = Colors.status_error,
        won = Colors.status_won,
    }
    local sc = statusColors[status] or Colors.status_idle
    -- status dot
    love.graphics.setColor(sc[1], sc[2], sc[3])
    love.graphics.circle("fill", 580, 28, 6)
    -- status text
    love.graphics.setColor(Colors.text_primary[1], Colors.text_primary[2], Colors.text_primary[3])
    local statusText = status == "won" and "MISSION COMPLETE" or string.upper(status)
    love.graphics.print(statusText, 592, 20)

    -- bottom bar panel
    drawPanel(0, 490, 960, 50)

    -- buttons
    for _, btn in ipairs(HUD.buttons) do
        drawButton(btn)
    end

    -- keyboard hints
    love.graphics.setColor(Colors.text_muted[1], Colors.text_muted[2], Colors.text_muted[3])
    love.graphics.print("F5=RUN  Esc=STOP  F8=RESET", 520, 512)

    -- error panel (inside top bar, right side — never covers buttons)
    if HUD.errorText then
        local errX = 700
        local errW = 250
        drawPanel(errX, 4, errW, 48)
        love.graphics.setColor(Colors.status_error[1], Colors.status_error[2], Colors.status_error[3])
        love.graphics.print("ERROR", errX + 8, 8)
        love.graphics.setColor(Colors.text_primary[1], Colors.text_primary[2], Colors.text_primary[3])
        local msg = HUD.errorText
        if #msg > 38 then msg = msg:sub(1, 35) .. "..." end
        love.graphics.print(msg, errX + 8, 26)
    end

    -- win overlay
    if HUD.world.isWon() then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, 960, 540)
        love.graphics.setColor(Colors.status_won[1], Colors.status_won[2], Colors.status_won[3])
        love.graphics.printf("MISSION COMPLETE", 0, 200, 960, "center")
        love.graphics.setColor(Colors.text_primary[1], Colors.text_primary[2], Colors.text_primary[3])
        love.graphics.printf(string.format("%d / %d ORE DEPOSITED", deposited, C.WIN_ORE_TARGET), 0, 240, 960, "center")
        love.graphics.setColor(Colors.text_muted[1], Colors.text_muted[2], Colors.text_muted[3])
        love.graphics.printf("Press RESET to play again", 0, 280, 960, "center")
    end
end

function HUD.mousepressed(x, y, button)
    if button ~= 1 then return false end
    for _, btn in ipairs(HUD.buttons) do
        if btn.enabled and x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            return btn.id
        end
    end
    return false
end

function HUD.keypressed(key)
    for _, btn in ipairs(HUD.buttons) do
        if key == btn.key and btn.enabled then
            return btn.id
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
