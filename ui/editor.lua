-- CODE SWARM — Python Editor (V0.2)
-- Multiline text buffer with caret, scroll, auto-indent, error highlight.

local Editor = {
    lines = { "" },
    caretRow = 1,
    caretCol = 1,   -- 1-based, cursor position (after char)
    scrollRow = 1,
    focused = true,
    errorLine = nil, -- highlighted on ERROR
    font = nil,
    fontHeight = 20,
    lineHeight = 24,
    padX = 8,
    padY = 8,
    saveTimer = 0,
    saveDebounce = 2,
    dirty = false,
    width = 400,
    height = 300,
    x = 0,
    y = 0,
}

function Editor.init(x, y, w, h)
    Editor.x = x
    Editor.y = y
    Editor.width = w
    Editor.height = h
    Editor.font = love.graphics.newFont(14)
    Editor.fontHeight = Editor.font:getHeight()
    Editor.lineHeight = Editor.fontHeight + 6
    Editor.focused = true
    Editor.errorLine = nil
end

function Editor:getText()
    return table.concat(self.lines, "\n")
end

function Editor:setText(s)
    if not s or s == "" then
        self.lines = { "" }
    else
        -- Normalize line endings
        s = s:gsub("\r\n", "\n"):gsub("\r", "\n")
        self.lines = {}
        for line in s:gmatch("([^\n]*)") do
            self.lines[#self.lines + 1] = line
        end
        if #self.lines == 0 then self.lines = { "" } end
    end
    self.caretRow = 1
    self.caretCol = 1
    self.scrollRow = 1
    self.errorLine = nil
end

function Editor:focus(f)
    self.focused = f
end

function Editor:highlightLine(n)
    self.errorLine = n
end

function Editor:clearHighlight()
    self.errorLine = nil
end

-- Clamp caret to valid position
function Editor:_clampCaret()
    if self.caretRow < 1 then self.caretRow = 1 end
    if self.caretRow > #self.lines then self.caretRow = #self.lines end
    local lineLen = #self.lines[self.caretRow]
    if self.caretCol < 1 then self.caretCol = 1 end
    if self.caretCol > lineLen + 1 then self.caretCol = lineLen + 1 end
end

-- Auto-indent: count leading spaces of current line + 4 if line ends with ':'
function Editor:_getAutoIndent()
    local line = self.lines[self.caretRow] or ""
    local indent = line:match("^(%s*)") or ""
    if line:match(":%s*$") then
        indent = indent .. "    "
    end
    return indent
end

-- Keyboard input
function Editor:handleKey(key)
    self.errorLine = nil  -- clear on any keypress
    self.dirty = true
    self.saveTimer = 0

    if key == "left" then
        self.caretCol = self.caretCol - 1
        if self.caretCol < 1 then
            self.caretRow = self.caretRow - 1
            if self.caretRow >= 1 then
                self.caretCol = #self.lines[self.caretRow] + 1
            else
                self.caretRow = 1
                self.caretCol = 1
            end
        end
    elseif key == "right" then
        local lineLen = #self.lines[self.caretRow]
        if self.caretCol <= lineLen then
            self.caretCol = self.caretCol + 1
        else
            self.caretRow = self.caretRow + 1
            if self.caretRow <= #self.lines then
                self.caretCol = 1
            else
                self.caretRow = #self.lines
                self.caretCol = #self.lines[self.caretRow] + 1
            end
        end
    elseif key == "up" then
        self.caretRow = self.caretRow - 1
        self:_clampCaret()
        local lineLen = #self.lines[self.caretRow]
        if self.caretCol > lineLen + 1 then self.caretCol = lineLen + 1 end
    elseif key == "down" then
        self.caretRow = self.caretRow + 1
        self:_clampCaret()
        local lineLen = #self.lines[self.caretRow]
        if self.caretCol > lineLen + 1 then self.caretCol = lineLen + 1 end
    elseif key == "home" then
        self.caretCol = 1
    elseif key == "end" then
        self.caretCol = #self.lines[self.caretRow] + 1
    elseif key == "return" then
        local line = self.lines[self.caretRow] or ""
        local before = line:sub(1, self.caretCol - 1)
        local after = line:sub(self.caretCol)
        self.lines[self.caretRow] = before
        local indent = self:_getAutoIndent()
        table.insert(self.lines, self.caretRow + 1, indent .. after)
        self.caretRow = self.caretRow + 1
        self.caretCol = #indent + 1
    elseif key == "backspace" then
        if self.caretCol > 1 then
            local line = self.lines[self.caretRow]
            self.lines[self.caretRow] = line:sub(1, self.caretCol - 2) .. line:sub(self.caretCol)
            self.caretCol = self.caretCol - 1
        elseif self.caretRow > 1 then
            local prevLen = #self.lines[self.caretRow - 1]
            self.lines[self.caretRow - 1] = self.lines[self.caretRow - 1] .. self.lines[self.caretRow]
            table.remove(self.lines, self.caretRow)
            self.caretRow = self.caretRow - 1
            self.caretCol = prevLen + 1
        end
    elseif key == "delete" then
        local line = self.lines[self.caretRow]
        if self.caretCol <= #line then
            self.lines[self.caretRow] = line:sub(1, self.caretCol - 1) .. line:sub(self.caretCol + 1)
        elseif self.caretRow < #self.lines then
            self.lines[self.caretRow] = line .. self.lines[self.caretRow + 1]
            table.remove(self.lines, self.caretRow + 1)
        end
    elseif key == "tab" then
        -- Insert 4 spaces
        local line = self.lines[self.caretRow]
        local spaces = "    "
        self.lines[self.caretRow] = line:sub(1, self.caretCol - 1) .. spaces .. line:sub(self.caretCol)
        self.caretCol = self.caretCol + 4
    else
        return false  -- not handled
    end

    self:_clampCaret()
    self:_updateScroll()
    return true
end

-- Text input (printable characters)
function Editor:handleTextInput(text)
    if not text or text == "" then return end
    -- Ignore control chars
    if text:byte(1) < 32 then return end

    self.errorLine = nil
    self.dirty = true
    self.saveTimer = 0

    local line = self.lines[self.caretRow]
    self.lines[self.caretRow] = line:sub(1, self.caretCol - 1) .. text .. line:sub(self.caretCol)
    self.caretCol = self.caretCol + #text
    self:_clampCaret()
    self:_updateScroll()
end

-- Mouse click: place caret
function Editor:handleClick(x, y)
    local relX = x - self.x - self.padX
    local relY = y - self.y - self.padY + self.scrollRow * self.lineHeight

    local row = math.floor(relY / self.lineHeight) + 1
    local col = math.floor(relX / (self.font:getWidth("m"))) + 1

    if row < 1 then row = 1 end
    if row > #self.lines then row = #self.lines end

    local lineLen = #self.lines[row]
    if col < 1 then col = 1 end
    if col > lineLen + 1 then col = lineLen + 1 end

    self.caretRow = row
    self.caretCol = col
    self.focused = true
    self:_updateScroll()
end

-- Mouse wheel scroll
function Editor:handleWheel(dx, dy)
    self.scrollRow = self.scrollRow - dy * 3
    local maxScroll = math.max(1, #self.lines - self:_visibleLines() + 1)
    if self.scrollRow < 1 then self.scrollRow = 1 end
    if self.scrollRow > maxScroll then self.scrollRow = maxScroll end
end

-- Calculate visible lines in panel
function Editor:_visibleLines()
    return math.floor((self.height - self.padY * 2) / self.lineHeight)
end

-- Ensure caret is visible
function Editor:_updateScroll()
    local vis = self:_visibleLines()
    if self.caretRow < self.scrollRow then
        self.scrollRow = self.caretRow
    elseif self.caretRow >= self.scrollRow + vis then
        self.scrollRow = self.caretRow - vis + 1
    end
end

-- Draw
function Editor:draw()
    -- Background panel
    love.graphics.setColor(0.08, 0.09, 0.12)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)

    -- Border
    if self.focused then
        love.graphics.setColor(0.3, 0.5, 0.8, 0.6)
    else
        love.graphics.setColor(0.2, 0.22, 0.25)
    end
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

    -- Clip
    love.graphics.setScissor(self.x + 1, self.y + 1, self.width - 2, self.height - 2)

    -- Label
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.5, 0.55, 0.6)
    love.graphics.print("Your Python program", self.x + self.padX, self.y + 4)

    local startY = self.y + self.padY + 20
    local vis = self:_visibleLines()

    for i = 1, vis do
        local lineIdx = self.scrollRow + i - 1
        if lineIdx > #self.lines then break end

        local y = startY + (i - 1) * self.lineHeight
        local line = self.lines[lineIdx]

        -- Error line highlight
        if self.errorLine and lineIdx == self.errorLine then
            love.graphics.setColor(0.4, 0.1, 0.1, 0.5)
            love.graphics.rectangle("fill", self.x, y - 2, self.width, self.lineHeight)
        end

        -- Line number
        love.graphics.setColor(0.3, 0.32, 0.35)
        local lineNum = tostring(lineIdx)
        local numWidth = self.font:getWidth("00")
        love.graphics.printf(lineNum, self.x + 2, y, numWidth, "right")

        -- Code text
        love.graphics.setColor(0.85, 0.88, 0.92)
        love.graphics.print(line, self.x + self.padX + numWidth + 8, y)

        -- Caret (blinking)
        if self.focused and lineIdx == self.caretRow then
            local t = love.timer.getTime()
            if math.floor(t * 2) % 2 == 0 then
                local charBefore = line:sub(1, self.caretCol - 1)
                local cx = self.x + self.padX + numWidth + 8 + self.font:getWidth(charBefore)
                love.graphics.setColor(0.9, 0.95, 1.0)
                love.graphics.rectangle("fill", cx, y, 2, self.fontHeight)
            end
        end
    end

    love.graphics.setScissor()
end

-- Update (for save debounce)
function Editor:update(dt)
    if self.dirty then
        self.saveTimer = self.saveTimer + dt
        if self.saveTimer >= self.saveDebounce then
            self.dirty = false
            self.saveTimer = 0
            -- Trigger save
            if Editor.onSave then
                Editor.onSave(self:getText())
            end
        end
    end
end

return Editor
