# 13 — Gate 2 Final Pass (cho freebuff)

> **SUPERSEDED** by [14-mission01-product-pass.md](./14-mission01-product-pass.md) for product Gate 2.  
> File này vẫn hữu ích cho: `qa/worker_harness.py`, scenario scripts A–H, pre-flight trước playtest.

> **Trạng thái hiện tại:** `YELLOW` — technical prototype OK; **product pass chưa xong**  
> **Commit tham chiếu:** `273a301` (F9 reset code, worker spawn, move_to IPC)  
> **Issue #2:** vẫn **open** — chưa đóng cho đến Gate question = YES  
> **KHI NÀO ĐÓNG:** Scenarios A–H pass trên máy thật + cập nhật `qa-gate2-evidence.md`

---

## Bạn đang ở đâu?

P0–P6 **đã có code**. QA audit phát hiện blockers B1–B3; phần lớn đã fix sau `ca2e832`. Việc còn lại:

```
┌─────────────────────────────────────────────────────────────┐
│  Architecture / UI scaffold     → PASS (static review)      │
│  Python worker IPC              → FIXED (needs re-verify)   │
│  Live beginner playtest A–H     → UNKNOWN  ← làm ở đây     │
│  Bundled Python (clean VM)      → FAIL (vendor/ missing)    │
└─────────────────────────────────────────────────────────────┘
```

**Nhiệm vụ:** Chơi game như người mới → gặp lỗi → sửa → chơi lại → lặp đến khi **GREEN**.

---

## Quy trình bắt buộc (fix loop)

Lặp cho đến Gate = YES:

```text
1. Pre-flight harness     → python qa/worker_harness.py
2. Chạy game              → run.bat (Windows)
3. Scenario A → H         → gõ code đúng script bên dưới
4. FAIL?                  → ghi evidence, sửa code, commit
5. Retest scenario fail   → không nhảy scenario khác khi blocker
6. Tất cả PASS            → cập nhật qa-gate2-evidence.md
7. Báo owner              → Issue #2 ready to close
```

**Rule:** Một scenario FAIL = **blocker**. Sửa xong retest scenario đó trước khi sang scenario tiếp.

---

## Chuẩn bị môi trường

### Windows (bắt buộc Gate 2)

| Yêu cầu | Kiểm tra |
|---------|----------|
| LÖVE 11.x | `%LOCALAPPDATA%\Programs\LOVE\love-11.5-win64\love.exe` hoặc `love` on PATH |
| Python 3.10+ | `python --version` hoặc `run.bat` set `CODESWARM_PYTHON` |
| Repo path có space OK | `cd /d "%~dp0"` trong `run.bat` |

### Bundled Python (P0 / clean machine)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\fetch-python.ps1
```

Sau fetch: `vendor\python\python.exe` phải tồn tại. Clean VM test: **không** cài Python system, chỉ `run.bat`.

### Save cũ / editor bẩn

Nếu error chỉ "Unknown name" dòng 74+ mà code trông đúng:

1. **F9** (NEW CODE) — reset về `data/mission01/starter.py`
2. Hoặc xóa save: `%APPDATA%\LOVE\code-swwarm\mission01_code.py`

---

## Pre-flight — trước khi mở LÖVE

Từ repo root:

```bat
python qa\worker_harness.py
```

| Test | Pass khi |
|------|----------|
| SyntaxError missing `:` | `response.type == "error"`, `kind == SyntaxError` |
| NameError `minne()` | `response.type == "error"`, `kind == NameError` — **không** `done` |
| Infinite loop | `RuntimeError` budget hoặc timeout — **không** `done` sớm |

**Harness FAIL → sửa `python/worker.py` trước.** Đừng mở LÖVE khi harness đỏ.

---

## Controls (nhớ khi chơi)

| Phím / nút | Hành động |
|------------|-----------|
| **F5** / RUN | Chạy code trong editor |
| **Esc** / STOP | Dừng worker + script |
| **F8** / RESET WORLD | Reset map/ore/drone — **giữ code** |
| **F9** / NEW CODE | Reset editor về starter — **xóa save** |
| **F1** | API reference |
| **F11** | Fullscreen |

**Chỉ dòng không có `#` mới chạy.** Comment = ghi chú, không execute.

---

## Scenario A — Fresh start

**Setup:** F9 (NEW CODE) hoặc xóa save, restart game.

| Step | Làm gì | Pass? |
|------|--------|-------|
| A1 | Boot game | Coach panel hiện Step 1, starter **không** có loop thắng |
| A2 | Đọc Coach, không Google | Biết phải gõ `move_to(nearest_ore())` |
| A3 | F5 với starter only (chỉ comment) | Không crash; Coach nhắc hoặc idle OK |

**Starter đúng:** ~9 dòng comment, **không** có `while True`.

---

## Scenario B — First success

**Setup:** F9 → code sạch.

### B1 — Move

Gõ **một dòng** (không `#`):

```python
move_to(nearest_ore())
```

F5 → **Pass:** drone di chuyển tới ore, dừng idle tại ore. Coach → Step 2.

**Fail thường gặp:**

| Triệu chứng | Nguyên nhân | Fix |
|-------------|-------------|-----|
| Unknown name | `nearest ore()` (space), typo, save cũ | F9, gõ lại `nearest_ore()` |
| Invalid move target | IPC `ore#id` không parse | `scripting/api.lua` `parseOreTargetString` |
| Drone không đi | `waitUntil` sai runner | `python_runner.waitUntil`, `Api.setRunner(pythonRunner)` |
| Worker failed to start | WindowsApps python stub | `scripts/launch-worker.bat`, reject stub |

### B2 — Mine

Thêm dòng:

```python
move_to(nearest_ore())
mine()
```

F5 → **Pass:** cargo tăng (HUD 1/5).

### B3 — Feedback

**Pass:** mining VFX/SFX, drone sprite (không hình chữ nhật xanh).

---

## Scenario C — Syntax errors

Mỗi test: F9 → paste snippet → F5 → kiểm tra Error panel + highlight dòng.

### C1 — Missing colon

```python
while cargo() < 20
    pass
```

**Pass:** friendly message nhắc `:`, line highlight.

### C2 — Bad indent

```python
while cargo() < 20:
move_to(nearest_ore())
```

**Pass:** IndentationError message.

### C3 — Typo API

```python
minne()
```

**Pass:** NameError, gợi ý kiểm tra `mine()`. **Không** hiện `done`/success.

---

## Scenario D — Logic errors

### D1 — Mine before move

```python
mine()
```

**Pass:** runtime/coach giải thích phải move trước.

### D2 — Deposit away from base

Sau khi có cargo (B2), chỉ gõ:

```python
deposit()
```

**Pass:** "not at base" hoặc tương đương.

### D3 — Fix và tiếp tục

```python
move_to("base")
deposit()
```

**Pass:** deposited tăng, Coach step tiến.

---

## Scenario E — Infinite loop + STOP

### E1 — Anti-freeze

F9, gõ:

```python
while True:
    pass
```

F5 → **Pass trong ~5s:** error budget / infinite loop message, **cửa sổ vẫn phản hồi** (không freeze cứng).

### E2 — STOP mid-run

F9, gõ script chạy lâu:

```python
while True:
    move_to(nearest_ore())
    mine()
```

F5 → đợi drone đi → **Esc** → **Pass:** worker dừng, status stopped, **không** kill mọi `python.exe` khác trên máy.

---

## Scenario F — Full mission WIN @ 20

**Mục tiêu:** Hoàn thành chỉ với Coach + hints (tier 1–3), không copy solution từ tier 4 trước step 7.

Solution tham chiếu (chỉ verify cuối cùng):

```python
while True:
    if cargo() >= capacity():
        move_to("base")
        deposit()
    else:
        move_to(nearest_ore())
        mine()
```

| Step | Pass? |
|------|-------|
| F1 | Deposited 20/20, WIN state |
| F2 | Script dừng sau WIN, không runaway |
| F3 | Coach steps 1→7 advance trong quá trình chơi tự nhiên |

**Coach wiring:** `main.lua` gọi `Mission01:onEvent` → `CoachPanel:setStep`.

---

## Scenario G — Persistence

### G1 — Save survives quit

1. F9
2. Viết multi-line (ví dụ B2 code)
3. Quit game (Alt+F4 hoặc đóng cửa sổ)
4. Mở lại `run.bat`

**Pass:** code còn nguyên trong editor.

### G2 — RESET preserves code

1. Có code multi-line
2. F8 RESET WORLD

**Pass:** code **không** đổi; ore/drone reset.

---

## Scenario H — Buffer truth

| Step | Pass? |
|------|-------|
| H1 | Sửa `mine()` → `move_to("base")` only → RUN behavior đổi |
| H2 | Không sửa sau load → RUN khớp buffer |
| H3 | Audit: `main.lua` `doAction("run")` dùng `Editor:getText()` only |

```lua
-- main.lua — RUN path phải là:
local source = Editor:getText()
runner.run(source)
```

---

## Clean machine test (bắt buộc trước đóng Issue)

VM hoặc máy **không** có Python trên PATH:

1. Clone repo
2. `scripts\fetch-python.ps1`
3. Cài LÖVE only
4. `run.bat`
5. Scenario **B1** minimum

**Fail → P0 chưa xong**, không đóng Issue #2.

---

## Playbook sửa lỗi (khi scenario fail)

| Triệu chứng | File ưu tiên |
|-------------|--------------|
| Worker không start | `scripting/python_runner.lua`, `scripts/launch-worker.bat`, `run.bat` |
| `move_to(nearest_ore())` fail | `scripting/api.lua`, `python_runner.lua` `parseApiCall` |
| Error nuốt → done | `python/worker.py` `had_error` flag |
| Drone không chờ idle | `python_runner.waitUntil`, `main.lua` `Api.setRunner` |
| Coach stuck step 1 | `main.lua` events, `coach/mission01.lua` |
| Error panel trống / line sai | `scripting/python_runner.lua` `mapError`, `ui/error_panel.lua` |
| Editor crash UTF-8 | `ui/editor.lua` `_sanitizeUtf8` |
| STOP kill all python | `python_runner.killWorker` + `worker.pid` |
| Save corrupt / line 74+ | F9 reset; cân nhắc validate save on load |

### Thứ tự fix đề xuất (nếu nhiều fail)

```text
1. qa/worker_harness.py — all green
2. B1 move_to(nearest_ore()) — live
3. C3 NameError — live
4. E1 anti-freeze — live
5. F WIN @ 20
6. G persistence
7. vendor/python + clean machine
8. qa-gate2-evidence.md → GREEN
```

---

## Đã PASS — đừng sửa lung tung

| Hạng mục | Ghi chú |
|----------|---------|
| V0.1 sim (walls, sprites, audio) | Giữ nguyên |
| 6 API contract | `doc/v02/04-python-api-spec.md` |
| Coach copy + hints.json | Content OK |
| HUD layout 4 zones | `ui/hud_v02.lua` |
| F9 reset code | `main.lua` `resetEditorToStarter` |
| No regex Python→Lua | grep cấm |

---

## KHÔNG làm trong final pass

- Level 2, enemy, shop, multi-drone
- macOS/Linux bundle (out of scope Gate 2)
- LLM tutor, online help
- Refactor lớn ECS/architecture
- Thêm API thứ 7 (`deposited()` — dùng HUD)
- Pretty IDE (themes, autocomplete)

---

## Evidence — cập nhật `doc/v02/qa-gate2-evidence.md`

Sau mỗi session, ghi:

```markdown
# Gate 2 QA Evidence — V0.2

- **Tester:** freebuff
- **Date:** YYYY-MM-DD
- **Commit:** `<git rev-parse --short HEAD>`
- **LÖVE:** 11.5
- **OS:** Windows 10/11
- **Python:** bundled / system 3.x

## Pre-flight harness
| Test | Result | Notes |
|------|--------|-------|
| SyntaxError | PASS/FAIL | |
| NameError | PASS/FAIL | |
| Infinite loop | PASS/FAIL | |

## Scenarios
| ID | Result | Notes / screenshot |
|----|--------|-------------------|
| A | PASS/FAIL | |
| B | PASS/FAIL | |
| ... | | |

## Gate question
Answer: YES/NO
Reason: ...

## Sign-off
- [ ] A–H all PASS
- [ ] Clean machine B1 PASS
- [ ] Issue #2 ready to close
```

---

## Thứ tự làm (ước lượng 2–4 giờ)

```text
1. python qa/worker_harness.py           (~2 min)
2. fetch-python nếu chưa có vendor/      (~5 min)
3. Scenario A → B (blocker path)         (~20 min)
4. C, D, E                               (~30 min)
5. F full WIN                            (~30 min)
6. G, H                                  (~15 min)
7. Clean machine B1                      (~20 min)
8. qa-gate2-evidence.md + commit         (~10 min)
9. Comment Issue #2                      (~5 min)
```

---

## Commit message gợi ý

```
fix: Gate 2 final pass — live scenarios A–H green

- Fix <specific blocker> found during beginner playtest
- Add/update qa-gate2-evidence.md with live results
- (optional) Bundle vendor/python via fetch script
```

---

## Khi nào được báo GATE 2 PASS?

Chỉ khi **tất cả** đúng:

- [ ] `qa/worker_harness.py` — 3/3 PASS
- [ ] Scenarios A–H — live PASS trên Windows
- [ ] Clean machine — `run.bat` + B1 without system Python
- [ ] Gate question = **YES** với lý do 1–2 câu
- [ ] `doc/v02/qa-gate2-evidence.md` updated
- [ ] Không regression V0.1 visuals/audio

Báo owner:

```text
CODE SWARM V0.2 — GATE 2 PASS
Commit: <hash>
Evidence: doc/v02/qa-gate2-evidence.md
Issue #2 ready to close.
```

---

## Prompt ngắn (paste cho freebuff)

```text
Đọc doc/v02/13-gate2-final-pass.md. Gate 2 = YELLOW.

Làm fix loop:
1. python qa/worker_harness.py
2. run.bat → chơi scenarios A–H đúng script trong doc
3. FAIL → sửa → commit → retest đến GREEN
4. Clean machine test (fetch-python + B1)
5. Cập nhật doc/v02/qa-gate2-evidence.md

Không thêm feature. Báo GATE 2 PASS khi Gate question = YES.
```

---

## Liên kết

| Doc | Mục đích |
|-----|----------|
| [11-testing.md](./11-testing.md) | Scenario definitions |
| [qa-gate2-evidence.md](./qa-gate2-evidence.md) | Evidence log (update here) |
| [08-errors-and-hints.md](./08-errors-and-hints.md) | Error copy templates |
| [07-coach-mission01.md](./07-coach-mission01.md) | Coach step triggers |
| [12-anti-patterns.md](./12-anti-patterns.md) | Hard bans |
