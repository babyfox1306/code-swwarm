-- Regression: `love .` must resolve runtime files from getSource(), not parent dir.
package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    filesystem = {
        isFused = function() return false end,
        getSource = function() return "D:/duan/code-swwarm" end,
        getSourceBaseDirectory = function() return "D:/duan" end,
        getWorkingDirectory = function() return "D:/duan/code-swwarm" end,
    },
}

local runner = require("scripting.python_runner_v04")
local root = runner.getRuntimeRoot()
assert(root == "D:/duan/code-swwarm", "wrong runtime root: " .. tostring(root))
print("runtime root PASS: " .. root)
