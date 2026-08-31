local C = require("game.constants")

local Api = {
    world = nil,
    runner = nil,
}

-- target handle: opaque reference to ore node
local Targets = {}
Targets.__index = Targets

function Targets.new(oreNode)
    return setmetatable({ __type = "ore_target", id = oreNode.id }, Targets)
end

function Targets:__tostring()
    return "ore#" .. tostring(self.id)
end

local function isOreTarget(t)
    return type(t) == "table" and t.__type == "ore_target"
end

function Api._inRange(drone, ore)
    local dx = ore.x - drone.x
    local dy = ore.y - drone.y
    return math.sqrt(dx * dx + dy * dy) <= C.MINING_RANGE
end

function Api.setWorld(worldRef)
    Api.world = worldRef
end

function Api.setRunner(runnerRef)
    Api.runner = runnerRef
end

-- API: nearest_ore() → ore_target
function Api.nearest_ore()
    local drone = Api.world.getDrone()
    local ore = Api.world.findNearestOre(drone.x, drone.y)
    if not ore then
        error("No ore available")
    end
    return Targets.new(ore)
end

-- Parse ore target string from nearest_ore() (Python IPC returns "ore#id")
local function parseOreTargetString(target)
    if type(target) ~= "string" then return nil end
    local id = target:match("^ore#(%d+)$") or target:match("^ore:(%d+)$")
    if id then return tonumber(id) end
    return nil
end

-- API: move_to(target) — blocking via coroutine yield
function Api.move_to(target)
    local drone = Api.world.getDrone()
    drone.lastMoveTarget = nil  -- clear previous
    if type(target) == "string" and target == "base" then
        drone.targetX = C.BASE_X
        drone.targetY = C.BASE_Y
        drone.state = "moving"
    elseif isOreTarget(target) then
        local ore = Api.world.getOreById(target.id)
        if not ore then
            error("Invalid ore target")
        end
        if not ore:hasOre() then
            error("Ore node depleted")
        end
        drone.targetX = ore.x
        drone.targetY = ore.y
        drone.state = "moving"
        drone.lastMoveTarget = { type = "ore", id = target.id }
    else
        local oreId = parseOreTargetString(target)
        if oreId then
            local ore = Api.world.getOreById(oreId)
            if not ore then
                error("Invalid ore target")
            end
            if not ore:hasOre() then
                error("Ore node depleted")
            end
            drone.targetX = ore.x
            drone.targetY = ore.y
            drone.state = "moving"
            drone.lastMoveTarget = { type = "ore", id = oreId }
        else
            error("Invalid move target: " .. tostring(target))
        end
    end

    -- yield until drone returns to idle
    Api.runner.waitUntil(function()
        return drone.state == "idle"
    end)
end

-- API: mine() — blocking via coroutine yield
function Api.mine()
    local drone = Api.world.getDrone()
    -- prefer ore from last move_to target
    local ore = nil
    if drone.lastMoveTarget and drone.lastMoveTarget.type == "ore" then
        ore = Api.world.getOreById(drone.lastMoveTarget.id)
        if ore and (not ore:hasOre() or not Api._inRange(drone, ore)) then
            ore = nil  -- fall through to nearest
        end
    end
    if not ore then
        ore = Api.world.findNearestOre(drone.x, drone.y)
    end
    if not ore then
        error("No ore available")
    end
    if not Api._inRange(drone, ore) then
        error("Not in range of ore")
    end
    if drone.cargo >= drone.capacity then
        error("Cargo full")
    end
    if not ore:hasOre() then
        error("Ore depleted")
    end

    drone.state = "mining"
    drone.miningOreId = ore.id
    drone.miningTimer = C.MINE_DURATION

    -- spawn mining effect immediately
    local Effects = require("game.effects")
    Effects.spawnMiningEffect(ore.x, ore.y)

    Api.runner.waitUntil(function()
        return drone.state == "idle"
    end)
end

-- API: cargo() → number
function Api.cargo()
    return Api.world.getDrone():getCargo()
end

-- API: capacity() → number
function Api.capacity()
    return Api.world.getDrone():getCapacity()
end

-- API: deposit() — blocking via coroutine yield
function Api.deposit()
    local drone = Api.world.getDrone()
    local base = Api.world.getBase()
    if not base:isDroneInRange(drone) then
        error("Not at base")
    end
    if drone.cargo == 0 then
        return -- no-op
    end

    drone.state = "depositing"
    drone.depositTimer = C.DEPOSIT_DURATION

    Api.runner.waitUntil(function()
        return drone.state == "idle"
    end)
end

return Api
