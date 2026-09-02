-- CODE SWARM — Python Runner V0.4
-- Windows-first production runner.
-- Key invariant: when launched with `love .`, runtime files are resolved from
-- love.filesystem.getSource() (the source directory), NOT getSourceBaseDirectory()
-- (the directory containing the source). The old behavior pointed one level up.

local IPC = require("scripting.ipc_protocol")

local PYTHON_WAIT = "__PYTHON_WAIT__"
local IS_WINDOWS = package.config:sub(1, 1) == "\\"

local PythonRunner = {
    status = "idle", -- idle | starting | running | error | won | stopped
    errorMessage = nil,
    errorLine = nil,
    errorKind = nil,
    world = nil,
    api = nil,
    workerSpawned = false,
    workerPid = nil,
    pythonExe = nil,
    runtimeRoot = nil,
    ipcDir = nil,
    pendingSource = nil,
    startTimer = 0,
    START_TIMEOUT = 5,
    wallTimer = 0,
    WALL_TIMEOUT = 30,
    pendingApiCall = nil,
    _waitPredicate = nil,
}

local function normalizePath(p)
    return (p or ""):gsub("\\", "/"):gsub("/+$", "")
end

local function dirname(p)
    p = normalizePath(p)
    return p:match("^(.*)/[^/]+$") or "."
end

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then f:close(); return true end
    return false
end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

local function removeFile(path)
    if path then os.remove(path) end
end

local function winPath(p)
    return (p or ""):gsub("/", "\\")
end

local function getRuntimeRoot()
    if PythonRunner.runtimeRoot then return PythonRunner.runtimeRoot end

    local fs = love and love.filesystem
    local root = ""

    if fs then
        local fused = fs.isFused and fs.isFused() or false
        if fused then
            -- Fused build: external Python/runtime files are expected next to exe.
            root = fs.getSourceBaseDirectory and fs.getSourceBaseDirectory() or ""
        else
            -- Dev / `love .`: getSource() is the actual source directory.
            root = fs.getSource and fs.getSource() or ""
            root = normalizePath(root)
            if root:lower():match("%.love$") then
                root = dirname(root)
            end
        end

        if root == "" and fs.getWorkingDirectory then
            root = fs.getWorkingDirectory()
        end
    end

    if root == "" then root = "." end
    PythonRunner.runtimeRoot = normalizePath(root)
    return PythonRunner.runtimeRoot
end

local function unescapeJsonString(s)
    if not s then return nil end
    return s:gsub('\\"', '"')
            :gsub('\\n', '\n')
            :gsub('\\r', '\r')
            :gsub('\\t', '\t')
            :gsub('\\b', '\b')
            :gsub('\\f', '\f')
            :gsub('\\\\', '\\')
end

local function extractStringField(s, key)
    if not s then return nil end
    local _, e = s:find('"' .. key .. '"%s*:%s*"')
    if not e then return nil end
    local i, out, escaped = e + 1, {}, false
    while i <= #s do
        local ch = s:sub(i, i)
        if escaped then
            out[#out + 1] = "\\" .. ch
            escaped = false
        elseif ch == "\\" then
            escaped = true
        elseif ch == '"' then
            return unescapeJsonString(table.concat(out))
        else
            out[#out + 1] = ch
        end
        i = i + 1
    end
    return nil
end

local function extractNumberField(s, key)
    if not s then return nil end
    local raw = s:match('"' .. key .. '"%s*:%s*(-?%d+%.?%d*)')
    return raw and tonumber(raw) or nil
end

local function extractStringArray(s, key)
    local values = {}
    if not s then return values end
    local _, e = s:find('"' .. key .. '"%s*:%s*%[')
    if not e then return values end
    local i = e + 1
    while i <= #s do
        local ch = s:sub(i, i)
        if ch == "]" then break end
        if ch == '"' then
            i = i + 1
            local out, escaped = {}, false
            while i <= #s do
                local c = s:sub(i, i)
                if escaped then
                    out[#out + 1] = "\\" .. c
                    escaped = false
                elseif c == "\\" then
                    escaped = true
                elseif c == '"' then
                    values[#values + 1] = unescapeJsonString(table.concat(out))
                    break
                else
                    out[#out + 1] = c
                end
                i = i + 1
            end
        end
        i = i + 1
    end
    return values
end

local function parseApiCall(content)
    local fn = extractStringField(content, "fn")
    local callId = extractNumberField(content, "call_id")
    if not fn or not callId then return nil end
    return { fn = fn, call_id = callId, args = extractStringArray(content, "args") }
end

local function parseWorkerResponse(content)
    local responseType = extractStringField(content, "type")
    if not responseType then return nil end
    return {
        type = responseType,
        kind = extractStringField(content, "kind"),
        message = extractStringField(content, "message"),
        line = extractNumberField(content, "line"),
    }
end

local function makeSessionDir()
    local tmp = os.getenv("TEMP") or os.getenv("TMP") or "."
    local clockPart = 0
    if love and love.timer and love.timer.getTime then
        clockPart = math.floor(love.timer.getTime() * 1000000) % 1000000000
    end
    local session = string.format(
        "codeswarm_ipc_%d_%d_%d",
        os.time(), clockPart, math.random(100000, 999999)
    )
    local dir = normalizePath(tmp) .. "/" .. session
    if IS_WINDOWS then
        os.execute('mkdir "' .. winPath(dir) .. '" >nul 2>&1')
    else
        os.execute('mkdir -p "' .. dir .. '" >/dev/null 2>&1')
    end
    return dir
end

local function ipcPath(name)
    if not PythonRunner.ipcDir then PythonRunner.ipcDir = makeSessionDir() end
    return PythonRunner.ipcDir .. "/" .. name
end

local IPC_FILES = {
    "command.json", "response.json", "api_call.json", "api_response.json",
    "worker.pid", "worker_error.txt",
    "command.json.tmp", "response.json.tmp", "api_call.json.tmp", "api_response.json.tmp",
}

local function cleanupIpcFiles()
    for _, name in ipairs(IPC_FILES) do removeFile(ipcPath(name)) end
end

local function isBadPythonPath(path)
    if not path or path == "" then return true end
    return path:lower():find("windowsapps", 1, true) ~= nil
end

local function findPython()
    local envPy = os.getenv("CODESWARM_PYTHON")
    if envPy and fileExists(envPy) and not isBadPythonPath(envPy) then
        return normalizePath(envPy)
    end

    local root = getRuntimeRoot()
    local bundled = root .. "/vendor/python/python.exe"
    if fileExists(bundled) then return bundled end

    local localApp = os.getenv("LOCALAPPDATA")
    local locations = {}
    if localApp then
        local base = normalizePath(localApp) .. "/Programs/Python"
        locations[#locations + 1] = base .. "/Python311/python.exe"
        locations[#locations + 1] = base .. "/Python310/python.exe"
        locations[#locations + 1] = base .. "/Python312/python.exe"
    end
    locations[#locations + 1] = "C:/Python311/python.exe"
    locations[#locations + 1] = "C:/Python310/python.exe"

    for _, loc in ipairs(locations) do
        if fileExists(loc) and not isBadPythonPath(loc) then return loc end
    end

    if IS_WINDOWS then
        local handle = io.popen('where python 2>nul')
        if handle then
            for line in handle:lines() do
                local path = line:match("^%s*(.-)%s*$")
                if path and path ~= "" and fileExists(path) and not isBadPythonPath(path) then
                    handle:close()
                    return normalizePath(path)
                end
            end
            handle:close()
        end
    end

    return nil
end

local function setInternalError(message, kind)
    PythonRunner.status = "error"
    PythonRunner.errorKind = kind or "InternalError"
    PythonRunner.errorMessage = message
end

local function spawnWorker()
    local root = getRuntimeRoot()
    PythonRunner.pythonExe = findPython()
    if not PythonRunner.pythonExe then
        setInternalError(
            "Python runtime not found.\nExpected bundled runtime at:\n" ..
            root .. "/vendor/python/python.exe",
            "RuntimeMissing"
        )
        return false
    end

    local workerPy = root .. "/python/worker.py"
    local launcher = root .. "/scripts/launch-worker.bat"

    -- Fail immediately with useful diagnostics instead of a fake 5-second timeout.
    if not fileExists(workerPy) then
        setInternalError(
            "CODE SWARM could not find its Python worker.\n\n" ..
            "Runtime root: " .. root .. "\n" ..
            "Expected: " .. workerPy,
            "WorkerPathError"
        )
        return false
    end

    if not PythonRunner.ipcDir then PythonRunner.ipcDir = makeSessionDir() end
    cleanupIpcFiles()

    local py = winPath(PythonRunner.pythonExe)
    local worker = winPath(workerPy)
    local ipcDir = winPath(PythonRunner.ipcDir)
    local cmd

    if IS_WINDOWS and fileExists(launcher) then
        cmd = string.format(
            'cmd.exe /D /S /C "\"%s\" \"%s\" \"%s\" \"%s\""',
            winPath(launcher), py, worker, ipcDir
        )
    elseif IS_WINDOWS then
        cmd = string.format(
            'cmd.exe /D /S /C "start \"\" /B \"%s\" \"%s\" \"%s\""',
            py, worker, ipcDir
        )
    else
        cmd = string.format(
            '"%s" "%s" "%s" >/dev/null 2>&1 &',
            PythonRunner.pythonExe, workerPy, PythonRunner.ipcDir
        )
    end

    os.execute(cmd)
    PythonRunner.workerSpawned = true
    PythonRunner.workerPid = nil
    PythonRunner.startTimer = 0
    return true
end

local function killWorker()
    if not PythonRunner.workerSpawned then return end

    local pidContent = readFile(ipcPath("worker.pid"))
    local pid = pidContent and tonumber(pidContent:match("(%d+)")) or nil

    IPC.writeJson(ipcPath("command.json"), { fn = "stop", args = {} })

    if pid then
        if IS_WINDOWS then
            os.execute('taskkill /T /F /PID ' .. pid .. ' >nul 2>&1')
        else
            os.execute('kill -TERM ' .. pid .. ' >/dev/null 2>&1')
        end
    end

    PythonRunner.workerSpawned = false
    PythonRunner.workerPid = nil
    PythonRunner.pendingSource = nil
    cleanupIpcFiles()
end

local function mapError(kind, message)
    local title = kind or "Error"
    local body = message or "Something went wrong."
    local hint = ""

    if kind == "SyntaxError" then
        title = "Python syntax problem"
        body = "Python could not understand this line."
        hint = "Check spelling, parentheses, quotes, and ':' after while/if."
    elseif kind == "IndentationError" then
        title = "Indentation problem"
        body = "Python uses indentation to show which lines belong inside a block."
        hint = "Indent lines inside while/if with 4 spaces."
    elseif kind == "NameError" then
        local badName = message and message:match("name '([^']+)'")
        title = badName and ("Unknown name: " .. badName) or "Unknown name"
        body = "Python does not recognize that name. Check spelling."
        if badName == "minne" then hint = "Did you mean mine()?" end
    elseif kind == "RuntimeError" then
        if message and message:find("Not at base") then
            title, body, hint = "Not at base", "deposit() works only at base.", 'Use move_to("base") first.'
        elseif message and message:find("Cargo full") then
            title, body, hint = "Cargo full", "The drone cannot mine more.", "Return to base and deposit()."
        elseif message and message:find("Instruction budget") then
            title, body, hint = "Loop ran too long", "Your program is repeating without useful progress.", "Check the while condition."
        elseif message and message:find("Not in range") then
            title, body, hint = "Cannot mine here", "The drone is not close enough to ore.", "Move to nearest_ore() first."
        elseif message and message:find("Invalid") then
            title, body, hint = "Invalid target", "That destination does not exist.", 'Use nearest_ore() or "base".'
        end
    end

    return title, body, hint
end

function PythonRunner.init(worldRef, apiRef)
    PythonRunner.world = worldRef
    PythonRunner.api = apiRef
    PythonRunner.status = "idle"
    PythonRunner.errorMessage = nil
    PythonRunner.errorLine = nil
    PythonRunner.errorKind = nil
    PythonRunner.pendingApiCall = nil
    PythonRunner._waitPredicate = nil
    PythonRunner.pendingSource = nil
    PythonRunner.wallTimer = 0
    PythonRunner.startTimer = 0
    PythonRunner.workerSpawned = false
    PythonRunner.workerPid = nil
    PythonRunner.runtimeRoot = nil
    PythonRunner.ipcDir = makeSessionDir()
    cleanupIpcFiles()
end

function PythonRunner.waitUntil(predicate)
    if PythonRunner.status ~= "running" then error("Execution stopped", 0) end
    PythonRunner._waitPredicate = predicate
    error(PYTHON_WAIT, 0)
end

function PythonRunner.run(source)
    if PythonRunner.status == "won" then return end
    PythonRunner.stop()

    if not source or source:match("^%s*$") then
        setInternalError("Editor is empty.\nWrite some Python code first.", "EmptyProgram")
        return
    end

    PythonRunner.errorMessage = nil
    PythonRunner.errorLine = nil
    PythonRunner.errorKind = nil
    PythonRunner.pendingApiCall = nil
    PythonRunner._waitPredicate = nil
    PythonRunner.pendingSource = source
    PythonRunner.status = "starting"
    PythonRunner.startTimer = 0
    PythonRunner.wallTimer = 0

    if not spawnWorker() then return end
end

function PythonRunner.stop()
    if PythonRunner.status == "running" or PythonRunner.status == "starting" or PythonRunner.status == "error" then
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
    killWorker()
    PythonRunner.status = "won"
end

function PythonRunner.getStatus() return PythonRunner.status end
function PythonRunner.getError() return PythonRunner.errorMessage end
function PythonRunner.getErrorLine() return PythonRunner.errorLine end
function PythonRunner.getErrorKind() return PythonRunner.errorKind end
function PythonRunner.isRunning() return PythonRunner.status == "running" or PythonRunner.status == "starting" end
function PythonRunner.getRuntimeRoot() return getRuntimeRoot() end

function PythonRunner._executeApiCall(fn, args)
    local api = PythonRunner.api
    if not api then return nil, "API not initialized" end
    PythonRunner._waitPredicate = nil

    local ok, result = pcall(function()
        if fn == "move_to" then
            api.move_to(args[1]); return true
        elseif fn == "nearest_ore" then
            return tostring(api.nearest_ore())
        elseif fn == "mine" then
            api.mine(); return true
        elseif fn == "cargo" then
            return api.cargo()
        elseif fn == "capacity" then
            return api.capacity()
        elseif fn == "deposit" then
            api.deposit(); return true
        end
        error("Unknown API: " .. tostring(fn), 0)
    end)

    if not ok and result == PYTHON_WAIT then return nil, "pending" end
    if not ok then return nil, tostring(result) end
    return result, nil
end

local function finishPendingApiCall(callId, result, errMsg)
    local payload = errMsg and { error = errMsg, call_id = callId }
        or { result = result, call_id = callId }
    local ok, err = IPC.writeJson(ipcPath("api_response.json"), payload)
    if not ok then
        setInternalError("Could not write simulation response: " .. tostring(err), "IPCWriteError")
        killWorker()
        return false
    end
    PythonRunner.pendingApiCall = nil
    PythonRunner._waitPredicate = nil
    return true
end

local function updateStarting(dt)
    PythonRunner.startTimer = PythonRunner.startTimer + dt

    local workerErr = readFile(ipcPath("worker_error.txt"))
    if workerErr and workerErr ~= "" then
        setInternalError("Python worker failed to start.\n" .. workerErr, "WorkerStartError")
        killWorker()
        return
    end

    local pidContent = readFile(ipcPath("worker.pid"))
    if pidContent then
        PythonRunner.workerPid = tonumber(pidContent:match("(%d+)"))
        local source = PythonRunner.pendingSource or ""
        local ok, err = IPC.writeJson(ipcPath("command.json"), { fn = "run", args = { source } })
        if not ok then
            setInternalError("Could not send Python program to worker: " .. tostring(err), "IPCWriteError")
            killWorker()
            return
        end
        PythonRunner.pendingSource = nil
        PythonRunner.status = "running"
        PythonRunner.wallTimer = 0
        return
    end

    if PythonRunner.startTimer >= PythonRunner.START_TIMEOUT then
        setInternalError(
            "Python worker did not become ready within 5 seconds.\n\n" ..
            "Runtime root: " .. getRuntimeRoot() .. "\n" ..
            "Python: " .. tostring(PythonRunner.pythonExe),
            "WorkerStartTimeout"
        )
        killWorker()
    end
end

function PythonRunner.update(dt)
    if PythonRunner.status == "starting" then
        updateStarting(dt)
        return
    end
    if PythonRunner.status ~= "running" then return end

    PythonRunner.wallTimer = PythonRunner.wallTimer + dt
    if PythonRunner.wallTimer > PythonRunner.WALL_TIMEOUT then
        setInternalError("Your program took too long.\nIt may be stuck in a loop or waiting for the simulation.", "TimeoutError")
        killWorker()
        return
    end

    if PythonRunner.pendingApiCall then
        local pred = PythonRunner._waitPredicate
        if pred and pred() then
            local pending = PythonRunner.pendingApiCall
            if finishPendingApiCall(pending.call_id, pending.result or true, nil) then
                PythonRunner.wallTimer = 0
                if PythonRunner.world and PythonRunner.world.isWon() then PythonRunner:onWin() end
            end
        end
        return
    end

    local callPath = ipcPath("api_call.json")
    local callContent = readFile(callPath)
    if callContent and callContent ~= "" then
        local call = parseApiCall(callContent)
        if not call then
            setInternalError("Malformed API request from Python worker.", "IPCParseError")
            killWorker()
            return
        end
        removeFile(callPath)
        PythonRunner.wallTimer = 0

        local result, err = PythonRunner._executeApiCall(call.fn, call.args)
        if err == "pending" then
            PythonRunner.pendingApiCall = { call_id = call.call_id, result = true }
        elseif err then
            finishPendingApiCall(call.call_id, nil, err)
        else
            finishPendingApiCall(call.call_id, result, nil)
            if PythonRunner.world and PythonRunner.world.isWon() then PythonRunner:onWin() end
        end
        return
    end

    local responsePath = ipcPath("response.json")
    local responseContent = readFile(responsePath)
    if not responseContent or responseContent == "" then return end

    local response = parseWorkerResponse(responseContent)
    if not response then
        setInternalError("Malformed response from Python worker.", "IPCParseError")
        killWorker()
        return
    end
    removeFile(responsePath)

    if response.type == "error" then
        PythonRunner.status = "error"
        PythonRunner.errorKind = response.kind
        PythonRunner.errorLine = response.line
        local title, body, hint = mapError(response.kind, response.message)
        local msg = title .. "\n\n" .. body
        if hint ~= "" then msg = msg .. "\n\n" .. hint end
        if response.line then msg = msg .. "\n\nSee line " .. response.line .. " in your editor." end
        PythonRunner.errorMessage = msg
        killWorker()
    elseif response.type == "done" then
        PythonRunner.status = "idle"
        PythonRunner.wallTimer = 0
        if PythonRunner.world and PythonRunner.world.isWon() then PythonRunner:onWin() end
    else
        setInternalError("Unknown worker response: " .. tostring(response.type), "IPCProtocolError")
        killWorker()
    end
end

return PythonRunner
