# 07 — UI & HUD

## Window layout (960 × 540)

```text
┌──────────────────────────────────────────────────────────────┐
│ TOP BAR (h=56)                                               │
│  CODE SWARM          ORE: 12/20    CARGO: 3/5    ● RUNNING   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│                    WORLD VIEW (800×400)                      │
│                  offset (80, 80) from top-left               │
│                                                              │
│   [BASE]                              [ORE]                  │
│                                                              │
│                      (drone)              [ORE]              │
│                                                              │
│                                        [ORE]                 │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│ BOTTOM BAR (h=64)                                            │
│  [ RUN ]    [ STOP ]    [ RESET ]          F5 / Esc / F8     │
│                                                              │
│  ERROR PANEL (if any, above bottom bar or in top bar)        │
└──────────────────────────────────────────────────────────────┘
```

---

## Color palette (dark sci-fi)

| Token | Hex | Usage |
|-------|-----|-------|
| `bg_dark` | `#0d1117` | Window background |
| `panel` | `#161b22` | HUD panels |
| `panel_border` | `#30363d` | Panel stroke |
| `text_primary` | `#e6edf3` | Labels |
| `text_muted` | `#8b949e` | Hints |
| `accent_cyan` | `#58a6ff` | Header accent |
| `status_run` | `#3fb950` | RUNNING |
| `status_stop` | `#8b949e` | STOPPED / IDLE |
| `status_error` | `#f85149` | ERROR |
| `status_won` | `#d29922` | WON |
| `button_run` | `#238636` | RUN button |
| `button_stop` | `#da3633` | STOP button |
| `button_reset` | `#6e7681` | RESET button |

---

## Typography

```lua
-- love.load
fonts = {
    title = love.graphics.newFont(20),
    body  = love.graphics.newFont(14),
    small = love.graphics.newFont(12),
    mono  = love.graphics.newFont("assets/fonts/optional-mono.ttf", 12), -- fallback default
}
```

Nearest filter on fonts optional — pixel font nếu có.

---

## HUD elements

### Header

- Title: **CODE SWARM** (left)
- Subtitle optional: `V0.1` muted

### Stats (right side top bar)

```text
ORE: {deposited} / {WIN_ORE_TARGET}
CARGO: {cargo} / {capacity}
```

### Status indicator

```text
● IDLE | ● RUNNING | ● STOPPED | ● ERROR | ★ MISSION COMPLETE
```

Color dot matches status. Pulse animation khi RUNNING.

### Error panel

Visible when `runner.status == "error"`:

```text
┌─ ERROR ─────────────────────────────────────┐
│ Runtime error: attempt to call nil 'foo'    │
└─────────────────────────────────────────────┘
```

Max 2 lines, truncate with `...`

### Win overlay

Semi-transparent full-world overlay:

```text
        ╔═══════════════════════╗
        ║   MISSION COMPLETE    ║
        ║   20 / 20 ORE         ║
        ║   Press RESET         ║
        ╚═══════════════════════╝
```

Block không cần block input — nhưng script đã stop.

---

## Buttons

| Button | Rect (bottom bar) | Action |
|--------|-------------------|--------|
| RUN | x=80, w=120, h=40 | `runner.run()` — disabled if won until RESET |
| STOP | x=220, w=120, h=40 | `runner.stop()` |
| RESET | x=360, w=120, h=40 | `runner.reset()` |

### Button states

- **hover:** lighten 10%
- **pressed:** darken 10%
- **disabled:** greyed (RUN when won)

### Hit test

```lua
function Hud:hitTest(x, y)
    for _, btn in ipairs(self.buttons) do
        if pointInRect(x, y, btn.rect) and btn.enabled then
            return btn.id
        end
    end
end
```

---

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `F5` | RUN |
| `Escape` | STOP |
| `F8` | RESET |

Implement in `hud.keypressed` → delegate runner.

---

## Draw order

```lua
function Hud:draw()
    self:drawTopBar()
    self:drawErrorPanel()
    self:drawBottomBar()
    if world.isWon() then
        self:drawWinOverlay()
    end
end
```

World draws **before** HUD in `main.lua`, nhưng win overlay có thể che world — OK.

---

## World viewport

Center playable area trong window:

```lua
local WORLD_X = 80
local WORLD_Y = 80
local WORLD_W = 800
local WORLD_H = 400

love.graphics.setScissor(WORLD_X, WORLD_Y, WORLD_W, WORLD_H)
-- draw world translated
love.graphics.setScissor()
```

Optional dark border around play area.

---

## HUD module structure

```lua
local Hud = {}

function Hud:init(runner, world)
    self.runner = runner
    self.world = world
    self.buttons = { ... }
    self.mouseOver = nil
end

function Hud:update(dt)
    -- hover state, status pulse
end

function Hud:draw()
    -- ...
end

function Hud:mousepressed(x, y, button)
    local id = self:hitTest(x, y)
    if id == "run" then self.runner.run() end
    -- ...
end

function Hud:keypressed(key) ... end

return Hud
```

---

## Không làm

- Scrollable code editor phức tạp
- Drag-drop UI
- Settings menu
- Localization

---

## Accessibility minimum

- Text contrast đủ trên nền tối
- Buttons đủ lớn (min 120×40)
- Status không chỉ dựa màu — có text label
