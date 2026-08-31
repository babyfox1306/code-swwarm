# V0.2 — 06 In-Game Editor Spec

## Purpose

Multiline Python workspace **inside** the game. RUN always uses **visible buffer**.

---

## Visual requirements

| Element | Spec |
|---------|------|
| Font | Monospace, ≥14px effective |
| Background | Dark panel, distinct from world |
| Line numbers | Optional P2, recommended P3 |
| Caret | Visible blink |
| Selection | Nice-to-have; not blocker |
| Scrollbar | When lines exceed panel height |

---

## Buffer model

```lua
Editor = {
  lines = { "# starter" },
  caretRow = 1,
  caretCol = 1,  -- 1-based, after char
  scrollRow = 1,
  focused = true,
  errorLine = nil,  -- highlight on ERROR
}
```

### `getText()`

```lua
function Editor:getText()
  return table.concat(self.lines, "\n")
end
```

### `setText(s)`

Split on `\n`, normalize `\r\n`, reset caret to end or line 1.

---

## Keyboard (when focused)

| Key | Action |
|-----|--------|
| Arrow keys | Move caret |
| Home / End | Line start/end |
| Enter | Newline + auto-indent |
| Backspace | Merge lines if at col 1 |
| Delete | Delete char forward |
| Tab | Insert 4 spaces |
| Shift+Tab | Remove up to 4 spaces indent (P3+) |
| Ctrl+A | Select all (optional) |

### Auto-indent rule

On Enter after line matching `%s:%s*$`:

```python
while cargo() < 20:█
```

New line starts with **parent indent + 4 spaces**.

---

## Mouse

| Action | Behavior |
|--------|----------|
| Click panel | Focus editor, place caret at nearest char |
| Wheel | Scroll when focused |

---

## Interaction with game keys

| Key | Editor focused | Editor not focused |
|-----|----------------|------------------|
| F5 RUN | Still RUN (global) | RUN |
| Esc STOP | STOP | STOP |
| F8 RESET world | RESET world | RESET world |

Typing goes to editor when focused. Click Coach panel → unfocus editor (optional).

---

## RUN contract

```lua
function doRun()
  local source = editor:getText()
  if source == "" then
    coach.say("Your editor is empty. Start with move_to(nearest_ore())")
    return
  end
  python_runner.run(source)
end
```

**Forbidden:**

- RUN reads `player/program.lua`
- RUN reads file from disk without showing in editor
- RUN uses cached source != buffer after edit

---

## Starter content rules

Load order on boot:

1. Save file `mission01_code.py` if exists
2. Else `data/mission01/starter.py`

Starter must:

- Explain Mission in comments
- Point to Coach panel
- **Not** contain winning automation

Example:

```python
# Welcome to CODE SWARM!
# Read the Coach panel on the right →
# Step 1: Make the drone move to the nearest ore.

```

---

## Error highlight

On ERROR with line N:

- `editor.errorLine = N`
- Draw red tint on line N
- Clear on next keypress or RUN

---

## Persistence hooks

| Event | Action |
|-------|--------|
| Text change | Debounce 2s → save |
| RUN pressed | Save immediately |
| Boot | Load save → `setText` |

See [10-save-persistence.md](./10-save-persistence.md)

---

## Minimum size

Editor panel ≥ **40% screen width**, ≥ **50% height** on 1280×720.

---

## Out of scope V0.2

- Syntax highlighting (colors for keywords)
- Autocomplete
- Multiple files/tabs
- Vim bindings
- Undo/redo stack (nice-to-have; single-level undo optional)

---

## Acceptance tests

| Test | Expected |
|------|----------|
| Type `move_to(nearest_ore())`, RUN | Drone moves |
| Add line, don't RUN | Old behavior if RUN again uses new text |
| 30 lines | Scroll works, caret visible |
| Tab | Spaces not `\t` |
| After ERROR line 3 | Line 3 highlighted |
