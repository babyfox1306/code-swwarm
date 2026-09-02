-- CODE SWARM — editor geometry/error-navigation hotfix wrapper
-- Keeps the existing editor implementation while fixing click mapping and
-- ensuring Python errors are actually brought into view.

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

-- ErrorPanel may say "line 83" while the editor is still showing line 1.
-- That is useless for a beginner. Highlighting an error now reveals that line
-- and places the caret there so the next keystroke fixes the actual location.
function Editor:highlightLine(n)
    n = tonumber(n)
    if not n then
        self.errorLine = nil
        return
    end

    n = math.floor(n)
    if n < 1 or n > #self.lines then
        self.errorLine = nil
        return
    end

    self.errorLine = n
    self.caretRow = n
    self.caretCol = math.min(self.caretCol or 1, #(self.lines[n] or "") + 1)
    if self.caretCol < 1 then self.caretCol = 1 end

    local vis = math.max(1, self:_visibleLines())
    local desired = n - math.floor(vis / 2)
    local maxScroll = math.max(1, #self.lines - vis + 1)
    if desired < 1 then desired = 1 end
    if desired > maxScroll then desired = maxScroll end
    self.scrollRow = desired
    self.focused = true
end

return Editor
