-- Run from repo root: lua qa/lua_ipc_e2e.lua <ipc-dir>
package.path = "./?.lua;./?/init.lua;" .. package.path

local IPC = require("scripting.ipc_protocol")
local dir = assert(arg[1], "ipc dir required")
local path = dir .. "/command.json"

local source = 'message = "CODE SWARM"\nvalue = 40 + 2\n'
local encoded = IPC.encode({ fn = "run", args = { source } })

assert(encoded:find('"args":%['), "args must be encoded as a JSON array")
assert(not encoded:find("table: 0x", 1, true), "Lua table address leaked into JSON")
assert(encoded:find('\\"CODE SWARM\\"'), "quotes inside player source must be escaped")
assert(encoded:find('\\n'), "newlines inside player source must be escaped")

local ok, err = IPC.atomicWrite(path, encoded)
assert(ok, err)
print("Lua IPC command published: " .. path)
