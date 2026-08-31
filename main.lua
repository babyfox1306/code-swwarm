-- CODE SWARM — LÖVE2D Entry Point (V0.2)
-- Supports both V0.1 Lua runner and V0.2 Python runner

local world = require("game.world")
local Assets = require("game.assets")
local Audio = require("game.audio")
local C = require("game.constants")

-- V0.1 modules (kept for regression/dev)
local Api = require("scripting.api")
local luaRunner = require("scripting.runner")

-- V0.2 modules
local pythonRunner = require("scripting.python_runner")
local Editor = require("ui.editor")
local CoachPanel = require("ui.coach_panel")
local ErrorPanel = require("ui.error_panel")
local ApiRef = require("ui.api_reference")
local HudV02 = require("ui.hud_v02")
local Mission01 = require("coach.mission01")

-- State
local usePython = true  -- toggle: true=V0.2 Python, false=V0.1 Lua
local runner = nil      -- active runner
local lastRunnerStatus = "idle"
local saveFile = "mission01_code.py"
local lastCargo = 0
local lastDeposited = 0
local lastDroneState = "idle"
local arrivedAtOreEmitted = false

-- ═══════════════════════════════════════════════════════════════
-- Save / Load editor code
-- ═══════════════════════════════════════════════════════════════

local function loadStarterCode()
    local info = love.filesystem.getInfo(saveFile)
    if info then
        local content = love.filesystem.read(saveFile)
        if content and content ~= "" then return content end
    end
    local starterInfo = love.filesystem.getInfo("data/mission01/starter.py")
    if starterInfo then
        return love.filesystem.read("data/mission01/starter.py")
    end
    return "# Welcome to CODE SWARM!\n# Read the Coach panel.\n"
end

local function saveEditorCode(text)
    love.filesystem.write(saveFile, text, "string")
end

-- ═══════════════════════════════════════════════════════════════
-- Action handler
-- ═══════════════════════════════════════════════════════════════

local function doAction(action)
    if action == "run" then
        Audio.play("ui_click")
        local source = Editor:getText()
        if source == "" or source:match("^%s*$") then
            CoachPanel.coachText = "Your editor is empty.\nStart with: move_to(nearest_ore())"
            return
        end
        -- Save before run
        saveEditorCode(source)
        runner.run(source)
        HudV02:setStatus(runner.getStatus())
    elseif action == "stop" then
        Audio.play("ui_click")
        Audio.play("run_stop")
        runner.stop()
        ErrorPanel:clear()
        HudV02:setStatus(runner.getStatus())
    elseif action == "reset" then
        Audio.play("ui_click")
        Audio.stopDroneHum()
        runner.reset()
        ErrorPanel:clear()
        Mission01.init()
        CoachPanel:setStep(1)
        lastCargo = 0
        lastDeposited = 0
        lastDroneState = "idle"
        arrivedAtOreEmitted = false
        HudV02:setStatus("idle")
        HudV02:setDeposited(0)
        HudV02:setCargo(0, C.CARGO_CAPACITY)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- love.load
-- ═══════════════════════════════════════════════════════════════

function love.load()
    love.window.setTitle("CODE SWARM")
    love.window.setMode(1280, 720, { resizable = false })
    love.graphics.setBackgroundColor(0.08, 0.09, 0.12)
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Load assets
    Assets.load()
    Audio.load()
    world.setAssets(Assets)
    world.setAudio(Audio)
    world.init()

    -- Init Lua runner (V0.1)
    Api.setWorld(world)
    luaRunner.init(world, Api)
    Api.setRunner(luaRunner)

    -- Init Python runner (V0.2)
    pythonRunner.init(world, Api)

    -- Choose active runner
    runner = usePython and pythonRunner or luaRunner
    Api.setRunner(runner)

    -- Init UI
    Editor.init(0, 0, 600, 300)
    CoachPanel.init(0, 0, 280, 300)
    ErrorPanel.init(0, 0, 280, 120)
    ApiRef.init(200, 80, 500, 400)
    HudV02.init(Editor, CoachPanel, ErrorPanel, ApiRef)

    -- Load code into editor
    local code = loadStarterCode()
    Editor:setText(code)

    -- Wire editor save callback
    Editor.onSave = function(text)
        saveEditorCode(text)
    end

    -- Init coach
    Mission01.init()
    CoachPanel:setStep(Mission01.getStep())
    lastCargo = world.getDrone():getCargo()
    lastDeposited = world.getDepositedOre()

    -- Start ambience
    Audio.startAmbience()
end

-- ═══════════════════════════════════════════════════════════════
-- love.update
-- ═══════════════════════════════════════════════════════════════

function love.update(dt)
    -- Update runner
    runner.update(dt)

    -- Update simulation
    world.update(dt)

    -- Win detection
    if world.isWon() and runner.getStatus() ~= "won" then
        runner:onWin()
    end

    -- Sync status to HUD
    local status = runner.getStatus()
    HudV02:setStatus(status)
    HudV02:setDeposited(world.getDepositedOre())
    local drone = world.getDrone()
    HudV02:setCargo(drone:getCargo(), drone:getCapacity())

    -- Error handling
    if status == "error" then
        if lastRunnerStatus ~= "error" then
            Audio.play("error")
        end
        -- Parse error for coach panel
        local errMsg = runner.getError()
        if errMsg then
            local title, rest = errMsg:match("^(.-)\n\n(.*)")
            if not title then title = errMsg; rest = "" end
            ErrorPanel:setError(title, rest, "", runner.getErrorLine())
            -- Highlight error line in editor
            if runner.getErrorLine() then
                Editor:highlightLine(runner.getErrorLine())
            end
        end
    else
        ErrorPanel:clear()
        Editor:clearHighlight()
    end

    lastRunnerStatus = status

    -- Audio
    Audio.update(dt, drone.state)
    HudV02:update(dt)

    -- Coach events — sync step with simulation
    local deposited = world.getDepositedOre()
    local base = world.getBase()

    if drone.state == "idle" and drone.lastMoveTarget
        and drone.lastMoveTarget.type == "ore"
        and not arrivedAtOreEmitted then
        Mission01:onEvent("arrived_at_ore", { oreId = drone.lastMoveTarget.id })
        CoachPanel:setStep(Mission01.getStep())
        arrivedAtOreEmitted = true
    end

    if drone.cargo ~= lastCargo then
        Mission01:onEvent("cargo_changed", { cargo = drone.cargo })
        CoachPanel:setStep(Mission01.getStep())
        lastCargo = drone.cargo
    end

    if deposited ~= lastDeposited then
        Mission01:onEvent("deposited", { amount = deposited - lastDeposited, total = deposited })
        CoachPanel:setStep(Mission01.getStep())
        lastDeposited = deposited
    end

    if base:isDroneInRange(drone) and drone.cargo > 0 and lastDroneState ~= "at_base" then
        Mission01:onEvent("at_base", { cargo = drone.cargo })
        CoachPanel:setStep(Mission01.getStep())
        lastDroneState = "at_base"
    elseif not base:isDroneInRange(drone) then
        lastDroneState = "away"
    end
end

-- ═══════════════════════════════════════════════════════════════
-- love.draw
-- ═══════════════════════════════════════════════════════════════

function love.draw()
    -- Draw world in its zone
    love.graphics.setScissor(HudV02.worldX, HudV02.worldY, HudV02.worldW, HudV02.worldH)
    world.draw()
    love.graphics.setScissor()

    -- Draw editor
    Editor:draw()

    -- Draw HUD (top bar, coach, errors, controls, overlays)
    HudV02:draw()
end

-- ═══════════════════════════════════════════════════════════════
-- Input callbacks
-- ═══════════════════════════════════════════════════════════════

function love.mousepressed(x, y, button)
    local action = HudV02:mousepressed(x, y, button)
    if action then doAction(action) end
end

function love.keypressed(key)
    -- API reference takes priority
    if ApiRef.visible then
        ApiRef:handleKey(key)
        return
    end

    local action = HudV02:keypressed(key)
    if action then
        doAction(action)
    end
end

function love.textinput(text)
    HudV02:textinput(text)
end

function love.wheelmoved(dx, dy)
    HudV02:wheelmoved(dx, dy)
end

-- ═══════════════════════════════════════════════════════════════
-- love.quit — cleanup
-- ═══════════════════════════════════════════════════════════════

function love.quit()
    -- Save editor code
    local code = Editor:getText()
    if code and code ~= "" then
        saveEditorCode(code)
    end
    -- Kill Python worker
    if usePython then
        pythonRunner.stop()
    end
end
