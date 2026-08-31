# CODE SWARM — V0.2 Implementation Docs

> **Thi công:** freebuff  
> **Issue:** [#2 — In-Game Python Workspace](https://github.com/babyfox1306/code-swwarm/issues/2)  
> **Prerequisite:** Issue #1 CLOSED — Gate 1 PASS  
> **Mục tiêu:** Người **chưa biết code** học Python **trong game** → RUN → hiểu lỗi → sửa → WIN

---

## Đọc theo thứ tự

| # | File | Nội dung |
|---|------|----------|
| 00 | [00-overview.md](./00-overview.md) | Nguyên tắc sản phẩm, out-of-scope, gate question |
| 01 | [01-architecture.md](./01-architecture.md) | Python ↔ Lua boundary, luồng RUN |
| 02 | [02-file-structure.md](./02-file-structure.md) | Cây thư mục + spec từng file mới |
| 03 | [03-milestones.md](./03-milestones.md) | **P0→P7 lộ trình** (quan trọng nhất) |
| 04 | [04-python-api-spec.md](./04-python-api-spec.md) | 6 API Python — hợp đồng player |
| 05 | [05-python-runtime.md](./05-python-runtime.md) | Bundled CPython, worker, sandbox, anti-freeze |
| 06 | [06-editor.md](./06-editor.md) | In-game editor — behavior bắt buộc |
| 07 | [07-coach-mission01.md](./07-coach-mission01.md) | Mission 01 từng bước + hint 4 tầng |
| 08 | [08-errors-and-hints.md](./08-errors-and-hints.md) | Syntax/runtime errors — beginner copy |
| 09 | [09-layout-hud.md](./09-layout-hud.md) | Layout màn hình V0.2 |
| 10 | [10-save-persistence.md](./10-save-persistence.md) | Autosave, RESET vs code |
| 11 | [11-testing.md](./11-testing.md) | Scenario A–H + Definition of Done |
| 12 | [12-anti-patterns.md](./12-anti-patterns.md) | Cấm + FAQ |

---

## Quy tắc vàng V0.2

1. **Teaching > testing** — không editor trắng + “good luck”.
2. **Python thật** — không pseudo-Python, không regex → Lua.
3. **RUN = code trên màn hình** — không dual state với file ngoài.
4. **Engine Lua, player Python** — user không thấy Lua.
5. **RESET world ≠ xóa code** — buffer editor giữ nguyên.
6. **Bundled runtime** — player không cài pip/venv/Python.
7. **Prove spike trước editor đẹp** — P0 bắt buộc pass.
8. **Không Level 2 / enemy / shop** trong Issue #2.

---

## Thứ tự thi công tóm tắt

```text
P0 Python spike (API + blocking + errors + anti-freeze)
 → P1 Editor buffer → RUN
 → P2 Minimum editor UX
 → P3 Errors + line highlight
 → P4 Coach + hints
 → P5 Mission 01 progression
 → P6 Save/persistence
 → P7 Full beginner QA (A–H)
```

Chi tiết: **[03-milestones.md](./03-milestones.md)**

---

## Gate question (Issue #2)

> Một người chưa từng code có thể mở CODE SWARM, hiểu phải làm gì, viết Python đầu tiên, thấy drone phản ứng, hiểu lỗi, sửa lỗi và tiến bộ **mà không rời game**?

**Không → Issue #2 chưa xong.**

---

## Prompt gửi freebuff

```
Implement CODE SWARM V0.2 per Issue #2.
Read doc/v02/README.md → doc/v03-milestones.md (P0 first).
Player language = real Python (bundled). No regex-to-Lua.
RUN executes editor buffer only. Mission 01 with Coach + 4-tier hints.
Do not add Level 2, enemies, shop. Report after each milestone.
```

---

## Liên kết V0.1

Simulation Lua (`game/`, `scripting/runner.lua` cho dev/QA) **giữ nguyên**. V0.2 thêm layer Python + UI — xem [01-architecture.md](./01-architecture.md).
