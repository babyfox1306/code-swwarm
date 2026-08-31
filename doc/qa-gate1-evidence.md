# Gate 1 — Runtime QA Evidence

- **Tester:** freebuff (re-run C/C2/C3 after LuaJIT runner fix)
- **Date:** 2026-08-31
- **Commit:** `9eab18c` (pre-fix) → **re-test after anti-freeze patch** (`git rev-parse --short HEAD`)
- **LÖVE version:** 11.x (LuaJIT 2.1)
- **OS:** Windows

> **Gate status:** `YELLOW` — anti-freeze LuaJIT hardened in code; **C3 must pass on device** before GREEN.

---

## Results

| ID | Scenario | Pass? | Notes |
|----|----------|-------|-------|
| A | Happy path → WIN @ 20 | ✅ | ORE 20/20, WIN overlay, RESET OK (9eab18c) |
| B | `foo()` runtime error | ✅ | Error SFX once, HUD, STOP/RESET (9eab18c) |
| C | `while true do end` | ✅ | Budget error, no freeze (9eab18c) |
| C2 | `while true do cargo() end` | ✅ | Non-yield hot loop caught (9eab18c) |
| **C3** | **JIT loop `x = x + 1`** | ☐ | **Re-run required** — see below |
| D | `move_to("moon")` | ✅ | Controlled error (9eab18c) |
| E | RESET mid-action | ✅ | Clean state (9eab18c) |

### Scenario C3 — JIT-friendly loop (mandatory)

```lua
-- player/program.lua
local x = 0
while true do
    x = x + 1
end
```

**Expected after runner fix (`jit.off(fn, true)` + hook arm/disarm per resume):**

- Budget error within a few seconds
- Window responsive; STOP and RESET work
- No permanent hook left on VM while drone is moving/mining

| Step | Pass? | Notes |
|------|-------|-------|
| RUN C3 | ☐ | |
| Budget error shown | ☐ | |
| STOP works | ☐ | |
| RESET recovery | ☐ | |

---

## Anti-freeze — LuaJIT requirements (code review)

| Requirement | 9eab18c | After patch |
|-------------|---------|-------------|
| `jit.off(playerFn, true)` after compile | ❌ | ✅ `scripting/runner.lua` |
| Hook **not** left on during yield/simulation | ❌ set at coroutine start | ✅ arm only around `resume()` |
| Budget = 50k real instructions | ✅ | ✅ |
| C3 JIT loop tested on device | ❌ | ☐ pending |

**Why C3 matters:** LuaJIT does not invoke debug hooks from JIT-compiled tight loops unless JIT is disabled for that function. C/C2 alone do not prove safety.

---

## Presentation check

| Item | Pass? | Notes |
|------|-------|-------|
| Drone sprite | ✅ | Robot Lab, 4-frame |
| Floor tiles | ✅ | |
| Ore = radioactive barrel | ✅ | |
| Walls border | ✅ | |
| Mining / deposit VFX | ✅ | |
| HUD + SFX | ✅ | |
| Ambience | ✅ | Procedural — accepted V0.1 |
| MIT LICENSE | ✅ | `LICENSE` at repo root |

---

## Other blockers (9eab18c) — resolved

| Item | Status |
|------|--------|
| STOP from ERROR → stopped | ✅ |
| No double error SFX | ✅ |
| Runtime error SFX | ✅ |
| Budget 50k (not 50M) | ✅ |

---

## Final gate question

> Does this feel like a small actual game, or a technical test?

**Answer (9eab18c):** Small actual game — sprites, VFX, HUD, SFX, WIN flow.

**Anti-freeze:** Not signed off until **C3 passes** on LÖVE 11.x Windows.

---

## Sign-off

- [x] Scenarios A, B, D, E Pass (9eab18c)
- [x] C, C2 Pass (9eab18c) — not sufficient alone for LuaJIT sign-off
- [ ] **C3 Pass after runner patch**
- [x] `jit.off` + per-resume hook in runner
- [x] MIT LICENSE
- [ ] Commit SHA updated in this file after re-test
- [ ] Ready to close Issue #1
