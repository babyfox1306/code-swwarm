# 14 — Mission 01 Product Pass (cho freebuff)

> **Issue:** [#2 — In-Game Python Workspace](https://github.com/babyfox1306/code-swwarm/issues/2)  
> **Issue comments (source of truth):** `5481975436` (product audit) · `5496198980` (Figma Make workflow)  
> **Trạng thái Gate 2:** `YELLOW / NOT COMPLETE` — **không** tự chấm PASS bằng code review  
> **Thay thế:** [13-gate2-final-pass.md](./13-gate2-final-pass.md) chỉ còn giá trị tham khảo harness A–H; **plan này là bắt buộc**

---

## Bạn đang ở đâu?

```text
TECHNICAL V0.2 PROTOTYPE     → WORKING (Python, editor, worker, WIN có thể đạt được)
GATE 2 PRODUCT EXPERIENCE    → YELLOW — Mission 01 chưa cảm giác là GAME dạy Python
```

**Đích rõ ràng:**

> Mission 01 phải thực sự có cảm giác là **một game dạy Python**, không phải IDE demo có drone chạy bên cạnh.

Player phải cảm thấy:

> **Tao đang điều khiển drone trong một facility bằng Python console.**

Không phải:

> **Tao đang dùng một IDE có sprite chạy bên cạnh.**

---

## Quy tắc cứng — đọc trước khi code

| # | Rule |
|---|------|
| R1 | **Không nhảy phase.** Phase N chưa PASS → không mở Phase N+1. |
| R2 | **Không Mission 02**, enemy, shop, multi-drone, tech tree, economy. |
| R3 | **Không thêm API thứ 7** (`deposited()` — dùng HUD). |
| R4 | **Không LLM/AI tutor** — Coach = rule-based deterministic. |
| R5 | **Không regex Python→Lua** — player chạy CPython thật. |
| R6 | **UI visual pass:** Figma Make → lock hierarchy → LÖVE → đối chiếu Figma. **Cấm** thêm rectangle trong Lua cho tới khi vừa chỗ. |
| R7 | **Gate 2 GREEN** chỉ khi **cold-start beginner playtest** (Phase 10) PASS — không chỉ harness/code review. |
| R8 | Mỗi phase xong: **commit + comment Issue #2** với checklist phase đó. |

---

## Thứ tự làm — KHÓA 0→10

```text
Phase 0  — Figma Make: 7 UI states + lock composition     [BLOCKER cho Phase 2,4,7 UI]
Phase 1  — Fix tutorial Step 3 → Step 4 (state machine)
Phase 2  — World viewport / camera / layout (theo Figma)
Phase 3  — Coach phản hồi theo code + hành vi thực tế
Phase 4  — Mining / deposit / world progress feedback
Phase 5  — Editor UX đủ dùng thật
Phase 6  — Hint tiến cấp (không nhảy đáp án)
Phase 7  — Mission Complete + progression screen
Phase 8  — README / product language (Python, in-game editor)
Phase 9  — Windows alpha tự chạy (không cài Python/LÖVE)
Phase 10 — Cold-start beginner playtest + evidence GREEN
```

**Song song được:** Phase 0 và Phase 1 (logic tutorial không cần Figma).  
**Phase 2 trở đi:** phải có Figma reference đã lock (Phase 0 PASS).

---

## Báo cáo sau mỗi phase

Paste vào Issue #2:

```markdown
## Phase N complete — <tên>
- Commit: `<hash>`
- Checklist: (copy tick từ section Exit criteria)
- Demo: screenshot hoặc 1 câu mô tả hành vi
- Known gaps: none / mô tả
- Next: Phase N+1
```

---

# Phase 0 — Figma Make reference (BLOCKER UI)

## Mục tiêu

Thiết kế **toàn bộ màn hình player-facing** trong Figma Make **trước** khi sửa `hud_v02.lua`, `editor.lua`, `coach_panel.lua`, layout.

## Workflow bắt buộc

```text
Figma Make → chốt UI/game hierarchy → mới code LÖVE2D → chạy game đối chiếu lại Figma
```

## 7 states — phải có frame riêng trong Figma

| # | State | Player thấy gì |
|---|-------|----------------|
| S1 | **Fresh Mission 01** | Objective, world lớn/đọc được, Coach step 1, starter editor |
| S2 | **Editing** | Editor focus, world vẫn có presence, không bị “panel nhỏ” |
| S3 | **Running** | Trạng thái execute rõ — code đang chạy ↔ drone đang làm |
| S4 | **Beginner error** | Dòng lỗi ↔ giải thích Coach/error — visual link |
| S5 | **Progress milestone** | Ví dụ cargo full / deposit đầu — world **phản hồi** |
| S6 | **Mission complete** | Completion có reward, không chỉ text + RESET |
| S7 | **API / help opened** | Overlay không phá context mission |

## Câu hỏi Figma phải trả lời

- Mắt player nhìn đầu tiên vào đâu?
- World chiếm bao nhiêu % màn hình để **cảm giác gameplay**?
- Editor nằm đâu mà không nuốt hết identity?
- RUN trông như **hành động gameplay chính** thế nào?
- Khi code chạy, UI thay đổi gì?
- Quan hệ visual giữa **một dòng code** và **hành động drone**?
- Mission 01 cảm giác **mission** chứ không phải worksheet?
- Scale 1280×720 và fullscreen lớn hơn?

## Deliverables

| File / artifact | Nội dung |
|-----------------|----------|
| `doc/design/mission01-figma-reference.md` | Link Figma Make + ảnh export 7 states (PNG trong `doc/design/screens/`) |
| `doc/design/mission01-ui-spec.md` | Spacing, typography scale, color tokens, panel hierarchy (copy từ Figma) |
| Owner sign-off | Comment Issue #2: "Figma reference locked" |

## Exit criteria — Phase 0 PASS

- [ ] 7 states có frame trong Figma Make
- [ ] Composition khớp tinh thần **facility + Python console**, không IDE dashboard
- [ ] World viewport **≥ 50% chiều cao vùng gameplay** (ước lượng visual — không 45% panel nhỏ)
- [ ] RUN, objective, progress, Coach hierarchy đã chốt
- [ ] `doc/design/mission01-figma-reference.md` committed
- [ ] **Không** sửa layout LÖVE cho đến khi checklist trên tick hết

## Cấm

- Bắt đầu Phase 2 bằng cách kéo rectangle trong Lua
- Gọi UI “done” vì panel render được

---

# Phase 1 — Fix tutorial Step 3 → Step 4

## Vấn đề (blocker hiện tại)

`coach/mission01.lua` thiếu transition **Step 3 → Step 4**:

```text
Step 1 --arrived_at_ore--> Step 2
Step 2 --cargo >= 1--> Step 3
         (DEAD END — không có điều kiện vào Step 4)
Step 4 --cargo >= 5--> Step 5
...
```

Beginner viết `while` đúng vẫn kẹt ở “Repeat”.

## Mục tiêu

Progression hiểu **cả code lẫn simulation** — không chỉ raw cargo events.

## Files

| File | Việc |
|------|------|
| `coach/mission01.lua` | State machine + transition Step 3→4 |
| `coach/code_analyzer.lua` | **MỚI** — lightweight recognizer trên source Python |
| `main.lua` | Gọi analyzer sau RUN / trước hoặc sau events |
| `data/mission01/hints.json` | Chỉ sửa nếu step text lệch (optional Phase 6) |

## Transition spec — Mission 01

| Step | ID | Complete khi (ALL logic OR) |
|------|-----|----------------------------|
| 1 | `move` | `move_to` + `nearest_ore` trong code **và** event `arrived_at_ore` |
| 2 | `mine` | `mine()` trong code **và** `cargo >= 1` |
| 3 | `loop_intro` | Code có `while` **và** (`cargo > 1` **hoặc** ≥2 lần mine thành công trong một RUN) |
| 4 | `capacity` | `cargo() == capacity()` (5) — event `cargo_full` |
| 5 | `base` | Drone at base với `cargo > 0` — event `at_base` |
| 6 | `deposit` | `deposit()` success — event `deposited` amount > 0 |
| 7 | `automate` | `deposited >= 20` WIN |

### Step 3 → 4 (fix chính)

```lua
-- Pseudocode — implement in mission01.lua
if step == 3 then
    if CodeAnalyzer.hasWhileLoop(source)
       and (data.cargo > 1 or session.mineCountThisRun >= 2) then
        step = 4
    end
end

if step == 4 and data.cargo >= capacity then
    step = 5  -- optional: chỉ advance khi player đã thấy full cargo
end
```

## `coach/code_analyzer.lua` — minimum API

```lua
-- Không cần AST đầy đủ. Regex/token đủ cho Mission 01.
CodeAnalyzer.hasWhileLoop(source)      -- while + :
CodeAnalyzer.hasCall(source, "mine")
CodeAnalyzer.hasCall(source, "move_to")
CodeAnalyzer.hasCall(source, "deposit")
CodeAnalyzer.mentionsNearestOre(source)
CodeAnalyzer.mentionsBase(source)
CodeAnalyzer.mentionsCapacity(source) -- cargo() >= capacity() pattern
```

**Cấm:** parse Python bằng regex→Lua execution. Chỉ **đọc string** để nhận diện pattern cho Coach.

## Session trace (cho Phase 3)

Thêm vào `Mission01` hoặc module riêng:

```lua
session = {
    lastSource = "",
    lastRunResult = "idle", -- idle | success | error | stopped
    mineCountThisRun = 0,
    moveCountThisRun = 0,
    depositCountThisRun = 0,
    eventsThisRun = {},
}
```

Reset session mỗi lần RUN; append events từ simulation.

## Verify — manual script

1. F9 fresh code
2. `move_to(nearest_ore())` → RUN → Coach **Step 2**
3. thêm `mine()` → RUN → **Step 3**
4. Thêm loop:

```python
move_to(nearest_ore())
while cargo() < 5:
    mine()
```

RUN đến cargo ≥ 2 → Coach **Step 4** (không kẹt Step 3)

5. Tiếp tục đến cargo 5 → **Step 5**

## Exit criteria — Phase 1 PASS

- [ ] Step 3 → 4 transition hoạt động live
- [ ] Không regression Step 1, 2, 5, 6, 7
- [ ] `code_analyzer.lua` có unit notes trong comment hoặc `qa/` smoke
- [ ] Issue #2 comment Phase 1

---

# Phase 2 — World viewport / camera / layout

## Prerequisites

- Phase 0 Figma **PASS**
- Phase 1 **PASS** (có thể test song song nhưng không skip)

## Vấn đề

Sim V0.1: world ~800×400 tại offset (80,80). V0.2 nhét vào ~45% chiều cao trái + `setScissor` → world bị **crop như preview**, không phải gameplay.

## Mục tiêu

```text
simulation coordinates (unchanged)
        ↓
world camera: scale + offset (fit)
        ↓
V0.2 world viewport rect (from Figma)
```

## Files

| File | Việc |
|------|------|
| `game/world_camera.lua` | **MỚI** — fit world bounds vào viewport |
| `game/world.lua` | Draw qua camera transform |
| `ui/hud_v02.lua` | Layout theo `doc/design/mission01-ui-spec.md` |
| `main.lua` | Pass viewport rect; `love.resize` → relayout + camera |

## `world_camera.lua` spec

```lua
WorldCamera.setViewport(x, y, w, h)  -- from HudV02
WorldCamera.begin()   -- love.graphics.push + translate + scale
WorldCamera.endDraw() -- pop
WorldCamera.screenToWorld(sx, sy)    -- optional debug
```

**Fit algorithm:**

```text
content_bounds = { x=80, y=80, w=800, h=400 }  -- from C.WORLD_*
scale = min(viewport.w / content.w, viewport.h / content.h) * 0.95  -- padding
offset_x = viewport.x + (viewport.w - content.w * scale) / 2
offset_y = viewport.y + (viewport.h - content.h * scale) / 2
```

- Resize/fullscreen: recompute — **không clip** base, 3 ore, drone start
- World **dominant** — match Figma (≥ visual target từ Phase 0)

## Layout rules (from Figma spec)

- Không hardcode 45% trong `hud_v02.lua` — dùng tokens từ `mission01-ui-spec.md`
- Editor: bottom hoặc side per Figma — **đối chiếu screenshot**
- Coach: không wall of text — max visible lines + scroll

## Verify

| Check | Pass |
|-------|------|
| 1280×720 | Toàn bộ 3 ore + base + drone readable |
| 1920×1080 / F11 | Composition giữ, không object clip |
| Resize nhỏ 1024×600 | Min spec [09-layout-hud.md](./09-layout-hud.md) |
| Side-by-side Figma S1 | Viewer nói “programming game” không nói “IDE” |

## Exit criteria — Phase 2 PASS

- [ ] `world_camera.lua` implemented
- [ ] No gameplay coordinate hacks per-object
- [ ] Figma S1/S2/S3 screenshot compare documented in Issue comment
- [ ] Regression: walls, sprites, VFX vẫn vẽ đúng

---

# Phase 3 — Coach phản hồi theo hành vi / code thực tế

## Prerequisites

Phase 1 (analyzer + session trace)

## Mục tiêu

Sau mỗi RUN (success / error / stop), Coach hiển thị **diagnosis** từ code + state + events — không chỉ static step text.

## Files

| File | Việc |
|------|------|
| `coach/feedback.lua` | **MỚI** — rule engine post-run |
| `ui/coach_panel.lua` | Hiển thị `feedback` + step text |
| `main.lua` | Gọi `Feedback.diagnose(session, world, error)` khi RUN kết thúc |

## `Feedback.diagnose` — priority rules (first match wins)

Implement theo thứ tự:

| Priority | Condition | Message (paraphrase OK) |
|----------|-----------|-------------------------|
| 1 | Syntax/Name/Indent error | Map từ error panel + next action |
| 2 | `mine()` before move / not at ore | "Move to ore first" |
| 3 | `deposit()` not at base | "Return to base first" |
| 4 | Moved, cargo still 0, no `mine()` | "You reached ore. Add mine()." |
| 5 | Mined once, no `while`, cargo 1 | "Good — try while to repeat" |
| 6 | Cargo full, still at ore | "Full — return to base" |
| 7 | At base, cargo > 0, no deposit | "Call deposit() at base" |
| 8 | Deposited once, no loop automation | "Automate the full trip" |
| 9 | WIN | "You automated the full cycle!" |
| 10 | Default | Step static text từ `STEP_TEXTS` |

**Cấm:** gọi API LLM. Chỉ `if/elseif` deterministic.

## UI presentation

- Post-run feedback: block **"What happened"** trên Coach
- Step title vẫn hiện (Step N of 7)
- Error state (S4): feedback + error panel **cùng nói một story**

## Verify scripts

| After RUN | Expected Coach tail |
|-----------|---------------------|
| only `move_to(nearest_ore())` | "Add mine()" |
| move + mine once | mentions `while` |
| full cargo at ore | "return to base" |
| at base, no deposit | "deposit()" |

## Exit criteria — Phase 3 PASS

- [ ] ≥ 6 rules trên hoạt động live
- [ ] Feedback đổi sau mỗi RUN — không static-only
- [ ] Figma S4 có counterpart trong game (screenshot compare)

---

# Phase 4 — Mining / deposit / world progress feedback

## Prerequisites

Phase 2 (camera — actions phải readable)

## Mục tiêu

Player thấy **dòng Python gây ra hiệu ứng** — world đáng quan tâm.

## Giữ asset hiện có — không art project mới

Dùng `assets/` + VFX code. Chỉ thêm lights/pips/monitor states đơn giản.

## Drone

| State | Feedback |
|-------|----------|
| idle | bob nhẹ |
| moving | thruster/trail hướng target |
| mining | tool/beam VFX |
| depositing | dock animation |
| `move_to` active | destination marker tại target |
| cargo 1–5 | cargo pips trên drone hoặc HUD sync |

Files: `game/drone.lua`, `game/effects.lua`

## Mining (`mine()`)

- [ ] Beam/VFX mạnh, sync SFX `mine` (đã có audio)
- [ ] Ore sprite react (shake/flash)
- [ ] Ore depleted → visual khác (dim/empty)
- [ ] Cargo HUD đổi **cùng frame**

## Deposit (`deposit()`)

- [ ] Transfer VFX drone → base
- [ ] DEPOSITED counter pulse/animate
- [ ] Base glow tăng theo progress

## Facility progress milestones

| Deposited | World response (chọn ≥ 3) |
|-----------|---------------------------|
| 5 | light on |
| 10 | monitor color change |
| 15 | machinery anim / reactor fill |
| 20 | pre-WIN glow (→ Phase 7) |

File: `game/world.lua` hoặc `game/facility_state.lua` **MỚI**

```lua
FacilityState.getTier(deposited) -- 0..4
FacilityState.drawOverlays()     -- lights, monitor, reactor bar
```

## Verify

- RUN `mine()` — player chỉ vào **một** dòng code đã gõ (highlight optional Phase 5)
- Deposit 5 — facility **khác** deposit 0 (screenshot)
- Figma S5 milestone compare

## Exit criteria — Phase 4 PASS

- [ ] Mining + deposit có cause/effect rõ
- [ ] ≥ 3 milestone world responses
- [ ] Không regression audio Gate 1

---

# Phase 5 — Editor UX đủ dùng thật

## Mục tiêu

Editor = **nơi viết Python thật** trong game, không prototype textarea.

## Files

`ui/editor.lua`, `ui/hud_v02.lua` (focus chrome per Figma)

## Bắt buộc

| Feature | Spec |
|---------|------|
| Ctrl+A | Select all |
| Ctrl+C/X/V | Clipboard (love.system.setClipboardText / get) |
| Shift+Tab | Outdent line/selection (nếu có selection) |
| Current line highlight | Subtle background khi không error |
| Long lines | Horizontal scroll **hoặ** clip + indicator |
| After RUN/error | Caret + scroll preserved; editable ngay |
| RESET world (F8) | Code không đổi |
| NEW CODE (F9) | Confirm nếu buffer ≠ starter: "Replace your code?" |

## Strongly recommended (làm nếu < 2h)

- Syntax highlight tối thiểu: keyword, string, comment, 6 API calls
- Auto-close `()`, `"`, `'`
- F1 API ref: click example → insert at caret

## Cấm

- LSP, autocomplete dropdown, multi-file tabs, Vim mode

## Verify

- Gõ `while` + indent 4 spaces — không fight editor
- Paste từ Notepad — clipboard OK
- Error line red; current line subtle blue/gray
- 20+ dòng scroll mượt

## Exit criteria — Phase 5 PASS

- [ ] Clipboard 3/3
- [ ] F9 confirm khi dirty
- [ ] Figma S2 editing compare

---

# Phase 6 — Hint tiến cấp

## Mục tiêu

Tier 1→4 **khác nhau rõ** — tier 4 mới full solution **cho step hiện tại**.

## File

`data/mission01/hints.json` — rewrite toàn bộ 7 steps

## Pattern bắt buộc

```text
Tier 1 — mô tả vấn đề (không code)
Tier 2 — concept + API name
Tier 3 — code shape, còn chỗ trống / ...
Tier 4 — full solution CHỈ cho step này
```

## Ví dụ Step 5 (full cargo → base) — copy vào JSON

**tier1:** "Your drone is full. Where should the ore go?"  
**tier2:** "The base accepts cargo. move_to(\"base\") sends the drone home."  
**tier3:** `if cargo() >= capacity():\n    # return home here`  
**tier4:** `if cargo() >= capacity():\n    move_to("base")`

## UX rules

- `hintTier` reset về 0 mỗi `setStep(n)`
- Tier 4: confirm dialog "Show solution for this step?"
- **tier3 ≠ tier4** — audit tất cả 7 steps
- Không show full mission solution ở step 1–3

## `coach_panel.lua`

- Nút "Next Hint" → tier++
- Hiển thị tier label: "Hint 2 of 4 — API"

## Exit criteria — Phase 6 PASS

- [ ] 7 steps × 4 tiers audited
- [ ] Không duplicate tier3/4
- [ ] Tier 4 confirm works
- [ ] Cold-run: beginner không nhận full answer ở tier 1

---

# Phase 7 — Mission Complete + progression

## Prerequisites

Phase 0 S6 Figma + Phase 4 facility at 20

## Mục tiêu

WIN = **mission complete**, không phải test harness.

## Files

| File | Việc |
|------|------|
| `ui/mission_complete.lua` | **MỚI** — modal/screen |
| `coach/progression.lua` | **MỚI** — track stats |
| `main.lua` | Show on WIN; actions |

## Stats to track (session)

```lua
progression = {
    runCount = 0,
    errorCount = 0,
    hintsUsed = 0,
    depositedFinal = 20,
    concepts = { "commands", "while", "automation" },
}
```

Increment: RUN start, error, hint button.

## Completion screen — bắt buộc hiển thị

- [ ] "Mission Complete" headline
- [ ] Concepts learned (3 bullets)
- [ ] Ore deposited: 20
- [ ] RUN attempts, errors count, hints used
- [ ] Rank/medal đơn giản (A/B/C hoặc 1–3 star)
- [ ] Buttons: **Replay** | **Review Code** | **Continue**

## Continue behavior

Mission 02 chưa có → **Continue** mở screen:

```text
Mission 02 — Coming Soon
Thanks for completing First Program.
[Back to Mission 01]
```

Không chỉ RESET im lặng.

## Verify

- Đạt 20 deposited → modal, script stopped
- Replay → reset world, **giữ hoặc hỏi** code (design: Replay = F8 world + giữ code)
- Figma S6 compare

## Exit criteria — Phase 7 PASS

- [ ] Completion screen live
- [ ] Continue → coming soon (không crash)
- [ ] Stats plausible sau 1 playthrough

---

# Phase 8 — README / product language

## File

`README.md` (root) — **primary Quick Start**

## Bắt buộc thay

| Cũ (V0.1) | Mới (V0.2) |
|-----------|------------|
| Edit `player/program.lua` | Write Python **in the game editor** |
| Lua player language | Python for players |
| `love .` for players | `CodeSwarm.exe` or `run.bat` for dev |

## README structure

```markdown
# CODE SWARM
Programming game — learn Python by controlling drones in a facility.

## How to Play (players)
download alpha → double-click CodeSwarm.exe
Write Python in the editor → RUN (F5) → watch drone obey

## Controls
F5 RUN, Esc STOP, F8 reset world, F9 new code, F1 API

## For developers
run.bat, doc/v02/, architecture note Lua engine + Python player
```

## Also update

- [ ] `doc/README.md` — pointer Phase 0–10
- [ ] `doc/v02/qa-gate2-evidence.md` — banner YELLOW, link plan này

## Exit criteria — Phase 8 PASS

- [ ] New user đọc README không thấy Lua player path
- [ ] Quick Start khớp alpha package (Phase 9)

---

# Phase 9 — Windows alpha tự chạy

## Mục tiêu

```text
download / unzip → double-click CodeSwarm.exe
```

Không: cmd, PowerShell, pip, Python install, `love .`, PATH.

## Target folder

```text
dist/CODE-SWARM-alpha/
    CodeSwarm.exe          # love.exe fused OR launcher
    love.dll + *.dll
    game.love OR loose files
    vendor/python/         # embeddable CPython
    (assets, data, python/, scripting/, ...)
```

## Scripts to create

| Script | Purpose |
|--------|---------|
| `scripts/fetch-python.ps1` | Đã có — đảm bảo idempotent |
| `scripts/build-alpha.ps1` | **MỚI** — fetch python + copy love + fuse |
| `scripts/verify-alpha.ps1` | **MỚI** — smoke trên máy sạch |

## Build steps (document in script)

1. `fetch-python.ps1` → `vendor/python/`
2. Copy LÖVE 11.5 win64 files (hoặc document path)
3. `love --version` — fuse: `copy /b love.exe+game.love CodeSwarm.exe` **hoặc** folder layout documented
4. Set `CODESWARM_PYTHON` relative to exe dir in launcher
5. Zip `CODE-SWARM-alpha.zip`

## Clean machine proof

VM hoặc máy **không** có Python/LÖVE:

- [ ] Unzip only
- [ ] Double-click `CodeSwarm.exe`
- [ ] Scenario B1: `move_to(nearest_ore())` works
- [ ] Ghi trong evidence: OS, no prior installs

## Exit criteria — Phase 9 PASS

- [ ] `dist/CODE-SWARM-alpha.zip` in repo **hoặc** GitHub Release artifact
- [ ] `doc/v02/alpha-build.md` — build instructions
- [ ] Clean machine checklist ticked

---

# Phase 10 — Cold-start beginner playtest

## Prerequisites

Phases 1–9 **ALL PASS**

## Mục tiêu

Trả lời Gate question bằng **play thật**, không code review.

## Gate question (final)

> Can a person who has never programmed launch the packaged game, understand the mission, write Python inside CODE SWARM, see a meaningful machine/world respond to their code, make a mistake, understand and fix it, automate the task, complete the mission, and feel that they just played and progressed through a game?

**YES chỉ khi playtest PASS.**

## Protocol — 11 bước quan sát

Tester = người không biết CODE SWARM internals. **Không** đọc source/doc trước.

| # | Observe | Pass? |
|---|---------|-------|
| 1 | Hiểu goal Mission 01 | |
| 2 | Biết gõ ở đâu | |
| 3 | Chạy lệnh đầu tiên | |
| 4 | Nối code ↔ drone | |
| 5 | Sửa 1 typo có hướng dẫn | |
| 6 | Hiểu indent khi `while` | |
| 7 | Cargo đạt 5 | |
| 8 | Hiểu phải về base | |
| 9 | Deposit 1 load | |
| 10 | Automate đến 20 | |
| 11 | Không rời game | |

**Ghi:** hesitate ở đâu, wording nào confuse, hint tier nào cần.

## Automated pre-flight (vẫn bắt buộc)

```bat
python qa\worker_harness.py
```

Plus manual A–H từ [11-testing.md](./11-testing.md) trên **alpha package**.

## Evidence

Cập nhật `doc/v02/qa-gate2-evidence.md`:

```markdown
# Gate 2 QA Evidence — V0.2 (PRODUCT GREEN)

- Status: GREEN / YELLOW
- Alpha build: CODE-SWARM-alpha.zip @ commit
- Beginner tester: <name or "scripted cold-start">
- Date:

## Phase 0–9 sign-off table
| Phase | PASS | Commit |

## Beginner playtest (11 steps)
| Step | PASS | Notes |

## Gate question
Answer: YES/NO
Reason:

## Figma compare
|S1-S7| match Y/N | screenshot links |
```

## Exit criteria — Phase 10 / GATE 2 PASS

- [ ] Harness 3/3
- [ ] A–H on alpha package
- [ ] 11-step playtest — **no blocking usability fail**
- [ ] Figma S1–S7 compare documented
- [ ] Gate question = **YES**
- [ ] Issue #2 ready to close

---

# Phụ lục A — File ownership

| Area | Files |
|------|-------|
| Tutorial state | `coach/mission01.lua`, `coach/code_analyzer.lua` |
| Coach UX | `coach/feedback.lua`, `ui/coach_panel.lua` |
| World present | `game/world_camera.lua`, `game/facility_state.lua`, `game/effects.lua` |
| Editor | `ui/editor.lua` |
| Layout | `ui/hud_v02.lua`, `doc/design/*` |
| Complete | `ui/mission_complete.lua`, `coach/progression.lua` |
| Build | `scripts/build-alpha.ps1`, `dist/` |
| Runtime | `python/*`, `scripting/python_runner.lua` — chỉ sửa nếu playtest block |

---

# Phụ lục B — Regression không được phá

- [ ] 6 Python API unchanged ([04-python-api-spec.md](./04-python-api-spec.md))
- [ ] STOP / anti-freeze / worker harness
- [ ] RESET world ≠ wipe code
- [ ] RUN = editor buffer only
- [ ] Gate 1 visuals baseline (sprites, walls, SFX)

---

# Phụ lục C — Cấm scatter (Issue #2)

Không làm trước khi Phase 10 PASS:

- Mission 02 content
- Enemies, combat, shop
- Multiple drones
- Procedural maps
- Online features
- macOS/Linux alpha (Windows only Gate 2)

---

# Prompt paste cho freebuff

```text
Đọc doc/v02/14-mission01-product-pass.md — đây là plan BẮT BUỘC Issue #2.

Gate 2 = YELLOW. Không tự PASS bằng code review.

Làm đúng thứ tự Phase 0→10. Không nhảy phase. Không Mission 02.

Phase 0: Figma Make 7 states → doc/design/ → lock trước khi sửa layout Lua.
Phase 1: Fix Step 3→4 trong coach/mission01.lua + code_analyzer.lua.
Phase 2–10: theo checklist từng phase.

Mỗi phase xong: commit + comment Issue #2 với checklist.

Chỉ báo GATE 2 PASS sau Phase 10 cold-start playtest trên alpha package.
```

---

# Liên kết

| Doc | Khi nào đọc |
|-----|-------------|
| [07-coach-mission01.md](./07-coach-mission01.md) | Step definitions |
| [08-errors-and-hints.md](./08-errors-and-hints.md) | Error copy templates |
| [09-layout-hud.md](./09-layout-hud.md) | Min resolution (superseded by Figma for composition) |
| [11-testing.md](./11-testing.md) | A–H regression |
| [13-gate2-final-pass.md](./13-gate2-final-pass.md) | Harness scripts only |
| Issue #2 comments | `5481975436`, `5496198980` |
