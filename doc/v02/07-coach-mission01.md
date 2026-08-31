# V0.2 — 07 Coach & Mission 01

## Mission summary

| Field | Value |
|-------|-------|
| ID | `mission01` |
| Title | First Program |
| Goal | Deposit **20 ore** at base |
| Map | V0.1 single map |
| Drone | 1 |
| Capacity | 5 |

---

## Coach tone

- Second person: "Your drone…", "Try…"
- Short sentences
- One concept per step
- Celebrate small wins: "Nice! The drone moved."
- Never condescending; never jargon without gloss

**Glossary inline:** "loop = repeat code", "indent = spaces at line start"

---

## Step progression

| Step | ID | Objective | Coach intro (paraphrase) | Advance when |
|------|-----|-----------|--------------------------|--------------|
| 1 | `move` | Drone reaches ore | "Every program gives orders. First: send drone to ore." | `move_to` completed at ore |
| 2 | `mine` | Mine once | "At ore, call mine(). One line." | `cargo() >= 1` |
| 3 | `loop_intro` | Repeat mine | "One ore isn't enough. Use while to repeat." | Player runs loop that mines 2+ times OR cargo > 1 |
| 4 | `capacity` | Notice full cargo | "Drone holds 5. When full, cargo() >= capacity()." | `cargo() == capacity()` once |
| 5 | `base` | Go to base | "Full? Go to base with move_to('base')." | Drone at base while cargo > 0 |
| 6 | `deposit` | Deposit once | "At base, deposit() empties cargo." | `deposited >= 1` |
| 7 | `automate` | Loop until 20 | "Combine: mine until full, deposit, repeat until 20 ore total." | `deposited >= 20` WIN |

Steps are **soft-guided** — player can RUN anything; Coach nudges if off-track.

---

## Step 1 — Move

**Coach panel:**

```text
Step 1 of 7 — Move
Your drone waits for orders. Find the nearest ore and go there.

Try typing:
  move_to(nearest_ore())

Then press RUN (F5).
```

**Hints:** see hints.json `step_1` tier 1–4 in [08-errors-and-hints.md](./08-errors-and-hints.md)

---

## Step 2 — Mine

```text
Step 2 — Mine
Good! Now mine the ore you're standing on.

Add:
  mine()

Run again.
```

**Common mistake:** mine before move — Coach: "Move to ore first."

---

## Step 3 — Loop

```text
Step 3 — Repeat
You need more ore. In Python, while repeats code.

Example shape:
  while cargo() < 5:
      (indented lines)

Indent with 4 spaces after the colon.
```

**Teach:** `:` required, indent required. Link to error messages.

---

## Step 4 — Capacity

```text
Step 4 — Cargo limit
Your drone holds 5 ore. capacity() returns 5.
When cargo() >= capacity(), you can't mine more.
```

**Optional exercise:** mine until full in loop.

---

## Step 5 — Base

```text
Step 5 — Return to base
When cargo is full, go to the base (the green zone).

  move_to("base")
```

---

## Step 6 — Deposit

```text
Step 6 — Deposit
At the base, empty your cargo:

  deposit()

Watch the DEPOSITED counter go up!
```

**Common mistake:** deposit away from base — runtime error with fix.

---

## Step 7 — Automate

```text
Step 7 — Automate
Put it together: mine until full, go to base, deposit, repeat.
Goal: DEPOSITED reaches 20.

Use while True: or while deposited < 20 if you added deposited() — prefer HUD counter + WIN.
```

**Reference solution shape (Coach tier 4 only — not starter):**

```python
while True:
    if cargo() >= capacity():
        move_to("base")
        deposit()
    else:
        move_to(nearest_ore())
        mine()
```

WIN stops script when world deposited >= 20.

---

## Hint system — 4 tiers

| Tier | Button label | Content type |
|------|--------------|--------------|
| 1 | Hint: Idea | Conceptual nudge, no code |
| 2 | Hint: API | Which function(s), signature |
| 3 | Hint: Shape | Pseudocode / skeleton with `...` |
| 4 | Show step solution | Full lines for **current step only** |

### UX rules

- Tier starts at 1 each step OR persist max tier per step (design choice — **recommend reset per step**)
- Button: "Next Hint" cycles 1→2→3→4
- Tier 4 requires confirm: "Show solution for this step?" — avoid misclick
- **Never** show full mission solution in tier 1–3

### Example `data/mission01/hints.json`

```json
{
  "step_1": {
    "tier1": "Your drone needs a destination. The ore is somewhere on the map.",
    "tier2": "Use nearest_ore() to find ore, then move_to(...) to go there.",
    "tier3": "Two lines:\n  target = nearest_ore()\n  move_to(target)",
    "tier4": "move_to(nearest_ore())"
  },
  "step_2": {
    "tier1": "Mining happens at the ore tile, after you've arrived.",
    "tier2": "Call mine() with empty parentheses.",
    "tier3": "Add on a new line:\n  mine()",
    "tier4": "move_to(nearest_ore())\nmine()"
  }
}
```

(Continue for steps 3–7 in implementation.)

---

## Event hooks (`coach/mission01.lua`)

| Event | Source | Action |
|-------|--------|--------|
| `drone_arrived` | sim | Check step 1/5 |
| `mined` | sim | Advance step 2, 3 |
| `cargo_full` | sim | Advance step 4 |
| `deposited` | sim | Advance step 6, 7, WIN |
| `python_error` | runner | Show mapped message, don't advance |
| `run_started` | UI | Optional encouragement |

---

## API reference panel

Toggle key: **F1** or button "API"

Shows all 6 functions from `data/api_reference.json` — scrollable, plain language.

Example entry:

```text
move_to(target)
  Sends your drone somewhere and waits until it arrives.
  target: nearest_ore() or "base"
  Example: move_to(nearest_ore())
```

---

## Objective HUD

Always visible:

```text
MISSION: Deposit 20 ore
DEPOSITED: 12 / 20
CARGO: 3 / 5
STEP: 4 — Cargo limit
```

---

## What NOT to put in starter.py

```python
# FORBIDDEN in starter — full solution
while True:
    if cargo() >= capacity():
        move_to("base")
        deposit()
    else:
        move_to(nearest_ore())
        mine()
```

```python
# FORBIDDEN — too much hand-holding
move_to(nearest_ore())
mine()
move_to("base")
deposit()
```

Allowed: comments, empty lines, `# Your code below:`

---

## Beginner walkthrough success criteria

A tester with **zero** coding background, following only Coach + hints, reaches WIN in **< 45 minutes** without external browser.
