-- CODE SWARM — World Camera (Phase 2)
-- Fits simulation coordinates into the HUD world viewport (scale + offset).

local C = require("game.constants")

local WorldCamera = {
    vx = 0,
    vy = 0,
    vw = 800,
    vh = 400,
    scale = 1,
    offsetX = 0,
    offsetY = 0,
}

-- Playable bounds in simulation space (includes wall margin above/below floor)
local CONTENT_X = C.WORLD_X - 20
local CONTENT_Y = C.WORLD_Y - 40
local CONTENT_W = C.WORLD_W + 40
local CONTENT_H = C.WORLD_H + 56

function WorldCamera.setViewport(x, y, w, h)
    WorldCamera.vx = x
    WorldCamera.vy = y
    WorldCamera.vw = math.max(1, w)
    WorldCamera.vh = math.max(1, h)

    local pad = 0.94
    local sx = WorldCamera.vw / CONTENT_W
    local sy = WorldCamera.vh / CONTENT_H
    WorldCamera.scale = math.min(sx, sy) * pad

    local drawnW = CONTENT_W * WorldCamera.scale
    local drawnH = CONTENT_H * WorldCamera.scale
    WorldCamera.offsetX = WorldCamera.vx + (WorldCamera.vw - drawnW) * 0.5 - CONTENT_X * WorldCamera.scale
    WorldCamera.offsetY = WorldCamera.vy + (WorldCamera.vh - drawnH) * 0.5 - CONTENT_Y * WorldCamera.scale
end

function WorldCamera.begin()
    love.graphics.push()
    love.graphics.translate(WorldCamera.offsetX, WorldCamera.offsetY)
    love.graphics.scale(WorldCamera.scale, WorldCamera.scale)
end

function WorldCamera.endDraw()
    love.graphics.pop()
end

function WorldCamera.drawBackground()
    love.graphics.setColor(0.06, 0.07, 0.1)
    love.graphics.rectangle("fill", WorldCamera.vx, WorldCamera.vy, WorldCamera.vw, WorldCamera.vh)
    love.graphics.setColor(1, 1, 1)
end

return WorldCamera
