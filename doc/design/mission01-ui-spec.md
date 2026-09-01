# Mission 01 — UI Spec (from Figma)

> Copy values from Figma Make after Phase 0 lock.  
> LÖVE implementation (`ui/hud_v02.lua`, etc.) must match this doc.

**Status:** `DRAFT` — fill during Phase 0

---

## Layout grid @ 1280×720

```text
_(paste annotated frame or ASCII from Figma)_
```

---

## Panel hierarchy (z-order)

1. World (background gameplay)
2. Facility overlays / VFX
3. Editor chrome + buffer
4. Coach panel
5. Error strip
6. Top bar + control bar
7. API overlay (modal)
8. Mission complete (modal)

---

## Spacing tokens (px)

| Token | Value |
|-------|-------|
| `margin_screen` | |
| `gap_panel` | |
| `pad_coach` | |
| `pad_editor` | |
| `btn_height` | |
| `btn_min_width` | |

---

## RUN button treatment

| Property | Value |
|----------|-------|
| Label | RUN (F5) |
| Primary color | |
| Running state | |
| Disabled state | |

---

## Responsive breakpoints

| Resolution | World H % | Editor min lines |
|------------|-----------|------------------|
| 1280×720 | | 12 |
| 1024×600 | | 8 |
| 1920×1080 | scale | |

---

## LÖVE mapping

| Figma layer | Lua module |
|-------------|------------|
| World viewport | `game/world_camera.lua` + `HudV02.world*` |
| Editor | `ui/editor.lua` |
| Coach | `ui/coach_panel.lua` |
| Errors | `ui/error_panel.lua` |
| Complete | `ui/mission_complete.lua` |
