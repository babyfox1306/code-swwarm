-- CODE SWARM — LÖVE2D Entry Point (V0.2 product pass)
-- Python is the player language. Lua remains the engine/runtime language.

local world = require("game.world")
local WorldCamera = require("game.world_camera")
local Assets = require("game.assets")
local Audio = require("game.audio")
local C = require("game.constants")

-- V0.1 modules retained only for regression/dev.
local Api = require("scripting.api")
local luaRunner = require("scripting.runner")

-- V0.2 production modules.
local pythonRunner = require("scripting.python_runner_v03")
local Editor = require("ui.editor_fixed")
local CoachPanel = require("ui.coach_panel_fixed")
local ErrorPanel = require("ui.error_panel")
local ApiRef = require("ui.api_reference")
local HudV02 = require("ui.hud_v02")
local Mission01 = require("coach.mission01")

local usePython = true
local runner = nil
local lastRunnerStatus = "idle"
local saveFile = "mission01_code.py"
local lastCargo = 0
local lastDeposited = 0
local lastDroneSimState = "idle"
local arrivedAtOreEmitted = false
local atBaseEmitted = false

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
    if starterInfo then return love.filesystem.read("data/mission01/starter.py") end
    return "# Welcome to CODE SWARM!\n# Read the Coach panel.\n"
end

local function loadStarterOnly()
    local starterInfo = love.filesystem.getInfo("data/mission01/starter.py")
    if starterInfo then return love.filesystem.read("data/mission01/starter.py") end
    return "# Welcome to CODE SWARM!\n# Read the Coach panel.\n"
end

local function saveEditorCode(text)
    love.filesystem.write(saveFile, text)
end

local function resetEditorToStarter()
    love.filesystem.remove(saveFile)
    local code = loadStarterOnly()
    Editor:setText(code)
    saveEditorCode(code)
    ErrorPanel:clear()
    Editor:clearHighlight()
    Mission01.init()
    CoachPanel:setStep(1)
    arrivedAtOreEmitted = false
    atBaseEmitted = false
end

-- ═══════════════════════════════════════════════════════════════
-- Action handler
-- ═══════════════════════════════════════════════════════════════

local function doAction(action)
    if action == "run" then
        -- Prevent duplicate F5/click while the worker is starting or already running.
        if runner.isRunning and runner.isRunning() then return end

        Audio.play("ui_click")
        local source = Editor:getText()
        if source == "" or source:match("^%s*$") then
            CoachPanel.coachText = "Your editor is empty.\nStart with: move_to(nearest_ore())"
            return
        end

        saveEditorCode(source)
        Mission01:onRunStart(source)
        runner.run(source)
        Audio.play("run_start")
        HudV02:setStatus(runner.getStatus())

    elseif action == "stop" then
        Audio.play("ui_click")
        Audio.play("run_stop")
        Mission01:onRunEnd("stopped")
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
        lastDroneSimState = "idle"
        arrivedAtOreEmitted = false
        atBaseEmitted = false
        HudV02:setStatus("idle")
        HudV02:setDeposited(0)
        HudV02:setCargo(0, C.CARGO_CAPACITY)

    elseif action == "reset_code" then
        Audio.play("ui_click")
        runner.stop()
        resetEditorToStarter()
        HudV02:setStatus("idle")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- love.load
-- ═══════════════════════════════════════════════════════════════

function love.load()
    love.window.setTitle("CODE SWARM")
    love.graphics.setBackgroundColor(0.08, 0.09, 0.12)
    love.graphics.setDefaultFilter("nearest", "nearest")

    Assets.load()
    Audio.load()
    world.setAssets(Assets)
    world.setAudio(Audio)
    world.init()

    Api.setWorld(world)
    luaRunner.init(world, Api)
    Api.setRunner(luaRunner)

    pythonRunner.init(world, Api)
    runner = usePython and pythonRunner or luaRunner
    Api.setRunner(runner)

    Editor.init(0, 0, 600, 300)
    CoachPanel.init(0, 0, 280, 300)
    ErrorPanel.init(0, 0, 280, 120)
    ApiRef.init(200, 80, 500, 400)
    HudV02.init(Editor, CoachPanel, ErrorPanel, ApiRef)

    local code = loadStarterCode()
    Editor:setText(code)
    Editor.onSave = function(text) saveEditorCode(text) end

    Mission01.init()
    CoachPanel:setStep(Mission01.getStep())
    lastCargo = world.getDrone():getCargo()
    lastDeposited = world.getDepositedOre()
    lastRunnerStatus = runner.getStatus()

    Audio.startAmbience()
end

-- ═══════════════════════════════════════════════════════════════
-- love.update
-- ═══════════════════════════════════════════════════════════════

function love.update(dt)
    -- Simulation first so blocking Python API calls see movement progress this frame.
    world.update(dt)
    runner.update(dt)

    if world.isWon() and runner.getStatus() ~= "won" then
        Mission01:onRunEnd("won")
        runner:onWin()
    end

    local status = runner.getStatus()

    -- A normal finite Python program used to return to idle without recording success.
    if (lastRunnerStatus == "running" or lastRunnerStatus == "starting") and status == "idle" then
        Mission01:onRunEnd("success")
    end

    HudV02:setStatus(status)
    HudV02:setDeposited(world.getDepositedOre())
    local drone = world.getDrone()
    HudV02:setCargo(drone:getCargo(), drone:getCapacity())

    -- Main owns error presentation and audio. Runner never plays error SFX itself.
    if status == "error" then
        if lastRunnerStatus ~= "error" then
            Audio.play("error")
            Mission01:onRunEnd("error")
        end

        local errMsg = runner.getError()
        if errMsg then
            local title, rest = errMsg:match("^(.-)\n\n(.*)")
            if not title then title = errMsg; rest = "" end
            ErrorPanel:setError(title, rest, "", runner.getErrorLine())
            if runner.getErrorLine() then Editor:highlightLine(runner.getErrorLine()) end
        end
    else
        ErrorPanel:clear()
        Editor:clearHighlight()
    end

    lastRunnerStatus = status

    Audio.update(dt, drone.state)
    HudV02:update(dt)

    -- Mission event trace.
    local deposited = world.getDepositedOre()
    local base = world.getBase()

    if drone.state == "idle" and lastDroneSimState == "moving" then
        Mission01:onEvent("move_success", { target = drone.lastMoveTarget })
    end
    lastDroneSimState = drone.state

    if drone.state == "idle" and drone.lastMoveTarget
        and drone.lastMoveTarget.type == "ore"
        and not arrivedAtOreEmitted then
        Mission01:onEvent("arrived_at_ore", { oreId = drone.lastMoveTarget.id })
        CoachPanel:setStep(Mission01.getStep())
        arrivedAtOreEmitted = true
    end

    if drone.cargo ~= lastCargo then
        if drone.cargo > lastCargo then
            Mission01:onEvent("mine_success", { cargo = drone.cargo })
        end
        Mission01:onEvent("cargo_changed", { cargo = drone.cargo })
        CoachPanel:setStep(Mission01.getStep())
        lastCargo = drone.cargo
    end

    if deposited ~= lastDeposited then
        Mission01:onEvent("deposited", { amount = deposited - lastDeposited, total = deposited })
        CoachPanel:setStep(Mission01.getStep())
        lastDeposited = deposited
    end

    if base:isDroneInRange(drone) and drone.cargo > 0 and not atBaseEmitted then
        Mission01:onEvent("at_base", { cargo = drone.cargo })
        CoachPanel:setStep(Mission01.getStep())
        atBaseEmitted = true
    elseif not base:isDroneInRange(drone) then
        atBaseEmitted = false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- Drawing / resize
-- ═══════════════════════════════════════════════════════════════

function love.resize(w, h)
    -- The fixed Coach wrapper preserves tutorial step/hint state during relayout.
    HudV02.relayout()
end

function love.draw()
    WorldCamera.setViewport(HudV02.worldX, HudV02.worldY, HudV02.worldW, HudV02.worldH)
    love.graphics.setScissor(HudV02.worldX, HudV02.worldY, HudV02.worldW, HudV02.worldH)
    WorldCamera.drawBackground()
    WorldCamera.begin()
    world.draw()
    WorldCamera.endDraw()
    love.graphics.setScissor()

    Editor:draw()
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
    if ApiRef.visible then
        ApiRef:handleKey(key)
        return
    end

    local action = HudV02:keypressed(key)
    if action then doAction(action) end
end

function love.textinput(text)
    HudV02:textinput(text)
end

function love.wheelmoved(dx, dy)
    HudV02:wheelmoved(dx, dy)
end

function love.quit()
    local code = Editor:getText()
    if code and code ~= "" then saveEditorCode(code) end
    if usePython then pythonRunner.stop() end
end
