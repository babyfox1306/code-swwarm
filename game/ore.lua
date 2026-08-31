local C = require("game.constants")
local Assets = nil

local Ore = {}
Ore.__index = Ore

function Ore.new(id, x, y, amount)
    local self = setmetatable({}, Ore)
    self.id = id
    self.x = x
    self.y = y
    self.initialAmount = amount or C.ORE_INITIAL_AMOUNT
    self.remaining = self.initialAmount
    self.animFrame = 1
    self.animTimer = 0
    return self
end

function Ore.setAssets(assetsRef)
    Assets = assetsRef
end

function Ore:reset()
    self.remaining = self.initialAmount
end

function Ore:hasOre()
    return self.remaining > 0
end

function Ore:extract(amount)
    local taken = math.min(self.remaining, amount)
    self.remaining = self.remaining - taken
    return taken
end

function Ore:getPosition()
    return self.x, self.y
end

function Ore:update(dt)
    if self:hasOre() and Assets and Assets.oreQuads then
        self.animTimer = self.animTimer + dt
        if self.animTimer >= 0.3 then
            self.animTimer = 0
            self.animFrame = (self.animFrame % #Assets.oreQuads) + 1
        end
    end
end

function Ore:draw()
    local scale = C.SPRITE_SCALE
    if Assets and Assets.sprites.ore then
        if self:hasOre() then
            love.graphics.setColor(1, 1, 1)
            local quad = Assets.oreQuads[self.animFrame]
            love.graphics.draw(Assets.sprites.ore, quad,
                self.x - 8 * scale, self.y - 8 * scale,
                0, scale, scale)
            -- remaining label
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(self.remaining), self.x - 4, self.y + 10)
        else
            -- depleted: dark tint
            love.graphics.setColor(0.35, 0.35, 0.35, 0.5)
            local quad = Assets.oreQuads[1]
            love.graphics.draw(Assets.sprites.ore, quad,
                self.x - 8 * scale, self.y - 8 * scale,
                0, scale, scale)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("x", self.x - 3, self.y - 4)
        end
    else
        -- fallback shapes
        if self:hasOre() then
            love.graphics.setColor(0.3, 0.5, 1.0)
            love.graphics.polygon("fill",
                self.x, self.y - 10,
                self.x + 8, self.y - 4,
                self.x + 6, self.y + 8,
                self.x - 6, self.y + 8,
                self.x - 8, self.y - 4
            )
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(self.remaining), self.x - 4, self.y + 10)
        else
            love.graphics.setColor(0.35, 0.35, 0.35)
            love.graphics.ellipse("fill", self.x, self.y, 8, 5)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("x", self.x - 3, self.y - 4)
        end
    end
end

return Ore
