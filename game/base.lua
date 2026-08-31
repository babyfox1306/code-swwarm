local C = require("game.constants")
local Assets = nil

local Base = {}
Base.__index = Base

function Base.new(x, y)
    local self = setmetatable({}, Base)
    self.x = x or C.BASE_X
    self.y = y or C.BASE_Y
    self.width = 64
    self.height = 64
    return self
end

function Base.setAssets(assetsRef)
    Assets = assetsRef
end

function Base:getPosition()
    return self.x, self.y
end

function Base:isDroneInRange(drone)
    local dx = drone.x - self.x
    local dy = drone.y - self.y
    return math.sqrt(dx * dx + dy * dy) <= C.BASE_RANGE
end

function Base:draw()
    local scale = C.SPRITE_SCALE
    if Assets and Assets.sprites.base then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(Assets.sprites.base,
            self.x - 16 * scale, self.y - 8 * scale,
            0, scale, scale)
        -- label
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("BASE", self.x - 14, self.y + 12)
    else
        -- fallback
        love.graphics.setColor(0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", self.x - 32, self.y - 32, 64, 64, 4, 4)
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.rectangle("line", self.x - 32, self.y - 32, 64, 64, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("BASE", self.x - 14, self.y - 6)
    end
end

return Base
