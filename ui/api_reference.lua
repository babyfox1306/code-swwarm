-- CODE SWARM — API Reference Panel (V0.2)
-- Toggle with F1, scrollable list of 6 API functions.

local ApiRef = {
    visible = false,
    entries = {},
    font = nil,
    smallFont = nil,
    x = 0,
    y = 0,
    width = 500,
    height = 400,
    scrollY = 0,
}

function ApiRef.init(x, y, w, h)
    ApiRef.x = x or 200
    ApiRef.y = y or 100
    ApiRef.width = w or 500
    ApiRef.height = h or 400
    ApiRef.font = love.graphics.newFont(13)
    ApiRef.smallFont = love.graphics.newFont(11)
    ApiRef.scrollY = 0
    ApiRef:_loadEntries()
end

function ApiRef:_loadEntries()
    local info = love.filesystem.getInfo("data/api_reference.json")
    if info then
        local content = love.filesystem.read("data/api_reference.json")
        if content then
            ApiRef.entries = ApiRef._parseJson(content)
        end
    end
end

function ApiRef._parseJson(s)
    local entries = {}
    -- Parse each object in the array
    for obj in s:gmatch("{[^{}]+}") do
        local entry = {}
        entry.name = obj:match('"name"%s*:%s*"([^"]*)"') or ""
        entry.signature = obj:match('"signature"%s*:%s*"([^"]*)"') or ""
        entry.summary = obj:match('"summary"%s*:%s*"([^"]*)"') or ""
        entry.example = obj:match('"example"%s*:%s*"([^"]*)"') or ""
        entries[#entries + 1] = entry
    end
    return entries
end

function ApiRef.toggle()
    ApiRef.visible = not ApiRef.visible
    ApiRef.scrollY = 0
end

function ApiRef:mousepressed(x, y, button)
    if not ApiRef.visible then return false end
    -- Close on click outside or X button
    if x < ApiRef.x or x > ApiRef.x + ApiRef.width or
       y < ApiRef.y or y > ApiRef.y + ApiRef.height then
        ApiRef.visible = false
        return true
    end
    return false
end

function ApiRef:handleKey(key)
    if not ApiRef.visible then return false end
    if key == "escape" or key == "f1" then
        ApiRef.visible = false
        return true
    end
    if key == "up" then
        ApiRef.scrollY = math.max(0, ApiRef.scrollY - 20)
        return true
    elseif key == "down" then
        ApiRef.scrollY = ApiRef.scrollY + 20
        return true
    end
    return false
end

function ApiRef:draw()
    if not ApiRef.visible then return end

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Panel
    love.graphics.setColor(0.08, 0.09, 0.12)
    love.graphics.rectangle("fill", ApiRef.x, ApiRef.y, ApiRef.width, ApiRef.height, 6, 6)
    love.graphics.setColor(0.3, 0.5, 0.8, 0.8)
    love.graphics.rectangle("line", ApiRef.x, ApiRef.y, ApiRef.width, ApiRef.height, 6, 6)

    -- Title
    love.graphics.setFont(ApiRef.font)
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("API Reference (F1 to close)", ApiRef.x + 12, ApiRef.y + 10)

    -- Entries
    love.graphics.setScissor(ApiRef.x + 1, ApiRef.y + 30, ApiRef.width - 2, ApiRef.height - 35)
    local yOff = 30 - ApiRef.scrollY

    for _, entry in ipairs(ApiRef.entries) do
        -- Function name
        love.graphics.setColor(0.9, 0.8, 0.3)
        love.graphics.print(entry.signature, ApiRef.x + 12, ApiRef.y + yOff)
        yOff = yOff + 20

        -- Summary
        love.graphics.setFont(ApiRef.smallFont)
        love.graphics.setColor(0.75, 0.78, 0.82)
        love.graphics.printf(entry.summary, ApiRef.x + 20, ApiRef.y + yOff, ApiRef.width - 40, "left")
        yOff = yOff + 18

        -- Example
        love.graphics.setColor(0.5, 0.7, 0.5)
        love.graphics.print("  " .. entry.example, ApiRef.x + 20, ApiRef.y + yOff)
        yOff = yOff + 25

        love.graphics.setFont(ApiRef.font)
    end

    love.graphics.setScissor()
end

return ApiRef
