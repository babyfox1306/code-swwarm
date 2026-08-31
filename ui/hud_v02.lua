-- CODE SWARM — HUD V0.2
-- Layout: top bar | world + editor (left) | coach + errors (right) | controls (bottom)

local C = require("game.constants")

local HudV02 = {
    font = nil,
    smallFont = nil,
    status = "idle",  -- idle | running | error | won
    buttons = {},
    editor = nil,
    coachPanel = nil,
    errorPanel = nil,
    apiRef = nil,
    worldX = 0,
    worldY = 0,
    worldW = 0,
    worldH = 0,
    editorX = 0,
    editorY = 0,
    editorW = 0,
    editorH = 0,
    coachX = 0,
    coachY = 0,
    coachW = 0,
    coachH = 0,
    controlY = 0,
    topBarH = 36,
    controlBarH = 40,
    deposited = 0,
    cargo = 0,
    capacity = 5,
}

function HudV02.relayout()
    local sw = love.graphics.getWidth()
    local sh = love.graphics.getHeight()

    -- Layout zones
    local rightW = math.max(240, math.floor(sw * 0.22))
    local leftW = sw - rightW
    local topH = HudV02.topBarH
    local controlH = HudV02.controlBarH
    local availH = sh - topH - controlH

    HudV02.worldX = 0
    HudV02.worldY = topH
    HudV02.worldW = leftW
    HudV02.worldH = math.floor(availH * 0.45)

    HudV02.editorX = 0
    HudV02.editorY = HudV02.worldY + HudV02.worldH
    HudV02.editorW = leftW
    HudV02.editorH = availH - HudV02.worldH

    HudV02.coachX = leftW
    HudV02.coachY = topH
    HudV02.coachW = rightW
    HudV02.coachH = math.floor(availH * 0.55)

    local errorY = HudV02.coachY + HudV02.coachH
    local errorH = availH - HudV02.coachH

    HudV02.controlY = sh - controlH

    if HudV02.editor then
        HudV02.editor.init(HudV02.editorX, HudV02.editorY, HudV02.editorW, HudV02.editorH)
    end
    if HudV02.coachPanel then
        HudV02.coachPanel.init(HudV02.coachX, HudV02.coachY, HudV02.coachW, HudV02.coachH)
    end
    if HudV02.errorPanel then
        HudV02.errorPanel.init(HudV02.coachX, errorY, HudV02.coachW, errorH)
    end
    if HudV02.apiRef then
        local refW = math.min(520, sw - 40)
        local refH = math.min(440, sh - 80)
        HudV02.apiRef.init(math.floor((sw - refW) / 2), math.floor((sh - refH) / 2), refW, refH)
    end

    local btnY = HudV02.controlY + 5
    local btnH = 30
    local btnW = 100
    local btnX = 10
    HudV02.buttons = {
        { id = "run", x = btnX, y = btnY, w = btnW, h = btnH, label = "RUN (F5)", color = {0.15, 0.5, 0.2} },
        { id = "stop", x = btnX + btnW + 10, y = btnY, w = btnW, h = btnH, label = "STOP (Esc)", color = {0.6, 0.15, 0.1} },
        { id = "reset", x = btnX + (btnW + 10) * 2, y = btnY, w = btnW + 20, h = btnH, label = "RESET (F8)", color = {0.3, 0.3, 0.15} },
        { id = "reset_code", x = btnX + (btnW + 10) * 3 + 20, y = btnY, w = btnW + 30, h = btnH, label = "NEW CODE (F9)", color = {0.25, 0.2, 0.35} },
        { id = "api_ref", x = btnX + (btnW + 10) * 4 + 50, y = btnY, w = 70, h = btnH, label = "API (F1)", color = {0.2, 0.25, 0.4} },
    }
end

function HudV02.init(editorRef, coachRef, errorRef, apiRefRef)
    HudV02.font = HudV02.font or love.graphics.newFont(14)
    HudV02.smallFont = HudV02.smallFont or love.graphics.newFont(11)
    HudV02.editor = editorRef
    HudV02.coachPanel = coachRef
    HudV02.errorPanel = errorRef
    HudV02.apiRef = apiRefRef
    HudV02.relayout()
end

function HudV02:setStatus(s)
    HudV02.status = s
end

function HudV02:setDeposited(n)
    HudV02.deposited = n
end

function HudV02:setCargo(c, cap)
    HudV02.cargo = c
    HudV02.capacity = cap or 5
end

function HudV02:setError(msg)
    if msg then
        -- Parse title from message (first line)
        local title, rest = msg:match("^(.-)\n\n(.*)")
        if not title then title = msg; rest = "" end
        HudV02.errorPanel:setError(title, rest, "", nil)
    else
        HudV02.errorPanel:clear()
    end
end

function HudV02:clearError()
    HudV02.errorPanel:clear()
end

-- Draw top bar
function HudV02:_drawTopBar()
    local sw = love.graphics.getWidth()
    love.graphics.setColor(0.06, 0.07, 0.1)
    love.graphics.rectangle("fill", 0, 0, sw, HudV02.topBarH)

    love.graphics.setFont(HudV02.font)

    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("CODE SWARM", 10, 8)

    love.graphics.setColor(0.7, 0.72, 0.75)
    love.graphics.print("Mission 01: First Program", 140, 8)

    love.graphics.setColor(0.9, 0.85, 0.3)
    local depText = string.format("DEPOSITED: %d / %d", HudV02.deposited, C.WIN_ORE_TARGET)
    love.graphics.print(depText, 420, 8)

    love.graphics.setColor(0.5, 0.8, 0.5)
    local cargoText = string.format("CARGO: %d / %d", HudV02.cargo, HudV02.capacity)
    love.graphics.print(cargoText, 620, 8)

    local statusColors = {
        idle = {0.5, 0.5, 0.5},
        running = {0.9, 0.8, 0.2},
        error = {0.9, 0.2, 0.2},
        won = {0.2, 0.8, 0.3},
        stopped = {0.5, 0.5, 0.5},
    }
    local sc = statusColors[HudV02.status] or {0.5, 0.5, 0.5}
    love.graphics.setColor(sc[1], sc[2], sc[3])
    love.graphics.printf(string.upper(HudV02.status), sw - 130, 8, 120, "right")
end

-- Draw controls bar
function HudV02:_drawControls()
    local y = HudV02.controlY
    love.graphics.setColor(0.05, 0.06, 0.08)
    love.graphics.rectangle("fill", 0, y, love.graphics.getWidth(), HudV02.controlBarH)
    love.graphics.setColor(0.2, 0.22, 0.25)
    love.graphics.line(0, y, love.graphics.getWidth(), y)

    for _, btn in ipairs(HudV02.buttons) do
        -- Button background
        local c = btn.color
        if btn.id == "run" and HudV02.status == "running" then
            love.graphics.setColor(0.1, 0.3, 0.1, 0.5)
        else
            love.graphics.setColor(c[1], c[2], c[3])
        end
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 4, 4)

        -- Button label
        love.graphics.setColor(0.9, 0.92, 0.95)
        love.graphics.printf(btn.label, btn.x, btn.y + 7, btn.w, "center")
    end

    -- Win overlay
    if HudV02.status == "won" then
        local sw = love.graphics.getWidth()
        local sh = love.graphics.getHeight()
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(0.2, 0.8, 0.3)
        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.printf("MISSION COMPLETE!", 0, sh / 2 - 40, sw, "center")
        love.graphics.setColor(0.8, 0.85, 0.9)
        love.graphics.setFont(HudV02.font)
        love.graphics.printf(string.format("Deposited %d ore!", HudV02.deposited), 0, sh / 2 + 10, sw, "center")
        love.graphics.printf("Press RESET (F8) to play again.", 0, sh / 2 + 40, sw, "center")
    end
end

-- Draw world placeholder (actual world.draw is called separately)
function HudV02:_drawWorldBorder()
    love.graphics.setColor(0.2, 0.22, 0.25)
    love.graphics.rectangle("line", HudV02.worldX, HudV02.worldY, HudV02.worldW, HudV02.worldH)
end

function HudV02:draw()
    -- Top bar
    self:_drawTopBar()

    -- World border
    self:_drawWorldBorder()

    -- Coach panel
    if self.coachPanel then self.coachPanel:draw() end

    -- Error panel
    if self.errorPanel then self.errorPanel:draw() end

    -- Controls
    self:_drawControls()

    -- API reference overlay
    if self.apiRef then self.apiRef:draw() end
end

function HudV02:update(dt)
    if self.editor then self.editor:update(dt) end
end

-- Input: returns action string or nil
function HudV02:mousepressed(x, y, button)
    -- API reference overlay takes priority
    if self.apiRef and self.apiRef.visible then
        self.apiRef:mousepressed(x, y, button)
        return nil
    end

    -- Check buttons
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.id == "run" and self.status ~= "running" then
                return "run"
            elseif btn.id == "stop" then
                return "stop"
            elseif btn.id == "reset" then
                return "reset"
            elseif btn.id == "reset_code" then
                return "reset_code"
            elseif btn.id == "api_ref" then
                if self.apiRef then self.apiRef.toggle() end
                return nil
            end
        end
    end

    -- Coach panel click
    if self.coachPanel then
        self.coachPanel:mousepressed(x, y, button)
    end

    -- Editor click
    if self.editor then
        if x >= self.editor.x and x <= self.editor.x + self.editor.width and
           y >= self.editor.y and y <= self.editor.y + self.editor.height then
            self.editor:handleClick(x, y)
        else
            self.editor:focus(false)
        end
    end

    return nil
end

function HudV02:keypressed(key)
    -- API reference takes priority
    if self.apiRef and self.apiRef.visible then
        self.apiRef:handleKey(key)
        return nil
    end

    -- Global keys
    if key == "f1" then
        if self.apiRef then self.apiRef.toggle() end
        return nil
    end
    if key == "f11" then
        local fs = not love.window.getFullscreen()
        love.window.setFullscreen(fs)
        HudV02.relayout()
        return nil
    end
    if key == "f5" then return "run" end
    if key == "f8" then return "reset" end
    if key == "f9" then return "reset_code" end
    if key == "escape" then
        if self.status == "running" or self.status == "error" then
            return "stop"
        end
    end

    -- Editor keys
    if self.editor and self.editor.focused then
        self.editor:handleKey(key)
    end

    return nil
end

function HudV02:textinput(text)
    if self.editor and self.editor.focused then
        self.editor:handleTextInput(text)
    end
end

function HudV02:wheelmoved(dx, dy)
    if self.editor then
        self.editor:handleWheel(dx, dy)
    end
end

return HudV02
