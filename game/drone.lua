local C = require("game.constants")
local Assets = nil  -- loaded after Assets.load()

local Drone = {}
Drone.__index = Drone

function Drone.new(opts)
    local self = setmetatable({}, Drone)
    self.x = opts.x or C.DRONE_START_X
    self.y = opts.y or C.DRONE_START_Y
    self.cargo = 0
    self.capacity = C.CARGO_CAPACITY
    self.speed = C.DRONE_SPEED
    self.state = "idle"
    -- movement
    self.targetX = nil
    self.targetY = nil
    -- mining
    self.miningOreId = nil
    self.miningTimer = 0
    -- depositing
    self.depositTimer = 0
    -- animation
    self.bobPhase = 0
    self.bobOffset = 0
    self.facingAngle = 0
    self.animFrame = 1
    self.animTimer = 0
    return self
end

function Drone:reset()
    self.x = C.DRONE_START_X
    self.y = C.DRONE_START_Y
    self.cargo = 0
    self.state = "idle"
    self.targetX = nil
    self.targetY = nil
    self.miningOreId = nil
    self.miningTimer = 0
    self.depositTimer = 0
    self.bobPhase = 0
    self.bobOffset = 0
    self.facingAngle = 0
end

function Drone:cancelAction()
    self.state = "idle"
    self.miningOreId = nil
    self.miningTimer = 0
    self.depositTimer = 0
    self.targetX = nil
    self.targetY = nil
end

function Drone:isBusy()
    return self.state ~= "idle"
end

function Drone:getCargo()
    return self.cargo
end

function Drone:getCapacity()
    return self.capacity
end

function Drone:update(dt)
    if self.state == "moving" then
        self:updateMoving(dt)
    elseif self.state == "mining" then
        -- mining update handled by world
    elseif self.state == "depositing" then
        -- deposit update handled by world
    end
    -- idle bob animation
    self.bobPhase = self.bobPhase + dt * C.DRONE_BOB_SPEED
    self.bobOffset = math.sin(self.bobPhase) * C.DRONE_BOB_AMPLITUDE
    -- sprite animation
    if Assets and Assets.droneQuads then
        self.animTimer = self.animTimer + dt
        if self.animTimer >= C.DRONE_ANIM_FRAME_TIME then
            self.animTimer = 0
            self.animFrame = (self.animFrame % #Assets.droneQuads) + 1
        end
    end
end

function Drone:updateMoving(dt)
    if not self.targetX or not self.targetY then
        self.state = "idle"
        return
    end
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= C.ARRIVAL_DISTANCE then
        self.x = self.targetX
        self.y = self.targetY
        self.targetX = nil
        self.targetY = nil
        self.state = "idle"
        return
    end
    local step = self.speed * dt
    local nx = dx / dist
    local ny = dy / dist
    self.x = self.x + nx * math.min(step, dist)
    self.y = self.y + ny * math.min(step, dist)
    self.facingAngle = math.atan2(dy, dx)
end

function Drone.setAssets(assetsRef)
    Assets = assetsRef
end

function Drone:draw()
    local drawX = self.x
    local drawY = self.y + self.bobOffset
    local scale = C.SPRITE_SCALE

    if Assets and Assets.sprites.drone then
        love.graphics.setColor(1, 1, 1)
        local quad = Assets.droneQuads[self.animFrame]
        love.graphics.draw(Assets.sprites.drone, quad,
            drawX - 8 * scale, drawY - 8 * scale,
            0, scale, scale)
    else
        -- fallback
        love.graphics.setColor(0.2, 0.8, 0.4)
        love.graphics.rectangle("fill", drawX - 12, drawY - 8, 24, 16, 3, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", drawX + 6, drawY - 2, 3)
    end
end

return Drone
