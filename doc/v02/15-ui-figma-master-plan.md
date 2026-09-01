# 15 — UI / Figma Master Plan (chi tiết từng bước)

> **Đọc sau:** [14-mission01-product-pass.md](./14-mission01-product-pass.md) (overview Phase 0→10)  
> **File này:** Plan UI **không thể làm sai** — Figma Make → LÖVE → đối chiếu → PASS  
> **Issue:** [#2](https://github.com/babyfox1306/code-swwarm/issues/2) · comments `5481975436`, `5496198980`  
> **Trạng thái UI:** `NOT PASS` — prototype rectangle, Phase 0 chưa bắt đầu

---

## 0. Verdict hiện tại (đừng tự lừa mình)

| Câu hỏi | Trả lời |
|---------|---------|
| Panel render được? | ✅ |
| Nút RUN/editor/coach chạy? | ✅ |
| Người mới nhìn thấy **programming game**? | ❌ |
| Match Figma reference? | ❌ (chưa có Figma) |
| Đạt Gate 2 UI? | ❌ |

**Kết luận:** UI **chưa được**. Cần làm đúng plan này trước khi báo UI xong.

---

## 1. North star — một câu duy nhất

> Player điều khiển **drone trong facility sci-fi** bằng **Python console gắn vào máy** — không phải mở IDE có game nhỏ bên cạnh.

### Visual metaphor (bắt buộc giữ xuyên suốt)

```text
┌─────────────────────────────────────────────────────────────┐
│  FACILITY COMMAND DECK                                        │
│  ┌─────────────────────────────┐  ┌──────────────────────┐  │
│  │                             │  │ MISSION BRIEFING     │  │
│  │   LIVE FACILITY FEED        │  │ (Coach — ngắn, rõ)   │  │
│  │   drone · ore · base · FX   │  │                      │  │
│  │                             │  ├──────────────────────┤  │
│  │                             │  │ ALERT / STATUS       │  │
│  └─────────────────────────────┘  └──────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ PYTHON CONTROL TERMINAL — monospace, terminal chrome    ││
│  └─────────────────────────────────────────────────────────┘│
│  [ ▶ EXECUTE ]  [ ■ ABORT ]  ...                             │
└─────────────────────────────────────────────────────────────┘
```

### Từ cấm khi review UI

- "dashboard", "IDE", "split panel dev tool", "worksheet"
- World nhỏ như thumbnail
- Coach = wall of text không scroll
- RUN = nút xanh generic không nổi bật
- WIN = chỉ chữ đỏ/xanh giữa màn hình

---

## 2. Thứ tự làm UI — KHÓA

```text
A. Phase 0 — Figma Make (7 frames)           ← BẮT ĐẦU Ở ĐÂY
B. Lock doc/design/mission01-ui-spec.md
C. Phase 2b — Implement LÖVE theo spec (KHÔNG tự ý layout)
D. Screenshot compare S1–S7
E. Phase 3–7 UI portions (feedback, FX, complete screen)
F. Phase 10 — beginner nhìn UI phải hiểu trong 10s
```

**Cấm:** Sửa `hud_v02.lua` layout/colors cho "vừa chỗ" trước khi A+B xong.

**Đã xong (giữ nguyên):** Phase 1 tutorial logic · `world_camera.lua` (fit map) — chỉ **reposition** theo Figma, không xóa camera.

---

## 3. Phase 0 — Figma Make (copy-paste prompt)

### 3.1 Prompt gửi Figma Make (tiếng Anh — tool hiểu tốt hơn)

Paste nguyên khối:

```text
Design a 1280×720 game UI for "CODE SWARM" — a beginner Python programming game.

VISUAL GOAL: The player operates a mining drone inside a sci-fi robot facility using an in-game Python control terminal. NOT a code IDE with a small game preview.

STYLE:
- Dark sci-fi facility command deck
- Teal/cyan accents for active systems
- Amber for warnings, green for success
- Monospace terminal for code area
- Readable at 1280×720 for ages 12+

LAYOUT HIERARCHY (eye flow):
1. LIVE FACILITY VIEW (largest) — top-left ~58% width, ~55% height
2. MISSION BRIEFING panel — top-right ~42% width, ~38% height  
3. ALERT/STATUS strip — top-right below briefing, ~42% width, ~17% height
4. PYTHON CONTROL TERMINAL — bottom full width of left column, ~45% height
5. COMMAND BAR — bottom 48px: EXECUTE (primary), ABORT, RESET FACILITY, NEW PROGRAM, API

REQUIRED FRAMES (7 separate artboards):
S1 Fresh Mission — Step 1 coach, starter comments in terminal, objective DEPOSITED 0/20
S2 Editing — cursor in terminal, line numbers, subtle current-line highlight
S3 Running — EXECUTE pulsing/active, facility feed shows drone moving, status RUNNING
S4 Error — line 3 highlighted red in terminal, alert panel explains fix in plain English
S5 Milestone — cargo 5/5 full, facility lights on, coach celebrates briefly
S6 Mission Complete — full reward screen: stats, concepts learned, Replay/Continue
S7 API Help — modal overlay listing 6 Python functions, mission still visible behind

Do NOT design a generic IDE. The facility world must feel like the main game.
```

### 3.2 Sau khi Figma generate — chỉnh tay (checklist)

- [ ] World **lớn hơn** editor (diện tích pixel)
- [ ] RUN/EXECUTE là **nút primary** lớn nhất command bar
- [ ] Coach ≤ **6 dòng** visible trên S1 (phần còn scroll)
- [ ] Terminal có **header chrome** (vd: `PYTHON CONTROL // DRONE-01`)
- [ ] Top bar: logo + mission name + DEPOSITED + CARGO + status pill
- [ ] S4: **cùng một số dòng** highlight ở terminal VÀ mention trong alert
- [ ] S6: không chỉ "MISSION COMPLETE" — có stats + 3 concepts + 3 buttons

### 3.3 Export bắt buộc

| File | Path |
|------|------|
| Figma link | `doc/design/mission01-figma-reference.md` |
| S1–S7 PNG @1x | `doc/design/screens/s1-fresh-mission.png` … `s7-api-help.png` |
| S1 @1920 scaled | `doc/design/screens/s1-1920.png` (resize test) |
| Tokens filled | `doc/design/mission01-ui-spec.md` |

### 3.4 Phase 0 PASS — tick hết mới code UI

- [ ] 7 PNG committed
- [ ] `mission01-ui-spec.md` có số đo px (không để trống)
- [ ] Owner comment Issue #2: **"Figma locked"**
- [ ] 2 người nhìn S1 đều nói "game" không nói "IDE"

---

## 4. Design tokens — điền vào `mission01-ui-spec.md`

Dùng giá trị Figma **thật** sau khi design. Dưới đây là **default đề xuất** nếu Figma chưa có — thay bằng số từ Figma khi lock.

### 4.1 Màu

| Token | Hex | Dùng cho |
|-------|-----|----------|
| `bg_deck` | `#0C0E14` | Nền toàn màn |
| `bg_facility_feed` | `#12161F` | Vùng world |
| `bg_briefing` | `#141820` | Coach panel |
| `bg_terminal` | `#0A0D12` | Editor |
| `bg_terminal_header` | `#1A2030` | Terminal chrome |
| `border_panel` | `#2A3040` | Viền panel |
| `text_primary` | `#E8EAED` | Body |
| `text_muted` | `#8A9099` | Labels |
| `accent_cyan` | `#4FC3F7` | Title, links, active |
| `accent_amber` | `#FFB74D` | CARGO, hints |
| `accent_green` | `#66BB6A` | DEPOSITED, success |
| `accent_red` | `#EF5350` | Error |
| `btn_execute` | `#1B5E20` | RUN primary |
| `btn_execute_glow` | `#4CAF50` | RUN running pulse |
| `btn_abort` | `#B71C1C` | STOP |
| `btn_secondary` | `#37474F` | RESET, API |

### 4.2 Typography @ 1280×720

| Role | Font | Size | Weight |
|------|------|------|--------|
| Game title | Sans (default LÖVE) | 16px | bold |
| Mission subtitle | Sans | 13px | normal |
| HUD counters | Sans | 14px | bold |
| Coach title | Sans | 15px | bold |
| Coach body | Sans | 13px | normal |
| Terminal code | Monospace 14px | 14px | normal |
| Line numbers | Monospace | 12px | muted |
| Button | Sans | 12px | bold |
| Error title | Sans | 14px | bold |
| Error body | Sans | 12px | normal |

### 4.3 Layout grid @ 1280×720 (target — chỉnh theo Figma)

```text
Screen: 1280 × 720

top_bar:     y=0,   h=40
content:     y=40,  h=632
command_bar: y=672, h=48

content split:
  left_col:  x=0,   w=744   (58%)
  right_col: x=744, w=536   (42%)

left_col:
  facility_feed:  x=8,  y=48,  w=728, h=348  (~52% content)
  terminal:       x=8,  y=404, w=728, h=268  (~48% content - gap 8px)

right_col:
  briefing:       x=752, y=48,  w=520, h=240
  alert_strip:    x=752, y=296, w=520, h=108
  (gap 8px between panels)

command_bar buttons (left to right, y=680):
  EXECUTE:  x=16,  w=140, h=36  PRIMARY
  ABORT:    x=164, w=100, h=36
  RESET:    x=272, w=130, h=36
  NEW CODE: x=410, w=130, h=36
  API:      x=548, w=80,  h=36
  status pill right-aligned: x=1100
```

**Rule:** Facility feed min height **≥ 320px** @ 1280×720. Nếu nhỏ hơn → FAIL composition.

### 4.4 Responsive

| Resolution | Rule |
|------------|------|
| 1280×720 | Reference frame |
| 1920×1080 | Scale panels proportionally; facility feed **không** shrink dưới 45% height |
| 1024×600 | Min: facility 280px h, terminal 8 lines visible, briefing scroll |

---

## 5. Bảy frames — spec nội dung pixel-perfect

Mỗi frame: **copy chính xác** text demo vào Figma để LÖVE match sau này.

---

### S1 — Fresh Mission 01

**Player story:** Mới mở game, chưa RUN.

| Vùng | Nội dung bắt buộc |
|------|-------------------|
| Top bar | `CODE SWARM` · `Mission 01: First Program` · `DEPOSITED: 0 / 20` · `CARGO: 0 / 5` · pill `READY` |
| Facility feed | Map đầy đủ: base trái, 3 ore, drone tại spawn — **không crop** |
| Terminal header | `PYTHON CONTROL // UNIT DRONE-01` |
| Terminal body | Starter 9 dòng comment (từ `data/mission01/starter.py`) |
| Briefing title | `Step 1 of 7 — Move` |
| Briefing body | `Your drone waits for orders. Find the nearest ore and go there.` + `Try: move_to(nearest_ore())` + `Press EXECUTE (F5)` |
| Alert strip | Empty hoặc subtle tip: `Tip: Lines starting with # are notes — not executed.` |
| Command bar | EXECUTE enabled, ABORT dim |

**Eye test:** 3 giây đầu player biết (1) mục tiêu 20 ore (2) gõ ở terminal (3) bấm EXECUTE.

---

### S2 — Editing

| Khác S1 | Chi tiết |
|---------|----------|
| Terminal | Caret sau dòng `move_to(nearest_ore())` — player vừa gõ |
| Current line | Background `#1E2838` subtle |
| Line numbers | Cột trái, muted |
| Briefing | Giữ Step 1 hoặc "Ready when you are." |
| Focus | Terminal border glow cyan mỏng |

---

### S3 — Running

| Khác S2 | Chi tiết |
|---------|----------|
| Status pill | `RUNNING` amber pulse |
| EXECUTE | Disabled hoặc "RUNNING…" |
| Facility | Drone đang di chuyển (motion trail / thruster) |
| Terminal | Optional: dim non-active lines; **không** lock input (player có thể sửa sau STOP) |
| Briefing | `Executing your program…` hoặc Coach ngắn |

**Visual link:** Mũi tên hoặc highlight mờ từ dòng `move_to` → drone trên map (Figma annotation OK).

---

### S4 — Beginner error

**Demo error:** `minne()` dòng 4 — NameError

| Vùng | Nội dung |
|------|----------|
| Terminal line 4 | Background `#3D1515`, gutter red |
| Alert title | `Unknown name` |
| Alert body | `This name isn't defined. Did you mean mine()?` |
| Alert footer | `See line 4 in your control terminal.` |
| Briefing | Có thể duplicate ngắn: `Fix line 4, then EXECUTE again.` |
| Status pill | `ERROR` red |

**Rule:** Số dòng alert **=** dòng highlight terminal. Không traceback Python raw làm primary.

---

### S5 — Progress milestone

**Demo:** Cargo full 5/5, drone tại ore.

| Vùng | Nội dung |
|------|----------|
| CARGO counter | `5 / 5` amber pulse |
| Facility | Lights bật / monitor vàng — **world phản hồi** |
| Briefing | `Step 4 — Cargo limit` hoặc celebration: `Drone full! Time to return to base.` |
| Terminal | Sample `while cargo() < 5: mine()` |
| Alert | Optional green: `Milestone: cargo capacity reached.` |

---

### S6 — Mission complete

**Không** chỉ overlay chữ. Full screen modal hoặc dedicated panel:

```text
┌────────────────────────────────────────┐
│         ★ MISSION COMPLETE ★          │
│      First Program — Passed          │
│                                      │
│  You learned:                        │
│  • Commands (move_to, mine, deposit) │
│  • while loops                       │
│  • Automation                        │
│                                      │
│  Ore deposited: 20                   │
│  Program runs: 12                    │
│  Errors fixed: 3                     │
│  Hints used: 2                       │
│                                      │
│  Rank: ★★★ Operator                  │
│                                      │
│  [ REPLAY ]  [ REVIEW CODE ]  [ CONTINUE ] │
└────────────────────────────────────────┘
```

| Button | Hành vi LÖVE (Phase 7) |
|--------|------------------------|
| REPLAY | F8 world reset, giữ code |
| REVIEW CODE | Đóng modal, focus terminal |
| CONTINUE | Screen "Mission 02 — Coming Soon" |

---

### S7 — API / Help

| Chi tiết | Spec |
|----------|------|
| Overlay | 60% opacity backdrop, modal center ~520×440 |
| Title | `Python API — Drone Control` |
| 6 entries | `move_to`, `nearest_ore`, `mine`, `cargo`, `capacity`, `deposit` — signature + 1 line example |
| Close | X, Esc, F1 |
| Behind | S1/S2 blurred/dimmed — **mission context preserved** |

---

## 6. Phase 2b — Map Figma → LÖVE (sau Phase 0 PASS)

### 6.1 File refactor plan

| Figma layer | Lua module | Việc |
|-------------|------------|------|
| Top bar | `ui/hud_top_bar.lua` | **MỚI** — tách khỏi hud_v02 |
| Facility feed | `game/world_camera.lua` + draw in main | Giữ camera, thêm bezel chrome |
| Terminal | `ui/editor.lua` + `ui/terminal_chrome.lua` | **MỚI** chrome header, line nums style |
| Briefing | `ui/coach_panel.lua` | Restyle, max height scroll |
| Alert | `ui/error_panel.lua` | Rename conceptually "alert_strip", unify với coach feedback |
| Command bar | `ui/command_bar.lua` | **MỚI** — EXECUTE primary styling |
| API modal | `ui/api_reference.lua` | Match S7 |
| Complete | `ui/mission_complete.lua` | **MỚI** — S6 |
| Layout orchestrator | `ui/hud_v02.lua` | Chỉ layout + delegate draw — **không** hardcode 0.45/0.52 |

### 6.2 `hud_v02.lua` — đọc layout từ spec

```lua
-- Pseudocode — values from mission01-ui-spec.md NOT magic numbers
local Layout = require("ui.layout_spec")

function HudV02.relayout()
    local r = Layout.compute(love.graphics.getWidth(), love.graphics.getHeight())
    HudV02.worldX, HudV02.worldY = r.facility.x, r.facility.y
    HudV02.worldW, HudV02.worldH = r.facility.w, r.facility.h
    -- ...
end
```

Tạo `ui/layout_spec.lua` — single source từ `doc/design/mission01-ui-spec.md`.

### 6.3 Draw order (z-index)

```text
1. bg_deck full screen
2. facility_feed bezel + WorldCamera + world.draw()
3. terminal chrome + editor:draw()
4. briefing panel
5. alert strip (if visible)
6. top bar
7. command bar
8. api overlay (if open)
9. mission complete modal (if won)
```

### 6.4 Phase 2b verify — screenshot compare

| Frame | Game screenshot | Pass |
|-------|-----------------|------|
| S1 | Side-by-side Figma | Composition ±5% panel size |
| S3 | Drone moving + RUNNING pill | |
| S4 | Error line 4 + alert | Same line number |
| S6 | Complete modal | All 3 buttons visible |

Tool: export `qa/screenshots/` during dev; paste vào Issue comment.

### 6.5 Phase 2b exit criteria

- [ ] `layout_spec.lua` — no magic 0.45/0.52 in hud
- [ ] Facility ≥ spec min height @ 1280×720
- [ ] Terminal có header chrome
- [ ] EXECUTE visually primary
- [ ] S1,S3,S4,S6 screenshot compare PASS

---

## 7. Phase 3 — Coach / Alert UI (feedback)

### 7.1 Hai vùng text phải phân vai

| Vùng | Vai trò | Max lines visible |
|------|---------|-------------------|
| **Briefing** (coach) | Step goal + "what to try next" | 5–6 |
| **Alert strip** | Post-run diagnosis + errors | 4–5 |

**Không** dump cả error traceback vào briefing.

### 7.2 `coach/feedback.lua` → UI binding

```lua
-- Returns { briefing = "...", alert = "..." }
-- One of alert/briefing may be empty
Feedback.diagnose(session, world, runnerError)
```

| Situation | Briefing | Alert |
|-----------|----------|-------|
| Moved, no mine | `Next: add mine()` | — |
| NameError | Short coach tip | Full friendly error (S4 style) |
| Cargo full at ore | `Return to base` | `Cargo 5/5` milestone tone |

### 7.3 `coach_panel.lua` changes

- [ ] `setFeedback(briefingText, alertText)` 
- [ ] Scroll nếu text > panel
- [ ] Step title luôn hiện: `Step N of 7 — …`

### 7.3 Phase 3 exit criteria

- [ ] Sau RUN, briefing **đổi** theo tình huống (6 rules min)
- [ ] S4 layout khi error — screenshot match Figma

---

## 8. Phase 4 — World presentation (trong facility feed)

Không đổi layout — chỉ **nội dung** facility feed.

### 8.1 Drone states (visual)

| State | Min feedback |
|-------|--------------|
| idle | Bob |
| moving | Thruster + destination marker |
| mining | Beam VFX |
| depositing | Transfer line to base |

### 8.2 Milestone overlays (facility feed corners)

| Deposited | Overlay |
|-----------|---------|
| 5 | `PWR 25%` bar |
| 10 | Light strip on |
| 15 | Monitor amber |
| 20 | Pre-complete glow |

File: `game/facility_state.lua`

### 8.3 Phase 4 exit criteria

- [ ] S5 screenshot có world response + HUD
- [ ] mine()/deposit() — player chỉ vào action trong <2s

---

## 9. Phase 5 — Terminal (editor) polish

### 9.1 Bắt buộc

| Feature | UI behavior |
|---------|-------------|
| Ctrl+A/C/V/X | Standard |
| Shift+Tab | Outdent |
| Current line | `#1E2838` when not error |
| Error line | `#3D1515` + red gutter |
| F9 dirty | Confirm dialog modal (match game style) |
| Long lines | Horizontal scroll |

### 9.2 Khuyến nghị (nếu <4h)

Syntax colors trong terminal only:

| Token | Color |
|-------|-------|
| keyword | `#C792EA` |
| string | `#C3E88D` |
| comment | `#546E7A` |
| api call | `#82AAFF` |

### 9.3 Phase 5 exit criteria

- [ ] S2 screenshot match (editing state)
- [ ] Clipboard works in-game

---

## 10. Phase 6 — Hints UI

### 10.1 Hint button states

| Tier | Button label | Panel prefix |
|------|--------------|--------------|
| 0 | `REQUEST HINT` | — |
| 1–3 | `NEXT HINT (n/4)` | `Hint n —` amber |
| 4 | `SOLUTION SHOWN` | Confirm trước: modal "Show full solution for this step?" |

### 10.2 Rewrite `hints.json`

Mỗi step — audit [14 plan Phase 6 examples](./14-mission01-product-pass.md#phase-6--hint-tiến-cấp).

**UI rule:** Tier 3 **không** được identical tier 4.

### 10.3 Phase 6 exit criteria

- [ ] Hint tier visible in UI
- [ ] Tier 4 confirm modal

---

## 11. Phase 7 — Mission Complete UI

Implement `ui/mission_complete.lua` **exactly** per S6 frame.

### Stats wired from `coach/progression.lua`

- runCount, errorCount, hintsUsed, depositedFinal

### Phase 7 exit criteria

- [ ] S6 screenshot compare PASS
- [ ] CONTINUE → coming soon screen (styled, not raw text)

---

## 12. UI regression checklist (mỗi commit UI)

Chạy trước khi commit bất kỳ file `ui/*`:

- [ ] 1280×720 — không overlap panel
- [ ] F11 fullscreen — relayout OK
- [ ] 1024×600 — min spec
- [ ] Click EXECUTE / terminal / hint không miss hitbox
- [ ] Error không che caret
- [ ] API modal đóng được
- [ ] WIN modal không trap (3 buttons work)

---

## 13. UI anti-patterns — instant FAIL

| Làm | Hậu quả |
|-----|---------|
| Tăng/giảm % panel trong Lua không có Figma | FAIL |
| Thêm panel thứ 5 (console log, file tree…) | FAIL scope |
| Raw Python traceback làm text chính | FAIL teaching |
| Coach >10 dòng không scroll | FAIL |
| World <40% screen height @ 1280 | FAIL composition |
| Bỏ qua S6 dedicated screen | FAIL Phase 7 |
| Self-PASS UI vì "buttons work" | FAIL Gate 2 |

---

## 14. Timeline ước lượng

| Phase | Ai | Giờ |
|-------|-----|-----|
| 0 Figma | Designer / owner + freebuff | 4–8h |
| 2b LÖVE layout | freebuff | 6–10h |
| 3 Coach UI | freebuff | 3–5h |
| 4 World FX | freebuff | 4–6h |
| 5 Terminal | freebuff | 3–5h |
| 6 Hints | freebuff | 2–3h |
| 7 Complete | freebuff | 3–4h |
| Compare + fix | freebuff | 2–4h |

**Tổng UI:** ~27–45h sau khi Figma lock.

---

## 15. Prompt freebuff (UI only)

```text
Đọc doc/v02/15-ui-figma-master-plan.md.

UI chưa PASS. Bắt đầu Phase 0:
1. Paste prompt section 3.1 vào Figma Make
2. Chỉnh theo checklist 3.2
3. Export S1–S7 → doc/design/screens/
4. Điền mission01-ui-spec.md với số đo thật
5. Comment Issue #2 "Figma locked" + checklist Phase 0

CHỈ sau Phase 0 PASS mới được Phase 2b (layout_spec.lua + refactor ui/).

Mỗi frame: screenshot compare trước khi tick PASS.
Không tự chấm UI xong vì panel render được.
```

---

## 16. Liên kết

| Doc | Mục đích |
|-----|----------|
| [14-mission01-product-pass.md](./14-mission01-product-pass.md) | Full Phase 0–10 |
| [mission01-figma-reference.md](../design/mission01-figma-reference.md) | Link + export checklist |
| [mission01-ui-spec.md](../design/mission01-ui-spec.md) | Tokens + px (fill after Figma) |
| [09-layout-hud.md](./09-layout-hud.md) | Legacy V0.2 layout (superseded by spec) |
