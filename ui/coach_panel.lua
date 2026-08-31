-- CODE SWARM — Coach Panel (V0.2)
-- Displays mission step, coach text, hint button.

local CoachPanel = {
    x = 0,
    y = 0,
    width = 300,
    height = 200,
    font = nil,
    smallFont = nil,
    step = 1,
    maxSteps = 7,
    hintTier = 0,
    hints = {},
    coachText = "",
    stepTitle = "",
    width = 300,
    buttonY = 0,
    buttonH = 30,
}

function CoachPanel.init(x, y, w, h)
    CoachPanel.x = x
    CoachPanel.y = y
    CoachPanel.width = w
    CoachPanel.height = h
    CoachPanel.font = love.graphics.newFont(13)
    CoachPanel.smallFont = love.graphics.newFont(11)
    CoachPanel.step = 1
    CoachPanel.hintTier = 0
    CoachPanel:_loadHints()
    CoachPanel:_updateText()
end

function CoachPanel:_loadHints()
    local info = love.filesystem.getInfo("data/mission01/hints.json")
    if info then
        local content = love.filesystem.read("data/mission01/hints.json")
        if content then
            -- Simple JSON parse for our known structure
            CoachPanel.hints = CoachPanel._parseHintsJson(content)
        end
    end
end

function CoachPanel._parseHintsJson(s)
    local hints = {}
    for stepName, tiers in s:gmatch('"(step_%d+)"%s*:%s*{(.-)}') do
        local stepNum = tonumber(stepName:match("step_(%d+)"))
        local stepHints = {}
        for tierName, tierText in tiers:gmatch('"(tier%d+)"%s*:%s*"([^"]*)"') do
            local tierNum = tonumber(tierName:match("tier(%d+)"))
            stepHints[tierNum] = tierText:gsub("\\n", "\n")
        end
        hints[stepNum] = stepHints
    end
    return hints
end

local STEP_TEXTS = {
    { title = "Step 1 — Move", text = "Your drone waits for orders.\nFind the nearest ore and go there.\n\nTry typing:\n  move_to(nearest_ore())\n\nThen press RUN (F5)." },
    { title = "Step 2 — Mine", text = "Good! Now mine the ore you're standing on.\n\nAdd:\n  mine()\n\nRun again." },
    { title = "Step 3 — Repeat", text = "You need more ore.\nIn Python, while repeats code.\n\nwhile cargo() < 5:\n    (indented lines)\n\nIndent with 4 spaces after the colon." },
    { title = "Step 4 — Cargo limit", text = "Your drone holds 5 ore.\ncapacity() returns 5.\nWhen cargo() >= capacity(),\nyou can't mine more." },
    { title = "Step 5 — Return to base", text = "When cargo is full, go to the base.\n\nmove_to(\"base\")" },
    { title = "Step 6 — Deposit", text = "At the base, empty your cargo:\n\ndeposit()\n\nWatch the DEPOSITED counter go up!" },
    { title = "Step 7 — Automate", text = "Put it together: mine until full,\ngo to base, deposit, repeat.\nGoal: DEPOSITED reaches 20." },
}

function CoachPanel:_updateText()
    local step = STEP_TEXTS[CoachPanel.step]
    if step then
        CoachPanel.stepTitle = step.title
        CoachPanel.coachText = step.text
    end
end

function CoachPanel:setStep(n)
    CoachPanel.step = math.max(1, math.min(n, CoachPanel.maxSteps))
    CoachPanel.hintTier = 0
    CoachPanel:_updateText()
end

function CoachPanel:getStep()
    return CoachPanel.step
end

function CoachPanel:getHint()
    local hints = CoachPanel.hints[CoachPanel.step]
    if hints then
        return hints[CoachPanel.hintTier]
    end
    return nil
end

function CoachPanel:nextHint()
    CoachPanel.hintTier = math.min(CoachPanel.hintTier + 1, 4)
    return CoachPanel:getHint()
end

function CoachPanel:getHintTier()
    return CoachPanel.hintTier
end

function CoachPanel:mousepressed(x, y, button)
    if button ~= 1 then return nil end
    -- Check hint button
    local bx = self.x + 8
    local by = self.buttonY
    local bw = self.width - 16
    if x >= bx and x <= bx + bw and y >= by and y <= by + self.buttonH then
        if self.hintTier < 4 then
            return self:nextHint()
        end
    end
    return nil
end

function CoachPanel:draw()
    -- Panel background
    love.graphics.setColor(0.1, 0.11, 0.15)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)
    love.graphics.setColor(0.25, 0.28, 0.32)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

    -- Step title
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print(self.stepTitle, self.x + 10, self.y + 10)

    -- Coach text
    love.graphics.setColor(0.8, 0.82, 0.85)
    love.graphics.printf(self.coachText, self.x + 10, self.y + 30, self.width - 20, "left")

    -- Hint display
    if self.hintTier > 0 then
        local hint = self:getHint()
        if hint then
            love.graphics.setColor(1.0, 0.9, 0.4)
            love.graphics.printf("Hint " .. self.hintTier .. ":\n" .. hint,
                self.x + 10, self.y + 130, self.width - 20, "left")
        end
    end

    -- Hint button
    self.buttonY = self.y + self.height - 40
    local label = self.hintTier < 4 and "Next Hint" or "Step solution shown"
    local bx = self.x + 8
    local bw = self.width - 16
    if self.hintTier < 4 then
        love.graphics.setColor(0.25, 0.35, 0.55)
    else
        love.graphics.setColor(0.15, 0.18, 0.22)
    end
    love.graphics.rectangle("fill", bx, self.buttonY, bw, self.buttonH, 4, 4)
    love.graphics.setColor(0.9, 0.92, 0.95)
    love.graphics.printf(label, bx, self.buttonY + 7, bw, "center")
end

return CoachPanel
