-- CODE SWARM — Code Analyzer (Phase 1)
-- Lightweight string-pattern recognizer on Python source.
-- Used by Coach to detect what the player wrote — NOT to execute or transpile.
-- CANT parse Python via regex→Lua execution. Read-only string inspection.

local CodeAnalyzer = {}

-- hasWhileLoop: detect "while ... :" pattern
function CodeAnalyzer.hasWhileLoop(source)
    if not source or source == "" then return false end
    -- Match: "while" + whitespace + any content + ":"
    -- Allows: while True:, while cargo() < 5:, while cargo() < capacity():
    return source:find("while%s+.-%s*:") ~= nil
end

-- hasCall: detect function_name( pattern
function CodeAnalyzer.hasCall(source, funcName)
    if not source or source == "" or not funcName then return false end
    -- Match: funcName followed by "(" — allows whitespace before paren
    return source:find(funcName .. "%s*%(") ~= nil
end

-- mentionsNearestOre: detect nearest_ore() call
function CodeAnalyzer.mentionsNearestOre(source)
    return CodeAnalyzer.hasCall(source, "nearest_ore")
end

-- mentionsBase: detect "base" string in move_to or other context
function CodeAnalyzer.mentionsBase(source)
    if not source or source == "" then return false end
    return source:find("base") ~= nil
end

-- mentionsCapacity: detect capacity() in comparison
function CodeAnalyzer.mentionsCapacity(source)
    if not source or source == "" then return false end
    return source:find("capacity%s*%(") ~= nil
end

-- countCalls: count occurrences of a function call pattern
function CodeAnalyzer.countCalls(source, funcName)
    if not source or source == "" or not funcName then return 0 end
    local count = 0
    local pattern = funcName .. "%s*%("
    local pos = 1
    while true do
        local s, e = source:find(pattern, pos)
        if not s then break end
        count = count + 1
        pos = e + 1
    end
    return count
end

-- Smoke tests (run manually or via qa/):
--
-- hasWhileLoop:
--   "while True:"                    → true
--   "while cargo() < 5:"            → true
--   "while cargo() < capacity():"    → true
--   "for i in range(5):"             → false
--   "# just a comment"               → false
--
-- hasCall:
--   hasCall("mine()\n", "mine")              → true
--   hasCall("move_to(\"base\")", "move_to")  → true
--   hasCall("print(\"hi\")", "mine")         → false
--
-- mentionsNearestOre:
--   mentionsNearestOre("move_to(nearest_ore())")  → true
--   mentionsNearestOre("mine()\nwhile True:")     → false
--
-- countCalls:
--   countCalls("mine()\nmine()\n", "mine")  → 2
--   countCalls("move_to(x)\n", "mine")        → 0

return CodeAnalyzer
