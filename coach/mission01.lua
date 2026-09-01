-- CODE SWARM — Mission 01 Coach
-- Step state machine with auto-advance on simulation events.
-- Phase 1: added session trace + code analyzer integration for Step 3→4 fix.

local CodeAnalyzer = require("coach.code_analyzer")

local Mission01 = {
    step = 1,
    maxSteps = 7,
    events = {},  -- log of events
    -- Session trace (Phase 1) — reset each RUN
    lastSource = "",
    lastRunResult = "idle",  -- idle | success | error | stopped
    mineCountThisRun = 0,
    moveCountThisRun = 0,
    depositCountThisRun = 0,
    eventsThisRun = {},
}

function Mission01.init()
    Mission01.step = 1
    Mission01.events = {}
    Mission01:resetSession()
end

-- Reset session trace — called at start of each RUN
function Mission01:resetSession()
    self.lastSource = ""
    self.lastRunResult = "idle"
    self.mineCountThisRun = 0
    self.moveCountThisRun = 0
    self.depositCountThisRun = 0
    self.eventsThisRun = {}
end

-- Called by main.lua when RUN starts
function Mission01:onRunStart(source)
    self:resetSession()
    self.lastSource = source or ""
    self.lastRunResult = "running"
end

-- Called by main.lua when RUN ends
function Mission01:onRunEnd(result)
    self.lastRunResult = result or "idle"
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
    table.insert(Mission01.eventsThisRun, { name = name, data = data })

    -- Track per-run counters
    if name == "mine_success" then
        Mission01.mineCountThisRun = Mission01.mineCountThisRun + 1
    end
    if name == "move_success" then
        Mission01.moveCountThisRun = Mission01.moveCountThisRun + 1
    end
    if name == "deposited" and data then
        Mission01.depositCountThisRun = Mission01.depositCountThisRun + 1
    end

    -- Auto-advance logic
    -- Step 1 → 2: arrived at ore
    if name == "arrived_at_ore" and Mission01.step == 1 then
        Mission01.step = 2
    end

    -- Step 2 → 3: mined at least once (cargo >= 1)
    if name == "cargo_changed" and data then
        if data.cargo >= 1 and Mission01.step == 2 then
            Mission01.step = 3
        end
    end

    -- Step 3 → 4: code has while loop AND (cargo > 1 OR mined >= 2 times this run)
    -- This is the Phase 1 fix — previously a DEAD END.
    if Mission01.step == 3 then
        local src = Mission01.lastSource
        local hasLoop = CodeAnalyzer.hasWhileLoop(src)
        local cargo = (data and data.cargo) or 0
        local minedEnough = Mission01.mineCountThisRun >= 2
        if hasLoop and (cargo > 1 or minedEnough) then
            Mission01.step = 4
        end
    end

    -- Step 4 → 5: cargo full (cargo >= capacity = 5)
    if name == "cargo_changed" and data then
        if data.cargo >= 5 and Mission01.step == 4 then
            Mission01.step = 5
        end
    end

    -- Step 5 → 6: at base with cargo > 0
    if name == "at_base" and data then
        if data.cargo > 0 and Mission01.step == 5 then
            Mission01.step = 6
        end
    end

    -- Step 6 → 7: deposited successfully
    if name == "deposited" and data then
        if data.amount > 0 and Mission01.step == 6 then
            Mission01.step = 7
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
