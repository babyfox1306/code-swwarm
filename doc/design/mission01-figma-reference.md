# Mission 01 — Figma Make Reference

> **STATUS: NOT LOCKED / PRODUCT BLOCKER**
>
> This file deliberately supersedes the previous claim that ASCII wireframes could serve as a locked Figma reference.

## Rule

**ASCII wireframes are planning notes only. They are not Figma Make output and they do not authorize a final UI implementation.**

The UI may be kept functional while runtime bugs are fixed, but no visual pass can be declared complete until the real design reference below exists.

## Required Figma Make evidence

- [ ] Real Figma Make project/frame URL
- [ ] S1 — Fresh Mission
- [ ] S2 — Editing
- [ ] S3 — Running
- [ ] S4 — Beginner error
- [ ] S5 — Progress milestone
- [ ] S6 — Mission complete
- [ ] S7 — API / help
- [ ] Exported reference images committed under `doc/design/screens/`
- [ ] `mission01-ui-spec.md` updated from the real design
- [ ] Game screenshots compared against the Figma frames
- [ ] Product-owner sign-off recorded in Issue #2

## Product direction

The player should feel:

> I am operating a programmable drone inside a sci-fi mining facility. Python is the control system.

The player should **not** feel:

> I am using an IDE/dashboard with a tiny game preview attached.

## Non-negotiable hierarchy

1. The game world must remain visually important and readable.
2. The Python editor must feel like an in-world control terminal, not a generic textarea.
3. The Coach must explain the player's actual attempt and next concept.
4. Errors must connect the highlighted code line to what happened in the world.
5. RUN / STOP / RESET must read as game controls.
6. Mission progress must visibly change the facility, not only counters.

## Current temporary layout

The current LÖVE layout and `world_camera.lua` are **functional scaffolding only**. They may be used to keep development/test paths operational, but their dimensions, ratios, colors, panel hierarchy, and camera scale are not design-approved.

Do not mark Phase 0/Figma complete until the real Figma Make reference exists.
