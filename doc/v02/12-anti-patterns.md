# V0.2 — 12 Anti-Patterns & Handoff

## Hard bans (Issue #2)

| Ban | Why | Detection |
|-----|-----|-----------|
| Regex / string transpile Python→Lua | Fake Python | Code review, grep `gsub`, `translate` |
| RUN reads file player didn't see | Breaks trust | Trace RUN path |
| Blank editor + "figure it out" | Violates teaching | UX review |
| Full solution in starter.py | Skips learning | Read starter |
| RESET wipes code | Frustrating | QA G2 |
| Require pip/venv/system Python | Barrier | Clean VM test |
| Show Lua to player | Wrong language | UI audit |
| Level 2, enemies, shop | Scope creep | Feature audit |
| LLM/online tutor | Scope | Network audit |
| Pseudo-Python (`endif`, `repeat`) | Not transferable | Syntax check |

---

## Soft anti-patterns (avoid)

| Pattern | Better |
|---------|--------|
| Editor polish before P0 spike | Spike first |
| 7th API function without need | HUD + WIN event |
| Persist half-finished sim | Reset world on boot |
| Hint tier 4 shows full mission on step 1 | Step-scoped only |
| Stack trace in UI | Mapped beginner copy |
| `\t` tab characters | 4 spaces |
| Blocking LÖVE main thread on Python | IPC per frame |
| One giant `hints.lua` in code | `data/mission01/hints.json` |

---

## freebuff handoff checklist

Before starting:

- [ ] Read Issue #2 on GitHub
- [ ] Read `doc/v02/README.md` → `03-milestones.md`
- [ ] Run V0.1 (`run.bat`) — confirm baseline works
- [ ] Confirm Gate 1 assets/sim intact

Implementation order:

```text
P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7
```

After each milestone: commit + report per `03-milestones.md`.

---

## Prompt template for freebuff

```text
Implement CODE SWARM V0.2 (Issue #2).

Docs: doc/v02/README.md — follow milestones P0→P7 in order.

Hard rules:
- Real bundled Python (CPython). NO regex Python→Lua.
- Player only sees Python. RUN uses editor buffer only.
- Coach + Mission 01 + 4-tier hints + in-game API reference.
- Starter code must NOT contain full winning solution.
- RESET world only — never wipe editor code.
- No Level 2, enemies, multiple drones, shop.

Start with P0 spike: python worker + 6 API + blocking + STOP + anti-freeze.
Do not build pretty UI until P0 demo works.

When P7 done: follow [14-mission01-product-pass.md](./14-mission01-product-pass.md) Phase 10 — cold-start playtest + GREEN evidence.
```

---

## Common spike pitfalls

| Pitfall | Mitigation |
|---------|------------|
| `io.popen` buffering | Line-buffered mode, flush stdout in Python |
| Zombie python.exe on crash | Kill on love.quit |
| Path spaces (`code swam`) | Quote all paths in spawn cmd |
| LOVE working directory | Use love.filesystem.getSource() for paths |
| embeddable python no site | Edit `python311._pth` |
| JSON stdin deadlock | Separate threads in worker for read/write |

---

## Keeping V0.1 alive for dev

Optional env `CODESWARM_DEV=1`:

- Load `ui/hud.lua` + Lua runner
- Hidden from release build

Player build: **Python path only**.

---

## File ownership suggestion

| Area | Primary files |
|------|---------------|
| Runtime | `python/*`, `scripting/python_runner.lua` |
| Editor | `ui/editor.lua` |
| Coach | `coach/*`, `data/mission01/*` |
| Layout | `ui/hud_v02.lua`, `main.lua` |
| Sim | `game/*` — touch only if API needs |

---

## Questions escalated to maintainer

Escalate before implementing:

1. Adding 7th API function `deposited()`
2. Bundled python via LFS vs download script only
3. Persist Coach step vs reset each session
4. macOS support in V0.2 scope

Default decisions in docs unless maintainer overrides:

- No `deposited()` — use HUD
- Windows bundle required; fetch script for dev
- Optional progress JSON
- Windows only Gate 2

---

## Done means done

Issue #2 is **not** done when:

- Python works but no Coach
- Editor works but errors show raw traceback
- Mission completable only with pre-written starter loop
- Player must install Python manually

Issue #2 **is** done when Gate question = YES and A–H green.
