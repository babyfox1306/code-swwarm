local C = require("game.constants")
local Sandbox = require("scripting.sandbox")

local Runner = {
    status = "idle",     -- idle | running | stopped | error | won
    errorMessage = nil,
    co = nil,
    fn = nil,
    world = nil,
    api = nil,
    instructionsThisFrame = 0,
}

-- Instruction budget hook
-- Hook fires every HOOK_INTERVAL instructions.
-- Budget is in real instructions, so we multiply count by interval.
local function hook(event)
    if event == "count" then
        Runner.instructionsThisFrame = Runner.instructionsThisFrame + C.HOOK_INSTRUCTION_INTERVAL
        if Runner.instructionsThisFrame > C.INSTRUCTION_BUDGET then
            error("Execution stopped: instruction budget exceeded", 0)
        end
    end
end

function Runner.init(worldRef, apiRef)
    Runner.world = worldRef
    Runner.api = apiRef
    Runner.status = "idle"
    Runner.errorMessage = nil
    Runner.co = nil
    Runner.fn = nil
end

function Runner.getStatus(self_or_runner)
    local r = type(self_or_runner) == "table" and self_or_runner or Runner
    return r.status
end

function Runner.getError(self_or_runner)
    local r = type(self_or_runner) == "table" and self_or_runner or Runner
    return r.errorMessage
end

function Runner.isRunning(self_or_runner)
    local r = type(self_or_runner) == "table" and self_or_runner or Runner
    return r.status == "running"
end

function Runner.update(self_or_runner, dt)
    local r = type(self_or_runner) == "table" and self_or_runner or Runner
    if r.status ~= "running" or not r.co then
        return
    end

    r.instructionsThisFrame = 0
    local ok, err = coroutine.resume(r.co)

    if not ok then
        if r.co then
            debug.sethook(r.co, nil)
        end
        r.status = "error"
        r.errorMessage = tostring(err)
        r.co = nil
        -- cancel drone action
        local drone = r.world.getDrone()
        drone:cancelAction()
        return
    end

    if coroutine.status(r.co) == "dead" then
        if r.co then
            debug.sethook(r.co, nil)
        end
        if r.status == "running" then
            r.status = "idle"
        end
        r.co = nil
    end
end

function Runner.run()
    if Runner.status == "won" then
        return
    end

    Runner.stop()

    local source, err = Sandbox.loadProgram()
    if not source then
        Runner.status = "error"
        Runner.errorMessage = err
        return
    end

    local env = Sandbox.createEnv(Runner.api)
    local fn, compileErr = Sandbox.compile(source, env)
    if not fn then
        Runner.status = "error"
        Runner.errorMessage = compileErr
        return
    end

    Runner.fn = fn
    Runner.co = coroutine.create(function()
        debug.sethook(hook, "c", C.HOOK_INSTRUCTION_INTERVAL)
        fn()
    end)
    Runner.status = "running"
    Runner.errorMessage = nil
end

-- STOP: works from running, error, or any active state
function Runner.stop()
    if Runner.co then
        debug.sethook(Runner.co, nil)
        Runner.co = nil
    end
    Runner.fn = nil

    if Runner.status == "running" or Runner.status == "error" then
        Runner.status = "stopped"
    end

    -- cancel drone pending action
    if Runner.world then
        local drone = Runner.world.getDrone()
        drone:cancelAction()
    end
end

function Runner.reset()
    Runner.stop()
    if Runner.world then
        Runner.world.reset()
    end
    Runner.status = "idle"
    Runner.errorMessage = nil
end

function Runner.onWin()
    Runner.stop()
    Runner.status = "won"
end

-- coroutine helper: yield until predicate is true
function Runner.waitUntil(predicate)
    while not predicate() do
        if Runner.status ~= "running" then
            error("Execution stopped", 0)
        end
        coroutine.yield("wait")
    end
end

-- yield one frame
function Runner.yield()
    coroutine.yield("api")
end

return Runner
