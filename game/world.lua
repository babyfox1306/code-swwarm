local C = require("game.constants")
local Drone = require("game.drone")
local Ore = require("game.ore")
local Base = require("game.base")
local Effects = require("game.effects")
local Assets = nil

local World = {
    drone = nil,
    base = nil,
    ores = {},
    depositedOre = 0,
    won = false,
}

function World.setAssets(assetsRef)
    Assets = assetsRef
    Drone.setAssets(assetsRef)
    Ore.setAssets(assetsRef)
    Base.setAssets(assetsRef)
end

function World.init()
    World.drone = Drone.new({ x = C.DRONE_START_X, y = C.DRONE_START_Y })
    World.base = Base.new(C.BASE_X, C.BASE_Y)
    World.ores = {}
    for _, pos in ipairs(C.ORE_POSITIONS) do
        table.insert(World.ores, Ore.new(pos.id, pos.x, pos.y))
    end
    World.depositedOre = 0
    World.won = false
    Effects.clear()
end

function World.reset()
    World.drone:reset()
    World.depositedOre = 0
    World.won = false
    for _, ore in ipairs(World.ores) do
        ore:reset()
    end
    Effects.clear()
end

function World.update(dt)
    World.drone:update(dt)

    -- ore animation
    for _, ore in ipairs(World.ores) do
        ore:update(dt)
    end

    -- mining update
    if World.drone.state == "mining" then
        World.drone.miningTimer = World.drone.miningTimer - dt
        -- spawn mining particles periodically
        if math.random() < dt * 3 then
            local ore = World.getOreById(World.drone.miningOreId)
            if ore then
                Effects.spawnMiningEffect(ore.x, ore.y)
            end
        end
        if World.drone.miningTimer <= 0 then
            local ore = World.getOreById(World.drone.miningOreId)
            if ore then
                local extracted = ore:extract(C.ORE_PER_MINE)
                local space = World.drone.capacity - World.drone.cargo
                local gained = math.min(extracted, space)
                World.drone.cargo = World.drone.cargo + gained
            end
            World.drone.state = "idle"
            World.drone.miningOreId = nil
        end
    end

    -- depositing update
    if World.drone.state == "depositing" then
        World.drone.depositTimer = World.drone.depositTimer - dt
        if World.drone.depositTimer <= 0 then
            local amount = World.drone.cargo
            World.drone.cargo = 0
            World.depositedOre = World.depositedOre + amount
            Effects.spawnDepositEffect(World.base.x, World.base.y)
            World.drone.state = "idle"
            if World.depositedOre >= C.WIN_ORE_TARGET then
                World.won = true
            end
        end
    end

    Effects.update(dt)
end

function World.draw()
    -- floor tiles
    if Assets and Assets.tiles.floor then
        local tile = Assets.tiles.floor
        local tw, th = tile:getWidth(), tile:getHeight()
        local scale = C.SPRITE_SCALE
        for ty = 0, math.ceil(C.WORLD_H / (th * scale)) do
            for tx = 0, math.ceil(C.WORLD_W / (tw * scale)) do
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(tile,
                    C.WORLD_X + tx * tw * scale,
                    C.WORLD_Y + ty * th * scale,
                    0, scale, scale)
            end
        end
    else
        -- fallback dark background
        love.graphics.setColor(0.15, 0.18, 0.2)
        love.graphics.rectangle("fill", C.WORLD_X, C.WORLD_Y, C.WORLD_W, C.WORLD_H, 4, 4)
        love.graphics.setColor(0.2, 0.22, 0.25)
        for gx = C.WORLD_X, C.WORLD_X + C.WORLD_W, 40 do
            love.graphics.line(gx, C.WORLD_Y, gx, C.WORLD_Y + C.WORLD_H)
        end
        for gy = C.WORLD_Y, C.WORLD_Y + C.WORLD_H, 40 do
            love.graphics.line(C.WORLD_X, gy, C.WORLD_X + C.WORLD_W, gy)
        end
    end

    World.base:draw()
    for _, ore in ipairs(World.ores) do
        ore:draw()
    end
    World.drone:draw()
    Effects.draw()
end

function World.getDrone()
    return World.drone
end

function World.getBase()
    return World.base
end

function World.isWon()
    return World.won
end

function World.getDepositedOre()
    return World.depositedOre
end

function World.getOreById(id)
    for _, ore in ipairs(World.ores) do
        if ore.id == id then
            return ore
        end
    end
    return nil
end

function World.findNearestOre(x, y)
    local best, bestDist
    for _, ore in ipairs(World.ores) do
        if ore:hasOre() then
            local dx = ore.x - x
            local dy = ore.y - y
            local d = dx * dx + dy * dy
            if not bestDist or d < bestDist then
                best = ore
                bestDist = d
            end
        end
    end
    return best
end

return World
