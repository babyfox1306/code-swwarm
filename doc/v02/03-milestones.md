# V0.2 — 03 Milestones (P0 → P7)

> **Rule:** Không nhảy milestone. P0 phải **demo được** trước khi làm editor đẹp.

---

## P0 — Python runtime spike (BLOCKER)

**Goal:** Prove real Python drives drone via 6 API — trước editor/in-game UX.

### Deliverables

| # | Item | Done when |
|---|------|-----------|
| P0.1 | `vendor/python/` or fetch script works on Windows | `python.exe -c "print(1)"` OK |
| P0.2 | `python/worker.py` + `codeswarm.py` | Subprocess starts |
| P0.3 | `scripting/python_runner.lua` IPC | JSON round-trip |
| P0.4 | All 6 API callable from Python | Drone moves, mines, deposits in test script |
| P0.5 | Blocking `move_to` / `mine` | Python waits until sim idle |
| P0.6 | Syntax error surfaces | `SyntaxError` with line → Lua receives |
| P0.7 | Runtime error surfaces | `NameError: minne` → Lua receives |
| P0.8 | STOP terminates | Worker dead, sim resets motion |
| P0.9 | Anti-freeze | `while True: pass` stops within timeout |

### Spike test script (hardcoded OK for P0)

`qa/spike_win.py`:

```python
while cargo() < 20:
    if cargo() >= capacity():
        move_to("base")
        deposit()
    else:
        move_to(nearest_ore())
        mine()
```

Run via dev key or temporary `main.lua` hook — **not** player UI yet.

### P0 exit criteria

- [ ] Spike script deposits 20 ore
- [ ] STOP works mid-run
- [ ] Infinite loop does not freeze LÖVE window
- [ ] **No regex Python→Lua anywhere in repo**

**Report:** commit + short note in PR/issue comment.

---

## P1 — Editor buffer → Python RUN

**Goal:** RUN executes string from in-memory buffer (minimal editor or textarea stub).

### Deliverables

| # | Item |
|---|------|
| P1.1 | `ui/editor.lua` minimal — multiline string buffer |
| P1.2 | RUN reads `editor:getText()` only |
| P1.3 | Hardcoded starter loaded into buffer on first run |
| P1.4 | Status: IDLE / RUNNING / ERROR / WIN (reuse V0.1 patterns) |
| P1.5 | F5 = RUN, Esc = STOP |

### P1 exit criteria

- [ ] Edit text in buffer → RUN → behavior changes
- [ ] No silent read from external file on RUN

---

## P2 — Minimum in-game editor UX

**Goal:** Usable editor for beginners — not polished IDE.

### Deliverables

| # | Item |
|---|------|
| P2.1 | Caret + arrow keys |
| P2.2 | Enter = newline |
| P2.3 | Backspace/Delete |
| P2.4 | Tab = 4 spaces (not `\t` char if possible) |
| P2.5 | Auto-indent +4 after line ending with `:` |
| P2.6 | Scroll when caret off-screen |
| P2.7 | Monospace font, readable size |
| P2.8 | Click to place caret (nice-to-have P2, required P3 if skipped) |

### P2 exit criteria

- [ ] User can write `while cargo() < 20:` + indented body without fighting editor
- [ ] 20+ line script scrollable

---

## P3 — Structured errors + line highlighting

**Goal:** Beginner understands **what** broke and **where**.

### Deliverables

| # | Item |
|---|------|
| P3.1 | `coach/errors.lua` maps error types |
| P3.2 | Error panel shows friendly title + fix hint |
| P3.3 | Editor highlights error line (red gutter or background) |
| P3.4 | Cases: SyntaxError, IndentationError, NameError, TypeError |
| P3.5 | Game logic errors: deposit empty, mine wrong target |
| P3.6 | Infinite loop message (not silent hang) |

Copy templates: [08-errors-and-hints.md](./08-errors-and-hints.md)

### P3 exit criteria

- [ ] Missing `:` → message mentions colon
- [ ] Bad indent → message mentions indentation
- [ ] `minne()` → suggests checking spelling / `mine`
- [ ] Wrong order mine/deposit → Coach explains

---

## P4 — Coach + progressive hints

**Goal:** Player never stuck at blank screen.

### Deliverables

| # | Item |
|---|------|
| P4.1 | `coach/mission01.lua` step machine |
| P4.2 | `ui/coach_panel.lua` always visible |
| P4.3 | `data/mission01/hints.json` 4 tiers |
| P4.4 | Hint button cycles tier (or separate Hint 1/2/3/Solution) |
| P4.5 | `ui/api_reference.lua` toggle panel |
| P4.6 | `data/api_reference.json` from API spec |
| P4.7 | Starter from `data/mission01/starter.py` — no full answer |

### P4 exit criteria

- [ ] Fresh boot: Coach says what to do **before** user types
- [ ] Hint tier 1 never shows full code; tier 4 shows step solution only
- [ ] API reference lists all 6 functions with examples

---

## P5 — Mission 01 progression

**Goal:** Guided path move → … → automate → WIN 20.

Steps: [07-coach-mission01.md](./07-coach-mission01.md)

### Deliverables

| # | Item |
|---|------|
| P5.1 | 7+ coach steps with detection hooks |
| P5.2 | Step transitions on success events |
| P5.3 | WIN at 20 deposited ore stops script |
| P5.4 | Objective HUD shows ore deposited / 20 |
| P5.5 | Celebration / WIN state (reuse V0.1) |

### P5 exit criteria

- [ ] Beginner following Coach only can reach WIN without external docs
- [ ] Starter code alone does **not** WIN

---

## P6 — Save / persistence + polish

**Goal:** Code survives sessions; RESET is safe.

### Deliverables

| # | Item |
|---|------|
| P6.1 | Autosave `mission01_code.py` to save directory |
| P6.2 | Load save on boot (fallback starter) |
| P6.3 | RESET world: ore/drone positions — **not** editor |
| P6.4 | `run.bat` documents bundled python |
| P6.5 | No regression V0.1 sim (walls, sprites, audio) |

### P6 exit criteria

- [ ] Close game, reopen — code still there
- [ ] RESET mid-edit — code unchanged

---

## P7 — Full beginner QA (Gate 2)

**Goal:** Scenario A–H pass. Gate question = YES.

Checklist: [11-testing.md](./11-testing.md)

### P7 exit criteria

- [ ] All scenarios A–H documented with evidence
- [ ] `doc/v02/qa-gate2-evidence.md` created (freebuff)
- [ ] Issue #2 ready to close

---

## Milestone dependency graph

```text
P0 ──→ P1 ──→ P2
              ↓
         P3 ←──┘
              ↓
         P4 ──→ P5 ──→ P6 ──→ P7
```

P3 and P2 can overlap slightly **only after** P1 done; P4 requires P3 error copy minimally.

---

## Reporting format (freebuff)

After each Pn:

```markdown
## Pn complete
- Commit: `<hash>`
- Demo: <what you ran>
- Exit criteria: <checklist>
- Known gaps: <if any>
- Next: Pn+1
```
