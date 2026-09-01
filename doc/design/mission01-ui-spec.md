# Mission 01 — UI Spec (from Figma)

> **Master plan:** [../v02/15-ui-figma-master-plan.md](../v02/15-ui-figma-master-plan.md)  
> **Status:** `DRAFT` — replace defaults below with Figma-locked values after Phase 0

LÖVE implementation reads this via `ui/layout_spec.lua` (Phase 2b).

---

## Reference resolution

Primary: **1280 × 720**  
Min: **1024 × 600**  
Fullscreen: scale proportionally

---

## Layout @ 1280×720 (default — update after Figma lock)

```text
top_bar:     y=0,   h=40
content:     y=40,  h=632
command_bar: y=672, h=48

left_col:    x=0,   w=744   (58%)
right_col:   x=744, w=536   (42%)

facility_feed:  x=8,  y=48,  w=728, h=348
terminal:       x=8,  y=404, w=728, h=268
briefing:       x=752, y=48,  w=520, h=240
alert_strip:    x=752, y=296, w=520, h=108
```

**Min facility height @ 1280:** 320px

---

## Color tokens

| Token | Hex | Use |
|-------|-----|-----|
| `bg_deck` | `#0C0E14` | Full screen |
| `bg_facility_feed` | `#12161F` | World viewport |
| `bg_briefing` | `#141820` | Coach |
| `bg_terminal` | `#0A0D12` | Editor area |
| `bg_terminal_header` | `#1A2030` | Terminal chrome |
| `border_panel` | `#2A3040` | Panel borders |
| `text_primary` | `#E8EAED` | Body |
| `text_muted` | `#8A9099` | Labels |
| `accent_cyan` | `#4FC3F7` | Titles, active |
| `accent_amber` | `#FFB74D` | Cargo, hints |
| `accent_green` | `#66BB6A` | Deposited, success |
| `accent_red` | `#EF5350` | Errors |
| `btn_execute` | `#1B5E20` | RUN |
| `btn_execute_glow` | `#4CAF50` | RUN running |
| `btn_abort` | `#B71C1C` | STOP |
| `btn_secondary` | `#37474F` | Secondary buttons |
| `line_current` | `#1E2838` | Editor current line |
| `line_error` | `#3D1515` | Editor error line |

---

## Typography

| Role | Size | Notes |
|------|------|-------|
| Game title | 16px bold | Top bar |
| Mission subtitle | 13px | Top bar |
| HUD counters | 14px bold | DEPOSITED, CARGO |
| Coach title | 15px bold | Briefing |
| Coach body | 13px | Briefing |
| Terminal code | 14px mono | Editor |
| Line numbers | 12px mono muted | Gutter |
| Buttons | 12px bold | Command bar |

---

## Command bar buttons (1280×720)

| ID | Label | x | w | h | y |
|----|-------|---|---|---|---|
| execute | EXECUTE (F5) | 16 | 140 | 36 | 680 |
| abort | ABORT (Esc) | 164 | 100 | 36 | 680 |
| reset | RESET FACILITY (F8) | 272 | 130 | 36 | 680 |
| new_code | NEW PROGRAM (F9) | 410 | 130 | 36 | 680 |
| api | API (F1) | 548 | 80 | 36 | 680 |

Status pill: right-aligned, x≈1100

---

## Terminal chrome

Header text: `PYTHON CONTROL // UNIT DRONE-01`  
Header height: 28px  
Gutter width (line numbers): 40px

---

## LÖVE module map

| Region | Module |
|--------|--------|
| Layout math | `ui/layout_spec.lua` |
| Top bar | `ui/hud_top_bar.lua` |
| Facility | `game/world_camera.lua` |
| Terminal | `ui/editor.lua` + `ui/terminal_chrome.lua` |
| Briefing | `ui/coach_panel.lua` |
| Alert | `ui/error_panel.lua` |
| Commands | `ui/command_bar.lua` |
| API | `ui/api_reference.lua` |
| Complete | `ui/mission_complete.lua` |
| Orchestrator | `ui/hud_v02.lua` |

---

## Figma compare checklist

| Frame | PNG | Game screenshot | Match? |
|-------|-----|-----------------|--------|
| S1 | `screens/s1-fresh-mission.png` | | ☐ |
| S2 | `screens/s2-editing.png` | | ☐ |
| S3 | `screens/s3-running.png` | | ☐ |
| S4 | `screens/s4-error.png` | | ☐ |
| S5 | `screens/s5-milestone.png` | | ☐ |
| S6 | `screens/s6-complete.png` | | ☐ |
| S7 | `screens/s7-api-help.png` | | ☐ |
