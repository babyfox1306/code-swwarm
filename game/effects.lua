local Effects = {
    particles = {},
    pulses = {},
}

function Effects.clear()
    Effects.particles = {}
    Effects.pulses = {}
end

-- Mining beam effect
function Effects.spawnMiningEffect(x, y)
    for i = 1, 6 do
        table.insert(Effects.particles, {
            x = x + math.random(-8, 8),
            y = y + math.random(-8, 8),
            vx = math.random(-20, 20),
            vy = math.random(-40, -10),
            life = 0.5 + math.random() * 0.5,
            maxLife = 1.0,
            color = { 0.3, 0.7, 1.0 },
            size = 2 + math.random() * 2,
        })
    end
    -- beam line
    table.insert(Effects.pulses, {
        type = "beam",
        x = x,
        y = y,
        timer = 0.4,
        maxTimer = 0.4,
    })
end

-- Deposit pulse effect
function Effects.spawnDepositEffect(x, y)
    table.insert(Effects.pulses, {
        type = "ring",
        x = x,
        y = y,
        timer = 0.5,
        maxTimer = 0.5,
        radius = 8,
        maxRadius = 40,
    })
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        table.insert(Effects.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * 30,
            vy = math.sin(angle) * 30,
            life = 0.4 + math.random() * 0.3,
            maxLife = 0.7,
            color = { 1.0, 0.85, 0.2 },
            size = 2 + math.random() * 2,
        })
    end
end

function Effects.update(dt)
    -- update particles
    for i = #Effects.particles, 1, -1 do
        local p = Effects.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Effects.particles, i)
        end
    end
    -- update pulses
    for i = #Effects.pulses, 1, -1 do
        local p = Effects.pulses[i]
        p.timer = p.timer - dt
        if p.timer <= 0 then
            table.remove(Effects.pulses, i)
        end
    end
end

function Effects.draw()
    -- draw pulses
    for _, p in ipairs(Effects.pulses) do
        local progress = 1 - (p.timer / p.maxTimer)
        if p.type == "beam" then
            love.graphics.setColor(0.3, 0.7, 1.0, 1 - progress)
            love.graphics.setLineWidth(2)
            love.graphics.line(p.x, p.y - 20, p.x, p.y - 40 - progress * 20)
            love.graphics.setLineWidth(1)
        elseif p.type == "ring" then
            local r = p.radius + (p.maxRadius - p.radius) * progress
            love.graphics.setColor(1.0, 0.85, 0.2, 1 - progress)
            love.graphics.circle("line", p.x, p.y, r)
        end
    end
    -- draw particles
    for _, p in ipairs(Effects.particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

return Effects
