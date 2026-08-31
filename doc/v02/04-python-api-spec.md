# V0.2 — 04 Python API Spec

> **Player contract:** Exactly **6 functions**. Names, arity, and blocking behavior are stable for Mission 01.

## Module

Player code implicitly has access to:

```python
from codeswarm import move_to, nearest_ore, mine, cargo, capacity, deposit
```

Or equivalent injection — player **never** writes `import os`, `open`, etc.

---

## `move_to(target)`

**Purpose:** Send drone to a location. **Blocks** until arrival or failure.

| Param | Type | Description |
|-------|------|-------------|
| `target` | `str` or position token | `"base"` or ore id from `nearest_ore()` |

**Returns:** `None`

**Example:**

```python
move_to(nearest_ore())
move_to("base")
```

**Errors (runtime, beginner messages in UI):**

| Condition | Coach message gist |
|-----------|-------------------|
| Unknown target | "That target doesn't exist. Try nearest_ore() or 'base'." |
| Blocked path | "Drone can't reach there yet." (V0.2: rare — keep simple) |

---

## `nearest_ore()`

**Purpose:** Find closest ore patch.

**Returns:** `str` — target id passable to `move_to`

**Example:**

```python
target = nearest_ore()
move_to(target)
```

**Note for docs:** Function call form required — not a bare name.

---

## `mine()`

**Purpose:** Mine ore at current location. **Blocks** until one mine action completes.

**Returns:** `None`

**Precondition:** Drone at ore tile.

**Errors:**

| Condition | Message gist |
|-----------|-------------|
| Not on ore | "Move to an ore patch first with move_to(nearest_ore())." |
| Cargo full | "Cargo is full. Go to base and deposit()." |

---

## `cargo()`

**Purpose:** Current ore count in drone.

**Returns:** `int` — 0 .. `capacity()`

**Example:**

```python
if cargo() >= capacity():
    move_to("base")
```

---

## `capacity()`

**Purpose:** Maximum ore drone can hold.

**Returns:** `int` — Mission 01: **5** (match V0.1 constants)

**Example:**

```python
while cargo() < 20:
    ...
```

---

## `deposit()`

**Purpose:** Deposit all cargo at base. **Blocks** until complete.

**Returns:** `None`

**Precondition:** Drone at base.

**Errors:**

| Condition | Message gist |
|-----------|-------------|
| Not at base | "Move to the base first: move_to('base')" |
| Empty cargo | "Nothing to deposit — mine some ore first." |

---

## Mission 01 win condition

```python
# Win triggers when total deposited >= 20 (tracked by world)
# Player typically uses:
while cargo() < 20:  # WRONG for win — teaches need to track total

# Correct pattern ( taught in later steps ):
while True:
    if cargo() >= capacity():
        move_to("base")
        deposit()
    else:
        move_to(nearest_ore())
        mine()
    # Win when world.deposited >= 20 — script stops via runner onWin
```

**Teaching note:** Coach step 6 explains deposited total vs `cargo()` — see Mission 01 doc.

World exposes `deposited` count to HUD; optional read-only `deposited()` API **only if** needed for loop clarity — **prefer** implicit WIN stop to avoid 7th function unless playtest demands it.

### Optional 7th function (discuss before adding)

```python
def deposited() -> int: ...
```

**Default V0.2:** NO — use HUD + WIN event. Add only if beginner loop impossible without it.

---

## Blocking guarantee

Every API call that triggers simulation:

1. Python worker emits `call`
2. Lua runs simulation until idle
3. Lua sends `resume`
4. Python continues

Player must **never** need `async`, `await`, or `time.sleep`.

---

## Forbidden in player sandbox

| Blocked | Reason |
|---------|--------|
| `import os, sys, subprocess` | Security |
| `open()`, file I/O | Not teaching goal |
| `while True` without budget | Anti-freeze handles |
| Network | Out of scope |

Worker bootstrap sets `__builtins__` allowlist.

---

## Python version

**Target:** CPython **3.11+** (bundled).

Syntax taught:

- `while` loops
- `if` / `else`
- Comparisons `>=`, `<`
- Function calls
- **Indentation** (4 spaces)
- Comments `#`

**Not taught Mission 01:** classes, def, list comprehensions, f-strings (optional in errors only).

---

## Mapping to Lua internal (`scripting/api.lua`)

| Python | Lua internal |
|--------|--------------|
| `move_to(t)` | `api.move_to(t)` |
| `nearest_ore()` | `api.nearest_ore()` |
| `mine()` | `api.mine()` |
| `cargo()` | `api.cargo()` |
| `capacity()` | `api.capacity()` |
| `deposit()` | `api.deposit()` |

Lua bridge returns JSON-serializable values only.

---

## In-game API reference content

Each entry in `data/api_reference.json`:

```json
{
  "name": "move_to",
  "signature": "move_to(target)",
  "summary": "Send your drone to a location and wait until it arrives.",
  "params": [{"name": "target", "desc": "Use nearest_ore() or 'base'"}],
  "example": "move_to(nearest_ore())",
  "related": ["nearest_ore"]
}
```

Panel renders from this file — keep in sync with `codeswarm.py` docstrings.
