local C = require("game.constants")
local Sandbox = require("scripting.sandbox")

local jit_ok, jit = pcall(require, "jit")

local Runner = {
    status = "idle",     -- idle | running | stopped | error | won
    errorMessage = nil,
    co = nil,
    fn = nil,
    world = nil,
    api = nil,
    instructionsThisFrame = 0,
}

-- Instruction budget hook (count mode: fires every HOOK_INSTRUCTION_INTERVAL ops)
local function hook(event)
    if event == "count" then
        Runner.instructionsThisFrame = Runner.instructionsThisFrame + C.HOOK_INSTRUCTION_INTERVAL
        if Runner.instructionsThisFrame > C.INSTRUCTION_BUDGET then
            error("Execution stopped: instruction budget exceeded", 0)
        end
    end
end

local function clearHook(co)
    if co then
        debug.sethook(co, nil)
    end
end

local function armHook(co)
    debug.sethook(co, hook, "c", C.HOOK_INSTRUCTION_INTERVAL)
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
    local co = r.co

    -- Arm hook only for this resume; clear before simulation/draw runs.
    -- JIT-compiled loops skip hooks unless jit.off() was applied to player fn.
    armHook(co)
    local ok, err = coroutine.resume(co)
    clearHook(co)

    if not ok then
        r.status = "error"
        r.errorMessage = tostring(err)
        r.co = nil
        local drone = r.world.getDrone()
        drone:cancelAction()
        return
    end

    if coroutine.status(co) == "dead" then
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

    -- LuaJIT: JIT-compiled code does not invoke debug hooks in tight loops.
    -- Disable JIT for the player chunk and everything it calls.
    if jit_ok and jit.off then
        jit.off(fn, true)
    end

    Runner.fn = fn
    Runner.co = coroutine.create(function()
        fn()
    end)
    Runner.status = "running"
    Runner.errorMessage = nil
end

-- STOP: works from running, error, or any active state
function Runner.stop()
    if Runner.co then
        clearHook(Runner.co)
        Runner.co = nil
    end
    Runner.fn = nil

    if Runner.status == "running" or Runner.status == "error" then
        Runner.status = "stopped"
    end

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

function Runner.waitUntil(predicate)
    while not predicate() do
        if Runner.status ~= "running" then
            error("Execution stopped", 0)
        end
        coroutine.yield("wait")
    end
end

function Runner.yield()
    coroutine.yield("api")
end

return Runner
