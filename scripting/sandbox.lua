local Sandbox = {}

function Sandbox.loadProgram(path)
    path = path or "player/program.lua"
    local info = love.filesystem.getInfo(path)
    if not info then
        return nil, "Program file not found: " .. path
    end
    local source = love.filesystem.read(path)
    return source, nil
end

function Sandbox.createEnv(api)
    return {
        move_to = api.move_to,
        nearest_ore = api.nearest_ore,
        mine = api.mine,
        cargo = api.cargo,
        capacity = api.capacity,
        deposit = api.deposit,
    }
end

function Sandbox.compile(source, env)
    local fn, err = load(source, "@player/program.lua", "t", env)
    if not fn then
        return nil, "Syntax error: " .. err
    end
    return fn, nil
end

return Sandbox
