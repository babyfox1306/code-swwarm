-- CODE SWARM — Python Runner V0.5 error-pipeline guard
-- Wraps v0.4 without changing process/IPC behavior.
-- Guarantees player-facing errors refer to the current editor buffer and
-- provides typo help for the six beginner API functions.

local Base = require("scripting.python_runner_v04")

local Runner = Base
local baseRun = Base.run
local baseGetError = Base.getError
local baseGetErrorLine = Base.getErrorLine
local baseGetErrorKind = Base.getErrorKind

local lastSource = ""
local sourceLineCount = 1

local KNOWN_CALLS = {
    "move_to",
    "nearest_ore",
    "mine",
    "cargo",
    "capacity",
    "deposit",
}

local function countLines(s)
    if not s or s == "" then return 1 end
    local n = 1
    for _ in s:gmatch("\n") do n = n + 1 end
    return n
end

local function getSourceLine(n)
    if not n or n < 1 then return nil end
    local i = 1
    for line in (lastSource .. "\n"):gmatch("(.-)\n") do
        if i == n then return line end
        i = i + 1
    end
    return nil
end

local function levenshtein(a, b)
    local m, n = #a, #b
    local prev = {}
    for j = 0, n do prev[j] = j end
    for i = 1, m do
        local cur = { [0] = i }
        local ca = a:sub(i, i)
        for j = 1, n do
            local cost = ca == b:sub(j, j) and 0 or 1
            local del = prev[j] + 1
            local ins = cur[j - 1] + 1
            local sub = prev[j - 1] + cost
            cur[j] = math.min(del, ins, sub)
        end
        prev = cur
    end
    return prev[n]
end

local function nearestKnown(name)
    if not name or name == "" then return nil end
    local best, bestDist = nil, math.huge
    for _, candidate in ipairs(KNOWN_CALLS) do
        local d = levenshtein(name, candidate)
        if d < bestDist then
            best, bestDist = candidate, d
        end
    end
    if bestDist <= 2 then return best end
    return nil
end

local function validPlayerLine()
    local line = baseGetErrorLine()
    if type(line) ~= "number" then return nil end
    line = math.floor(line)
    if line < 1 or line > sourceLineCount then return nil end
    return line
end

local function stripDuplicateLineReference(msg)
    if not msg then return nil end
    -- ErrorPanel already renders the line reference separately.
    return (msg:gsub("\n\nSee line %d+ in your editor%.$", ""))
end

function Runner.run(source)
    lastSource = source or ""
    sourceLineCount = countLines(lastSource)
    return baseRun(source)
end

function Runner.getErrorLine()
    return validPlayerLine()
end

function Runner.getErrorKind()
    return baseGetErrorKind()
end

function Runner.getError()
    local msg = stripDuplicateLineReference(baseGetError())
    local kind = baseGetErrorKind()
    local rawLine = baseGetErrorLine()
    local line = validPlayerLine()

    -- Never teach a bogus editor line. If the runtime reports a line outside
    -- the exact source buffer we sent, treat it as an internal mapping issue.
    if rawLine and not line then
        return "Python error\n\nCODE SWARM received an error location outside your current program. The error was not mapped to your code, so no fake line number is shown.\n\n" .. (msg or "")
    end

    if kind == "NameError" and line then
        local srcLine = getSourceLine(line) or ""
        local calledName = srcLine:match("([%a_][%w_]*)%s*%(")
        local suggestion = nearestKnown(calledName)
        if calledName and suggestion and calledName ~= suggestion then
            return "Unknown command: " .. calledName .. "\n\nPython does not know `" .. calledName .. "()`.\n\nDid you mean `" .. suggestion .. "()`?\n\nCheck the spelling on line " .. line .. "."
        end
    end

    return msg
end

return Runner
