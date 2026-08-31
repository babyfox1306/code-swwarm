# V0.2 — 11 Testing & Definition of Done

## Gate 2 question

> Could a person who has never written code open CODE SWARM, understand what to do, write their first Python inside the game, see the drone react, understand a mistake, fix it, and make visible progress **without leaving the game**?

**All scenarios A–H must pass.**

---

## Scenario A — Fresh start

| Step | Action | Pass |
|------|--------|------|
| A1 | Launch game, no prior save | Coach visible, starter not empty solution |
| A2 | Read Coach without external docs | Knows to type move command |
| A3 | Press RUN with starter only | No crash; Coach nudges |

---

## Scenario B — First success

| Step | Action | Pass |
|------|--------|------|
| B1 | Type `move_to(nearest_ore())`, RUN | Drone moves to ore |
| B2 | Add `mine()`, RUN | Cargo increases |
| B3 | Visual feedback | Effects/audio OK |

---

## Scenario C — Syntax errors

| Step | Action | Pass |
|------|--------|------|
| C1 | `while cargo() < 20` (no colon) | Friendly error, line hint |
| C2 | Missing indent under while | Indentation message |
| C3 | `minne()` | Suggests mine |

---

## Scenario D — Logic errors

| Step | Action | Pass |
|------|--------|------|
| D1 | `mine()` before move | Coach/runtime explains order |
| D2 | `deposit()` away from base | Not at base message |
| D3 | Fix and RUN | Progress continues |

---

## Scenario E — Infinite loop

| Step | Action | Pass |
|------|--------|------|
| E1 | `while True: pass` or equiv, RUN | Stops with message, window responsive |
| E2 | STOP (Esc) | Worker stops mid-run |

---

## Scenario F — Full mission

| Step | Action | Pass |
|------|--------|------|
| F1 | Complete automation to 20 deposited | WIN state |
| F2 | Script stops on WIN | No runaway |
| F3 | Following Coach+hints only | Achievable without Google |

---

## Scenario G — Persistence

| Step | Action | Pass |
|------|--------|------|
| G1 | Write multi-line script, quit, reopen | Code intact |
| G2 | F8 RESET WORLD | Code intact, world reset |

---

## Scenario H — Buffer truth

| Step | Action | Pass |
|------|--------|------|
| H1 | Edit buffer, RUN | Behavior matches **new** code |
| H2 | No edit after load | RUN matches visible buffer |
| H3 | grep/manual audit | RUN path uses `editor:getText()` only |

---

## Definition of Done checklist

Copy to PR / `doc/v02/qa-gate2-evidence.md`:

### Python runtime

- [ ] Bundled python — no manual install on clean Windows VM
- [ ] 6 API work from Python
- [ ] Blocking semantics correct
- [ ] Real Python exec — no regex transpile
- [ ] STOP + anti-freeze

### Editor

- [ ] Multiline, indent, scroll
- [ ] RUN = buffer
- [ ] Autosave + reload

### Teaching

- [ ] Coach Mission 01 all steps
- [ ] Hints 4 tiers
- [ ] API reference in game
- [ ] Starter ≠ full solution
- [ ] Beginner error copy for C1–C3, D1–D2, E1

### Simulation

- [ ] No V0.1 visual regression
- [ ] WIN @ 20 deposited

### Scenarios

- [ ] A through H pass with notes/screenshots

---

## Evidence template

```markdown
# Gate 2 QA Evidence — V0.2

Date:
Tester:
Build: commit `<hash>`
Platform: Windows 10/11

## Scenario A
- Result: PASS/FAIL
- Notes:

## Scenario B
...

## Gate question
Answer: YES/NO
Reason:
```

---

## Clean machine test (required P7)

Machine **without** Python on PATH:

1. Clone repo or extract release zip
2. Run `run.bat` (includes bundled python)
3. Complete Scenario B minimum

If fails → P0 not done.

---

## Performance smoke

| Metric | Target |
|--------|--------|
| RUN startup | < 2s after first worker spawn |
| Editor typing | No lag > 50ms |
| STOP response | < 500ms |

---

## Out of scope tests

Do not block V0.2 on:

- macOS/Linux bundled python
- Accessibility screen readers
- Localization

---

## Sign-off

Issue #2 closes when:

1. DoD checklist complete
2. Gate question YES with evidence
3. No P0–P6 exit criteria open
