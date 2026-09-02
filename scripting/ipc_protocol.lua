-- CODE SWARM — IPC protocol helpers
-- Pure Lua: no LÖVE dependency. Used by the Python runner and QA contract tests.

local M = {}

local function escapeString(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
         :gsub('"', '\\"')
         :gsub("\b", "\\b")
         :gsub("\f", "\\f")
         :gsub("\n", "\\n")
         :gsub("\r", "\\r")
         :gsub("\t", "\\t")
    return '"' .. s .. '"'
end

local function isArray(t)
    if next(t) == nil then return true end
    local max, count = 0, 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false end
        if k > max then max = k end
        count = count + 1
    end
    return max == count
end

local function encodeValue(v, stack)
    local tv = type(v)
    if tv == "nil" then return "null" end
    if tv == "boolean" then return v and "true" or "false" end
    if tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then
            error("Cannot encode non-finite number as JSON")
        end
        return tostring(v)
    end
    if tv == "string" then return escapeString(v) end
    if tv ~= "table" then error("Unsupported JSON type: " .. tv) end

    stack = stack or {}
    if stack[v] then error("Cannot encode cyclic table as JSON") end
    stack[v] = true

    local out = {}
    if isArray(v) then
        for i = 1, #v do out[#out + 1] = encodeValue(v[i], stack) end
        stack[v] = nil
        return "[" .. table.concat(out, ",") .. "]"
    end

    local keys = {}
    for k in pairs(v) do
        if type(k) ~= "string" then error("JSON object keys must be strings") end
        keys[#keys + 1] = k
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
        out[#out + 1] = escapeString(k) .. ":" .. encodeValue(v[k], stack)
    end
    stack[v] = nil
    return "{" .. table.concat(out, ",") .. "}"
end

function M.encode(value)
    return encodeValue(value, {})
end

function M.atomicWrite(path, content)
    local tmp = path .. ".tmp"
    local f, err = io.open(tmp, "wb")
    if not f then return false, err end
    local ok, writeErr = f:write(content)
    f:close()
    if not ok then
        os.remove(tmp)
        return false, writeErr
    end

    -- Windows rename cannot replace an existing file reliably.
    os.remove(path)
    local renamed, renameErr = os.rename(tmp, path)
    if not renamed then
        os.remove(tmp)
        return false, renameErr
    end
    return true
end

function M.writeJson(path, value)
    return M.atomicWrite(path, M.encode(value))
end

return M
