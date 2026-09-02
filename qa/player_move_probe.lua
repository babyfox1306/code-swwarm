-- CODE SWARM production-path probe for the first beginner command.
-- This intentionally executes the exact line taught to a new player:
--     move_to(nearest_ore())
-- through python_runner_v03 -> worker.py -> codeswarm.py -> Lua API mock.

package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    filesystem = {
        getSourceBaseDirectory = function() return "." end,
    },
    timer = {
        getTime = function() return os.clock() end,
    },
}

local Runner = require("scripting.python_runner_v03")

local movedTarget = nil
local drone = {
    cancelAction = function() end,
}

local world = {
    getDrone = function() return drone end,
    reset = function() end,
    isWon = function() return false end,
}

local target = setmetatable({}, {
    __tostring = function() return "ore#1" end,
})

local api = {
    nearest_ore = function()
        return target
    end,
    move_to = function(value)
        movedTarget = value
        return true
    end,
    mine = function() return true end,
    cargo = function() return 0 end,
    capacity = function() return 5 end,
    deposit = function() return true end,
}

Runner.init(world, api)
Runner.run("move_to(nearest_ore())\n")

local deadline = os.time() + 10
while os.time() <= deadline do
    Runner.update(0.02)
    local status = Runner.getStatus()
    if status == "idle" or status == "error" or status == "won" then
        break
    end
    os.execute("sleep 0.02")
end

local status = Runner.getStatus()
if status == "error" then
    io.stderr:write("PLAYER PATH FAIL: " .. tostring(Runner.getError()) .. "\n")
    Runner.stop()
    os.exit(1)
end

if movedTarget ~= "ore#1" then
    io.stderr:write("PLAYER PATH FAIL: move_to received " .. tostring(movedTarget) .. "\n")
    Runner.stop()
    os.exit(1)
end

if status ~= "idle" then
    io.stderr:write("PLAYER PATH FAIL: final runner status " .. tostring(status) .. "\n")
    Runner.stop()
    os.exit(1)
end

Runner.stop()
print("PLAYER PATH PASS: move_to(nearest_ore()) -> ore#1")
