-- CODE SWARM — Mission 01 Coach
-- Step state machine with auto-advance on simulation events.

local Mission01 = {
    step = 1,
    maxSteps = 7,
    events = {},  -- log of events
}

function Mission01.init()
    Mission01.step = 1
    Mission01.events = {}
end

function Mission01.getStep()
    return Mission01.step
end

function Mission01.setStep(n)
    Mission01.step = math.max(1, math.min(n, Mission01.maxSteps))
end

-- Called when simulation events happen
function Mission01:onEvent(name, data)
    table.insert(Mission01.events, { name = name, data = data, step = Mission01.step })

    -- Auto-advance logic (soft guidance)
    if name == "arrived_at_ore" and Mission01.step == 1 then
        Mission01.step = 2
    end

    if name == "cargo_changed" and data then
        if data.cargo >= 1 and Mission01.step == 2 then
            Mission01.step = 3
        end
        if data.cargo >= 5 and Mission01.step == 4 then
            Mission01.step = 5
        end
    end

    if name == "deposited" and data then
        if data.amount > 0 and Mission01.step <= 6 then
            Mission01.step = 7
        end
    end

    if name == "at_base" and data then
        if data.cargo > 0 and Mission01.step == 5 then
            Mission01.step = 6
        end
    end
end

function Mission01:getCoachText()
    local texts = {
        "Move to the nearest ore: move_to(nearest_ore())",
        "Mine the ore: mine()",
        "Repeat with a while loop",
        "Notice cargo() >= capacity()",
        "Go to base: move_to(\"base\")",
        "Deposit: deposit()",
        "Automate: combine all steps!",
    }
    return texts[Mission01.step] or ""
end

return Mission01
