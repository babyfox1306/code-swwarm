-- CODE SWARM — Error Panel (V0.2)
-- Shows beginner-friendly error messages in right column bottom.

local ErrorPanel = {
    x = 0,
    y = 0,
    width = 300,
    height = 120,
    visible = false,
    title = "",
    body = "",
    hint = "",
    line = nil,
    font = nil,
    smallFont = nil,
}

function ErrorPanel.init(x, y, w, h)
    ErrorPanel.x = x
    ErrorPanel.y = y
    ErrorPanel.width = w
    ErrorPanel.height = h
    ErrorPanel.font = love.graphics.newFont(13)
    ErrorPanel.smallFont = love.graphics.newFont(11)
    ErrorPanel.visible = false
end

function ErrorPanel:setError(title, body, hint, line)
    ErrorPanel.title = title or ""
    ErrorPanel.body = body or ""
    ErrorPanel.hint = hint or ""
    ErrorPanel.line = line
    ErrorPanel.visible = true
end

function ErrorPanel:clear()
    ErrorPanel.visible = false
    ErrorPanel.title = ""
    ErrorPanel.body = ""
    ErrorPanel.hint = ""
    ErrorPanel.line = nil
end

function ErrorPanel:draw()
    if not ErrorPanel.visible then return end

    -- Background
    love.graphics.setColor(0.25, 0.08, 0.08, 0.95)
    love.graphics.rectangle("fill", ErrorPanel.x, ErrorPanel.y, ErrorPanel.width, ErrorPanel.height, 4, 4)
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle("line", ErrorPanel.x, ErrorPanel.y, ErrorPanel.width, ErrorPanel.height, 4, 4)

    -- Warning icon + title
    love.graphics.setFont(ErrorPanel.font)
    love.graphics.setColor(1.0, 0.4, 0.3)
    local titleText = "⚠ " .. ErrorPanel.title
    love.graphics.print(titleText, ErrorPanel.x + 8, ErrorPanel.y + 6)

    -- Body
    love.graphics.setFont(ErrorPanel.smallFont)
    love.graphics.setColor(0.9, 0.85, 0.8)
    love.graphics.printf(ErrorPanel.body, ErrorPanel.x + 8, ErrorPanel.y + 26, ErrorPanel.width - 16, "left")

    -- Hint
    if ErrorPanel.hint ~= "" then
        love.graphics.setColor(0.7, 0.9, 0.7)
        local hintY = ErrorPanel.y + 26 + #ErrorPanel.body * 2 + 10
        if hintY > ErrorPanel.y + ErrorPanel.height - 20 then
            hintY = ErrorPanel.y + ErrorPanel.height - 20
        end
        love.graphics.printf("💡 " .. ErrorPanel.hint, ErrorPanel.x + 8, hintY, ErrorPanel.width - 16, "left")
    end

    -- Line reference
    if ErrorPanel.line then
        love.graphics.setColor(0.6, 0.6, 0.7)
        love.graphics.printf("See line " .. ErrorPanel.line .. " in your editor.",
            ErrorPanel.x + 8, ErrorPanel.y + ErrorPanel.height - 18, ErrorPanel.width - 16, "right")
    end
end

return ErrorPanel
