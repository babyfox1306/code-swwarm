-- CODE SWARM — LÖVE2D Entry Point
-- M1: Boot only

local function initPackagePath()
    local root = love.filesystem.getSource()
    if root and root ~= "" then
        package.path = package.path
            .. ";" .. root .. "/?.lua"
            .. ";" .. root .. "/?/init.lua"
    end
end

function love.load()
    initPackagePath()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.12)
    love.graphics.setDefaultFilter("nearest", "nearest")
end

function love.update(dt)
    -- placeholder
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CODE SWARM — M1 Boot OK", 10, 10)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
