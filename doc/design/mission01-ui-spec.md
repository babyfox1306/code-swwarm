# Mission 01 — UI Spec

> **STATUS: PROVISIONAL / NOT FIGMA-LOCKED**  
> The measurements below are scaffolding for a functional development build. They are **not** values copied from Figma Make.

Real UI implementation approval requires `mission01-figma-reference.md` to contain a real Figma Make link and exported S1–S7 frames.

## Reference resolutions

- Primary development viewport: **1280 × 720**
- Minimum supported development viewport: **1024 × 600**
- Fullscreen: responsive fit

## Current functional scaffold

These values describe the intended rough hierarchy only and may be replaced after the real design pass:

```text
top bar
┌───────────────────────────┬──────────────────┐
│                           │ mission / coach  │
│     FACILITY WORLD        │                  │
│                           ├──────────────────┤
├───────────────────────────┤ error / status   │
│     PYTHON TERMINAL       │                  │
│                           │                  │
└───────────────────────────┴──────────────────┘
command bar
```

Product hierarchy:

1. Facility/world is the primary game surface.
2. Python editor is an in-world control terminal.
3. Coach is short and contextual, not a documentation wall.
4. Error/status connects code to visible world behavior.
5. EXECUTE/RUN is the primary action.

## Current provisional tokens

These are implementation placeholders, not final design tokens.

| Token | Current value | Meaning |
|---|---|---|
| `bg_deck` | `#0C0E14` | screen background |
| `bg_facility_feed` | `#12161F` | world region |
| `bg_terminal` | `#0A0D12` | editor |
| `accent_cyan` | `#4FC3F7` | active systems |
| `accent_amber` | `#FFB74D` | warnings/hints |
| `accent_green` | `#66BB6A` | success |
| `accent_red` | `#EF5350` | errors |

## Required real-Figma measurements

After Figma Make is approved, replace this section with exact values for:

- top bar height
- command bar height
- world viewport x/y/w/h
- terminal x/y/w/h
- coach x/y/w/h
- error/status x/y/w/h
- panel gaps/padding
- typography scale
- button sizes/states
- responsive rules at 1024×600, 1280×720, 1920×1080

## Required frames

| Frame | Figma export | Game screenshot | Compared |
|---|---|---|---|
| S1 Fresh Mission | ☐ | ☐ | ☐ |
| S2 Editing | ☐ | ☐ | ☐ |
| S3 Running | ☐ | ☐ | ☐ |
| S4 Beginner error | ☐ | ☐ | ☐ |
| S5 Progress milestone | ☐ | ☐ | ☐ |
| S6 Mission complete | ☐ | ☐ | ☐ |
| S7 API / help | ☐ | ☐ | ☐ |

## Module mapping

| Region | Current module |
|---|---|
| World viewport | `game/world_camera.lua` |
| Editor | `ui/editor.lua` + `ui/editor_fixed.lua` |
| Coach | `ui/coach_panel.lua` + `ui/coach_panel_fixed.lua` |
| Errors | `ui/error_panel.lua` |
| HUD/layout | `ui/hud_v02.lua` |
| API overlay | `ui/api_reference.lua` |

## Lock rule

Do **not** change this file to `LOCKED` merely because an ASCII wireframe exists.

Lock only after:

1. real Figma Make reference exists;
2. S1–S7 exported;
3. values above copied from Figma;
4. game screenshots compared;
5. product owner approves in Issue #2.
