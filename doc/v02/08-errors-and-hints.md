# V0.2 — 08 Errors & Hints

## Philosophy

Errors are **teaching moments**. Every message answers:

1. What happened? (plain language)
2. Where? (line number + highlight)
3. What to try? (one concrete fix)

Avoid: stack traces, "Traceback", jargon without explanation.

---

## Display format

```text
⚠ Syntax Error (line 4)

Python expected a colon at the end of your while line.

Fix: Add : at the end
  while cargo() < 20:
      ...

[Editor line 4 highlighted]
```

---

## Syntax & Python errors

### Missing colon (`SyntaxError`)

**Trigger:** `while cargo() < 20` without `:`

**Title:** Missing colon

**Body:**

```text
A while line in Python must end with a colon (:).
The colon tells Python "the repeated code comes next."
```

**Fix hint:**

```text
Change:
  while cargo() < 20
To:
  while cargo() < 20:
```

---

### Bad indentation (`IndentationError`)

**Trigger:** body not indented after `:`

**Title:** Indentation problem

**Body:**

```text
Lines inside a while block must be indented (moved right).
Use 4 spaces at the start of each line inside the loop.
```

**Fix hint:**

```text
Press Tab at the start of the line after while ...:
```

---

### Unexpected indent

**Title:** Extra indentation

**Body:** `This line is indented but Python doesn't expect it here. Check lines above for a missing colon.`

---

### NameError — typo `minne`

**Trigger:** `minne()`

**Title:** Unknown name: minne

**Body:**

```text
Python doesn't recognize minne. Did you mean mine?
Spelling matters — computer words must match exactly.
```

**Fix:** `mine()`

---

### NameError — undefined variable

**Trigger:** `move_to(ore)` without defining `ore`

**Body:** `The name "ore" isn't defined. Use nearest_ore() to get a target.`

---

### Missing parentheses

**Trigger:** `move_to nearest_ore` or `mine`

**Body:** `Functions need parentheses (): move_to(nearest_ore())`

---

## Game logic errors (runtime)

### Mine not on ore

**Title:** Can't mine here

**Body:**

```text
mine() only works when your drone is on an ore patch.
First: move_to(nearest_ore())
```

---

### Deposit not at base

**Title:** Not at base

**Body:**

```text
deposit() only works at the base (green area).
Use move_to("base") first.
```

---

### Deposit empty cargo

**Title:** Nothing to deposit

**Body:** `Your cargo is empty. Mine some ore before depositing.`

---

### Cargo full, keep mining

**Title:** Cargo full

**Body:**

```text
Your drone can't hold more ore (capacity is 5).
Go to base and deposit().
```

---

## Infinite loop / budget

**Trigger:** budget exceeded or wall timeout

**Title:** Loop ran too long

**Body:**

```text
Your program may be stuck in an infinite loop.
Check: does your while condition ever become false?
For Mission 1, try if cargo() >= capacity(): to visit base.
```

**Dev test script:** `while True: x = 1` must hit this, not freeze.

---

## Coach nudges (not errors)

| Situation | Nudge |
|-----------|-------|
| Empty editor RUN | "Start with move_to(nearest_ore()) — see Coach panel." |
| Step 1 but only `mine()` | "Move to ore before mining." |
| Step 6 but no `deposit` yet | "You're at base! Try deposit()." |
| WIN | "You deposited 20 ore! Mission complete." |

---

## Hint tier content guidelines

| Tier | DO | DON'T |
|------|-----|-------|
| 1 | Metaphor, goal | Code |
| 2 | Function names, params | Full lines |
| 3 | Skeleton with `...` | Runnable full loop |
| 4 | Step-complete snippet | Entire mission automation unless step 7 |

---

## `coach/errors.lua` mapping table

```lua
-- Pseudocode structure
local messages = {
  SyntaxError = {
    missing_colon = { title = "...", body = "...", fix = "..." },
    default = { ... },
  },
  IndentationError = { default = { ... } },
  NameError = {
    pattern_minne = { match = "minne", ... },
    default = { ... },
  },
  RuntimeError = {
    not_at_base = { ... },
    not_on_ore = { ... },
    budget = { ... },
  },
}
```

Pattern match on `message` string from Python when `kind` alone insufficient.

---

## Line number rules

- 1-based line numbers match editor display
- If Python reports `line = nil`, show message without highlight
- Multi-line statements: highlight **start line**

---

## Audio / visual

Reuse V0.1 error SFX on ERROR.

Status bar: red ERROR, yellow RUNNING, green WIN.

---

## QA scripts for errors

Create `qa/error_samples/` (dev only, not player):

| File | Expected error |
|------|----------------|
| `bad_colon.py` | Missing colon |
| `bad_indent.py` | IndentationError |
| `typo_minne.py` | NameError minne |
| `infinite.py` | Budget/timeout |
| `deposit_nowhere.py` | Not at base |

Run via dev menu or automated harness post-P7.
