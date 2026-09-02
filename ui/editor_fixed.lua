-- CODE SWARM — editor geometry hotfix wrapper
-- Keeps the existing editor implementation but fixes click-to-caret mapping.

local Editor = require("ui.editor")

function Editor:handleClick(x, y)
    local numWidth = self.font:getWidth("00")
    local textX = self.x + self.padX + numWidth + 8
    local startY = self.y + self.padY + 20

    local visualRow = math.floor((y - startY) / self.lineHeight)
    local row = self.scrollRow + visualRow
    if row < 1 then row = 1 end
    if row > #self.lines then row = #self.lines end

    local line = self.lines[row] or ""
    local targetX = math.max(0, x - textX)

    -- Default font is proportional, so do not estimate columns with width("m").
    -- Pick the closest caret position by measuring actual rendered prefixes.
    local bestCol = 1
    local bestDist = math.huge
    for col = 1, #line + 1 do
        local prefix = Editor._sanitizeUtf8(line:sub(1, col - 1))
        local px = Editor._safeTextWidth(prefix)
        local dist = math.abs(px - targetX)
        if dist < bestDist then
            bestDist = dist
            bestCol = col
        end
        if px > targetX and dist > bestDist then break end
    end

    self.caretRow = row
    self.caretCol = bestCol
    self.focused = true
    self:_clampCaret()
    self:_updateScroll()
end

return Editor
