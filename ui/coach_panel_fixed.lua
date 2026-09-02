-- CODE SWARM — Coach panel hotfix wrapper
-- 1) relayout/F11 must not reset tutorial progress to Step 1
-- 2) hints are runtime data, not regex-parsed JSON strings with escaped quotes

local CoachPanel = require("ui.coach_panel")
local originalInit = CoachPanel.init
local initialized = false

local HINTS = {
    [1] = {
        "You need two commands together: find ore, then move there.",
        "nearest_ore() gives you a destination. move_to(...) sends the drone there.",
        "Put nearest_ore() inside move_to(...).",
        "move_to(nearest_ore())",
    },
    [2] = {
        "The drone is at ore, but cargo is still empty.",
        "Use the mining command after the move command.",
        "The command takes no arguments.",
        "mine()",
    },
    [3] = {
        "Repeating mine() by hand works, but Python can repeat it for you.",
        "A while loop repeats indented lines while a condition is True.",
        "Try repeating move_to(nearest_ore()) and mine() while cargo is below capacity.",
        "while cargo() < capacity():\n    move_to(nearest_ore())\n    mine()",
    },
    [4] = {
        "Watch the CARGO counter. The drone eventually becomes full.",
        "cargo() tells you how much ore is loaded; capacity() tells you the limit.",
        "When cargo() reaches capacity(), mining should stop and the drone needs a new job.",
        "while cargo() < capacity():\n    move_to(nearest_ore())\n    mine()",
    },
    [5] = {
        "Full cargo is useful only if you bring it home.",
        "move_to(...) also accepts the base as a destination.",
        "The base destination is the string \"base\".",
        "move_to(\"base\")",
    },
    [6] = {
        "You are at base with ore still inside the drone.",
        "There is one command that transfers all cargo into the facility.",
        "Call deposit() after moving to base.",
        "deposit()",
    },
    [7] = {
        "One trip works. Now make the whole trip repeat automatically.",
        "Use an outer while True: loop around the full mine -> return -> deposit cycle.",
        "Inside it: fill cargo, return to base, deposit, then repeat.",
        "while True:\n    while cargo() < capacity():\n        move_to(nearest_ore())\n        mine()\n    move_to(\"base\")\n    deposit()",
    },
}

function CoachPanel:_loadHints()
    self.hints = HINTS
end

function CoachPanel.init(x, y, w, h)
    local oldStep = CoachPanel.step
    local oldTier = CoachPanel.hintTier
    local oldText = CoachPanel.coachText
    local oldTitle = CoachPanel.stepTitle

    originalInit(x, y, w, h)

    if initialized then
        CoachPanel:setStep(oldStep or 1)
        CoachPanel.hintTier = oldTier or 0
        if oldText and oldText ~= "" then CoachPanel.coachText = oldText end
        if oldTitle and oldTitle ~= "" then CoachPanel.stepTitle = oldTitle end
    end
    initialized = true
end

return CoachPanel
