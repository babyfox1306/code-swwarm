local C = require("game.constants")

local Assets = {
    sprites = {},
    tiles = {},
    droneQuads = {},
    oreQuads = {},
}

function Assets.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Sprites
    Assets.sprites.drone = love.graphics.newImage("assets/sprites/drone.png")
    Assets.sprites.ore = love.graphics.newImage("assets/sprites/ore.png")
    Assets.sprites.base = love.graphics.newImage("assets/sprites/base.png")

    -- Tiles
    Assets.tiles.floor = love.graphics.newImage("assets/tiles/floor.png")

    -- Drone quads: 4 frames, 16×16 each
    local dw, dh = 16, 16
    for i = 0, 3 do
        Assets.droneQuads[i + 1] = love.graphics.newQuad(
            i * dw, 0, dw, dh,
            Assets.sprites.drone:getDimensions()
        )
    end

    -- Ore quads: 8 frames, 16×16 each (barrel animation)
    local ow, oh = 16, 16
    for i = 0, 7 do
        Assets.oreQuads[i + 1] = love.graphics.newQuad(
            i * ow, 0, ow, oh,
            Assets.sprites.ore:getDimensions()
        )
    end
end

return Assets
