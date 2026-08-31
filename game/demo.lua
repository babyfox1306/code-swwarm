local C = require("game.constants")

local Demo = {
    active = false,
    phase = "idle",
    targetOre = nil,
}

function Demo.start(world)
    if Demo.active then return end
    Demo.active = true
    Demo.phase = "find_ore"
    Demo.targetOre = nil
end

function Demo.stop()
    Demo.active = false
    Demo.phase = "idle"
    Demo.targetOre = nil
end

function Demo.update(dt, world)
    if not Demo.active then return end
    local drone = world.getDrone()

    if Demo.phase == "find_ore" then
        local ore = world.findNearestOre(drone.x, drone.y)
        if not ore then
            Demo.stop()
            return
        end
        Demo.targetOre = ore
        -- start moving to ore
        drone.targetX = ore.x
        drone.targetY = ore.y
        drone.state = "moving"
        Demo.phase = "move_to_ore"

    elseif Demo.phase == "move_to_ore" then
        if drone.state == "idle" then
            -- arrived, start mining
            if Demo.targetOre and Demo.targetOre:hasOre() and drone.cargo < drone.capacity then
                drone.state = "mining"
                drone.miningOreId = Demo.targetOre.id
                drone.miningTimer = C.MINE_DURATION
                Demo.phase = "mining"
            else
                Demo.phase = "move_to_base"
            end
        end

    elseif Demo.phase == "mining" then
        if drone.state == "idle" then
            -- mining complete (state set idle by world.update)
            if drone.cargo < drone.capacity then
                -- check if same ore still has ore
                if Demo.targetOre and Demo.targetOre:hasOre() then
                    drone.state = "mining"
                    drone.miningOreId = Demo.targetOre.id
                    drone.miningTimer = C.MINE_DURATION
                else
                    -- find new ore or go to base
                    local ore = world.findNearestOre(drone.x, drone.y)
                    if ore then
                        Demo.targetOre = ore
                        drone.targetX = ore.x
                        drone.targetY = ore.y
                        drone.state = "moving"
                        Demo.phase = "move_to_ore"
                    else
                        Demo.phase = "move_to_base"
                    end
                end
            else
                Demo.phase = "move_to_base"
            end
        end

    elseif Demo.phase == "move_to_base" then
        if drone.state == "idle" then
            drone.targetX = C.BASE_X
            drone.targetY = C.BASE_Y
            drone.state = "moving"
            Demo.phase = "moving_to_base"
        end

    elseif Demo.phase == "moving_to_base" then
        if drone.state == "idle" then
            -- arrived at base
            if drone.cargo > 0 then
                drone.state = "depositing"
                drone.depositTimer = C.DEPOSIT_DURATION
                Demo.phase = "depositing"
            else
                Demo.phase = "find_ore"
            end
        end

    elseif Demo.phase == "depositing" then
        if drone.state == "idle" then
            -- deposit complete
            Demo.phase = "find_ore"
        end
    end
end

return Demo
