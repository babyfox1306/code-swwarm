-- CODE SWARM — Python Script Runner (V0.2)
-- Spawns Python worker subprocess, communicates via file IPC,
-- yields simulation while waiting for Python responses.

local C = require("game.constants")

local PYTHON_WAIT = "__PYTHON_WAIT__"

local PythonRunner = {
    status = "idle",        -- idle | running | error | won | stopped
    errorMessage = nil,
    errorLine = nil,
    errorKind = nil,
    world = nil,
    api = nil,
    workerPid = nil,
    pythonExe = nil,
    ipcDir = nil,
    wallTimer = 0,
    WALL_TIMEOUT = 30,
    pendingApiCall = nil,
    _waitPredicate = nil,
}

-- ═══════════════════════════════════════════════════════════════
-- JSON helpers (minimal, for IPC only)
-- ═══════════════════════════════════════════════════════════════

local function jsonEncode(tbl)
    local parts = {}
    local keys = {}
    for k in pairs(tbl) do keys[#keys+1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        local v = tbl[k]
        local val
        if type(v) == "string" then
            val = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"')
                :gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
        elseif type(v) == "number" then
            val = tostring(v)
        elseif type(v) == "boolean" then
            val = v and "true" or "false"
        elseif v == nil then
            val = "null"
        else
            val = '"' .. tostring(v) .. '"'
        end
        parts[#parts+1] = '"' .. k .. '":' .. val
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function jsonDecode(s)
    if not s or s == "" then return nil end
    s = s:match("^%s*(.-)%s*$")
    if s:sub(1, 1) ~= "{" then return nil end
    local obj = {}
    -- Match "key":value patterns
    for k, v in s:gmatch('"([^"]+)"%s*:%s*([^-][^,}]*[^,}]?)') do
        v = v:match("^%s*(.-)%s*$")
        if v:sub(1, 1) == '"' and v:sub(-1) == '"' then
            obj[k] = v:sub(2, -2):gsub('\\n', '\n'):gsub('\\"', '"'):gsub('\\\\', '\\')
        elseif v == "true" then
            obj[k] = true
        elseif v == "false" then
            obj[k] = false
        elseif v == "null" then
            obj[k] = nil
        else
            obj[k] = tonumber(v) or v
        end
    end
    return obj
end

-- ═══════════════════════════════════════════════════════════════
-- File I/O helpers
-- ═══════════════════════════════════════════════════════════════

local function fileExists(path)
    local f = io.open(path, "r")
    if f then f:close(); return true end
    return false
end

local function writeFile(path, content)
    local f = io.open(path, "w")
    if f then f:write(content); f:close(); return true end
    return false
end

local function readFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function removeFile(path)
    os.remove(path)
end

-- ═══════════════════════════════════════════════════════════════
-- IPC directory + path helpers
-- ═══════════════════════════════════════════════════════════════

local function getIpcDir()
    if PythonRunner.ipcDir then return PythonRunner.ipcDir end
    local tmp = os.getenv("TEMP") or os.getenv("TMP") or os.tmpdir and os.tmpdir() or "/tmp"
    local dir = tmp:gsub("\\", "/") .. "/codeswarm_ipc"
    -- Create directory
    os.execute('mkdir "' .. dir .. '" 2>nul')
    PythonRunner.ipcDir = dir
    return dir
end

local function ipcPath(name)
    return getIpcDir() .. "/" .. name
end

-- ═══════════════════════════════════════════════════════════════
-- Python executable finder
-- ═══════════════════════════════════════════════════════════════

local function findPython()
    local envPy = os.getenv("CODESWARM_PYTHON")
    if envPy and fileExists(envPy) then return envPy end

    -- Bundled
    local src = love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory() or ""
    if src ~= "" then
        local bundled = src .. "/vendor/python/python.exe"
        if fileExists(bundled) then return bundled end
    end

    -- System PATH
    local handle = io.popen('where python 2>nul')
    if handle then
        local result = handle:read("*l")
        handle:close()
        if result and result ~= "" then
            -- where returns full path, take first line
            local path = result:match("^[^\r\n]+")
            if path and fileExists(path) then return path end
        end
    end

    -- Common locations
    local locations = {
        os.getenv("LOCALAPPDATA") .. "/Programs/Python/Python310/python.exe",
        os.getenv("LOCALAPPDATA") .. "/Programs/Python/Python311/python.exe",
        "C:/Python310/python.exe",
        "C:/Python311/python.exe",
    }
    for _, loc in ipairs(locations) do
        if loc and fileExists(loc) then return loc end
    end

    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- Worker process management
-- ═══════════════════════════════════════════════════════════════

local function spawnWorker()
    if PythonRunner.workerPid then return true end

    PythonRunner.pythonExe = findPython()
    if not PythonRunner.pythonExe then
        PythonRunner.status = "error"
        PythonRunner.errorMessage = "Python not found.\nInstall Python 3.10+ or set CODESWARM_PYTHON env var."
        return false
    end

    local dir = getIpcDir()

    -- Clean old IPC files
    removeFile(ipcPath("command.json"))
    removeFile(ipcPath("response.json"))
    removeFile(ipcPath("api_call.json"))
    removeFile(ipcPath("api_response.json"))

    -- Resolve worker.py path
    local src = love.filesystem.getSourceBaseDirectory and love.filesystem.getSourceBaseDirectory() or ""
    local workerPy = src ~= "" and (src .. "/python/worker.py") or "python/worker.py"

    -- Launch Python worker with IPC dir env var
    local cmd = string.format(
        'set CODESWARM_IPC_DIR=%s && start "" /B "%s" "%s"',
        dir,
        PythonRunner.pythonExe,
        workerPy
    )
    os.execute(cmd)

    PythonRunner.workerPid = true
    return true
end

local function killWorker()
    if not PythonRunner.workerPid then return end

    -- Try graceful stop first
    writeJson(ipcPath("command.json"), { fn = "stop", args = {} })
    local start = os.clock()
    while os.clock() - start < 0.3 do end  -- brief wait

    -- Force kill our worker only (by PID file)
    local pidContent = readFile(ipcPath("worker.pid"))
    if pidContent then
        local pid = pidContent:match("(%d+)")
        if pid then
            os.execute('taskkill /F /PID ' .. pid .. ' >nul 2>&1')
        end
    end

    PythonRunner.workerPid = nil
    removeFile(ipcPath("command.json"))
    removeFile(ipcPath("response.json"))
    removeFile(ipcPath("worker.pid"))
    removeFile(ipcPath("api_call.json"))
    removeFile(ipcPath("api_response.json"))
end

local function writeJson(path, tbl)
    writeFile(path, jsonEncode(tbl))
end

local function readJsonFile(path)
    local content = readFile(path)
    if not content or content == "" then return nil end
    return jsonDecode(content)
end

-- ═══════════════════════════════════════════════════════════════
-- Error mapping (Python errors → beginner-friendly messages)
-- ═══════════════════════════════════════════════════════════════

local function mapError(kind, message, line)
    local title = kind or "Error"
    local body = message or "Something went wrong."
    local hint = ""

    if kind == "SyntaxError" then
        if message and message:find("expected ':'") then
            title = "Missing colon"
            body = "A while or if line must end with a colon (:).\nThe colon tells Python: the repeated code comes next."
            hint = "Change:  while cargo() < 20\nTo:       while cargo() < 20:"
        else
            title = "Syntax error"
            body = "Python found something it didn't expect in your code."
            hint = "Check the line for typos or missing symbols."
        end
    elseif kind == "IndentationError" then
        title = "Indentation problem"
        body = "Lines inside a while block must be indented (moved right).\nUse 4 spaces at the start of each line inside the loop."
        hint = "Press Tab at the start of the line after while ...:"
    elseif kind == "NameError" then
        if message and message:find("minne") then
            title = "Unknown name: minne"
            body = "Python doesn't recognize minne. Did you mean mine()?\nSpelling matters — computer words must match exactly."
            hint = "Change:  minne()\nTo:       mine()"
        elseif message and message:find("is not defined") then
            title = "Unknown name"
            body = "This name isn't defined. Check your spelling or use nearest_ore()."
        end
    elseif kind == "RuntimeError" then
        if message and message:find("Not at base") then
            title = "Not at base"
            body = "deposit() only works at the base.\nUse move_to(\"base\") first."
        elseif message and message:find("Cargo full") then
            title = "Cargo full"
            body = "Your drone can't hold more ore (capacity is 5).\nGo to base and deposit()."
        elseif message and message:find("Instruction budget") then
            title = "Loop ran too long"
            body = "Your program may be stuck in an infinite loop.\nCheck: does your while condition ever become False?"
        elseif message and message:find("No ore") then
            title = "No ore available"
            body = "There's no ore to mine."
        elseif message and message:find("Not in range") then
            title = "Can't mine here"
            body = "mine() only works on an ore patch.\nFirst: move_to(nearest_ore())"
        elseif message and message:find("Invalid") then
            title = "Invalid target"
            body = "That target doesn't exist.\nTry nearest_ore() or \"base\"."
        end
    end

    return title, body, hint
end

-- ═══════════════════════════════════════════════════════════════
-- Public API
-- ═══════════════════════════════════════════════════════════════

function PythonRunner.init(worldRef, apiRef)
    PythonRunner.world = worldRef
    PythonRunner.api = apiRef
    PythonRunner.status = "idle"
    PythonRunner.errorMessage = nil
    PythonRunner.errorLine = nil
    PythonRunner.errorKind = nil
    PythonRunner.pendingApiCall = nil
    PythonRunner._waitPredicate = nil
end

-- Called by Api.move_to/mine/deposit when Python path is active
function PythonRunner.waitUntil(predicate)
    if PythonRunner.status ~= "running" then
        error("Execution stopped", 0)
    end
    PythonRunner._waitPredicate = predicate
    error(PYTHON_WAIT, 0)
end

function PythonRunner.run(source)
    if PythonRunner.status == "won" then return end

    PythonRunner.stop()

    if not source or source == "" then
        PythonRunner.status = "error"
        PythonRunner.errorMessage = "Editor is empty.\nWrite some Python code first."
        return
    end

    if not PythonRunner.workerPid then
        if not spawnWorker() then return end
    end

    -- Clean old response, send run command
    removeFile(ipcPath("response.json"))
    writeJson(ipcPath("command.json"), { fn = "run", args = { source } })

    PythonRunner.status = "running"
    PythonRunner.errorMessage = nil
    PythonRunner.errorLine = nil
    PythonRunner.errorKind = nil
    PythonRunner.wallTimer = 0
end

function PythonRunner.stop()
    if PythonRunner.status == "running" or PythonRunner.status == "error" then
        PythonRunner.status = "stopped"
    end
    PythonRunner.pendingApiCall = nil
    PythonRunner._waitPredicate = nil
    killWorker()
    if PythonRunner.world then
        local drone = PythonRunner.world.getDrone()
        if drone then drone:cancelAction() end
    end
end

function PythonRunner.reset()
    PythonRunner.stop()
    if PythonRunner.world then PythonRunner.world.reset() end
    PythonRunner.status = "idle"
    PythonRunner.errorMessage = nil
    PythonRunner.errorLine = nil
    PythonRunner.errorKind = nil
end

function PythonRunner.onWin()
    PythonRunner.stop()
    PythonRunner.status = "won"
end

function PythonRunner.getStatus()  return PythonRunner.status end
function PythonRunner.getError()   return PythonRunner.errorMessage end
function PythonRunner.getErrorLine() return PythonRunner.errorLine end
function PythonRunner.getErrorKind() return PythonRunner.errorKind end
function PythonRunner.isRunning()  return PythonRunner.status == "running" end

-- ═══════════════════════════════════════════════════════════════
-- Execute an API call from Python in the Lua simulation
-- ═══════════════════════════════════════════════════════════════

function PythonRunner._executeApiCall(fn, args)
    local api = PythonRunner.api
    if not api then return nil, "API not initialized" end

    PythonRunner._waitPredicate = nil
    local ok, result = pcall(function()
        if fn == "move_to" then
            api.move_to(args[1])
            return true
        elseif fn == "nearest_ore" then
            local target = api.nearest_ore()
            return tostring(target)
        elseif fn == "mine" then
            api.mine()
            return true
        elseif fn == "cargo" then
            return api.cargo()
        elseif fn == "capacity" then
            return api.capacity()
        elseif fn == "deposit" then
            api.deposit()
            return true
        else
            error("Unknown API: " .. tostring(fn), 0)
        end
    end)

    if not ok and result == PYTHON_WAIT then
        return nil, "pending"
    end
    if not ok then
        return nil, tostring(result)
    end
    return result, nil
end

local function finishPendingApiCall(callId, result, errMsg)
    local respData
    if errMsg then
        respData = { error = errMsg, call_id = callId }
    else
        respData = { result = result, call_id = callId }
    end
    writeJson(ipcPath("api_response.json"), respData)
    PythonRunner.pendingApiCall = nil
    PythonRunner._waitPredicate = nil
end

-- ═══════════════════════════════════════════════════════════════
-- Update: poll IPC, check timeout
-- ═══════════════════════════════════════════════════════════════

function PythonRunner.update(dt)
    if PythonRunner.status ~= "running" then return end

    -- Wall-clock timeout
    PythonRunner.wallTimer = PythonRunner.wallTimer + dt
    if PythonRunner.wallTimer > PythonRunner.WALL_TIMEOUT then
        PythonRunner.status = "error"
        PythonRunner.errorMessage = "Your program took too long.\nIt may be stuck in an infinite loop."
        PythonRunner.errorKind = "TimeoutError"
        killWorker()
        local Audio = require("game.audio")
        if Audio then Audio.play("error") end
        return
    end

    -- Resume pending blocking API call (move/mine/deposit)
    if PythonRunner.pendingApiCall then
        local pending = PythonRunner.pendingApiCall
        if PythonRunner.status ~= "running" then
            finishPendingApiCall(pending.call_id, nil, "Execution stopped")
            return
        end
        local pred = PythonRunner._waitPredicate
        if pred and pred() then
            finishPendingApiCall(pending.call_id, pending.result or true, nil)
            PythonRunner.wallTimer = 0
            if PythonRunner.world and PythonRunner.world.isWon() then
                PythonRunner:onWin()
            end
        end
        return
    end

    -- Poll for API call from Python (api_call.json)
    local callPath = ipcPath("api_call.json")
    local content = readFile(callPath)
    if content and content ~= "" then
        local resp = jsonDecode(content)
        removeFile(callPath)
        if resp and resp.fn then
            PythonRunner.wallTimer = 0  -- reset on progress
            local result, err = PythonRunner._executeApiCall(resp.fn, resp.args)
            if err == "pending" then
                PythonRunner.pendingApiCall = {
                    call_id = resp.call_id,
                    result = true,
                }
            elseif err then
                finishPendingApiCall(resp.call_id, nil, err)
            else
                finishPendingApiCall(resp.call_id, result, nil)
                if PythonRunner.world and PythonRunner.world.isWon() then
                    PythonRunner:onWin()
                end
            end
            return
        end
    end

    -- Poll for script completion/error (response.json from worker loop)
    local respPath = ipcPath("response.json")
    local respContent = readFile(respPath)
    if not respContent or respContent == "" then return end

    local resp2 = jsonDecode(respContent)
    removeFile(respPath)
    if not resp2 then return end

    if resp2.type == "error" then
        PythonRunner.status = "error"
        PythonRunner.errorKind = resp2.kind
        PythonRunner.errorLine = resp2.line
        local title, body, hint = mapError(resp2.kind, resp2.message, resp2.line)
        local msg = title .. "\n\n" .. body
        if hint ~= "" then msg = msg .. "\n\n" .. hint end
        if resp2.line then msg = msg .. "\n\nSee line " .. resp2.line .. " in your editor." end
        PythonRunner.errorMessage = msg
        killWorker()
        local Audio = require("game.audio")
        if Audio then Audio.play("error") end

    elseif resp2.type == "done" then
        PythonRunner.status = "idle"
        PythonRunner.wallTimer = 0
        if PythonRunner.world and PythonRunner.world.isWon() then
            PythonRunner:onWin()
        end
    end
end

return PythonRunner
